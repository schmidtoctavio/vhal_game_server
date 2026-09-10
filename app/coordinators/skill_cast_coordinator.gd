class_name SkillCastCoordinator
extends Node

# =========================================================
# SIGNALS
# =========================================================

signal skill_cast_request_started(
	peer_id: int,
	request_id: int
)

signal skill_cast_approach_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary,
	cast_range: float
)

signal valid_offensive_skill_against_player(
	attacker_peer_id: int,
	target_peer_id: int,
	skill_id: String
)

# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

var world_navigation_registry: WorldNavigationRegistry = null

var player_status_effect_coordinator: PlayerStatusEffectCoordinator = null

# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_mob_registry: WorldMobRegistry,
	p_world_navigation_registry: WorldNavigationRegistry,
	p_player_status_effect_coordinator: PlayerStatusEffectCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_mob_registry == null:
		return false

	if p_world_navigation_registry == null:
		return false

	if p_player_status_effect_coordinator == null:
		return false

	game_server = p_game_server


	world_session_registry = (
		p_world_session_registry
	)


	world_mob_registry = (
		p_world_mob_registry
	)

	world_navigation_registry = (
		p_world_navigation_registry
	)

	player_status_effect_coordinator = (
		p_player_status_effect_coordinator
	)

	_bind_signals()


	configured = true


	print(
		"SkillCastCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_skill_cast_requested.is_connected(
		_on_client_skill_cast_requested
	):
		game_server.client_skill_cast_requested.connect(
			_on_client_skill_cast_requested
		)


# =========================================================
# INTENCIÓN DE CAST
# =========================================================

func _on_client_skill_cast_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary
) -> void:
	_process_skill_cast_request(
		peer_id,
		request_id,
		skill_id,
		target,
		false
	)


func execute_approached_skill_cast(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary
) -> void:
	_process_skill_cast_request(
		peer_id,
		request_id,
		skill_id,
		target,
		true
	)


