class_name ServerSkillUsageRules
extends RefCounted


# =========================================================
# CAST USAGE ELIGIBILITY
# =========================================================
#
# IMPORTANTE:
#
# Learning Requirements y Usage Requirements NO son
# lo mismo.
#
# Class / Level / Permanent Primary Stats determinan si
# una Skill puede APRENDERSE.
#
# Una vez aprendida, esos requisitos NO vuelven a
# evaluarse durante cada cast.
#
# Esto permite que el ownership durable sobreviva a
# cambios de Level/Stats producidos por un Reset futuro.
#
# El cast sigue sujeto a:
#
# - Skill ownership
# - Character alive
# - Target
# - Mana
# - Cooldown
# - reglas específicas del efecto
# =========================================================

static func validate_cast_usage(
	definition: ServerSkillDefinition,
	skill_runtime: ServerSkillRuntimeState
) -> String:
	if definition == null:
		return "unknown_skill"


	if not definition.is_valid():
		return "unknown_skill"


	if skill_runtime == null:
		return "runtime_failure"


	if not skill_runtime.is_valid():
		return "runtime_failure"


	if not skill_runtime.has_learned_skill(
		definition.skill_id
	):
		return "skill_not_learned"


	return ""


# =========================================================
# CONTRATO
# =========================================================

static func validate_contract() -> String:
	var definition := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.HEAL_ID
		)
	)


	if definition == null:
		return (
			"No se pudo resolver Heal para Usage Contract."
		)


	var runtime := (
		ServerSkillRuntimeState.new()
	)


	var before_learning := (
		validate_cast_usage(
			definition,
			runtime
		)
	)


	if before_learning != "skill_not_learned":
		return (
			"Skill Usage permitió una Skill no aprendida."
		)


	if not runtime.learn_skill(
		ServerSkillCatalog.HEAL_ID
	):
		return (
			"Skill Usage no pudo preparar ownership."
		)


	var after_learning := (
		validate_cast_usage(
			definition,
			runtime
		)
	)


	if not after_learning.is_empty():
		return (
			"Skill aprendida fue rechazada por Usage: "
			+
			after_learning
		)


	return ""
