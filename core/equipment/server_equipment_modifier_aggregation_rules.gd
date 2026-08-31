class_name ServerEquipmentModifierAggregationRules
extends RefCounted


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Este contrato agrega únicamente STAT MODIFIERS.
#
# Incluye:
#
# - Definition.fixed_modifiers
# - Instance.state.rolled_modifiers
#
#
# NO incluye:
#
# - Base Item Stats
# - Enhancement intrinsic scaling
# - Special Effects
#
#
# Ejemplo:
#
# Helmet:
#
# Fixed:
# +2 VIT
#
# Rolled:
# +4 VIT
# +8 Armor
#
# Resultado del agregador:
#
# vitality = 6
# armor_rating = 8
#
#
# El Armor intrínseco del Helmet, por ejemplo:
#
# Base Armor 20
# Enhancement +13 = +26
#
# NO forma parte de este resultado.
#
# Ese valor será combinado posteriormente en la capa
# de Equipment Resolved Contributions.
#
#
# IMPORTANTE:
#
# Estos totales tampoco modifican Permanent Primary.
#
# Ejemplo futuro:
#
# Permanent VIT = 27
# Equipment Modifier VIT = +6
# Effective VIT = 33
#
# Permanent VIT continúa siendo 27.
# =========================================================


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# EMPTY TOTALS
	# -----------------------------------------------------

	var empty_totals := (
		create_empty_totals()
	)


	if empty_totals.is_empty():
		return (
			"No se pudieron crear Equipment "
			+
			"Modifier Totals vacíos."
		)


	if (
		empty_totals.size()
		!=
		ServerEquipmentStatModifierCatalog
		.DEFINITIONS
		.size()
	):
		return (
			"Equipment Modifier Totals no contiene "
			+
			"todos los stat_id conocidos."
		)


	if (
		int(
			get_total(
				empty_totals,
				"vitality"
			)
		)
		!=
		0
	):
		return (
			"Equipment VIT foundation no comienza en 0."
		)


	if not is_equal_approx(
		float(
			get_total(
				empty_totals,
				"critical_strike_chance"
			)
		),
		0.0
	):
		return (
			"Equipment Crit foundation "
			+
			"no comienza en 0.0."
		)


	# -----------------------------------------------------
	# CROSS-SOURCE AGGREGATION
	# -----------------------------------------------------

	var synthetic_definition := {
		"equipment_category_id": "head",

		"hand_equip_mode_id": "none",

		"fixed_modifiers": [
			{
				"stat_id": "vitality",
				"operation_id": "flat_add",
				"value": 2,
			},

			{
				"stat_id": "critical_strike_chance",
				"operation_id": "flat_add",
				"value": 0.01,
			},
		],
	}


	var synthetic_item := {
		"uid": "aggregation-cross-source",

		"item_id": "synthetic_helmet",

		"state": {
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
					"stat_id": "critical_strike_chance",
					"operation_id": "flat_add",
					"value": 0.02,
				},
			],
		},
	}


	var synthetic_totals := (
		aggregate_item(
			synthetic_item,
			synthetic_definition
		)
	)


	if synthetic_totals.is_empty():
		return (
			"No se pudo agregar Equipment sintético."
		)


	if (
		int(
			get_total(
				synthetic_totals,
				"vitality"
			)
		)
		!=
		6
	):
		return (
			"Fixed + Rolled VIT no resolvió +6."
		)


	if (
		int(
			get_total(
				synthetic_totals,
				"armor_rating"
			)
		)
		!=
		8
	):
		return (
			"Rolled Armor no resolvió +8."
		)


	if not is_equal_approx(
		float(
			get_total(
				synthetic_totals,
				"critical_strike_chance"
			)
		),
		0.03
	):
		return (
			"Fixed + Rolled Crit no resolvió 0.03."
		)


	# -----------------------------------------------------
	# AGREGACIÓN DIRECTA — DUPLICADOS ENTRE FUENTES
	# -----------------------------------------------------

	var combined_modifiers := [
		{
			"stat_id": "max_hp",
			"operation_id": "flat_add",
			"value": 100,
		},

		{
			"stat_id": "max_hp",
			"operation_id": "flat_add",
			"value": 50,
		},

		{
			"stat_id": "critical_strike_chance",
			"operation_id": "flat_add",
			"value": 0.03,
		},

		{
			"stat_id": "critical_strike_chance",
			"operation_id": "flat_add",
			"value": 0.02,
		},
	]


	var combined_totals := (
		aggregate_modifier_array(
			combined_modifiers
		)
	)


	if combined_totals.is_empty():
		return (
			"No se pudieron agregar modifiers "
			+
			"combinados."
		)


	if (
		int(
			get_total(
				combined_totals,
				"max_hp"
			)
		)
		!=
		150
	):
		return (
			"Max HP combinado no resolvió +150."
		)


	if not is_equal_approx(
		float(
			get_total(
				combined_totals,
				"critical_strike_chance"
			)
		),
		0.05
	):
		return (
			"Critical Strike combinado "
			+
			"no resolvió 0.05."
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
				"uid": "aggregation-real-helmet",

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
		],
	}


	var snapshot_totals := (
		aggregate_equipment_snapshot(
			equipment_snapshot
		)
	)


	if snapshot_totals.is_empty():
		return (
			"No se pudo agregar Equipment Snapshot "
			+
			"foundation."
		)


	if (
		int(
			get_total(
				snapshot_totals,
				"vitality"
			)
		)
		!=
		4
	):
		return (
			"Equipment Snapshot VIT "
			+
			"no resolvió +4."
		)


	if (
		int(
			get_total(
				snapshot_totals,
				"armor_rating"
			)
		)
		!=
		8
	):
		return (
			"Equipment Snapshot Armor "
			+
			"no resolvió +8."
		)


	if (
		int(
			get_total(
				snapshot_totals,
				"max_hp"
			)
		)
		!=
		100
	):
		return (
			"Equipment Snapshot Max HP "
			+
			"no resolvió +100."
		)


	# -----------------------------------------------------
	# MODIFIER INVÁLIDO DEBE FALLAR CLOSED
	# -----------------------------------------------------

	var invalid_modifiers := [
		{
			"stat_id": "unknown_stat",
			"operation_id": "flat_add",
			"value": 10,
		},
	]


	if not (
		aggregate_modifier_array(
			invalid_modifiers
		)
		.is_empty()
	):
		return (
			"Aggregation permitió modifier inválido."
		)


	return ""


