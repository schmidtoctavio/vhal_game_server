class_name ServerSkillScalingResolver
extends RefCounted


# =========================================================
# RESOLVER EFFECT VALUE
# =========================================================
#
# Fórmula canónica:
#
# Effect
# =
# Flat Effect
# +
# Power Source * Coefficient
#
# El Game Server es la única autoridad de esta resolución.
# =========================================================

static func calculate_effect_value(
	profile: ServerSkillScalingProfile,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if profile == null:
		return 0


	if not profile.is_valid():
		return 0


	if derived_stats == null:
		return 0


	if not derived_stats.is_valid():
		return 0


	var source_power := (
		_resolve_power_source(
			profile.power_source,
			derived_stats
		)
	)


	if source_power < 0:
		return 0


	var resolved_value := (
		float(
			profile.flat_effect_value
		)
		+
		(
			float(
				source_power
			)
			*
			profile.power_coefficient
		)
	)


	if resolved_value <= 0.0:
		return 0


	return int(
		floor(
			resolved_value
		)
	)


# =========================================================
# RESOLVER POWER SOURCE
# =========================================================

static func _resolve_power_source(
	power_source: String,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	match power_source:
		ServerSkillScalingProfile.POWER_NONE:
			return 0

		ServerSkillScalingProfile.POWER_PHYSICAL:
			return (
				derived_stats.physical_power
			)

		ServerSkillScalingProfile.POWER_MAGIC:
			return (
				derived_stats.magic_power
			)

		ServerSkillScalingProfile.POWER_HEALING:
			return (
				derived_stats.healing_power
			)


	return -1
