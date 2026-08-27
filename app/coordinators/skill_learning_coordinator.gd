class_name SkillLearningCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var world_session_registry: WorldSessionRegistry = null

var backend_repository: BackendCharacterSkillLearningRepository = null


# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_world_session_registry: WorldSessionRegistry,
	p_backend_repository: BackendCharacterSkillLearningRepository
) -> bool:
	if configured:
		return true


	if p_world_session_registry == null:
		return false


	if p_backend_repository == null:
		return false


	world_session_registry = p_world_session_registry

	backend_repository = p_backend_repository


	configured = true


	print(
		"SkillLearningCoordinator | Inicializado."
	)


	return true


# =========================================================
# REQUEST DE APRENDIZAJE
# =========================================================

func request_learning(
	peer_id: int,
	skill_id: String,
	scroll_uid: String
) -> Error:
	if not configured:
		return ERR_UNAVAILABLE


	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	var normalized_scroll_uid := (
		scroll_uid
		.strip_edges()
		.to_lower()
	)


	if (
		peer_id <= 1
		or
		normalized_skill_id.is_empty()
		or
		normalized_scroll_uid.is_empty()
	):
		return ERR_INVALID_PARAMETER


	# -----------------------------------------------------
	# SESIÓN
	# -----------------------------------------------------

	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	# -----------------------------------------------------
	# SKILL EXISTENTE
	# -----------------------------------------------------

	var learning_definition := (
		ServerSkillLearningCatalog.get_definition(
			normalized_skill_id
		)
	)


	if learning_definition == null:
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"unknown_skill"
		)


		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# RUNTIME DE SKILLS VÁLIDO
	# -----------------------------------------------------

	if session.skill_runtime == null:
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"skill_runtime_unavailable"
		)


		return ERR_UNAVAILABLE


	# -----------------------------------------------------
	# YA APRENDIDA
	# -----------------------------------------------------

	if session.skill_runtime.has_learned_skill(
		normalized_skill_id
	):
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"skill_already_learned"
		)


		return ERR_ALREADY_EXISTS


	# -----------------------------------------------------
	# CLASE
	# -----------------------------------------------------

	if not learning_definition.is_class_allowed(
		session.class_id
	):
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"class_requirement_not_met"
		)


		return ERR_UNAUTHORIZED


	# -----------------------------------------------------
	# LEVEL
	# -----------------------------------------------------

	if not learning_definition.meets_level_requirement(
		session.level
	):
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"level_requirement_not_met"
		)


		return ERR_UNAUTHORIZED


	# -----------------------------------------------------
	# TRAINER / SERVICIO NPC
	# -----------------------------------------------------

	if not session.has_active_npc_service():
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"trainer_service_required"
		)


		return ERR_UNAUTHORIZED


	if not learning_definition.is_trainer_service_compatible(
		session.active_service_id
	):
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"incompatible_trainer_service"
		)


		return ERR_UNAUTHORIZED


	# -----------------------------------------------------
	# INVENTORY AUTORITATIVO
	# -----------------------------------------------------

	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"inventory_unavailable"
		)


		return ERR_UNAVAILABLE


	var scroll_item := (
		_find_inventory_item_by_uid(
			inventory_snapshot,
			normalized_scroll_uid
		)
	)


	if scroll_item.is_empty():
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"scroll_not_found"
		)


		return ERR_DOES_NOT_EXIST


	var actual_item_id := String(
		scroll_item.get(
			"item_id",
			""
		)
	).strip_edges().to_lower()


	if (
		actual_item_id
		!=
		learning_definition.scroll_item_id
	):
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"scroll_item_mismatch"
		)


		return ERR_INVALID_DATA


	var quantity := int(
		scroll_item.get(
			"quantity",
			0
		)
	)


	if quantity <= 0:
		_log_rejection(
			session,
			normalized_skill_id,
			normalized_scroll_uid,
			"invalid_scroll_quantity"
		)


		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# PERSISTENCIA DURABLE
	#
	# Recién llegamos aquí después de TODAS las reglas
	# autoritativas del Game Server.
	# -----------------------------------------------------

	var persist_result := (
		backend_repository.persist_learning(
			peer_id,
			session.account_id,
			session.character_id,
			normalized_skill_id,
			normalized_scroll_uid,
			learning_definition.scroll_item_id
		)
	)


	if persist_result != OK:
		print(
			"SkillLearningCoordinator | "
			+
			"No se pudo iniciar persistencia",
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | Skill: ",
			normalized_skill_id,
			" | Scroll UID: ",
			normalized_scroll_uid,
			" | Error: ",
			persist_result
		)


		return persist_result


	print(
		"SkillLearningCoordinator | "
		+
		"Aprendizaje autorizado para persistencia",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Clase: ",
		session.class_id,
		" | Nivel: ",
		session.level,
		" | Skill: ",
		normalized_skill_id,
		" | Scroll: ",
		learning_definition.scroll_item_id,
		" | Scroll UID: ",
		normalized_scroll_uid,
		" | Trainer: ",
		session.active_npc_id,
		" | Service: ",
		session.active_service_id
	)


	return OK


# =========================================================
# BUSCAR ITEM POR UID
# =========================================================

func _find_inventory_item_by_uid(
	inventory_snapshot: Dictionary,
	item_uid: String
) -> Dictionary:
	var items_value: Variant = (
		inventory_snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return {}


	for item_value: Variant in (
		items_value as Array
	):
		if typeof(item_value) != TYPE_DICTIONARY:
			continue


		var item: Dictionary = (
			item_value
		)


		var candidate_uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges().to_lower()


		if candidate_uid == item_uid:
			return item.duplicate(
				true
			)


	return {}


# =========================================================
# LOG DE RECHAZO
# =========================================================

func _log_rejection(
	session: PlayerWorldSession,
	skill_id: String,
	scroll_uid: String,
	reason: String
) -> void:
	if session == null:
		return


	print(
		"SkillLearningCoordinator | "
		+
		"Aprendizaje rechazado",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | Clase: ",
		session.class_id,
		" | Nivel: ",
		session.level,
		" | Skill: ",
		skill_id,
		" | Scroll UID: ",
		scroll_uid,
		" | Motivo: ",
		reason
	)
