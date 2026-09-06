class_name ServerSkillPeriodicDamageRules
extends RefCounted


static func calculate_tick_damage(
	definition: ServerSkillDefinition,
	derived_stats: ServerCharacterDerivedStatsState
) -> int:
	if definition == null:
		return 0

	if not definition.is_valid():
		return 0

	if definition.status_effect_profile == null:
		return 0

	if not definition.status_effect_profile.is_valid():
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


static func validate_contract() -> String:
	var poison := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.POISON_ID
		)
	)

	if poison == null:
		return "No se pudo resolver Poison."

	if (
		poison.target_kind
		!=
		ServerSkillDefinition.TARGET_ENTITY
	):
		return "Poison debe utilizar target entity."

	if not is_equal_approx(
		poison.cast_range,
		6.0
	):
		return "Poison debe conservar cast range 6.0."

	if poison.status_effect_profile == null:
		return "Poison no posee Status Effect Profile."

	if (
		poison.status_effect_profile.effect_id
		!=
		ServerSkillCatalog.POISON_ID
	):
		return "Poison debe utilizar effect_id poison."

	if (
		poison.status_effect_profile.damage_type
		!=
		ServerSkillDamageProfile.DAMAGE_POISON
	):
		return "Poison debe utilizar Poison Damage."

	if not is_equal_approx(
		poison.status_effect_profile.tick_interval_seconds,
		1.0
	):
		return "Poison debe conservar intervalo de 1 segundo."

	if poison.status_effect_profile.tick_count != 5:
		return "Poison debe conservar 5 ticks."

	if (
		poison.status_effect_profile.refresh_policy
		!=
		ServerSkillStatusEffectProfile.REFRESH_REPLACE
	):
		return "Poison debe utilizar refresh replace."

	if poison.scaling_profile == null:
		return "Poison no posee Scaling Profile."

	if (
		poison.scaling_profile.power_source
		!=
		ServerSkillScalingProfile.POWER_PHYSICAL
	):
		return "Poison debe escalar con Physical Power."

	if (
		poison.scaling_profile.flat_effect_value
		!=
		0
	):
		return "Poison debe conservar flat effect 0."

	if not is_equal_approx(
		poison.scaling_profile.power_coefficient,
		0.20
	):
		return "Poison debe conservar coefficient 0.20."

	var archer_derived := (
		ServerCharacterDerivedStatsState.new(
			"archer",
			0,
			10,
			0,
			184,
			148,
			0,
			0,
			93,
			15,
			15,
			0.0,
			1.5,
			1.0,
			4.0
		)
	)

	if not archer_derived.is_valid():
		return "No se pudo crear Archer foundation."

	var tick_damage := (
		calculate_tick_damage(
			poison,
			archer_derived
		)
	)

	if tick_damage != 18:
		return (
			"Poison con Physical Power 93 "
			+
			"debe producir 18 Damage por tick."
		)

	return ""
