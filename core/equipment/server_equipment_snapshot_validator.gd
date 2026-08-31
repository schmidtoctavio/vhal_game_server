class_name ServerEquipmentSnapshotValidator
extends RefCounted


# =========================================================
# VALIDAR SNAPSHOT
# =========================================================

static func validate(
	snapshot: Dictionary
) -> String:
	var account_id := int(
		snapshot.get(
			"account_id",
			0
		)
	)


	if account_id <= 0:
		return "account_id inválido"


	var character_id := int(
		snapshot.get(
			"character_id",
			0
		)
	)


	if character_id <= 0:
		return "character_id inválido"


	var container := String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges()


	if container != "equipment":
		return "container inválido"


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return "items inválido"


	var items: Array = (
		items_value as Array
	)


	var known_uids: Dictionary = {}

	var items_by_slot: Dictionary = {}

	var definitions_by_slot: Dictionary = {}


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "item inválido"


		var item: Dictionary = (
			item_value
		)


		# -------------------------------------------------
		# UID
		# -------------------------------------------------

		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		if uid.is_empty():
			return "item sin uid"


		if known_uids.has(
			uid
		):
			return (
				"uid duplicado: "
				+
				uid
			)


		known_uids[
			uid
		] = true


		# -------------------------------------------------
		# ITEM ID / DEFINITION
		# -------------------------------------------------

		var item_id := String(
			item.get(
				"item_id",
				""
			)
		).strip_edges()


		if item_id.is_empty():
			return (
				"item sin item_id: "
				+
				uid
			)


		var definition := (
			ServerItemCatalog.get_definition(
				item_id
			)
		)


		if definition.is_empty():
			return (
				"item_id desconocido: "
				+
				item_id
			)


		if not ServerEquipmentRules.is_equipment_definition(
			definition
		):
			return (
				"item no es Equipment: "
				+
				item_id
			)

		var enhancement_state_error := (
			ServerEquipmentEnhancementInstanceRules
			.validate_item_instance(
				item,
				definition
			)
		)


		if not enhancement_state_error.is_empty():
			return (
				"estado Enhancement inválido: "
				+
				uid
				+
				" | "
				+
				enhancement_state_error
			)

		# -------------------------------------------------
		# QUANTITY
		# -------------------------------------------------

		var quantity := int(
			item.get(
				"quantity",
				0
			)
		)


		if quantity != 1:
			return (
				"cantidad de Equipment inválida: "
				+
				uid
			)


		if int(
			definition.get(
				"max_stack",
				1
			)
		) != 1:
			return (
				"definición Equipment stackable no soportada: "
				+
				item_id
			)


		# -------------------------------------------------
		# EQUIPMENT SLOT
		# -------------------------------------------------

		var raw_slot_id := String(
			item.get(
				"equipment_slot",
				""
			)
		).strip_edges()


		var slot_id := (
			ServerEquipmentSlotCatalog.normalize_slot_id(
				raw_slot_id
			)
		)


		if not ServerEquipmentSlotCatalog.is_valid_slot_id(
			slot_id
		):
			return (
				"equipment_slot inválido: "
				+
				raw_slot_id
			)


		if raw_slot_id != String(
			slot_id
		):
			return (
				"equipment_slot no canónico: "
				+
				raw_slot_id
			)


		if items_by_slot.has(
			slot_id
		):
			return (
				"slot duplicado: "
				+
				raw_slot_id
			)


		if not ServerEquipmentRules.can_definition_use_slot(
			definition,
			slot_id
		):
			return (
				"item incompatible con slot: "
				+
				item_id
				+
				" -> "
				+
				raw_slot_id
			)


		# -------------------------------------------------
		# EQUIPMENT NO USA GRID POSITION
		# -------------------------------------------------

		if item.has(
			"grid_position"
		):
			return (
				"Equipment contiene grid_position: "
				+
				uid
			)


		items_by_slot[
			slot_id
		] = item


		definitions_by_slot[
			slot_id
		] = definition


	# =====================================================
	# RESERVAS DERIVADAS
	# =====================================================

	for slot_value: Variant in items_by_slot.keys():
		var slot_id := (
			ServerEquipmentSlotCatalog.normalize_slot_id(
				slot_value
			)
		)


		var definition: Dictionary = (
			definitions_by_slot[
				slot_value
			]
		)


		var reserved_slots := (
			ServerEquipmentRules.get_reserved_slot_ids(
				definition,
				slot_id
			)
		)


		for reserved_slot: StringName in reserved_slots:
			if items_by_slot.has(
				reserved_slot
			):
				return (
					"slot reservado ocupado: "
					+
					String(reserved_slot)
				)


	return ""

# =========================================================
# SELF TEST
# =========================================================

