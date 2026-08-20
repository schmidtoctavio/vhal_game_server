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

signal client_move_requested(
	peer_id: int,
	request_id: int,
	target: Vector3
)

signal client_npc_interaction_requested(
	peer_id: int,
	request_id: int,
	npc_id: String
)

signal client_npc_service_end_requested(
	peer_id: int
)

signal client_vault_item_move_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
)

# =========================================================
# CONFIGURACIÓN
# =========================================================

const DEFAULT_PORT: int = 7000

const DEFAULT_MAX_CLIENTS: int = 100

const AUTH_TIMEOUT_SECONDS: float = 10.0

const NETWORK_PROTOCOL_VERSION: int = 1

const MESSAGE_WORLD_SNAPSHOT: String = (
	"world_snapshot"
)

const MESSAGE_MOVE_REQUEST: String = (
	"move_request"
)

const MESSAGE_NPC_INTERACTION_REQUEST: String = (
	"npc_interaction_request"
)

const MAX_CLIENT_PACKET_SIZE: int = 2048

const MESSAGE_MOVEMENT_STATE: String = (
	"movement_state"
)

const MESSAGE_MOVEMENT_DECISION: String = (
	"movement_decision"
)

const MESSAGE_WORLD_PRESENCE_SNAPSHOT: String = (
	"world_presence_snapshot"
)

const MESSAGE_PLAYER_PRESENCE_JOINED: String = (
	"player_presence_joined"
)

const MESSAGE_PLAYER_PRESENCE_LEFT: String = (
	"player_presence_left"
)

const MESSAGE_NPC_INTERACTION_DECISION: String = (
	"npc_interaction_decision"
)

const MESSAGE_NPC_SERVICE_END_REQUEST: String = (
	"npc_service_end_request"
)

const MESSAGE_NPC_SERVICE_ENDED: String = (
	"npc_service_ended"
)

const MESSAGE_VAULT_SNAPSHOT: String = (
	"vault_snapshot"
)

const MESSAGE_CHARACTER_INVENTORY_SNAPSHOT: String = (
	"character_inventory_snapshot"
)

const MESSAGE_VAULT_ITEM_MOVE_REQUEST: String = (
	"vault_item_move_request"
)

# =========================================================
# ESTADO
# =========================================================

var network_peer: ENetMultiplayerPeer = null

var running: bool = false


var authentication_pending: Dictionary = {}

var authenticated_sessions: Dictionary = {}

