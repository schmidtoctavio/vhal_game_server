class_name BasicAttackCoordinator
extends Node


var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null


var configured: bool = false


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


	if not game_server.client_basic_attack_requested.is_connected(
		_on_client_basic_attack_requested
	):
		game_server.client_basic_attack_requested.connect(
			_on_client_basic_attack_requested
		)


	configured = true


	print(
		"BasicAttackCoordinator | Inicializado."
	)


	return true


func _on_client_basic_attack_requested(
	peer_id: int,
	request_id: int,
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
			"No existe sesión para Basic Attack."
		)


		return


	# -----------------------------------------------------
	# REQUEST ID
	# -----------------------------------------------------

	if not session.accept_basic_attack_request_id(
		request_id
	):
		_send_result(
			peer_id,
			request_id,
			false,
			"stale_request",
			target,
			_default_profile()
		)


		return


	# -----------------------------------------------------
	# CASTER VIVO
	# -----------------------------------------------------

	if session.vitals.hp <= 0:
		_send_result(
			peer_id,
			request_id,
			false,
			"character_not_alive",
			target,
			_default_profile()
		)


		return


	# -----------------------------------------------------
	# TARGET
	# -----------------------------------------------------

	var entity_id := String(
		target.get(
			"entity_id",
			""
		)
	).strip_edges().to_lower()


	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if mob == null:
		_send_result(
			peer_id,
			request_id,
			false,
			"target_not_found",
			target,
			_default_profile()
		)


		return


	if mob.map_id != session.map_id:
		_send_result(
			peer_id,
			request_id,
			false,
			"target_wrong_map",
			target,
			_default_profile()
		)


		return


	if not mob.is_alive():
		_send_result(
			peer_id,
			request_id,
			false,
			"target_not_alive",
			target,
			_default_profile()
		)


		return


	# -----------------------------------------------------
	# PERFIL AUTORITATIVO
	# -----------------------------------------------------

	var attack_profile := (
		ServerBasicAttackProfileResolver.resolve(
			session.get_equipment_snapshot()
		)
	)


	if attack_profile.is_empty():
		_send_result(
			peer_id,
			request_id,
			false,
			"invalid_equipment_state",
			target,
			_default_profile()
		)


		return


	var base_damage := int(
		attack_profile.get(
			"base_damage",
			0
		)
	)


	var attack_range := float(
		attack_profile.get(
			"attack_range",
			0.0
		)
	)


	var cooldown_duration_seconds := float(
		attack_profile.get(
			"cooldown_duration_seconds",
			0.0
		)
	)


	if (
		base_damage <= 0
		or
		attack_range <= 0.0
		or
		cooldown_duration_seconds < 0.0
	):
		_send_result(
			peer_id,
			request_id,
			false,
			"invalid_attack_profile",
			target,
			attack_profile
		)


		return

	# -----------------------------------------------------
	# DERIVED POWER AUTORITATIVO
	# -----------------------------------------------------

	if session.derived_stats == null:
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	if not session.derived_stats.is_valid():
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return

	# -----------------------------------------------------
	# ATTACK SPEED AUTORITATIVO
	# -----------------------------------------------------

	var effective_cooldown_duration_seconds := (
		ServerBasicAttackSpeedRules
		.calculate_effective_cooldown_seconds(
			cooldown_duration_seconds,
			session.derived_stats.attack_speed_multiplier
		)
	)


	if effective_cooldown_duration_seconds < 0.0:
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return

	var pre_critical_damage := (
		ServerBasicAttackDamageRules
		.calculate_pre_mitigation_damage(
			attack_profile,
			session.derived_stats
		)
	)


	if pre_critical_damage <= 0:
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return

	# -----------------------------------------------------
	# ARMOR FÍSICO DEL TARGET
	# -----------------------------------------------------

	if mob.definition == null:
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	if not mob.definition.is_valid():
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	var armor_rating := (
		mob.definition.base_armor_rating
	)

	# -----------------------------------------------------
	# RANGO AUTORITATIVO
	# -----------------------------------------------------

	var attacker_position := Vector2(
		session.position.x,
		session.position.z
	)


	var target_position := Vector2(
		mob.position.x,
		mob.position.z
	)


	var distance := (
		attacker_position.distance_to(
			target_position
		)
	)


	if distance > attack_range:
		print(
			"BasicAttackCoordinator | Fuera de rango",
			" | Request: ",
			request_id,
			" | Entity: ",
			mob.entity_id,
			" | Distancia: ",
			distance,
			" | Rango: ",
			attack_range
		)


		_send_result(
			peer_id,
			request_id,
			false,
			"out_of_range",
			target,
			attack_profile
		)


		return


	# -----------------------------------------------------
	# COOLDOWN AUTORITATIVO
	# -----------------------------------------------------

	if session.basic_attack_runtime == null:
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	var cooldown_remaining := (
		session
		.basic_attack_runtime
		.get_cooldown_remaining_seconds()
	)


	if cooldown_remaining > 0.0:
		print(
			"BasicAttackCoordinator | Cooldown activo",
			" | Request: ",
			request_id,
			" | Restante: ",
			cooldown_remaining
		)


		_send_result(
			peer_id,
			request_id,
			false,
			"attack_cooldown_active",
			target,
			attack_profile
		)


		return


	if not session.basic_attack_runtime.start_cooldown(
		effective_cooldown_duration_seconds
	):
		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return

	# -----------------------------------------------------
	# CRITICAL STRIKE AUTORITATIVO
	#
	# El roll ocurre sólo después de que:
	#
	# - target fue validado
	# - rango fue validado
	# - cooldown fue aceptado
	#
	# Requests inválidos no consumen Critical Rolls.
	# -----------------------------------------------------

	var critical_roll := randf()


	var is_critical := (
		ServerCriticalStrikeRules.is_critical_roll(
			session.derived_stats.critical_strike_chance,
			critical_roll
		)
	)


	var pre_mitigation_damage := (
		ServerCriticalStrikeRules.calculate_critical_damage(
			pre_critical_damage,
			is_critical,
			session.derived_stats.critical_damage_multiplier
		)
	)


	if pre_mitigation_damage <= 0:
		session.basic_attack_runtime.reset()


		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	# -----------------------------------------------------
	# PHYSICAL ARMOR MITIGATION
	# -----------------------------------------------------

	var post_mitigation_damage := (
		ServerPhysicalDamageMitigationRules
		.calculate_post_mitigation_damage(
			pre_mitigation_damage,
			armor_rating
		)
	)


	if post_mitigation_damage <= 0:
		session.basic_attack_runtime.reset()


		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return

	# -----------------------------------------------------
	# DAMAGE AUTORITATIVO
	#
	# La mutación del mob pasa por WorldMobRegistry para
	# centralizar la transición alive → dead.
	# -----------------------------------------------------

	var damage_result := (
		world_mob_registry.apply_damage_to_mob(
			mob.entity_id,
			post_mitigation_damage,
			{
				"kind": "player_basic_attack",

				"peer_id": peer_id,

				"character_id": (
					session.character_id
				),

				"request_id": request_id,

				"attack_mode": String(
					attack_profile.get(
						"mode",
						""
					)
				),

				"weapon_item_id": String(
					attack_profile.get(
						"weapon_item_id",
						""
					)
				),
			}
		)
	)


	if damage_result.is_empty():
		session.basic_attack_runtime.reset()


		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
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
		session.basic_attack_runtime.reset()


		_send_result(
			peer_id,
			request_id,
			false,
			"runtime_failure",
			target,
			attack_profile
		)


		return


	# -----------------------------------------------------
	# RESULTADO PARA EL ATACANTE
	# -----------------------------------------------------

	_send_result(
		peer_id,
		request_id,
		true,
		"ok",
		target,
		attack_profile
	)


	# -----------------------------------------------------
	# REPLICAR NUEVO ESTADO DEL MOB
	# -----------------------------------------------------

	_broadcast_mob_state(
		mob
	)


	print(
		"BasicAttackCoordinator | Ataque ejecutado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Entity: ",
		mob.entity_id,
		" | Mode: ",
		String(
			attack_profile.get(
				"mode",
				""
			)
		),
		" | Weapon: ",
		String(
			attack_profile.get(
				"weapon_item_id",
				""
			)
		),
		" | Base Cooldown: ",
		cooldown_duration_seconds,
		" | Attack Speed: ",
		session.derived_stats.attack_speed_multiplier,
		" | Effective Cooldown: ",
		effective_cooldown_duration_seconds,
		" | Distancia: ",
		distance,
		" | Base Damage: ",
		base_damage,
		" | Physical Power: ",
		session.derived_stats.physical_power,
		" | Pre-Crit: ",
		pre_critical_damage,
		" | Crit Chance: ",
		session.derived_stats.critical_strike_chance,
		" | Crit Roll: ",
		critical_roll,
		" | Critical: ",
		is_critical,
		" | Crit Multiplier: ",
		session.derived_stats.critical_damage_multiplier,
		" | Pre-Mitigation: ",
		pre_mitigation_damage,
		" | Armor: ",
		armor_rating,
		" | Post-Mitigation: ",
		post_mitigation_damage,
		" | Damage: ",
		applied_damage,
		" | HP restante: ",
		mob.vitals.hp,
		"/",
		mob.vitals.max_hp,
		" | Killed: ",
		target_died
	)


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
					"BasicAttackCoordinator | "
					+
					"No se pudo replicar mob. Error: %d"
				)
				%
				result
			)


			continue


		recipients += 1


	print(
		"BasicAttackCoordinator | Estado de mob replicado",
		" | Entity: ",
		mob.entity_id,
		" | Recipients: ",
		recipients,
		" | HP: ",
		mob.vitals.hp,
		"/",
		mob.vitals.max_hp
	)


func _default_profile() -> Dictionary:
	return {
		"mode": "unarmed",

		"weapon_item_id": "",

		"weapon_uid": "",

		"base_damage": 0,

		"attack_range": 0.0,

		"cooldown_duration_seconds": 0.0,
	}


func _send_result(
	peer_id: int,
	request_id: int,
	accepted: bool,
	reason: String,
	target: Dictionary,
	attack_profile: Dictionary
) -> void:
	var result := (
		game_server.send_basic_attack_result(
			peer_id,
			request_id,
			accepted,
			reason,
			target,
			attack_profile
		)
	)


	if result != OK:
		push_warning(
			(
				"BasicAttackCoordinator | "
				+
				"No se pudo enviar resultado. Error: %d"
			)
			%
			result
		)


		return


	print(
		"BasicAttackCoordinator | Resultado enviado",
		" | Request: ",
		request_id,
		" | Accepted: ",
		accepted,
		" | Reason: ",
		reason,
		" | Mode: ",
		String(
			attack_profile.get(
				"mode",
				""
			)
		)
	)
