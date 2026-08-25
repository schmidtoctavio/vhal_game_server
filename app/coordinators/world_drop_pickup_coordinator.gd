class_name WorldDropPickupCoordinator
extends Node


const PICKUP_RANGE: float = 2.0


var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_drop_registry: WorldDropRegistry = null

var inventory_repository: BackendCharacterInventoryRepository = null


var pending_by_uid: Dictionary = {}

var locked_drop_entities: Dictionary = {}

var configured: bool = false


func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_drop_registry: WorldDropRegistry,
	p_inventory_repository: BackendCharacterInventoryRepository
) -> bool:
	if configured:
		return true


	if (
		p_game_server == null
		or
		p_world_session_registry == null
		or
		p_world_drop_registry == null
		or
		p_inventory_repository == null
	):
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	world_drop_registry = (
		p_world_drop_registry
	)

	inventory_repository = (
		p_inventory_repository
	)


	game_server.client_world_drop_pickup_requested.connect(
		_on_pickup_requested
	)


	inventory_repository.inventory_item_granted.connect(
		_on_inventory_item_granted
	)


	inventory_repository.inventory_item_grant_failed.connect(
		_on_inventory_item_grant_failed
	)


	configured = true


	print(
		"WorldDropPickupCoordinator | Inicializado."
	)


	return true


func _on_pickup_requested(
	peer_id: int,
	request_id: int,
	entity_id: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if not session.accept_world_drop_pickup_request_id(
		request_id
	):
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"stale_request"
		)


		return


	var drop := (
		world_drop_registry.get_drop(
			entity_id
		)
	)


	if drop == null:
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"drop_not_found"
		)


		return


	if locked_drop_entities.has(
		drop.entity_id
	):
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"drop_busy"
		)


		return


	if drop.map_id != session.map_id:
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"wrong_map"
		)


		return


	var player_xz := Vector2(
		session.position.x,
		session.position.z
	)


	var drop_xz := Vector2(
		drop.position.x,
		drop.position.z
	)


	var distance := player_xz.distance_to(
		drop_xz
	)


	if distance > PICKUP_RANGE:
		print(
			"WorldDropPickupCoordinator | Pickup fuera de rango",
			" | Request: ",
			request_id,
			" | Entity: ",
			entity_id,
			" | Distancia: ",
			distance,
			" | Rango: ",
			PICKUP_RANGE
		)


		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"out_of_range"
		)


		return


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"inventory_unavailable"
		)


		return


	var grid_position := (
		ServerInventoryPlacementResolver.find_first_available(
			inventory_snapshot,
			drop.persistent_item_uid,
			drop.item_id,
			drop.quantity
		)
	)


	if (
		grid_position
		==
		ServerInventoryPlacementResolver.INVALID_POSITION
	):
		_send_result(
			peer_id,
			request_id,
			entity_id,
			false,
			"inventory_full"
		)


		return


	locked_drop_entities[
		drop.entity_id
	] = drop.persistent_item_uid


	pending_by_uid[
		drop.persistent_item_uid
	] = {
		"peer_id": peer_id,

		"request_id": request_id,

		"entity_id": drop.entity_id,

		"account_id": session.account_id,

		"character_id": session.character_id,

		"grid_position": grid_position,
	}


	var persist_result := (
		inventory_repository.grant_inventory_item(
			peer_id,
			session.account_id,
			session.character_id,
			drop.persistent_item_uid,
			drop.item_id,
			drop.quantity,
			grid_position
		)
	)


	if persist_result == OK:
		print(
			"WorldDropPickupCoordinator | Pickup persistente iniciado",
			" | Request: ",
			request_id,
			" | Entity: ",
			drop.entity_id,
			" | Item: ",
			drop.item_id,
			" | Posición Inventory: ",
			grid_position
		)


		return


	_release_pending(
		drop.persistent_item_uid
	)


	var reason := (
		"inventory_busy"
		if persist_result == ERR_BUSY
		else
		"persistence_unavailable"
	)


	_send_result(
		peer_id,
		request_id,
		entity_id,
		false,
		reason
	)


