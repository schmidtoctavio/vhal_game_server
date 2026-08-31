class_name MovementCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_navigation_registry: WorldNavigationRegistry = null

var world_movement_system: WorldMovementSystem = null

var npc_service_coordinator: NpcServiceCoordinator = null


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
	p_world_navigation_registry: WorldNavigationRegistry,
	p_world_movement_system: WorldMovementSystem,
	p_npc_service_coordinator: NpcServiceCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_navigation_registry == null:
		return false


	if p_world_movement_system == null:
		return false


	if p_npc_service_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	world_navigation_registry = p_world_navigation_registry

	world_movement_system = p_world_movement_system

	npc_service_coordinator = p_npc_service_coordinator


	_bind_signals()


	configured = true


	print(
		"MovementCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_move_requested.is_connected(
		_on_client_move_requested
	):
		game_server.client_move_requested.connect(
			_on_client_move_requested
		)


	if not world_movement_system.movement_completed.is_connected(
		_on_authoritative_movement_completed
	):
		world_movement_system.movement_completed.connect(
			_on_authoritative_movement_completed
		)


	if not world_movement_system.movement_state_sampled.is_connected(
		_on_authoritative_movement_state_sampled
	):
		world_movement_system.movement_state_sampled.connect(
			_on_authoritative_movement_state_sampled
		)


# =========================================================
# RECHAZAR MOVIMIENTO
# =========================================================

func _reject_client_move(
	peer_id: int,
	request_id: int,
	session: PlayerWorldSession,
	target: Vector3,
	reason: String
) -> void:
	if session == null:
		return


	session.reject_move_request()


	var result := (
		game_server.send_movement_decision(
			peer_id,
			request_id,
			false,
			session.position,
			session.rotation_y,
			Vector3.ZERO,
			reason
		)
	)


	if result != OK:
		push_warning(
			(
				"MovementCoordinator | No se pudo informar "
				+
				"el rechazo al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


	print(
		"MovementCoordinator | Movimiento rechazado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Desde: ",
		session.position,
		" | Solicitado: ",
		target,
		" | Motivo: ",
		reason
	)


# =========================================================
# INTENCIÓN DE MOVIMIENTO
# =========================================================

func _on_client_move_requested(
	peer_id: int,
	request_id: int,
	target: Vector3
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el peer."
		)


		return


	# -----------------------------------------------------
	# REGISTRAR INTENCIÓN RAW
	# -----------------------------------------------------

	session.request_move_to(
		target
	)


	# -----------------------------------------------------
	# RESOLVER DESTINO CONTRA EL NAVMESH AUTORITATIVO
	# -----------------------------------------------------

	var resolution := (
		world_navigation_registry.resolve_reachable_target(
			session.map_id,
			session.position,
			target
		)
	)


	# -----------------------------------------------------
	# DESTINO NO RESOLVIBLE
	# -----------------------------------------------------

	if not bool(
		resolution.get(
			"ok",
			false
		)
	):
		var reason := String(
			resolution.get(
				"reason",
				"unknown"
			)
		)


		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			reason
		)


		return


	# -----------------------------------------------------
	# VALIDAR DESTINO RESUELTO
	# -----------------------------------------------------

	var resolved_value: Variant = (
		resolution.get(
			"resolved_target",
			null
		)
	)


	if typeof(resolved_value) != TYPE_VECTOR3:
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"resolved_target_invalid"
		)


		return


	var resolved_target: Vector3 = (
		resolved_value
	)


	# -----------------------------------------------------
	# VALIDAR PATH
	# -----------------------------------------------------

	var path_value: Variant = (
		resolution.get(
			"path",
			null
		)
	)


	if (
		typeof(path_value)
		!=
		TYPE_PACKED_VECTOR3_ARRAY
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_invalid"
		)


		return


	var authorized_path: PackedVector3Array = (
		path_value
	)


	if authorized_path.is_empty():
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_empty"
		)


		return


	# -----------------------------------------------------
	# CONSISTENCIA ENTRE PATH Y DESTINO RESUELTO
	# -----------------------------------------------------

	var path_final_target: Vector3 = (
		authorized_path[
			authorized_path.size() - 1
		]
	)


	if not path_final_target.is_equal_approx(
		resolved_target
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"resolved_target_mismatch"
		)


		return


	# -----------------------------------------------------
	# AUTORIZAR RUTA
	# -----------------------------------------------------

	if not session.authorize_move_path(
		authorized_path
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_authorization_failed"
		)


		return


	# -----------------------------------------------------
	# CONFIRMAR DECISIÓN AL CLIENTE
	# -----------------------------------------------------

	var decision_result := (
		game_server.send_movement_decision(
			peer_id,
			request_id,
			true,
			session.position,
			session.rotation_y,
			session.authorized_move_target
		)
	)


	if decision_result != OK:
		push_warning(
			(
				"MovementCoordinator | No se pudo confirmar "
				+
				"el movimiento al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				decision_result,
			]
		)


	print(
		"MovementCoordinator | Movimiento autorizado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Desde: ",
		session.position,
		" | Solicitado: ",
		target,
		" | Autorizado: ",
		session.authorized_move_target,
		" | Movement Speed: ",
		session.derived_stats.movement_speed,
		" | Path points: ",
		int(
			resolution.get(
				"path_points",
				0
			)
		)
	)


# =========================================================
# REPLICAR MOVIMIENTO AL MAPA
# =========================================================

func _replicate_movement_state_to_map(
	peer_id: int,
	position: Vector3,
	rotation_y: float,
	moving: bool
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var target_peer_ids: Array[int] = [
		peer_id
	]


	var remote_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			peer_id
		)
	)


	for remote_session: PlayerWorldSession in remote_sessions:
		if remote_session == null:
			continue


		target_peer_ids.append(
			remote_session.peer_id
		)


	var result := (
		game_server.send_movement_state_to_peers(
			peer_id,
			target_peer_ids,
			position,
			rotation_y,
			moving
		)
	)


	if result != OK:
		push_warning(
			(
				"MovementCoordinator | No se pudo replicar "
				+
				"movimiento del peer %d al mapa. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


# =========================================================
# MOVIMIENTO AUTORITATIVO COMPLETADO
# =========================================================

func _on_authoritative_movement_completed(
	peer_id: int,
	position: Vector3,
	rotation_y: float
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	npc_service_coordinator.validate_active_service_range(
		peer_id
	)


	_replicate_movement_state_to_map(
		peer_id,
		position,
		rotation_y,
		false
	)


	print(
		"MovementCoordinator | Movimiento autoritativo completado",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Posición: ",
		position,
		" | Rotación Y: ",
		rotation_y
	)


# =========================================================
# REPLICACIÓN DE MOVIMIENTO
# =========================================================

func _on_authoritative_movement_state_sampled(
	peer_id: int,
	position: Vector3,
	rotation_y: float
) -> void:
	npc_service_coordinator.validate_active_service_range(
		peer_id
	)


	_replicate_movement_state_to_map(
		peer_id,
		position,
		rotation_y,
		true
	)