func _process_skill_cast_request(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary,
	request_id_already_accepted: bool
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el cast."
		)


		return


	# -----------------------------------------------------
	# REQUEST ID
	# -----------------------------------------------------
	#
	# Un cast reejecutado desde Action Approach conserva
	# el Request ID original ya aceptado.
	# -----------------------------------------------------

	if not request_id_already_accepted:
		if not session.accept_skill_cast_request_id(
			request_id
		):
			_send_result(
				peer_id,
				request_id,
				skill_id,
				false,
				"stale_request",
				session,
				0.0,
				{}
			)


			return


		skill_cast_request_started.emit(
			peer_id,
			request_id
		)


	# -----------------------------------------------------
	# DEFINICIÓN AUTORITATIVA
	# -----------------------------------------------------

	var definition := (
		ServerSkillCatalog.get_definition(
			skill_id
		)
	)


	if definition == null:
		_send_result(
			peer_id,
			request_id,
			skill_id,
			false,
			"unknown_skill",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# SKILL APRENDIDA
	# -----------------------------------------------------

	# -----------------------------------------------------
	# SKILL USAGE ELIGIBILITY
	#
	# Learning Requirements NO se vuelven a evaluar.
	#
	# Una Skill durablemente aprendida sigue siendo usable
	# después de futuros Resets aunque Level o allocations
	# cambien.
	# -----------------------------------------------------

	var usage_error := (
		ServerSkillUsageRules.validate_cast_usage(
			definition,
			session.skill_runtime
		)
	)


	if not usage_error.is_empty():
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			usage_error,
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# ESTADO VITAL DEL CASTER
	# -----------------------------------------------------

	if session.vitals.hp <= 0:
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"character_not_alive",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# TARGET AUTORITATIVO
	#
	# F17-C:
	#
	# Ya no asumimos que todas las skills usan "self".
	#
	# La definición de la skill determina si espera:
	#
	# self
	# entity
	#
	# Para entity, el Game Server vuelve a resolver el
	# entity_id contra WorldMobRegistry.
	# -----------------------------------------------------

	var target_error := (
		_validate_authoritative_target(
			definition,
			session,
			target,
			request_id
		)
	)


	if not target_error.is_empty():
		# -------------------------------------------------
		# ACTION APPROACH
		#
		# Solamente las entity skills actualmente
		# implementadas participan:
		#
		# Fire Ball
		# Poison
		#
		# No gastamos Mana ni iniciamos Cooldown hasta
		# alcanzar rango y ejecutar realmente el cast.
		# -------------------------------------------------

		if (
			target_error == "out_of_range"
			and
			not request_id_already_accepted
			and
			_supports_action_approach(
				definition
			)
		):
			var approach_cooldown_remaining := (
				session
				.skill_runtime
				.get_cooldown_remaining_seconds(
					definition.skill_id
				)
			)


			if approach_cooldown_remaining > 0.0:
				_send_result(
					peer_id,
					request_id,
					definition.skill_id,
					false,
					"cooldown_active",
					session,
					approach_cooldown_remaining,
					{}
				)


				return


			if not session.vitals.has_enough_mana(
				definition.mana_cost
			):
				_send_result(
					peer_id,
					request_id,
					definition.skill_id,
					false,
					"insufficient_mana",
					session,
					0.0,
					{}
				)


				return


			skill_cast_approach_requested.emit(
				peer_id,
				request_id,
				definition.skill_id,
				target.duplicate(
					true
				),
				definition.cast_range
			)


			return


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			target_error,
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# EJECUCIÓN IMPLEMENTADA
	#
	# F17-C ya permite validar un target de entidad real,
	# pero todavía solamente Heal posee efecto real.
	#
	# Fire Ball y Poison deben llegar hasta acá DESPUÉS
	# de haber validado correctamente el target.
	# -----------------------------------------------------

	if (
		definition.skill_id
		!=
		ServerSkillCatalog.HEAL_ID

		and

		definition.skill_id
		!=
		ServerSkillCatalog.FIRE_BALL_ID

		and

		definition.skill_id
		!=
		ServerSkillCatalog.POISON_ID

	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"skill_not_implemented",
			session,
			0.0,
			{}
		)


		return

	# -----------------------------------------------------
	# HEALING POWER AUTORITATIVO
	# -----------------------------------------------------

	# -----------------------------------------------------
	# PREPARAR EFECTO AUTORITATIVO
	#
	# Todavía NO mutamos nada.
	#
	# Primero resolvemos y validamos completamente el
	# efecto. Mana y Cooldown se comprometen después.
	# -----------------------------------------------------

	var requested_heal_amount: int = 0

	var direct_damage_context: ServerDamageResolutionContext = null

	var periodic_damage_context: ServerDamageResolutionContext = null

	var damage_target: WorldMobRuntimeState = null

	var damage_player_target: PlayerWorldSession = null

	var damage_target_entity_id: String = ""

	var area_damage_center: Vector3 = Vector3.ZERO

	var area_damage_entries: Array = []

	if (
		definition.skill_id
		==
		ServerSkillCatalog.HEAL_ID
	):
		requested_heal_amount = (
			ServerHealEffect.calculate_heal_amount(
				definition,
				session.derived_stats
			)
		)


		if requested_heal_amount <= 0:
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


	elif (
		definition.skill_id
		==
		ServerSkillCatalog.FIRE_BALL_ID
	):
		direct_damage_context = (
			ServerSkillDamageRules
			.build_resolution_context(
				definition,
				session.derived_stats
			)
		)


		if (
			direct_damage_context == null
			or
			not direct_damage_context.is_valid()
		):
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return

		var position_result := (
			_read_target_position(
				target
			)
		)


		if not bool(
			position_result.get(
				"ok",
				false
			)
		):
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var position_value: Variant = (
			position_result.get(
				"position",
				null
			)
		)


		if typeof(position_value) != TYPE_VECTOR3:
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		area_damage_center = (
			position_value
		)


		var area_preparation := (
			_prepare_area_damage_entries(
				definition,
				session,
				area_damage_center,
				direct_damage_context
			)
		)


		if not bool(
			area_preparation.get(
				"ok",
				false
			)
		):
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var entries_value: Variant = (
			area_preparation.get(
				"entries",
				[]
			)
		)


		if typeof(entries_value) != TYPE_ARRAY:
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		area_damage_entries = (
			entries_value
		)

	elif (
		definition.skill_id
		==
		ServerSkillCatalog.POISON_ID
	):
		periodic_damage_context = (
			ServerSkillPeriodicDamageRules
			.build_tick_resolution_context(
				definition,
				session.derived_stats
			)
		)


		if (
			periodic_damage_context == null
			or
			not periodic_damage_context.is_valid()
		):
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)

			return

	# -----------------------------------------------------
	# DAMAGE TARGET AUTORITATIVO
	#
	# Fire Ball y Poison comparten el mismo target runtime.
	#
	# La validación semántica/map/range ya ocurrió antes.
	# Acá resolvemos la instancia que será mutada.
	# -----------------------------------------------------

	if (
		definition.skill_id
		==
		ServerSkillCatalog.POISON_ID
	):
		damage_target_entity_id = String(
			target.get(
				"entity_id",
				""
			)
		).strip_edges().to_lower()


		if damage_target_entity_id.is_empty():
			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		if ServerCombatEntityRef.is_player_entity_id(
			damage_target_entity_id
		):
			var target_peer_id := (
				ServerCombatEntityRef.get_player_peer_id(
					damage_target_entity_id
				)
			)


			damage_player_target = (
				world_session_registry.get_session(
					target_peer_id
				)
			)


			if (
				damage_player_target == null
				or
				damage_player_target.vitals == null
				or
				damage_player_target.vitals.hp <= 0
			):
				_send_result(
					peer_id,
					request_id,
					definition.skill_id,
					false,
					"runtime_failure",
					session,
					0.0,
					{}
				)


				return

		else:
			damage_target = (
				world_mob_registry.get_mob(
					damage_target_entity_id
				)
			)


			if (
				damage_target == null
				or
				not damage_target.is_alive()
			):
				_send_result(
					peer_id,
					request_id,
					definition.skill_id,
					false,
					"runtime_failure",
					session,
					0.0,
					{}
				)


				return

	# -----------------------------------------------------
	# COOLDOWN
	# -----------------------------------------------------

	var cooldown_remaining := (
		session
		.skill_runtime
		.get_cooldown_remaining_seconds(
			definition.skill_id
		)
	)


	if cooldown_remaining > 0.0:
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"cooldown_active",
			session,
			cooldown_remaining,
			{}
		)


		return


	# -----------------------------------------------------
	# MANA
	# -----------------------------------------------------

	if not session.vitals.has_enough_mana(
		definition.mana_cost
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"insufficient_mana",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# GASTAR MANA
	# -----------------------------------------------------

	if not session.vitals.spend_mana(
		definition.mana_cost
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"runtime_failure",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# INICIAR COOLDOWN
	# -----------------------------------------------------

	if not session.skill_runtime.start_cooldown(
		definition.skill_id,
		definition.cooldown_duration
	):
		# Si por alguna razón inesperada no podemos iniciar
		# el cooldown, devolvemos el mana consumido.

		session.vitals.restore_mp(
			definition.mana_cost
		)


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"runtime_failure",
			session,
			0.0,
			{}
		)


		return


	# =====================================================
	# EJECUTAR HEAL
	# =====================================================

	if (
		definition.skill_id
		==
		ServerSkillCatalog.HEAL_ID
	):
		var restored_hp := (
			ServerHealEffect.apply(
				session.vitals,
				requested_heal_amount
			)
		)


		cooldown_remaining = (
			session
			.skill_runtime
			.get_cooldown_remaining_seconds(
				definition.skill_id
			)
		)


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			true,
			"ok",
			session,
			cooldown_remaining,
			{
				"kind": "heal",
				"amount": restored_hp,
			}
		)


		print(
			"SkillCastCoordinator | Cast autoritativo ejecutado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | Skill: ",
			definition.skill_id,
			" | Healing Power: ",
			session.derived_stats.healing_power,
			" | Requested Heal: ",
			requested_heal_amount,
			" | Restored Heal: ",
			restored_hp,
			" | HP: ",
			session.vitals.hp,
			"/",
			session.vitals.max_hp,
			" | MP: ",
			session.vitals.mp,
			"/",
			session.vitals.max_mp,
			" | Cooldown: ",
			cooldown_remaining
		)


		return


	# =====================================================
	# EJECUTAR FIRE BALL AoE POSITION + HARD CC
	# =====================================================

	if (
		definition.skill_id
		==
		ServerSkillCatalog.FIRE_BALL_ID
	):
		if (
			direct_damage_context == null
			or
			definition.status_effect_profile == null
		):
			_rollback_committed_skill_costs(
				session,
				definition
			)


			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var total_applied_damage := 0

		var applied_target_count := 0

		var applied_status_target_count := 0


		for entry_value: Variant in area_damage_entries:
			if typeof(entry_value) != TYPE_DICTIONARY:
				continue


			var entry: Dictionary = (
				entry_value
			)


			var mob_value: Variant = (
				entry.get(
					"mob",
					null
				)
			)

			var resolution_value: Variant = (
				entry.get(
					"resolution",
					null
				)
			)


			var area_mob := (
				mob_value
				as
				WorldMobRuntimeState
			)

			var damage_resolution := (
				resolution_value
				as
				ServerDamageResolutionResult
			)


			if (
				area_mob == null
				or
				damage_resolution == null
			):
				continue


			if not area_mob.is_alive():
				continue


			if not damage_resolution.is_valid():
				continue


			var damage_result := (
				world_mob_registry.apply_damage_to_mob(
					area_mob.entity_id,
					damage_resolution.final_damage,
					{
						"kind": "player_skill",

						"peer_id": peer_id,

						"character_id": (
							session.character_id
						),

						"request_id": request_id,

						"skill_id": (
							definition.skill_id
						),

						"area": true,

						"school": (
							damage_resolution.school
						),

						"element": (
							damage_resolution.element
						),

						"delivery": (
							damage_resolution.delivery
						),
					}
				)
			)


			if damage_result.is_empty():
				continue


			var applied_damage := int(
				damage_result.get(
					"applied_damage",
					0
				)
			)


			if applied_damage <= 0:
				continue


			total_applied_damage += (
				applied_damage
			)

			applied_target_count += 1


			# -------------------------------------------------
			# HARD CC
			#
			# Sólo se aplica a víctimas que sobrevivieron.
			# -------------------------------------------------

			var status_replicated := false

			var status_operation := "none"


			if area_mob.is_alive():
				var status_effect := (
					ServerStatusEffectRuntime.create(
						definition.status_effect_profile,
						null,
						{
							"kind": (
								"player_skill_status"
							),

							"peer_id": peer_id,

							"character_id": (
								session.character_id
							),

							"request_id": (
								request_id
							),

							"skill_id": (
								definition.skill_id
							),
						},
						Time.get_ticks_msec()
					)
				)


				if status_effect == null:
					push_warning(
						(
							"SkillCastCoordinator | "
							+
							"No se pudo crear Fire Ball Stun."
						)
					)

				else:
					var status_result := (
						world_mob_registry
						.apply_status_effect_to_mob(
							area_mob.entity_id,
							status_effect
						)
					)


					if bool(
						status_result.get(
							"ok",
							false
						)
					):
						status_operation = String(
							status_result.get(
								"operation",
								""
							)
						)


						status_replicated = bool(
							status_result.get(
								"changed",
								false
							)
						)


						if status_replicated:
							applied_status_target_count += 1

					else:
						push_warning(
							(
								"SkillCastCoordinator | "
								+
								"No se pudo aplicar "
								+
								"Fire Ball Stun."
							)
						)


			# -------------------------------------------------
			# Si Status Effect cambió, WorldPresence ya mandó
			# el snapshot HP + Status.
			#
			# Si no cambió por immunity/death, replicamos HP
			# mediante el pipeline normal de la Skill.
			# -------------------------------------------------

			if not status_replicated:
				_broadcast_mob_state(
					area_mob
				)


			print(
				"SkillCastCoordinator | Fire Ball AoE victim",
				" | Request: ",
				request_id,
				" | Entity: ",
				area_mob.entity_id,
				" | Applied Damage: ",
				applied_damage,
				" | Status: ",
				definition.status_effect_profile.effect_id,
				" | Status Operation: ",
				status_operation,
				" | HP restante: ",
				area_mob.vitals.hp,
				"/",
				area_mob.vitals.max_hp
			)


		cooldown_remaining = (
			session
			.skill_runtime
			.get_cooldown_remaining_seconds(
				definition.skill_id
			)
		)


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			true,
			"ok",
			session,
			cooldown_remaining,
			{
				"kind": "area_damage",

				"amount": total_applied_damage,

				"target_count": (
					applied_target_count
				),

				"status_effect_id": (
					definition
					.status_effect_profile
					.effect_id
				),

				"status_target_count": (
					applied_status_target_count
				),

				"center": {
					"x": area_damage_center.x,
					"y": area_damage_center.y,
					"z": area_damage_center.z,
				},

				"radius": (
					definition.area_radius
				),
			}
		)


		print(
			"SkillCastCoordinator | Fire Ball AoE autoritativo ejecutado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | Center: ",
			area_damage_center,
			" | Radius: ",
			definition.area_radius,
			" | Targets: ",
			applied_target_count,
			" | Stunned: ",
			applied_status_target_count,
			" | Total Damage: ",
			total_applied_damage,
			" | MP: ",
			session.vitals.mp,
			"/",
			session.vitals.max_mp,
			" | Cooldown: ",
			cooldown_remaining
		)


		return

	# =====================================================
	# EJECUTAR POISON
	# =====================================================

	if (
		definition.skill_id
		==
		ServerSkillCatalog.POISON_ID
	):
		if (
			(
				damage_target == null
				and
				damage_player_target == null
			)
			or
			definition.status_effect_profile == null
			or
			periodic_damage_context == null
		):
			_rollback_committed_skill_costs(
				session,
				definition
			)


			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var status_effect := (
			ServerStatusEffectRuntime.create(
				definition.status_effect_profile,
				periodic_damage_context,
				{
					"kind": "player_skill_periodic",

					"peer_id": peer_id,

					"character_id": (
						session.character_id
					),

					"request_id": request_id,

					"skill_id": (
						definition.skill_id
					),

					"school": (
						periodic_damage_context.school
					),

					"element": (
						periodic_damage_context.element
					),

					"delivery": (
						periodic_damage_context.delivery
					),
				},
				Time.get_ticks_msec()
			)
		)


		if status_effect == null:
			_rollback_committed_skill_costs(
				session,
				definition
			)


			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var status_application: Dictionary = {}


		if damage_player_target != null:
			status_application = (
				player_status_effect_coordinator
				.apply_status_effect_to_player(
					damage_player_target.peer_id,
					status_effect
				)
			)

		else:
			status_application = (
				world_mob_registry
				.apply_status_effect_to_mob(
					damage_target.entity_id,
					status_effect
				)
			)


		if (
			not bool(
				status_application.get(
					"ok",
					false
				)
			)
			or
			not bool(
				status_application.get(
					"changed",
					false
				)
			)
		):
			_rollback_committed_skill_costs(
				session,
				definition
			)


			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		var applied_status_value: Variant = (
			status_application.get(
				"status_effect",
				null
			)
		)


		var applied_status := (
			applied_status_value
			as
			ServerStatusEffectRuntime
		)


		if applied_status == null:
			_rollback_committed_skill_costs(
				session,
				definition
			)


			_send_result(
				peer_id,
				request_id,
				definition.skill_id,
				false,
				"runtime_failure",
				session,
				0.0,
				{}
			)


			return


		if damage_player_target != null:
			valid_offensive_skill_against_player.emit(
				peer_id,
				damage_player_target.peer_id,
				definition.skill_id
			)


		cooldown_remaining = (
			session
			.skill_runtime
			.get_cooldown_remaining_seconds(
				definition.skill_id
			)
		)


		var status_operation := String(
			status_application.get(
				"operation",
				""
			)
		)


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			true,
			"ok",
			session,
			cooldown_remaining,
			{
				"kind": "status_effect",

				"amount": 0,

				"status_effect_id": (
					definition
					.status_effect_profile
					.effect_id
				),

				"status_category": (
					definition
					.status_effect_profile
					.category
				),

				"status_operation": (
					status_operation
				),

				"stacks": (
					applied_status.stack_count
				),

				"tick_damage": (
					periodic_damage_context.raw_damage
				),

				"school": (
					periodic_damage_context.school
				),

				"element": (
					periodic_damage_context.element
				),

				"delivery": (
					periodic_damage_context.delivery
				),

				"tick_count": (
					definition
					.status_effect_profile
					.tick_count
				),

				"tick_interval": (
					definition
					.status_effect_profile
					.tick_interval_seconds
				),

				"duration": (
					definition
					.status_effect_profile
					.get_duration_seconds()
				),

				"entity_id": (
					damage_target_entity_id
				),
			}
		)


		print(
			"SkillCastCoordinator | Poison autoritativo aplicado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | Entity: ",
			damage_target_entity_id,
			" | Target Type: ",
			(
				"player"
				if damage_player_target != null
				else "mob"
			),
			" | Operation: ",
			status_operation,
			" | Stacks: ",
			applied_status.stack_count,
			" | Physical Power: ",
			session.derived_stats.physical_power,
			" | Raw Damage/Tick: ",
			periodic_damage_context.raw_damage,
			" | School: ",
			periodic_damage_context.school,
			" | Element: ",
			periodic_damage_context.element,
			" | Ticks: ",
			definition.status_effect_profile.tick_count,
			" | Interval: ",
			definition.status_effect_profile.tick_interval_seconds,
			" | Duration: ",
			definition.status_effect_profile.get_duration_seconds(),
			" | MP: ",
			session.vitals.mp,
			"/",
			session.vitals.max_mp,
			" | Cooldown: ",
			cooldown_remaining
		)


		return

