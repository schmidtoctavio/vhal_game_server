class_name ServerHealEffect
extends RefCounted


# =========================================================
# HEAL — FOUNDATION AUTORITATIVA
#
# F22-F3-D2
#
# En esta primera integración:
#
# Requested Heal = Healing Power
#
# Todavía NO participan:
#
# - coeficientes específicos de Skill
# - bonuses de Equipment
# - buffs/debuffs
# - critical healing
# - modificadores del objetivo
#
# Esos sistemas podrán ampliar esta regla posteriormente.
# =========================================================

static func calculate_heal_amount(
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if derived_stats == null:
		return 0


	if not derived_stats.is_valid():
		return 0


	if derived_stats.healing_power <= 0:
		return 0


	return derived_stats.healing_power


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
