class_name ServerSkillLearningDefinition
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var skill_id: String = ""

var scroll_item_id: String = ""


# =========================================================
# REQUISITOS
# =========================================================

var allowed_class_ids: PackedStringArray = (
	PackedStringArray()
)

var minimum_level: int = 1

var trainer_service_id: String = ""


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_skill_id: String = "",
	p_scroll_item_id: String = "",
	p_allowed_class_ids: PackedStringArray = PackedStringArray(),
	p_minimum_level: int = 1,
	p_trainer_service_id: String = ""
) -> void:
	skill_id = (
		p_skill_id
		.strip_edges()
		.to_lower()
	)


	scroll_item_id = (
		p_scroll_item_id
		.strip_edges()
		.to_lower()
	)


	minimum_level = p_minimum_level


	trainer_service_id = (
		p_trainer_service_id
		.strip_edges()
		.to_lower()
	)


	for class_id: String in p_allowed_class_ids:
		allowed_class_ids.append(
			class_id
			.strip_edges()
			.to_lower()
		)


# =========================================================
# CLASE PERMITIDA
# =========================================================

func is_class_allowed(
	class_id: String
) -> bool:
	var normalized_class_id := (
		class_id
		.strip_edges()
		.to_lower()
	)


	if normalized_class_id.is_empty():
		return false


	return (
		allowed_class_ids.has(
			normalized_class_id
		)
	)


# =========================================================
# NIVEL
# =========================================================

func meets_level_requirement(
	level: int
) -> bool:
	return (
		level >= minimum_level
	)


# =========================================================
# TRAINER
# =========================================================

func is_trainer_service_compatible(
	service_id: String
) -> bool:
	return (
		service_id
		.strip_edges()
		.to_lower()
		==
		trainer_service_id
	)


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if skill_id.is_empty():
		return false


	if scroll_item_id.is_empty():
		return false


	if minimum_level <= 0:
		return false


	if trainer_service_id.is_empty():
		return false


	if allowed_class_ids.is_empty():
		return false


	var seen_class_ids: Dictionary = {}


	for class_id: String in allowed_class_ids:
		if class_id.is_empty():
			return false


		if (
			class_id
			!=
			class_id.strip_edges().to_lower()
		):
			return false


		if seen_class_ids.has(
			class_id
		):
			return false


		seen_class_ids[
			class_id
		] = true


	return true