# =========================================================
# ACTION APPROACH
# =========================================================

func _supports_action_approach(
	definition: ServerSkillDefinition
) -> bool:
	if definition == null:
		return false


	if (
		definition.target_kind
		!=
		ServerSkillDefinition.TARGET_ENTITY
	):
		return false


	if definition.cast_range <= 0.0:
		return false


	return (
		definition.skill_id
		==
		ServerSkillCatalog.POISON_ID
	)


func cancel_approached_skill_cast(
	peer_id: int,
	request_id: int,
	skill_id: String,
	_target: Dictionary,
	reason: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var cooldown_remaining := 0.0


	if session.skill_runtime != null:
		cooldown_remaining = (
			session
			.skill_runtime
			.get_cooldown_remaining_seconds(
				skill_id
			)
		)


	_send_result(
		peer_id,
		request_id,
		skill_id,
		false,
		reason,
		session,
		cooldown_remaining,
		{}
	)

# =========================================================
# ROLLBACK DE COSTOS DE SKILL
# =========================================================

func _rollback_committed_skill_costs(
	session: PlayerWorldSession,
	definition: ServerSkillDefinition
) -> void:
	if session == null:
		return


	if definition == null:
		return


	if session.vitals != null:
		session.vitals.restore_mp(
			definition.mana_cost
		)


	if session.skill_runtime != null:
		session.skill_runtime.start_cooldown(
			definition.skill_id,
			0.0
		)

# =========================================================
# VALIDAR TARGET AUTORITATIVO
# =========================================================

func _validate_authoritative_target(
	definition: ServerSkillDefinition,
	session: PlayerWorldSession,
	target: Dictionary,
	request_id: int
) -> String:
	if definition == null:
		return "invalid_target"


	if session == null:
		return "invalid_target"


	var target_kind := String(
		target.get(
			"kind",
			""
		)
	).strip_edges().to_lower()


	if target_kind != definition.target_kind:
		return "invalid_target"


	# -----------------------------------------------------
	# SELF
	# -----------------------------------------------------

	if (
		target_kind
		==
		ServerSkillDefinition.TARGET_SELF
	):
		return ""


	# -----------------------------------------------------
	# ENTITY
	# -----------------------------------------------------

	if (
		target_kind
		==
		ServerSkillDefinition.TARGET_ENTITY
	):
		return _validate_entity_target(
			definition,
			session,
			target,
			request_id
		)


	# -----------------------------------------------------
	# POSITION
	# -----------------------------------------------------

	if (
		target_kind
		==
		ServerSkillDefinition.TARGET_POSITION
	):
		return _validate_position_target(
			definition,
			session,
			target,
			request_id
		)


	return "invalid_target"


# =========================================================
# ENTITY TARGET
# =========================================================

func _validate_entity_target(
	definition: ServerSkillDefinition,
	session: PlayerWorldSession,
	target: Dictionary,
	request_id: int
) -> String:
	var entity_id := String(
		target.get(
			"entity_id",
			""
		)
	).strip_edges().to_lower()


	if entity_id.is_empty():
		return "invalid_target"


	# =====================================================
	# PLAYER PvP
	# =====================================================

	if entity_id.begins_with(
		ServerCombatEntityRef.PLAYER_PREFIX
	):
		if not ServerCombatEntityRef.is_player_entity_id(
			entity_id
		):
			return "invalid_target"


		var target_peer_id := (
			ServerCombatEntityRef.get_player_peer_id(
				entity_id
			)
		)


		var target_session := (
			world_session_registry.get_session(
				target_peer_id
			)
		)


		var pvp_reason := (
			ServerPvpPolicy.validate_engagement(
				session,
				target_session
			)
		)


		if not pvp_reason.is_empty():
			print(
				"SkillCastCoordinator | PvP Skill rechazado",
				" | Request: ",
				request_id,
				" | Skill: ",
				definition.skill_id,
				" | Target: ",
				entity_id,
				" | Reason: ",
				pvp_reason
			)


			return pvp_reason


		if (
			target_session == null
			or
			not target_session.is_valid()
		):
			return "target_not_ready"


		# -------------------------------------------------
		# RANGE
		# -------------------------------------------------

		if definition.cast_range > 0.0:
			var caster_position := Vector2(
				session.position.x,
				session.position.z
			)


			var player_position := Vector2(
				target_session.position.x,
				target_session.position.z
			)


			var distance := (
				caster_position.distance_to(
					player_position
				)
			)


			if distance > definition.cast_range:
				print(
					"SkillCastCoordinator | PvP Skill fuera de rango",
					" | Request: ",
					request_id,
					" | Skill: ",
					definition.skill_id,
					" | Target: ",
					entity_id,
					" | Distancia: ",
					distance,
					" | Rango: ",
					definition.cast_range
				)


				return "out_of_range"


		# -------------------------------------------------
		# LOS
		# -------------------------------------------------

		if not ServerWorldLineOfSight.has_line_of_sight(
			session.map_id,
			session.position,
			target_session.position
		):
			print(
				"SkillCastCoordinator | PvP Skill LOS bloqueado",
				" | Request: ",
				request_id,
				" | Skill: ",
				definition.skill_id,
				" | Target: ",
				entity_id
			)


			return "line_of_sight_blocked"


		print(
			"SkillCastCoordinator | Target PvP autoritativo validado",
			" | Request: ",
			request_id,
			" | Skill: ",
			definition.skill_id,
			" | Entity: ",
			entity_id,
			" | Target Peer: ",
			target_session.peer_id,
			" | Personaje: ",
			target_session.character_name,
			" | HP: ",
			target_session.vitals.hp,
			"/",
			target_session.vitals.max_hp
		)


		return ""


	# =====================================================
	# MOB PvE
	# =====================================================

	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if mob == null:
		return "target_not_found"


	if mob.map_id != session.map_id:
		return "target_wrong_map"


	if not mob.is_alive():
		return "target_not_alive"


	if definition.cast_range > 0.0:
		var caster_position := Vector2(
			session.position.x,
			session.position.z
		)


		var mob_position := Vector2(
			mob.position.x,
			mob.position.z
		)


		var distance := (
			caster_position.distance_to(
				mob_position
			)
		)


		if distance > definition.cast_range:
			print(
				"SkillCastCoordinator | Skill fuera de rango",
				" | Request: ",
				request_id,
				" | Skill: ",
				definition.skill_id,
				" | Entity: ",
				mob.entity_id,
				" | Distancia: ",
				distance,
				" | Rango: ",
				definition.cast_range
			)


			return "out_of_range"


	if not ServerWorldLineOfSight.has_line_of_sight(
		session.map_id,
		session.position,
		mob.position
	):
		print(
			"SkillCastCoordinator | LOS bloqueado",
			" | Request: ",
			request_id,
			" | Skill: ",
			definition.skill_id,
			" | Entity: ",
			mob.entity_id
		)


		return "line_of_sight_blocked"


	print(
		"SkillCastCoordinator | Target autoritativo validado",
		" | Request: ",
		request_id,
		" | Skill: ",
		definition.skill_id,
		" | Entity: ",
		mob.entity_id,
		" | Type: mob",
		" | Mapa: ",
		mob.map_id,
		" | HP: ",
		mob.vitals.hp,
		"/",
		mob.vitals.max_hp
	)


	return ""


# =========================================================
# POSITION TARGET
# =========================================================

func _validate_position_target(
	definition: ServerSkillDefinition,
	session: PlayerWorldSession,
	target: Dictionary,
	request_id: int
) -> String:
	if world_navigation_registry == null:
		return "runtime_failure"


	if definition.cast_range <= 0.0:
		return "invalid_target"


	var position_result := (
		_read_target_position(
			target
		)
	)


	if not bool(
		position_result.get(
			"ok",
			false
		)
	):
		return "invalid_target"


	var requested_value: Variant = (
		position_result.get(
			"position",
			null
		)
	)


	if typeof(requested_value) != TYPE_VECTOR3:
		return "invalid_target"


	var requested_position: Vector3 = (
		requested_value
	)


	var navigation_result := (
		world_navigation_registry
		.resolve_authoritative_target_position(
			session.map_id,
			requested_position
		)
	)


	if not bool(
		navigation_result.get(
			"ok",
			false
		)
	):
		return String(
			navigation_result.get(
				"reason",
				"invalid_target"
			)
		)


	var resolved_value: Variant = (
		navigation_result.get(
			"resolved_target",
			null
		)
	)


	if typeof(resolved_value) != TYPE_VECTOR3:
		return "runtime_failure"


	var authoritative_position: Vector3 = (
		resolved_value
	)


	# -----------------------------------------------------
	# RANGE
	# -----------------------------------------------------

	var caster_position_xz := Vector2(
		session.position.x,
		session.position.z
	)

	var target_position_xz := Vector2(
		authoritative_position.x,
		authoritative_position.z
	)


	var distance := (
		caster_position_xz.distance_to(
			target_position_xz
		)
	)


	if distance > definition.cast_range:
		print(
			"SkillCastCoordinator | Position fuera de rango",
			" | Request: ",
			request_id,
			" | Skill: ",
			definition.skill_id,
			" | Requested: ",
			requested_position,
			" | Authoritative: ",
			authoritative_position,
			" | Distance: ",
			distance,
			" | Range: ",
			definition.cast_range
		)


		return "out_of_range"


	# -----------------------------------------------------
	# LOS HACIA EL CENTRO AUTORITATIVO
	# -----------------------------------------------------

	if not ServerWorldLineOfSight.has_line_of_sight(
		session.map_id,
		session.position,
		authoritative_position
	):
		print(
			"SkillCastCoordinator | Position LOS bloqueado",
			" | Request: ",
			request_id,
			" | Skill: ",
			definition.skill_id,
			" | Position: ",
			authoritative_position
		)


		return "line_of_sight_blocked"


	# -----------------------------------------------------
	# SOBRESCRIBIR LA PROPUESTA DEL CLIENT
	#
	# A partir de acá el resto del cast consume solamente
	# la posición proyectada por Game Server.
	# -----------------------------------------------------

	target[
		"position"
	] = {
		"x": authoritative_position.x,
		"y": authoritative_position.y,
		"z": authoritative_position.z,
	}


	print(
		"SkillCastCoordinator | Target position autoritativo validado",
		" | Request: ",
		request_id,
		" | Skill: ",
		definition.skill_id,
		" | Requested: ",
		requested_position,
		" | Authoritative: ",
		authoritative_position,
		" | Range: ",
		definition.cast_range,
		" | Area Radius: ",
		definition.area_radius
	)


	return ""


# =========================================================
# LEER POSITION TARGET
# =========================================================

func _read_target_position(
	target: Dictionary
) -> Dictionary:
	var position_value: Variant = (
		target.get(
			"position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		return {
			"ok": false,
		}


	var position_data: Dictionary = (
		position_value
	)


	if (
		not position_data.has("x")
		or
		not position_data.has("y")
		or
		not position_data.has("z")
	):
		return {
			"ok": false,
		}


	var x_value: Variant = (
		position_data["x"]
	)

	var y_value: Variant = (
		position_data["y"]
	)

	var z_value: Variant = (
		position_data["z"]
	)


	if (
		typeof(x_value) != TYPE_FLOAT
		and
		typeof(x_value) != TYPE_INT
	):
		return {
			"ok": false,
		}


	if (
		typeof(y_value) != TYPE_FLOAT
		and
		typeof(y_value) != TYPE_INT
	):
		return {
			"ok": false,
		}


	if (
		typeof(z_value) != TYPE_FLOAT
		and
		typeof(z_value) != TYPE_INT
	):
		return {
			"ok": false,
		}


	return {
		"ok": true,

		"position": Vector3(
			float(x_value),
			float(y_value),
			float(z_value)
		),
	}


# =========================================================
# PREPARAR AoE DAMAGE
#
# El Client NO elige víctimas.
#
# Game Server:
#
# center autoritativo
# → mismo mapa
# → vivos
# → radio
# → defense profile
# → Unified Damage Resolver
# =========================================================

func _prepare_area_damage_entries(
	definition: ServerSkillDefinition,
	session: PlayerWorldSession,
	center: Vector3,
	damage_context: ServerDamageResolutionContext
) -> Dictionary:
	if definition == null:
		return {
			"ok": false,
		}


	if session == null:
		return {
			"ok": false,
		}


	if damage_context == null:
		return {
			"ok": false,
		}


	if not damage_context.is_valid():
		return {
			"ok": false,
		}


	if definition.area_radius <= 0.0:
		return {
			"ok": false,
		}


	var entries: Array = []


	var center_xz := Vector2(
		center.x,
		center.z
	)


	for mob: WorldMobRuntimeState in (
		world_mob_registry.get_mobs_in_map(
			session.map_id
		)
	):
		if mob == null:
			continue


		if not mob.is_alive():
			continue


		var mob_xz := Vector2(
			mob.position.x,
			mob.position.z
		)


		var distance := (
			center_xz.distance_to(
				mob_xz
			)
		)


		if distance > definition.area_radius:
			continue


		if mob.definition == null:
			return {
				"ok": false,
			}


		if not mob.definition.is_valid():
			return {
				"ok": false,
			}


		var defense_profile := (
			ServerMobDamageDefenseProfileResolver
			.resolve(
				mob.definition
			)
		)


		if (
			defense_profile == null
			or
			not defense_profile.is_valid()
		):
			return {
				"ok": false,
			}


		var damage_resolution := (
			ServerDamageResolver.resolve(
				damage_context,
				defense_profile
			)
		)


		if (
			damage_resolution == null
			or
			not damage_resolution.is_valid()
		):
			return {
				"ok": false,
			}


		entries.append(
			{
				"mob": mob,

				"resolution": (
					damage_resolution
				),
			}
		)


	return {
		"ok": true,

		"entries": entries,
	}

# =========================================================
# REPLICAR MOB STATE
# =========================================================

func _broadcast_mob_state(
	mob: WorldMobRuntimeState
) -> void:
	if mob == null:
		return


	var snapshot := (
		mob.to_snapshot()
	)


	if snapshot.is_empty():
		return


	var recipients := 0


	for target_session: PlayerWorldSession in (
		world_session_registry.get_sessions_in_map(
			mob.map_id
		)
	):
		if target_session == null:
			continue


		var result := (
			game_server.send_mob_state_updated(
				target_session.peer_id,
				snapshot
			)
		)


		if result != OK:
			push_warning(
				(
					"SkillCastCoordinator | "
					+
					"No se pudo replicar mob. Error: %d"
				)
				%
				result
			)


			continue


		recipients += 1


	print(
		"SkillCastCoordinator | Estado de mob replicado",
		" | Entity: ",
		mob.entity_id,
		" | Recipients: ",
		recipients,
		" | HP: ",
		mob.vitals.hp,
		"/",
		mob.vitals.max_hp
	)

# =========================================================
# ENVIAR RESULTADO
# =========================================================

func _send_result(
	peer_id: int,
	request_id: int,
	skill_id: String,
	accepted: bool,
	reason: String,
	session: PlayerWorldSession,
	cooldown_remaining_seconds: float,
	effect: Dictionary
) -> void:
	if session == null:
		return


	if session.vitals == null:
		return


	var result := (
		game_server.send_skill_cast_result(
			peer_id,
			request_id,
			skill_id,
			accepted,
			reason,
			session.vitals.to_snapshot(),
			cooldown_remaining_seconds,
			effect
		)
	)


	if result != OK:
		push_warning(
			(
				"SkillCastCoordinator | "
				+
				"No se pudo enviar el resultado "
				+
				"del cast al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


		return


	print(
		"SkillCastCoordinator | Resultado enviado",
		" | Request: ",
		request_id,
		" | Skill: ",
		skill_id,
		" | Accepted: ",
		accepted,
		" | Reason: ",
		reason,
		" | Cooldown: ",
		cooldown_remaining_seconds
	)
