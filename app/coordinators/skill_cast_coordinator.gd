class_name SkillCastCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

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
	p_world_mob_registry: WorldMobRegistry
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_mob_registry == null:
		return false


	game_server = p_game_server


	world_session_registry = (
		p_world_session_registry
	)


	world_mob_registry = (
		p_world_mob_registry
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
		ServerSkillCatalog.FIRE_BALL_ID

		or

		definition.skill_id
		==
		ServerSkillCatalog.POISON_ID
	):
		var target_entity_id := String(
			target.get(
				"entity_id",
				""
			)
		).strip_edges().to_lower()


		damage_target = (
			world_mob_registry.get_mob(
				target_entity_id
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
	# EJECUTAR FIRE BALL
	# =====================================================

	if (
		definition.skill_id
		==
		ServerSkillCatalog.FIRE_BALL_ID
	):
		if (
			damage_target == null
			or
			direct_damage_context == null
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


		var damage_defense_profile := (
			ServerMobDamageDefenseProfileResolver
			.resolve(
				damage_target.definition
			)
		)


		if (
			damage_defense_profile == null
			or
			not damage_defense_profile.is_valid()
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


		var damage_resolution := (
			ServerDamageResolver.resolve(
				direct_damage_context,
				damage_defense_profile
			)
		)


		if (
			damage_resolution == null
			or
			not damage_resolution.is_valid()
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


		var damage_result := (
			world_mob_registry.apply_damage_to_mob(
				damage_target.entity_id,
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

					# Legacy metadata temporal.
					"damage_type": (
						definition
						.damage_profile
						.damage_type
					),

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


		var applied_damage := int(
			damage_result.get(
				"applied_damage",
				0
			)
		)


		var target_died := bool(
			damage_result.get(
				"died",
				false
			)
		)


		if applied_damage <= 0:
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
				"kind": "damage",

				"amount": applied_damage,

				"raw_amount": (
					damage_resolution.raw_damage
				),

				"pre_mitigation_amount": (
					damage_resolution
					.pre_mitigation_damage
				),

				"school": (
					damage_resolution.school
				),

				"school_rating": (
					damage_resolution.school_rating
				),

				"post_school_amount": (
					damage_resolution.post_school_damage
				),

				"element": (
					damage_resolution.element
				),

				"element_rating": (
					damage_resolution.element_rating
				),

				"resolved_amount": (
					damage_resolution.final_damage
				),

				# Legacy metadata temporal.
				"damage_type": (
					definition
					.damage_profile
					.damage_type
				),

				"entity_id": (
					damage_target.entity_id
				),

				"killed": target_died,
			}
		)


		_broadcast_mob_state(
			damage_target
		)


		print(
			"SkillCastCoordinator | Fire Ball autoritativo ejecutado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | Entity: ",
			damage_target.entity_id,
			" | Magic Power: ",
			session.derived_stats.magic_power,
			" | Raw Damage: ",
			damage_resolution.raw_damage,
			" | School: ",
			damage_resolution.school,
			" | School Rating: ",
			damage_resolution.school_rating,
			" | Post School: ",
			damage_resolution.post_school_damage,
			" | Element: ",
			damage_resolution.element,
			" | Element Rating: ",
			damage_resolution.element_rating,
			" | Final Damage: ",
			damage_resolution.final_damage,
			" | Applied Damage: ",
			applied_damage,
			" | HP restante: ",
			damage_target.vitals.hp,
			"/",
			damage_target.vitals.max_hp,
			" | Killed: ",
			target_died,
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
			damage_target == null
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
			WorldMobStatusEffectRuntime.create(
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

					"damage_type": (
						definition
						.status_effect_profile
						.damage_type
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


		if not world_mob_registry.apply_status_effect_to_mob(
			damage_target.entity_id,
			status_effect
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
				"kind": "status_effect",

				"amount": 0,

				"status_effect_id": (
					definition
					.status_effect_profile
					.effect_id
				),

				"damage_type": (
					definition
					.status_effect_profile
					.damage_type
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
					damage_target.entity_id
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
			damage_target.entity_id,
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


	# -----------------------------------------------------
	# EL TARGET DEBE COINCIDIR CON LA DEFINICIÓN
	# -----------------------------------------------------

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
		!=
		ServerSkillDefinition.TARGET_ENTITY
	):
		return "invalid_target"


	var entity_id := String(
		target.get(
			"entity_id",
			""
		)
	).strip_edges().to_lower()


	if entity_id.is_empty():
		return "invalid_target"


	# -----------------------------------------------------
	# RESOLVER LA ENTIDAD CONTRA EL REGISTRY AUTORITATIVO
	# -----------------------------------------------------

	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if mob == null:
		return "target_not_found"


	# -----------------------------------------------------
	# MISMO MAPA
	# -----------------------------------------------------

	if mob.map_id != session.map_id:
		return "target_wrong_map"


	# -----------------------------------------------------
	# MOB VIVO
	# -----------------------------------------------------

	if not mob.is_alive():
		return "target_not_alive"

	# -----------------------------------------------------
	# RANGO AUTORITATIVO
	#
	# Algunas entity Skills todavía pueden conservar
	# cast_range = 0 mientras no estén implementadas.
	#
	# Si la definición declara rango positivo,
	# el Game Server lo hace cumplir.
	# -----------------------------------------------------

	if definition.cast_range > 0.0:
		var caster_position := Vector2(
			session.position.x,
			session.position.z
		)


		var target_position := Vector2(
			mob.position.x,
			mob.position.z
		)


		var distance := (
			caster_position.distance_to(
				target_position
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


	# -----------------------------------------------------
	# TARGET VALIDADO
	# -----------------------------------------------------

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
