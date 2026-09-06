class_name ServerCharacterDerivedStatsBootstrap
extends RefCounted


# =========================================================
# CREAR DESDE PRIMARY STATS
# =========================================================
#
# Camino foundation / legacy:
#
# Primary Permanent
# →
# Derived
#
# Equipment todavía no participa.
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


	return (
		_create_state_from_values(
			primary_stats,
			values
		)
	)


# =========================================================
# CREAR DESDE EQUIPMENT SNAPSHOT
# =========================================================
#
# Pipeline:
#
# Equipment Snapshot
# →
# Equipment Contributions
# →
# Effective Primary
# →
# Resolved Derived
# →
# Derived Stats State
#
#
# IMPORTANTE:
#
# Primary Stats durable NO es mutado.
# =========================================================

static func create_from_equipment_snapshot(
	primary_stats: ServerCharacterPrimaryStatsState,
	equipment_snapshot: Dictionary
) -> ServerCharacterDerivedStatsState:
	if primary_stats == null:
		return null


	if not primary_stats.is_valid():
		return null


	var snapshot_error := (
		ServerEquipmentSnapshotValidator
		.validate(
			equipment_snapshot
		)
	)


	if not snapshot_error.is_empty():
		return null


	var equipment_contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if equipment_contributions.is_empty():
		return null


	var effective_primary := (
		ServerCharacterEffectivePrimaryStatsRules
		.resolve(
			primary_stats,
			equipment_contributions
		)
	)


	if effective_primary.is_empty():
		return null


	var values := (
		ServerCharacterResolvedDerivedStatsRules
		.resolve(
			primary_stats,
			effective_primary,
			equipment_contributions
		)
	)


	return (
		_create_state_from_values(
			primary_stats,
			values
		)
	)

# =========================================================
# CREAR DESDE EQUIPMENT ACTUAL
# =========================================================
#
# Este es el entry point para reconstrucciones runtime:
#
# - Allocation
# - stale_revision
# - Level Up
#
# Si Equipment todavía no fue cargado, preservamos el
# comportamiento foundation.
#
# Si ya existe snapshot autoritativo, Equipment participa.
# =========================================================

static func create_from_current_equipment(
	primary_stats: ServerCharacterPrimaryStatsState,
	equipment_snapshot: Dictionary
) -> ServerCharacterDerivedStatsState:
	if primary_stats == null:
		return null


	if not primary_stats.is_valid():
		return null


	if equipment_snapshot.is_empty():
		return (
			create_from_primary_stats(
				primary_stats
			)
		)


	return (
		create_from_equipment_snapshot(
			primary_stats,
			equipment_snapshot
		)
	)

# =========================================================
# CREAR STATE DESDE VALUES
# =========================================================

static func _create_state_from_values(
	primary_stats: ServerCharacterPrimaryStatsState,
	values: Dictionary
) -> ServerCharacterDerivedStatsState:
	if primary_stats == null:
		return null


	if not primary_stats.is_valid():
		return null


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
			),
			float(
				values.get(
					"attack_speed_multiplier",
					-1.0
				)
			),
			float(
				values.get(
					"movement_speed",
					-1.0
				)
			)
		)
	)


	if not state.is_valid():
		return null


	return state


# =========================================================
# EQUIPMENT BOOTSTRAP CONTRACT
# =========================================================

static func validate_equipment_bootstrap_contract() -> String:
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
	# LEGACY
	# -----------------------------------------------------

	var legacy_state := (
		create_from_primary_stats(
			primary_stats
		)
	)


	if legacy_state == null:
		return (
			"No se pudo crear Derived State legacy."
		)


	if legacy_state.max_hp != 288:
		return (
			"Legacy Derived State no conservó Max HP 288."
		)


	if legacy_state.max_mp != 79:
		return (
			"Legacy Derived State no conservó Max MP 79."
		)

	var current_without_equipment := (
		create_from_current_equipment(
			primary_stats,
			{}
		)
	)


	if current_without_equipment == null:
		return (
			"Current Equipment Bootstrap vacío falló."
		)


	if current_without_equipment.max_hp != 288:
		return (
			"Current Equipment Bootstrap vacío "
			+
			"no conservó Max HP 288."
		)

	# -----------------------------------------------------
	# EQUIPMENT
	# -----------------------------------------------------
	#
	# Permanent VIT 27
	#
	# Equipment:
	# +4 VIT
	# +100 Max HP
	# +0.03 Crit
	#
	# Effective VIT 31
	#
	# HP por Effective VIT:
	# 304
	#
	# +100 directo
	#
	# Final:
	# Max HP 404
	# -----------------------------------------------------

	var equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "derived-bootstrap-helmet",

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
							"stat_id": "max_hp",
							"operation_id": "flat_add",
							"value": 100,
						},

						{
							"stat_id": "critical_strike_chance",
							"operation_id": "flat_add",
							"value": 0.03,
						},
					],
				},
			},
		],
	}


	var equipment_state := (
		create_from_current_equipment(
			primary_stats,
			equipment_snapshot
		)
	)


	if equipment_state == null:
		return (
			"No se pudo crear Derived State "
			+
			"desde Equipment."
		)


	if equipment_state.max_hp != 404:
		return (
			"Equipment Derived State "
			+
			"no resolvió Max HP 404."
		)


	if equipment_state.max_mp != 79:
		return (
			"Equipment inesperadamente alteró Max MP."
		)


	if equipment_state.physical_power != 84:
		return (
			"Equipment inesperadamente alteró "
			+
			"Physical Power."
		)


	if not is_equal_approx(
		equipment_state.critical_strike_chance,
		0.03
	):
		return (
			"Equipment Derived State "
			+
			"no resolvió Crit 0.03."
		)


	if primary_stats.permanent_vitality != 27:
		return (
			"Equipment Bootstrap mutó Permanent VIT."
		)


	return ""


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
