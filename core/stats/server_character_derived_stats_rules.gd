class_name ServerCharacterDerivedStatsRules
extends RefCounted


# =========================================================
# FOUNDATION DE COMPATIBILIDAD
#
# Estos valores reproducen deliberadamente el runtime
# temporal existente.
#
# NO representan fórmulas finales de balance.
#
# F22-F2 / F22-F3 reemplazarán progresivamente estos
# outputs por reglas derivadas desde Primary Stats.
# =========================================================

const FOUNDATION_MAX_HP: int = 100_000

const FOUNDATION_MAX_MP: int = 350


const FOUNDATION_HP_REGENERATION: int = 0

const FOUNDATION_MP_REGENERATION: int = 0


const FOUNDATION_PHYSICAL_POWER: int = 0

const FOUNDATION_MAGIC_POWER: int = 0

const FOUNDATION_HEALING_POWER: int = 0


# =========================================================
# RESOLVER FOUNDATION
# =========================================================

static func build_foundation_values(
	primary_stats: ServerCharacterPrimaryStatsState
) -> Dictionary:
	if primary_stats == null:
		return {}


	if not primary_stats.is_valid():
		return {}


	return {
		"max_hp": FOUNDATION_MAX_HP,

		"max_mp": FOUNDATION_MAX_MP,

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
