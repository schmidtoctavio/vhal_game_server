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


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# UNARMED
	# -----------------------------------------------------

	var unarmed_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


	var unarmed_profile := (
		resolve(
			unarmed_snapshot
		)
	)


	if unarmed_profile.is_empty():
		return (
			"No se pudo resolver Basic Attack unarmed."
		)


	if String(
		unarmed_profile.get(
			"mode",
			""
		)
	) != MODE_UNARMED:
		return (
			"Basic Attack unarmed resolvió modo incorrecto."
		)


	if int(
		unarmed_profile.get(
			"base_damage",
			0
		)
	) != UNARMED_BASE_DAMAGE:
		return (
			"Basic Attack unarmed alteró Base Damage."
		)


	# -----------------------------------------------------
	# BRONZE SWORD +0
	# -----------------------------------------------------

	var sword_zero_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "basic-attack-sword-zero",

				"item_id": "bronze_sword",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 0,
				},
			},
		],
	}


	var sword_zero_profile := (
		resolve(
			sword_zero_snapshot
		)
	)


	if sword_zero_profile.is_empty():
		return (
			"No se pudo resolver Bronze Sword +0."
		)


	if int(
		sword_zero_profile.get(
			"base_damage",
			0
		)
	) != 1000:
		return (
			"Bronze Sword +0 no resolvió Weapon Damage 1000."
		)


	# -----------------------------------------------------
	# BRONZE SWORD +7
	# -----------------------------------------------------

	var sword_plus_seven_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "basic-attack-sword-plus-seven",

				"item_id": "bronze_sword",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 7,
				},
			},
		],
	}


	var sword_plus_seven_profile := (
		resolve(
			sword_plus_seven_snapshot
		)
	)


	if sword_plus_seven_profile.is_empty():
		return (
			"No se pudo resolver Bronze Sword +7."
		)


	if int(
		sword_plus_seven_profile.get(
			"base_damage",
			0
		)
	) != 1150:
		return (
			"Bronze Sword +7 no resolvió Weapon Damage 1150."
		)


	if not is_equal_approx(
		float(
			sword_plus_seven_profile.get(
				"attack_range",
				0.0
			)
		),
		2.0
	):
		return (
			"Enhancement alteró Attack Range."
		)


	if not is_equal_approx(
		float(
			sword_plus_seven_profile.get(
				"cooldown_duration_seconds",
				-1.0
			)
		),
		0.9
	):
		return (
			"Enhancement alteró cooldown base."
		)


	# -----------------------------------------------------
	# BRONZE BOW +0
	# -----------------------------------------------------

	var bow_zero_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "basic-attack-bow-zero",

				"item_id": "bronze_bow",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 0,
				},
			},
		],
	}


	var bow_zero_profile := (
		resolve(
			bow_zero_snapshot
		)
	)


	if bow_zero_profile.is_empty():
		return (
			"No se pudo resolver Bronze Bow +0."
		)


	if String(
		bow_zero_profile.get(
			"mode",
			""
		)
	) != MODE_RANGED:
		return (
			"Bronze Bow debe resolver modo ranged."
		)


	if int(
		bow_zero_profile.get(
			"base_damage",
			0
		)
	) != 900:
		return (
			"Bronze Bow +0 no resolvió Weapon Damage 900."
		)


	if not is_equal_approx(
		float(
			bow_zero_profile.get(
				"attack_range",
				0.0
			)
		),
		7.0
	):
		return (
			"Bronze Bow debe conservar Attack Range 7.0."
		)


	if not is_equal_approx(
		float(
			bow_zero_profile.get(
				"cooldown_duration_seconds",
				-1.0
			)
		),
		1.0
	):
		return (
			"Bronze Bow debe conservar cooldown base 1.0."
		)


	# -----------------------------------------------------
	# BRONZE BOW +7
	# -----------------------------------------------------

	var bow_plus_seven_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "basic-attack-bow-plus-seven",

				"item_id": "bronze_bow",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 7,
				},
			},
		],
	}


	var bow_plus_seven_profile := (
		resolve(
			bow_plus_seven_snapshot
		)
	)


	if bow_plus_seven_profile.is_empty():
		return (
			"No se pudo resolver Bronze Bow +7."
		)


	if int(
		bow_plus_seven_profile.get(
			"base_damage",
			0
		)
	) != 1050:
		return (
			"Bronze Bow +7 no resolvió Weapon Damage 1050."
		)


	return ""

static func resolve(
	equipment_snapshot: Dictionary
) -> Dictionary:
	if equipment_snapshot.is_empty():
		return {}

	var equipment_contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if equipment_contributions.is_empty():
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


	var weapon_damage_value: Variant = (
		ServerEquipmentResolvedContributionRules
		.get_slot_intrinsic_value(
			equipment_contributions,
			ServerEquipmentSlotCatalog.MAIN_HAND,
			ServerEquipmentEnhancementProfileCatalog.WEAPON_DAMAGE
		)
	)


	if typeof(
		weapon_damage_value
	) != TYPE_INT:
		return {}


	var base_damage := int(
		weapon_damage_value
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
