class_name CharacterRuntimeStateCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var world_session_registry: WorldSessionRegistry = null

var backend_repository: BackendCharacterRuntimeStateRepository = null


# =========================================================
# ESTADO
# =========================================================

var configured: bool = false

var pending_checkpoints: Dictionary = {}


# =========================================================
# SETUP
# =========================================================

func setup(
	p_world_session_registry: WorldSessionRegistry,
	p_backend_repository: BackendCharacterRuntimeStateRepository
) -> bool:
	if configured:
		return true


	if p_world_session_registry == null:
		return false


	if p_backend_repository == null:
		return false


	if not p_backend_repository.is_configured():
		return false


	world_session_registry = (
		p_world_session_registry
	)

	backend_repository = (
		p_backend_repository
	)


	_bind_signals()


	configured = true


	print(
		"CharacterRuntimeStateCoordinator | Inicializado."
	)


	return true


# =========================================================
# SIGNALS
# =========================================================

func _bind_signals() -> void:
	if not backend_repository.runtime_state_persisted.is_connected(
		_on_runtime_state_persisted
	):
		backend_repository.runtime_state_persisted.connect(
			_on_runtime_state_persisted
		)


	if not backend_repository.runtime_state_persist_failed.is_connected(
		_on_runtime_state_persist_failed
	):
		backend_repository.runtime_state_persist_failed.connect(
			_on_runtime_state_persist_failed
		)


# =========================================================
# CHECKPOINT
# =========================================================

func checkpoint_session(
	session: PlayerWorldSession,
	reason: String
) -> Error:
	if not configured:
		return ERR_UNCONFIGURED


	if session == null:
		return ERR_INVALID_PARAMETER


	if not session.is_valid():
		return ERR_INVALID_DATA


	var peer_id := session.peer_id


	if pending_checkpoints.has(
		peer_id
	):
		return ERR_BUSY


	var runtime_state := (
		session.to_persistent_runtime_state()
	)


	if runtime_state.is_empty():
		return ERR_INVALID_DATA


	var checkpoint_reason := (
		reason.strip_edges()
	)


	if checkpoint_reason.is_empty():
		checkpoint_reason = "unknown"


	pending_checkpoints[
		peer_id
	] = {
		"character_id": session.character_id,
		"character_name": session.character_name,
		"expected_revision": session.runtime_revision,
		"reason": checkpoint_reason,
	}


	var persist_result := (
		backend_repository.persist_runtime_state(
			session.peer_id,
			session.account_id,
			session.character_id,
			session.runtime_revision,
			runtime_state
		)
	)


	if persist_result != OK:
		pending_checkpoints.erase(
			peer_id
		)

		return persist_result


	print(
		"CharacterRuntimeStateCoordinator | Checkpoint iniciado",
		" | Peer: ",
		session.peer_id,
		" | Character ID: ",
		session.character_id,
		" | Personaje: ",
		session.character_name,
		" | Reason: ",
		checkpoint_reason,
		" | Revision esperada: ",
		session.runtime_revision,
		" | Mapa: ",
		session.map_id,
		" | Posición: ",
		session.position,
		" | HP: ",
		session.vitals.hp,
		" | MP: ",
		session.vitals.mp
	)


	return OK


# =========================================================
# CONFIRMADO
# =========================================================

func _on_runtime_state_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	revision: int,
	_runtime_state: Dictionary,
	idempotent: bool
) -> void:
	var checkpoint: Dictionary = (
		pending_checkpoints.get(
			peer_id,
			{}
		)
	)


	pending_checkpoints.erase(
		peer_id
	)


	# -----------------------------------------------------
	# Si la sesión todavía existe, actualizamos revision.
	#
	# En disconnect normalmente ya habrá sido removida.
	# Esto queda preparado para autosaves futuros.
	# -----------------------------------------------------

	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if (
		session != null
		and
		session.account_id == account_id
		and
		session.character_id == character_id
	):
		session.runtime_revision = revision


	print(
		"CharacterRuntimeStateCoordinator | Checkpoint confirmado",
		" | Peer: ",
		peer_id,
		" | Character ID: ",
		character_id,
		" | Reason: ",
		String(
			checkpoint.get(
				"reason",
				"unknown"
			)
		),
		" | Revision: ",
		expected_revision,
		" -> ",
		revision,
		" | Idempotent: ",
		idempotent
	)


# =========================================================
# ERROR
# =========================================================

func _on_runtime_state_persist_failed(
	peer_id: int,
	_account_id: int,
	character_id: int,
	expected_revision: int,
	response_code: int,
	message: String,
	current_runtime: Dictionary
) -> void:
	var checkpoint: Dictionary = (
		pending_checkpoints.get(
			peer_id,
			{}
		)
	)


	pending_checkpoints.erase(
		peer_id
	)


	var current_revision := int(
		current_runtime.get(
			"revision",
			0
		)
	)


	push_warning(
		(
			"CharacterRuntimeStateCoordinator | "
			+
			"Falló checkpoint runtime"
			+
			" | Peer: %d"
			+
			" | Character ID: %d"
			+
			" | Reason: %s"
			+
			" | Expected revision: %d"
			+
			" | Current revision: %d"
			+
			" | HTTP: %d"
			+
			" | %s"
		)
		%
		[
			peer_id,
			character_id,
			String(
				checkpoint.get(
					"reason",
					"unknown"
				)
			),
			expected_revision,
			current_revision,
			response_code,
			message,
		]
	)
