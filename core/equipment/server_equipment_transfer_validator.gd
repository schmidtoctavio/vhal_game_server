class_name ServerEquipmentTransferValidator
extends RefCounted


# =========================================================
# CONTENEDORES
# =========================================================

const INVENTORY_CONTAINER: String = "inventory"

const EQUIPMENT_CONTAINER: String = "equipment"


# =========================================================
# EQUIPAR INVENTORY -> EQUIPMENT
# =========================================================

static func validate_equip(
	inventory_snapshot: Dictionary,
	equipment_snapshot: Dictionary,
	uid: String,
	current_position: Vector2i,
	equipment_slot: Variant
) -> Dictionary:
	var context_error := (
		_validate_snapshot_context(
			inventory_snapshot,
			equipment_snapshot
		)
	)


	if not context_error.is_empty():
		return _failure(
			context_error
		)


	var normalized_uid := (
		uid.strip_edges()
	)


	if normalized_uid.is_empty():
		return _failure(
			"uid vacío"
		)


	var normalized_slot := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			equipment_slot
		)
	)


	if not ServerEquipmentSlotCatalog.is_valid_slot_id(
		normalized_slot
	):
		return _failure(
			"equipment_slot inválido"
		)


	# -----------------------------------------------------
	# COPIAS CANDIDATAS
	# -----------------------------------------------------

	var inventory_candidate := (
		inventory_snapshot.duplicate(
			true
		)
	)


	var equipment_candidate := (
		equipment_snapshot.duplicate(
			true
		)
	)


	var inventory_items: Array = (
		inventory_candidate.get(
			"items",
			[]
		)
	)


	var equipment_items: Array = (
		equipment_candidate.get(
			"items",
			[]
		)
	)


	# -----------------------------------------------------
	# LOCALIZAR ITEM EN INVENTORY
	# -----------------------------------------------------

	var source_index: int = -1

	var moved_item: Dictionary = {}


	for index in range(
		inventory_items.size()
	):
		var item_value: Variant = (
			inventory_items[
				index
			]
		)


		if typeof(item_value) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en Inventory"
			)


		var item: Dictionary = (
			item_value
		)


		if String(
			item.get(
				"uid",
				""
			)
		).strip_edges() != normalized_uid:
			continue


		source_index = index

		moved_item = item.duplicate(
			true
		)


		break


	if source_index < 0:
		return _failure(
			(
				"uid no encontrado en Inventory: "
				+
				normalized_uid
			)
		)


	# -----------------------------------------------------
	# SOURCE STALE
	# -----------------------------------------------------

	var current_position_value: Variant = (
		moved_item.get(
			"grid_position",
			null
		)
	)


	if (
		typeof(current_position_value)
		!=
		TYPE_DICTIONARY
	):
		return _failure(
			"grid_position actual inválida"
		)


	var stored_position: Dictionary = (
		current_position_value
	)


	var stored_grid_position := Vector2i(
		int(
			stored_position.get(
				"x",
				-1
			)
		),
		int(
			stored_position.get(
				"y",
				-1
			)
		)
	)


	if stored_grid_position != current_position:
		return _failure(
			"posición actual del item no coincide"
		)


	# -----------------------------------------------------
	# DEFINITION
	# -----------------------------------------------------

	var item_id := String(
		moved_item.get(
			"item_id",
			""
		)
	).strip_edges()


	var definition := (
		ServerItemCatalog.get_definition(
			item_id
		)
	)


	if definition.is_empty():
		return _failure(
			(
				"item_id desconocido: "
				+
				item_id
			)
		)


	if not ServerEquipmentRules.is_equipment_definition(
		definition
	):
		return _failure(
			(
				"item no es Equipment: "
				+
				item_id
			)
		)


	if not ServerEquipmentRules.can_definition_use_slot(
		definition,
		normalized_slot
	):
		return _failure(
			(
				"item incompatible con slot: "
				+
				item_id
				+
				" -> "
				+
				String(normalized_slot)
			)
		)


	# -----------------------------------------------------
	# UID NO PUEDE EXISTIR YA EN EQUIPMENT
	# -----------------------------------------------------

	for equipment_item_value: Variant in equipment_items:
		if typeof(
			equipment_item_value
		) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en Equipment"
			)


		var equipment_item: Dictionary = (
			equipment_item_value
		)


		if String(
			equipment_item.get(
				"uid",
				""
			)
		).strip_edges() == normalized_uid:
			return _failure(
				"uid ya existe en Equipment"
			)


	# -----------------------------------------------------
	# SIMULAR
	# -----------------------------------------------------

	inventory_items.remove_at(
		source_index
	)


	moved_item.erase(
		"grid_position"
	)


	moved_item[
		"equipment_slot"
	] = String(
		normalized_slot
	)


	equipment_items.append(
		moved_item
	)


	inventory_candidate[
		"items"
	] = inventory_items


	equipment_candidate[
		"items"
	] = equipment_items


	# -----------------------------------------------------
	# VALIDAR ESTADO RESULTANTE
	# -----------------------------------------------------

	var inventory_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_candidate
		)
	)


	if not inventory_error.is_empty():
		return _failure(
			(
				"equip dejaría Inventory inválido: "
				+
				inventory_error
			)
		)


	var equipment_error := (
		ServerEquipmentSnapshotValidator.validate(
			equipment_candidate
		)
	)


	if not equipment_error.is_empty():
		return _failure(
			(
				"equip dejaría Equipment inválido: "
				+
				equipment_error
			)
		)


	return _success(
		moved_item,
		inventory_candidate,
		equipment_candidate
	)


