extends Node


# =========================================================
# REFERENCIAS
# =========================================================

@onready var game_server: GameServer = (
	$GameServer
)

@onready var backend_ticket_validator: BackendTicketValidator = (
	$BackendTicketValidator
)

@onready var world_session_registry: WorldSessionRegistry = (
	$WorldSessionRegistry
)

@onready var world_navigation_registry: WorldNavigationRegistry = (
	$WorldNavigationRegistry
)

@onready var world_movement_system: WorldMovementSystem = (
	$WorldMovementSystem
)

# =========================================================
# START
# =========================================================

func _ready() -> void:
	if game_server == null:
		push_error(
			"ServerMain | No existe GameServer."
		)

		get_tree().quit(
			1
		)

		return


	if backend_ticket_validator == null:
		push_error(
			"ServerMain | No existe BackendTicketValidator."
		)

		get_tree().quit(
			2
		)

		return


	if not backend_ticket_validator.is_configured():
		push_error(
			"ServerMain | BackendTicketValidator no configurado."
		)

		get_tree().quit(
			3
		)

		return


	if world_session_registry == null:
		push_error(
			"ServerMain | No existe WorldSessionRegistry."
		)

		get_tree().quit(
			4
		)

		return

	if world_navigation_registry == null:
		push_error(
			"ServerMain | No existe WorldNavigationRegistry."
		)

		get_tree().quit(
			5
		)

		return


	var navigation_result: Error = (
		await world_navigation_registry.initialize()
	)


	if navigation_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"la navegación. Error: %d"
			)
			%
			navigation_result
		)

		get_tree().quit(
			5
		)

		return

	if world_movement_system == null:
		push_error(
			"ServerMain | No existe WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return


	if not world_movement_system.setup(
		world_session_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return

	_bind_authentication()


	var result := game_server.start()


	if result != OK:
		push_error(
			"ServerMain | No se pudo iniciar el servidor."
		)

		get_tree().quit(
			result
		)

		return


	print(
		"ServerMain | VHAL Game Server iniciado."
	)


# =========================================================
# BIND AUTHENTICATION
# =========================================================

func _bind_authentication() -> void:
	if not game_server.client_authentication_requested.is_connected(
		_on_client_authentication_requested
	):
		game_server.client_authentication_requested.connect(
			_on_client_authentication_requested
		)


	if not backend_ticket_validator.ticket_validated.is_connected(
		_on_ticket_validated
	):
		backend_ticket_validator.ticket_validated.connect(
			_on_ticket_validated
		)


	if not backend_ticket_validator.ticket_rejected.is_connected(
		_on_ticket_rejected
	):
		backend_ticket_validator.ticket_rejected.connect(
			_on_ticket_rejected
		)

	if not game_server.client_authenticated.is_connected(
		_on_client_authenticated
	):
		game_server.client_authenticated.connect(
			_on_client_authenticated
		)


	if not game_server.client_disconnected.is_connected(
		_on_client_disconnected
	):
		game_server.client_disconnected.connect(
			_on_client_disconnected
		)

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
# AUTH REQUEST
# =========================================================

func _on_client_authentication_requested(
	peer_id: int,
	ticket: String
) -> void:
	backend_ticket_validator.validate_ticket(
		peer_id,
		ticket
	)


# =========================================================
# TICKET VALIDADO
# =========================================================

func _on_ticket_validated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> void:
	print(
		"ServerMain | Identidad validada | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		character_data.get(
			"name",
			"?"
		)
	)


	game_server.accept_authentication(
		peer_id,
		account_id,
		character_data
	)


# =========================================================
# TICKET RECHAZADO
# =========================================================

func _on_ticket_rejected(
	peer_id: int,
	message: String
) -> void:
	game_server.reject_authentication(
		peer_id,
		message
	)

# =========================================================
# PEER AUTENTICADO
# =========================================================

func _on_client_authenticated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> void:
	var session := (
		world_session_registry.create_session(
			peer_id,
			account_id,
			character_data
		)
	)


	if session == null:
		push_error(
			(
				"ServerMain | No se pudo crear la sesión "
				+
				"de mundo para el peer %d."
			)
			%
			peer_id
		)

		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo crear la sesión de mundo."
		)

		return

	var snapshot_result := (
		game_server.send_world_snapshot(
			peer_id,
			session.to_snapshot()
		)
	)


	if snapshot_result != OK:
		push_error(
			(
				"ServerMain | No se pudo enviar el snapshot "
				+
				"de mundo al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				snapshot_result,
			]
		)


		world_session_registry.remove_session(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo iniciar la sesión de mundo."
		)


		return


	print(
		"ServerMain | Snapshot de mundo enviado | Peer: ",
		peer_id
	)

	print(
		"ServerMain | Mundo autoritativo preparado | Peer: ",
		peer_id,
		" | Mapa: ",
		session.map_id,
		" | Posición: ",
		session.position
	)


