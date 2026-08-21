class_name CharacterItemStateCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var inventory_repository: BackendCharacterInventoryRepository = null

var equipment_repository: BackendCharacterEquipmentRepository = null


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
	p_inventory_repository: BackendCharacterInventoryRepository,
	p_equipment_repository: BackendCharacterEquipmentRepository
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_inventory_repository == null:
		return false


	if p_equipment_repository == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	inventory_repository = p_inventory_repository

	equipment_repository = p_equipment_repository


	_bind_repository_signals()


	configured = true


	print(
		"CharacterItemStateCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND REPOSITORIES
# =========================================================

func _bind_repository_signals() -> void:
	if not inventory_repository.inventory_loaded.is_connected(
		_on_inventory_loaded
	):
		inventory_repository.inventory_loaded.connect(
			_on_inventory_loaded
		)


	if not inventory_repository.inventory_load_failed.is_connected(
		_on_inventory_load_failed
	):
		inventory_repository.inventory_load_failed.connect(
			_on_inventory_load_failed
		)


	if not equipment_repository.equipment_loaded.is_connected(
		_on_equipment_loaded
	):
		equipment_repository.equipment_loaded.connect(
			_on_equipment_loaded
		)


	if not equipment_repository.equipment_load_failed.is_connected(
		_on_equipment_load_failed
	):
		equipment_repository.equipment_load_failed.connect(
			_on_equipment_load_failed
		)


# =========================================================
# CARGA INICIAL INVENTORY + EQUIPMENT
# =========================================================

func load_initial_snapshots(
	peer_id: int
) -> Error:
	if not configured:
		return ERR_UNAVAILABLE


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var inventory_result := (
		inventory_repository.load_inventory(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	if inventory_result != OK:
		push_error(
			(
				"CharacterItemStateCoordinator | "
				+
				"No se pudo iniciar la carga "
				+
				"del Inventory persistente."
				+
				" Error: %d"
			)
			%
			inventory_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo cargar el inventario "
				+
				"persistente."
			)
		)


		return inventory_result


	var equipment_result := (
		equipment_repository.load_equipment(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	if equipment_result != OK:
		push_error(
			(
				"CharacterItemStateCoordinator | "
				+
				"No se pudo iniciar la carga "
				+
				"del Equipment persistente."
				+
				" Error: %d"
			)
			%
			equipment_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo cargar el Equipment "
				+
				"persistente."
			)
		)


		return equipment_result


	return OK


# =========================================================
# RELOAD AUTORITATIVO INVENTORY + EQUIPMENT
# =========================================================

func reload_snapshots(
	peer_id: int,
	reason: String
) -> void:
	if not configured:
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var inventory_result := (
		inventory_repository.load_inventory(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	var equipment_result := (
		equipment_repository.load_equipment(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	if (
		inventory_result == OK
		and
		equipment_result == OK
	):
		return


	push_error(
		(
			"CharacterItemStateCoordinator | "
			+
			"No se pudo recargar estado "
			+
			"Inventory/Equipment"
			+
			" | Peer: %d"
			+
			" | Reason: %s"
			+
			" | Inventory error: %d"
			+
			" | Equipment error: %d"
		)
		%
		[
			peer_id,
			reason,
			inventory_result,
			equipment_result,
		]
	)


	# -----------------------------------------------------
	# Después de una mutación persistente ya no podemos
	# continuar con snapshots potencialmente stale.
	# -----------------------------------------------------

	game_server.reject_authenticated_peer(
		peer_id,
		(
			"No se pudo resincronizar "
			+
			"el estado persistente del personaje."
		)
	)


# =========================================================
# REENVIAR INVENTORY + EQUIPMENT ACTUALES
# =========================================================

func resend_snapshots(
	peer_id: int
) -> void:
	if not configured:
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if not inventory_snapshot.is_empty():
		var inventory_result := (
			game_server.send_character_inventory_snapshot(
				peer_id,
				inventory_snapshot
			)
		)


		if inventory_result != OK:
			push_warning(
				(
					"CharacterItemStateCoordinator | "
					+
					"No se pudo reenviar "
					+
					"Inventory. Error: %d"
				)
				%
				inventory_result
			)


	if not equipment_snapshot.is_empty():
		var equipment_result := (
			game_server.send_character_equipment_snapshot(
				peer_id,
				equipment_snapshot
			)
		)


		if equipment_result != OK:
			push_warning(
				(
					"CharacterItemStateCoordinator | "
					+
					"No se pudo reenviar "
					+
					"Equipment. Error: %d"
				)
				%
				equipment_result
			)


# =========================================================
# INVENTORY CARGADO
# =========================================================

func _on_inventory_loaded(
	peer_id: int,
	account_id: int,
	character_id: int,
	snapshot: Dictionary
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	var validation_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			snapshot
		)
	)


	if not validation_error.is_empty():
		print(
			"CharacterItemStateCoordinator | "
			+
			"Inventory persistente rechazado",
			" | Peer: ",
			peer_id,
			" | Cuenta: ",
			account_id,
			" | Personaje: ",
			character_id,
			" | Motivo: ",
			validation_error
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"Inventory persistente inválido."
		)


		return


	if not session.set_inventory_snapshot(
		snapshot
	):
		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo registrar el "
				+
				"Inventory persistente."
			)
		)


		return


	var send_result := (
		game_server.send_character_inventory_snapshot(
			peer_id,
			snapshot
		)
	)


	if send_result != OK:
		push_error(
			(
				"CharacterItemStateCoordinator | "
				+
				"No se pudo enviar "
				+
				"Inventory persistente al cliente."
				+
				" Error: %d"
			)
			%
			send_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo sincronizar el "
				+
				"Inventory persistente."
			)
		)


		return


	var items: Array = (
		snapshot.get(
			"items",
			[]
		)
	)


	print(
		"CharacterItemStateCoordinator | Snapshot de Inventory enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Items: ",
		items.size()
	)


	print(
		"CharacterItemStateCoordinator | Inventory persistente cargado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		session.character_name,
		" | Character ID: ",
		character_id,
		" | Items: ",
		items.size()
	)


# =========================================================
# INVENTORY LOAD FAILED
# =========================================================

func _on_inventory_load_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	message: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	print(
		"CharacterItemStateCoordinator | "
		+
		"Error cargando Inventory persistente",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Motivo: ",
		message
	)


	game_server.reject_authenticated_peer(
		peer_id,
		(
			"No se pudo cargar el inventario "
			+
			"persistente."
		)
	)


# =========================================================
# EQUIPMENT CARGADO
# =========================================================

func _on_equipment_loaded(
	peer_id: int,
	account_id: int,
	character_id: int,
	snapshot: Dictionary
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	var validation_error := (
		ServerEquipmentSnapshotValidator.validate(
			snapshot
		)
	)


	if not validation_error.is_empty():
		print(
			"CharacterItemStateCoordinator | "
			+
			"Equipment persistente rechazado",
			" | Peer: ",
			peer_id,
			" | Cuenta: ",
			account_id,
			" | Personaje: ",
			character_id,
			" | Motivo: ",
			validation_error
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"Equipment persistente inválido."
		)


		return


	if not session.set_equipment_snapshot(
		snapshot
	):
		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo registrar el "
				+
				"Equipment persistente."
			)
		)


		return


	var send_result := (
		game_server.send_character_equipment_snapshot(
			peer_id,
			snapshot
		)
	)


	if send_result != OK:
		push_error(
			(
				"CharacterItemStateCoordinator | "
				+
				"No se pudo enviar "
				+
				"Equipment persistente al cliente."
				+
				" Error: %d"
			)
			%
			send_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo sincronizar el "
				+
				"Equipment persistente."
			)
		)


		return


	var items: Array = (
		snapshot.get(
			"items",
			[]
		)
	)


	print(
		"CharacterItemStateCoordinator | Snapshot de Equipment enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Items: ",
		items.size()
	)


	print(
		"CharacterItemStateCoordinator | Equipment persistente cargado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		session.character_name,
		" | Character ID: ",
		character_id,
		" | Items: ",
		items.size()
	)


# =========================================================
# EQUIPMENT LOAD FAILED
# =========================================================

func _on_equipment_load_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	message: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	if session.character_id != character_id:
		return


	print(
		"CharacterItemStateCoordinator | "
		+
		"Error cargando Equipment persistente",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Motivo: ",
		message
	)


	game_server.reject_authenticated_peer(
		peer_id,
		(
			"No se pudo cargar el Equipment "
			+
			"persistente."
		)
	)
