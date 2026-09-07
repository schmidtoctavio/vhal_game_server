class_name ServerCharacterResolvedDerivedStatsRules
extends RefCounted


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Resolved Derived:
#
# Derived calculado desde Effective Primary
#
# +
#
# Equipment Direct Derived:
#
# - max_hp
# - max_mp
# - physical_power
# - magic_power
# - healing_power
#
# +
#
# Equipment Combat Secondary que actualmente pertenece
# al Derived State:
#
# - critical_strike_chance
# - critical_damage_multiplier
# - attack_speed_multiplier
#
#
# NO incluye:
#
# - Primary Stats
#   ya fueron consumidos vía Effective Primary.
#
# - armor_rating
#   sigue siendo Equipment Combat Contribution separada.
#
# - movement_speed
#   todavía no es Equipment Stat Modifier.
#
# - weapon_damage
#   es slot-local.
# =========================================================


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var primary_stats := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			7,
			11,
			0,
			25,
			15,
			25,
			10,
			2,
			0,
			2,
			3,
			5,
			200,
			50,
			0,
			0,
			50,
			7,
			43
		)
	)


	if primary_stats == null:
		return (
			"No se pudo crear Primary Stats foundation."
		)


	if not primary_stats.is_valid():
		return (
			"Primary Stats foundation inválido."
		)


	# -----------------------------------------------------
	# EQUIPMENT SINTÉTICO
	# -----------------------------------------------------
	#
	# Primary:
	#
	# +3 STR
	# +5 AGI
	# +4 VIT
	# +3 ENE
	#
	# Direct Derived:
	#
	# +100 Max HP
	# +20 Max MP
	# +10 Physical Power
	# +7 Magic Power
	# +5 Healing Power
	#
	# Secondary:
	#
	# +0.03 Crit Chance
	# +0.25 Crit Damage
	# +0.05 Attack Speed
	# -----------------------------------------------------

	var equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "resolved-derived-helmet",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 7,

					"rolled_modifiers": [
						{
							"stat_id": "strength",
							"operation_id": "flat_add",
							"value": 3,
						},

						{
							"stat_id": "agility",
							"operation_id": "flat_add",
							"value": 5,
						},

						{
							"stat_id": "vitality",
							"operation_id": "flat_add",
							"value": 4,
						},

						{
							"stat_id": "energy",
							"operation_id": "flat_add",
							"value": 3,
						},

						{
							"stat_id": "max_hp",
							"operation_id": "flat_add",
							"value": 100,
						},

						{
							"stat_id": "max_mp",
							"operation_id": "flat_add",
							"value": 20,
						},

						{
							"stat_id": "physical_power",
							"operation_id": "flat_add",
							"value": 10,
						},

						{
							"stat_id": "magic_power",
							"operation_id": "flat_add",
							"value": 7,
						},

						{
							"stat_id": "healing_power",
							"operation_id": "flat_add",
							"value": 5,
						},

						{
							"stat_id": "critical_strike_chance",
							"operation_id": "flat_add",
							"value": 0.03,
						},

						{
							"stat_id": "critical_damage_multiplier",
							"operation_id": "flat_add",
							"value": 0.25,
						},

						{
							"stat_id": "attack_speed_multiplier",
							"operation_id": "flat_add",
							"value": 0.05,
						},
					],
				},
			},
		],
	}


	var equipment_contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if equipment_contributions.is_empty():
		return (
			"No se pudieron resolver Equipment Contributions."
		)


	var effective_primary := (
		ServerCharacterEffectivePrimaryStatsRules
		.resolve(
			primary_stats,
			equipment_contributions
		)
	)


	if effective_primary.is_empty():
		return (
			"No se pudo resolver Effective Primary."
		)


	var resolved_values := (
		resolve(
			primary_stats,
			effective_primary,
			equipment_contributions
		)
	)


	if resolved_values.is_empty():
		return (
			"No se pudieron resolver Derived Stats finales."
		)


	# -----------------------------------------------------
	# BASE DERIVED DESDE EFFECTIVE PRIMARY
	# -----------------------------------------------------
	#
	# Effective:
	#
	# STR 30
	# AGI 20
	# VIT 31
	# ENE 16
	#
	# Base Derived:
	#
	# HP       304
	# MP        88
	# Physical  90
	# Magic     16
	# Healing   16
	# Crit     0.0
	# Crit DMG 1.5
	# AS       1.021875
	#
	#
	# + Equipment direct:
	#
	# HP       +100 = 404
	# MP        +20  = 108
	# Physical  +10  = 100
	# Magic     +7   = 23
	# Healing   +5   = 21
	# Crit      +.03 = .03
	# Crit DMG  +.25 = 1.75
	# AS        +.05 = 1.071875
	# -----------------------------------------------------

	if int(
		resolved_values.get(
			"max_hp",
			-1
		)
	) != 404:
		return (
			"Resolved Max HP no resolvió 404."
		)


	if int(
		resolved_values.get(
			"max_mp",
			-1
		)
	) != 108:
		return (
			"Resolved Max MP no resolvió 108."
		)

	if int(
		resolved_values.get(
			"hp_regeneration",
			-1
		)
	) != 3:
		return (
			"Resolved HP Regeneration no resolvió 3."
		)


	if int(
		resolved_values.get(
			"mp_regeneration",
			-1
		)
	) != 1:
		return (
			"Resolved MP Regeneration no resolvió 1."
		)


	if int(
		resolved_values.get(
			"physical_power",
			-1
		)
	) != 100:
		return (
			"Resolved Physical Power no resolvió 100."
		)


	if int(
		resolved_values.get(
			"magic_power",
			-1
		)
	) != 23:
		return (
			"Resolved Magic Power no resolvió 23."
		)


	if int(
		resolved_values.get(
			"healing_power",
			-1
		)
	) != 21:
		return (
			"Resolved Healing Power no resolvió 21."
		)


	if not is_equal_approx(
		float(
			resolved_values.get(
				"critical_strike_chance",
				-1.0
			)
		),
		0.03
	):
		return (
			"Resolved Crit Chance no resolvió 0.03."
		)


	if not is_equal_approx(
		float(
			resolved_values.get(
				"critical_damage_multiplier",
				-1.0
			)
		),
		1.75
	):
		return (
			"Resolved Crit Damage no resolvió 1.75."
		)


	if not is_equal_approx(
		float(
			resolved_values.get(
				"attack_speed_multiplier",
				-1.0
			)
		),
		1.071875
	):
		return (
			"Resolved Attack Speed no resolvió 1.071875."
		)


	if not is_equal_approx(
		float(
			resolved_values.get(
				"movement_speed",
				-1.0
			)
		),
		4.0
	):
		return (
			"Equipment alteró Movement Speed."
		)


	# -----------------------------------------------------
	# ARMOR SIGUE FUERA DE DERIVED
	# -----------------------------------------------------

	if resolved_values.has(
		"armor_rating"
	):
		return (
			"Armor fue incorporado incorrectamente "
			+
			"al Derived State."
		)


	return ""


