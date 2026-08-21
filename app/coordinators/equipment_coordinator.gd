class_name EquipmentCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var equipment_repository: BackendCharacterEquipmentRepository = null

var character_item_state_coordinator: CharacterItemStateCoordinator = null


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
	p_equipment_repository: BackendCharacterEquipmentRepository,
	p_character_item_state_coordinator: CharacterItemStateCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_equipment_repository == null:
		return false


	if p_character_item_state_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	equipment_repository = p_equipment_repository

	character_item_state_coordinator = (
		p_character_item_state_coordinator
	)


	_bind_signals()


	configured = true


	print(
		"EquipmentCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_equipment_equip_requested.is_connected(
		_on_client_equipment_equip_requested
	):
		game_server.client_equipment_equip_requested.connect(
			_on_client_equipment_equip_requested
		)


	if not game_server.client_equipment_unequip_requested.is_connected(
		_on_client_equipment_unequip_requested
	):
		game_server.client_equipment_unequip_requested.connect(
			_on_client_equipment_unequip_requested
		)


	if not equipment_repository.equipment_item_equipped.is_connected(
		_on_equipment_item_equipped
	):
		equipment_repository.equipment_item_equipped.connect(
			_on_equipment_item_equipped
		)


	if not equipment_repository.equipment_item_equip_failed.is_connected(
		_on_equipment_item_equip_failed
	):
		equipment_repository.equipment_item_equip_failed.connect(
			_on_equipment_item_equip_failed
		)


	if not equipment_repository.equipment_item_unequipped.is_connected(
		_on_equipment_item_unequipped
	):
		equipment_repository.equipment_item_unequipped.connect(
			_on_equipment_item_unequipped
		)


	if not equipment_repository.equipment_item_unequip_failed.is_connected(
		_on_equipment_item_unequip_failed
	):
		equipment_repository.equipment_item_unequip_failed.connect(
			_on_equipment_item_unequip_failed
		)


# =========================================================
# REQUEST AUTORITATIVO — EQUIP
# =========================================================

func _request_equipment_equip(
	peer_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: Variant
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if (
		inventory_snapshot.is_empty()
		or
		equipment_snapshot.is_empty()
	):
		return ERR_UNAVAILABLE


	var validation_result := (
		ServerEquipmentTransferValidator.validate_equip(
			inventory_snapshot,
			equipment_snapshot,
			uid,
			current_position,
			equipment_slot
		)
	)


	if not bool(
		validation_result.get(
			"ok",
			false
		)
	):
		print(
			"EquipmentCoordinator | Equip rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Slot: ",
			equipment_slot,
			" | Motivo: ",
			validation_result.get(
				"message",
				"unknown"
			)
		)


		return ERR_INVALID_DATA


	return equipment_repository.equip_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_position,
		equipment_slot
	)


# =========================================================
# REQUEST AUTORITATIVO — UNEQUIP
# =========================================================

func _request_equipment_unequip(
	peer_id: int,
	uid: String,
	current_equipment_slot: Variant,
	new_position: Vector2i
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if (
		inventory_snapshot.is_empty()
		or
		equipment_snapshot.is_empty()
	):
		return ERR_UNAVAILABLE


	var validation_result := (
		ServerEquipmentTransferValidator.validate_unequip(
			inventory_snapshot,
			equipment_snapshot,
			uid,
			current_equipment_slot,
			new_position
		)
	)


	if not bool(
		validation_result.get(
			"ok",
			false
		)
	):
		print(
			"EquipmentCoordinator | Unequip rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Slot: ",
			current_equipment_slot,
			" | Destino: ",
			new_position,
			" | Motivo: ",
			validation_result.get(
				"message",
				"unknown"
			)
		)


		return ERR_INVALID_DATA


	return equipment_repository.unequip_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_equipment_slot,
		new_position
	)


# =========================================================
# CLIENT REQUEST — EQUIP
# =========================================================

func _on_client_equipment_equip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: String
) -> void:
	var result := (
		_request_equipment_equip(
			peer_id,
			uid,
			current_position,
			equipment_slot
		)
	)


	print(
		"EquipmentCoordinator | Solicitud Equip procesada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		equipment_slot,
		" | Resultado: ",
		result
	)


	if (
		result == OK
		or
		result == ERR_BUSY
	):
		return


	character_item_state_coordinator.resend_snapshots(
		peer_id
	)


# =========================================================
# CLIENT REQUEST — UNEQUIP
# =========================================================

func _on_client_equipment_unequip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_equipment_slot: String,
	new_position: Vector2i
) -> void:
	var result := (
		_request_equipment_unequip(
			peer_id,
			uid,
			current_equipment_slot,
			new_position
		)
	)


	print(
		"EquipmentCoordinator | Solicitud Unequip procesada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		current_equipment_slot,
		" | Destino: ",
		new_position,
		" | Resultado: ",
		result
	)


	if (
		result == OK
		or
		result == ERR_BUSY
	):
		return


	character_item_state_coordinator.resend_snapshots(
		peer_id
	)


# =========================================================
# BACKEND — ITEM EQUIPADO
# =========================================================

func _on_equipment_item_equipped(
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
		"EquipmentCoordinator | Item equipado y persistido",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		item.get(
			"equipment_slot",
			"?"
		)
	)


	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"equip_persisted"
	)


# =========================================================
# BACKEND — EQUIP RECHAZADO
# =========================================================

func _on_equipment_item_equip_failed(
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
		"EquipmentCoordinator | Equip persistente rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"equip_rejected"
	)


# =========================================================
# BACKEND — ITEM DESEQUIPADO
# =========================================================

func _on_equipment_item_unequipped(
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
		"EquipmentCoordinator | Item desequipado y persistido",
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


	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"unequip_persisted"
	)


# =========================================================
# BACKEND — UNEQUIP RECHAZADO
# =========================================================

func _on_equipment_item_unequip_failed(
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
		"EquipmentCoordinator | Unequip persistente rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"unequip_rejected"
	)