# =========================================================
# CREAR TOTALS VACÍOS
# =========================================================

static func create_empty_totals() -> Dictionary:
	var result: Dictionary = {}


	for raw_stat_id: Variant in (
		ServerEquipmentStatModifierCatalog
		.DEFINITIONS
		.keys()
	):
		var stat_id := (
			ServerEquipmentStatModifierCatalog
			.normalize_stat_id(
				raw_stat_id
			)
		)


		if stat_id.is_empty():
			return {}


		var stat_definition := (
			ServerEquipmentStatModifierCatalog
			.get_definition(
				stat_id
			)
		)


		if stat_definition.is_empty():
			return {}


		var numeric_kind := StringName(
			String(
				stat_definition.get(
					"numeric_kind",
					""
				)
			)
		)


		var result_key := String(
			stat_id
		)


		if (
			numeric_kind
			==
			ServerEquipmentStatModifierCatalog
			.NUMERIC_INT
		):
			result[
				result_key
			] = 0


			continue


		if (
			numeric_kind
			==
			ServerEquipmentStatModifierCatalog
			.NUMERIC_NUMBER
		):
			result[
				result_key
			] = 0.0


			continue


		return {}


	return result


# =========================================================
# AGREGAR ARRAY DE MODIFIERS
# =========================================================
#
# A diferencia del Source Contract, acá SÍ pueden aparecer
# varias entradas con el mismo stat_id.
#
# ¿Por qué?
#
# Porque este Array puede representar modifiers ya
# validados provenientes de:
#
# - distintas fuentes;
# - distintos items equipados.
#
# Todos son flat_add en F22-I v1.
# =========================================================

