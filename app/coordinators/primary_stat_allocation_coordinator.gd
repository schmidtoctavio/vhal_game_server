class_name PrimaryStatAllocationCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var stats_repository: BackendCharacterStatsRepository = null


# =========================================================
# ESTADO
# =========================================================

var pending_by_peer: Dictionary = {}

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_stats_repository: BackendCharacterStatsRepository
) -> bool:
	if configured:
		return true


	if (
		p_game_server == null
		or
		p_world_session_registry == null
		or
		p_stats_repository == null
	):
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	stats_repository = p_stats_repository


	if not game_server.client_primary_stat_allocation_requested.is_connected(
		_on_primary_stat_allocation_requested
	):
		game_server.client_primary_stat_allocation_requested.connect(
			_on_primary_stat_allocation_requested
		)


	if not game_server.client_disconnected.is_connected(
		_on_client_disconnected
	):
		game_server.client_disconnected.connect(
			_on_client_disconnected
		)


	if not stats_repository.primary_stats_persisted.is_connected(
		_on_primary_stats_persisted
	):
		stats_repository.primary_stats_persisted.connect(
			_on_primary_stats_persisted
		)


	if not stats_repository.primary_stats_persist_failed.is_connected(
		_on_primary_stats_persist_failed
	):
		stats_repository.primary_stats_persist_failed.connect(
			_on_primary_stats_persist_failed
		)


	configured = true


	print(
		"PrimaryStatAllocationCoordinator | Inicializado."
	)


	return true


# =========================================================
# REQUEST
# =========================================================

func _on_primary_stat_allocation_requested(
	peer_id: int,
	request_id: int,
	stat_id: String,
	points: int
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if (
		session.primary_stats == null
		or
		not session.primary_stats.is_valid()
	):
		game_server.reject_authenticated_peer(
			peer_id,
			"El runtime de Primary Stats es inválido."
		)


		return


	if not session.accept_primary_stat_allocation_request_id(
		request_id
	):
		_send_result(
			session,
			request_id,
			stat_id,
			maxi(
				points,
				1
			),
			false,
			"stale_request"
		)


		return


	var normalized_stat_id := (
		stat_id
		.strip_edges()
		.to_lower()
	)


	if not _is_valid_stat_id(
		normalized_stat_id
	):
		_send_result(
			session,
			request_id,
			normalized_stat_id,
			maxi(
				points,
				1
			),
			false,
			"invalid_stat"
		)


		return


	if points <= 0:
		_send_result(
			session,
			request_id,
			normalized_stat_id,
			1,
			false,
			"invalid_points"
		)


		return


	# -----------------------------------------------------
	# Sólo permitimos una allocation durable en vuelo
	# por Character/Peer.
	# -----------------------------------------------------

	if pending_by_peer.has(
		peer_id
	):
		_send_result(
			session,
			request_id,
			normalized_stat_id,
			points,
			false,
			"allocation_busy"
		)


		return


	if (
		points
		>
		session.primary_stats.unspent_points
	):
		_send_result(
			session,
			request_id,
			normalized_stat_id,
			points,
			false,
			"insufficient_points"
		)


		return


	var expected_revision := (
		session.primary_stats.revision
	)


	var next_allocated := (
		_build_next_allocated(
			session.primary_stats,
			normalized_stat_id,
			points
		)
	)


	if next_allocated.is_empty():
		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo construir la próxima allocation de Stats."
		)


		return


	pending_by_peer[
		peer_id
	] = {
		"request_id": request_id,

		"stat_id": normalized_stat_id,

		"points": points,

		"account_id": session.account_id,

		"character_id": session.character_id,

		"expected_revision": (
			expected_revision
		),

		"next_allocated": (
			next_allocated.duplicate(
				true
			)
		),
	}


	var persist_result := (
		stats_repository.persist_allocation(
			peer_id,
			session.account_id,
			session.character_id,
			expected_revision,
			next_allocated
		)
	)


	if persist_result == OK:
		print(
			"PrimaryStatAllocationCoordinator | "
			+
			"Persistencia iniciada",
			" | Peer: ",
			peer_id,
			" | Request: ",
			request_id,
			" | Stat: ",
			normalized_stat_id,
			" | Points: ",
			points,
			" | Expected revision: ",
			expected_revision
		)


		return


	pending_by_peer.erase(
		peer_id
	)


	var failure_reason := (
		"allocation_busy"
		if persist_result == ERR_BUSY
		else
		"persistence_unavailable"
	)


	_send_result(
		session,
		request_id,
		normalized_stat_id,
		points,
		false,
		failure_reason
	)


