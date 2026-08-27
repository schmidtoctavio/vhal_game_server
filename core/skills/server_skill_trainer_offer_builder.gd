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


# =========================================================
# VALIDAR SNAPSHOT DE OFERTAS
#
# Se utiliza antes de cruzar el boundary de networking.
# El Builder es dueño del contrato de las ofertas.
# =========================================================

static func validate_snapshot(
	snapshot: Dictionary
) -> String:
	if snapshot.is_empty():
		return "El snapshot de Trainer Offers está vacío."


	var character_id := int(
		snapshot.get(
			"character_id",
			0
		)
	)


	if character_id <= 0:
		return "El character_id de Trainer Offers es inválido."


	var npc_id := String(
		snapshot.get(
			"npc_id",
			""
		)
	).strip_edges().to_lower()


	if (
		npc_id.is_empty()
		or
		npc_id.length() > 64
	):
		return "El npc_id de Trainer Offers es inválido."


	var service_id := String(
		snapshot.get(
			"service_id",
			""
		)
	).strip_edges().to_lower()


	if (
		service_id
		!=
		ServerSkillLearningCatalog.SKILL_TRAINER_SERVICE_ID
	):
		return "El servicio de Trainer Offers no es skill_trainer."


	var class_id := String(
		snapshot.get(
			"class_id",
			""
		)
	).strip_edges().to_lower()


	if (
		class_id.is_empty()
		or
		class_id.length() > 64
	):
		return "El class_id de Trainer Offers es inválido."


	var level := int(
		snapshot.get(
			"level",
			0
		)
	)


	if level <= 0:
		return "El nivel de Trainer Offers es inválido."


	var offers_value: Variant = (
		snapshot.get(
			"offers",
			null
		)
	)


	if typeof(offers_value) != TYPE_ARRAY:
		return "Trainer Offers no contiene un Array de ofertas."


	var seen_skill_ids: Dictionary = {}


	for offer_value: Variant in (
		offers_value as Array
	):
		if typeof(offer_value) != TYPE_DICTIONARY:
			return "Trainer Offers contiene una oferta inválida."


		var offer: Dictionary = (
			offer_value as Dictionary
		)


		var skill_id := String(
			offer.get(
				"skill_id",
				""
			)
		).strip_edges().to_lower()


		if (
			skill_id.is_empty()
			or
			skill_id.length() > 64
		):
			return "Trainer Offer contiene un skill_id inválido."


		if seen_skill_ids.has(
			skill_id
		):
			return (
				"Trainer Offer duplicada para Skill: "
				+
				skill_id
			)


		seen_skill_ids[
			skill_id
		] = true


		var definition := (
			ServerSkillLearningCatalog.get_definition(
				skill_id
			)
		)


		if definition == null:
			return (
				"Trainer Offer referencia una Skill desconocida: "
				+
				skill_id
			)


		if not definition.is_trainer_service_compatible(
			service_id
		):
			return (
				"Trainer Offer incompatible con el servicio: "
				+
				skill_id
			)


		if not definition.is_class_allowed(
			class_id
		):
			return (
				"Trainer Offer incompatible con la clase: "
				+
				skill_id
			)


		var scroll_item_id := String(
			offer.get(
				"scroll_item_id",
				""
			)
		).strip_edges().to_lower()


		if (
			scroll_item_id
			!=
			definition.scroll_item_id
		):
			return (
				"Trainer Offer posee un Scroll incorrecto: "
				+
				skill_id
			)


		var scroll_uid := String(
			offer.get(
				"scroll_uid",
				""
			)
		).strip_edges().to_lower()


		if scroll_uid.length() > 64:
			return (
				"Trainer Offer posee un Scroll UID inválido: "
				+
				skill_id
			)


		var minimum_level := int(
			offer.get(
				"minimum_level",
				0
			)
		)


		if (
			minimum_level
			!=
			definition.minimum_level
		):
			return (
				"Trainer Offer posee un nivel mínimo incorrecto: "
				+
				skill_id
			)


		if typeof(
			offer.get(
				"already_learned",
				null
			)
		) != TYPE_BOOL:
			return (
				"Trainer Offer posee already_learned inválido: "
				+
				skill_id
			)


		if typeof(
			offer.get(
				"level_requirement_met",
				null
			)
		) != TYPE_BOOL:
			return (
				"Trainer Offer posee level_requirement_met inválido: "
				+
				skill_id
			)


		if typeof(
			offer.get(
				"has_scroll",
				null
			)
		) != TYPE_BOOL:
			return (
				"Trainer Offer posee has_scroll inválido: "
				+
				skill_id
			)


		if typeof(
			offer.get(
				"can_learn",
				null
			)
		) != TYPE_BOOL:
			return (
				"Trainer Offer posee can_learn inválido: "
				+
				skill_id
			)


		var already_learned := bool(
			offer["already_learned"]
		)


		var level_requirement_met := bool(
			offer["level_requirement_met"]
		)


		var has_scroll := bool(
			offer["has_scroll"]
		)


		var can_learn := bool(
			offer["can_learn"]
		)


		if (
			has_scroll
			!=
			not scroll_uid.is_empty()
		):
			return (
				"Trainer Offer posee estado de Scroll inconsistente: "
				+
				skill_id
			)


		var expected_level_requirement_met := (
			definition.meets_level_requirement(
				level
			)
		)


		if (
			level_requirement_met
			!=
			expected_level_requirement_met
		):
			return (
				"Trainer Offer posee estado de nivel inconsistente: "
				+
				skill_id
			)


		var expected_can_learn := (
			not already_learned
			and
			level_requirement_met
			and
			has_scroll
		)


		if can_learn != expected_can_learn:
			return (
				"Trainer Offer posee can_learn inconsistente: "
				+
				skill_id
			)


		var reason := String(
			offer.get(
				"reason",
				""
			)
		).strip_edges().to_lower()


		var expected_reason := (
			_resolve_unavailable_reason(
				already_learned,
				level_requirement_met,
				has_scroll
			)
		)


		if reason != expected_reason:
			return (
				"Trainer Offer posee reason inconsistente: "
				+
				skill_id
			)


	return ""
