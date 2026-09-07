class_name ServerCharacterDerivedStatsRules
extends RefCounted


# =========================================================
# FOUNDATION TODAVÍA PENDIENTE
#
# F22-F2 ya resuelve Max HP / Max MP desde:
#
# - Class
# - Level
# - Permanent Vitality
# - Permanent Energy
#
# F26-E habilita una foundation mínima de regeneración:
#
# - VIT → HP Regeneration
# - ENE → MP Regeneration
#
# F22-F3 resuelve Physical / Magic / Healing Power
# desde el balance autoritativo de cada Class.
# Serán reemplazados en etapas posteriores.
# =========================================================

const HP_REGENERATION_VITALITY_DIVISOR: int = 10

const MP_REGENERATION_ENERGY_DIVISOR: int = 10

# =========================================================
# CRITICAL FOUNDATION
#
# F22-G2-A
#
# Todavía NO existe una fuente real de Critical Chance.
#
# No asumimos:
#
# - AGI
# - Class
# - Equipment
# - Buffs
#
# El multiplier define solamente la semántica base
# de un Critical Strike futuro.
# =========================================================

const FOUNDATION_CRITICAL_STRIKE_CHANCE: float = 0.0

const FOUNDATION_CRITICAL_DAMAGE_MULTIPLIER: float = 1.5

# =========================================================
# SPEED FOUNDATION
#
# F22-H1-A
#
# Attack Speed todavía NO recibe aporte real de:
#
# - AGI
# - Class
# - Equipment
# - Buffs
#
# Movement Speed tampoco recibe aporte de Primary Stats.
#
# Estos valores preservan exactamente el gameplay actual.
# =========================================================

const FOUNDATION_ATTACK_SPEED_MULTIPLIER: float = 1.0

const FOUNDATION_MOVEMENT_SPEED: float = 4.0

# =========================================================
# MAX HP
# =========================================================

static func calculate_max_hp(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return 0


	if class_definition == null:
		return 0


	if not primary_stats.is_valid():
		return 0


	if not class_definition.is_valid():
		return 0


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return 0


	var level_growth := (
		(primary_stats.level - 1)
		*
		class_definition.hp_per_level
	)


	var vitality_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.VITALITY
		)
	)


	if vitality_value < 0:
		return 0


	var vitality_growth := (
		vitality_value
		*
		class_definition.hp_per_vitality
	)


	return (
		class_definition.base_max_hp
		+
		level_growth
		+
		vitality_growth
	)


# =========================================================
# MAX MP
# =========================================================

static func calculate_max_mp(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var level_growth := (
		(primary_stats.level - 1)
		*
		class_definition.mp_per_level
	)


	var energy_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.ENERGY
		)
	)


	if energy_value < 0:
		return -1


	var energy_growth := (
		energy_value
		*
		class_definition.mp_per_energy
	)


	return (
		class_definition.base_max_mp
		+
		level_growth
		+
		energy_growth
	)

# =========================================================
# HP REGENERATION
# =========================================================
#
# F26-E foundation:
#
# floor(Effective VIT / 10)
#
# La fórmula vive en Balance/Derived Stats.
# El runtime de regeneración sólo consume el resultado.
# =========================================================

static func calculate_hp_regeneration(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var vitality_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.VITALITY
		)
	)


	if vitality_value < 0:
		return -1


	return floori(
		float(
			vitality_value
		)
		/
		float(
			HP_REGENERATION_VITALITY_DIVISOR
		)
	)


# =========================================================
# MP REGENERATION
# =========================================================
#
# F26-E foundation:
#
# floor(Effective ENE / 10)
# =========================================================

static func calculate_mp_regeneration(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var energy_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.ENERGY
		)
	)


	if energy_value < 0:
		return -1


	return floori(
		float(
			energy_value
		)
		/
		float(
			MP_REGENERATION_ENERGY_DIVISOR
		)
	)

# =========================================================
# PHYSICAL POWER
# =========================================================

static func calculate_physical_power(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var level_growth := (
		(primary_stats.level - 1)
		*
		class_definition.physical_power_per_level
	)


	var strength_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.STRENGTH
		)
	)


	var agility_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.AGILITY
		)
	)


	if (
		strength_value < 0
		or
		agility_value < 0
	):
		return -1


	var strength_growth := (
		strength_value
		*
		class_definition.physical_power_per_strength
	)


	var agility_growth := (
		agility_value
		*
		class_definition.physical_power_per_agility
	)


	return (
		class_definition.base_physical_power
		+
		level_growth
		+
		strength_growth
		+
		agility_growth
	)

# =========================================================
# MAGIC POWER
# =========================================================

