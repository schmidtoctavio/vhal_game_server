class_name ServerCharacterPhysicalDefenseProfileResolver
extends RefCounted


# =========================================================
# RESULT KEYS
# =========================================================

const ARMOR_RATING_KEY: String = (
	"armor_rating"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Esta capa traduce:
#
# Equipment
# →
# Combat Defense Profile
#
#
# Actualmente:
#
# armor_rating
#
# proviene de:
#
# - Armor intrínseco base
# - Enhancement de Armor
# - Fixed modifiers
# - Rolled modifiers
#
#
# IMPORTANTE:
#
# Esta clase NO aplica mitigación.
#
# Sólo resuelve la defensa física autoritativa
# del personaje.
#
# El consumidor de daño deberá usar:
#
# ServerPhysicalDamageMitigationRules
# .calculate_post_mitigation_damage(...)
# =========================================================


# =========================================================
# RESOLVER
# =========================================================

static func resolve(
	equipment_snapshot: Dictionary
) -> Dictionary:
	var damage_defense_profile := (
		ServerCharacterDamageDefenseProfileResolver
		.resolve(
			equipment_snapshot
		)
	)


	if damage_defense_profile == null:
		return {}


	if not damage_defense_profile.is_valid():
		return {}


	return {
		ARMOR_RATING_KEY: (
			damage_defense_profile.armor_rating
		),
	}


# =========================================================
# CONSULTAR ARMOR
# =========================================================

static func get_armor_rating(
	defense_profile: Dictionary
) -> int:
	if defense_profile.is_empty():
		return -1


	var armor_value: Variant = (
		defense_profile.get(
			ARMOR_RATING_KEY,
			null
		)
	)


	if typeof(armor_value) != TYPE_INT:
		return -1


	var armor_rating := int(
		armor_value
	)


	if armor_rating < 0:
		return -1


	return armor_rating


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# EQUIPMENT VACÍO
	# -----------------------------------------------------

	var empty_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


	var empty_profile := (
		resolve(
			empty_snapshot
		)
	)


	if empty_profile.is_empty():
		return (
			"Equipment vacío no produjo "
			+
			"Physical Defense Profile."
		)


	if get_armor_rating(
		empty_profile
	) != 0:
		return (
			"Equipment vacío no resolvió Armor 0."
		)


	# -----------------------------------------------------
	# LEATHER HELMET +0
	#
	# Base Armor = 20
	# -----------------------------------------------------

	var helmet_zero_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "physical-defense-helmet-zero",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 0,
				},
			},
		],
	}


	var helmet_zero_profile := (
		resolve(
			helmet_zero_snapshot
		)
	)


	if helmet_zero_profile.is_empty():
		return (
			"No se pudo resolver Leather Helmet +0."
		)


	if get_armor_rating(
		helmet_zero_profile
	) != 20:
		return (
			"Leather Helmet +0 no resolvió Armor 20."
		)


	# -----------------------------------------------------
	# LEATHER HELMET +7
	#
	# Base       20
	# Enhance    +7
	#
	# Total      27
	# -----------------------------------------------------

	var helmet_plus_seven_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "physical-defense-helmet-seven",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 7,
				},
			},
		],
	}


	var helmet_plus_seven_profile := (
		resolve(
			helmet_plus_seven_snapshot
		)
	)


	if helmet_plus_seven_profile.is_empty():
		return (
			"No se pudo resolver Leather Helmet +7."
		)


	if get_armor_rating(
		helmet_plus_seven_profile
	) != 27:
		return (
			"Leather Helmet +7 no resolvió Armor 27."
		)


	# -----------------------------------------------------
	# LEATHER HELMET +7 + ROLLED ARMOR
	#
	# Base       20
	# Enhance    +7
	# Rolled     +8
	#
	# Total      35
	# -----------------------------------------------------

	var rolled_helmet_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "physical-defense-helmet-rolled",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 7,

					"rolled_modifiers": [
						{
							"stat_id": "armor_rating",
							"operation_id": "flat_add",
							"value": 8,
						},
					],
				},
			},
		],
	}


	var rolled_helmet_profile := (
		resolve(
			rolled_helmet_snapshot
		)
	)


	if rolled_helmet_profile.is_empty():
		return (
			"No se pudo resolver Helmet +7 "
			+
			"con Rolled Armor."
		)


	if get_armor_rating(
		rolled_helmet_profile
	) != 35:
		return (
			"Helmet +7 + Rolled Armor "
			+
			"no resolvió Armor 35."
		)


	# -----------------------------------------------------
	# MITIGATION COMPATIBILITY
	#
	# 584 con Armor 100 → 530
	#
	# Este cálculo ya pertenece a las reglas de combate.
	# Sólo comprobamos que el profile pueda alimentarlas.
	# -----------------------------------------------------

	var mitigated_damage := (
		ServerPhysicalDamageMitigationRules
		.calculate_post_mitigation_damage(
			584,
			100
		)
	)


	if mitigated_damage != 530:
		return (
			"Physical Defense Profile no es compatible "
			+
			"con Physical Damage Mitigation."
		)


	return ""
