class_name ServerSkillPrimaryStatRequirements
extends RefCounted


# =========================================================
# REQUIREMENTS
# =========================================================

var minimum_strength: int = 0

var minimum_agility: int = 0

var minimum_vitality: int = 0

var minimum_energy: int = 0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_minimum_strength: int = 0,
	p_minimum_agility: int = 0,
	p_minimum_vitality: int = 0,
	p_minimum_energy: int = 0
) -> void:
	minimum_strength = p_minimum_strength

	minimum_agility = p_minimum_agility

	minimum_vitality = p_minimum_vitality

	minimum_energy = p_minimum_energy


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		minimum_strength >= 0
		and
		minimum_agility >= 0
		and
		minimum_vitality >= 0
		and
		minimum_energy >= 0
	)


# =========================================================
# VALIDAR PRIMARY STATS
# =========================================================

func validate(
	primary_stats: ServerCharacterPrimaryStatsState
) -> String:
	if primary_stats == null:
		return "primary_stats_unavailable"


	if not primary_stats.is_valid():
		return "primary_stats_unavailable"


	if (
		primary_stats.permanent_strength
		<
		minimum_strength
	):
		return "strength_requirement_not_met"


	if (
		primary_stats.permanent_agility
		<
		minimum_agility
	):
		return "agility_requirement_not_met"


	if (
		primary_stats.permanent_vitality
		<
		minimum_vitality
	):
		return "vitality_requirement_not_met"


	if (
		primary_stats.permanent_energy
		<
		minimum_energy
	):
		return "energy_requirement_not_met"


	return ""


# =========================================================
# CONTRATO
# =========================================================

static func validate_contract() -> String:
	var requirements := (
		ServerSkillPrimaryStatRequirements.new(
			0,
			0,
			0,
			20
		)
	)


	if not requirements.is_valid():
		return (
			"No se pudo crear Skill Requirements foundation."
		)


	# -----------------------------------------------------
	# WARRIOR CON PERMANENT ENERGY 20
	#
	# Base ENE      10
	# Allocated ENE 10
	# Permanent     20
	#
	# Debe permitir.
	# -----------------------------------------------------

	var enough_energy := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			1,
			5,
			0,
			25,
			15,
			25,
			10,
			0,
			0,
			0,
			10,
			5,
			200,
			20,
			0,
			0,
			20,
			10,
			10
		)
	)


	if (
		enough_energy == null
		or
		not enough_energy.is_valid()
	):
		return (
			"No se pudo crear Primary Stats "
			+
			"válido para Skill Requirements."
		)


	var valid_result := (
		requirements.validate(
			enough_energy
		)
	)


	if not valid_result.is_empty():
		return (
			"Permanent Energy 20 fue rechazada: "
			+
			valid_result
		)


	# -----------------------------------------------------
	# WARRIOR CON PERMANENT ENERGY 19
	#
	# Debe rechazar.
	# -----------------------------------------------------

	var insufficient_energy := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			1,
			5,
			0,
			25,
			15,
			25,
			10,
			0,
			0,
			0,
			9,
			5,
			200,
			20,
			0,
			0,
			20,
			9,
			11
		)
	)


	if (
		insufficient_energy == null
		or
		not insufficient_energy.is_valid()
	):
		return (
			"No se pudo crear Primary Stats insuficiente "
			+
			"para Skill Requirements."
		)


	var invalid_result := (
		requirements.validate(
			insufficient_energy
		)
	)


	if (
		invalid_result
		!=
		"energy_requirement_not_met"
	):
		return (
			"Permanent Energy 19 debía ser rechazada "
			+
			"por Energy Requirement."
		)


	return ""
