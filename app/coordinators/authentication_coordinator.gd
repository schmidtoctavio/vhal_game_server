class_name AuthenticationCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var backend_ticket_validator: BackendTicketValidator = null

var world_session_registry: WorldSessionRegistry = null

var world_presence_coordinator: WorldPresenceCoordinator = null

var character_item_state_coordinator: CharacterItemStateCoordinator = null

var character_runtime_state_coordinator: CharacterRuntimeStateCoordinator = null

# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_backend_ticket_validator: BackendTicketValidator,
	p_world_session_registry: WorldSessionRegistry,
	p_world_presence_coordinator: WorldPresenceCoordinator,
	p_character_item_state_coordinator: CharacterItemStateCoordinator,
	p_character_runtime_state_coordinator: CharacterRuntimeStateCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_backend_ticket_validator == null:
		return false


	if not p_backend_ticket_validator.is_configured():
		return false


	if p_world_session_registry == null:
		return false


	if p_world_presence_coordinator == null:
		return false


	if p_character_item_state_coordinator == null:
		return false

	if p_character_runtime_state_coordinator == null:
		return false

	game_server = p_game_server

	backend_ticket_validator = p_backend_ticket_validator

	world_session_registry = p_world_session_registry

	world_presence_coordinator = p_world_presence_coordinator

	character_item_state_coordinator = p_character_item_state_coordinator

	character_runtime_state_coordinator = (
		p_character_runtime_state_coordinator
	)

	_bind_signals()


	configured = true


	print(
		"AuthenticationCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
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
		"AuthenticationCoordinator | Identidad validada",
		" | Peer: ",
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
	print(
		"AuthenticationCoordinator | Ticket rechazado",
		" | Peer: ",
		peer_id,
		" | Motivo: ",
		message
	)


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
				"AuthenticationCoordinator | "
				+
				"No se pudo crear la sesión "
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


	# -----------------------------------------------------
	# SNAPSHOT INICIAL DE MUNDO
	# -----------------------------------------------------

	var snapshot_result := (
		game_server.send_world_snapshot(
			peer_id,
			session.to_snapshot()
		)
	)


	if snapshot_result != OK:
		push_error(
			(
				"AuthenticationCoordinator | "
				+
				"No se pudo enviar el snapshot "
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


	# -----------------------------------------------------
	# PRESENCIA DE MUNDO
	# -----------------------------------------------------

	var presence_result := (
		world_presence_coordinator.prepare_presence(
			session
		)
	)


	if presence_result != OK:
		push_error(
			(
				"AuthenticationCoordinator | "
				+
				"No se pudo preparar "
				+
				"la presencia de mundo del peer %d. Error: %d"
			)
			%
			[
				peer_id,
				presence_result,
			]
		)


		world_session_registry.remove_session(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo preparar la presencia del mundo."
		)


		return


	print(
		"AuthenticationCoordinator | Snapshot de mundo enviado",
		" | Peer: ",
		peer_id
	)


	print(
		"AuthenticationCoordinator | Mundo autoritativo preparado",
		" | Peer: ",
		peer_id,
		" | Mapa: ",
		session.map_id,
		" | Posición: ",
		session.position
	)


	# -----------------------------------------------------
	# ESTADO PERSISTENTE DEL PERSONAJE
	# -----------------------------------------------------

	var item_state_load_result := (
		character_item_state_coordinator.load_initial_snapshots(
			peer_id
		)
	)


	if item_state_load_result != OK:
		return


# =========================================================
# PEER DESCONECTADO
# =========================================================

func _on_client_disconnected(
	peer_id: int
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return

	var checkpoint_result := (
		character_runtime_state_coordinator.checkpoint_session(
			session,
			"disconnect"
		)
	)


	if checkpoint_result != OK:
		push_warning(
			(
				"AuthenticationCoordinator | "
				+
				"No se pudo iniciar checkpoint runtime"
				+
				" | Peer: %d"
				+
				" | Character ID: %d"
				+
				" | Error: %d"
			)
			%
			[
				peer_id,
				session.character_id,
				checkpoint_result,
			]
		)

	world_presence_coordinator.notify_presence_left(
		session
	)


	world_session_registry.remove_session(
		peer_id
	)


	print(
		"AuthenticationCoordinator | Sesión de mundo finalizada",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name
	)