# =========================================================
# PEER DESCONECTADO
# =========================================================

func _on_client_disconnected(
	peer_id: int
) -> void:
	world_session_registry.remove_session(
		peer_id
	)

# =========================================================
# INTENCIÓN DE MOVIMIENTO
# =========================================================

func _on_client_move_requested(
	peer_id: int,
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
	# REGISTRAMOS PRIMERO LA INTENCIÓN RAW
	# -----------------------------------------------------

	session.request_move_to(
		target
	)


	# -----------------------------------------------------
	# EL SERVIDOR RESUELVE EL DESTINO
	# -----------------------------------------------------

	var resolution := (
		world_navigation_registry.resolve_reachable_target(
			session.map_id,
			session.position,
			target
		)
	)


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


		print(
			"ServerMain | Movimiento rechazado",
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


		session.reject_move_request()


		return


	var resolved_value: Variant = (
		resolution.get(
			"resolved_target",
			null
		)
	)


	if typeof(resolved_value) != TYPE_VECTOR3:
		session.reject_move_request()


		print(
			"ServerMain | Movimiento rechazado",
			" | Peer: ",
			peer_id,
			" | Motivo: resolved_target inválido"
		)


		return


	var resolved_target: Vector3 = (
		resolved_value
	)


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
		session.reject_move_request()


		print(
			"ServerMain | Movimiento rechazado",
			" | Peer: ",
			peer_id,
			" | Motivo: path inválido"
		)


		return


	var authorized_path: PackedVector3Array = (
		path_value
	)


	if authorized_path.is_empty():
		session.reject_move_request()


		print(
			"ServerMain | Movimiento rechazado",
			" | Peer: ",
			peer_id,
			" | Motivo: path vacío"
		)


		return


	# -----------------------------------------------------
	# CONSISTENCIA DE LA RESOLUCIÓN
	# -----------------------------------------------------

	var path_final_target: Vector3 = (
		authorized_path[
			authorized_path.size() - 1
		]
	)


	if not path_final_target.is_equal_approx(
		resolved_target
	):
		session.reject_move_request()


		print(
			"ServerMain | Movimiento rechazado",
			" | Peer: ",
			peer_id,
			" | Motivo: destino final inconsistente"
		)


		return


	# -----------------------------------------------------
	# AUTORIZAR LA RUTA ANTES DE INFORMARLA
	# -----------------------------------------------------

	if not session.authorize_move_path(
		authorized_path
	):
		session.reject_move_request()


		print(
			"ServerMain | Movimiento rechazado",
			" | Peer: ",
			peer_id,
			" | Motivo: no se pudo autorizar la ruta"
		)


		return


	print(
		"ServerMain | Movimiento autorizado",
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
		" | Path points: ",
		int(
			resolution.get(
				"path_points",
				0
			)
		)
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

	var replication_result := (
		game_server.send_movement_state(
			peer_id,
			position,
			rotation_y,
			false
		)
	)


	if replication_result != OK:
		push_warning(
			(
				"ServerMain | No se pudo replicar "
				+
				"el final del movimiento al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				replication_result,
			]
		)

	print(
		"ServerMain | Movimiento autoritativo completado",
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
	var result := (
		game_server.send_movement_state(
			peer_id,
			position,
			rotation_y,
			true
		)
	)


	if result != OK:
		push_warning(
			(
				"ServerMain | No se pudo replicar movimiento "
				+
				"al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)
