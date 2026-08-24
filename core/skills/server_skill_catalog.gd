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
				ServerSkillDefinition.TARGET_ENTITY
			)

		POISON_ID:
			return ServerSkillDefinition.new(
				POISON_ID,
				20,
				5.0,
				ServerSkillDefinition.TARGET_ENTITY
			)

		HEAL_ID:
			return ServerSkillDefinition.new(
				HEAL_ID,
				40,
				4.0,
				ServerSkillDefinition.TARGET_SELF
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


	return ""
