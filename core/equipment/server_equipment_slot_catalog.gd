class_name ServerEquipmentSlotCatalog
extends RefCounted


# =========================================================
# IDENTIDAD ESTABLE
# =========================================================

const INVALID_SLOT_ID: StringName = &""


const HEAD: StringName = &"head"
const CHEST: StringName = &"chest"
const PANTS: StringName = &"pants"
const GLOVES: StringName = &"gloves"
const BOOTS: StringName = &"boots"

const MAIN_HAND: StringName = &"main_hand"
const OFF_HAND: StringName = &"off_hand"

const WINGS: StringName = &"wings"
const PENDANT: StringName = &"pendant"

const RING_LEFT: StringName = &"ring_left"
const RING_RIGHT: StringName = &"ring_right"


const SLOT_IDS: Array[StringName] = [
	HEAD,
	CHEST,
	PANTS,
	GLOVES,
	BOOTS,

	MAIN_HAND,
	OFF_HAND,

	WINGS,
	PENDANT,

	RING_LEFT,
	RING_RIGHT,
]


# =========================================================
# CATEGORÍAS ESTRUCTURALMENTE ADMITIDAS
# =========================================================

const ALLOWED_CATEGORIES_BY_SLOT_ID: Dictionary = {
	HEAD: [
		ServerEquipmentCategoryCatalog.HEAD,
	],

	CHEST: [
		ServerEquipmentCategoryCatalog.CHEST,
	],

	PANTS: [
		ServerEquipmentCategoryCatalog.PANTS,
	],

	GLOVES: [
		ServerEquipmentCategoryCatalog.GLOVES,
	],

	BOOTS: [
		ServerEquipmentCategoryCatalog.BOOTS,
	],

	MAIN_HAND: [
		ServerEquipmentCategoryCatalog.WEAPON,
	],

	OFF_HAND: [
		ServerEquipmentCategoryCatalog.WEAPON,
		ServerEquipmentCategoryCatalog.SHIELD,
	],

	WINGS: [
		ServerEquipmentCategoryCatalog.WINGS,
	],

	PENDANT: [
		ServerEquipmentCategoryCatalog.PENDANT,
	],

	RING_LEFT: [
		ServerEquipmentCategoryCatalog.RING,
	],

	RING_RIGHT: [
		ServerEquipmentCategoryCatalog.RING,
	],
}


# =========================================================
# NORMALIZACIÓN
# =========================================================

static func normalize_slot_id(
	value: Variant
) -> StringName:
	return StringName(
		String(
			value
		)
		.strip_edges()
		.to_lower()
	)


# =========================================================
# VALIDACIÓN
# =========================================================

static func is_valid_slot_id(
	value: Variant
) -> bool:
	var normalized := (
		normalize_slot_id(
			value
		)
	)


	return (
		normalized != INVALID_SLOT_ID
		and
		ALLOWED_CATEGORIES_BY_SLOT_ID.has(
			normalized
		)
	)


static func is_hand_slot(
	value: Variant
) -> bool:
	var normalized := (
		normalize_slot_id(
			value
		)
	)


	return (
		normalized == MAIN_HAND
		or
		normalized == OFF_HAND
	)


# =========================================================
# CATEGORÍAS
# =========================================================

static func get_allowed_categories(
	slot_id: Variant
) -> Array[StringName]:
	var normalized := (
		normalize_slot_id(
			slot_id
		)
	)


	if not ALLOWED_CATEGORIES_BY_SLOT_ID.has(
		normalized
	):
		return []


	var result: Array[StringName] = []


	var values: Array = (
		ALLOWED_CATEGORIES_BY_SLOT_ID[
			normalized
		]
	)


	for value: Variant in values:
		result.append(
			ServerEquipmentCategoryCatalog.normalize_category_id(
				value
			)
		)


	return result


static func accepts_category(
	slot_id: Variant,
	category_id: Variant
) -> bool:
	var normalized_category := (
		ServerEquipmentCategoryCatalog.normalize_category_id(
			category_id
		)
	)


	return get_allowed_categories(
		slot_id
	).has(
		normalized_category
	)


static func get_slot_ids() -> Array[StringName]:
	return SLOT_IDS.duplicate()


# =========================================================
# SELF VALIDATION
# =========================================================

static func validate_catalog() -> bool:
	if SLOT_IDS.is_empty():
		return false


	if not ServerEquipmentCategoryCatalog.validate_catalog():
		return false


	var seen: Dictionary = {}


	for slot_id: StringName in SLOT_IDS:
		if slot_id == INVALID_SLOT_ID:
			return false


		if seen.has(
			slot_id
		):
			return false


		seen[
			slot_id
		] = true


		if not ALLOWED_CATEGORIES_BY_SLOT_ID.has(
			slot_id
		):
			return false


		var categories := (
			get_allowed_categories(
				slot_id
			)
		)


		if categories.is_empty():
			return false


		for category_id: StringName in categories:
			if not ServerEquipmentCategoryCatalog.is_equipment_category(
				category_id
			):
				return false


	return (
		seen.size()
		==
		ALLOWED_CATEGORIES_BY_SLOT_ID.size()
	)
