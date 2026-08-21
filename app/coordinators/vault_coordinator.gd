class_name VaultCoordinator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal npc_service_invalidation_requested(
	session: PlayerWorldSession,
	reason: String
)


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var vault_repository: BackendVaultRepository = null


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
	p_vault_repository: BackendVaultRepository
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_vault_repository == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	vault_repository = p_vault_repository


	_bind_signals()


	configured = true


	print(
		"VaultCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_vault_item_move_requested.is_connected(
		_on_client_vault_item_move_requested
	):
		game_server.client_vault_item_move_requested.connect(
			_on_client_vault_item_move_requested
		)


	if not vault_repository.vault_loaded.is_connected(
		_on_vault_loaded
	):
		vault_repository.vault_loaded.connect(
			_on_vault_loaded
		)


	if not vault_repository.vault_load_failed.is_connected(
		_on_vault_load_failed
	):
		vault_repository.vault_load_failed.connect(
			_on_vault_load_failed
		)


	if not vault_repository.vault_item_moved.is_connected(
		_on_vault_item_moved
	):
		vault_repository.vault_item_moved.connect(
			_on_vault_item_moved
		)


	if not vault_repository.vault_item_move_failed.is_connected(
		_on_vault_item_move_failed
	):
		vault_repository.vault_item_move_failed.connect(
			_on_vault_item_move_failed
		)


# =========================================================
# CARGAR VAULT ACTIVA
# =========================================================

func load_active_vault(
	peer_id: int
) -> Error:
	if not configured:
		return ERR_UNAVAILABLE


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return ERR_UNAVAILABLE


	return vault_repository.load_vault(
		peer_id,
		session.account_id
	)


# =========================================================
# SOLICITAR INVALIDACIÓN DEL SERVICIO NPC
# =========================================================

func _request_npc_service_invalidation(
	session: PlayerWorldSession,
	reason: String
) -> void:
	if session == null:
		return


	if not session.has_active_npc_service():
		return


	npc_service_invalidation_requested.emit(
		session,
		reason
	)


# =========================================================
# VAULT CARGADA
# =========================================================

func _on_vault_loaded(
	peer_id: int,
	account_id: int,
	snapshot: Dictionary
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


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	var validation_error := (
		ServerVaultSnapshotValidator.validate(
			snapshot
		)
	)


	if not validation_error.is_empty():
		print(
			"VaultCoordinator | Snapshot de Vault rechazado",
			" | Peer: ",
			peer_id,
			" | Cuenta: ",
			account_id,
			" | Motivo: ",
			validation_error
		)


		_request_npc_service_invalidation(
			session,
			"invalid_vault_snapshot"
		)


		return


	if not session.set_active_vault_snapshot(
		snapshot
	):
		_request_npc_service_invalidation(
			session,
			"invalid_vault_session_snapshot"
		)


		return


	var items: Array = (
		snapshot.get(
			"items",
			[]
		)
	)


	print(
		"VaultCoordinator | Vault persistente cargada",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		session.character_name,
		" | Items: ",
		items.size()
	)


	var send_result := (
		game_server.send_vault_snapshot(
			peer_id,
			snapshot
		)
	)


	if send_result != OK:
		push_warning(
			(
				"VaultCoordinator | No se pudo enviar "
				+
				"el snapshot de Vault al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				send_result,
			]
		)


		return


	print(
		"VaultCoordinator | Snapshot de Vault enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Items: ",
		items.size()
	)


# =========================================================
# ERROR CARGANDO VAULT
# =========================================================

func _on_vault_load_failed(
	peer_id: int,
	account_id: int,
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


	print(
		"VaultCoordinator | No se pudo cargar Vault persistente",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Motivo: ",
		message
	)


	if session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		_request_npc_service_invalidation(
			session,
			"vault_backend_unavailable"
		)


# =========================================================
# REQUEST AUTORITATIVO DE MOVIMIENTO
# =========================================================

func _request_vault_item_move(
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


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return ERR_UNAVAILABLE


	var validation_error := (
		ServerVaultSnapshotValidator.validate_move(
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if not validation_error.is_empty():
		print(
			"VaultCoordinator | "
			+
			"Movimiento de Vault rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Motivo: ",
			validation_error
		)


		return ERR_INVALID_DATA


	return vault_repository.move_vault_item(
		peer_id,
		session.account_id,
		uid,
		current_position,
		new_position
	)


# =========================================================
# CLIENT REQUEST — MOVER ITEM
# =========================================================

func _on_client_vault_item_move_requested(
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


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		print(
			"VaultCoordinator | Movimiento Vault rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: servicio Warehouse no activo"
		)


		return


	var snapshot := (
		session.get_active_vault_snapshot()
	)


	if snapshot.is_empty():
		print(
			"VaultCoordinator | Movimiento Vault rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: no existe snapshot autoritativo"
		)


		var reload_result := (
			load_active_vault(
				peer_id
			)
		)


		if reload_result != OK:
			_request_npc_service_invalidation(
				session,
				"vault_reload_failed"
			)


		return


	print(
		"VaultCoordinator | Solicitud de movimiento Vault recibida",
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
		_request_vault_item_move(
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
		"VaultCoordinator | Movimiento Vault no iniciado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Error: ",
		move_result
	)


	if move_result != ERR_BUSY:
		var resend_result := (
			game_server.send_vault_snapshot(
				peer_id,
				snapshot
			)
		)


		if resend_result != OK:
			push_warning(
				(
					"VaultCoordinator | No se pudo reenviar "
					+
					"snapshot de Vault. Error: %d"
				)
				%
				resend_result
			)


# =========================================================
# ITEM MOVIDO
# =========================================================

func _on_vault_item_moved(
	peer_id: int,
	account_id: int,
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


	print(
		"VaultCoordinator | Posición de item Vault persistida",
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


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	# -----------------------------------------------------
	# Laravel continúa siendo la fuente definitiva.
	# No parcheamos localmente el snapshot.
	# -----------------------------------------------------

	var reload_result := (
		load_active_vault(
			peer_id
		)
	)


	if reload_result != OK:
		_request_npc_service_invalidation(
			session,
			"vault_reload_failed"
		)


# =========================================================
# MOVIMIENTO RECHAZADO
# =========================================================

func _on_vault_item_move_failed(
	peer_id: int,
	account_id: int,
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


	print(
		"VaultCoordinator | Movimiento persistente de Vault rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	var reload_result := (
		load_active_vault(
			peer_id
		)
	)


	if reload_result != OK:
		_request_npc_service_invalidation(
			session,
			"vault_reload_failed"
		)
