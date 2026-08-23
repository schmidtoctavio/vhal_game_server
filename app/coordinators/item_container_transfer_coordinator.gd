class_name ItemContainerTransferCoordinator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal npc_service_invalidation_requested(
	session: PlayerWorldSession,
	reason: String
)


# =========================================================
# CONSTANTES
# =========================================================

const WAREHOUSE_NPC_ID: String = "warehouse_keeper"
const WAREHOUSE_SERVICE_ID: String = "warehouse"


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var inventory_repository: BackendCharacterInventoryRepository = null

var item_transfer_repository: BackendItemTransferRepository = null

var vault_coordinator: VaultCoordinator = null


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
	p_inventory_repository: BackendCharacterInventoryRepository,
	p_item_transfer_repository: BackendItemTransferRepository,
	p_vault_coordinator: VaultCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_inventory_repository == null:
		return false


	if p_item_transfer_repository == null:
		return false


	if p_vault_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	inventory_repository = p_inventory_repository

	item_transfer_repository = p_item_transfer_repository

	vault_coordinator = p_vault_coordinator


	_bind_signals()


	configured = true


	print(
		"ItemContainerTransferCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_item_container_transfer_requested.is_connected(
		_on_client_item_container_transfer_requested
	):
		game_server.client_item_container_transfer_requested.connect(
			_on_client_item_container_transfer_requested
		)


	if not item_transfer_repository.item_transferred.is_connected(
		_on_item_transferred
	):
		item_transfer_repository.item_transferred.connect(
			_on_item_transferred
		)


	if not item_transfer_repository.item_transfer_failed.is_connected(
		_on_item_transfer_failed
	):
		item_transfer_repository.item_transfer_failed.connect(
			_on_item_transfer_failed
		)


# =========================================================
# WAREHOUSE ACTIVO
# =========================================================