# =========================================================
# DESEQUIPAR EQUIPMENT -> INVENTORY
# =========================================================

static func validate_unequip(
	inventory_snapshot: Dictionary,
	equipment_snapshot: Dictionary,
	uid: String,
	current_equipment_slot: Variant,
	new_position: Vector2i
) -> Dictionary:
	var context_error := (
		_validate_snapshot_context(
			inventory_snapshot,
			equipment_snapshot
		)
	)


	if not context_error.is_empty():
		return _failure(
			context_error
		)


	var normalized_uid := (
		uid.strip_edges()
	)


	if normalized_uid.is_empty():
		return _failure(
			"uid vacío"
		)


	var normalized_slot := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			current_equipment_slot
		)
	)


	if not ServerEquipmentSlotCatalog.is_valid_slot_id(
		normalized_slot
	):
		return _failure(
			"equipment_slot actual inválido"
		)


	var inventory_candidate := (
		inventory_snapshot.duplicate(
			true
		)
	)


	var equipment_candidate := (
		equipment_snapshot.duplicate(
			true
		)
	)


	var inventory_items: Array = (
		inventory_candidate.get(
			"items",
			[]
		)
	)


	var equipment_items: Array = (
		equipment_candidate.get(
			"items",
			[]
		)
	)


	# -----------------------------------------------------
	# LOCALIZAR ITEM EN EQUIPMENT
	# -----------------------------------------------------

	var source_index: int = -1

	var moved_item: Dictionary = {}


	for index in range(
		equipment_items.size()
	):
		var item_value: Variant = (
			equipment_items[
				index
			]
		)


		if typeof(item_value) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en Equipment"
			)


		var item: Dictionary = (
			item_value
		)


		if String(
			item.get(
				"uid",
				""
			)
		).strip_edges() != normalized_uid:
			continue


		source_index = index

		moved_item = item.duplicate(
			true
		)


		break


	if source_index < 0:
		return _failure(
			(
				"uid no encontrado en Equipment: "
				+
				normalized_uid
			)
		)


	# -----------------------------------------------------
	# SOURCE STALE
	# -----------------------------------------------------

	var stored_slot := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			moved_item.get(
				"equipment_slot",
				""
			)
		)
	)


	if stored_slot != normalized_slot:
		return _failure(
			"equipment_slot actual del item no coincide"
		)


	# -----------------------------------------------------
	# UID NO PUEDE EXISTIR YA EN INVENTORY
	# -----------------------------------------------------

	for inventory_item_value: Variant in inventory_items:
		if typeof(
			inventory_item_value
		) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en Inventory"
			)


		var inventory_item: Dictionary = (
			inventory_item_value
		)


		if String(
			inventory_item.get(
				"uid",
				""
			)
		).strip_edges() == normalized_uid:
			return _failure(
				"uid ya existe en Inventory"
			)


	# -----------------------------------------------------
	# SIMULAR
	# -----------------------------------------------------

	equipment_items.remove_at(
		source_index
	)


	moved_item.erase(
		"equipment_slot"
	)


	moved_item[
		"grid_position"
	] = {
		"x": new_position.x,
		"y": new_position.y,
	}


	inventory_items.append(
		moved_item
	)


	equipment_candidate[
		"items"
	] = equipment_items


	inventory_candidate[
		"items"
	] = inventory_items


	# -----------------------------------------------------
	# VALIDAR RESULTADO
	# -----------------------------------------------------

	var equipment_error := (
		ServerEquipmentSnapshotValidator.validate(
			equipment_candidate
		)
	)


	if not equipment_error.is_empty():
		return _failure(
			(
				"unequip dejaría Equipment inválido: "
				+
				equipment_error
			)
		)


	var inventory_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_candidate
		)
	)


	if not inventory_error.is_empty():
		return _failure(
			(
				"unequip dejaría Inventory inválido: "
				+
				inventory_error
			)
		)


	return _success(
		moved_item,
		inventory_candidate,
		equipment_candidate
	)


