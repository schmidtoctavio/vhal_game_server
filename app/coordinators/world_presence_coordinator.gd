class_name WorldPresenceCoordinator
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


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry


	configured = true


	print(
		"WorldPresenceCoordinator | Inicializado."
	)


	return true


# =========================================================
# PREPARAR PRESENCIA
# =========================================================

func prepare_presence(
	session: PlayerWorldSession
) -> Error:
	if not configured:
		return ERR_UNAVAILABLE


	if session == null:
		return ERR_INVALID_PARAMETER


	# -----------------------------------------------------
	# JUGADORES QUE YA ESTÁN EN EL MISMO MAPA
	# -----------------------------------------------------

	var existing_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			session.peer_id
		)
	)


	var existing_players: Array = []


	for existing_session: PlayerWorldSession in existing_sessions:
		if existing_session == null:
			continue


		existing_players.append(
			existing_session.to_presence_snapshot()
		)


	# -----------------------------------------------------
	# ROSTER INICIAL PARA EL NUEVO PLAYER
	# -----------------------------------------------------

	var presence_result := (
		game_server.send_world_presence_snapshot(
			session.peer_id,
			existing_players
		)
	)


	if presence_result != OK:
		return presence_result


	# -----------------------------------------------------
	# AVISAR A LOS DEMÁS QUE ESTE PLAYER ENTRÓ
	# -----------------------------------------------------

	var new_player_presence := (
		session.to_presence_snapshot()
	)


	for existing_session: PlayerWorldSession in existing_sessions:
		if existing_session == null:
			continue


		var notify_result := (
			game_server.send_player_presence_joined(
				existing_session.peer_id,
				new_player_presence
			)
		)


		if notify_result != OK:
			push_warning(
				(
					"WorldPresenceCoordinator | "
					+
					"No se pudo avisar al peer "
					+
					"%d sobre la entrada del peer %d. Error: %d"
				)
				%
				[
					existing_session.peer_id,
					session.peer_id,
					notify_result,
				]
			)


	print(
		"WorldPresenceCoordinator | Presencia de mundo preparada",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | Mapa: ",
		session.map_id,
		" | Remotos existentes: ",
		existing_players.size()
	)


	return OK


# =========================================================
# ELIMINAR PRESENCIA
# =========================================================

func notify_presence_left(
	session: PlayerWorldSession
) -> void:
	if not configured:
		return


	if session == null:
		return


	var remaining_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			session.peer_id
		)
	)


	for remaining_session: PlayerWorldSession in remaining_sessions:
		if remaining_session == null:
			continue


		var result := (
			game_server.send_player_presence_left(
				remaining_session.peer_id,
				session.peer_id
			)
		)


		if result != OK:
			push_warning(
				(
					"WorldPresenceCoordinator | "
					+
					"No se pudo avisar al peer "
					+
					"%d sobre la salida del peer %d. Error: %d"
				)
				%
				[
					remaining_session.peer_id,
					session.peer_id,
					result,
				]
			)


	print(
		"WorldPresenceCoordinator | Presencia eliminada",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | Mapa: ",
		session.map_id,
		" | Peers notificados: ",
		remaining_sessions.size()
	)
