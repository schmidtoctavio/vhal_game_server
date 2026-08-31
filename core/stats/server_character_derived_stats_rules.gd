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
# Regeneration y Power continúan temporalmente en 0.
# Serán reemplazados en etapas posteriores.
# =========================================================

const FOUNDATION_HP_REGENERATION: int = 0

const FOUNDATION_MP_REGENERATION: int = 0


const FOUNDATION_PHYSICAL_POWER: int = 0

const FOUNDATION_MAGIC_POWER: int = 0

const FOUNDATION_HEALING_POWER: int = 0


# =========================================================
# MAX HP
# =========================================================

static func calculate_max_hp(
	primary_stats: ServerCharacterPrimaryStatsState,
	class_definition: ServerClassStatsDefinition
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


	var vitality_growth := (
		primary_stats.permanent_vitality
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
	class_definition: ServerClassStatsDefinition
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


	var energy_growth := (
		primary_stats.permanent_energy
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
# RESOLVER DERIVED STATS
# =========================================================

static func build_foundation_values(
	primary_stats: ServerCharacterPrimaryStatsState
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
		class_definition
	)


	var max_mp := calculate_max_mp(
		primary_stats,
		class_definition
	)


	if max_hp <= 0:
		return {}


	if max_mp < 0:
		return {}


	return {
		"max_hp": max_hp,

		"max_mp": max_mp,

		"hp_regeneration": (
			FOUNDATION_HP_REGENERATION
		),

		"mp_regeneration": (
			FOUNDATION_MP_REGENERATION
		),

		"physical_power": (
			FOUNDATION_PHYSICAL_POWER
		),

		"magic_power": (
			FOUNDATION_MAGIC_POWER
		),

		"healing_power": (
			FOUNDATION_HEALING_POWER
		),
	}
