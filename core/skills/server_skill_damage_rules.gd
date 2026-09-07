class_name ServerSkillDamageRules
extends RefCounted


# =========================================================
# RAW SKILL DAMAGE
#
# Raw Damage:
#
# Skill Scaling Profile
# → Flat Effect
# + Power Source * Coefficient
#
# Todavía NO participa:
#
# - target resistance
# - armor
# - magic resistance
# - critical
# - penetration
# - PvP modifiers
#
# Estas capas deben consumir este resultado después.
# =========================================================

static func calculate_raw_damage(
	definition: ServerSkillDefinition,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if definition == null:
		return 0


	if not definition.is_valid():
		return 0


	if definition.damage_profile == null:
		return 0


	if not definition.damage_profile.is_valid():
		return 0


	if definition.scaling_profile == null:
		return 0


	if not definition.scaling_profile.is_valid():
		return 0


	return (
		ServerSkillScalingResolver
		.calculate_effect_value(
			definition.scaling_profile,
			derived_stats
		)
	)

# =========================================================
# DAMAGE RESOLUTION CONTEXT
# =========================================================

static func build_resolution_context(
	definition: ServerSkillDefinition,
	derived_stats: ServerCharacterDerivedStatsState
) -> ServerDamageResolutionContext:
	if definition == null:
		return null


	if definition.damage_profile == null:
		return null


	var raw_damage := (
		calculate_raw_damage(
			definition,
			derived_stats
		)
	)


	if raw_damage <= 0:
		return null


	return (
		definition
		.damage_profile
		.build_resolution_context(
			raw_damage,
			ServerDamageResolutionContext.SOURCE_SKILL,
			definition.skill_id
		)
	)


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# FIRE BALL
	# -----------------------------------------------------

	var fire_ball := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.FIRE_BALL_ID
		)
	)


	if fire_ball == null:
		return (
			"No se pudo resolver Fire Ball."
		)


	if fire_ball.damage_profile == null:
		return (
			"Fire Ball no posee Damage Profile."
		)


	if (
		fire_ball.damage_profile.school
		!=
		ServerDamageTaxonomy.SCHOOL_MAGICAL
	):
		return (
			"Fire Ball debe utilizar Magical School."
		)


	if (
		fire_ball.damage_profile.element
		!=
		ServerDamageTaxonomy.ELEMENT_FIRE
	):
		return (
			"Fire Ball debe utilizar Fire Element."
		)


	if (
		fire_ball.damage_profile.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_DIRECT
	):
		return (
			"Fire Ball debe utilizar Direct Delivery."
		)


	if fire_ball.damage_profile.can_critical:
		return (
			"Fire Ball foundation todavía no debe criticar."
		)

	if (
		fire_ball.target_kind
		!=
		ServerSkillDefinition.TARGET_ENTITY
	):
		return (
			"Fire Ball debe utilizar target entity."
		)


	if not is_equal_approx(
		fire_ball.cast_range,
		6.0
	):
		return (
			"Fire Ball foundation debe conservar "
			+
			"cast range 6.0."
		)


	if fire_ball.scaling_profile == null:
		return (
			"Fire Ball no posee Scaling Profile."
		)


	if (
		fire_ball.scaling_profile.power_source
		!=
		ServerSkillScalingProfile.POWER_MAGIC
	):
		return (
			"Fire Ball debe escalar con Magic Power."
		)


	if (
		fire_ball.scaling_profile.flat_effect_value
		!=
		0
	):
		return (
			"Fire Ball foundation debe conservar "
			+
			"flat effect 0."
		)


	if not is_equal_approx(
		fire_ball.scaling_profile.power_coefficient,
		1.0
	):
		return (
			"Fire Ball foundation debe conservar "
			+
			"Magic Power coefficient 1.0."
		)


	# -----------------------------------------------------
	# SYNTHETIC MAGE
	#
	# Magic Power = 90
	#
	# Fire Ball:
	#
	# 0 + 90 * 1.0
	# =
	# 90 Raw Magic Damage
	# -----------------------------------------------------

	var mage_derived := (
		ServerCharacterDerivedStatsState.new(
			"mage",
			0,
			1,
			0,
			115,
			295,
			0,
			0,
			15,
			90,
			80,
			0.0,
			1.5,
			1.0,
			4.0
		)
	)


	if not mage_derived.is_valid():
		return (
			"No se pudo crear Mage Derived foundation."
		)


	var fire_ball_damage := (
		calculate_raw_damage(
			fire_ball,
			mage_derived
		)
	)


	if fire_ball_damage != 90:
		return (
			"Fire Ball con Magic Power 90 "
			+
			"debe resolver Raw Damage 90."
		)

	var fire_ball_context := (
		build_resolution_context(
			fire_ball,
			mage_derived
		)
	)


	if (
		fire_ball_context == null
		or
		not fire_ball_context.is_valid()
	):
		return (
			"No se pudo construir Fire Ball Damage Context."
		)


	if fire_ball_context.raw_damage != 90:
		return (
			"Fire Ball Damage Context debe conservar Raw Damage 90."
		)


	if (
		fire_ball_context.school
		!=
		ServerDamageTaxonomy.SCHOOL_MAGICAL
	):
		return (
			"Fire Ball Context debe ser Magical."
		)


	if (
		fire_ball_context.element
		!=
		ServerDamageTaxonomy.ELEMENT_FIRE
	):
		return (
			"Fire Ball Context debe ser Fire."
		)


	if (
		fire_ball_context.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_DIRECT
	):
		return (
			"Fire Ball Context debe ser Direct."
		)

	# -----------------------------------------------------
	# HEAL NO ES DAMAGE
	# -----------------------------------------------------

	var heal := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.HEAL_ID
		)
	)


	if heal == null:
		return (
			"No se pudo resolver Heal."
		)


	if calculate_raw_damage(
		heal,
		mage_derived
	) != 0:
		return (
			"Heal no debe producir Raw Damage."
		)


	# -----------------------------------------------------
	# POISON TODAVÍA NO IMPLEMENTADO
	# -----------------------------------------------------

	var poison := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.POISON_ID
		)
	)


	if poison == null:
		return (
			"No se pudo resolver Poison."
		)


	if calculate_raw_damage(
		poison,
		mage_derived
	) != 0:
		return (
			"Poison todavía no debe producir "
			+
			"Raw Damage directo."
		)


	return ""
