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

signal client_skill_cast_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary
)

signal client_skill_learning_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	scroll_uid: String
)

signal client_basic_attack_requested(
	peer_id: int,
	request_id: int,
	target: Dictionary
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

signal client_inventory_item_move_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
)

signal client_item_container_transfer_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	current_position: Vector2i,
	new_position: Vector2i
)

signal client_equipment_equip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: String
)


signal client_equipment_unequip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_equipment_slot: String,
	new_position: Vector2i
)

signal client_world_drop_pickup_requested(
	peer_id: int,
	request_id: int,
	entity_id: String
)

signal client_primary_stat_allocation_requested(
	peer_id: int,
	request_id: int,
	stat_id: String,
	points: int
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

const MESSAGE_SKILL_CAST_REQUEST: String = (
	"skill_cast_request"
)

const MESSAGE_SKILL_CAST_RESULT: String = (
	"skill_cast_result"
)

const MESSAGE_SKILL_LEARNING_REQUEST: String = (
	"skill_learning_request"
)

const MESSAGE_SKILL_LEARNING_RESULT: String = (
	"skill_learning_result"
)

const MESSAGE_SKILL_TRAINER_OFFERS: String = (
	"skill_trainer_offers"
)

const MESSAGE_BASIC_ATTACK_REQUEST: String = (
	"basic_attack_request"
)

const MESSAGE_BASIC_ATTACK_RESULT: String = (
	"basic_attack_result"
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

const MESSAGE_CHARACTER_EQUIPMENT_SNAPSHOT: String = (
	"character_equipment_snapshot"
)

const MESSAGE_VAULT_ITEM_MOVE_REQUEST: String = (
	"vault_item_move_request"
)

const MESSAGE_INVENTORY_ITEM_MOVE_REQUEST: String = (
	"inventory_item_move_request"
)

const MESSAGE_ITEM_CONTAINER_TRANSFER_REQUEST: String = (
	"item_container_transfer_request"
)

const MESSAGE_EQUIPMENT_EQUIP_REQUEST: String = (
	"equipment_equip_request"
)


const MESSAGE_EQUIPMENT_UNEQUIP_REQUEST: String = (
	"equipment_unequip_request"
)

const MESSAGE_MOB_STATE_UPDATED: String = (
	"mob_state_updated"
)

const MESSAGE_WORLD_DROP_SPAWNED: String = (
	"world_drop_spawned"
)

const MESSAGE_WORLD_DROP_PICKUP_REQUEST: String = (
	"world_drop_pickup_request"
)

const MESSAGE_WORLD_DROP_PICKUP_RESULT: String = (
	"world_drop_pickup_result"
)

const MESSAGE_WORLD_DROP_REMOVED: String = (
	"world_drop_removed"
)

const MESSAGE_CHARACTER_PROGRESSION_UPDATED: String = (
	"character_progression_updated"
)

const MESSAGE_PRIMARY_STAT_ALLOCATION_REQUEST: String = (
	"primary_stat_allocation_request"
)

const MESSAGE_PRIMARY_STAT_ALLOCATION_RESULT: String = (
	"primary_stat_allocation_result"
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
# ENVIAR RESULTADO DE APRENDIZAJE DE SKILL
# =========================================================

func send_skill_learning_result(
	peer_id: int,
	request_id: int,
	skill_id: String,
	scroll_uid: String,
	accepted: bool,
	reason: String,
	learned_skill_ids: PackedStringArray,
	idempotent: bool = false
) -> Error:
	if (
		peer_id <= 1
		or
		request_id <= 0
	):
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	var normalized_scroll_uid := (
		scroll_uid
		.strip_edges()
		.to_lower()
	)


	var normalized_reason := (
		reason.strip_edges()
	)


	if (
		normalized_skill_id.is_empty()
		or
		normalized_skill_id.length() > 64
	):
		return ERR_INVALID_PARAMETER


	if (
		normalized_scroll_uid.is_empty()
		or
		normalized_scroll_uid.length() > 64
	):
		return ERR_INVALID_PARAMETER


	if normalized_reason.is_empty():
		return ERR_INVALID_PARAMETER


	var normalized_learned_skill_ids: Array[String] = []

	var seen_skill_ids: Dictionary = {}


	for learned_skill_id_value: String in learned_skill_ids:
		var learned_skill_id := (
			learned_skill_id_value
			.strip_edges()
			.to_lower()
		)


		if (
			learned_skill_id.is_empty()
			or
			learned_skill_id.length() > 64
		):
			return ERR_INVALID_DATA


		if not ServerSkillCatalog.has_definition(
			learned_skill_id
		):
			return ERR_INVALID_DATA


		if seen_skill_ids.has(
			learned_skill_id
		):
			return ERR_INVALID_DATA


		seen_skill_ids[
			learned_skill_id
		] = true


		normalized_learned_skill_ids.append(
			learned_skill_id
		)


	normalized_learned_skill_ids.sort()


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_SKILL_LEARNING_RESULT,

		"data": {
			"request_id": request_id,

			"skill_id": normalized_skill_id,

			"scroll_uid": normalized_scroll_uid,

			"accepted": accepted,

			"reason": normalized_reason,

			"learned_skill_ids": (
				normalized_learned_skill_ids
			),

			"idempotent": idempotent,
		},
	}


	return scene_multiplayer.send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# ENVIAR OFERTAS AUTORITATIVAS DEL SKILL TRAINER
# =========================================================

func send_skill_trainer_offers(
	peer_id: int,
	snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var contract_error := (
		ServerSkillTrainerOfferBuilder.validate_snapshot(
			snapshot
		)
	)


	if not contract_error.is_empty():
		push_warning(
			(
				"GameServer | "
				+
				"Trainer Offers inválidas: %s"
			)
			%
			contract_error
		)


		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# EL SNAPSHOT DEBE PERTENECER AL PERSONAJE
	# AUTENTICADO EN ESTE PEER.
	# -----------------------------------------------------

	var authenticated_value: Variant = (
		authenticated_sessions[
			peer_id
		]
	)


	if typeof(authenticated_value) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA


	var authenticated: Dictionary = (
		authenticated_value as Dictionary
	)


	var character_value: Variant = (
		authenticated.get(
			"character",
			null
		)
	)


	if typeof(character_value) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA


	var character: Dictionary = (
		character_value as Dictionary
	)


	var authenticated_character_id := int(
		character.get(
			"id",
			0
		)
	)


	var snapshot_character_id := int(
		snapshot.get(
			"character_id",
			0
		)
	)


	if (
		authenticated_character_id <= 0
		or
		snapshot_character_id
		!=
		authenticated_character_id
	):
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_SKILL_TRAINER_OFFERS,

		"data": snapshot.duplicate(
			true
		),
	}


	return scene_multiplayer.send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# ENVIAR RESULTADO DE SKILL CAST
# =========================================================

func send_skill_cast_result(
	peer_id: int,
	request_id: int,
	skill_id: String,
	accepted: bool,
	reason: String,
	vitals_snapshot: Dictionary,
	cooldown_remaining_seconds: float = 0.0,
	effect: Dictionary = {}
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if request_id <= 0:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	if normalized_skill_id.is_empty():
		return ERR_INVALID_PARAMETER


	if vitals_snapshot.is_empty():
		return ERR_INVALID_DATA


	if cooldown_remaining_seconds < 0.0:
		return ERR_INVALID_PARAMETER


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_SKILL_CAST_RESULT,

		"data": {
			"request_id": request_id,

			"skill_id": normalized_skill_id,

			"accepted": accepted,

			"reason": reason,

			"vitals": vitals_snapshot.duplicate(
				true
			),

			"cooldown_remaining_seconds": (
				cooldown_remaining_seconds
			),

			"effect": effect.duplicate(
				true
			),
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

	if message_type == MESSAGE_SKILL_CAST_REQUEST:
		_process_skill_cast_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_SKILL_LEARNING_REQUEST:
		_process_skill_learning_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_BASIC_ATTACK_REQUEST:
		_process_basic_attack_request(
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

	if message_type == MESSAGE_INVENTORY_ITEM_MOVE_REQUEST:
		_process_inventory_item_move_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_ITEM_CONTAINER_TRANSFER_REQUEST:
		_process_item_container_transfer_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_EQUIPMENT_EQUIP_REQUEST:
		_process_equipment_equip_request(
			peer_id,
			message
		)


		return


	if message_type == MESSAGE_EQUIPMENT_UNEQUIP_REQUEST:
		_process_equipment_unequip_request(
			peer_id,
			message
		)


		return

	if message_type == MESSAGE_WORLD_DROP_PICKUP_REQUEST:
		_process_world_drop_pickup_request(
			peer_id,
			message
		)


		return

	if (
		message_type
		==
		MESSAGE_PRIMARY_STAT_ALLOCATION_REQUEST
	):
		_process_primary_stat_allocation_request(
			peer_id,
			message
		)


		return

func _process_world_drop_pickup_request(
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
			"Pickup sin datos válidos."
		)


		return


	var data: Dictionary = data_value


	var request_id := int(
		data.get(
			"request_id",
			0
		)
	)


	if request_id <= 0:
		reject_authenticated_peer(
			peer_id,
			"Pickup sin Request ID válido."
		)


		return


	var entity_id_value: Variant = data.get(
		"entity_id",
		null
	)


	if typeof(entity_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Pickup sin Entity ID válido."
		)


		return


	var entity_id := String(
		entity_id_value
	).strip_edges().to_lower()


	if (
		entity_id.is_empty()
		or
		entity_id.length() > 96
	):
		reject_authenticated_peer(
			peer_id,
			"Pickup con Entity ID inválido."
		)


		return


	client_world_drop_pickup_requested.emit(
		peer_id,
		request_id,
		entity_id
	)

# =========================================================
# PRIMARY STAT ALLOCATION REQUEST
# =========================================================

func _process_primary_stat_allocation_request(
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
			"Stat Allocation sin datos válidos."
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
			"Stat Allocation sin Request ID válido."
		)


		return


	var stat_id_value: Variant = (
		data.get(
			"stat_id",
			null
		)
	)


	if typeof(stat_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Stat Allocation sin Stat ID válido."
		)


		return


	var stat_id := String(
		stat_id_value
	).strip_edges().to_lower()


	if (
		stat_id.is_empty()
		or
		stat_id.length() > 32
	):
		reject_authenticated_peer(
			peer_id,
			"Stat Allocation con Stat ID inválido."
		)


		return


	var points_value: Variant = (
		data.get(
			"points",
			null
		)
	)


	if (
		typeof(points_value) != TYPE_INT
		and
		typeof(points_value) != TYPE_FLOAT
	):
		reject_authenticated_peer(
			peer_id,
			"Stat Allocation con Points inválidos."
		)


		return


	var points := int(
		points_value
	)


	client_primary_stat_allocation_requested.emit(
		peer_id,
		request_id,
		stat_id,
		points
	)

# =========================================================
# PRIMARY STAT ALLOCATION RESULT
# =========================================================

func send_primary_stat_allocation_result(
	peer_id: int,
	request_id: int,
	stat_id: String,
	points: int,
	accepted: bool,
	reason: String,
	primary_stats_snapshot: Dictionary
) -> Error:
	if (
		peer_id <= 1
		or
		request_id <= 0
	):
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_stat_id := (
		stat_id
		.strip_edges()
		.to_lower()
	)


	var normalized_reason := (
		reason.strip_edges()
	)


	if (
		normalized_stat_id.is_empty()
		or
		normalized_stat_id.length() > 32
	):
		return ERR_INVALID_PARAMETER


	if points <= 0:
		return ERR_INVALID_PARAMETER


	if normalized_reason.is_empty():
		return ERR_INVALID_PARAMETER


	if primary_stats_snapshot.is_empty():
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": (
			MESSAGE_PRIMARY_STAT_ALLOCATION_RESULT
		),

		"data": {
			"request_id": request_id,

			"stat_id": normalized_stat_id,

			"points": points,

			"accepted": accepted,

			"reason": normalized_reason,

			"primary_stats": (
				primary_stats_snapshot.duplicate(
					true
				)
			),
		},
	}


	return scene_multiplayer.send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

func send_world_drop_pickup_result(
	peer_id: int,
	request_id: int,
	entity_id: String,
	accepted: bool,
	reason: String
) -> Error:
	if (
		peer_id <= 1
		or
		request_id <= 0
	):
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_WORLD_DROP_PICKUP_RESULT,

		"data": {
			"request_id": request_id,

			"entity_id": entity_id,

			"accepted": accepted,

			"reason": reason,
		},
	}


	return (
		multiplayer as SceneMultiplayer
	).send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

func send_world_drop_removed(
	peer_id: int,
	entity_id: String
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_WORLD_DROP_REMOVED,

		"data": {
			"entity_id": entity_id,
		},
	}


	return (
		multiplayer as SceneMultiplayer
	).send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

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
# SKILL CAST REQUEST
# =========================================================

func _process_skill_cast_request(
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
			"Cast sin datos válidos."
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
			"Cast sin Request ID válido."
		)


		return


	# -----------------------------------------------------
	# SKILL ID
	# -----------------------------------------------------

	var skill_id_value: Variant = (
		data.get(
			"skill_id",
			null
		)
	)


	if typeof(skill_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Cast sin Skill ID válido."
		)


		return


	var skill_id := String(
		skill_id_value
	).strip_edges().to_lower()


	if skill_id.is_empty():
		reject_authenticated_peer(
			peer_id,
			"Cast con Skill ID vacío."
		)


		return


	if skill_id.length() > 64:
		reject_authenticated_peer(
			peer_id,
			"Cast con Skill ID demasiado largo."
		)


		return


	# -----------------------------------------------------
	# TARGET
	# -----------------------------------------------------

	var target_value: Variant = (
		data.get(
			"target",
			null
		)
	)


	if typeof(target_value) != TYPE_DICTIONARY:
		reject_authenticated_peer(
			peer_id,
			"Cast sin target válido."
		)


		return


	var target: Dictionary = (
		target_value
	)


	var target_kind_value: Variant = (
		target.get(
			"kind",
			null
		)
	)


	if typeof(target_kind_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Cast sin tipo de target válido."
		)


		return


	var target_kind := String(
		target_kind_value
	).strip_edges().to_lower()


	if target_kind.is_empty():
		reject_authenticated_peer(
			peer_id,
			"Cast con tipo de target vacío."
		)


		return


	if target_kind.length() > 32:
		reject_authenticated_peer(
			peer_id,
			"Cast con tipo de target demasiado largo."
		)


		return


	var normalized_target: Dictionary = {}


	# -----------------------------------------------------
	# SELF TARGET
	# -----------------------------------------------------

	if target_kind == "self":
		normalized_target = {
			"kind": "self",
		}


	# -----------------------------------------------------
	# ENTITY TARGET
	# -----------------------------------------------------

	elif target_kind == "entity":
		var entity_id_value: Variant = (
			target.get(
				"entity_id",
				null
			)
		)


		if typeof(entity_id_value) != TYPE_STRING:
			reject_authenticated_peer(
				peer_id,
				"Cast entity sin Entity ID válido."
			)


			return


		var entity_id := String(
			entity_id_value
		).strip_edges().to_lower()


		if entity_id.is_empty():
			reject_authenticated_peer(
				peer_id,
				"Cast entity con Entity ID vacío."
			)


			return


		if entity_id.length() > 96:
			reject_authenticated_peer(
				peer_id,
				"Cast entity con Entity ID demasiado largo."
			)


			return


		normalized_target = {
			"kind": "entity",

			"entity_id": entity_id,
		}


	# -----------------------------------------------------
	# KIND NO SOPORTADO
	# -----------------------------------------------------

	else:
		reject_authenticated_peer(
			peer_id,
			"Tipo de target de cast no soportado."
		)


		return


	client_skill_cast_requested.emit(
		peer_id,
		request_id,
		skill_id,
		normalized_target
	)

# =========================================================
# SKILL LEARNING REQUEST
# =========================================================

func _process_skill_learning_request(
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
			"Aprendizaje de Skill sin datos válidos."
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
			"Aprendizaje de Skill sin Request ID válido."
		)


		return


	# -----------------------------------------------------
	# SKILL ID
	# -----------------------------------------------------

	var skill_id_value: Variant = (
		data.get(
			"skill_id",
			null
		)
	)


	if typeof(skill_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Aprendizaje de Skill sin Skill ID válido."
		)


		return


	var skill_id := String(
		skill_id_value
	).strip_edges().to_lower()


	if (
		skill_id.is_empty()
		or
		skill_id.length() > 64
	):
		reject_authenticated_peer(
			peer_id,
			"Aprendizaje con Skill ID inválido."
		)


		return


	# -----------------------------------------------------
	# SCROLL UID
	# -----------------------------------------------------

	var scroll_uid_value: Variant = (
		data.get(
			"scroll_uid",
			null
		)
	)


	if typeof(scroll_uid_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Aprendizaje de Skill sin Scroll UID válido."
		)


		return


	var scroll_uid := String(
		scroll_uid_value
	).strip_edges().to_lower()


	if (
		scroll_uid.is_empty()
		or
		scroll_uid.length() > 64
	):
		reject_authenticated_peer(
			peer_id,
			"Aprendizaje con Scroll UID inválido."
		)


		return


	client_skill_learning_requested.emit(
		peer_id,
		request_id,
		skill_id,
		scroll_uid
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
	players: Array,
	mobs: Array,
	drops: Array
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
			"players": players.duplicate(
				true
			),

			"mobs": mobs.duplicate(
				true
			),

			"drops": drops.duplicate(
				true
			),
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
# ENVIAR SNAPSHOT DE EQUIPMENT DEL PERSONAJE
# =========================================================

func send_character_equipment_snapshot(
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


	if String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges() != "equipment":
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,
		"type": MESSAGE_CHARACTER_EQUIPMENT_SNAPSHOT,
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

# =========================================================
# INVENTORY ITEM MOVE REQUEST
# =========================================================

func _process_inventory_item_move_request(
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
			"Movimiento de Inventory sin datos válidos."
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
			"Movimiento de Inventory sin Request ID válido."
		)


		return


	var uid_value: Variant = (
		data.get(
			"uid",
			null
		)
	)


	if typeof(uid_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Movimiento de Inventory sin UID válido."
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
			"UID de Inventory inválido."
		)


		return


	var current_position := (
		_parse_inventory_grid_position(
			data.get(
				"current_grid_position",
				null
			)
		)
	)


	var new_position := (
		_parse_inventory_grid_position(
			data.get(
				"new_grid_position",
				null
			)
		)
	)


	if (
		current_position == Vector2i(-1, -1)
		or
		new_position == Vector2i(-1, -1)
	):
		reject_authenticated_peer(
			peer_id,
			"Posición de Inventory inválida."
		)


		return


	if current_position == new_position:
		return


	client_inventory_item_move_requested.emit(
		peer_id,
		request_id,
		uid,
		current_position,
		new_position
	)


# =========================================================
# PARSEAR POSICIÓN DE INVENTORY
# =========================================================

func _parse_inventory_grid_position(
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
		not data.has(
			"x"
		)
		or
		not data.has(
			"y"
		)
	):
		return Vector2i(
			-1,
			-1
		)


	var x_value: Variant = (
		data[
			"x"
		]
	)

	var y_value: Variant = (
		data[
			"y"
		]
	)


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
		position.y >= 8
	):
		return Vector2i(
			-1,
			-1
		)


	return position

# =========================================================
# ITEM CONTAINER TRANSFER REQUEST
# =========================================================

func _process_item_container_transfer_request(
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
			"Transferencia de item sin datos válidos."
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
			"Transferencia de item sin Request ID válido."
		)


		return


	# -----------------------------------------------------
	# UID
	# -----------------------------------------------------

	var uid_value: Variant = (
		data.get(
			"uid",
			null
		)
	)


	if typeof(uid_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Transferencia de item sin UID válido."
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
			"UID de transferencia inválido."
		)


		return


	# -----------------------------------------------------
	# CONTENEDOR ORIGEN
	# -----------------------------------------------------

	var source_value: Variant = (
		data.get(
			"source_container",
			null
		)
	)


	if typeof(source_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Contenedor de origen inválido."
		)


		return


	var source_container := String(
		source_value
	).strip_edges().to_lower()


	if not _is_transfer_container(
		source_container
	):
		reject_authenticated_peer(
			peer_id,
			"Contenedor de origen no soportado."
		)


		return


	# -----------------------------------------------------
	# CONTENEDOR DESTINO
	# -----------------------------------------------------

	var target_value: Variant = (
		data.get(
			"target_container",
			null
		)
	)


	if typeof(target_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Contenedor de destino inválido."
		)


		return


	var target_container := String(
		target_value
	).strip_edges().to_lower()


	if not _is_transfer_container(
		target_container
	):
		reject_authenticated_peer(
			peer_id,
			"Contenedor de destino no soportado."
		)


		return


	if source_container == target_container:
		reject_authenticated_peer(
			peer_id,
			(
				"Transferencia con origen "
				+
				"y destino iguales."
			)
		)


		return


	# -----------------------------------------------------
	# POSICIÓN ACTUAL
	# -----------------------------------------------------

	var current_position := (
		_parse_transfer_grid_position(
			data.get(
				"current_grid_position",
				null
			),
			source_container
		)
	)


	if current_position == Vector2i(
		-1,
		-1
	):
		reject_authenticated_peer(
			peer_id,
			"Posición actual de transferencia inválida."
		)


		return


	# -----------------------------------------------------
	# POSICIÓN DESTINO
	# -----------------------------------------------------

	var new_position := (
		_parse_transfer_grid_position(
			data.get(
				"new_grid_position",
				null
			),
			target_container
		)
	)


	if new_position == Vector2i(
		-1,
		-1
	):
		reject_authenticated_peer(
			peer_id,
			"Posición destino de transferencia inválida."
		)


		return


	# -----------------------------------------------------
	# ENTREGAR INTENCIÓN A SERVER MAIN
	# -----------------------------------------------------

	client_item_container_transfer_requested.emit(
		peer_id,
		request_id,
		uid,
		source_container,
		target_container,
		current_position,
		new_position
	)


# =========================================================
# CONTENEDOR DE TRANSFERENCIA SOPORTADO
# =========================================================

func _is_transfer_container(
	container: String
) -> bool:
	return (
		container == "inventory"
		or
		container == "vault"
	)


# =========================================================
# PARSEAR POSICIÓN SEGÚN CONTENEDOR
# =========================================================

func _parse_transfer_grid_position(
	value: Variant,
	container: String
) -> Vector2i:
	match container:
		"inventory":
			return _parse_inventory_grid_position(
				value
			)

		"vault":
			return _parse_vault_grid_position(
				value
			)


	return Vector2i(
		-1,
		-1
	)

# =========================================================
# EQUIPMENT — EQUIP REQUEST
# =========================================================

func _process_equipment_equip_request(
	peer_id: int,
	message: Dictionary
) -> void:
	if not authenticated_sessions.has(
		peer_id
	):
		return


	var data_value: Variant = (
		message.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
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
		return


	var uid := String(
		data.get(
			"uid",
			""
		)
	).strip_edges()


	if uid.is_empty():
		return


	var slot_id := String(
		data.get(
			"equipment_slot",
			""
		)
	).strip_edges().to_lower()


	if (
		slot_id.is_empty()
		or
		slot_id.length() > 32
	):
		return


	var position_value: Variant = (
		data.get(
			"current_grid_position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		return


	var position: Dictionary = (
		position_value
	)


	var current_position := Vector2i(
		int(
			position.get(
				"x",
				-1
			)
		),
		int(
			position.get(
				"y",
				-1
			)
		)
	)


	if not _is_inventory_grid_position_valid(
		current_position
	):
		return


	client_equipment_equip_requested.emit(
		peer_id,
		request_id,
		uid,
		current_position,
		slot_id
	)

# =========================================================
# EQUIPMENT — UNEQUIP REQUEST
# =========================================================

func _process_equipment_unequip_request(
	peer_id: int,
	message: Dictionary
) -> void:
	if not authenticated_sessions.has(
		peer_id
	):
		return


	var data_value: Variant = (
		message.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
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
		return


	var uid := String(
		data.get(
			"uid",
			""
		)
	).strip_edges()


	if uid.is_empty():
		return


	var slot_id := String(
		data.get(
			"current_equipment_slot",
			""
		)
	).strip_edges().to_lower()


	if (
		slot_id.is_empty()
		or
		slot_id.length() > 32
	):
		return


	var position_value: Variant = (
		data.get(
			"new_grid_position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		return


	var position: Dictionary = (
		position_value
	)


	var new_position := Vector2i(
		int(
			position.get(
				"x",
				-1
			)
		),
		int(
			position.get(
				"y",
				-1
			)
		)
	)


	if not _is_inventory_grid_position_valid(
		new_position
	):
		return


	client_equipment_unequip_requested.emit(
		peer_id,
		request_id,
		uid,
		slot_id,
		new_position
	)

func _is_inventory_grid_position_valid(
	position: Vector2i
) -> bool:
	return (
		position.x >= 0
		and
		position.x < 8
		and
		position.y >= 0
		and
		position.y < 8
	)


# =========================================================
# BASIC ATTACK REQUEST
# =========================================================

func _process_basic_attack_request(
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
			"Basic Attack sin datos válidos."
		)


		return


	var data: Dictionary = data_value


	var request_id := int(
		data.get(
			"request_id",
			0
		)
	)


	if request_id <= 0:
		reject_authenticated_peer(
			peer_id,
			"Basic Attack sin Request ID válido."
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
			"Basic Attack sin target válido."
		)


		return


	var target: Dictionary = target_value


	var target_kind := String(
		target.get(
			"kind",
			""
		)
	).strip_edges().to_lower()


	if target_kind != "entity":
		reject_authenticated_peer(
			peer_id,
			"Basic Attack con tipo de target inválido."
		)


		return


	var entity_id_value: Variant = (
		target.get(
			"entity_id",
			null
		)
	)


	if typeof(entity_id_value) != TYPE_STRING:
		reject_authenticated_peer(
			peer_id,
			"Basic Attack sin Entity ID válido."
		)


		return


	var entity_id := String(
		entity_id_value
	).strip_edges().to_lower()


	if (
		entity_id.is_empty()
		or
		entity_id.length() > 96
	):
		reject_authenticated_peer(
			peer_id,
			"Basic Attack con Entity ID inválido."
		)


		return


	client_basic_attack_requested.emit(
		peer_id,
		request_id,
		{
			"kind": "entity",

			"entity_id": entity_id,
		}
	)

func send_basic_attack_result(
	peer_id: int,
	request_id: int,
	accepted: bool,
	reason: String,
	target: Dictionary,
	attack_profile: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if request_id <= 0:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	var normalized_reason := (
		reason.strip_edges()
	)


	if normalized_reason.is_empty():
		return ERR_INVALID_PARAMETER


	if (
		target.is_empty()
		or
		attack_profile.is_empty()
	):
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_BASIC_ATTACK_RESULT,

		"data": {
			"request_id": request_id,

			"accepted": accepted,

			"reason": normalized_reason,

			"target": target.duplicate(true),

			"attack_profile": (
				attack_profile.duplicate(true)
			),
		},
	}


	return scene_multiplayer.send_bytes(
		JSON.stringify(
			message
		).to_utf8_buffer(),
		peer_id,
		MultiplayerPeer.TRANSFER_MODE_RELIABLE,
		0
	)

# =========================================================
# ENVIAR ESTADO ACTUALIZADO DE MOB
# =========================================================

func send_mob_state_updated(
	peer_id: int,
	mob_snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if mob_snapshot.is_empty():
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_MOB_STATE_UPDATED,

		"data": {
			"mob": mob_snapshot.duplicate(
				true
			),
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
# ENVIAR NUEVO WORLD DROP
# =========================================================

func send_world_drop_spawned(
	peer_id: int,
	drop_snapshot: Dictionary
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if drop_snapshot.is_empty():
		return ERR_INVALID_DATA


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": MESSAGE_WORLD_DROP_SPAWNED,

		"data": {
			"drop": drop_snapshot.duplicate(
				true
			),
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
# ENVIAR PROGRESIÓN AUTORITATIVA
# =========================================================

func send_character_progression_updated(
	peer_id: int,
	character_id: int,
	level: int,
	experience: int,
	experience_required: int,
	experience_gained: int,
	levels_gained: int
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if not authenticated_sessions.has(
		peer_id
	):
		return ERR_DOES_NOT_EXIST


	if character_id <= 0:
		return ERR_INVALID_PARAMETER


	if level <= 0:
		return ERR_INVALID_PARAMETER


	if experience < 0:
		return ERR_INVALID_PARAMETER


	if experience_required <= 0:
		return ERR_INVALID_PARAMETER


	if experience >= experience_required:
		return ERR_INVALID_PARAMETER


	if experience_gained <= 0:
		return ERR_INVALID_PARAMETER


	if levels_gained < 0:
		return ERR_INVALID_PARAMETER


	var scene_multiplayer := (
		multiplayer
		as SceneMultiplayer
	)


	if scene_multiplayer == null:
		return ERR_UNAVAILABLE


	var message := {
		"version": NETWORK_PROTOCOL_VERSION,

		"type": (
			MESSAGE_CHARACTER_PROGRESSION_UPDATED
		),

		"data": {
			"character_id": character_id,

			"level": level,

			"experience": experience,

			"experience_required": (
				experience_required
			),

			"experience_gained": (
				experience_gained
			),

			"levels_gained": levels_gained,
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
