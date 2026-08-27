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

var npc_service_coordinator: NpcServiceCoordinator = null

# =========================================================
# ESTADO
# =========================================================

var configured: bool = false

var pending_request_by_peer: Dictionary = {}

# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_npc_service_coordinator: NpcServiceCoordinator,
	p_backend_repository: BackendCharacterSkillLearningRepository,
	p_character_item_state_coordinator: CharacterItemStateCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false

	if p_npc_service_coordinator == null:
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

	npc_service_coordinator = (
		p_npc_service_coordinator
	)

	_bind_npc_service_signals()

	_bind_game_server_signals()

	_bind_repository_signals()


	configured = true


	print(
		"SkillLearningCoordinator | Inicializado."
	)


	return true

# =========================================================
# BIND NPC SERVICE
# =========================================================

func _bind_npc_service_signals() -> void:
	if not npc_service_coordinator.npc_service_authorized.is_connected(
		_on_npc_service_authorized
	):
		npc_service_coordinator.npc_service_authorized.connect(
			_on_npc_service_authorized
		)

# =========================================================
# BIND GAME SERVER
# =========================================================

func _bind_game_server_signals() -> void:
	if not game_server.client_skill_learning_requested.is_connected(
		_on_client_skill_learning_requested
	):
		game_server.client_skill_learning_requested.connect(
			_on_client_skill_learning_requested
		)

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
# INTENCIÓN DE APRENDIZAJE DEL CLIENTE
# =========================================================

func _on_client_skill_learning_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	scroll_uid: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No existe una sesión de mundo "
				+
				"para aprender la Skill."
			)
		)


		return


	if not session.accept_skill_learning_request_id(
		request_id
	):
		_send_learning_result(
			peer_id,
			request_id,
			skill_id,
			scroll_uid,
			false,
			"stale_request",
			session,
			false
		)


		return


	request_learning(
		peer_id,
		request_id,
		skill_id,
		scroll_uid
	)

# =========================================================
# REQUEST DE APRENDIZAJE
# =========================================================