# =========================================================
# PERSISTENCIA CONFIRMADA
# =========================================================

func _on_primary_stats_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary,
	stats_snapshot: Dictionary,
	idempotent: bool
) -> void:
	if not pending_by_peer.has(
		peer_id
	):
		return


	var pending_value: Variant = (
		pending_by_peer[
			peer_id
		]
	)


	if typeof(pending_value) != TYPE_DICTIONARY:
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"El estado pendiente de Primary Stats es inválido."
		)


		return


	var pending: Dictionary = (
		pending_value
	)


	if not _pending_matches_persistence(
		pending,
		account_id,
		character_id,
		expected_revision,
		next_allocated
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"La confirmación de Primary Stats no coincide con la solicitud pendiente."
		)


		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		pending_by_peer.erase(
			peer_id
		)


		return


	if (
		session.account_id != account_id
		or
		session.character_id != character_id
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"La identidad de Primary Stats cambió durante la persistencia."
		)


		return


	if (
		session.primary_stats == null
		or
		session.primary_stats.revision
		!=
		expected_revision
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"El runtime local de Primary Stats cambió durante la persistencia."
		)


		return


	var next_state := (
		ServerCharacterPrimaryStatsBootstrap
		.create_from_snapshot(
			session.class_id,
			session.level,
			session.reset_count,
			stats_snapshot
		)
	)


	if next_state == null:
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"Laravel confirmó un snapshot de Primary Stats inválido."
		)


		return


	var next_derived_stats := (
		ServerCharacterDerivedStatsBootstrap
		.create_from_primary_stats(
			next_state
		)
	)


	if next_derived_stats == null:
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudieron reconstruir "
				+
				"Derived Stats después de allocation."
			)
		)


		return

	if (
		session.vitals == null
		or
		not session.vitals.is_valid()
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudieron actualizar Vitals "
				+
				"después de allocation."
			)
		)


		return


	if not session.vitals.reconfigure_maximums(
		next_derived_stats.max_hp,
		next_derived_stats.max_mp
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudieron reconfigurar "
				+
				"los máximos de Vitals."
			)
		)


		return

	session.primary_stats = next_state

	session.derived_stats = (
		next_derived_stats
	)

	print(
		(
			"PrimaryStatAllocationCoordinator | "
			+
			"Vitals reconfigurados post allocation"
		),
		" | Character ID: ",
		character_id,
		" | HP: ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp,
		" | MP: ",
		session.vitals.mp,
		"/",
		session.vitals.max_mp
	)

	var request_id := int(
		pending.get(
			"request_id",
			0
		)
	)

	var stat_id := String(
		pending.get(
			"stat_id",
			""
		)
	)

	var points := int(
		pending.get(
			"points",
			0
		)
	)


	pending_by_peer.erase(
		peer_id
	)

	print(
		(
			"PrimaryStatAllocationCoordinator | "
			+
			"Derived Stats reconstruidos post allocation"
		),
		" | Character ID: ",
		character_id,
		" | Source revision: ",
		session.derived_stats.source_primary_stats_revision,
		" | Level: ",
		session.derived_stats.level,
		" | Max HP/MP: ",
		session.derived_stats.max_hp,
		"/",
		session.derived_stats.max_mp,
		" | Power P/M/H: ",
		session.derived_stats.physical_power,
		"/",
		session.derived_stats.magic_power,
		"/",
		session.derived_stats.healing_power
	)

	print(
		"PrimaryStatAllocationCoordinator | "
		+
		"Allocation durable confirmada",
		" | Peer: ",
		peer_id,
		" | Request: ",
		request_id,
		" | Stat: ",
		stat_id,
		" | Points: ",
		points,
		" | Revision: ",
		session.primary_stats.revision,
		" | Spent: ",
		session.primary_stats.spent_points,
		"/",
		session.primary_stats.total_points,
		" | Unspent: ",
		session.primary_stats.unspent_points,
		" | Idempotent: ",
		idempotent
	)


	_send_result(
		session,
		request_id,
		stat_id,
		points,
		true,
		"ok"
	)

	_send_vitals_update(
		session,
		character_id,
		"allocation"
	)