# =========================================================
# RESOLVER
# =========================================================

static func resolve(
	primary_stats: ServerCharacterPrimaryStatsState,
	effective_primary: Dictionary,
	equipment_contributions: Dictionary
) -> Dictionary:
	if primary_stats == null:
		return {}


	if not primary_stats.is_valid():
		return {}


	var effective_error := (
		ServerCharacterEffectivePrimaryStatsRules
		.validate_resolved_for_primary_stats(
			primary_stats,
			effective_primary
		)
	)


	if not effective_error.is_empty():
		return {}


	if equipment_contributions.is_empty():
		return {}


	var base_values := (
		ServerCharacterDerivedStatsRules
		.build_effective_primary_values(
			primary_stats,
			effective_primary
		)
	)


	if base_values.is_empty():
		return {}


	var result := (
		base_values.duplicate(
			true
		)
	)


	# =====================================================
	# DIRECT DERIVED INT
	# =====================================================

	var int_stat_ids: Array[StringName] = [
		ServerEquipmentStatModifierCatalog.MAX_HP,
		ServerEquipmentStatModifierCatalog.MAX_MP,
		ServerEquipmentStatModifierCatalog.PHYSICAL_POWER,
		ServerEquipmentStatModifierCatalog.MAGIC_POWER,
		ServerEquipmentStatModifierCatalog.HEALING_POWER,
	]


	for stat_id: StringName in int_stat_ids:
		var equipment_value: Variant = (
			ServerEquipmentResolvedContributionRules
			.get_stat_total(
				equipment_contributions,
				stat_id
			)
		)


		if typeof(equipment_value) != TYPE_INT:
			return {}


		var stat_key := String(
			stat_id
		)


		if not result.has(
			stat_key
		):
			return {}


		if typeof(
			result[
				stat_key
			]
		) != TYPE_INT:
			return {}


		result[
			stat_key
		] = (
			int(
				result[
					stat_key
				]
			)
			+
			int(
				equipment_value
			)
		)


	# =====================================================
	# COMBAT SECONDARY NUMBER
	# =====================================================

	var number_stat_ids: Array[StringName] = [
		ServerEquipmentStatModifierCatalog
		.CRITICAL_STRIKE_CHANCE,

		ServerEquipmentStatModifierCatalog
		.CRITICAL_DAMAGE_MULTIPLIER,

		ServerEquipmentStatModifierCatalog
		.ATTACK_SPEED_MULTIPLIER,
	]


	for stat_id: StringName in number_stat_ids:
		var equipment_value: Variant = (
			ServerEquipmentResolvedContributionRules
			.get_stat_total(
				equipment_contributions,
				stat_id
			)
		)


		if not (
			typeof(equipment_value) == TYPE_INT
			or
			typeof(equipment_value) == TYPE_FLOAT
		):
			return {}


		var stat_key := String(
			stat_id
		)


		if not result.has(
			stat_key
		):
			return {}


		var current_value: Variant = (
			result[
				stat_key
			]
		)


		if not (
			typeof(current_value) == TYPE_INT
			or
			typeof(current_value) == TYPE_FLOAT
		):
			return {}


		result[
			stat_key
		] = (
			float(
				current_value
			)
			+
			float(
				equipment_value
			)
		)


	# =====================================================
	# VALIDACIÓN FINAL
	# =====================================================

	if int(
		result.get(
			"max_hp",
			0
		)
	) <= 0:
		return {}


	if int(
		result.get(
			"max_mp",
			-1
		)
	) < 0:
		return {}

	if int(
		result.get(
			"hp_regeneration",
			-1
		)
	) < 0:
		return {}


	if int(
		result.get(
			"mp_regeneration",
			-1
		)
	) < 0:
		return {}


	if int(
		result.get(
			"physical_power",
			-1
		)
	) < 0:
		return {}


	if int(
		result.get(
			"magic_power",
			-1
		)
	) < 0:
		return {}


	if int(
		result.get(
			"healing_power",
			-1
		)
	) < 0:
		return {}


	var crit_chance := float(
		result.get(
			"critical_strike_chance",
			-1.0
		)
	)


	if (
		crit_chance < 0.0
		or
		crit_chance > 1.0
	):
		return {}


	if float(
		result.get(
			"critical_damage_multiplier",
			-1.0
		)
	) < 1.0:
		return {}


	if float(
		result.get(
			"attack_speed_multiplier",
			-1.0
		)
	) <= 0.0:
		return {}


	if float(
		result.get(
			"movement_speed",
			-1.0
		)
	) <= 0.0:
		return {}


	return result