# =========================================================
# CONTEXTO COMÚN
# =========================================================

static func _validate_snapshot_context(
	inventory_snapshot: Dictionary,
	equipment_snapshot: Dictionary
) -> String:
	var inventory_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_snapshot
		)
	)


	if not inventory_error.is_empty():
		return (
			"Inventory autoritativo inválido: "
			+
			inventory_error
		)


	var equipment_error := (
		ServerEquipmentSnapshotValidator.validate(
			equipment_snapshot
		)
	)


	if not equipment_error.is_empty():
		return (
			"Equipment autoritativo inválido: "
			+
			equipment_error
		)


	var inventory_account_id := int(
		inventory_snapshot.get(
			"account_id",
			0
		)
	)


	var equipment_account_id := int(
		equipment_snapshot.get(
			"account_id",
			0
		)
	)


	if (
		inventory_account_id
		!=
		equipment_account_id
	):
		return (
			"Inventory y Equipment pertenecen "
			+
			"a cuentas diferentes"
		)


	var inventory_character_id := int(
		inventory_snapshot.get(
			"character_id",
			0
		)
	)


	var equipment_character_id := int(
		equipment_snapshot.get(
			"character_id",
			0
		)
	)


	if (
		inventory_character_id
		!=
		equipment_character_id
	):
		return (
			"Inventory y Equipment pertenecen "
			+
			"a personajes diferentes"
		)


	# -----------------------------------------------------
	# PROHIBIR UID REPETIDO ENTRE CONTENEDORES
	# -----------------------------------------------------

	var inventory_uids: Dictionary = {}


	var inventory_items: Array = (
		inventory_snapshot.get(
			"items",
			[]
		)
	)


	for item_value: Variant in inventory_items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "item inválido en Inventory"


		var item: Dictionary = (
			item_value
		)


		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		inventory_uids[
			uid
		] = true


	var equipment_items: Array = (
		equipment_snapshot.get(
			"items",
			[]
		)
	)


	for item_value: Variant in equipment_items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "item inválido en Equipment"


		var item: Dictionary = (
			item_value
		)


		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		if inventory_uids.has(
			uid
		):
			return (
				"uid presente simultáneamente "
				+
				"en Inventory y Equipment: "
				+
				uid
			)


	return ""


# =========================================================
# SELF TEST
# =========================================================