func _is_warehouse_active(
	session: PlayerWorldSession
) -> bool:
	if session == null:
		return false


	return session.is_using_npc_service(
		WAREHOUSE_NPC_ID,
		WAREHOUSE_SERVICE_ID
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
# CLIENT REQUEST — INVENTORY / VAULT
# =========================================================

func _on_client_item_container_transfer_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	source_container: String,
	target_container: String,
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


	# -----------------------------------------------------
	# VAULT SÓLO PUEDE MANIPULARSE DURANTE WAREHOUSE
	# -----------------------------------------------------

	if not _is_warehouse_active(
		session
	):
		print(
			"ItemContainerTransferCoordinator | "
			+
			"Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: servicio Warehouse no activo"
		)


		return


	# -----------------------------------------------------
	# INVENTORY AUTORITATIVO
	# -----------------------------------------------------

	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		print(
			"ItemContainerTransferCoordinator | "
			+
			"Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: Inventory autoritativo no disponible"
		)


		var inventory_reload_result := (
			inventory_repository.load_inventory(
				peer_id,
				session.account_id,
				session.character_id
			)
		)


		if (
			inventory_reload_result != OK
			and
			inventory_reload_result != ERR_BUSY
		):
			game_server.reject_authenticated_peer(
				peer_id,
				"No se pudo recuperar el Inventory persistente."
			)


		return


	# -----------------------------------------------------
	# VAULT AUTORITATIVA
	# -----------------------------------------------------

	var vault_snapshot := (
		session.get_active_vault_snapshot()
	)


	if vault_snapshot.is_empty():
		print(
			"ItemContainerTransferCoordinator | "
			+
			"Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: Vault autoritativa no disponible"
		)


		var vault_reload_result := (
			vault_coordinator.load_active_vault(
				peer_id
			)
		)


		if (
			vault_reload_result != OK
			and
			vault_reload_result != ERR_BUSY
		):
			_request_npc_service_invalidation(
				session,
				"vault_reload_failed"
			)


		return


	# -----------------------------------------------------
	# SIMULAR + VALIDAR AMBOS CONTENEDORES
	# -----------------------------------------------------

	var validation := (
		ServerItemContainerTransferValidator.validate_transfer(
			inventory_snapshot,
			vault_snapshot,
			uid,
			source_container,
			target_container,
			current_position,
			new_position
		)
	)


	if not bool(
		validation.get(
			"ok",
			false
		)
	):
		print(
			"ItemContainerTransferCoordinator | "
			+
			"Transferencia Inventory/Vault rechazada antes del backend",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Desde: ",
			source_container,
			" ",
			current_position,
			" | Hacia: ",
			target_container,
			" ",
			new_position,
			" | Motivo: ",
			validation.get(
				"message",
				"unknown"
			)
		)


		_resend_item_container_snapshots(
			peer_id,
			session,
			inventory_snapshot,
			vault_snapshot
		)


		return


	print(
		"ItemContainerTransferCoordinator | "
		+
		"Transferencia Inventory/Vault validada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" ",
		current_position,
		" | Hacia: ",
		target_container,
		" ",
		new_position
	)


	# -----------------------------------------------------
	# PERSISTENCIA ATÓMICA
	# -----------------------------------------------------

	var transfer_result := (
		item_transfer_repository.transfer_item(
			peer_id,
			session.account_id,
			session.character_id,
			uid,
			source_container,
			target_container,
			current_position,
			new_position
		)
	)


	if transfer_result == OK:
		return


	print(
		"ItemContainerTransferCoordinator | "
		+
		"Transferencia Inventory/Vault no iniciada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Error: ",
		transfer_result
	)


	if transfer_result != ERR_BUSY:
		_resend_item_container_snapshots(
			peer_id,
			session,
			inventory_snapshot,
			vault_snapshot
		)


# =========================================================
# TRANSFERENCIA PERSISTIDA
# =========================================================

func _on_item_transferred(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
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
		"ItemContainerTransferCoordinator | "
		+
		"Transferencia Inventory/Vault persistida",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" | Hacia: ",
		target_container,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	# -----------------------------------------------------
	# No aplicamos snapshots candidatos.
	#
	# Laravel vuelve a ser la fuente definitiva.
	# -----------------------------------------------------

	_reload_item_container_snapshots(
		session
	)


# =========================================================
# TRANSFERENCIA RECHAZADA POR BACKEND
# =========================================================

func _on_item_transfer_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
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
		"ItemContainerTransferCoordinator | "
		+
		"Transferencia Inventory/Vault rechazada por backend",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" | Hacia: ",
		target_container,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	# -----------------------------------------------------
	# Puede ser stale-state, por ejemplo HTTP 409.
	#
	# Recargamos ambos contenedores desde persistencia.
	# -----------------------------------------------------

	_reload_item_container_snapshots(
		session
	)


# =========================================================
# RECARGAR INVENTORY + VAULT
# =========================================================

func _reload_item_container_snapshots(
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


	var inventory_result := (
		inventory_repository.load_inventory(
			session.peer_id,
			session.account_id,
			session.character_id
		)
	)


	if (
		inventory_result != OK
		and
		inventory_result != ERR_BUSY
	):
		game_server.reject_authenticated_peer(
			session.peer_id,
			"No se pudo recargar el Inventory persistente."
		)


		return


	# -----------------------------------------------------
	# Si Warehouse ya terminó mientras la operación HTTP
	# estaba en curso, no volvemos a cargar Vault.
	# -----------------------------------------------------

	if not _is_warehouse_active(
		session
	):
		return


	var vault_result := (
		vault_coordinator.load_active_vault(
			session.peer_id
		)
	)


	if (
		vault_result != OK
		and
		vault_result != ERR_BUSY
	):
		_request_npc_service_invalidation(
			session,
			"vault_reload_failed"
		)


# =========================================================
# REENVIAR SNAPSHOTS AUTORITATIVOS ACTUALES
# =========================================================

func _resend_item_container_snapshots(
	peer_id: int,
	session: PlayerWorldSession,
	inventory_snapshot: Dictionary,
	vault_snapshot: Dictionary
) -> void:
	if session == null:
		return


	if not inventory_snapshot.is_empty():
		var inventory_result := (
			game_server.send_character_inventory_snapshot(
				peer_id,
				inventory_snapshot
			)
		)


		if inventory_result != OK:
			push_warning(
				(
					"ItemContainerTransferCoordinator | "
					+
					"No se pudo reenviar Inventory "
					+
					"después de transferencia. Error: %d"
				)
				%
				inventory_result
			)


	if (
		_is_warehouse_active(
			session
		)
		and
		not vault_snapshot.is_empty()
	):
		var vault_result := (
			game_server.send_vault_snapshot(
				peer_id,
				vault_snapshot
			)
		)


		if vault_result != OK:
			push_warning(
				(
					"ItemContainerTransferCoordinator | "
					+
					"No se pudo reenviar Vault "
					+
					"después de transferencia. Error: %d"
				)
				%
				vault_result
			)
