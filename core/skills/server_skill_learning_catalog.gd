class_name ServerSkillLearningCatalog
extends RefCounted


# =========================================================
# SERVICIOS
# =========================================================

const SKILL_TRAINER_SERVICE_ID: String = (
	"skill_trainer"
)


# =========================================================
# CONSULTAR DEFINICIÓN
# =========================================================

static func get_definition(
	skill_id: String
) -> ServerSkillLearningDefinition:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	match normalized_skill_id:
		ServerSkillCatalog.FIRE_BALL_ID:
			return ServerSkillLearningDefinition.new(
				ServerSkillCatalog.FIRE_BALL_ID,
				ServerItemCatalog.SKILL_SCROLL_FIRE_BALL_ID,
				PackedStringArray(
					[
						"mage",
					]
				),
				10,
				SKILL_TRAINER_SERVICE_ID
			)


		ServerSkillCatalog.POISON_ID:
			return ServerSkillLearningDefinition.new(
				ServerSkillCatalog.POISON_ID,
				ServerItemCatalog.SKILL_SCROLL_POISON_ID,
				PackedStringArray(
					[
						"archer",
					]
				),
				10,
				SKILL_TRAINER_SERVICE_ID
			)


		ServerSkillCatalog.HEAL_ID:
			return ServerSkillLearningDefinition.new(
				ServerSkillCatalog.HEAL_ID,
				ServerItemCatalog.SKILL_SCROLL_HEAL_ID,
				PackedStringArray(
					[
						"warrior",
						"mage",
						"archer",
					]
				),
				5,
				SKILL_TRAINER_SERVICE_ID
			)


	return null


# =========================================================
# IDS
# =========================================================

static func get_all_skill_ids() -> PackedStringArray:
	return ServerSkillCatalog.get_all_skill_ids()


# =========================================================
# VALIDACIÓN DEL CONTRATO
# =========================================================

static func validate_contract() -> String:
	var seen_skill_ids: Dictionary = {}

	var seen_scroll_item_ids: Dictionary = {}


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
				"Skill duplicada en Learning Catalog: "
				+
				normalized_skill_id
			)


		seen_skill_ids[
			normalized_skill_id
		] = true


		# -------------------------------------------------
		# SKILL RUNTIME EXISTENTE
		# -------------------------------------------------

		if not ServerSkillCatalog.has_definition(
			normalized_skill_id
		):
			return (
				"Learning Definition referencia una Skill "
				+
				"inexistente: "
				+
				normalized_skill_id
			)


		# -------------------------------------------------
		# LEARNING DEFINITION
		# -------------------------------------------------

		var definition := (
			get_definition(
				normalized_skill_id
			)
		)


		if definition == null:
			return (
				"No existe Learning Definition para: "
				+
				normalized_skill_id
			)


		if not definition.is_valid():
			return (
				"Learning Definition inválida para: "
				+
				normalized_skill_id
			)


		if (
			definition.skill_id
			!=
			normalized_skill_id
		):
			return (
				"El skill_id de Learning Definition "
				+
				"no coincide: "
				+
				normalized_skill_id
			)


		# -------------------------------------------------
		# SCROLL EXISTENTE
		# -------------------------------------------------

		if not ServerItemCatalog.has_definition(
			definition.scroll_item_id
		):
			return (
				"Scroll inexistente para Skill "
				+
				normalized_skill_id
				+
				": "
				+
				definition.scroll_item_id
			)


		# -------------------------------------------------
		# UN SCROLL NO ENSEÑA DOS SKILLS DIFERENTES
		# -------------------------------------------------

		if seen_scroll_item_ids.has(
			definition.scroll_item_id
		):
			return (
				"Scroll duplicado en Learning Catalog: "
				+
				definition.scroll_item_id
			)


		seen_scroll_item_ids[
			definition.scroll_item_id
		] = true


	return ""
