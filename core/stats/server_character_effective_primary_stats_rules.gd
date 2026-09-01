class_name ServerCharacterEffectivePrimaryStatsRules
extends RefCounted


# =========================================================
# RESULT KEYS
# =========================================================

const SOURCE_PRIMARY_STATS_REVISION_KEY: String = (
	"source_primary_stats_revision"
)

const CLASS_ID_KEY: String = (
	"class_id"
)

const LEVEL_KEY: String = (
	"level"
)

const RESET_COUNT_KEY: String = (
	"reset_count"
)

const PERMANENT_KEY: String = (
	"permanent"
)

const EQUIPMENT_BONUS_KEY: String = (
	"equipment_bonus"
)

const EFFECTIVE_KEY: String = (
	"effective"
)


# =========================================================
# PRIMARY STAT IDS
# =========================================================

const PRIMARY_STAT_IDS: Array[StringName] = [
	ServerEquipmentStatModifierCatalog.STRENGTH,
	ServerEquipmentStatModifierCatalog.AGILITY,
	ServerEquipmentStatModifierCatalog.VITALITY,
	ServerEquipmentStatModifierCatalog.ENERGY,
]


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Permanent Primary:
#
# Class Base
# +
# Allocated
# +
# futuros Permanent Bonuses
#
#
# Equipment Primary Bonus:
#
# suma de los Primary Stat Modifiers aportados por
# Equipment actualmente equipado.
#
#
# Effective Primary:
#
# Permanent Primary
# +
# Equipment Primary Bonus
#
#
# IMPORTANTE:
#
# Equipment NUNCA modifica:
#
# - base_strength / agility / vitality / energy
# - allocated_*
# - permanent_*
#
#
# Ejemplo:
#
# Permanent VIT = 27
# Equipment VIT = +4
#
# Effective VIT = 31
#
# Permanent VIT continúa siendo 27.
#
#
# Esta capa todavía NO modifica:
#
# - Derived Stats
# - Vitals
# - Power
# - Crit
# - Attack Speed
# - Combat
# - snapshots enviados al Client
# =========================================================


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# PRIMARY FOUNDATION SINTÉTICO
	# -----------------------------------------------------
	#
	# Mismo estado foundation de ProgAudit:
	#
	# Base:
	# STR 25 / AGI 15 / VIT 25 / ENE 10
	#
	# Allocated:
	# STR 2 / AGI 0 / VIT 2 / ENE 3
	#
	# Permanent:
	# STR 27 / AGI 15 / VIT 27 / ENE 13
	# -----------------------------------------------------

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
			"No se pudo crear Primary Stats "
			+
			"foundation."
		)


	if not primary_stats.is_valid():
		return (
			"Primary Stats foundation inválido."
		)


	# -----------------------------------------------------
	# EMPTY EQUIPMENT
	# -----------------------------------------------------

	var empty_equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


	var empty_contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			empty_equipment_snapshot
		)
	)


	if empty_contributions.is_empty():
		return (
			"No se pudieron resolver contributions "
			+
			"de Equipment vacío."
		)


	var empty_effective := (
		resolve(
			primary_stats,
			empty_contributions
		)
	)


	if empty_effective.is_empty():
		return (
			"Equipment vacío no produjo "
			+
			"Effective Primary."
		)


	if (
		int(
			get_permanent_value(
				empty_effective,
				"vitality"
			)
		)
		!=
		27
	):
		return (
			"Permanent VIT foundation "
			+
			"no resolvió 27."
		)


	if (
		int(
			get_equipment_bonus(
				empty_effective,
				"vitality"
			)
		)
		!=
		0
	):
		return (
			"Equipment vacío no resolvió VIT +0."
		)


	if (
		int(
			get_effective_value(
				empty_effective,
				"vitality"
			)
		)
		!=
		27
	):
		return (
			"Effective VIT con Equipment vacío "
			+
			"no resolvió 27."
		)


	# -----------------------------------------------------
	# EQUIPMENT PRIMARY BONUSES
	# -----------------------------------------------------

	var equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "effective-primary-helmet",

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
							"stat_id": "energy",
							"operation_id": "flat_add",
							"value": 3,
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


	var equipment_contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if equipment_contributions.is_empty():
		return (
			"No se pudieron resolver Equipment "
			+
			"Contributions para Effective Primary."
		)


	var effective_primary := (
		resolve(
			primary_stats,
			equipment_contributions
		)
	)


	if effective_primary.is_empty():
		return (
			"No se pudo resolver Effective Primary."
		)


	# -----------------------------------------------------
	# PERMANENT DEBE PERMANECER INTACTO
	# -----------------------------------------------------

	if (
		int(
			get_permanent_value(
				effective_primary,
				"strength"
			)
		)
		!=
		27
	):
		return (
			"Permanent STR fue alterado."
		)


	if (
		int(
			get_permanent_value(
				effective_primary,
				"agility"
			)
		)
		!=
		15
	):
		return (
			"Permanent AGI fue alterado."
		)


	if (
		int(
			get_permanent_value(
				effective_primary,
				"vitality"
			)
		)
		!=
		27
	):
		return (
			"Permanent VIT fue alterado."
		)


	if (
		int(
			get_permanent_value(
				effective_primary,
				"energy"
			)
		)
		!=
		13
	):
		return (
			"Permanent ENE fue alterado."
		)


	# -----------------------------------------------------
	# EQUIPMENT BONUS
	# -----------------------------------------------------

	if (
		int(
			get_equipment_bonus(
				effective_primary,
				"strength"
			)
		)
		!=
		0
	):
		return (
			"Equipment STR no resolvió +0."
		)


	if (
		int(
			get_equipment_bonus(
				effective_primary,
				"agility"
			)
		)
		!=
		0
	):
		return (
			"Equipment AGI no resolvió +0."
		)


	if (
		int(
			get_equipment_bonus(
				effective_primary,
				"vitality"
			)
		)
		!=
		4
	):
		return (
			"Equipment VIT no resolvió +4."
		)


	if (
		int(
			get_equipment_bonus(
				effective_primary,
				"energy"
			)
		)
		!=
		3
	):
		return (
			"Equipment ENE no resolvió +3."
		)


	# -----------------------------------------------------
	# EFFECTIVE
	# -----------------------------------------------------

	if (
		int(
			get_effective_value(
				effective_primary,
				"strength"
			)
		)
		!=
		27
	):
		return (
			"Effective STR no resolvió 27."
		)


	if (
		int(
			get_effective_value(
				effective_primary,
				"agility"
			)
		)
		!=
		15
	):
		return (
			"Effective AGI no resolvió 15."
		)


	if (
		int(
			get_effective_value(
				effective_primary,
				"vitality"
			)
		)
		!=
		31
	):
		return (
			"Effective VIT no resolvió 31."
		)


	if (
		int(
			get_effective_value(
				effective_primary,
				"energy"
			)
		)
		!=
		16
	):
		return (
			"Effective ENE no resolvió 16."
		)


	# -----------------------------------------------------
	# DIRECT DERIVED NO DEBE CONTAMINAR PRIMARY
	# -----------------------------------------------------

	if typeof(
		get_effective_value(
			effective_primary,
			"max_hp"
		)
	) != TYPE_NIL:
		return (
			"Max HP fue tratado incorrectamente "
			+
			"como Primary Stat."
		)


	# -----------------------------------------------------
	# PRIMARY STATE ORIGINAL NO FUE MUTADO
	# -----------------------------------------------------

	if primary_stats.permanent_vitality != 27:
		return (
			"Resolver mutó Permanent VIT original."
		)


	if primary_stats.permanent_energy != 13:
		return (
			"Resolver mutó Permanent ENE original."
		)


	return ""


