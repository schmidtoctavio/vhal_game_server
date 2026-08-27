class_name ServerSkillTrainerOfferBuilder
extends RefCounted


# =========================================================
# CONSTRUIR OFERTAS DEL TRAINER
#
# Esta clase NO persiste nada.
#
# Deriva un estado de presentación autoritativo utilizando:
# - catálogo de aprendizaje del Game Server
# - clase
# - nivel
# - Skills aprendidas
# - Inventory autoritativo
# - servicio Trainer activo
#
# El cliente solamente representará este resultado.
# =========================================================

static func build_offers(
	class_id: String,
	level: int,
	learned_skill_ids: PackedStringArray,
	inventory_snapshot: Dictionary,
	trainer_service_id: String
) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []


	var normalized_class_id := (
		class_id
		.strip_edges()
		.to_lower()
	)


	var normalized_service_id := (
		trainer_service_id
		.strip_edges()
		.to_lower()
	)


	if normalized_class_id.is_empty():
		return offers


	if level <= 0:
		return offers


	if normalized_service_id.is_empty():
		return offers


	# -----------------------------------------------------
	# OWNERSHIP ACTUAL
	# -----------------------------------------------------

	var learned_lookup: Dictionary = {}


	for skill_id: String in learned_skill_ids:
		var normalized_skill_id := (
			skill_id
			.strip_edges()
			.to_lower()
		)


		if normalized_skill_id.is_empty():
			continue


		learned_lookup[
			normalized_skill_id
		] = true


	# -----------------------------------------------------
	# CATÁLOGO
	# -----------------------------------------------------

	var skill_ids := (
		ServerSkillLearningCatalog.get_all_skill_ids()
	)


	skill_ids.sort()


	for skill_id: String in skill_ids:
		var definition := (
			ServerSkillLearningCatalog.get_definition(
				skill_id
			)
		)


		if definition == null:
			continue


		# -------------------------------------------------
		# ESTE TRAINER PUEDE ENSEÑARLA
		# -------------------------------------------------

		if not definition.is_trainer_service_compatible(
			normalized_service_id
		):
			continue


		# -------------------------------------------------
		# SKILLS DE OTRAS CLASES NO SE OFRECEN
		# -------------------------------------------------

		if not definition.is_class_allowed(
			normalized_class_id
		):
			continue


		var scroll_uid := (
			_find_first_scroll_uid(
				inventory_snapshot,
				definition.scroll_item_id
			)
		)


		var already_learned := (
			learned_lookup.has(
				definition.skill_id
			)
		)


		var level_requirement_met := (
			definition.meets_level_requirement(
				level
			)
		)


		var has_scroll := (
			not scroll_uid.is_empty()
		)


		var can_learn := (
			not already_learned
			and
			level_requirement_met
			and
			has_scroll
		)


		var reason := (
			_resolve_unavailable_reason(
				already_learned,
				level_requirement_met,
				has_scroll
			)
		)


		offers.append(
			{
				"skill_id": definition.skill_id,

				"scroll_item_id": (
					definition.scroll_item_id
				),

				"scroll_uid": scroll_uid,

				"minimum_level": (
					definition.minimum_level
				),

				"already_learned": already_learned,

				"level_requirement_met": (
					level_requirement_met
				),

				"has_scroll": has_scroll,

				"can_learn": can_learn,

				"reason": reason,
			}
		)


	return offers


# =========================================================
# BUSCAR SCROLL REAL EN INVENTORY
# =========================================================

static func _find_first_scroll_uid(
	inventory_snapshot: Dictionary,
	scroll_item_id: String
) -> String:
	var normalized_scroll_item_id := (
		scroll_item_id
		.strip_edges()
		.to_lower()
	)


	if normalized_scroll_item_id.is_empty():
		return ""


	var items_value: Variant = (
		inventory_snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return ""


	for item_value: Variant in (
		items_value as Array
	):
		if typeof(item_value) != TYPE_DICTIONARY:
			continue


		var item: Dictionary = (
			item_value as Dictionary
		)


		var item_id := String(
			item.get(
				"item_id",
				""
			)
		).strip_edges().to_lower()


		if item_id != normalized_scroll_item_id:
			continue


		var quantity := int(
			item.get(
				"quantity",
				0
			)
		)


		if quantity <= 0:
			continue


		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges().to_lower()


		if uid.is_empty():
			continue


		return uid


	return ""


# =========================================================
# MOTIVO DE NO DISPONIBILIDAD
# =========================================================

static func _resolve_unavailable_reason(
	already_learned: bool,
	level_requirement_met: bool,
	has_scroll: bool
) -> String:
	if already_learned:
		return "skill_already_learned"


	if not level_requirement_met:
		return "level_requirement_not_met"


	if not has_scroll:
		return "scroll_required"


	return "ok"
