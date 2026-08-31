class_name ServerPhysicalDamageMitigationRules
extends RefCounted


# =========================================================
# PHYSICAL DAMAGE — ARMOR MITIGATION
#
# F22-G1-B
#
# Foundation:
#
# reduction
# =
# armor
# /
# (armor + K)
#
# Equivalent:
#
# post_mitigation_damage
# =
# pre_mitigation_damage
# *
# K
# /
# (armor + K)
#
# K queda centralizado aquí.
# Más adelante podrá evolucionar según Level,
# Content Tier o PvP Profile sin duplicar fórmula.
# =========================================================

const ARMOR_MITIGATION_CONSTANT: float = 1000.0


# =========================================================
# CALCULAR POST-MITIGATION DAMAGE
# =========================================================

static func calculate_post_mitigation_damage(
	pre_mitigation_damage: int,
	armor_rating: int
) -> int:
	if pre_mitigation_damage <= 0:
		return 0


	if armor_rating < 0:
		return 0


	if armor_rating == 0:
		return pre_mitigation_damage


	var denominator := (
		ARMOR_MITIGATION_CONSTANT
		+
		float(armor_rating)
	)


	if denominator <= 0.0:
		return 0


	var mitigated_damage := int(
		floor(
			float(pre_mitigation_damage)
			*
			ARMOR_MITIGATION_CONSTANT
			/
			denominator
		)
	)


	return maxi(
		mitigated_damage,
		1
	)
