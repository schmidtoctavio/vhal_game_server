class_name ServerCharacterProgressionRules
extends RefCounted


# =========================================================
# PROGRESIÓN FOUNDATION
# =========================================================

const MAX_LEVEL: int = 400

const BASE_EXPERIENCE_REQUIRED: int = 50

const LINEAR_EXPERIENCE_FACTOR: int = 15

const QUADRATIC_EXPERIENCE_FACTOR: int = 2


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


	var level_offset := (
		level
		-
		1
	)


	return (
		BASE_EXPERIENCE_REQUIRED
		+
		(
			LINEAR_EXPERIENCE_FACTOR
			*
			level_offset
		)
		+
		(
			QUADRATIC_EXPERIENCE_FACTOR
			*
			level_offset
			*
			level_offset
		)
	)


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
	#
	# El comportamiento final de EXP en Level 400 se
	# resolverá explícitamente en F22-E5.
	#
	# Por ahora preservamos la semántica segura existente:
	# el personaje no supera MAX_LEVEL y EXP se mantiene
	# dentro de un estado válido.
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