func _on_inventory_item_granted(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary,
	idempotent: bool
) -> void:
	if not pending_by_uid.has(
		uid
	):
		return


	var pending: Dictionary = (
		pending_by_uid[
			uid
		]
	)


	if (
		int(pending.get("peer_id", -1))
		!=
		peer_id
		or
		int(pending.get("account_id", -1))
		!=
		account_id
		or
		int(pending.get("character_id", -1))
		!=
		character_id
	):
		return


	var entity_id := String(
		pending.get(
			"entity_id",
			""
		)
	)


	var request_id := int(
		pending.get(
			"request_id",
			0
		)
	)


	# -----------------------------------------------------
	# LARAVEL YA CONFIRMÓ EL ITEM.
	# Recién ahora retiramos el WorldDrop.
	# -----------------------------------------------------

	var consumed_drop := (
		world_drop_registry.consume_drop(
			entity_id
		)
	)


	_release_pending(
		uid
	)


	if consumed_drop == null:
		push_error(
			(
				"WorldDropPickupCoordinator | "
				+
				"El item fue persistido pero el drop ya no existía: %s"
			)
			%
			entity_id
		)


	# El item YA existe persistentemente.
	# Por lo tanto el pickup se considera aceptado.
	_send_result(
		peer_id,
		request_id,
		entity_id,
		true,
		"ok"
	)


	print(
		"WorldDropPickupCoordinator | Pickup confirmado",
		" | Request: ",
		request_id,
		" | Entity: ",
		entity_id,
		" | UID: ",
		uid,
		" | Item: ",
		item.get(
			"item_id",
			""
		),
		" | Idempotent: ",
		idempotent
	)


	# -----------------------------------------------------
	# Laravel sigue siendo source of truth.
	# Recargamos todo el Inventory.
	# -----------------------------------------------------

	var reload_result := (
		inventory_repository.load_inventory(
			peer_id,
			account_id,
			character_id
		)
	)


	if reload_result != OK:
		game_server.reject_authenticated_peer(
			peer_id,
			(
				"El pickup fue persistido pero no se pudo "
				+
				"resincronizar el Inventory."
			)
		)


func _on_inventory_item_grant_failed(
	peer_id: int,
	_account_id: int,
	_character_id: int,
	uid: String,
	response_code: int,
	message: String
) -> void:
	if not pending_by_uid.has(
		uid
	):
		return


	var pending: Dictionary = (
		pending_by_uid[
			uid
		]
	)


	var entity_id := String(
		pending.get(
			"entity_id",
			""
		)
	)


	var request_id := int(
		pending.get(
			"request_id",
			0
		)
	)


	_release_pending(
		uid
	)


	print(
		"WorldDropPickupCoordinator | Persistencia rechazada",
		" | Request: ",
		request_id,
		" | Entity: ",
		entity_id,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	_send_result(
		peer_id,
		request_id,
		entity_id,
		false,
		"persistence_rejected"
	)


func _release_pending(
	uid: String
) -> void:
	if not pending_by_uid.has(
		uid
	):
		return


	var pending: Dictionary = (
		pending_by_uid[
			uid
		]
	)


	var entity_id := String(
		pending.get(
			"entity_id",
			""
		)
	)


	pending_by_uid.erase(
		uid
	)


	if not entity_id.is_empty():
		locked_drop_entities.erase(
			entity_id
		)


func _send_result(
	peer_id: int,
	request_id: int,
	entity_id: String,
	accepted: bool,
	reason: String
) -> void:
	var result := (
		game_server.send_world_drop_pickup_result(
			peer_id,
			request_id,
			entity_id,
			accepted,
			reason
		)
	)


	if result != OK:
		push_warning(
			(
				"WorldDropPickupCoordinator | "
				+
				"No se pudo enviar pickup result. Error: %d"
			)
			%
			result
		)
