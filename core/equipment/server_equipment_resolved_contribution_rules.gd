class_name ServerEquipmentResolvedContributionRules
extends RefCounted


# =========================================================
# RESULT KEYS
# =========================================================

const STAT_TOTALS_KEY: String = (
	"stat_totals"
)

const SLOT_INTRINSICS_KEY: String = (
	"slot_intrinsics"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Esta capa combina:
#
# 1. Stat Modifiers agregados
#    - fixed_modifiers
#    - rolled_modifiers
#
# 2. Intrinsic Equipment resuelto
#    - Base Item Stat
#    - Enhancement
#
#
# Pero respeta el scope semántico del intrinsic:
#
# armor_rating
# → character_additive
#
# weapon_damage
# → slot_local
#
#
# Ejemplo:
#
# Leather Helmet +7:
#
# Base Armor              20
# Enhancement              7
# Rolled Armor             8
# Rolled VIT               4
# Rolled Max HP          100
#
# Resultado:
#
# stat_totals:
# armor_rating = 35
# vitality = 4
# max_hp = 100
#
#
# Bronze Sword +7:
#
# Base Damage           1000
# Enhancement            150
#
# Resultado:
#
# slot_intrinsics:
# main_hand:
# weapon_damage = 1150
#
#
# IMPORTANTE:
#
# Esta clase TODAVÍA no modifica:
#
# - Permanent Primary
# - Effective Primary
# - Derived Stats
# - Runtime
# - Combat
# =========================================================


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var catalog_error := (
		ServerEquipmentIntrinsicContributionCatalog
		.validate_catalog()
	)


	if not catalog_error.is_empty():
		return (
			"Intrinsic Contribution Catalog inválido: "
			+
			catalog_error
		)


	# -----------------------------------------------------
	# EMPTY SNAPSHOT
	# -----------------------------------------------------

	var empty_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


	var empty_contributions := (
		resolve_equipment_snapshot(
			empty_snapshot
		)
	)


	if empty_contributions.is_empty():
		return (
			"Equipment vacío no produjo "
			+
			"Resolved Contributions."
		)


	if (
		int(
			get_stat_total(
				empty_contributions,
				"armor_rating"
			)
		)
		!=
		0
	):
		return (
			"Equipment vacío no resolvió Armor 0."
		)


	var empty_slot_intrinsics_value: Variant = (
		empty_contributions.get(
			SLOT_INTRINSICS_KEY,
			null
		)
	)


	if (
		typeof(empty_slot_intrinsics_value)
		!=
		TYPE_DICTIONARY
	):
		return (
			"slot_intrinsics foundation inválido."
		)


	if not (
		empty_slot_intrinsics_value as Dictionary
	).is_empty():
		return (
			"Equipment vacío produjo slot intrinsics."
		)


	# -----------------------------------------------------
	# SNAPSHOT REALISTA
	# -----------------------------------------------------

	var equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "resolved-contribution-helmet",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 7,

					"rolled_modifiers": [
						{
							"stat_id": "vitality",
							"operation_id": "flat_add",
							"value": 4,
						},

						{
							"stat_id": "armor_rating",
							"operation_id": "flat_add",
							"value": 8,
						},

						{
							"stat_id": "max_hp",
							"operation_id": "flat_add",
							"value": 100,
						},
					],
				},
			},

			{
				"uid": "resolved-contribution-sword",

				"item_id": "bronze_sword",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 7,

					"rolled_modifiers": [
						{
							"stat_id": "critical_strike_chance",
							"operation_id": "flat_add",
							"value": 0.02,
						},
					],
				},
			},
		],
	}


	var contributions := (
		resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if contributions.is_empty():
		return (
			"No se pudieron resolver "
			+
			"Equipment Contributions foundation."
		)


	# Leather Helmet +7:
	#
	# 20 base
	# +7 Enhancement
	# +8 modifier
	# = 35

	if (
		int(
			get_stat_total(
				contributions,
				"armor_rating"
			)
		)
		!=
		35
	):
		return (
			"Resolved Armor no resolvió 35."
		)


	if (
		int(
			get_stat_total(
				contributions,
				"vitality"
			)
		)
		!=
		4
	):
		return (
			"Resolved Equipment VIT no resolvió +4."
		)


	if (
		int(
			get_stat_total(
				contributions,
				"max_hp"
			)
		)
		!=
		100
	):
		return (
			"Resolved Equipment Max HP "
			+
			"no resolvió +100."
		)


	if not is_equal_approx(
		float(
			get_stat_total(
				contributions,
				"critical_strike_chance"
			)
		),
		0.02
	):
		return (
			"Resolved Equipment Crit "
			+
			"no resolvió 0.02."
		)


	# Bronze Sword +7:
	#
	# 1000 base
	# +150 Enhancement
	# = 1150
	#
	# Debe permanecer slot-local.

	var weapon_damage: Variant = (
		get_slot_intrinsic_value(
			contributions,
			"main_hand",
			"weapon_damage"
		)
	)


	if typeof(weapon_damage) != TYPE_INT:
		return (
			"Weapon Damage slot-local no resolvió int."
		)


	if int(
		weapon_damage
	) != 1150:
		return (
			"Bronze Sword +7 no resolvió "
			+
			"Weapon Damage 1150."
		)


	# Armor NO debe aparecer como intrinsic slot-local.

	if typeof(
		get_slot_intrinsic_value(
			contributions,
			"head",
			"armor_rating"
		)
	) != TYPE_NIL:
		return (
			"Armor fue expuesto incorrectamente "
			+
			"como slot-local."
		)


	# Weapon Damage NO es un stat global.

	if typeof(
		get_stat_total(
			contributions,
			"weapon_damage"
		)
	) != TYPE_NIL:
		return (
			"Weapon Damage fue agregado "
			+
			"incorrectamente como stat global."
		)


	return ""


# =========================================================
# EMPTY CONTRIBUTIONS
# =========================================================

static func create_empty_contributions() -> Dictionary:
	var modifier_totals := (
		ServerEquipmentModifierAggregationRules
		.create_empty_totals()
	)


	if modifier_totals.is_empty():
		return {}


	return {
		STAT_TOTALS_KEY: modifier_totals,

		SLOT_INTRINSICS_KEY: {},
	}


# =========================================================
# RESOLVER EQUIPMENT SNAPSHOT
# =========================================================

static func resolve_equipment_snapshot(
	snapshot: Dictionary
) -> Dictionary:
	var snapshot_error := (
		ServerEquipmentSnapshotValidator
		.validate(
			snapshot
		)
	)


	if not snapshot_error.is_empty():
		return {}


	var modifier_totals := (
		ServerEquipmentModifierAggregationRules
		.aggregate_equipment_snapshot(
			snapshot
		)
	)


	if modifier_totals.is_empty():
		return {}


	var result := {
		STAT_TOTALS_KEY: (
			modifier_totals.duplicate(
				true
			)
		),

		SLOT_INTRINSICS_KEY: {},
	}


	var stat_totals: Dictionary = (
		result[
			STAT_TOTALS_KEY
		]
	)


	var slot_intrinsics: Dictionary = (
		result[
			SLOT_INTRINSICS_KEY
		]
	)


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return {}


	var items: Array = (
		items_value as Array
	)


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return {}


		var item: Dictionary = (
			item_value as Dictionary
		)


		var item_id := String(
			item.get(
				"item_id",
				""
			)
		).strip_edges()


		if item_id.is_empty():
			return {}


		var definition := (
			ServerItemCatalog.get_definition(
				item_id
			)
		)


		if definition.is_empty():
			return {}


		var intrinsic_stat_id := (
			ServerEquipmentEnhancementRules
			.get_intrinsic_stat_id(
				definition
			)
		)


		if intrinsic_stat_id.is_empty():
			return {}


		var intrinsic_value := (
			ServerEquipmentEnhancementRules
			.get_resolved_intrinsic_value(
				item,
				definition
			)
		)


		if intrinsic_value < 0:
			return {}


		var scope_id := (
			ServerEquipmentIntrinsicContributionCatalog
			.get_scope_id(
				intrinsic_stat_id
			)
		)


		if scope_id.is_empty():
			return {}


		# -------------------------------------------------
		# CHARACTER ADDITIVE
		# -------------------------------------------------

		if (
			scope_id
			==
			ServerEquipmentIntrinsicContributionCatalog
			.CHARACTER_ADDITIVE
		):
			var stat_key := String(
				intrinsic_stat_id
			)


			if not stat_totals.has(
				stat_key
			):
				return {}


			if typeof(
				stat_totals[
					stat_key
				]
			) != TYPE_INT:
				return {}


			stat_totals[
				stat_key
			] = (
				int(
					stat_totals[
						stat_key
					]
				)
				+
				intrinsic_value
			)


			continue


		# -------------------------------------------------
		# SLOT LOCAL
		# -------------------------------------------------

		if (
			scope_id
			==
			ServerEquipmentIntrinsicContributionCatalog
			.SLOT_LOCAL
		):
			var raw_slot_id := String(
				item.get(
					"equipment_slot",
					""
				)
			).strip_edges()


			var slot_id := (
				ServerEquipmentSlotCatalog
				.normalize_slot_id(
					raw_slot_id
				)
			)


			if not (
				ServerEquipmentSlotCatalog
				.is_valid_slot_id(
					slot_id
				)
			):
				return {}


			var slot_key := String(
				slot_id
			)


			var slot_value: Variant = (
				slot_intrinsics.get(
					slot_key,
					{}
				)
			)


			if typeof(slot_value) != TYPE_DICTIONARY:
				return {}


			var slot_entry: Dictionary = (
				(
					slot_value as Dictionary
				)
				.duplicate(
					true
				)
			)


			var intrinsic_key := String(
				intrinsic_stat_id
			)


			if slot_entry.has(
				intrinsic_key
			):
				return {}


			slot_entry[
				intrinsic_key
			] = intrinsic_value


			slot_intrinsics[
				slot_key
			] = slot_entry


			continue


		return {}


	result[
		STAT_TOTALS_KEY
	] = stat_totals


	result[
		SLOT_INTRINSICS_KEY
	] = slot_intrinsics


	return result


# =========================================================
# CONSULTAR GLOBAL STAT TOTAL
# =========================================================

static func get_stat_total(
	contributions: Dictionary,
	stat_id: Variant
) -> Variant:
	var stat_totals_value: Variant = (
		contributions.get(
			STAT_TOTALS_KEY,
			null
		)
	)


	if typeof(stat_totals_value) != TYPE_DICTIONARY:
		return null


	var stat_totals: Dictionary = (
		stat_totals_value as Dictionary
	)


	return (
		ServerEquipmentModifierAggregationRules
		.get_total(
			stat_totals,
			stat_id
		)
	)


# =========================================================
# CONSULTAR SLOT-LOCAL INTRINSIC
# =========================================================

static func get_slot_intrinsic_value(
	contributions: Dictionary,
	slot_id: Variant,
	intrinsic_stat_id: Variant
) -> Variant:
	var normalized_slot_id := (
		ServerEquipmentSlotCatalog
		.normalize_slot_id(
			slot_id
		)
	)


	if not (
		ServerEquipmentSlotCatalog
		.is_valid_slot_id(
			normalized_slot_id
		)
	):
		return null


	var normalized_intrinsic_stat_id := (
		ServerEquipmentIntrinsicContributionCatalog
		.normalize_intrinsic_stat_id(
			intrinsic_stat_id
		)
	)


	if not (
		ServerEquipmentIntrinsicContributionCatalog
		.has_definition(
			normalized_intrinsic_stat_id
		)
	):
		return null


	if (
		ServerEquipmentIntrinsicContributionCatalog
		.get_scope_id(
			normalized_intrinsic_stat_id
		)
		!=
		ServerEquipmentIntrinsicContributionCatalog
		.SLOT_LOCAL
	):
		return null


	var slot_intrinsics_value: Variant = (
		contributions.get(
			SLOT_INTRINSICS_KEY,
			null
		)
	)


	if typeof(slot_intrinsics_value) != TYPE_DICTIONARY:
		return null


	var slot_intrinsics: Dictionary = (
		slot_intrinsics_value as Dictionary
	)


	var slot_key := String(
		normalized_slot_id
	)


	if not slot_intrinsics.has(
		slot_key
	):
		return null


	var slot_value: Variant = (
		slot_intrinsics[
			slot_key
		]
	)


	if typeof(slot_value) != TYPE_DICTIONARY:
		return null


	var slot_entry: Dictionary = (
		slot_value as Dictionary
	)


	var intrinsic_key := String(
		normalized_intrinsic_stat_id
	)


	if not slot_entry.has(
		intrinsic_key
	):
		return null


	var value: Variant = (
		slot_entry[
			intrinsic_key
		]
	)


	if typeof(value) != TYPE_INT:
		return null


	return int(
		value
	)
