class_name ServerHealEffect
extends RefCounted


# =========================================================
# HEAL AUTORITATIVO
#
# F22-J
#
# Heal ya no conoce directamente la fórmula:
#
# Requested Heal = Healing Power
#
# Ahora consume el Scaling Profile autoritativo declarado
# por ServerSkillCatalog.
#
# Balance actual:
#
# Heal
# =
# 0
# +
# Healing Power * 1.0
#
# El resultado permanece idéntico al comportamiento
# anterior.
# =========================================================

static func calculate_heal_amount(
	definition: ServerSkillDefinition,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if definition == null:
		return 0


	if not definition.is_valid():
		return 0


	if definition.scaling_profile == null:
		return 0


	return (
		ServerSkillScalingResolver
		.calculate_effect_value(
			definition.scaling_profile,
			derived_stats
		)
	)


# =========================================================
# APLICAR HEAL
# =========================================================

static func apply(
	vitals: ServerVitalsState,
	requested_heal_amount: int
) -> int:
	if vitals == null:
		return 0


	if not vitals.is_valid():
		return 0


	if requested_heal_amount <= 0:
		return 0


	return vitals.restore_hp(
		requested_heal_amount
	)