# =========================================================
# PERSISTENCIA RECHAZADA
# =========================================================

func _on_primary_stats_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary,
	response_code: int,
	reason: String,
	message: String,
	context: Dictionary
) -> void:
	if not pending_by_peer.has(
		peer_id
	):
		return


	var pending_value: Variant = (
		pending_by_peer[
			peer_id
		]
	)


	if typeof(pending_value) != TYPE_DICTIONARY:
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"El estado pendiente de Primary Stats es inválido."
		)


		return


	var pending: Dictionary = (
		pending_value
	)


	if not _pending_matches_persistence(
		pending,
		account_id,
		character_id,
		expected_revision,
		next_allocated
	):
		pending_by_peer.erase(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"El rechazo de Primary Stats no coincide con la solicitud pendiente."
		)


		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	var request_id := int(
		pending.get(
			"request_id",
			0
		)
	)

	var stat_id := String(
		pending.get(
			"stat_id",
			""
		)
	)

	var points := int(
		pending.get(
			"points",
			0
		)
	)


	pending_by_peer.erase(
		peer_id
	)


	if session == null:
		return


	var normalized_reason := (
		reason
		.strip_edges()
		.to_lower()
	)


	if normalized_reason.is_empty():
		normalized_reason = (
			"persistence_rejected"
		)


	print(
		"PrimaryStatAllocationCoordinator | "
		+
		"Persistencia rechazada",
		" | Peer: ",
		peer_id,
		" | Request: ",
		request_id,
		" | HTTP: ",
		response_code,
		" | Reason: ",
		normalized_reason,
		" | Message: ",
		message
	)


	# -----------------------------------------------------
	# STALE REVISION:
	#
	# Laravel posee un estado más nuevo.
	# Si entrega current, resincronizamos el runtime.
	# -----------------------------------------------------

	if normalized_reason == "stale_revision":
		var current_value: Variant = (
			context.get(
				"current",
				null
			)
		)


		if typeof(current_value) != TYPE_DICTIONARY:
			game_server.reject_authenticated_peer(
				peer_id,
				"Backend informó stale_revision sin snapshot actual."
			)


			return


		var current_state := (
			ServerCharacterPrimaryStatsBootstrap
			.create_from_snapshot(
				session.class_id,
				session.level,
				session.reset_count,
				current_value
			)
		)


		if current_state == null:
			game_server.reject_authenticated_peer(
				peer_id,
				"No se pudo resincronizar Primary Stats después de stale_revision."
			)


			return

		var current_derived_stats := (
			ServerCharacterDerivedStatsBootstrap
			.create_from_primary_stats(
				current_state
			)
		)


		if current_derived_stats == null:
			game_server.reject_authenticated_peer(
				peer_id,
				(
					"No se pudieron resincronizar "
					+
					"Derived Stats después de stale_revision."
				)
			)


			return

		if (
			session.vitals == null
			or
			not session.vitals.is_valid()
		):
			game_server.reject_authenticated_peer(
				peer_id,
				(
					"No se pudieron resincronizar "
					+
					"Vitals después de stale_revision."
				)
			)


			return


		if not session.vitals.reconfigure_maximums(
			current_derived_stats.max_hp,
			current_derived_stats.max_mp
		):
			game_server.reject_authenticated_peer(
				peer_id,
				(
					"No se pudieron reconfigurar "
					+
					"Vitals después de stale_revision."
				)
			)


			return

		session.primary_stats = (
			current_state
		)

		session.derived_stats = (
			current_derived_stats
		)


		_send_result(
			session,
			request_id,
			stat_id,
			points,
			false,
			"stale_revision"
		)

		_send_vitals_update(
			session,
			character_id,
			"stale_revision"
		)

		return


	# -----------------------------------------------------
	# Respuestas que indican corrupción/inconsistencia
	# del contrato interno.
	# -----------------------------------------------------

	if _is_fatal_persistence_failure(
		normalized_reason
	):
		game_server.reject_authenticated_peer(
			peer_id,
			(
				"Falló el contrato interno de Primary Stats: "
				+
				normalized_reason
			)
		)


		return


	_send_result(
		session,
		request_id,
		stat_id,
		points,
		false,
		normalized_reason
	)


