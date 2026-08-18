class_name WorldSessionRegistry
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal session_created(
	peer_id: int,
	session: PlayerWorldSession
)

signal session_removed(
	peer_id: int
)


# =========================================================
# CONFIGURACIÓN TEMPORAL DE F13
# =========================================================

const DEFAULT_MAP_ID: String = "test_town"

const DEFAULT_SPAWN_POSITION: Vector3 = (
	Vector3.ZERO
)

const DEFAULT_SPAWN_ROTATION_Y: float = 0.0


# =========================================================
# ESTADO
# =========================================================

var sessions: Dictionary = {}


# =========================================================
# CREAR SESIÓN
# =========================================================

func create_session(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> PlayerWorldSession:
	if peer_id <= 1:
		return null


	if account_id <= 0:
		return null


	if sessions.has(
		peer_id
	):
		remove_session(
			peer_id
		)


	var session := PlayerWorldSession.new(
		peer_id,
		account_id,
		character_data,
		DEFAULT_MAP_ID,
		DEFAULT_SPAWN_POSITION,
		DEFAULT_SPAWN_ROTATION_Y
	)


	if not session.is_valid():
		return null


	sessions[
		peer_id
	] = session


	print(
		"WorldSessionRegistry | Sesión creada | Peer: ",
		peer_id,
		" | Character ID: ",
		session.character_id,
		" | Personaje: ",
		session.character_name,
		" | Mapa: ",
		session.map_id,
		" | Posición: ",
		session.position
	)


	session_created.emit(
		peer_id,
		session
	)


	return session


# =========================================================
# ELIMINAR SESIÓN
# =========================================================

func remove_session(
	peer_id: int
) -> void:
	if not sessions.has(
		peer_id
	):
		return


	sessions.erase(
		peer_id
	)


	print(
		"WorldSessionRegistry | Sesión eliminada | Peer: ",
		peer_id
	)


	session_removed.emit(
		peer_id
	)


# =========================================================
# CONSULTAR
# =========================================================

func get_session(
	peer_id: int
) -> PlayerWorldSession:
	if not sessions.has(
		peer_id
	):
		return null


	return (
		sessions[
			peer_id
		]
		as PlayerWorldSession
	)


func has_session(
	peer_id: int
) -> bool:
	return sessions.has(
		peer_id
	)

# =========================================================
# TODAS LAS SESIONES
# =========================================================

func get_all_sessions() -> Array[PlayerWorldSession]:
	var result: Array[PlayerWorldSession] = []


	for session_value: Variant in sessions.values():
		var session := (
			session_value
			as PlayerWorldSession
		)


		if session == null:
			continue


		result.append(
			session
		)


	return result

# =========================================================
# SESIONES DE UN MAPA
# =========================================================

func get_sessions_in_map(
	map_id: String,
	excluded_peer_id: int = -1
) -> Array[PlayerWorldSession]:
	var result: Array[PlayerWorldSession] = []


	var normalized_map_id := (
		map_id.strip_edges()
	)


	if normalized_map_id.is_empty():
		return result


	for session: PlayerWorldSession in get_all_sessions():
		if session == null:
			continue


		if session.peer_id == excluded_peer_id:
			continue


		if session.map_id != normalized_map_id:
			continue


		result.append(
			session
		)


	return result
