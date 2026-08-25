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


	if not session.accept_basic_attack_request_id(
		request_id
	):
		_send_result(
			peer_id,
			request_id,
			false,
			"stale_request",
			target,
			{
				"mode": "unarmed",
				"weapon_item_id": "",
				"weapon_uid": "",
			}
		)


		return


	if session.vitals.hp <= 0:
		_send_result(
			peer_id,
			request_id,
			false,
			"character_not_alive",
			target,
			{
				"mode": "unarmed",
				"weapon_item_id": "",
				"weapon_uid": "",
			}
		)


		return


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


	print(
		"BasicAttackCoordinator | Intent autoritativo validado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Entity: ",
		mob.entity_id,
		" | Mob HP: ",
		mob.vitals.hp,
		"/",
		mob.vitals.max_hp,
		" | Mode: ",
		attack_profile["mode"],
		" | Weapon: ",
		attack_profile["weapon_item_id"]
	)


	# -----------------------------------------------------
	# F17-D
	#
	# Target y perfil de ataque ya son autoritativos.
	# El golpe/daño todavía no se ejecuta.
	# -----------------------------------------------------

	_send_result(
		peer_id,
		request_id,
		false,
		"basic_attack_not_implemented",
		target,
		attack_profile
	)


func _default_profile() -> Dictionary:
	return {
		"mode": "unarmed",
		"weapon_item_id": "",
		"weapon_uid": "",
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