static func validate_contract() -> String:
	# =====================================================
	# SNAPSHOT VACÍO VÁLIDO
	# =====================================================

	var empty_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",
		"items": [],
	}


	var empty_error := validate(
		empty_snapshot
	)


	if not empty_error.is_empty():
		return (
			"snapshot vacío válido rechazado: "
			+
			empty_error
		)


	# =====================================================
	# SWORD -> MAIN_HAND VÁLIDO
	# =====================================================

	var sword_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-sword",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},
		],
	}


	var sword_error := validate(
		sword_snapshot
	)


	if not sword_error.is_empty():
		return (
			"snapshot sword/main_hand válido rechazado: "
			+
			sword_error
		)


	# =====================================================
	# HELMET -> HEAD VÁLIDO
	# =====================================================

	var helmet_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-helmet",
				"item_id": "leather_helmet",
				"quantity": 1,
				"equipment_slot": "head",
				"state": {},
			},
		],
	}


	var helmet_error := validate(
		helmet_snapshot
	)


	if not helmet_error.is_empty():
		return (
			"snapshot helmet/head válido rechazado: "
			+
			helmet_error
		)


	# =====================================================
	# HEALTH POTION NO PUEDE EXISTIR EN EQUIPMENT
	# =====================================================

	var potion_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-potion",
				"item_id": "health_potion",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},
		],
	}


	if validate(
		potion_snapshot
	).is_empty():
		return (
			"snapshot permitió health_potion en Equipment"
		)


	# =====================================================
	# ITEM ID DESCONOCIDO
	# =====================================================

	var unknown_item_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-unknown-item",
				"item_id": "item_that_does_not_exist",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},
		],
	}


	if validate(
		unknown_item_snapshot
	).is_empty():
		return (
			"snapshot permitió item_id desconocido"
		)


	# =====================================================
	# EQUIPMENT SIEMPRE QUANTITY = 1
	# =====================================================

	var invalid_quantity_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-stacked-sword",
				"item_id": "bronze_sword",
				"quantity": 2,
				"equipment_slot": "main_hand",
				"state": {},
			},
		],
	}


	if validate(
		invalid_quantity_snapshot
	).is_empty():
		return (
			"snapshot permitió Equipment con quantity != 1"
		)


	# =====================================================
	# SLOT INEXISTENTE
	# =====================================================

	var invalid_slot_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-invalid-slot",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "third_hand",
				"state": {},
			},
		],
	}


	if validate(
		invalid_slot_snapshot
	).is_empty():
		return (
			"snapshot permitió equipment_slot inexistente"
		)


	# =====================================================
	# SLOT DEBE USAR SU ID CANÓNICO
	#
	# normalize_slot_id() acepta MAIN_HAND como equivalente
	# lógico, pero persistencia/networking debe conservar
	# exactamente "main_hand".
	# =====================================================

	var non_canonical_slot_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-non-canonical-slot",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "MAIN_HAND",
				"state": {},
			},
		],
	}


	if validate(
		non_canonical_slot_snapshot
	).is_empty():
		return (
			"snapshot permitió equipment_slot no canónico"
		)


	# =====================================================
	# UID DUPLICADO DENTRO DE EQUIPMENT
	# =====================================================

	var duplicated_uid_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-duplicate",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},

			{
				"uid": "snapshot-duplicate",
				"item_id": "leather_helmet",
				"quantity": 1,
				"equipment_slot": "head",
				"state": {},
			},
		],
	}


	if validate(
		duplicated_uid_snapshot
	).is_empty():
		return (
			"snapshot permitió UID duplicado"
		)


	# =====================================================
	# DOS ITEMS NO PUEDEN OCUPAR EL MISMO SLOT
	# =====================================================

	var duplicated_slot_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-main-hand-a",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},

			{
				"uid": "snapshot-main-hand-b",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "main_hand",
				"state": {},
			},
		],
	}


	if validate(
		duplicated_slot_snapshot
	).is_empty():
		return (
			"snapshot permitió slot duplicado"
		)


	# =====================================================
	# ITEM / SLOT INCOMPATIBLE
	# =====================================================

	var incompatible_slot_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-sword-on-head",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "head",
				"state": {},
			},
		],
	}


	if validate(
		incompatible_slot_snapshot
	).is_empty():
		return (
			"snapshot permitió sword -> head"
		)


	# =====================================================
	# EQUIPMENT NO PUEDE CONSERVAR GRID_POSITION
	# =====================================================

	var grid_position_snapshot := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-grid-position",
				"item_id": "bronze_sword",
				"quantity": 1,
				"equipment_slot": "main_hand",

				"grid_position": {
					"x": 0,
					"y": 0,
				},

				"state": {},
			},
		],
	}


	if validate(
		grid_position_snapshot
	).is_empty():
		return (
			"snapshot permitió grid_position en Equipment"
		)


	# =====================================================
	# CONTEXTO ESTRUCTURAL
	# =====================================================

	var invalid_account_snapshot := (
		empty_snapshot.duplicate(
			true
		)
	)


	invalid_account_snapshot[
		"account_id"
	] = 0


	if validate(
		invalid_account_snapshot
	).is_empty():
		return (
			"snapshot permitió account_id inválido"
		)


	var invalid_character_snapshot := (
		empty_snapshot.duplicate(
			true
		)
	)


	invalid_character_snapshot[
		"character_id"
	] = 0


	if validate(
		invalid_character_snapshot
	).is_empty():
		return (
			"snapshot permitió character_id inválido"
		)


	var invalid_container_snapshot := (
		empty_snapshot.duplicate(
			true
		)
	)


	invalid_container_snapshot[
		"container"
	] = "inventory"


	if validate(
		invalid_container_snapshot
	).is_empty():
		return (
			"snapshot permitió container incorrecto"
		)


	return ""
