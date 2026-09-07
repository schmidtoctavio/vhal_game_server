class_name ServerPhysicalDamageMitigationRules
extends RefCounted


# =========================================================
# PHYSICAL DAMAGE — ARMOR MITIGATION
#
# Compatibility wrapper.
#
# La curva genérica vive ahora en:
#
# ServerResistanceMitigationRules
#
# Basic Attack conserva esta API hasta que F24-C/F24-D
# migren todo al Unified Damage Resolver.
# =========================================================

const ARMOR_MITIGATION_CONSTANT: float = (
	ServerResistanceMitigationRules
	.RATING_MITIGATION_CONSTANT
)


static func calculate_post_mitigation_damage(
	pre_mitigation_damage: int,
	armor_rating: int
) -> int:
	return (
		ServerResistanceMitigationRules
		.calculate_post_mitigation_damage(
			pre_mitigation_damage,
			armor_rating
		)
	)
