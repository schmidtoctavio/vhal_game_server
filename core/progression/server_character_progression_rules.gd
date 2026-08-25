class_name ServerCharacterProgressionRules
extends RefCounted


# =========================================================
# FOUNDATION / TESTING
# =========================================================
#
# Curva temporal para validar el sistema:
#
# cada nivel requiere 100 EXP.
#
# NO es balance final.
# =========================================================

const TEST_EXPERIENCE_REQUIRED_PER_LEVEL: int = 100

const MAX_LEVEL: int = 65_535


# =========================================================
# EXP REQUERIDA
# =========================================================

static func get_experience_required(
	level: int
) -> int:
	if (
		level <= 0
		or
		level > MAX_LEVEL
	):
		return 0


	return TEST_EXPERIENCE_REQUIRED_PER_LEVEL


# =========================================================
# VALIDAR ESTADO
# =========================================================

static func is_state_valid(
	level: int,
	experience: int
) -> bool:
	var required := (
		get_experience_required(
			level
		)
	)


	if required <= 0:
		return false


	if experience < 0:
		return false


	if experience >= required:
		return false


	return true


# =========================================================
# APLICAR EXPERIENCIA
# =========================================================

static func apply_experience(
	level: int,
	experience: int,
	gained_experience: int
) -> Dictionary:
	if gained_experience <= 0:
		return {}


	if not is_state_valid(
		level,
		experience
	):
		return {}


	var next_level := level

	var next_experience := (
		experience
		+
		gained_experience
	)


	var levels_gained := 0


	while next_level < MAX_LEVEL:
		var required := (
			get_experience_required(
				next_level
			)
		)


		if required <= 0:
			return {}


		if next_experience < required:
			break


		next_experience -= required

		next_level += 1

		levels_gained += 1


	# -----------------------------------------------------
	# MAX LEVEL FOUNDATION
	# -----------------------------------------------------

	if next_level >= MAX_LEVEL:
		var required_at_max := (
			get_experience_required(
				MAX_LEVEL
			)
		)


		next_experience = mini(
			next_experience,
			required_at_max - 1
		)


	return {
		"level": next_level,

		"experience": next_experience,

		"experience_required": (
			get_experience_required(
				next_level
			)
		),

		"experience_gained": gained_experience,

		"levels_gained": levels_gained,
	}
