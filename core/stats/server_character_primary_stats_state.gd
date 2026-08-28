class_name ServerCharacterPrimaryStatsState
extends RefCounted


# =========================================================
# IDENTIDAD / PROGRESIÓN
# =========================================================

var class_id: String = ""

var revision: int = 0

var level: int = 1

var reset_count: int = 0


# =========================================================
# BASE
# =========================================================

var base_strength: int = 0

var base_agility: int = 0

var base_vitality: int = 0

var base_energy: int = 0


# =========================================================
# ALLOCATED
# =========================================================

var allocated_strength: int = 0

var allocated_agility: int = 0

var allocated_vitality: int = 0

var allocated_energy: int = 0


# =========================================================
# PERMANENT FOUNDATION
# =========================================================
#
# En F22-C todavía:
#
# Permanent
# =
# Class Base
# +
# Allocated
#
# Permanent Bonuses futuros vendrán después.
# =========================================================

var permanent_strength: int = 0

var permanent_agility: int = 0

var permanent_vitality: int = 0

var permanent_energy: int = 0


# =========================================================
# BUDGET
# =========================================================

var stat_points_per_level: int = 0

var stat_points_per_reset: int = 0

var level_points: int = 0

var reset_points: int = 0

var bonus_stat_points: int = 0

var total_points: int = 0

var spent_points: int = 0

var unspent_points: int = 0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_class_id: String,
	p_revision: int,
	p_level: int,
	p_reset_count: int,
	p_base_strength: int,
	p_base_agility: int,
	p_base_vitality: int,
	p_base_energy: int,
	p_allocated_strength: int,
	p_allocated_agility: int,
	p_allocated_vitality: int,
	p_allocated_energy: int,
	p_stat_points_per_level: int,
	p_stat_points_per_reset: int,
	p_level_points: int,
	p_reset_points: int,
	p_bonus_stat_points: int,
	p_total_points: int,
	p_spent_points: int,
	p_unspent_points: int
) -> void:
	class_id = (
		p_class_id
		.strip_edges()
		.to_lower()
	)


	revision = p_revision

	level = p_level

	reset_count = p_reset_count


	base_strength = p_base_strength

	base_agility = p_base_agility

	base_vitality = p_base_vitality

	base_energy = p_base_energy


	allocated_strength = p_allocated_strength

	allocated_agility = p_allocated_agility

	allocated_vitality = p_allocated_vitality

	allocated_energy = p_allocated_energy


	permanent_strength = (
		base_strength
		+
		allocated_strength
	)

	permanent_agility = (
		base_agility
		+
		allocated_agility
	)

	permanent_vitality = (
		base_vitality
		+
		allocated_vitality
	)

	permanent_energy = (
		base_energy
		+
		allocated_energy
	)


	stat_points_per_level = (
		p_stat_points_per_level
	)

	stat_points_per_reset = (
		p_stat_points_per_reset
	)

	level_points = p_level_points

	reset_points = p_reset_points

	bonus_stat_points = (
		p_bonus_stat_points
	)

	total_points = p_total_points

	spent_points = p_spent_points

	unspent_points = p_unspent_points


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if class_id.is_empty():
		return false


	if revision < 0:
		return false


	if level < 1:
		return false


	if reset_count < 0:
		return false


	if (
		base_strength < 0
		or
		base_agility < 0
		or
		base_vitality < 0
		or
		base_energy < 0
	):
		return false


	if (
		allocated_strength < 0
		or
		allocated_agility < 0
		or
		allocated_vitality < 0
		or
		allocated_energy < 0
	):
		return false


	if (
		permanent_strength
		!=
		base_strength + allocated_strength
	):
		return false


	if (
		permanent_agility
		!=
		base_agility + allocated_agility
	):
		return false


	if (
		permanent_vitality
		!=
		base_vitality + allocated_vitality
	):
		return false


	if (
		permanent_energy
		!=
		base_energy + allocated_energy
	):
		return false


	if stat_points_per_level <= 0:
		return false


	if stat_points_per_reset <= 0:
		return false


	if (
		level_points
		!=
		(
			(level - 1)
			*
			stat_points_per_level
		)
	):
		return false


	if (
		reset_points
		!=
		(
			reset_count
			*
			stat_points_per_reset
		)
	):
		return false


	if bonus_stat_points < 0:
		return false


	if (
		spent_points
		!=
		(
			allocated_strength
			+
			allocated_agility
			+
			allocated_vitality
			+
			allocated_energy
		)
	):
		return false


	if (
		total_points
		!=
		(
			level_points
			+
			reset_points
			+
			bonus_stat_points
		)
	):
		return false


	if spent_points > total_points:
		return false


	if (
		unspent_points
		!=
		total_points - spent_points
	):
		return false


	# -----------------------------------------------------
	# Revision 0 significa que Backend no tiene todavía
	# una fila durable de allocation.
	#
	# Por contrato:
	#
	# allocated = 0
	# bonus = 0
	# -----------------------------------------------------

	if revision == 0:
		if spent_points != 0:
			return false


		if bonus_stat_points != 0:
			return false


	return true


# =========================================================
# SNAPSHOT INTERNO
# =========================================================

func to_snapshot() -> Dictionary:
	return {
		"revision": revision,

		"progression": {
			"level": level,
			"reset_count": reset_count,
		},

		"base": {
			"strength": base_strength,
			"agility": base_agility,
			"vitality": base_vitality,
			"energy": base_energy,
		},

		"allocated": {
			"strength": allocated_strength,
			"agility": allocated_agility,
			"vitality": allocated_vitality,
			"energy": allocated_energy,
		},

		"permanent": {
			"strength": permanent_strength,
			"agility": permanent_agility,
			"vitality": permanent_vitality,
			"energy": permanent_energy,
		},

		"bonus_stat_points": bonus_stat_points,

		"budget": {
			"points_per_level": (
				stat_points_per_level
			),

			"points_per_reset": (
				stat_points_per_reset
			),

			"level_points": level_points,

			"reset_points": reset_points,

			"bonus_points": (
				bonus_stat_points
			),

			"total_points": total_points,

			"spent_points": spent_points,

			"unspent_points": unspent_points,
		},
	}