# =========================================================
# RESOLVER
# =========================================================

static func resolve(
	primary_stats: ServerCharacterPrimaryStatsState,
	equipment_contributions: Dictionary
) -> Dictionary:
	if primary_stats == null:
		return {}


	if not primary_stats.is_valid():
		return {}


	if equipment_contributions.is_empty():
		return {}


	var permanent: Dictionary = {}

	var equipment_bonus: Dictionary = {}

	var effective: Dictionary = {}


	for stat_id: StringName in PRIMARY_STAT_IDS:
		var permanent_value := (
			_get_permanent_primary_value(
				primary_stats,
				stat_id
			)
		)


		if permanent_value < 0:
			return {}


		var equipment_value: Variant = (
			ServerEquipmentResolvedContributionRules
			.get_stat_total(
				equipment_contributions,
				stat_id
			)
		)


		if typeof(equipment_value) != TYPE_INT:
			return {}


		var equipment_bonus_value := int(
			equipment_value
		)


		if equipment_bonus_value < 0:
			return {}


		var stat_key := String(
			stat_id
		)


		permanent[
			stat_key
		] = permanent_value


		equipment_bonus[
			stat_key
		] = equipment_bonus_value


		effective[
			stat_key
		] = (
			permanent_value
			+
			equipment_bonus_value
		)


	return {
		SOURCE_PRIMARY_STATS_REVISION_KEY: (
			primary_stats.revision
		),

		CLASS_ID_KEY: (
			primary_stats.class_id
		),

		LEVEL_KEY: (
			primary_stats.level
		),

		RESET_COUNT_KEY: (
			primary_stats.reset_count
		),

		PERMANENT_KEY: permanent,

		EQUIPMENT_BONUS_KEY: equipment_bonus,

		EFFECTIVE_KEY: effective,
	}


