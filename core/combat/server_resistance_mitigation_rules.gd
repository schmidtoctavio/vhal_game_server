class_name ServerResistanceMitigationRules
extends RefCounted


# =========================================================
# DIMINISHING RESISTANCE RATING
#
# reduction:
#
# rating
# /
# (rating + K)
#
# remaining:
#
# K
# /
# (rating + K)
#
# Foundation:
#
# K = 1000
# =========================================================

const RATING_MITIGATION_CONSTANT: float = 1000.0


# =========================================================
# MITIGAR
# =========================================================

static func calculate_post_mitigation_damage(
	pre_mitigation_damage: int,
	resistance_rating: int
) -> int:
	if pre_mitigation_damage <= 0:
		return 0


	if resistance_rating < 0:
		return 0


	if resistance_rating == 0:
		return pre_mitigation_damage


	var denominator := (
		RATING_MITIGATION_CONSTANT
		+
		float(resistance_rating)
	)


	if denominator <= 0.0:
		return 0


	var mitigated_damage := int(
		floor(
			float(pre_mitigation_damage)
			*
			RATING_MITIGATION_CONSTANT
			/
			denominator
		)
	)


	return maxi(
		mitigated_damage,
		1
	)


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	if (
		calculate_post_mitigation_damage(
			100,
			0
		)
		!=
		100
	):
		return (
			"Resistance 0 debe conservar Damage 100."
		)


	if (
		calculate_post_mitigation_damage(
			584,
			100
		)
		!=
		530
	):
		return (
			"Rating 100 debe conservar "
			+
			"el caso 584 → 530."
		)


	if (
		calculate_post_mitigation_damage(
			100,
			1000
		)
		!=
		50
	):
		return (
			"Rating 1000 debe resolver "
			+
			"Damage 100 → 50."
		)


	if (
		calculate_post_mitigation_damage(
			100,
			-1
		)
		!=
		0
	):
		return (
			"Resistance negativa debe ser inválida."
		)


	return ""
