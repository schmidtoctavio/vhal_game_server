class_name ServerBasicAttackProfileResolver
extends RefCounted


const MODE_UNARMED: String = "unarmed"

const MODE_MELEE: String = "melee"

const MODE_RANGED: String = "ranged"


# =========================================================
# FOUNDATION TEMPORAL — UNARMED
# =========================================================

const UNARMED_BASE_DAMAGE: int = 500

const UNARMED_ATTACK_RANGE: float = 1.5

const UNARMED_COOLDOWN_SECONDS: float = 1.0


static func resolve(
	equipment_snapshot: Dictionary
) -> Dictionary:
	if equipment_snapshot.is_empty():
		return {}


	if String(
		equipment_snapshot.get(
			"container",
			""
		)
	).strip_edges() != "equipment":
		return {}


	var items_value: Variant = (
		equipment_snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return {}


	var items: Array = (
		items_value
	)


	var main_hand_item: Dictionary = {}


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return {}


		var item: Dictionary = (
			item_value
		)


		var slot_id := String(
			item.get(
				"equipment_slot",
				""
			)
		).strip_edges()


		if slot_id != "main_hand":
			continue


		main_hand_item = item


		break


	# -----------------------------------------------------
	# SIN ARMA
	# -----------------------------------------------------

	if main_hand_item.is_empty():
		return {
			"mode": MODE_UNARMED,

			"weapon_item_id": "",

			"weapon_uid": "",

			"base_damage": (
				UNARMED_BASE_DAMAGE
			),

			"attack_range": (
				UNARMED_ATTACK_RANGE
			),

			"cooldown_duration_seconds": (
				UNARMED_COOLDOWN_SECONDS
			),
		}


	# -----------------------------------------------------
	# ARMA EQUIPADA
	# -----------------------------------------------------

	var item_id := String(
		main_hand_item.get(
			"item_id",
			""
		)
	).strip_edges()


	var uid := String(
		main_hand_item.get(
			"uid",
			""
		)
	).strip_edges()


	if (
		item_id.is_empty()
		or
		uid.is_empty()
	):
		return {}


	var definition := (
		ServerItemCatalog.get_definition(
			item_id
		)
	)


	if definition.is_empty():
		return {}


	if String(
		definition.get(
			"equipment_category_id",
			""
		)
	).strip_edges() != "weapon":
		return {}


	var mode := String(
		definition.get(
			"basic_attack_mode_id",
			""
		)
	).strip_edges().to_lower()


	if (
		mode != MODE_MELEE
		and
		mode != MODE_RANGED
	):
		return {}


	var base_damage := int(
		definition.get(
			"basic_attack_base_damage",
			0
		)
	)


	var attack_range := float(
		definition.get(
			"basic_attack_range",
			0.0
		)
	)


	var cooldown_duration_seconds := float(
		definition.get(
			"basic_attack_cooldown_seconds",
			0.0
		)
	)


	if base_damage <= 0:
		return {}


	if attack_range <= 0.0:
		return {}


	if cooldown_duration_seconds < 0.0:
		return {}


	return {
		"mode": mode,

		"weapon_item_id": item_id,

		"weapon_uid": uid,

		"base_damage": base_damage,

		"attack_range": attack_range,

		"cooldown_duration_seconds": (
			cooldown_duration_seconds
		),
	}
