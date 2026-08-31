class_name ServerCharacterDerivedStatsBootstrap
extends RefCounted


# =========================================================
# CREAR DESDE PRIMARY STATS
# =========================================================

static func create_from_primary_stats(
	primary_stats: ServerCharacterPrimaryStatsState
) -> ServerCharacterDerivedStatsState:
	if primary_stats == null:
		return null


	if not primary_stats.is_valid():
		return null


	var values := (
		ServerCharacterDerivedStatsRules
		.build_foundation_values(
			primary_stats
		)
	)


	if values.is_empty():
		return null


	var state := (
		ServerCharacterDerivedStatsState.new(
			primary_stats.class_id,
			primary_stats.revision,
			primary_stats.level,
			primary_stats.reset_count,
			int(
				values.get(
					"max_hp",
					0
				)
			),
			int(
				values.get(
					"max_mp",
					-1
				)
			),
			int(
				values.get(
					"hp_regeneration",
					-1
				)
			),
			int(
				values.get(
					"mp_regeneration",
					-1
				)
			),
			int(
				values.get(
					"physical_power",
					-1
				)
			),
			int(
				values.get(
					"magic_power",
					-1
				)
			),
			int(
				values.get(
					"healing_power",
					-1
				)
			),
			float(
				values.get(
					"critical_strike_chance",
					-1.0
				)
			),
			float(
				values.get(
					"critical_damage_multiplier",
					-1.0
				)
			)
		)
	)


	if not state.is_valid():
		return null


	return state


# =========================================================
# SOURCE CURRENT
#
# Sirve para detectar si un Derived State debe
# reconstruirse después de:
#
# - allocation
# - Level Up
# - Reset futuro
# =========================================================

static func is_current_for_primary_stats(
	derived_stats: ServerCharacterDerivedStatsState,
	primary_stats: ServerCharacterPrimaryStatsState
) -> bool:
	if derived_stats == null:
		return false


	if primary_stats == null:
		return false


	if not derived_stats.is_valid():
		return false


	if not primary_stats.is_valid():
		return false


	if (
		derived_stats.class_id
		!=
		primary_stats.class_id
	):
		return false


	if (
		derived_stats.source_primary_stats_revision
		!=
		primary_stats.revision
	):
		return false


	if (
		derived_stats.level
		!=
		primary_stats.level
	):
		return false


	if (
		derived_stats.reset_count
		!=
		primary_stats.reset_count
	):
		return false


	return true
