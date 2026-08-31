class_name ServerEquipmentStatModifierCatalog
extends RefCounted


# =========================================================
# DOMAIN IDS
# =========================================================

const DOMAIN_PRIMARY: StringName = (
	&"primary"
)

const DOMAIN_DIRECT_DERIVED: StringName = (
	&"direct_derived"
)

const DOMAIN_COMBAT_SECONDARY: StringName = (
	&"combat_secondary"
)


const DOMAIN_IDS: Array[StringName] = [
	DOMAIN_PRIMARY,
	DOMAIN_DIRECT_DERIVED,
	DOMAIN_COMBAT_SECONDARY,
]


# =========================================================
# NUMERIC KIND IDS
# =========================================================

const NUMERIC_INT: StringName = (
	&"int"
)

const NUMERIC_NUMBER: StringName = (
	&"number"
)


const NUMERIC_KIND_IDS: Array[StringName] = [
	NUMERIC_INT,
	NUMERIC_NUMBER,
]


# =========================================================
# OPERATION IDS
# =========================================================
#
# F22-I v1 admite únicamente suma plana.
#
# No agregamos todavía:
#
# - percent_add
# - percent_more
# - multiply
# - override
#
# porque el orden de operaciones porcentuales debe
# diseñarse explícitamente más adelante.
# =========================================================

const OPERATION_FLAT_ADD: StringName = (
	&"flat_add"
)


const OPERATION_IDS: Array[StringName] = [
	OPERATION_FLAT_ADD,
]


# =========================================================
# PRIMARY STAT IDS
# =========================================================

const STRENGTH: StringName = (
	&"strength"
)

const AGILITY: StringName = (
	&"agility"
)

const VITALITY: StringName = (
	&"vitality"
)

const ENERGY: StringName = (
	&"energy"
)


# =========================================================
# DIRECT DERIVED STAT IDS
# =========================================================

const MAX_HP: StringName = (
	&"max_hp"
)

const MAX_MP: StringName = (
	&"max_mp"
)

const PHYSICAL_POWER: StringName = (
	&"physical_power"
)

const MAGIC_POWER: StringName = (
	&"magic_power"
)

const HEALING_POWER: StringName = (
	&"healing_power"
)


# =========================================================
# COMBAT / SECONDARY STAT IDS
# =========================================================

const ARMOR_RATING: StringName = (
	&"armor_rating"
)

const CRITICAL_STRIKE_CHANCE: StringName = (
	&"critical_strike_chance"
)

const CRITICAL_DAMAGE_MULTIPLIER: StringName = (
	&"critical_damage_multiplier"
)

const ATTACK_SPEED_MULTIPLIER: StringName = (
	&"attack_speed_multiplier"
)


# =========================================================
# DEFINITIONS
# =========================================================
#
# El catálogo define QUÉ puede modificar Equipment.
#
# Todavía NO:
#
# - asigna modifiers a Item Definitions;
# - persiste random rolls;
# - agrega stats al personaje;
# - reconstruye Derived Stats.
#
# numeric_kind:
#
# int
# → valores enteros.
#
# number
# → valores numéricos que pueden incluir decimales.
#
# Todos los modifiers foundation de F22-I son BONUS
# positivos mediante flat_add.
# =========================================================

const DEFINITIONS: Dictionary = {
	STRENGTH: {
		"domain_id": "primary",
		"numeric_kind": "int",
	},

	AGILITY: {
		"domain_id": "primary",
		"numeric_kind": "int",
	},

	VITALITY: {
		"domain_id": "primary",
		"numeric_kind": "int",
	},

	ENERGY: {
		"domain_id": "primary",
		"numeric_kind": "int",
	},

	MAX_HP: {
		"domain_id": "direct_derived",
		"numeric_kind": "int",
	},

	MAX_MP: {
		"domain_id": "direct_derived",
		"numeric_kind": "int",
	},

	PHYSICAL_POWER: {
		"domain_id": "direct_derived",
		"numeric_kind": "int",
	},

	MAGIC_POWER: {
		"domain_id": "direct_derived",
		"numeric_kind": "int",
	},

	HEALING_POWER: {
		"domain_id": "direct_derived",
		"numeric_kind": "int",
	},

	ARMOR_RATING: {
		"domain_id": "combat_secondary",
		"numeric_kind": "int",
	},

	CRITICAL_STRIKE_CHANCE: {
		"domain_id": "combat_secondary",
		"numeric_kind": "number",
	},

	CRITICAL_DAMAGE_MULTIPLIER: {
		"domain_id": "combat_secondary",
		"numeric_kind": "number",
	},

	ATTACK_SPEED_MULTIPLIER: {
		"domain_id": "combat_secondary",
		"numeric_kind": "number",
	},
}


# =========================================================
# NORMALIZAR IDS
# =========================================================

static func normalize_stat_id(
	value: Variant
) -> StringName:
	return StringName(
		String(
			value
		)
		.strip_edges()
		.to_lower()
	)


static func normalize_operation_id(
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
# CONSULTAR
# =========================================================

static func has_definition(
	stat_id: Variant
) -> bool:
	return DEFINITIONS.has(
		normalize_stat_id(
			stat_id
		)
	)


static func get_definition(
	stat_id: Variant
) -> Dictionary:
	var normalized_stat_id := (
		normalize_stat_id(
			stat_id
		)
	)


	if not DEFINITIONS.has(
		normalized_stat_id
	):
		return {}


	var definition_value: Variant = (
		DEFINITIONS[
			normalized_stat_id
		]
	)


	if typeof(definition_value) != TYPE_DICTIONARY:
		return {}


	return (
		definition_value as Dictionary
	).duplicate(
		true
	)


# =========================================================
# VALIDAR CATÁLOGO
# =========================================================

static func validate_catalog() -> String:
	if DEFINITIONS.is_empty():
		return (
			"Equipment Stat Modifier Catalog vacío."
		)


	var seen_stat_ids: Dictionary = {}


	for raw_stat_id: Variant in (
		DEFINITIONS.keys()
	):
		var stat_id := (
			normalize_stat_id(
				raw_stat_id
			)
		)


		if stat_id.is_empty():
			return (
				"Existe stat_id vacío."
			)


		if String(
			raw_stat_id
		) != String(
			stat_id
		):
			return (
				"stat_id no canónico: "
				+
				String(raw_stat_id)
			)


		if seen_stat_ids.has(
			stat_id
		):
			return (
				"stat_id duplicado: "
				+
				String(stat_id)
			)


		seen_stat_ids[
			stat_id
		] = true


		var definition := (
			get_definition(
				stat_id
			)
		)


		if definition.is_empty():
			return (
				"Definition inválida para stat: "
				+
				String(stat_id)
			)


		var domain_id := StringName(
			String(
				definition.get(
					"domain_id",
					""
				)
			)
			.strip_edges()
			.to_lower()
		)


		if not DOMAIN_IDS.has(
			domain_id
		):
			return (
				String(stat_id)
				+
				" | domain_id inválido."
			)


		var numeric_kind := StringName(
			String(
				definition.get(
					"numeric_kind",
					""
				)
			)
			.strip_edges()
			.to_lower()
		)


		if not NUMERIC_KIND_IDS.has(
			numeric_kind
		):
			return (
				String(stat_id)
				+
				" | numeric_kind inválido."
			)


	return ""
