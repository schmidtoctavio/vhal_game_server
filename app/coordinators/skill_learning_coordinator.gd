class_name SkillLearningCoordinator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal skill_learning_committed(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	learned_skill_ids: PackedStringArray,
	idempotent: bool
)


signal skill_learning_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	reason: String,
	message: String,
	context: Dictionary
)

# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var backend_repository: BackendCharacterSkillLearningRepository = null

var character_item_state_coordinator: CharacterItemStateCoordinator = null

# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_backend_repository: BackendCharacterSkillLearningRepository,
	p_character_item_state_coordinator: CharacterItemStateCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_backend_repository == null:
		return false


	if p_character_item_state_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	backend_repository = p_backend_repository

	character_item_state_coordinator = (
		p_character_item_state_coordinator
	)


	_bind_repository_signals()


	configured = true


	print(
		"SkillLearningCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND BACKEND
# =========================================================

func _bind_repository_signals() -> void:
	if not backend_repository.skill_learning_persisted.is_connected(
		_on_skill_learning_persisted
	):
		backend_repository.skill_learning_persisted.connect(
			_on_skill_learning_persisted
		)


	if not backend_repository.skill_learning_persist_failed.is_connected(
		_on_skill_learning_persist_failed
	):
		backend_repository.skill_learning_persist_failed.connect(
			_on_skill_learning_persist_failed
		)

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
# APRENDIZAJE PERSISTIDO
# =========================================================

func _on_skill_learning_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	idempotent: bool
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	# -----------------------------------------------------
	# El peer pudo desconectarse mientras Laravel
	# procesaba la operación.
	#
	# El ownership durable igualmente quedó correcto.
	# El próximo login lo reconstruirá desde el ticket.
	# -----------------------------------------------------

	if session == null:
		print(
			"SkillLearningCoordinator | "
			+
			"Aprendizaje durable confirmado sin sesión activa",
			" | Peer: ",
			peer_id,
			" | Character ID: ",
			character_id,
			" | Skill: ",
			skill_id
		)


		return


	# -----------------------------------------------------
	# NO MUTAR OTRA SESIÓN
	# -----------------------------------------------------

	if (
		session.account_id != account_id
		or
		session.character_id != character_id
	):
		push_warning(
			(
				"SkillLearningCoordinator | "
				+
				"Confirmación durable pertenece a otra sesión"
				+
				" | Peer: %d"
				+
				" | Account esperado: %d"
				+
				" | Account actual: %d"
				+
				" | Character esperado: %d"
				+
				" | Character actual: %d"
			)
			%
			[
				peer_id,
				account_id,
				session.account_id,
				character_id,
				session.character_id,
			]
		)


		return


	if session.skill_runtime == null:
		_reject_after_durable_commit(
			session,
			(
				"Skill Runtime no disponible "
				+
				"después del COMMIT durable."
			)
		)


		return


	# -----------------------------------------------------
	# DURABLE PRIMERO → RUNTIME DESPUÉS
	# -----------------------------------------------------

	if not session.skill_runtime.learn_skill(
		skill_id
	):
		_reject_after_durable_commit(
			session,
			(
				"No se pudo aplicar la Skill durable "
				+
				"al runtime."
			)
		)


		return


	# -----------------------------------------------------
	# REFRESCAR INVENTORY
	#
	# Laravel consumió el Scroll dentro del mismo COMMIT.
	# El snapshot actual del GS ahora está stale.
	# -----------------------------------------------------

	var reload_result := (
		character_item_state_coordinator.reload_inventory_snapshot(
			peer_id,
			"skill_learning_committed"
		)
	)


	if reload_result != OK:
		# CharacterItemStateCoordinator ya fuerza
		# desconexión para evitar continuar stale.
		return


	var learned_skill_ids := (
		session.skill_runtime.get_learned_skill_ids()
	)


	print(
		"SkillLearningCoordinator | "
		+
		"Aprendizaje durable aplicado al runtime",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Skill: ",
		skill_id,
		" | Learned: ",
		learned_skill_ids,
		" | Scroll UID: ",
		scroll_uid,
		" | Idempotent: ",
		idempotent
	)


	skill_learning_committed.emit(
		peer_id,
		account_id,
		character_id,
		skill_id,
		scroll_uid,
		scroll_item_id,
		learned_skill_ids,
		idempotent
	)

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

# =========================================================
# APRENDIZAJE NO PERSISTIDO
# =========================================================

func _on_skill_learning_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	response_code: int,
	reason: String,
	message: String,
	context: Dictionary
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if (
		session.account_id != account_id
		or
		session.character_id != character_id
	):
		return


	# -----------------------------------------------------
	# MUY IMPORTANTE:
	#
	# Si Backend rechazó, NO:
	# - learn_skill()
	# - modificamos Inventory
	# - hacemos optimismo local
	# -----------------------------------------------------

	print(
		"SkillLearningCoordinator | "
		+
		"Persistencia de aprendizaje rechazada",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Skill: ",
		skill_id,
		" | Scroll UID: ",
		scroll_uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		reason,
		" | Mensaje: ",
		message
	)


	skill_learning_failed.emit(
		peer_id,
		account_id,
		character_id,
		skill_id,
		scroll_uid,
		scroll_item_id,
		reason,
		message,
		context.duplicate(
			true
		)
	)


# =========================================================
# FALLA DESPUÉS DE COMMIT DURABLE
# =========================================================

func _reject_after_durable_commit(
	session: PlayerWorldSession,
	message: String
) -> void:
	if session == null:
		return


	push_error(
		"SkillLearningCoordinator | "
		+
		"Estado runtime inconsistente después de COMMIT"
		+
		" | Peer: "
		+
		str(
			session.peer_id
		)
		+
		" | Personaje: "
		+
		session.character_name
		+
		" | Motivo: "
		+
		message
	)


	# -----------------------------------------------------
	# Laravel ya es durable.
	#
	# No intentamos hacer rollback desde Game Server.
	# Forzamos reconnect y el ticket reconstruirá la
	# verdad durable.
	# -----------------------------------------------------

	game_server.reject_authenticated_peer(
		session.peer_id,
		(
			"Se requiere resincronizar "
			+
			"el estado durable del personaje."
		)
	)
