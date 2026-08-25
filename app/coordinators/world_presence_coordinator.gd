class_name WorldPresenceCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

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
	p_world_mob_registry: WorldMobRegistry
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_mob_registry == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	world_mob_registry = p_world_mob_registry

	if not world_mob_registry.mob_respawned.is_connected(
		_on_mob_respawned
	):
		world_mob_registry.mob_respawned.connect(
			_on_mob_respawned
		)

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
	# MOBS AUTORITATIVOS DEL MAPA
	# -----------------------------------------------------

	var mobs_in_map := (
		world_mob_registry.get_mobs_in_map(
			session.map_id
		)
	)


	var world_mobs: Array = []


	for mob: WorldMobRuntimeState in mobs_in_map:
		if mob == null:
			continue


		if not mob.is_valid():
			continue


		var mob_snapshot := (
			mob.to_snapshot()
		)


		if mob_snapshot.is_empty():
			continue


		world_mobs.append(
			mob_snapshot
		)

	# -----------------------------------------------------
	# ROSTER INICIAL PARA EL NUEVO PLAYER
	# -----------------------------------------------------

	var presence_result := (
		game_server.send_world_presence_snapshot(
			session.peer_id,
			existing_players,
			world_mobs
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
		" | Mobs: ",
		world_mobs.size(),
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

# =========================================================
# MOB RESPAWN
# =========================================================

func _on_mob_respawned(
	entity_id: String,
	map_id: String,
	mob_snapshot: Dictionary
) -> void:
	if not configured:
		return


	var normalized_entity_id := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	var normalized_map_id := (
		map_id.strip_edges()
	)


	if (
		normalized_entity_id.is_empty()
		or
		normalized_map_id.is_empty()
		or
		mob_snapshot.is_empty()
	):
		return


	var sessions := (
		world_session_registry.get_sessions_in_map(
			normalized_map_id
		)
	)


	var recipients := 0


	for session: PlayerWorldSession in sessions:
		if session == null:
			continue


		var result := (
			game_server.send_mob_state_updated(
				session.peer_id,
				mob_snapshot
			)
		)


		if result != OK:
			push_warning(
				(
					"WorldPresenceCoordinator | "
					+
					"No se pudo replicar respawn de '%s' "
					+
					"al peer %d. Error: %d"
				)
				%
				[
					normalized_entity_id,
					session.peer_id,
					result,
				]
			)


			continue


		recipients += 1


	print(
		"WorldPresenceCoordinator | Respawn de mob replicado",
		" | Entity: ",
		normalized_entity_id,
		" | Mapa: ",
		normalized_map_id,
		" | Recipients: ",
		recipients
	)