static func calculate_magic_power(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var level_growth := (
		(primary_stats.level - 1)
		*
		class_definition.magic_power_per_level
	)


	var energy_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.ENERGY
		)
	)


	if energy_value < 0:
		return -1


	var energy_growth := (
		energy_value
		*
		class_definition.magic_power_per_energy
	)


	return (
		class_definition.base_magic_power
		+
		level_growth
		+
		energy_growth
	)

# =========================================================
# HEALING POWER
# =========================================================

static func calculate_healing_power(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> int:
	if primary_stats == null:
		return -1


	if class_definition == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	if not class_definition.is_valid():
		return -1


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1


	var level_growth := (
		(primary_stats.level - 1)
		*
		class_definition.healing_power_per_level
	)


	var energy_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.ENERGY
		)
	)


	if energy_value < 0:
		return -1


	var energy_growth := (
		energy_value
		*
		class_definition.healing_power_per_energy
	)


	return (
		class_definition.base_healing_power
		+
		level_growth
		+
		energy_growth
	)

# =========================================================
# CRITICAL STRIKE CHANCE
# =========================================================

static func calculate_critical_strike_chance(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition
) -> float:
	if primary_stats == null:
		return -1.0


	if class_definition == null:
		return -1.0


	if not primary_stats.is_valid():
		return -1.0


	if not class_definition.is_valid():
		return -1.0


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1.0


	return FOUNDATION_CRITICAL_STRIKE_CHANCE


# =========================================================
# CRITICAL DAMAGE MULTIPLIER
# =========================================================

static func calculate_critical_damage_multiplier(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition
) -> float:
	if primary_stats == null:
		return -1.0


	if class_definition == null:
		return -1.0


	if not primary_stats.is_valid():
		return -1.0


	if not class_definition.is_valid():
		return -1.0


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1.0


	return FOUNDATION_CRITICAL_DAMAGE_MULTIPLIER

# =========================================================
# ATTACK SPEED MULTIPLIER
# =========================================================

static func calculate_attack_speed_multiplier(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition,
	resolved_primary: Dictionary = {}
) -> float:
	if primary_stats == null:
		return -1.0


	if class_definition == null:
		return -1.0


	if not primary_stats.is_valid():
		return -1.0


	if not class_definition.is_valid():
		return -1.0


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1.0


	var agility_value := (
		_get_formula_primary_value(
			primary_stats,
			resolved_primary,
			ServerEquipmentStatModifierCatalog.AGILITY
		)
	)


	if agility_value < 0:
		return -1.0


	var formula_agility := float(
		agility_value
	)


	var half_saturation := (
		class_definition
		.attack_speed_agility_half_saturation
	)


	var max_bonus := (
		class_definition.attack_speed_max_bonus
	)


	if formula_agility < 0.0:
		return -1.0


	if half_saturation <= 0.0:
		return -1.0


	if max_bonus < 0.0:
		return -1.0


	var agility_ratio := (
		formula_agility
		/
		(
			formula_agility
			+
			half_saturation
		)
	)


	var attack_speed_bonus := (
		max_bonus
		*
		agility_ratio
	)


	return (
		FOUNDATION_ATTACK_SPEED_MULTIPLIER
		+
		attack_speed_bonus
	)

# =========================================================
# MOVEMENT SPEED
# =========================================================

static func calculate_movement_speed(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition
) -> float:
	if primary_stats == null:
		return -1.0


	if class_definition == null:
		return -1.0


	if not primary_stats.is_valid():
		return -1.0


	if not class_definition.is_valid():
		return -1.0


	if (
		primary_stats.class_id
		!=
		class_definition.class_id
	):
		return -1.0


	return FOUNDATION_MOVEMENT_SPEED

# =========================================================
# RESOLVER PRIMARY VALUE PARA FÓRMULAS
# =========================================================

static func _get_formula_primary_value(
	primary_stats: ServerCharacterPrimaryStatsState,
	resolved_primary: Dictionary,
	stat_id: Variant
) -> int:
	if primary_stats == null:
		return -1


	if not primary_stats.is_valid():
		return -1


	var normalized_stat_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_stat_id(
			stat_id
		)
	)


	if not (
		ServerCharacterEffectivePrimaryStatsRules
		.PRIMARY_STAT_IDS
		.has(
			normalized_stat_id
		)
	):
		return -1


	# -----------------------------------------------------
	# LEGACY / FOUNDATION
	# -----------------------------------------------------
	#
	# Sin Resolved Primary mantenemos exactamente el
	# comportamiento histórico:
	#
	# Derived ← Permanent Primary
	# -----------------------------------------------------

	if resolved_primary.is_empty():
		match normalized_stat_id:
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


	# -----------------------------------------------------
	# EFFECTIVE
	# -----------------------------------------------------

	var validation_error := (
		ServerCharacterEffectivePrimaryStatsRules
		.validate_resolved_for_primary_stats(
			primary_stats,
			resolved_primary
		)
	)


	if not validation_error.is_empty():
		return -1


	var value: Variant = (
		ServerCharacterEffectivePrimaryStatsRules
		.get_effective_value(
			resolved_primary,
			normalized_stat_id
		)
	)


	if typeof(value) != TYPE_INT:
		return -1


	return int(
		value
	)