func request_learning(
	peer_id: int,
	request_id: int,
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
		request_id <= 0
		or
		normalized_skill_id.is_empty()
		or
		normalized_scroll_uid.is_empty()
	):
		return ERR_INVALID_PARAMETER


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var learning_definition := (
		ServerSkillLearningCatalog.get_definition(
			normalized_skill_id
		)
	)


	if learning_definition == null:
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"unknown_skill",
			ERR_INVALID_DATA
		)


	if session.skill_runtime == null:
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"skill_runtime_unavailable",
			ERR_UNAVAILABLE
		)


	if session.skill_runtime.has_learned_skill(
		normalized_skill_id
	):
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"skill_already_learned",
			ERR_ALREADY_EXISTS
		)


	if not learning_definition.is_class_allowed(
		session.class_id
	):
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"class_requirement_not_met",
			ERR_UNAUTHORIZED
		)


	if not learning_definition.meets_level_requirement(
		session.level
	):
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"level_requirement_not_met",
			ERR_UNAUTHORIZED
		)


	if not session.has_active_npc_service():
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"trainer_service_required",
			ERR_UNAUTHORIZED
		)


	if not learning_definition.is_trainer_service_compatible(
		session.active_service_id
	):
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"incompatible_trainer_service",
			ERR_UNAUTHORIZED
		)


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"inventory_unavailable",
			ERR_UNAVAILABLE
		)


	var scroll_item := (
		_find_inventory_item_by_uid(
			inventory_snapshot,
			normalized_scroll_uid
		)
	)


	if scroll_item.is_empty():
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"scroll_not_found",
			ERR_DOES_NOT_EXIST
		)


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
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"scroll_item_mismatch",
			ERR_INVALID_DATA
		)


	var quantity := int(
		scroll_item.get(
			"quantity",
			0
		)
	)


	if quantity <= 0:
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"invalid_scroll_quantity",
			ERR_INVALID_DATA
		)


	if pending_request_by_peer.has(
		peer_id
	):
		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			"learning_busy",
			ERR_BUSY
		)


	pending_request_by_peer[
		peer_id
	] = {
		"request_id": request_id,

		"skill_id": normalized_skill_id,

		"scroll_uid": normalized_scroll_uid,

		"scroll_item_id": (
			learning_definition.scroll_item_id
		),
	}


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
		pending_request_by_peer.erase(
			peer_id
		)


		var failure_reason := (
			"persist_request_failed"
		)


		if persist_result == ERR_BUSY:
			failure_reason = "learning_busy"

		elif persist_result == ERR_UNAVAILABLE:
			failure_reason = "backend_unavailable"


		return _reject_learning_request(
			session,
			request_id,
			normalized_skill_id,
			normalized_scroll_uid,
			failure_reason,
			persist_result
		)


	print(
		"SkillLearningCoordinator | "
		+
		"Aprendizaje autorizado para persistencia",
		" | Request: ",
		request_id,
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

	var pending_request := (
		_take_pending_request(
			peer_id
		)
	)


	var request_id := int(
		pending_request.get(
			"request_id",
			0
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

	if request_id > 0:
		_send_learning_result(
			peer_id,
			request_id,
			skill_id,
			scroll_uid,
			true,
			"ok",
			session,
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
# RECHAZAR REQUEST DE APRENDIZAJE
# =========================================================

func _reject_learning_request(
	session: PlayerWorldSession,
	request_id: int,
	skill_id: String,
	scroll_uid: String,
	reason: String,
	error: Error
) -> Error:
	_log_rejection(
		session,
		skill_id,
		scroll_uid,
		reason
	)


	_send_learning_result(
		session.peer_id,
		request_id,
		skill_id,
		scroll_uid,
		false,
		reason,
		session,
		false
	)


	return error

# =========================================================
# ENVIAR RESULTADO DE APRENDIZAJE
# =========================================================

func _send_learning_result(
	peer_id: int,
	request_id: int,
	skill_id: String,
	scroll_uid: String,
	accepted: bool,
	reason: String,
	session: PlayerWorldSession,
	idempotent: bool
) -> void:
	if session == null:
		return


	var learned_skill_ids := PackedStringArray()


	if session.skill_runtime != null:
		learned_skill_ids = (
			session.skill_runtime.get_learned_skill_ids()
		)


	var result := (
		game_server.send_skill_learning_result(
			peer_id,
			request_id,
			skill_id,
			scroll_uid,
			accepted,
			reason,
			learned_skill_ids,
			idempotent
		)
	)


	if result != OK:
		push_warning(
			(
				"SkillLearningCoordinator | "
				+
				"No se pudo enviar resultado de aprendizaje "
				+
				"al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


		return


	print(
		"SkillLearningCoordinator | Resultado enviado",
		" | Request: ",
		request_id,
		" | Skill: ",
		skill_id,
		" | Accepted: ",
		accepted,
		" | Reason: ",
		reason,
		" | Learned: ",
		learned_skill_ids,
		" | Idempotent: ",
		idempotent
	)

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

	var pending_request := (
		_take_pending_request(
			peer_id
		)
	)


	var request_id := int(
		pending_request.get(
			"request_id",
			0
		)
	)


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

	if request_id > 0:
		_send_learning_result(
			peer_id,
			request_id,
			skill_id,
			scroll_uid,
			false,
			reason,
			session,
			false
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


# =========================================================
# TOMAR REQUEST PENDIENTE
# =========================================================

func _take_pending_request(
	peer_id: int
) -> Dictionary:
	if not pending_request_by_peer.has(
		peer_id
	):
		return {}


	var value: Variant = (
		pending_request_by_peer[
			peer_id
		]
	)


	pending_request_by_peer.erase(
		peer_id
	)


	if typeof(value) != TYPE_DICTIONARY:
		return {}


	return (
		value as Dictionary
	).duplicate(
		true
	)


# =========================================================
# SNAPSHOT DE OFERTAS DEL SKILL TRAINER
# =========================================================

func build_active_trainer_offers_snapshot(
	peer_id: int
) -> Dictionary:
	if not configured:
		return {}


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return {}


	if not session.has_active_npc_service():
		return {}


	if (
		session.active_service_id
		!=
		ServerSkillLearningCatalog.SKILL_TRAINER_SERVICE_ID
	):
		return {}


	if session.skill_runtime == null:
		return {}


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		return {}


	var offers := (
		ServerSkillTrainerOfferBuilder.build_offers(
			session.class_id,
			session.level,
			session.skill_runtime.get_learned_skill_ids(),
			inventory_snapshot,
			session.active_service_id
		)
	)


	return {
		"character_id": session.character_id,

		"npc_id": session.active_npc_id,

		"service_id": session.active_service_id,

		"class_id": session.class_id,

		"level": session.level,

		"offers": offers,
	}


# =========================================================
# SKILL TRAINER AUTORIZADO
# =========================================================

func _on_npc_service_authorized(
	peer_id: int,
	npc_id: String,
	service_id: String
) -> void:
	var normalized_service_id := (
		service_id
		.strip_edges()
		.to_lower()
	)


	if (
		normalized_service_id
		!=
		ServerSkillLearningCatalog.SKILL_TRAINER_SERVICE_ID
	):
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if not session.is_using_npc_service(
		npc_id,
		normalized_service_id
	):
		return


	var snapshot := (
		build_active_trainer_offers_snapshot(
			peer_id
		)
	)


	if snapshot.is_empty():
		push_warning(
			(
				"SkillLearningCoordinator | "
				+
				"No se pudieron construir las ofertas "
				+
				"del Skill Trainer."
			)
		)


		return


	var offers_value: Variant = (
		snapshot.get(
			"offers",
			null
		)
	)


	if typeof(offers_value) != TYPE_ARRAY:
		return


	var offers: Array = (
		offers_value as Array
	)

	var send_result := (
		game_server.send_skill_trainer_offers(
			peer_id,
			snapshot
		)
	)


	if send_result != OK:
		push_warning(
			(
				"SkillLearningCoordinator | "
				+
				"No se pudieron enviar las ofertas "
				+
				"del Skill Trainer al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				send_result,
			]
		)


		return


	print(
		"SkillLearningCoordinator | "
		+
		"Ofertas autoritativas del Skill Trainer enviadas",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Character ID: ",
		session.character_id,
		" | NPC: ",
		session.active_npc_id,
		" | Ofertas: ",
		offers.size()
	)

	print(
		"SkillLearningCoordinator | "
		+
		"Ofertas autoritativas del Skill Trainer preparadas",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Clase: ",
		session.class_id,
		" | Nivel: ",
		session.level,
		" | NPC: ",
		session.active_npc_id,
		" | Ofertas: ",
		offers.size()
	)


	for offer_value: Variant in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue


		var offer: Dictionary = (
			offer_value as Dictionary
		)


		print(
			"SkillLearningCoordinator | Trainer Offer",
			" | Skill: ",
			offer.get("skill_id", ""),
			" | Scroll: ",
			offer.get("scroll_item_id", ""),
			" | Scroll UID: ",
			offer.get("scroll_uid", ""),
			" | Nivel mínimo: ",
			offer.get("minimum_level", 0),
			" | Learned: ",
			offer.get("already_learned", false),
			" | Has Scroll: ",
			offer.get("has_scroll", false),
			" | Can Learn: ",
			offer.get("can_learn", false),
			" | Reason: ",
			offer.get("reason", "")
		)
