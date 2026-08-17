class_name GameServer
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal server_started(
	port: int
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


# =========================================================
# ESTADO
# =========================================================

var network_peer: ENetMultiplayerPeer = null

var running: bool = false


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
		print(
			"GameServer | No se pudo iniciar. Error: ",
			result
		)


		network_peer = null


		return result


	_connect_multiplayer_signals()


	multiplayer.multiplayer_peer = (
		network_peer
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


# =========================================================
# CLIENT CONNECTED
# =========================================================

func _on_peer_connected(
	peer_id: int
) -> void:
	print(
		"GameServer | Peer conectado: ",
		peer_id
	)


	client_connected.emit(
		peer_id
	)


# =========================================================
# CLIENT DISCONNECTED
# =========================================================

func _on_peer_disconnected(
	peer_id: int
) -> void:
	print(
		"GameServer | Peer desconectado: ",
		peer_id
	)


	client_disconnected.emit(
		peer_id
	)
