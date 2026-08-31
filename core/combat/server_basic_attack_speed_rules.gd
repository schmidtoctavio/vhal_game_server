class_name ServerBasicAttackSpeedRules
extends RefCounted


# =========================================================
# BASIC ATTACK — EFFECTIVE COOLDOWN
#
# F22-H1-B
#
# El Attack Profile conserva el cooldown base del arma.
#
# El personaje aporta:
#
# attack_speed_multiplier
#
# Fórmula:
#
# effective_cooldown
# =
# base_cooldown
# /
# attack_speed_multiplier
#
# Ejemplos:
#
# Base 1.0 / Speed 1.0 = 1.0 s
# Base 1.0 / Speed 1.25 = 0.8 s
# Base 0.9 / Speed 1.0 = 0.9 s
#
# Esta clase NO decide de dónde sale Attack Speed.
# Consume el Derived Stat ya resuelto.
# =========================================================


static func calculate_effective_cooldown_seconds(
	base_cooldown_seconds: float,
	attack_speed_multiplier: float
) -> float:
	if base_cooldown_seconds < 0.0:
		return -1.0


	if attack_speed_multiplier <= 0.0:
		return -1.0


	return (
		base_cooldown_seconds
		/
		attack_speed_multiplier
	)
