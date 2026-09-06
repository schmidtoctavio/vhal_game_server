class_name ServerSkillCatalog
extends RefCounted


# =========================================================
# IDS
# =========================================================

const FIRE_BALL_ID: String = "fire_ball"

const POISON_ID: String = "poison"

const HEAL_ID: String = "heal"


# =========================================================
# CATÁLOGO
# =========================================================

static func get_definition(
	skill_id: String
) -> ServerSkillDefinition:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	match normalized_skill_id:
		FIRE_BALL_ID:
			return ServerSkillDefinition.new(
				FIRE_BALL_ID,
				30,
				3.0,
				ServerSkillDefinition.TARGET_ENTITY,

				ServerSkillScalingProfile.new(
					0,
					ServerSkillScalingProfile.POWER_MAGIC,
					1.0
				),

				ServerSkillDamageProfile.new(
					ServerSkillDamageProfile.DAMAGE_MAGIC
				),

				6.0
			)

		POISON_ID:
			return ServerSkillDefinition.new(
				POISON_ID,
				20,
				5.0,
				ServerSkillDefinition.TARGET_ENTITY,

				ServerSkillScalingProfile.new(
					0,
					ServerSkillScalingProfile.POWER_PHYSICAL,
					0.20
				),

				null,

				6.0,

				ServerSkillStatusEffectProfile.new(
					POISON_ID,
					ServerSkillDamageProfile.DAMAGE_POISON,
					1.0,
					5,
					ServerSkillStatusEffectProfile.REFRESH_REPLACE
				)
			)

		HEAL_ID:
			return ServerSkillDefinition.new(
				HEAL_ID,
				40,
				4.0,
				ServerSkillDefinition.TARGET_SELF,

				ServerSkillScalingProfile.new(
					0,
					ServerSkillScalingProfile.POWER_HEALING,
					1.0
				)
			)


	return null


# =========================================================
# CONSULTAR
# =========================================================

static func has_definition(
	skill_id: String
) -> bool:
	return (
		get_definition(
			skill_id
		)
		!=
		null
	)


static func get_all_skill_ids() -> PackedStringArray:
	return PackedStringArray(
		[
			FIRE_BALL_ID,
			POISON_ID,
			HEAL_ID,
		]
	)


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var seen_skill_ids: Dictionary = {}


	for skill_id: String in get_all_skill_ids():
		var normalized_skill_id := (
			skill_id
			.strip_edges()
			.to_lower()
		)


		if normalized_skill_id.is_empty():
			return (
				"Existe un skill_id vacío."
			)


		if seen_skill_ids.has(
			normalized_skill_id
		):
			return (
				"Skill duplicada: "
				+
				normalized_skill_id
			)


		seen_skill_ids[
			normalized_skill_id
		] = true


		var definition := (
			get_definition(
				normalized_skill_id
			)
		)


		if definition == null:
			return (
				"No existe definición para: "
				+
				normalized_skill_id
			)


		if not definition.is_valid():
			return (
				"Definición inválida para: "
				+
				normalized_skill_id
			)


		if definition.skill_id != normalized_skill_id:
			return (
				"El skill_id de la definición no coincide: "
				+
				normalized_skill_id
			)

	# =====================================================
	# HEAL SCALING CONTRACT
	# =====================================================

	var heal_definition := (
		get_definition(
			HEAL_ID
		)
	)


	if heal_definition == null:
		return (
			"No se pudo resolver Heal Scaling Profile."
		)


	if heal_definition.scaling_profile == null:
		return (
			"Heal no posee Scaling Profile."
		)


	if (
		heal_definition
		.scaling_profile
		.power_source
		!=
		ServerSkillScalingProfile.POWER_HEALING
	):
		return (
			"Heal debe utilizar Healing Power."
		)


	if (
		heal_definition
		.scaling_profile
		.flat_effect_value
		!=
		0
	):
		return (
			"Heal debe conservar flat effect 0."
		)


	if not is_equal_approx(
		heal_definition
		.scaling_profile
		.power_coefficient,
		1.0
	):
		return (
			"Heal debe conservar coefficient 1.0."
		)


	# =====================================================
	# RESET-SAFE USAGE CONTRACT
	# =====================================================

	var usage_contract_error := (
		ServerSkillUsageRules.validate_contract()
	)


	if not usage_contract_error.is_empty():
		return (
			"Skill Usage Contract inválido: "
			+
			usage_contract_error
		)

	# =====================================================
	# SKILL DAMAGE CONTRACT
	# =====================================================

	var damage_contract_error := (
		ServerSkillDamageRules.validate_contract()
	)


	if not damage_contract_error.is_empty():
		return (
			"Skill Damage Contract inválido: "
			+
			damage_contract_error
		)


	return ""
