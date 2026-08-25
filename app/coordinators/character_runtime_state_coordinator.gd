class_name CharacterRuntimeStateCoordinator
extends Node


# =========================================================
# CONFIGURACIÓN DE AUTOSAVE
# =========================================================

const AUTOSAVE_INTERVAL_MSEC: int = 30000

const AUTOSAVE_JITTER_MSEC: int = 5000

const AUTOSAVE_SCAN_INTERVAL_SECONDS: float = 1.0

const AUTOSAVE_RETRY_DELAY_MSEC: int = 5000


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

var queued_disconnect_checkpoints: Dictionary = {}

var last_confirmed_runtime_states: Dictionary = {}

var autosave_due_msec: Dictionary = {}

var autosave_timer: Timer = null


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

	_create_autosave_timer()


	configured = true


	print(
		"CharacterRuntimeStateCoordinator | Inicializado",
		" | Autosave: ",
		float(AUTOSAVE_INTERVAL_MSEC) / 1000.0,
		" s"
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


	if not world_session_registry.session_created.is_connected(
		_on_session_created
	):
		world_session_registry.session_created.connect(
			_on_session_created
		)


	if not world_session_registry.session_removed.is_connected(
		_on_session_removed
	):
		world_session_registry.session_removed.connect(
			_on_session_removed
		)


# =========================================================
# TIMER
# =========================================================

func _create_autosave_timer() -> void:
	if autosave_timer != null:
		return


	autosave_timer = Timer.new()

	autosave_timer.name = (
		"CharacterRuntimeAutosaveTimer"
	)

	autosave_timer.wait_time = (
		AUTOSAVE_SCAN_INTERVAL_SECONDS
	)

	autosave_timer.one_shot = false


	add_child(
		autosave_timer
	)


	autosave_timer.timeout.connect(
		_on_autosave_timer_timeout
	)


	autosave_timer.start()


# =========================================================
# SESIÓN CREADA
# =========================================================

func _on_session_created(
	peer_id: int,
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


	var runtime_state := (
		session.to_persistent_runtime_state()
	)


	if not runtime_state.is_empty():
		last_confirmed_runtime_states[
			peer_id
		] = runtime_state.duplicate(
			true
		)


	_schedule_next_autosave(
		peer_id
	)


# =========================================================
# SESIÓN REMOVIDA
# =========================================================

func _on_session_removed(
	peer_id: int
) -> void:
	autosave_due_msec.erase(
		peer_id
	)


	_cleanup_peer_tracking_if_inactive(
		peer_id
	)


# =========================================================
# PROGRAMAR AUTOSAVE
# =========================================================

func _schedule_next_autosave(
	peer_id: int
) -> void:
	var jitter := (
		absi(peer_id)
		%
		AUTOSAVE_JITTER_MSEC
	)


	autosave_due_msec[
		peer_id
	] = (
		Time.get_ticks_msec()
		+
		AUTOSAVE_INTERVAL_MSEC
		+
		jitter
	)


func _schedule_autosave_retry(
	peer_id: int
) -> void:
	autosave_due_msec[
		peer_id
	] = (
		Time.get_ticks_msec()
		+
		AUTOSAVE_RETRY_DELAY_MSEC
	)


# =========================================================
# AUTOSAVE SCAN
# =========================================================

func _on_autosave_timer_timeout() -> void:
	if not configured:
		return


	var now_msec := (
		Time.get_ticks_msec()
	)


	for session: PlayerWorldSession in (
		world_session_registry.get_all_sessions()
	):
		if session == null:
			continue


		var peer_id := session.peer_id


		if not autosave_due_msec.has(
			peer_id
		):
			_schedule_next_autosave(
				peer_id
			)

			continue


		var due_msec := int(
			autosave_due_msec[
				peer_id
			]
		)


		if now_msec < due_msec:
			continue


		if pending_checkpoints.has(
			peer_id
		):
			continue


		var current_state := (
			session.to_persistent_runtime_state()
		)


		if current_state.is_empty():
			_schedule_autosave_retry(
				peer_id
			)

			continue


		var previous_value: Variant = (
			last_confirmed_runtime_states.get(
				peer_id,
				null
			)
		)


		if typeof(previous_value) == TYPE_DICTIONARY:
			var previous_state: Dictionary = (
				previous_value
			)


			if _runtime_states_equal(
				previous_state,
				current_state
			):
				_schedule_next_autosave(
					peer_id
				)

				continue


		var result := (
			checkpoint_session(
				session,
				"autosave"
			)
		)


		if result == OK:
			continue


		if result == ERR_BUSY:
			continue


		push_warning(
			(
				"CharacterRuntimeStateCoordinator | "
				+
				"No se pudo iniciar autosave"
				+
				" | Peer: %d"
				+
				" | Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


		_schedule_autosave_retry(
			peer_id
		)


# =========================================================
# CHECKPOINT PÚBLICO
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


	var peer_id := session.peer_id


	# -----------------------------------------------------
	# Si ya hay un autosave en curso y el jugador sale,
	# NO perdemos el estado final.
	#
	# Guardamos una copia del estado de disconnect y la
	# persistiremos cuando finalice el request actual.
	# -----------------------------------------------------

	if pending_checkpoints.has(
		peer_id
	):
		if checkpoint_reason == "disconnect":
			queued_disconnect_checkpoints[
				peer_id
			] = {
				"account_id": session.account_id,
				"character_id": session.character_id,

				"character_name": (
					session.character_name
				),

				"runtime_state": (
					runtime_state.duplicate(
						true
					)
				),
			}


			print(
				(
					"CharacterRuntimeStateCoordinator | "
					+
					"Checkpoint de disconnect encolado"
				),
				" | Peer: ",
				peer_id,
				" | Character ID: ",
				session.character_id,
				" | Posición: ",
				session.position,
				" | HP: ",
				session.vitals.hp,
				" | MP: ",
				session.vitals.mp
			)


			return OK


		return ERR_BUSY


	return _start_checkpoint(
		session.peer_id,
		session.account_id,
		session.character_id,
		session.character_name,
		session.runtime_revision,
		runtime_state,
		checkpoint_reason
	)


# =========================================================
# INICIAR CHECKPOINT
# =========================================================

func _start_checkpoint(
	peer_id: int,
	account_id: int,
	character_id: int,
	character_name: String,
	expected_revision: int,
	runtime_state: Dictionary,
	reason: String,
	stale_retry_count: int = 0
) -> Error:
	if pending_checkpoints.has(
		peer_id
	):
		return ERR_BUSY


	pending_checkpoints[
		peer_id
	] = {
		"account_id": account_id,

		"character_id": character_id,

		"character_name": character_name,

		"expected_revision": expected_revision,

		"reason": reason,

		"runtime_state": (
			runtime_state.duplicate(
				true
			)
		),

		"stale_retry_count": (
			stale_retry_count
		),
	}


	var persist_result := (
		backend_repository.persist_runtime_state(
			peer_id,
			account_id,
			character_id,
			expected_revision,
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
		peer_id,
		" | Character ID: ",
		character_id,
		" | Personaje: ",
		character_name,
		" | Reason: ",
		reason,
		" | Revision esperada: ",
		expected_revision,
		" | Mapa: ",
		String(
			(
				runtime_state.get(
					"world",
					{}
				)
				as Dictionary
			).get(
				"map_id",
				"?"
			)
		),
		" | HP: ",
		int(
			(
				runtime_state.get(
					"vitals",
					{}
				)
				as Dictionary
			).get(
				"hp",
				-1
			)
		),
		" | MP: ",
		int(
			(
				runtime_state.get(
					"vitals",
					{}
				)
				as Dictionary
			).get(
				"mp",
				-1
			)
		)
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
	runtime_state: Dictionary,
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


	var confirmed_state := (
		_extract_persistent_runtime_state(
			runtime_state
		)
	)


	if not confirmed_state.is_empty():
		last_confirmed_runtime_states[
			peer_id
		] = confirmed_state


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


	# -----------------------------------------------------
	# Si el jugador salió mientras el autosave estaba
	# pendiente, persistimos AHORA la copia final.
	# -----------------------------------------------------

	if queued_disconnect_checkpoints.has(
		peer_id
	):
		_start_queued_disconnect_checkpoint(
			peer_id,
			revision
		)

		return


	if session != null:
		_schedule_next_autosave(
			peer_id
		)


	_cleanup_peer_tracking_if_inactive(
		peer_id
	)


# =========================================================
# ERROR
# =========================================================

func _on_runtime_state_persist_failed(
	peer_id: int,
	account_id: int,
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


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	# -----------------------------------------------------
	# STALE RECOVERY PARA SESIÓN ACTIVA
	# -----------------------------------------------------

	if (
		session != null
		and
		current_revision > 0
		and
		session.account_id == account_id
		and
		session.character_id == character_id
	):
		session.runtime_revision = (
			current_revision
		)


		var backend_state := (
			_extract_persistent_runtime_state(
				current_runtime
			)
		)


		if not backend_state.is_empty():
			last_confirmed_runtime_states[
				peer_id
			] = backend_state


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


	# -----------------------------------------------------
	# DISCONNECT ENCOLADO
	# -----------------------------------------------------

	if queued_disconnect_checkpoints.has(
		peer_id
	):
		var next_revision := (
			current_revision
			if
			current_revision > 0
			else
			expected_revision
		)


		_start_queued_disconnect_checkpoint(
			peer_id,
			next_revision
		)

		return


	# -----------------------------------------------------
	# Si el checkpoint que falló ERA el disconnect y
	# Laravel informó una revisión actual distinta,
	# hacemos un único retry contra esa revisión.
	# -----------------------------------------------------

	var reason := String(
		checkpoint.get(
			"reason",
			"unknown"
		)
	)


	var stale_retry_count := int(
		checkpoint.get(
			"stale_retry_count",
			0
		)
	)


	if (
		reason == "disconnect"
		and
		current_revision > 0
		and
		stale_retry_count < 1
	):
		var runtime_value: Variant = (
			checkpoint.get(
				"runtime_state",
				null
			)
		)


		if typeof(runtime_value) == TYPE_DICTIONARY:
			var retry_result := (
				_start_checkpoint(
					peer_id,
					account_id,
					character_id,

					String(
						checkpoint.get(
							"character_name",
							""
						)
					),

					current_revision,

					(
						runtime_value
						as Dictionary
					),

					"disconnect",

					stale_retry_count + 1
				)
			)


			if retry_result == OK:
				return


	if session != null:
		_schedule_autosave_retry(
			peer_id
		)


	_cleanup_peer_tracking_if_inactive(
		peer_id
	)


# =========================================================
# DISCONNECT ENCOLADO
# =========================================================

func _start_queued_disconnect_checkpoint(
	peer_id: int,
	expected_revision: int
) -> void:
	var queued_value: Variant = (
		queued_disconnect_checkpoints.get(
			peer_id,
			null
		)
	)


	if typeof(queued_value) != TYPE_DICTIONARY:
		queued_disconnect_checkpoints.erase(
			peer_id
		)

		return


	var queued: Dictionary = (
		queued_value
	)


	queued_disconnect_checkpoints.erase(
		peer_id
	)


	var runtime_value: Variant = (
		queued.get(
			"runtime_state",
			null
		)
	)


	if typeof(runtime_value) != TYPE_DICTIONARY:
		_cleanup_peer_tracking_if_inactive(
			peer_id
		)

		return


	var result := (
		_start_checkpoint(
			peer_id,

			int(
				queued.get(
					"account_id",
					0
				)
			),

			int(
				queued.get(
					"character_id",
					0
				)
			),

			String(
				queued.get(
					"character_name",
					""
				)
			),

			expected_revision,

			(
				runtime_value
				as Dictionary
			),

			"disconnect"
		)
	)


	if result != OK:
		push_warning(
			(
				"CharacterRuntimeStateCoordinator | "
				+
				"No se pudo iniciar checkpoint "
				+
				"de disconnect encolado"
				+
				" | Peer: %d"
				+
				" | Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


		_cleanup_peer_tracking_if_inactive(
			peer_id
		)


# =========================================================
# EXTRAER ESTADO
# =========================================================

func _extract_persistent_runtime_state(
	runtime_state: Dictionary
) -> Dictionary:
	var world_value: Variant = (
		runtime_state.get(
			"world",
			null
		)
	)


	var vitals_value: Variant = (
		runtime_state.get(
			"vitals",
			null
		)
	)


	if (
		typeof(world_value) != TYPE_DICTIONARY
		or
		typeof(vitals_value) != TYPE_DICTIONARY
	):
		return {}


	return {
		"world": (
			(
				world_value
				as Dictionary
			).duplicate(
				true
			)
		),

		"vitals": (
			(
				vitals_value
				as Dictionary
			).duplicate(
				true
			)
		),
	}


# =========================================================
# COMPARAR ESTADO
# =========================================================

func _runtime_states_equal(
	left: Dictionary,
	right: Dictionary
) -> bool:
	var left_world_value: Variant = (
		left.get(
			"world",
			null
		)
	)

	var right_world_value: Variant = (
		right.get(
			"world",
			null
		)
	)


	var left_vitals_value: Variant = (
		left.get(
			"vitals",
			null
		)
	)

	var right_vitals_value: Variant = (
		right.get(
			"vitals",
			null
		)
	)


	if (
		typeof(left_world_value) != TYPE_DICTIONARY
		or
		typeof(right_world_value) != TYPE_DICTIONARY
		or
		typeof(left_vitals_value) != TYPE_DICTIONARY
		or
		typeof(right_vitals_value) != TYPE_DICTIONARY
	):
		return false


	var left_world: Dictionary = (
		left_world_value
	)

	var right_world: Dictionary = (
		right_world_value
	)


	var left_vitals: Dictionary = (
		left_vitals_value
	)

	var right_vitals: Dictionary = (
		right_vitals_value
	)


	if String(
		left_world.get(
			"map_id",
			""
		)
	) != String(
		right_world.get(
			"map_id",
			""
		)
	):
		return false


	var left_position_value: Variant = (
		left_world.get(
			"position",
			null
		)
	)

	var right_position_value: Variant = (
		right_world.get(
			"position",
			null
		)
	)


	if (
		typeof(left_position_value) != TYPE_DICTIONARY
		or
		typeof(right_position_value) != TYPE_DICTIONARY
	):
		return false


	var left_position: Dictionary = (
		left_position_value
	)

	var right_position: Dictionary = (
		right_position_value
	)


	if not is_equal_approx(
		float(
			left_position.get(
				"x",
				0.0
			)
		),
		float(
			right_position.get(
				"x",
				0.0
			)
		)
	):
		return false


	if not is_equal_approx(
		float(
			left_position.get(
				"y",
				0.0
			)
		),
		float(
			right_position.get(
				"y",
				0.0
			)
		)
	):
		return false


	if not is_equal_approx(
		float(
			left_position.get(
				"z",
				0.0
			)
		),
		float(
			right_position.get(
				"z",
				0.0
			)
		)
	):
		return false


	if not is_equal_approx(
		float(
			left_world.get(
				"rotation_y",
				0.0
			)
		),
		float(
			right_world.get(
				"rotation_y",
				0.0
			)
		)
	):
		return false


	if int(
		left_vitals.get(
			"hp",
			-1
		)
	) != int(
		right_vitals.get(
			"hp",
			-1
		)
	):
		return false


	if int(
		left_vitals.get(
			"mp",
			-1
		)
	) != int(
		right_vitals.get(
			"mp",
			-1
		)
	):
		return false


	return true


# =========================================================
# CLEANUP
# =========================================================

func _cleanup_peer_tracking_if_inactive(
	peer_id: int
) -> void:
	if world_session_registry.has_session(
		peer_id
	):
		return


	if pending_checkpoints.has(
		peer_id
	):
		return


	if queued_disconnect_checkpoints.has(
		peer_id
	):
		return


	last_confirmed_runtime_states.erase(
		peer_id
	)

	autosave_due_msec.erase(
		peer_id
	)