static func aggregate_modifier_array(
	modifiers_value: Variant
) -> Dictionary:
	if typeof(modifiers_value) != TYPE_ARRAY:
		return {}


	var modifiers: Array = (
		modifiers_value as Array
	)


	var totals := (
		create_empty_totals()
	)


	if totals.is_empty():
		return {}


	for modifier_value: Variant in modifiers:
		if typeof(modifier_value) != TYPE_DICTIONARY:
			return {}


		var modifier: Dictionary = (
			modifier_value as Dictionary
		)


		var modifier_error := (
			ServerEquipmentStatModifierRules
			.validate_modifier(
				modifier
			)
		)


		if not modifier_error.is_empty():
			return {}


		var stat_id := (
			ServerEquipmentStatModifierCatalog
			.normalize_stat_id(
				modifier[
					ServerEquipmentStatModifierRules
					.STAT_ID_KEY
				]
			)
		)


		var stat_key := String(
			stat_id
		)


		if not totals.has(
			stat_key
		):
			return {}


		var stat_definition := (
			ServerEquipmentStatModifierCatalog
			.get_definition(
				stat_id
			)
		)


		if stat_definition.is_empty():
			return {}


		var numeric_kind := StringName(
			String(
				stat_definition.get(
					"numeric_kind",
					""
				)
			)
		)


		var numeric_value: Variant = (
			ServerEquipmentStatModifierRules
			.get_numeric_value(
				modifier
			)
		)


		if typeof(numeric_value) == TYPE_NIL:
			return {}


		if (
			numeric_kind
			==
			ServerEquipmentStatModifierCatalog
			.NUMERIC_INT
		):
			totals[
				stat_key
			] = (
				int(
					totals[
						stat_key
					]
				)
				+
				int(
					numeric_value
				)
			)


			continue


		if (
			numeric_kind
			==
			ServerEquipmentStatModifierCatalog
			.NUMERIC_NUMBER
		):
			totals[
				stat_key
			] = (
				float(
					totals[
						stat_key
					]
				)
				+
				float(
					numeric_value
				)
			)


			continue


		return {}


	return totals


# =========================================================
# AGREGAR UN ITEM
# =========================================================

static func aggregate_item(
	item: Dictionary,
	definition: Dictionary
) -> Dictionary:
	var definition_error := (
		ServerEquipmentModifierSourceRules
		.validate_definition(
			definition
		)
	)


	if not definition_error.is_empty():
		return {}


	var item_error := (
		ServerEquipmentModifierSourceRules
		.validate_item_instance(
			item,
			definition
		)
	)


	if not item_error.is_empty():
		return {}


	var modifiers := (
		ServerEquipmentModifierSourceRules
		.get_all_modifiers(
			item,
			definition
		)
	)


	return (
		aggregate_modifier_array(
			modifiers
		)
	)


# =========================================================
# AGREGAR EQUIPMENT SNAPSHOT
# =========================================================

static func aggregate_equipment_snapshot(
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


	var combined_modifiers: Array = []


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


		var modifiers := (
			ServerEquipmentModifierSourceRules
			.get_all_modifiers(
				item,
				definition
			)
		)


		for modifier_value: Variant in modifiers:
			if typeof(modifier_value) != TYPE_DICTIONARY:
				return {}


			combined_modifiers.append(
				(
					modifier_value as Dictionary
				).duplicate(
					true
				)
			)


	return (
		aggregate_modifier_array(
			combined_modifiers
		)
	)


# =========================================================
# CONSULTAR TOTAL
# =========================================================

static func get_total(
	totals: Dictionary,
	stat_id: Variant
) -> Variant:
	var normalized_stat_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_stat_id(
			stat_id
		)
	)


	if not (
		ServerEquipmentStatModifierCatalog
		.has_definition(
			normalized_stat_id
		)
	):
		return null


	var stat_key := String(
		normalized_stat_id
	)


	if not totals.has(
		stat_key
	):
		return null


	var stat_definition := (
		ServerEquipmentStatModifierCatalog
		.get_definition(
			normalized_stat_id
		)
	)


	if stat_definition.is_empty():
		return null


	var numeric_kind := StringName(
		String(
			stat_definition.get(
				"numeric_kind",
				""
			)
		)
	)


	var value: Variant = (
		totals[
			stat_key
		]
	)


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_INT
	):
		if typeof(value) != TYPE_INT:
			return null


		return int(
			value
		)


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_NUMBER
	):
		if (
			typeof(value) != TYPE_INT
			and
			typeof(value) != TYPE_FLOAT
		):
			return null


		return float(
			value
		)


	return null
