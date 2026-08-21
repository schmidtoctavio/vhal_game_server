class_name InventoryCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var inventory_repository: BackendCharacterInventoryRepository = null


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
	p_inventory_repository: BackendCharacterInventoryRepository
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_inventory_repository == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	inventory_repository = p_inventory_repository


	_bind_signals()


	configured = true


	print(
		"InventoryCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_inventory_item_move_requested.is_connected(
		_on_client_inventory_item_move_requested
	):
		game_server.client_inventory_item_move_requested.connect(
			_on_client_inventory_item_move_requested
		)


	if not inventory_repository.inventory_item_moved.is_connected(
		_on_inventory_item_moved
	):
		inventory_repository.inventory_item_moved.connect(
			_on_inventory_item_moved
		)


	if not inventory_repository.inventory_item_move_failed.is_connected(
		_on_inventory_item_move_failed
	):
		inventory_repository.inventory_item_move_failed.connect(
			_on_inventory_item_move_failed
		)


# =========================================================
# REQUEST AUTORITATIVO
# =========================================================

func _request_inventory_item_move(
	peer_id: int,
	snapshot: Dictionary,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var validation_error := (
		ServerCharacterInventorySnapshotValidator.validate_move(
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if not validation_error.is_empty():
		print(
			"InventoryCoordinator | "
			+
			"Movimiento de Inventory rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Motivo: ",
			validation_error
		)


		return ERR_INVALID_DATA


	return inventory_repository.move_inventory_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_position,
		new_position
	)


# =========================================================
# CLIENT REQUEST
# =========================================================

func _on_client_inventory_item_move_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var snapshot := (
		session.get_inventory_snapshot()
	)


	if snapshot.is_empty():
		print(
			"InventoryCoordinator | Movimiento Inventory rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: no existe snapshot autoritativo"
		)


		var reload_result := (
			inventory_repository.load_inventory(
				peer_id,
				session.account_id,
				session.character_id
			)
		)


		if reload_result != OK:
			game_server.reject_authenticated_peer(
				peer_id,
				"No se pudo recuperar el Inventory persistente."
			)


		return


	print(
		"InventoryCoordinator | Solicitud de movimiento Inventory recibida",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		current_position,
		" | Hacia: ",
		new_position
	)


	var move_result := (
		_request_inventory_item_move(
			peer_id,
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if move_result == OK:
		return


	print(
		"InventoryCoordinator | Movimiento Inventory no iniciado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Error: ",
		move_result
	)


	if move_result != ERR_BUSY:
		var resend_result := (
			game_server.send_character_inventory_snapshot(
				peer_id,
				snapshot
			)
		)


		if resend_result != OK:
			push_warning(
				(
					"InventoryCoordinator | No se pudo reenviar "
					+
					"snapshot de Inventory. Error: %d"
				)
				%
				resend_result
			)


# =========================================================
# ITEM PERSISTIDO
# =========================================================

func _on_inventory_item_moved(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	print(
		"InventoryCoordinator | Posición de item Inventory persistida",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	# -----------------------------------------------------
	# Laravel continúa siendo la fuente definitiva.
	# No parcheamos el snapshot local después del PATCH.
	# -----------------------------------------------------

	var reload_result := (
		inventory_repository.load_inventory(
			peer_id,
			account_id,
			character_id
		)
	)


	if reload_result != OK:
		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo recargar el Inventory persistente."
		)


# =========================================================
# MOVIMIENTO RECHAZADO
# =========================================================

func _on_inventory_item_move_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
	message: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	print(
		"InventoryCoordinator | Movimiento persistente de Inventory rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	var reload_result := (
		inventory_repository.load_inventory(
			peer_id,
			account_id,
			character_id
		)
	)


	if reload_result != OK:
		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo recuperar el Inventory persistente."
		)