# =========================================================
# BUILD NEXT ALLOCATED
# =========================================================

func _build_next_allocated(
	state: ServerCharacterPrimaryStatsState,
	stat_id: String,
	points: int
) -> Dictionary:
	if state == null:
		return {}


	if points <= 0:
		return {}


	var next_allocated := {
		"strength": (
			state.allocated_strength
		),

		"agility": (
			state.allocated_agility
		),

		"vitality": (
			state.allocated_vitality
		),

		"energy": (
			state.allocated_energy
		),
	}


	if not next_allocated.has(
		stat_id
	):
		return {}


	next_allocated[
		stat_id
	] = (
		int(
			next_allocated[
				stat_id
			]
		)
		+
		points
	)


	return next_allocated


# =========================================================
# VALIDAR PENDING VS REPOSITORY
# =========================================================

func _pending_matches_persistence(
	pending: Dictionary,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary
) -> bool:
	if (
		int(
			pending.get(
				"account_id",
				0
			)
		) != account_id
	):
		return false


	if (
		int(
			pending.get(
				"character_id",
				0
			)
		) != character_id
	):
		return false


	if (
		int(
			pending.get(
				"expected_revision",
				-1
			)
		) != expected_revision
	):
		return false


	var pending_next_value: Variant = (
		pending.get(
			"next_allocated",
			null
		)
	)


	if typeof(pending_next_value) != TYPE_DICTIONARY:
		return false


	var pending_next: Dictionary = (
		pending_next_value
	)


	return (
		pending_next
		==
		next_allocated
	)


# =========================================================
# VALIDAR STAT ID
# =========================================================

func _is_valid_stat_id(
	stat_id: String
) -> bool:
	return (
		stat_id == "strength"
		or
		stat_id == "agility"
		or
		stat_id == "vitality"
		or
		stat_id == "energy"
	)


# =========================================================
# FATAL PERSISTENCE FAILURE
# =========================================================

func _is_fatal_persistence_failure(
	reason: String
) -> bool:
	return (
		reason == "identity_mismatch"
		or
		reason == "invalid_backend_response"
		or
		reason == "confirmation_mismatch"
	)


# =========================================================
# CLIENT DISCONNECTED
# =========================================================

func _on_client_disconnected(
	peer_id: int
) -> void:
	pending_by_peer.erase(
		peer_id
	)

# =========================================================
# VITALS UPDATE
# =========================================================

func _send_vitals_update(
	session: PlayerWorldSession,
	character_id: int,
	source: String
) -> void:
	if session == null:
		return


	if session.vitals == null:
		return


	if not session.vitals.is_valid():
		return


	if character_id <= 0:
		return


	var replication_result := (
		game_server.send_character_vitals_updated(
			session.peer_id,
			character_id,
			session.vitals.to_snapshot()
		)
	)


	if replication_result != OK:
		push_warning(
			(
				"PrimaryStatAllocationCoordinator | "
				+
				"No se pudieron replicar Vitals live. "
				+
				"Source: %s | Error: %d"
			)
			%
			[
				source,
				replication_result,
			]
		)


		return


	print(
		(
			"PrimaryStatAllocationCoordinator | "
			+
			"Vitals autoritativos replicados"
		),
		" | Character ID: ",
		character_id,
		" | Source: ",
		source,
		" | HP: ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp,
		" | MP: ",
		session.vitals.mp,
		"/",
		session.vitals.max_mp
	)

# =========================================================
# RESULT
# =========================================================

func _send_result(
	session: PlayerWorldSession,
	request_id: int,
	stat_id: String,
	points: int,
	accepted: bool,
	reason: String
) -> void:
	if session == null:
		return


	if session.primary_stats == null:
		return


	var result := (
		game_server.send_primary_stat_allocation_result(
			session.peer_id,
			request_id,
			stat_id,
			points,
			accepted,
			reason,
			session.primary_stats.to_snapshot()
		)
	)


	if result != OK:
		push_warning(
			(
				"PrimaryStatAllocationCoordinator | "
				+
				"No se pudo enviar allocation result. "
				+
				"Error: %d"
			)
			%
			result
		)
