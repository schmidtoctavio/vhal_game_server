class_name ServerCharacterDamageDefenseProfileResolver
extends RefCounted


# =========================================================
# RESOLVER
#
# Equipment Snapshot
# →
# Damage Defense Profile
# =========================================================

static func resolve(
	equipment_snapshot: Dictionary
) -> ServerDamageDefenseProfile:
	if equipment_snapshot.is_empty():
		return null


	var contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if contributions.is_empty():
		return null


	var armor_rating := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.ARMOR_RATING
		)
	)


	var magic_resistance := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.MAGIC_RESISTANCE_RATING
		)
	)


	var fire_resistance := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.FIRE_RESISTANCE_RATING
		)
	)


	var cold_resistance := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.COLD_RESISTANCE_RATING
		)
	)


	var lightning_resistance := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.LIGHTNING_RESISTANCE_RATING
		)
	)


	var poison_resistance := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
			.POISON_RESISTANCE_RATING
		)
	)


	if (
		armor_rating < 0
		or
		magic_resistance < 0
		or
		fire_resistance < 0
		or
		cold_resistance < 0
		or
		lightning_resistance < 0
		or
		poison_resistance < 0
	):
		return null


	var profile := (
		ServerDamageDefenseProfile.new(
			armor_rating,
			magic_resistance,
			fire_resistance,
			cold_resistance,
			lightning_resistance,
			poison_resistance
		)
	)


	if not profile.is_valid():
		return null


	return profile


# =========================================================
# EXTRAER INT
# =========================================================

static func _get_int_stat(
	contributions: Dictionary,
	stat_id: Variant
) -> int:
	var value: Variant = (
		ServerEquipmentResolvedContributionRules
		.get_stat_total(
			contributions,
			stat_id
		)
	)


	if typeof(value) != TYPE_INT:
		return -1


	var result := int(
		value
	)


	if result < 0:
		return -1


	return result


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
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


	if empty_profile == null:
		return (
			"Equipment vacío no produjo "
			+
			"Damage Defense Profile."
		)


	if not empty_profile.is_valid():
		return (
			"Damage Defense Profile vacío inválido."
		)


	if empty_profile.armor_rating != 0:
		return (
			"Equipment vacío debe resolver Armor 0."
		)


	if empty_profile.magic_resistance_rating != 0:
		return (
			"Equipment vacío debe resolver "
			+
			"Magic Resistance 0."
		)


	if empty_profile.fire_resistance_rating != 0:
		return (
			"Equipment vacío debe resolver "
			+
			"Fire Resistance 0."
		)


	if empty_profile.cold_resistance_rating != 0:
		return (
			"Equipment vacío debe resolver "
			+
			"Cold Resistance 0."
		)


	if empty_profile.lightning_resistance_rating != 0:
		return (
			"Equipment vacío debe resolver "
			+
			"Lightning Resistance 0."
		)


	if empty_profile.poison_resistance_rating != 0:
		return (
			"Equipment vacío debe resolver "
			+
			"Poison Resistance 0."
		)


	# -----------------------------------------------------
	# RESISTANCE MODIFIERS FOUNDATION
	# -----------------------------------------------------

	var resistance_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "damage-defense-resistance-helmet",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 0,

					"rolled_modifiers": [
						{
							"stat_id": (
								"magic_resistance_rating"
							),

							"operation_id": "flat_add",

							"value": 50,
						},

						{
							"stat_id": (
								"fire_resistance_rating"
							),

							"operation_id": "flat_add",

							"value": 25,
						},
					],
				},
			},
		],
	}


	var resistance_profile := (
		resolve(
			resistance_snapshot
		)
	)


	if resistance_profile == null:
		return (
			"No se pudo resolver Equipment "
			+
			"con Resistance modifiers."
		)


	# Leather Helmet intrinsic:
	#
	# Armor = 20

	if resistance_profile.armor_rating != 20:
		return (
			"Resistance Equipment no conservó "
			+
			"Armor 20."
		)


	if (
		resistance_profile
		.magic_resistance_rating
		!=
		50
	):
		return (
			"Magic Resistance modifier "
			+
			"no resolvió 50."
		)


	if (
		resistance_profile
		.fire_resistance_rating
		!=
		25
	):
		return (
			"Fire Resistance modifier "
			+
			"no resolvió 25."
		)


	return ""
