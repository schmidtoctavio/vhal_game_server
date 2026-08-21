class_name ServerEquipmentCategoryCatalog
extends RefCounted


# =========================================================
# IDENTIDAD ESTABLE
# =========================================================

const NONE: StringName = &"none"

const HEAD: StringName = &"head"
const CHEST: StringName = &"chest"
const PANTS: StringName = &"pants"
const GLOVES: StringName = &"gloves"
const BOOTS: StringName = &"boots"

const WEAPON: StringName = &"weapon"
const SHIELD: StringName = &"shield"

const WINGS: StringName = &"wings"
const PENDANT: StringName = &"pendant"
const RING: StringName = &"ring"


const CATEGORY_IDS: Array[StringName] = [
	NONE,

	HEAD,
	CHEST,
	PANTS,
	GLOVES,
	BOOTS,

	WEAPON,
	SHIELD,

	WINGS,
	PENDANT,
	RING,
]


# =========================================================
# NORMALIZACIÓN
# =========================================================

static func normalize_category_id(
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

static func is_valid_category_id(
	value: Variant
) -> bool:
	return CATEGORY_IDS.has(
		normalize_category_id(
			value
		)
	)


static func is_equipment_category(
	value: Variant
) -> bool:
	var normalized := (
		normalize_category_id(
			value
		)
	)


	return (
		normalized != NONE
		and
		CATEGORY_IDS.has(
			normalized
		)
	)


static func is_hand_category(
	value: Variant
) -> bool:
	var normalized := (
		normalize_category_id(
			value
		)
	)


	return (
		normalized == WEAPON
		or
		normalized == SHIELD
	)


static func get_category_ids() -> Array[StringName]:
	return CATEGORY_IDS.duplicate()


static func validate_catalog() -> bool:
	if CATEGORY_IDS.is_empty():
		return false


	var seen: Dictionary = {}


	for category_id: StringName in CATEGORY_IDS:
		if category_id.is_empty():
			return false


		if seen.has(
			category_id
		):
			return false


		seen[
			category_id
		] = true


	return true
