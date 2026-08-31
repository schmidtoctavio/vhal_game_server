class_name ServerBasicAttackDamageRules
extends RefCounted


# =========================================================
# BASIC ATTACK — PRE-MITIGATION DAMAGE
#
# F22-F3-D1
#
# En esta foundation, Basic Attack usa:
#
# - Base Damage del Attack Profile autoritativo.
# - Physical Power derivado del personaje.
#
# Todavía NO participan:
#
# - defensa del objetivo
# - armor
# - critical
# - block
# - penetration
# - buffs/debuffs
# - multiplicadores de skill
#
# Esos sistemas deberán consumir este resultado
# en etapas posteriores.
# =========================================================

static func calculate_pre_mitigation_damage(
	attack_profile: Dictionary,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if attack_profile.is_empty():
		return 0


	if derived_stats == null:
		return 0


	if not derived_stats.is_valid():
		return 0


	var base_damage := int(
		attack_profile.get(
			"base_damage",
			0
		)
	)


	if base_damage <= 0:
		return 0


	if derived_stats.physical_power < 0:
		return 0


	return (
		base_damage
		+
		derived_stats.physical_power
	)
