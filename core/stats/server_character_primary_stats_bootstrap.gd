class_name ServerCharacterPrimaryStatsBootstrap
extends RefCounted


# =========================================================
# CREAR DESDE GAME SESSION TICKET
# =========================================================

static func create_from_character_data(
	character_data: Dictionary
) -> ServerCharacterPrimaryStatsState:
	# =====================================================
	# IDENTIDAD DE CLASS
	# =====================================================

	var class_id := String(
		character_data.get(
			"class_id",
			""
		)
	).strip_edges().to_lower()


	var class_definition := (
		ServerClassStatsCatalog.get_definition(
			class_id
		)
	)


	if class_definition == null:
		return null


	# =====================================================
	# PROGRESIÓN DEL CHARACTER
	# =====================================================

	var level := int(
		character_data.get(
			"level",
			0
		)
	)


	var reset_count := int(
		character_data.get(
			"reset_count",
			-1
		)
	)


	if level < 1:
		return null


	if reset_count < 0:
		return null


	# =====================================================
	# STATS SNAPSHOT
	# =====================================================

	var stats_value: Variant = (
		character_data.get(
			"stats",
			null
		)
	)


	if typeof(stats_value) != TYPE_DICTIONARY:
		return null


	var stats: Dictionary = (
		stats_value
	)


	var revision := int(
		stats.get(
			"revision",
			-1
		)
	)


	if revision < 0:
		return null


	# =====================================================
	# PROGRESSION DENTRO DEL SNAPSHOT
	# =====================================================

	var progression_value: Variant = (
		stats.get(
			"progression",
			null
		)
	)


	if (
		typeof(progression_value)
		!=
		TYPE_DICTIONARY
	):
		return null


	var progression: Dictionary = (
		progression_value
	)


	if int(
		progression.get(
			"level",
			0
		)
	) != level:
		return null


	if int(
		progression.get(
			"reset_count",
			-1
		)
	) != reset_count:
		return null


	# =====================================================
	# ALLOCATED
	# =====================================================

	var allocated_value: Variant = (
		stats.get(
			"allocated",
			null
		)
	)


	if (
		typeof(allocated_value)
		!=
		TYPE_DICTIONARY
	):
		return null


	var allocated: Dictionary = (
		allocated_value
	)


	var allocated_strength := int(
		allocated.get(
			"strength",
			-1
		)
	)

	var allocated_agility := int(
		allocated.get(
			"agility",
			-1
		)
	)

	var allocated_vitality := int(
		allocated.get(
			"vitality",
			-1
		)
	)

	var allocated_energy := int(
		allocated.get(
			"energy",
			-1
		)
	)


	if (
		allocated_strength < 0
		or
		allocated_agility < 0
		or
		allocated_vitality < 0
		or
		allocated_energy < 0
	):
		return null


	# =====================================================
	# BONUS POINTS
	# =====================================================

	var bonus_stat_points := int(
		stats.get(
			"bonus_stat_points",
			-1
		)
	)


	if bonus_stat_points < 0:
		return null


	# =====================================================
	# BUDGET SNAPSHOT
	# =====================================================

	var budget_value: Variant = (
		stats.get(
			"budget",
			null
		)
	)


	if (
		typeof(budget_value)
		!=
		TYPE_DICTIONARY
	):
		return null


	var budget: Dictionary = (
		budget_value
	)


	var points_per_level := int(
		budget.get(
			"points_per_level",
			-1
		)
	)

	var points_per_reset := int(
		budget.get(
			"points_per_reset",
			-1
		)
	)

	var level_points := int(
		budget.get(
			"level_points",
			-1
		)
	)

	var reset_points := int(
		budget.get(
			"reset_points",
			-1
		)
	)

	var bonus_points := int(
		budget.get(
			"bonus_points",
			-1
		)
	)

	var total_points := int(
		budget.get(
			"total_points",
			-1
		)
	)

	var spent_points := int(
		budget.get(
			"spent_points",
			-1
		)
	)

	var unspent_points := int(
		budget.get(
			"unspent_points",
			-1
		)
	)


	# =====================================================
	# REGLAS LOCALES DEL GAME SERVER
	# =====================================================

	if (
		points_per_level
		!=
		class_definition.stat_points_per_level
	):
		return null


	if (
		points_per_reset
		!=
		ServerPrimaryStatBudgetRules.RESET_STAT_POINTS
	):
		return null


	var expected_level_points := (
		ServerPrimaryStatBudgetRules.get_level_points(
			level,
			class_definition.stat_points_per_level
		)
	)


	if expected_level_points < 0:
		return null


	var expected_reset_points := (
		ServerPrimaryStatBudgetRules.get_reset_points(
			reset_count
		)
	)


	if expected_reset_points < 0:
		return null


	var expected_spent_points := (
		allocated_strength
		+
		allocated_agility
		+
		allocated_vitality
		+
		allocated_energy
	)


	var expected_total_points := (
		expected_level_points
		+
		expected_reset_points
		+
		bonus_stat_points
	)


	var expected_unspent_points := (
		expected_total_points
		-
		expected_spent_points
	)


	if expected_unspent_points < 0:
		return null


	# =====================================================
	# SNAPSHOT BACKEND VS REGLAS SERVER
	# =====================================================

	if level_points != expected_level_points:
		return null


	if reset_points != expected_reset_points:
		return null


	if bonus_points != bonus_stat_points:
		return null


	if total_points != expected_total_points:
		return null


	if spent_points != expected_spent_points:
		return null


	if unspent_points != expected_unspent_points:
		return null


	# =====================================================
	# REVISION 0
	# =====================================================

	if revision == 0:
		if expected_spent_points != 0:
			return null


		if bonus_stat_points != 0:
			return null


	# =====================================================
	# CREAR RUNTIME
	# =====================================================

	var state := (
		ServerCharacterPrimaryStatsState.new(
			class_id,
			revision,
			level,
			reset_count,
			class_definition.starting_strength,
			class_definition.starting_agility,
			class_definition.starting_vitality,
			class_definition.starting_energy,
			allocated_strength,
			allocated_agility,
			allocated_vitality,
			allocated_energy,
			points_per_level,
			points_per_reset,
			level_points,
			reset_points,
			bonus_stat_points,
			total_points,
			spent_points,
			unspent_points
		)
	)


	if not state.is_valid():
		return null


	return state
