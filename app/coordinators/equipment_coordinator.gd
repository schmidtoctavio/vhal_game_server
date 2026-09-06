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

	if not equipment_repository.equipment_item_enhanced.is_connected(
		_on_equipment_item_enhanced
	):
		equipment_repository.equipment_item_enhanced.connect(
			_on_equipment_item_enhanced
		)


	if not equipment_repository.equipment_item_enhance_failed.is_connected(
		_on_equipment_item_enhance_failed
	):
		equipment_repository.equipment_item_enhance_failed.connect(
			_on_equipment_item_enhance_failed
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

	# -----------------------------------------------------
	# USAGE ELIGIBILITY
	#
	# El Transfer Validator ya resolvió estructuralmente
	# qué item sería movido a Equipment.
	#
	# Ahora validamos si ESTE personaje puede utilizar
	# ESTA instancia concreta.
	#
	# Se contemplan:
	#
	# - Class
	# - Level
	# - Enhancement Level
	# - Permanent STR
	# - Permanent AGI
	# - Permanent VIT
	# - Permanent ENE
	#
	# Nunca Effective Primary.
	# -----------------------------------------------------

	var moved_item_value: Variant = (
		validation_result.get(
			"item",
			null
		)
	)


	if typeof(
		moved_item_value
	) != TYPE_DICTIONARY:
		print(
			"EquipmentCoordinator | "
			+
			"Equip rechazado por item resuelto inválido",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid
		)


		return ERR_INVALID_DATA


	var moved_item: Dictionary = (
		moved_item_value as Dictionary
	)


	var usage_error := (
		ServerEquipmentUsageRules
		.validate_item_usage(
			moved_item,
			session.primary_stats
		)
	)


	if not usage_error.is_empty():
		print(
			"EquipmentCoordinator | "
			+
			"Equip rechazado por Usage Eligibility",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Item: ",
			moved_item.get(
				"item_id",
				"?"
			),
			" | Slot: ",
			equipment_slot,
			" | Motivo: ",
			usage_error
		)


		return ERR_INVALID_DATA


	print(
		"EquipmentCoordinator | "
		+
		"Usage Eligibility validada",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Item: ",
		moved_item.get(
			"item_id",
			"?"
		),
		" | Slot: ",
		equipment_slot
	)


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
# REQUEST AUTORITATIVO — ENHANCEMENT
# =========================================================

func _request_equipment_enhancement(
	peer_id: int,
	uid: String
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var normalized_uid := (
		uid.strip_edges()
	)


	if normalized_uid.is_empty():
		return ERR_INVALID_PARAMETER


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


	# -----------------------------------------------------
	# SOURCE AUTORITATIVO
	#
	# El caller NO decide dónde está el item.
	#
	# Inventory / Equipment se resuelven desde la sesión
	# autoritativa actual.
	# -----------------------------------------------------

	var inventory_item := (
		_find_item_in_snapshot(
			inventory_snapshot,
			normalized_uid
		)
	)


	var equipment_item := (
		_find_item_in_snapshot(
			equipment_snapshot,
			normalized_uid
		)
	)


	var found_in_inventory := (
		not inventory_item.is_empty()
	)


	var found_in_equipment := (
		not equipment_item.is_empty()
	)


	# -----------------------------------------------------
	# EXACTAMENTE UN SOURCE
	#
	# false / false:
	#   UID inexistente.
	#
	# true / true:
	#   corrupción de snapshots.
	# -----------------------------------------------------

	if found_in_inventory == found_in_equipment:
		print(
			"EquipmentCoordinator | "
			+
			"Enhancement rechazado por source inválido",
			" | Peer: ",
			peer_id,
			" | UID: ",
			normalized_uid,
			" | Inventory: ",
			found_in_inventory,
			" | Equipment: ",
			found_in_equipment
		)


		return ERR_INVALID_DATA


	var source_container := "inventory"

	var current_item := inventory_item


	if found_in_equipment:
		source_container = "equipment"

		current_item = equipment_item


	# -----------------------------------------------------
	# TRANSICIÓN DETERMINISTA
	#
	# +N
	# →
	# +(N + 1)
	#
	# Todavía NO mutamos sesión.
	# -----------------------------------------------------

	var transition_result := (
		ServerEquipmentEnhancementTransitionRules
		.build_next_level_candidate(
			current_item
		)
	)


	if not bool(
		transition_result.get(
			ServerEquipmentEnhancementTransitionRules.OK_KEY,
			false
		)
	):
		print(
			"EquipmentCoordinator | "
			+
			"Enhancement rechazado por Transition Rules",
			" | Peer: ",
			peer_id,
			" | UID: ",
			normalized_uid,
			" | Container: ",
			source_container,
			" | Motivo: ",
			transition_result.get(
				ServerEquipmentEnhancementTransitionRules.MESSAGE_KEY,
				"unknown"
			)
		)


		return ERR_INVALID_DATA


	var candidate_value: Variant = (
		transition_result.get(
			ServerEquipmentEnhancementTransitionRules.ITEM_KEY,
			null
		)
	)


	if typeof(candidate_value) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA


	var candidate: Dictionary = (
		candidate_value as Dictionary
	)


	var current_level := int(
		transition_result.get(
			ServerEquipmentEnhancementTransitionRules.CURRENT_LEVEL_KEY,
			-1
		)
	)


	var next_level := int(
		transition_result.get(
			ServerEquipmentEnhancementTransitionRules.NEXT_LEVEL_KEY,
			-1
		)
	)


	if (
		current_level < 0
		or
		next_level != current_level + 1
	):
		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# EQUIPPED CANDIDATE USAGE ELIGIBILITY
	#
	# Un Enhancement puede aumentar Requirements.
	#
	# No permitimos persistir un item actualmente equipado
	# en un estado que el personaje ya no pueda utilizar.
	#
	# Inventory no necesita esta validación porque poseer
	# un item no implica poder equiparlo.
	# -----------------------------------------------------

	if source_container == "equipment":
		var usage_error := (
			ServerEquipmentUsageRules
			.validate_item_usage(
				candidate,
				session.primary_stats
			)
		)


		if not usage_error.is_empty():
			print(
				"EquipmentCoordinator | "
				+
				"Enhancement equipado rechazado por Usage Eligibility",
				" | Peer: ",
				peer_id,
				" | UID: ",
				normalized_uid,
				" | Level: ",
				current_level,
				" -> ",
				next_level,
				" | Motivo: ",
				usage_error
			)


			return ERR_INVALID_DATA


	print(
		"EquipmentCoordinator | "
		+
		"Enhancement candidato validado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		normalized_uid,
		" | Container: ",
		source_container,
		" | Level: ",
		current_level,
		" -> ",
		next_level
	)


	# -----------------------------------------------------
	# PERSISTENCIA DURABLE
	#
	# Laravel recibe el nivel esperado actual para poder
	# detectar estado stale bajo lockForUpdate().
	#
	# La sesión NO se modifica hasta el reload posterior.
	# -----------------------------------------------------

	return equipment_repository.enhance_item(
		peer_id,
		session.account_id,
		session.character_id,
		normalized_uid,
		source_container,
		current_level,
		next_level
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

# =========================================================
# ITEM LOOKUP
# =========================================================

func _find_item_in_snapshot(
	snapshot: Dictionary,
	uid: String
) -> Dictionary:
	if snapshot.is_empty():
		return {}


	var normalized_uid := (
		uid.strip_edges()
	)


	if normalized_uid.is_empty():
		return {}


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return {}


	var items: Array = (
		items_value as Array
	)


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			continue


		var item: Dictionary = (
			item_value as Dictionary
		)


		var item_uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		if item_uid != normalized_uid:
			continue


		return item.duplicate(
			true
		)


	return {}

# =========================================================
# BACKEND — ITEM MEJORADO
# =========================================================

func _on_equipment_item_enhanced(
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


	var enhancement_level := -1


	var state_value: Variant = (
		item.get(
			"state",
			null
		)
	)


	if typeof(state_value) == TYPE_DICTIONARY:
		var state: Dictionary = (
			state_value as Dictionary
		)


		enhancement_level = int(
			state.get(
				"enhancement_level",
				-1
			)
		)


	print(
		"EquipmentCoordinator | "
		+
		"Item mejorado y persistido",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Level: ",
		enhancement_level
	)


	# -----------------------------------------------------
	# SOURCE OF TRUTH
	#
	# No aplicamos el item retornado directamente sobre
	# la sesión.
	#
	# Recargamos los snapshots completos desde Laravel.
	# -----------------------------------------------------

	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"enhancement_persisted"
	)


# =========================================================
# BACKEND — ENHANCEMENT RECHAZADO
# =========================================================

func _on_equipment_item_enhance_failed(
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
		"EquipmentCoordinator | "
		+
		"Enhancement persistente rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	# Un rechazo puede significar source stale.
	# Recargamos para reconciliar la sesión con DB.

	character_item_state_coordinator.reload_snapshots(
		peer_id,
		"enhancement_rejected"
	)
