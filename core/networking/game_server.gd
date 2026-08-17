class_name GameServer
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal server_started(
	port: int
)

signal client_authentication_requested(
	peer_id: int,
	ticket: String
)

signal client_authenticated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
)

signal client_authentication_rejected(
	peer_id: int,
	message: String
)

signal client_connected(
	peer_id: int
)

signal client_disconnected(
	peer_id: int
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

const DEFAULT_PORT: int = 7000

const DEFAULT_MAX_CLIENTS: int = 100

const AUTH_TIMEOUT_SECONDS: float = 10.0


# =========================================================
# ESTADO
# =========================================================

var network_peer: ENetMultiplayerPeer = null

var running: bool = false


var authentication_pending: Dictionary = {}

var authenticated_sessions: Dictionary = {}


# =========================================================
# START
# =========================================================

func start(
	port: int = DEFAULT_PORT,
	max_clients: int = DEFAULT_MAX_CLIENTS
) -> Error:
	if running:
		return ERR_ALREADY_IN_USE


	network_peer = ENetMultiplayerPeer.new()


	var result := network_peer.create_server(
		port,
		max_clients
	)


	if result != OK:
		network_peer = null

		return result


	_connect_multiplayer_signals()


	multiplayer.multiplayer_peer = (
		network_peer
	)


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		network_peer.close()

		network_peer = null

		return ERR_UNAVAILABLE


	scene_multiplayer.auth_timeout = (
		AUTH_TIMEOUT_SECONDS
	)


	scene_multiplayer.auth_callback = (
		_on_auth_payload_received
	)


	running = true


	print(
		"VHAL Game Server | Listening on UDP ",
		port,
		" | Max clients: ",
		max_clients
	)


	server_started.emit(
		port
	)


	return OK


# =========================================================
# SIGNALS MULTIPLAYER
# =========================================================

func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(
		_on_peer_connected
	):
		multiplayer.peer_connected.connect(
			_on_peer_connected
		)


	if not multiplayer.peer_disconnected.is_connected(
		_on_peer_disconnected
	):
		multiplayer.peer_disconnected.connect(
			_on_peer_disconnected
		)


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return


	if not scene_multiplayer.peer_authenticating.is_connected(
		_on_peer_authenticating
	):
		scene_multiplayer.peer_authenticating.connect(
			_on_peer_authenticating
		)


	if not scene_multiplayer.peer_authentication_failed.is_connected(
		_on_peer_authentication_failed
	):
		scene_multiplayer.peer_authentication_failed.connect(
			_on_peer_authentication_failed
		)


# =========================================================
# PEER AUTENTICANDO
# =========================================================

func _on_peer_authenticating(
	peer_id: int
) -> void:
	print(
		"GameServer | Peer autenticando: ",
		peer_id
	)


# =========================================================
# RECIBIR AUTH
# =========================================================

func _on_auth_payload_received(
	peer_id: int,
	payload: PackedByteArray
) -> void:
	if peer_id <= 1:
		_reject_authentication(
			peer_id,
			"Peer inválido."
		)

		return


	if authentication_pending.has(
		peer_id
	):
		_reject_authentication(
			peer_id,
			"Autenticación duplicada."
		)

		return


	var parsed: Variant = (
		JSON.parse_string(
			payload.get_string_from_utf8()
		)
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		_reject_authentication(
			peer_id,
			"Payload de autenticación inválido."
		)

		return


	var auth_data: Dictionary = (
		parsed
	)


	var ticket := String(
		auth_data.get(
			"ticket",
			""
		)
	).strip_edges()


	if ticket.length() != 64:
		_reject_authentication(
			peer_id,
			"Formato de ticket inválido."
		)

		return


	authentication_pending[
		peer_id
	] = true


	client_authentication_requested.emit(
		peer_id,
		ticket
	)


# =========================================================
# ACEPTAR AUTENTICACIÓN
# =========================================================

func accept_authentication(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> void:
	if not authentication_pending.has(
		peer_id
	):
		return


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return


	if not scene_multiplayer.get_authenticating_peers().has(
		peer_id
	):
		authentication_pending.erase(
			peer_id
		)

		return


	var character_id := int(
		character_data.get(
			"id",
			0
		)
	)


	if (
		account_id <= 0
		or
		character_id <= 0
	):
		_reject_authentication(
			peer_id,
			"Identidad inválida."
		)

		return


	authenticated_sessions[
		peer_id
	] = {
		"account_id": account_id,
		"character": character_data.duplicate(
			true
		),
	}


	authentication_pending.erase(
		peer_id
	)


	var result := (
		scene_multiplayer.complete_auth(
			peer_id
		)
	)


	if result != OK:
		authenticated_sessions.erase(
			peer_id
		)


		_reject_authentication(
			peer_id,
			"No se pudo completar la autenticación."
		)


# =========================================================
# RECHAZAR AUTENTICACIÓN
# =========================================================

func reject_authentication(
	peer_id: int,
	message: String
) -> void:
	_reject_authentication(
		peer_id,
		message
	)


func _reject_authentication(
	peer_id: int,
	message: String
) -> void:
	authentication_pending.erase(
		peer_id
	)


	authenticated_sessions.erase(
		peer_id
	)


	print(
		"GameServer | Autenticación rechazada | Peer: ",
		peer_id,
		" | ",
		message
	)


	client_authentication_rejected.emit(
		peer_id,
		message
	)


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer != null:
		scene_multiplayer.disconnect_peer(
			peer_id
		)


# =========================================================
# AUTH FALLIDA
# =========================================================

func _on_peer_authentication_failed(
	peer_id: int
) -> void:
	authentication_pending.erase(
		peer_id
	)


	authenticated_sessions.erase(
		peer_id
	)


	print(
		"GameServer | Peer no autenticado desconectado: ",
		peer_id
	)


# =========================================================
# CLIENT CONNECTED
# =========================================================

func _on_peer_connected(
	peer_id: int
) -> void:
	if not authenticated_sessions.has(
		peer_id
	):
		var scene_multiplayer := (
			multiplayer
			as SceneMultiplayer
		)


		if scene_multiplayer != null:
			scene_multiplayer.disconnect_peer(
				peer_id
			)


		return


	var session: Dictionary = (
		authenticated_sessions[
			peer_id
		]
	)


	var account_id := int(
		session.get(
			"account_id",
			0
		)
	)


	var character_data: Dictionary = (
		session.get(
			"character",
			{}
		)
	)


	print(
		"GameServer | Peer autenticado conectado: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		character_data.get(
			"name",
			"?"
		)
	)


	client_connected.emit(
		peer_id
	)


	client_authenticated.emit(
		peer_id,
		account_id,
		character_data
	)


# =========================================================
# CLIENT DISCONNECTED
# =========================================================

func _on_peer_disconnected(
	peer_id: int
) -> void:
	authentication_pending.erase(
		peer_id
	)


	authenticated_sessions.erase(
		peer_id
	)


	print(
		"GameServer | Peer desconectado: ",
		peer_id
	)


	client_disconnected.emit(
		peer_id
	)


# =========================================================
# CONSULTAR SESIÓN
# =========================================================

func get_authenticated_session(
	peer_id: int
) -> Dictionary:
	if not authenticated_sessions.has(
		peer_id
	):
		return {}


	return (
		authenticated_sessions[
			peer_id
		].duplicate(
			true
		)
	)
