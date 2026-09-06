class_name ServerSkillScalingProfile
extends RefCounted


# =========================================================
# POWER SOURCES
# =========================================================

const POWER_NONE: String = "none"

const POWER_PHYSICAL: String = "physical_power"

const POWER_MAGIC: String = "magic_power"

const POWER_HEALING: String = "healing_power"


# =========================================================
# FLAT EFFECT
# =========================================================

var flat_effect_value: int = 0


# =========================================================
# POWER SCALING
# =========================================================

var power_source: String = POWER_NONE

var power_coefficient: float = 0.0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_flat_effect_value: int = 0,
	p_power_source: String = POWER_NONE,
	p_power_coefficient: float = 0.0
) -> void:
	flat_effect_value = (
		p_flat_effect_value
	)


	power_source = (
		p_power_source
		.strip_edges()
		.to_lower()
	)


	power_coefficient = (
		p_power_coefficient
	)


# =========================================================
# POWER SCALING
# =========================================================

func has_power_scaling() -> bool:
	return (
		power_source != POWER_NONE
		and
		power_coefficient > 0.0
	)


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if flat_effect_value < 0:
		return false


	if power_coefficient < 0.0:
		return false


	match power_source:
		POWER_NONE:
			return (
				power_coefficient == 0.0
			)

		POWER_PHYSICAL:
			return (
				power_coefficient > 0.0
			)

		POWER_MAGIC:
			return (
				power_coefficient > 0.0
			)

		POWER_HEALING:
			return (
				power_coefficient > 0.0
			)


	return false
