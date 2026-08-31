class_name ServerEquipmentRules
extends RefCounted


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	if not ServerEquipmentCategoryCatalog.validate_catalog():
		return "Equipment Category Catalog inválido"


	if not ServerHandEquipModeCatalog.validate_catalog():
		return "Hand Equip Mode Catalog inválido"


	if not ServerEquipmentSlotCatalog.validate_catalog():
		return "Equipment Slot Catalog inválido"

	var usage_contract_error := (
		ServerEquipmentUsageRules.validate_contract()
	)


	if not usage_contract_error.is_empty():
		return (
			"Equipment Usage Contract inválido: "
			+
			usage_contract_error
		)

	# -----------------------------------------------------
	# ONE HAND
	# -----------------------------------------------------

	var one_hand_weapon := {
		"equipment_category_id": "weapon",
		"hand_equip_mode_id": "one_hand",
	}


	if not can_definition_use_slot(
		one_hand_weapon,
		ServerEquipmentSlotCatalog.MAIN_HAND
	):
		return "ONE_HAND no acepta main_hand"


	if not can_definition_use_slot(
		one_hand_weapon,
		ServerEquipmentSlotCatalog.OFF_HAND
	):
		return "ONE_HAND no acepta off_hand"


	# -----------------------------------------------------
	# TWO HAND
	# -----------------------------------------------------

	var two_hand_weapon := {
		"equipment_category_id": "weapon",
		"hand_equip_mode_id": "two_hand",
	}


	if not can_definition_use_slot(
		two_hand_weapon,
		ServerEquipmentSlotCatalog.MAIN_HAND
	):
		return "TWO_HAND no acepta main_hand"


	if can_definition_use_slot(
		two_hand_weapon,
		ServerEquipmentSlotCatalog.OFF_HAND
	):
		return "TWO_HAND acepta off_hand incorrectamente"


	var reserved_slots := (
		get_reserved_slot_ids(
			two_hand_weapon,
			ServerEquipmentSlotCatalog.MAIN_HAND
		)
	)


	if (
		reserved_slots.size() != 1
		or
		not reserved_slots.has(
			ServerEquipmentSlotCatalog.OFF_HAND
		)
	):
		return "TWO_HAND no reserva off_hand"


	# -----------------------------------------------------
	# SHIELD
	# -----------------------------------------------------

	var shield := {
		"equipment_category_id": "shield",
		"hand_equip_mode_id": "off_hand_only",
	}


	if can_definition_use_slot(
		shield,
		ServerEquipmentSlotCatalog.MAIN_HAND
	):
		return "Shield acepta main_hand incorrectamente"


	if not can_definition_use_slot(
		shield,
		ServerEquipmentSlotCatalog.OFF_HAND
	):
		return "Shield no acepta off_hand"


	# -----------------------------------------------------
	# ARMOR
	# -----------------------------------------------------

	var helmet := {
		"equipment_category_id": "head",
		"hand_equip_mode_id": "none",
	}


	if not can_definition_use_slot(
		helmet,
		ServerEquipmentSlotCatalog.HEAD
	):
		return "Helmet no acepta head"


	return ""


# =========================================================
# DEFINICIÓN
# =========================================================

static func is_definition_configuration_valid(
	definition: Dictionary
) -> bool:
	if definition.is_empty():
		return false


	var category_id := (
		ServerEquipmentCategoryCatalog.normalize_category_id(
			definition.get(
				"equipment_category_id",
				"none"
			)
		)
	)


	var hand_mode_id := (
		ServerHandEquipModeCatalog.normalize_mode_id(
			definition.get(
				"hand_equip_mode_id",
				"none"
			)
		)
	)


	if not ServerEquipmentCategoryCatalog.is_valid_category_id(
		category_id
	):
		return false


	if not ServerHandEquipModeCatalog.is_valid_mode_id(
		hand_mode_id
	):
		return false


	# -----------------------------------------------------
	# NO EQUIPMENT
	# -----------------------------------------------------

	if category_id == ServerEquipmentCategoryCatalog.NONE:
		return (
			hand_mode_id
			==
			ServerHandEquipModeCatalog.NONE
		)


	# -----------------------------------------------------
	# EQUIPMENT DE MANO
	# -----------------------------------------------------

	if ServerEquipmentCategoryCatalog.is_hand_category(
		category_id
	):
		if hand_mode_id == ServerHandEquipModeCatalog.NONE:
			return false


		if (
			category_id
			==
			ServerEquipmentCategoryCatalog.SHIELD
		):
			return (
				hand_mode_id
				==
				ServerHandEquipModeCatalog.OFF_HAND_ONLY
			)


		return true


	# -----------------------------------------------------
	# EQUIPMENT NORMAL
	# -----------------------------------------------------

	return (
		hand_mode_id
		==
		ServerHandEquipModeCatalog.NONE
	)