var movement_sequences: Dictionary = {}

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

	if not scene_multiplayer.peer_packet.is_connected(
		_on_peer_packet
	):
		scene_multiplayer.peer_packet.connect(
			_on_peer_packet
		)

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

	movement_sequences.erase(
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

# =========================================================
# EXPULSAR PEER AUTENTICADO
# =========================================================

func reject_authenticated_peer(
	peer_id: int,
	message: String
) -> void:
	authenticated_sessions.erase(
		peer_id
	)


	print(
		"GameServer | Peer autenticado expulsado: ",
		peer_id,
		" | ",
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
# ENVIAR SNAPSHOT DE MUNDO
# =========================================================

func send_world_snapshot(
	peer_id: int,
	snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if snapshot.is_empty():
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,
		"type": MESSAGE_WORLD_SNAPSHOT,
		"data": snapshot,
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)


# =========================================================
# ENVIAR ESTADO DE MOVIMIENTO AL DUEÑO
# =========================================================

func send_movement_state(
	peer_id: int,
	position: Vector3,
	rotation_y: float,
	moving: bool
) -> Error:
	var target_peer_ids: Array[int] = [
		peer_id
	]


	return send_movement_state_to_peers(
		peer_id,
		target_peer_ids,
		position,
		rotation_y,
		moving
	)


# =========================================================
# ENVIAR ESTADO DE MOVIMIENTO A VARIOS PEERS
# =========================================================

func send_movement_state_to_peers(
	source_peer_id: int,
	target_peer_ids: Array[int],
	position: Vector3,
	rotation_y: float,
	moving: bool
) -> Error:
	if source_peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		source_peer_id
	):
		return ERR_DOES_NOT_EXIST


	if target_peer_ids.is_empty():
		return ERR_INVALID_PARAMETER


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	# -----------------------------------------------------
	# SEQUENCE DEL ACTOR QUE SE ESTÁ MOVIENDO
	# -----------------------------------------------------
	#
	# Se incrementa UNA SOLA VEZ aunque el mismo estado se
	# replique a varios clientes.
	# -----------------------------------------------------

	var sequence := (
		int(
			movement_sequences.get(
				source_peer_id,
				0
			)
		)
		+
		1
	)


	movement_sequences[
		source_peer_id
	] = sequence


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_MOVEMENT_STATE,

		"data": {
			"peer_id": source_peer_id,

			"sequence": sequence,

			"position": {
				"x": position.x,
				"y": position.y,
				"z": position.z,
			},

			"rotation_y": rotation_y,

			"moving": moving,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	var first_error: Error = OK

	var sent_peers: Dictionary = {}


	for target_peer_id: int in target_peer_ids:
		if target_peer_id <= 1:
			continue


		# -------------------------------------------------
		# EVITAR DESTINATARIOS DUPLICADOS
		# -------------------------------------------------

		if sent_peers.has(
			target_peer_id
		):
			continue


		sent_peers[
			target_peer_id
		] = true


		# -------------------------------------------------
		# EL PEER PUDO DESCONECTARSE ENTRE EL REGISTRY
		# Y ESTA REPLICACIÓN.
		# -------------------------------------------------

		if not authenticated_sessions.has(
			target_peer_id
		):
			continue


		var result := (
			scene_multiplayer.send_bytes(
				packet,
				target_peer_id,
				MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED,
				0
			)
		)


		if (
			result != OK
			and
			first_error == OK
		):
			first_error = result


	return first_error

# =========================================================
# ENVIAR DECISIÓN DE MOVIMIENTO
# =========================================================

func send_movement_decision(
	peer_id: int,
	request_id: int,
	accepted: bool,
	authoritative_position: Vector3,
	authoritative_rotation_y: float,
	authorized_target: Vector3 = Vector3.ZERO,
	reason: String = ""
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if request_id <= 0:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_MOVEMENT_DECISION,

		"data": {
			"peer_id": peer_id,

			"request_id": request_id,

			"accepted": accepted,

			"authoritative_position": {
				"x": authoritative_position.x,
				"y": authoritative_position.y,
				"z": authoritative_position.z,
			},

			"authoritative_rotation_y": (
				authoritative_rotation_y
			),

			"authorized_target": {
				"x": authorized_target.x,
				"y": authorized_target.y,
				"z": authorized_target.z,
			},

			"reason": reason,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# ENVIAR DECISIÓN DE INTERACCIÓN NPC
# =========================================================

func send_npc_interaction_decision(
	peer_id: int,
	request_id: int,
	accepted: bool,
	npc_id: String,
	service_id: String = "",
	reason: String = ""
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if request_id <= 0:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_npc_id := (
		npc_id.strip_edges()
	)


	if normalized_npc_id.is_empty():
		return ERR_INVALID_PARAMETER


	var normalized_service_id := (
		service_id.strip_edges()
	)


	var normalized_reason := (
		reason.strip_edges()
	)


	if (
		accepted
		and
		normalized_service_id.is_empty()
	):
		return ERR_INVALID_PARAMETER


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_NPC_INTERACTION_DECISION,

		"data": {
			"peer_id": peer_id,

			"request_id": request_id,

			"accepted": accepted,

			"npc_id": normalized_npc_id,

			"service_id": normalized_service_id,

			"reason": normalized_reason,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# PAQUETES DEL CLIENTE
# =========================================================

func _on_peer_packet(
	peer_id: int,
	packet: PackedByteArray
) -> void:
	if not authenticated_sessions.has(
		peer_id
	):
		reject_authenticated_peer(
			peer_id,
			"Paquete recibido desde un peer no autenticado."
		)

		return


	if packet.is_empty():
		return


	if packet.size() > MAX_CLIENT_PACKET_SIZE:
		reject_authenticated_peer(
			peer_id,
			"Paquete de cliente demasiado grande."
		)

		return


	var parsed: Variant = (
		JSON.parse_string(
			packet.get_string_from_utf8()
		)
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Paquete de cliente inválido."
		)

		return


	var message: Dictionary = (
		parsed
	)


	var version := int(
		message.get(
			"version",
			0
		)
	)


	if version != NETWORK_PROTOCOL_VERSION:
		reject_authenticated_peer(
			peer_id,
			"Versión de protocolo incompatible."
		)

		return


	var message_type := String(
		message.get(
			"type",
			""
		)
	)


	if message_type == MESSAGE_MOVE_REQUEST:
		_process_move_request(
			peer_id,
			message
		)


		return


	if message_type == MESSAGE_NPC_INTERACTION_REQUEST:
		_process_npc_interaction_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_NPC_SERVICE_END_REQUEST:
		client_npc_service_end_requested.emit(
			peer_id
		)


		return

	if message_type == MESSAGE_VAULT_ITEM_MOVE_REQUEST:
		_process_vault_item_move_request(
			peer_id,
			message
		)


		return

# =========================================================
# MOVE REQUEST
# =========================================================

func _process_move_request(
	peer_id: int,
	message: Dictionary
) -> void:
	var data_value: Variant = (
		message.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Movimiento sin datos válidos."
		)

		return


	var data: Dictionary = (
		data_value
	)

	var request_id := int(
		data.get(
			"request_id",
			0
		)
	)


	if request_id <= 0:
		reject_authenticated_peer(
			peer_id,
			"Movimiento sin Request ID válido."
		)

		return

	var target_value: Variant = (
		data.get(
			"target",
			null
		)
	)


	if typeof(target_value) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Movimiento sin destino válido."
		)

		return


	var target_data: Dictionary = (
		target_value
	)


	if (
		not target_data.has("x")
		or
		not target_data.has("y")
		or
		not target_data.has("z")
	):
		reject_authenticated_peer(
			peer_id,
			"Destino de movimiento incompleto."
		)

		return


	var x_value: Variant = target_data["x"]

	var y_value: Variant = target_data["y"]

	var z_value: Variant = target_data["z"]


	if (
		typeof(x_value) != TYPE_FLOAT
		and
		typeof(x_value) != TYPE_INT
	):
		reject_authenticated_peer(
			peer_id,
			"Coordenada X inválida."
		)

		return


	if (
		typeof(y_value) != TYPE_FLOAT
		and
		typeof(y_value) != TYPE_INT
	):
		reject_authenticated_peer(
			peer_id,
			"Coordenada Y inválida."
		)

		return


	if (
		typeof(z_value) != TYPE_FLOAT
		and
		typeof(z_value) != TYPE_INT
	):
		reject_authenticated_peer(
			peer_id,
			"Coordenada Z inválida."
		)

		return


	var target := Vector3(
		float(x_value),
		float(y_value),
		float(z_value)
	)


	client_move_requested.emit(
		peer_id,
		request_id,
		target
	)

# =========================================================
# NPC INTERACTION REQUEST
# =========================================================

func _process_npc_interaction_request(
	peer_id: int,
	message: Dictionary
) -> void:
	var data_value: Variant = (
		message.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Interacción NPC sin datos válidos."
		)


		return


	var data: Dictionary = (
		data_value
	)


	# -----------------------------------------------------
	# REQUEST ID
	# -----------------------------------------------------

	var request_id := int(
		data.get(
			"request_id",
			0
		)
	)


	if request_id <= 0:
		reject_authenticated_peer(
			peer_id,
			"Interacción NPC sin Request ID válido."
		)


		return


	# -----------------------------------------------------
	# NPC ID
	# -----------------------------------------------------

	var npc_id_value: Variant = (
		data.get(
			"npc_id",
			null
		)
	)


	if typeof(npc_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Interacción NPC sin NPC ID válido."
		)


		return


	var npc_id := String(
		npc_id_value
	).strip_edges()


	if npc_id.is_empty():
		reject_authenticated_peer(
			peer_id,
			"Interacción NPC con NPC ID vacío."
		)


		return


	if npc_id.length() > 64:
		reject_authenticated_peer(
			peer_id,
			"Interacción NPC con NPC ID demasiado largo."
		)


		return


	client_npc_interaction_requested.emit(
		peer_id,
		request_id,
		npc_id
	)

# =========================================================
# ENVIAR ROSTER DEL MUNDO
# =========================================================

func send_world_presence_snapshot(
	peer_id: int,
	players: Array
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_WORLD_PRESENCE_SNAPSHOT,

		"data": {
			"players": players,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# AVISAR ENTRADA DE PLAYER
# =========================================================

func send_player_presence_joined(
	target_peer_id: int,
	player: Dictionary
) -> Error:
	if target_peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if player.is_empty():
		return ERR_INVALID_DATA


	if not authenticated_sessions.has(
		target_peer_id
	):
		return ERR_DOES_NOT_EXIST


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_PLAYER_PRESENCE_JOINED,

		"data": {
			"player": player,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		target_peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# AVISAR SALIDA DE PLAYER
# =========================================================

func send_player_presence_left(
	target_peer_id: int,
	departed_peer_id: int
) -> Error:
	if target_peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if departed_peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		target_peer_id
	):
		return ERR_DOES_NOT_EXIST


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_PLAYER_PRESENCE_LEFT,

		"data": {
			"peer_id": departed_peer_id,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		target_peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# INFORMAR FINALIZACIÓN DE SERVICIO NPC
# =========================================================

func send_npc_service_ended(
	peer_id: int,
	npc_id: String,
	service_id: String,
	reason: String
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_npc_id := (
		npc_id.strip_edges()
	)


	var normalized_service_id := (
		service_id.strip_edges()
	)


	var normalized_reason := (
		reason.strip_edges()
	)


	if normalized_npc_id.is_empty():
		return ERR_INVALID_PARAMETER


	if normalized_service_id.is_empty():
		return ERR_INVALID_PARAMETER


	if normalized_reason.is_empty():
		return ERR_INVALID_PARAMETER


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_NPC_SERVICE_ENDED,

		"data": {
			"npc_id": normalized_npc_id,

			"service_id": normalized_service_id,

			"reason": normalized_reason,
		},
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)


# =========================================================
# ENVIAR SNAPSHOT DE INVENTORY DEL PERSONAJE
# =========================================================

func send_character_inventory_snapshot(
	peer_id: int,
	snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if snapshot.is_empty():
		return ERR_INVALID_DATA


	var account_id := int(
		snapshot.get(
			"account_id",
			0
		)
	)


	var character_id := int(
		snapshot.get(
			"character_id",
			0
		)
	)


	var container := String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges()


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if account_id <= 0:
		return ERR_INVALID_DATA


	if character_id <= 0:
		return ERR_INVALID_DATA


	if container != "inventory":
		return ERR_INVALID_DATA


	if typeof(items_value) != TYPE_ARRAY:
		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# El snapshot también debe corresponder a la identidad
	# autenticada que GameServer ya posee para ese peer.
	# -----------------------------------------------------

	var authenticated_session: Dictionary = (
		authenticated_sessions[
			peer_id
		]
	)


	if int(
		authenticated_session.get(
			"account_id",
			0
		)
	) != account_id:
		return ERR_INVALID_DATA


	var character_value: Variant = (
		authenticated_session.get(
			"character",
			null
		)
	)


	if typeof(character_value) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA


	var character: Dictionary = (
		character_value
	)


	if int(
		character.get(
			"id",
			0
		)
	) != character_id:
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_CHARACTER_INVENTORY_SNAPSHOT,

		"data": snapshot,
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# ENVIAR SNAPSHOT DE VAULT
# =========================================================

func send_vault_snapshot(
	peer_id: int,
	snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if snapshot.is_empty():
		return ERR_INVALID_DATA


	var account_id := int(
		snapshot.get(
			"account_id",
			0
		)
	)


	var container := String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges()


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if account_id <= 0:
		return ERR_INVALID_DATA


	if container != "vault":
		return ERR_INVALID_DATA


	if typeof(items_value) != TYPE_ARRAY:
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_VAULT_SNAPSHOT,

		"data": snapshot,
	}


	var packet := (
		JSON.stringify(
			message
		).to_utf8_buffer()
	)


	return scene_multiplayer.send_bytes(
		packet,
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# VAULT ITEM MOVE REQUEST
# =========================================================

func _process_vault_item_move_request(
	peer_id: int,
	message: Dictionary
) -> void:
	var data_value: Variant = message.get(
		"data",
		null
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Movimiento de Vault sin datos válidos."
		)


		return


	var data: Dictionary = (
		data_value
	)


	var request_id := int(
		data.get(
			"request_id",
			0
		)
	)


	if request_id <= 0:
		reject_authenticated_peer(
			peer_id,
			"Movimiento de Vault sin Request ID válido."
		)


		return


	var uid_value: Variant = data.get(
		"uid",
		null
	)


	if typeof(uid_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Movimiento de Vault sin UID válido."
		)


		return


	var uid := String(
		uid_value
	).strip_edges()


	if (
		uid.is_empty()
		or
		uid.length() > 64
	):
		reject_authenticated_peer(
			peer_id,
			"UID de Vault inválido."
		)


		return


	var current_position := (
		_parse_vault_grid_position(
			data.get(
				"current_grid_position",
				null
			)
		)
	)


	if current_position.x < 0:
		reject_authenticated_peer(
			peer_id,
			"Posición actual de Vault inválida."
		)


		return


	var new_position := (
		_parse_vault_grid_position(
			data.get(
				"new_grid_position",
				null
			)
		)
	)


	if new_position.x < 0:
		reject_authenticated_peer(
			peer_id,
			"Nueva posición de Vault inválida."
		)


		return


	client_vault_item_move_requested.emit(
		peer_id,
		request_id,
		uid,
		current_position,
		new_position
	)


func _parse_vault_grid_position(
	value: Variant
) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2i(
			-1,
			-1
		)


	var data: Dictionary = (
		value
	)


	if (
		not data.has("x")
		or
		not data.has("y")
	):
		return Vector2i(
			-1,
			-1
		)


	var x_value: Variant = data["x"]
	var y_value: Variant = data["y"]


	if (
		typeof(x_value) != TYPE_INT
		and
		typeof(x_value) != TYPE_FLOAT
	):
		return Vector2i(
			-1,
			-1
		)


	if (
		typeof(y_value) != TYPE_INT
		and
		typeof(y_value) != TYPE_FLOAT
	):
		return Vector2i(
			-1,
			-1
		)


	var x_float := float(
		x_value
	)

	var y_float := float(
		y_value
	)


	if x_float != floor(
		x_float
	):
		return Vector2i(
			-1,
			-1
		)


	if y_float != floor(
		y_float
	):
		return Vector2i(
			-1,
			-1
		)


	var position := Vector2i(
		int(x_float),
		int(y_float)
	)


	if (
		position.x < 0
		or
		position.x >= 8
		or
		position.y < 0
		or
		position.y >= 16
	):
		return Vector2i(
			-1,
			-1
		)


	return position
