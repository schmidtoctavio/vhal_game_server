class_name ServerBasicAttackDamageRules
extends RefCounted


# =========================================================
# BASIC ATTACK — RAW DAMAGE
#
# Foundation:
#
# Weapon / Unarmed Base Damage
# +
# Physical Power
#
# El resultado todavía NO incluye:
#
# - Critical
# - Armor
# - Element Resistance
# - future PvP modifiers
#
# Esas capas pertenecen a ServerDamageResolver.
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


# =========================================================
# DAMAGE RESOLUTION CONTEXT
# =========================================================

static func build_resolution_context(
	attack_profile: Dictionary,
	derived_stats: ServerCharacterDerivedStatsState
) -> ServerDamageResolutionContext:
	var raw_damage := (
		calculate_pre_mitigation_damage(
			attack_profile,
			derived_stats
		)
	)


	if raw_damage <= 0:
		return null


	var attack_mode := String(
		attack_profile.get(
			"mode",
			""
		)
	).strip_edges().to_lower()


	var weapon_item_id := String(
		attack_profile.get(
			"weapon_item_id",
			""
		)
	).strip_edges().to_lower()


	var source_id := (
		weapon_item_id
	)


	if source_id.is_empty():
		source_id = attack_mode


	if source_id.is_empty():
		return null


	var context := (
		ServerDamageResolutionContext.new(
			raw_damage,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			true,
			ServerDamageResolutionContext
				.SOURCE_BASIC_ATTACK,
			source_id
		)
	)


	if not context.is_valid():
		return null


	return context