# =========================================================
# EFFECTIVE PRIMARY → DERIVED FORMULA CONTRACT
# =========================================================

static func validate_effective_primary_formula_contract() -> String:
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
	# LEGACY DEBE PERMANECER IDÉNTICO
	# -----------------------------------------------------

	var legacy_values := (
		build_foundation_values(
			primary_stats
		)
	)


	if legacy_values.is_empty():
		return (
			"Legacy Derived Values vacío."
		)


	if int(
		legacy_values.get(
			"max_hp",
			-1
		)
	) != 288:
		return (
			"Legacy Max HP dejó de resolver 288."
		)


	if int(
		legacy_values.get(
			"max_mp",
			-1
		)
	) != 79:
		return (
			"Legacy Max MP dejó de resolver 79."
		)

	if int(
		legacy_values.get(
			"hp_regeneration",
			-1
		)
	) != 2:
		return (
			"Legacy HP Regeneration dejó de resolver 2."
		)


	if int(
		legacy_values.get(
			"mp_regeneration",
			-1
		)
	) != 1:
		return (
			"Legacy MP Regeneration dejó de resolver 1."
		)


	if int(
		legacy_values.get(
			"physical_power",
			-1
		)
	) != 84:
		return (
			"Legacy Physical Power dejó de resolver 84."
		)


	if not is_equal_approx(
		float(
			legacy_values.get(
				"attack_speed_multiplier",
				-1.0
			)
		),
		1.01666666666667
	):
		return (
			"Legacy Attack Speed cambió."
		)


	# -----------------------------------------------------
	# EFFECTIVE PRIMARY SINTÉTICO
	# -----------------------------------------------------
	#
	# Permanent:
	#
	# STR 27
	# AGI 15
	# VIT 27
	# ENE 13
	#
	# Equipment:
	#
	# STR +3
	# AGI +5
	# VIT +4
	# ENE +3
	#
	# Effective:
	#
	# STR 30
	# AGI 20
	# VIT 31
	# ENE 16
	# -----------------------------------------------------

	var resolved_primary := {
		"source_primary_stats_revision": 7,

		"class_id": "warrior",

		"level": 11,

		"reset_count": 0,

		"permanent": {
			"strength": 27,
			"agility": 15,
			"vitality": 27,
			"energy": 13,
		},

		"equipment_bonus": {
			"strength": 3,
			"agility": 5,
			"vitality": 4,
			"energy": 3,
		},

		"effective": {
			"strength": 30,
			"agility": 20,
			"vitality": 31,
			"energy": 16,
		},
	}


	var resolved_error := (
		ServerCharacterEffectivePrimaryStatsRules
		.validate_resolved_for_primary_stats(
			primary_stats,
			resolved_primary
		)
	)


	if not resolved_error.is_empty():
		return (
			"Effective Primary sintético inválido: "
			+
			resolved_error
		)


	var effective_values := (
		build_effective_primary_values(
			primary_stats,
			resolved_primary
		)
	)


	if effective_values.is_empty():
		return (
			"Effective Derived Values vacío."
		)


	# Warrior:
	#
	# HP = 100 + (10 * 8) + (31 * 4)
	#    = 304

	if int(
		effective_values.get(
			"max_hp",
			-1
		)
	) != 304:
		return (
			"Effective Max HP no resolvió 304."
		)


	# MP = 30 + (10 * 1) + (16 * 3)
	#    = 88

	if int(
		effective_values.get(
			"max_mp",
			-1
		)
	) != 88:
		return (
			"Effective Max MP no resolvió 88."
		)

	if int(
		effective_values.get(
			"hp_regeneration",
			-1
		)
	) != 3:
		return (
			"Effective HP Regeneration no resolvió 3."
		)


	if int(
		effective_values.get(
			"mp_regeneration",
			-1
		)
	) != 1:
		return (
			"Effective MP Regeneration no resolvió 1."
		)


	# Physical =
	#
	# 10
	# + 10 levels * 2
	# + 30 STR * 2
	# = 90

	if int(
		effective_values.get(
			"physical_power",
			-1
		)
	) != 90:
		return (
			"Effective Physical Power no resolvió 90."
		)


	if int(
		effective_values.get(
			"magic_power",
			-1
		)
	) != 16:
		return (
			"Effective Magic Power no resolvió 16."
		)


	if int(
		effective_values.get(
			"healing_power",
			-1
		)
	) != 16:
		return (
			"Effective Healing Power no resolvió 16."
		)


	if not is_equal_approx(
		float(
			effective_values.get(
				"critical_strike_chance",
				-1.0
			)
		),
		0.0
	):
		return (
			"Effective Primary alteró Crit foundation."
		)


	if not is_equal_approx(
		float(
			effective_values.get(
				"critical_damage_multiplier",
				-1.0
			)
		),
		1.5
	):
		return (
			"Effective Primary alteró Crit Damage foundation."
		)


	if not is_equal_approx(
		float(
			effective_values.get(
				"attack_speed_multiplier",
				-1.0
			)
		),
		1.021875
	):
		return (
			"Effective Attack Speed no resolvió 1.021875."
		)


	if not is_equal_approx(
		float(
			effective_values.get(
				"movement_speed",
				-1.0
			)
		),
		4.0
	):
		return (
			"Effective Primary alteró Movement Speed."
		)


	# Primary durable no debe sufrir mutación.

	if primary_stats.permanent_strength != 27:
		return (
			"Derived Formula mutó Permanent STR."
		)


	if primary_stats.permanent_agility != 15:
		return (
			"Derived Formula mutó Permanent AGI."
		)


	if primary_stats.permanent_vitality != 27:
		return (
			"Derived Formula mutó Permanent VIT."
		)


	if primary_stats.permanent_energy != 13:
		return (
			"Derived Formula mutó Permanent ENE."
		)


	return ""

