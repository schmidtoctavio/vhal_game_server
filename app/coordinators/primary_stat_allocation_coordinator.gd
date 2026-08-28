class_name PrimaryStatAllocationCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null


# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry
) -> bool:
	if configured:
		return true


	if (
		p_game_server == null
		or
		p_world_session_registry == null
	):
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)


	if not game_server.client_primary_stat_allocation_requested.is_connected(
		_on_primary_stat_allocation_requested
	):
		game_server.client_primary_stat_allocation_requested.connect(
			_on_primary_stat_allocation_requested
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


	# -----------------------------------------------------
	# F22-D2-A:
	#
	# El transporte ya existe, pero todavía NO existe
	# conexión con la persistencia durable.
	#
	# Nunca devolvemos accepted=true antes de que Laravel
	# confirme la mutación.
	# -----------------------------------------------------

	_send_result(
		session,
		request_id,
		normalized_stat_id,
		points,
		false,
		"persistence_not_connected"
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
