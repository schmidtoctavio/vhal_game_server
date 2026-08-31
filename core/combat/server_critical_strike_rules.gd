class_name ServerCriticalStrikeRules
extends RefCounted


# =========================================================
# CRITICAL STRIKE — FOUNDATION
#
# F22-G2-B
#
# Esta clase NO decide de dónde sale Critical Chance.
#
# Consume valores autoritativos ya resueltos:
#
# - critical_strike_chance
# - critical_damage_multiplier
#
# El roll también es generado por el Game Server.
# =========================================================


# =========================================================
# RESOLVER CRITICAL
# =========================================================

static func is_critical_roll(
	critical_strike_chance: float,
	roll: float
) -> bool:
	if critical_strike_chance < 0.0:
		return false


	if critical_strike_chance > 1.0:
		return false


	if roll < 0.0:
		return false


	if roll > 1.0:
		return false


	if critical_strike_chance <= 0.0:
		return false


	if critical_strike_chance >= 1.0:
		return true


	return (
		roll
		<
		critical_strike_chance
	)


# =========================================================
# APLICAR MULTIPLIER
# =========================================================

static func calculate_critical_damage(
	base_damage: int,
	is_critical: bool,
	critical_damage_multiplier: float
) -> int:
	if base_damage <= 0:
		return 0


	if critical_damage_multiplier < 1.0:
		return 0


	if not is_critical:
		return base_damage


	var critical_damage := int(
		floor(
			float(base_damage)
			*
			critical_damage_multiplier
		)
	)


	return maxi(
		critical_damage,
		1
	)