# =========================================================
# RESOLVER DERIVED STATS
# =========================================================

static func build_foundation_values(
	primary_stats: ServerCharacterPrimaryStatsState
) -> Dictionary:
	return (
		_build_values(
			primary_stats,
			{}
		)
	)


static func build_effective_primary_values(
	primary_stats: ServerCharacterPrimaryStatsState,
	resolved_primary: Dictionary
) -> Dictionary:
	var validation_error := (
		ServerCharacterEffectivePrimaryStatsRules
		.validate_resolved_for_primary_stats(
			primary_stats,
			resolved_primary
		)
	)


	if not validation_error.is_empty():
		return {}


	return (
		_build_values(
			primary_stats,
			resolved_primary
		)
	)


static func _build_values(
	primary_stats: ServerCharacterPrimaryStatsState,
	resolved_primary: Dictionary
) -> Dictionary:
	if primary_stats == null:
		return {}


	if not primary_stats.is_valid():
		return {}


	var class_definition := (
		ServerClassStatsCatalog.get_definition(
			primary_stats.class_id
		)
	)


	if class_definition == null:
		return {}


	if not class_definition.is_valid():
		return {}


	var max_hp := calculate_max_hp(
		primary_stats,
		class_definition,
		resolved_primary
	)


	var max_mp := calculate_max_mp(
		primary_stats,
		class_definition,
		resolved_primary
	)

	var hp_regeneration := (
		calculate_hp_regeneration(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)


	var mp_regeneration := (
		calculate_mp_regeneration(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)

	var physical_power := (
		calculate_physical_power(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)


	var magic_power := (
		calculate_magic_power(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)


	var healing_power := (
		calculate_healing_power(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)

	var critical_strike_chance := (
		calculate_critical_strike_chance(
			primary_stats,
			class_definition
		)
	)


	var critical_damage_multiplier := (
		calculate_critical_damage_multiplier(
			primary_stats,
			class_definition
		)
	)

	var attack_speed_multiplier := (
		calculate_attack_speed_multiplier(
			primary_stats,
			class_definition,
			resolved_primary
		)
	)


	var movement_speed := (
		calculate_movement_speed(
			primary_stats,
			class_definition
		)
	)

	if max_hp <= 0:
		return {}


	if max_mp < 0:
		return {}

	if hp_regeneration < 0:
		return {}


	if mp_regeneration < 0:
		return {}

	if physical_power < 0:
		return {}


	if magic_power < 0:
		return {}


	if healing_power < 0:
		return {}

	if critical_strike_chance < 0.0:
		return {}


	if critical_strike_chance > 1.0:
		return {}


	if critical_damage_multiplier < 1.0:
		return {}

	if attack_speed_multiplier <= 0.0:
		return {}


	if movement_speed <= 0.0:
		return {}

	return {
		"max_hp": max_hp,

		"max_mp": max_mp,

		"hp_regeneration": (
			hp_regeneration
		),

		"mp_regeneration": (
			mp_regeneration
		),

		"physical_power": (
			physical_power
		),

		"magic_power": (
			magic_power
		),

		"healing_power": (
			healing_power
		),

		"critical_strike_chance": (
			critical_strike_chance
		),

		"critical_damage_multiplier": (
			critical_damage_multiplier
		),

		"attack_speed_multiplier": (
			attack_speed_multiplier
		),

		"movement_speed": (
			movement_speed
		),
	}