static func validate_contract() -> String:
	var inventory := {
		"account_id": 1,
		"character_id": 1,
		"container": "inventory",

		"items": [
			{
				"uid": "test-sword",
				"item_id": "bronze_sword",
				"quantity": 1,

				"grid_position": {
					"x": 0,
					"y": 0,
				},

				"state": {},
			},

			{
				"uid": "test-potion",
				"item_id": "health_potion",
				"quantity": 1,

				"grid_position": {
					"x": 2,
					"y": 0,
				},

				"state": {},
			},

			{
				"uid": "test-helmet",
				"item_id": "leather_helmet",
				"quantity": 1,

				"grid_position": {
					"x": 3,
					"y": 0,
				},

				"state": {},
			},
		],
	}


	var equipment := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",
		"items": [],
	}


	# -----------------------------------------------------
	# SWORD -> MAIN HAND
	# -----------------------------------------------------

	var sword_result := (
		validate_equip(
			inventory,
			equipment,
			"test-sword",
			Vector2i(
				0,
				0
			),
			ServerEquipmentSlotCatalog.MAIN_HAND
		)
	)


	if not bool(
		sword_result.get(
			"ok",
			false
		)
	):
		return (
			"self-test sword/main_hand falló: "
			+
			String(
				sword_result.get(
					"message",
					""
				)
			)
		)


	# -----------------------------------------------------
	# POTION -> MAIN HAND DEBE FALLAR
	# -----------------------------------------------------

	var potion_result := (
		validate_equip(
			inventory,
			equipment,
			"test-potion",
			Vector2i(
				2,
				0
			),
			ServerEquipmentSlotCatalog.MAIN_HAND
		)
	)


	if bool(
		potion_result.get(
			"ok",
			false
		)
	):
		return (
			"self-test permitió equipar "
			+
			"health_potion"
		)


	# -----------------------------------------------------
	# HELMET -> HEAD
	# -----------------------------------------------------

	var helmet_result := (
		validate_equip(
			inventory,
			equipment,
			"test-helmet",
			Vector2i(
				3,
				0
			),
			ServerEquipmentSlotCatalog.HEAD
		)
	)


	if not bool(
		helmet_result.get(
			"ok",
			false
		)
	):
		return (
			"self-test helmet/head falló: "
			+
			String(
				helmet_result.get(
					"message",
					""
				)
			)
		)


	# -----------------------------------------------------
	# SWORD -> HEAD DEBE FALLAR
	# -----------------------------------------------------

	var wrong_slot_result := (
		validate_equip(
			inventory,
			equipment,
			"test-sword",
			Vector2i(
				0,
				0
			),
			ServerEquipmentSlotCatalog.HEAD
		)
	)


	if bool(
		wrong_slot_result.get(
			"ok",
			false
		)
	):
		return (
			"self-test permitió sword -> head"
		)


	# -----------------------------------------------------
	# UNEQUIP RESULTANTE
	# -----------------------------------------------------

	var equipped_inventory: Dictionary = (
		sword_result.get(
			"inventory_snapshot",
			{}
		)
	)


	var equipped_equipment: Dictionary = (
		sword_result.get(
			"equipment_snapshot",
			{}
		)
	)


	var unequip_result := (
		validate_unequip(
			equipped_inventory,
			equipped_equipment,
			"test-sword",
			ServerEquipmentSlotCatalog.MAIN_HAND,
			Vector2i(
				5,
				5
			)
		)
	)


	if not bool(
		unequip_result.get(
			"ok",
			false
		)
	):
		return (
			"self-test unequip falló: "
			+
			String(
				unequip_result.get(
					"message",
					""
				)
			)
		)


	return ""


# =========================================================
# RESULTADOS
# =========================================================

static func _success(
	item: Dictionary,
	inventory_snapshot: Dictionary,
	equipment_snapshot: Dictionary
) -> Dictionary:
	return {
		"ok": true,

		"message": "",

		"item": item.duplicate(
			true
		),

		"inventory_snapshot": (
			inventory_snapshot.duplicate(
				true
			)
		),

		"equipment_snapshot": (
			equipment_snapshot.duplicate(
				true
			)
		),
	}


static func _failure(
	message: String
) -> Dictionary:
	return {
		"ok": false,

		"message": message,

		"item": {},

		"inventory_snapshot": {},

		"equipment_snapshot": {},
	}
