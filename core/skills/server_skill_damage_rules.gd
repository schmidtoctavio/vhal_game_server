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
		fire_ball.damage_profile.damage_type
		!=
		ServerSkillDamageProfile.DAMAGE_MAGIC
	):
		return (
			"Fire Ball debe utilizar Magic Damage."
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
