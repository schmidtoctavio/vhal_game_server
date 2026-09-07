class_name ServerDamageResolver
extends RefCounted


# =========================================================
# RESOLVER
#
# Pipeline:
#
# Raw Damage
# → Critical
# → School Mitigation
# → Element Mitigation
# → Final Damage
#
#
# Todavía NO participan:
#
# - Accuracy / Evasion
# - Block
# - Penetration
# - PvP modifiers
# - bonus/more multipliers
#
# Esas capas se incorporarán sin duplicar el pipeline.
# =========================================================

static func resolve(
	context: ServerDamageResolutionContext,
	defense_profile: ServerDamageDefenseProfile,
	critical_strike_chance: float = 0.0,
	critical_damage_multiplier: float = 1.0,
	critical_roll: float = 0.0
) -> ServerDamageResolutionResult:
	if context == null:
		return null


	if not context.is_valid():
		return null


	if defense_profile == null:
		return null


	if not defense_profile.is_valid():
		return null


	# -----------------------------------------------------
	# CRITICAL
	# -----------------------------------------------------

	var resolved_critical_applied := false

	var resolved_critical_roll := 0.0

	var resolved_critical_multiplier := 1.0

	var pre_mitigation_damage := (
		context.raw_damage
	)


	if context.can_critical:
		if (
			critical_strike_chance < 0.0
			or
			critical_strike_chance > 1.0
		):
			return null


		if critical_damage_multiplier < 1.0:
			return null


		if (
			critical_roll < 0.0
			or
			critical_roll > 1.0
		):
			return null


		resolved_critical_roll = (
			critical_roll
		)


		resolved_critical_multiplier = (
			critical_damage_multiplier
		)


		resolved_critical_applied = (
			ServerCriticalStrikeRules
			.is_critical_roll(
				critical_strike_chance,
				critical_roll
			)
		)


		pre_mitigation_damage = (
			ServerCriticalStrikeRules
			.calculate_critical_damage(
				context.raw_damage,
				resolved_critical_applied,
				critical_damage_multiplier
			)
		)


	if pre_mitigation_damage <= 0:
		return null


	# -----------------------------------------------------
	# SCHOOL MITIGATION
	#
	# physical
	# → Armor
	#
	# magical
	# → Magic Resistance
	# -----------------------------------------------------

	var school_rating := (
		defense_profile.get_school_rating(
			context.school
		)
	)


	if school_rating < 0:
		return null


	var post_school_damage := (
		ServerResistanceMitigationRules
		.calculate_post_mitigation_damage(
			pre_mitigation_damage,
			school_rating
		)
	)


	if post_school_damage <= 0:
		return null


	# -----------------------------------------------------
	# ELEMENT MITIGATION
	#
	# none
	# → 0
	#
	# fire / cold / lightning / poison
	# → elemental rating correspondiente
	# -----------------------------------------------------

	var element_rating := (
		defense_profile.get_element_rating(
			context.element
		)
	)


	if element_rating < 0:
		return null


	var post_element_damage := (
		ServerResistanceMitigationRules
		.calculate_post_mitigation_damage(
			post_school_damage,
			element_rating
		)
	)


	if post_element_damage <= 0:
		return null


	# -----------------------------------------------------
	# FUTURE PvP HOOK
	#
	# PvP modifier deberá entrar entre:
	#
	# post_element_damage
	# →
	# final_damage
	#
	# sin duplicar el Damage Resolver.
	#
	# Foundation actual:
	#
	# final_damage = post_element_damage
	# -----------------------------------------------------

	var final_damage := (
		post_element_damage
	)


	var result := (
		ServerDamageResolutionResult.new(
			context.source_kind,
			context.source_id,
			context.school,
			context.element,
			context.delivery,
			context.raw_damage,
			resolved_critical_applied,
			resolved_critical_roll,
			resolved_critical_multiplier,
			pre_mitigation_damage,
			school_rating,
			post_school_damage,
			element_rating,
			post_element_damage,
			final_damage
		)
	)


	if not result.is_valid():
		return null


	return result


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# =====================================================
	# PHYSICAL / NONE
	#
	# Current Basic Attack compatibility:
	#
	# 584
	# Armor 100
	# →
	# 530
	# =====================================================

	var physical_context := (
		ServerDamageResolutionContext.new(
			584,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			true,
			ServerDamageResolutionContext
				.SOURCE_BASIC_ATTACK,
			"unarmed"
		)
	)


	var physical_defense := (
		ServerDamageDefenseProfile.new(
			100
		)
	)


	var physical_result := (
		resolve(
			physical_context,
			physical_defense,
			0.0,
			1.5,
			0.5
		)
	)


	if physical_result == null:
		return (
			"No se pudo resolver Physical Damage."
		)


	if physical_result.critical_applied:
		return (
			"Critical Chance 0 no debe criticar."
		)


	if (
		physical_result.pre_mitigation_damage
		!=
		584
	):
		return (
			"Physical pre-mitigation debe conservar 584."
		)


	if physical_result.school_rating != 100:
		return (
			"Physical Damage debe consumir Armor 100."
		)


	if physical_result.post_school_damage != 530:
		return (
			"Physical Damage con Armor 100 "
			+
			"debe resolver 530."
		)


	if physical_result.element_rating != 0:
		return (
			"Physical/none no debe consumir "
			+
			"Element Resistance."
		)


	if physical_result.final_damage != 530:
		return (
			"Physical final debe conservar 530."
		)


	# =====================================================
	# GUARANTEED CRITICAL
	#
	# 100
	# × 1.5
	# =
	# 150
	#
	# Armor 100:
	#
	# floor(150 * 1000 / 1100)
	# =
	# 136
	# =====================================================

	var critical_context := (
		ServerDamageResolutionContext.new(
			100,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			true,
			ServerDamageResolutionContext
				.SOURCE_BASIC_ATTACK,
			"critical_test"
		)
	)


	var critical_result := (
		resolve(
			critical_context,
			physical_defense,
			1.0,
			1.5,
			0.25
		)
	)


	if critical_result == null:
		return (
			"No se pudo resolver Critical Damage."
		)


	if not critical_result.critical_applied:
		return (
			"Critical Chance 1 debe criticar."
		)


	if (
		critical_result.pre_mitigation_damage
		!=
		150
	):
		return (
			"Critical 100 × 1.5 debe resolver 150."
		)


	if critical_result.final_damage != 136:
		return (
			"Critical 150 con Armor 100 "
			+
			"debe resolver 136."
		)


	# =====================================================
	# FIRE BALL — ZERO RESISTANCE
	#
	# 138
	# MR 0
	# Fire 0
	# →
	# 138
	# =====================================================

	var fire_context := (
		ServerDamageResolutionContext.new(
			138,
			ServerDamageTaxonomy.SCHOOL_MAGICAL,
			ServerDamageTaxonomy.ELEMENT_FIRE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			false,
			ServerDamageResolutionContext
				.SOURCE_SKILL,
			"fire_ball"
		)
	)


	var zero_defense := (
		ServerDamageDefenseProfile.new()
	)


	var fire_zero_result := (
		resolve(
			fire_context,
			zero_defense
		)
	)


	if fire_zero_result == null:
		return (
			"No se pudo resolver Fire Ball "
			+
			"sin Resistances."
		)


	if fire_zero_result.critical_applied:
		return (
			"Fire Ball foundation no debe criticar."
		)


	if fire_zero_result.school_rating != 0:
		return (
			"Fire Ball sin MR debe consumir rating 0."
		)


	if fire_zero_result.element_rating != 0:
		return (
			"Fire Ball sin Fire Resistance "
			+
			"debe consumir rating 0."
		)


	if fire_zero_result.final_damage != 138:
		return (
			"Fire Ball sin Resistances "
			+
			"debe conservar 138."
		)


	# =====================================================
	# FIRE BALL — MAGIC + FIRE RESISTANCE
	#
	# Raw              138
	#
	# MR 100:
	# floor(138000 / 1100)
	# = 125
	#
	# Fire 50:
	# floor(125000 / 1050)
	# = 119
	# =====================================================

	var fire_defense := (
		ServerDamageDefenseProfile.new(
			0,
			100,
			50
		)
	)


	var fire_resisted_result := (
		resolve(
			fire_context,
			fire_defense
		)
	)


	if fire_resisted_result == null:
		return (
			"No se pudo resolver Fire Ball "
			+
			"con Resistances."
		)


	if fire_resisted_result.school_rating != 100:
		return (
			"Fire Ball debe consumir MR 100."
		)


	if (
		fire_resisted_result.post_school_damage
		!=
		125
	):
		return (
			"Fire Ball con MR 100 "
			+
			"debe resolver 125 tras School."
		)


	if fire_resisted_result.element_rating != 50:
		return (
			"Fire Ball debe consumir Fire Resistance 50."
		)


	if fire_resisted_result.final_damage != 119:
		return (
			"Fire Ball con MR 100 + Fire 50 "
			+
			"debe resolver 119."
		)


	# =====================================================
	# POISON — ZERO RESISTANCE
	#
	# Current foundation tick:
	#
	# 45
	# →
	# 45
	# =====================================================

	var poison_context := (
		ServerDamageResolutionContext.new(
			45,
			ServerDamageTaxonomy.SCHOOL_MAGICAL,
			ServerDamageTaxonomy.ELEMENT_POISON,
			ServerDamageTaxonomy.DELIVERY_PERIODIC,
			false,
			ServerDamageResolutionContext
				.SOURCE_STATUS_EFFECT,
			"poison"
		)
	)


	var poison_zero_result := (
		resolve(
			poison_context,
			zero_defense
		)
	)


	if poison_zero_result == null:
		return (
			"No se pudo resolver Poison "
			+
			"sin Resistances."
		)


	if poison_zero_result.final_damage != 45:
		return (
			"Poison sin Resistances debe conservar 45."
		)


	# =====================================================
	# POISON — MAGIC + POISON RESISTANCE
	#
	# Raw              45
	#
	# MR 80:
	# floor(45000 / 1080)
	# = 41
	#
	# Poison 30:
	# floor(41000 / 1030)
	# = 39
	# =====================================================

	var poison_defense := (
		ServerDamageDefenseProfile.new(
			0,
			80,
			0,
			0,
			0,
			30
		)
	)


	var poison_resisted_result := (
		resolve(
			poison_context,
			poison_defense
		)
	)


	if poison_resisted_result == null:
		return (
			"No se pudo resolver Poison "
			+
			"con Resistances."
		)


	if poison_resisted_result.school_rating != 80:
		return (
			"Poison debe consumir MR 80."
		)


	if (
		poison_resisted_result.post_school_damage
		!=
		41
	):
		return (
			"Poison con MR 80 "
			+
			"debe resolver 41 tras School."
		)


	if poison_resisted_result.element_rating != 30:
		return (
			"Poison debe consumir Poison Resistance 30."
		)


	if poison_resisted_result.final_damage != 39:
		return (
			"Poison con MR 80 + Poison 30 "
			+
			"debe resolver 39."
		)


	return ""
