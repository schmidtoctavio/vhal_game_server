class_name ServerHandEquipModeCatalog
extends RefCounted


# =========================================================
# IDENTIDAD ESTABLE
# =========================================================

const NONE: StringName = &"none"

const MAIN_HAND_ONLY: StringName = &"main_hand_only"

const ONE_HAND: StringName = &"one_hand"

const TWO_HAND: StringName = &"two_hand"

const OFF_HAND_ONLY: StringName = &"off_hand_only"


const MODE_IDS: Array[StringName] = [
	NONE,
	MAIN_HAND_ONLY,
	ONE_HAND,
	TWO_HAND,
	OFF_HAND_ONLY,
]


# =========================================================
# NORMALIZACIÓN
# =========================================================

static func normalize_mode_id(
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

static func is_valid_mode_id(
	value: Variant
) -> bool:
	return MODE_IDS.has(
		normalize_mode_id(
			value
		)
	)


static func get_mode_ids() -> Array[StringName]:
	return MODE_IDS.duplicate()


static func validate_catalog() -> bool:
	if MODE_IDS.is_empty():
		return false


	var seen: Dictionary = {}


	for mode_id: StringName in MODE_IDS:
		if mode_id.is_empty():
			return false


		if seen.has(
			mode_id
		):
			return false


		seen[
			mode_id
		] = true


	return true