# =========================================================
# PERMANENT VALUE
# =========================================================

static func get_permanent_value(
	resolved_primary: Dictionary,
	stat_id: Variant
) -> Variant:
	return (
		_get_layer_value(
			resolved_primary,
			PERMANENT_KEY,
			stat_id
		)
	)


# =========================================================
# EQUIPMENT BONUS
# =========================================================

static func get_equipment_bonus(
	resolved_primary: Dictionary,
	stat_id: Variant
) -> Variant:
	return (
		_get_layer_value(
			resolved_primary,
			EQUIPMENT_BONUS_KEY,
			stat_id
		)
	)


# =========================================================
# EFFECTIVE VALUE
# =========================================================

static func get_effective_value(
	resolved_primary: Dictionary,
	stat_id: Variant
) -> Variant:
	return (
		_get_layer_value(
			resolved_primary,
			EFFECTIVE_KEY,
			stat_id
		)
	)


# =========================================================
# LAYER VALUE
# =========================================================

static func _get_layer_value(
	resolved_primary: Dictionary,
	layer_key: String,
	stat_id: Variant
) -> Variant:
	if resolved_primary.is_empty():
		return null


	var normalized_stat_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_stat_id(
			stat_id
		)
	)


	if not PRIMARY_STAT_IDS.has(
		normalized_stat_id
	):
		return null


	var layer_value: Variant = (
		resolved_primary.get(
			layer_key,
			null
		)
	)


	if typeof(layer_value) != TYPE_DICTIONARY:
		return null


	var layer: Dictionary = (
		layer_value as Dictionary
	)


	var stat_key := String(
		normalized_stat_id
	)


	if not layer.has(
		stat_key
	):
		return null


	var value: Variant = (
		layer[
			stat_key
		]
	)


	if typeof(value) != TYPE_INT:
		return null


	return int(
		value
	)


# =========================================================
# PRIMARY STATE → PERMANENT VALUE
# =========================================================

static func _get_permanent_primary_value(
	primary_stats: ServerCharacterPrimaryStatsState,
	stat_id: StringName
) -> int:
	if primary_stats == null:
		return -1


	match stat_id:
		ServerEquipmentStatModifierCatalog.STRENGTH:
			return primary_stats.permanent_strength

		ServerEquipmentStatModifierCatalog.AGILITY:
			return primary_stats.permanent_agility

		ServerEquipmentStatModifierCatalog.VITALITY:
			return primary_stats.permanent_vitality

		ServerEquipmentStatModifierCatalog.ENERGY:
			return primary_stats.permanent_energy

		_:
			return -1