static func is_equipment_definition(
	definition: Dictionary
) -> bool:
	if not is_definition_configuration_valid(
		definition
	):
		return false


	return (
		ServerEquipmentCategoryCatalog.normalize_category_id(
			definition.get(
				"equipment_category_id",
				"none"
			)
		)
		!=
		ServerEquipmentCategoryCatalog.NONE
	)


# =========================================================
# DEFINICIÓN -> SLOT
# =========================================================

static func can_definition_use_slot(
	definition: Dictionary,
	slot_id: Variant
) -> bool:
	if not is_equipment_definition(
		definition
	):
		return false


	var normalized_slot := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			slot_id
		)
	)


	if not ServerEquipmentSlotCatalog.is_valid_slot_id(
		normalized_slot
	):
		return false


	var category_id := (
		ServerEquipmentCategoryCatalog.normalize_category_id(
			definition.get(
				"equipment_category_id",
				"none"
			)
		)
	)


	if not ServerEquipmentSlotCatalog.accepts_category(
		normalized_slot,
		category_id
	):
		return false


	if not ServerEquipmentSlotCatalog.is_hand_slot(
		normalized_slot
	):
		return true


	return _hand_mode_allows_slot(
		definition.get(
			"hand_equip_mode_id",
			"none"
		),
		normalized_slot
	)


# =========================================================
# HAND MODE
# =========================================================

static func _hand_mode_allows_slot(
	hand_mode_id: Variant,
	slot_id: Variant
) -> bool:
	var mode := (
		ServerHandEquipModeCatalog.normalize_mode_id(
			hand_mode_id
		)
	)


	var slot := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			slot_id
		)
	)


	match mode:
		ServerHandEquipModeCatalog.MAIN_HAND_ONLY:
			return (
				slot
				==
				ServerEquipmentSlotCatalog.MAIN_HAND
			)


		ServerHandEquipModeCatalog.ONE_HAND:
			return (
				slot
				==
				ServerEquipmentSlotCatalog.MAIN_HAND
				or
				slot
				==
				ServerEquipmentSlotCatalog.OFF_HAND
			)


		ServerHandEquipModeCatalog.TWO_HAND:
			return (
				slot
				==
				ServerEquipmentSlotCatalog.MAIN_HAND
			)


		ServerHandEquipModeCatalog.OFF_HAND_ONLY:
			return (
				slot
				==
				ServerEquipmentSlotCatalog.OFF_HAND
			)


	return false


# =========================================================
# RESERVA DERIVADA DE SLOTS
# =========================================================

static func get_reserved_slot_ids(
	definition: Dictionary,
	equipped_slot_id: Variant
) -> Array[StringName]:
	var result: Array[StringName] = []


	if not is_equipment_definition(
		definition
	):
		return result


	var slot_id := (
		ServerEquipmentSlotCatalog.normalize_slot_id(
			equipped_slot_id
		)
	)


	if (
		slot_id
		!=
		ServerEquipmentSlotCatalog.MAIN_HAND
	):
		return result


	var hand_mode_id := (
		ServerHandEquipModeCatalog.normalize_mode_id(
			definition.get(
				"hand_equip_mode_id",
				"none"
			)
		)
	)


	if (
		hand_mode_id
		!=
		ServerHandEquipModeCatalog.TWO_HAND
	):
		return result


	result.append(
		ServerEquipmentSlotCatalog.OFF_HAND
	)


	return result
