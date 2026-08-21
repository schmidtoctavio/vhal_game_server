extends Node


# =========================================================
# REFERENCIAS
# =========================================================

@onready var game_server: GameServer = (
	$GameServer
)

@onready var backend_ticket_validator: BackendTicketValidator = (
	$BackendTicketValidator
)

@onready var backend_vault_repository: BackendVaultRepository = (
	$BackendVaultRepository
)

@onready var backend_character_inventory_repository: BackendCharacterInventoryRepository = (
	$BackendCharacterInventoryRepository
)

@onready var backend_character_equipment_repository: BackendCharacterEquipmentRepository = (
	$BackendCharacterEquipmentRepository
)

@onready var backend_item_transfer_repository: BackendItemTransferRepository = (
	$BackendItemTransferRepository
)

@onready var world_session_registry: WorldSessionRegistry = (
	$WorldSessionRegistry
)

@onready var world_navigation_registry: WorldNavigationRegistry = (
	$WorldNavigationRegistry
)

@onready var world_movement_system: WorldMovementSystem = (
	$WorldMovementSystem
)

@onready var world_npc_registry: WorldNpcRegistry = (
	$WorldNpcRegistry
)

# =========================================================
# START
# =========================================================

func _ready() -> void:
	if game_server == null:
		push_error(
			"ServerMain | No existe GameServer."
		)

		get_tree().quit(
			1
		)

		return


	if backend_ticket_validator == null:
		push_error(
			"ServerMain | No existe BackendTicketValidator."
		)

		get_tree().quit(
			2
		)

		return


	if not backend_ticket_validator.is_configured():
		push_error(
			"ServerMain | BackendTicketValidator no configurado."
		)

		get_tree().quit(
			3
		)

		return

	if backend_vault_repository == null:
		push_error(
			"ServerMain | No existe BackendVaultRepository."
		)


		get_tree().quit(
			8
		)


		return


	if not backend_vault_repository.is_configured():
		push_error(
			"ServerMain | BackendVaultRepository no configurado."
		)


		get_tree().quit(
			8
		)


		return

	if backend_character_inventory_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterInventoryRepository."
			)
		)


		get_tree().quit(
			9
		)


		return


	if not backend_character_inventory_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterInventoryRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			9
		)


		return

	if backend_character_equipment_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterEquipmentRepository."
			)
		)


		get_tree().quit(
			11
		)


		return


	if not backend_character_equipment_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterEquipmentRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			11
		)


		return


	var equipment_contract_error := (
		ServerEquipmentRules.validate_contract()
	)


	if not equipment_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Domain Contract inválido: "
				+
				equipment_contract_error
			)
		)
		get_tree().quit(
			12
		)
		return

	var equipment_transfer_contract_error := (
		ServerEquipmentTransferValidator.validate_contract()
	)


	if not equipment_transfer_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Transfer Contract inválido: "
				+
				equipment_transfer_contract_error
			)
		)


		get_tree().quit(
			13
		)


		return


	print(
		"ServerMain | Equipment Transfer Contract validado."
	)

	print(
		"ServerMain | Equipment Domain Contract validado."
	)

	if backend_item_transfer_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendItemTransferRepository."
			)
		)


		get_tree().quit(
			10
		)


		return


	if not backend_item_transfer_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendItemTransferRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			10
		)


		return

	if world_session_registry == null:
		push_error(
			"ServerMain | No existe WorldSessionRegistry."
		)

		get_tree().quit(
			4
		)

		return


	if world_navigation_registry == null:
		push_error(
			"ServerMain | No existe WorldNavigationRegistry."
		)

		get_tree().quit(
			5
		)

		return


	var navigation_result: Error = (
		await world_navigation_registry.initialize()
	)


	if navigation_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"la navegación. Error: %d"
			)
			%
			navigation_result
		)

		get_tree().quit(
			5
		)

		return


	if world_movement_system == null:
		push_error(
			"ServerMain | No existe WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return


	if not world_movement_system.setup(
		world_session_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return

	if world_npc_registry == null:
		push_error(
			"ServerMain | No existe WorldNpcRegistry."
		)

		get_tree().quit(
			7
		)

		return


	var npc_registry_result := (
		world_npc_registry.initialize()
	)


	if npc_registry_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"WorldNpcRegistry. Error: %d"
			)
			%
			npc_registry_result
		)

		get_tree().quit(
			7
		)

		return

	_bind_authentication()


	var result := (
		game_server.start()
	)


	if result != OK:
		push_error(
			"ServerMain | No se pudo iniciar el servidor."
		)

		get_tree().quit(
			result
		)

		return


	print(
		"ServerMain | VHAL Game Server iniciado."
	)


# =========================================================
# BIND AUTHENTICATION
# =========================================================

func _bind_authentication() -> void:
	if not game_server.client_authentication_requested.is_connected(
		_on_client_authentication_requested
	):
		game_server.client_authentication_requested.connect(
			_on_client_authentication_requested
		)


	if not backend_ticket_validator.ticket_validated.is_connected(
		_on_ticket_validated
	):
		backend_ticket_validator.ticket_validated.connect(
			_on_ticket_validated
		)


	if not backend_ticket_validator.ticket_rejected.is_connected(
		_on_ticket_rejected
	):
		backend_ticket_validator.ticket_rejected.connect(
			_on_ticket_rejected
		)

	if not backend_vault_repository.vault_loaded.is_connected(
		_on_backend_vault_loaded
	):
		backend_vault_repository.vault_loaded.connect(
			_on_backend_vault_loaded
		)


	if not backend_vault_repository.vault_load_failed.is_connected(
		_on_backend_vault_load_failed
	):
		backend_vault_repository.vault_load_failed.connect(
			_on_backend_vault_load_failed
		)

	if not backend_vault_repository.vault_item_moved.is_connected(
		_on_backend_vault_item_moved
	):
		backend_vault_repository.vault_item_moved.connect(
			_on_backend_vault_item_moved
		)


	if not backend_vault_repository.vault_item_move_failed.is_connected(
		_on_backend_vault_item_move_failed
	):
		backend_vault_repository.vault_item_move_failed.connect(
			_on_backend_vault_item_move_failed
		)

	if not backend_character_inventory_repository.inventory_loaded.is_connected(
		_on_backend_character_inventory_loaded
	):
		backend_character_inventory_repository.inventory_loaded.connect(
			_on_backend_character_inventory_loaded
		)


	if not backend_character_inventory_repository.inventory_load_failed.is_connected(
		_on_backend_character_inventory_load_failed
	):
		backend_character_inventory_repository.inventory_load_failed.connect(
			_on_backend_character_inventory_load_failed
		)

	if not backend_character_inventory_repository.inventory_item_moved.is_connected(
		_on_backend_character_inventory_item_moved
	):
		backend_character_inventory_repository.inventory_item_moved.connect(
			_on_backend_character_inventory_item_moved
		)


	if not backend_character_inventory_repository.inventory_item_move_failed.is_connected(
		_on_backend_character_inventory_item_move_failed
	):
		backend_character_inventory_repository.inventory_item_move_failed.connect(
			_on_backend_character_inventory_item_move_failed
		)

	if not backend_character_equipment_repository.equipment_loaded.is_connected(
		_on_backend_character_equipment_loaded
	):
		backend_character_equipment_repository.equipment_loaded.connect(
			_on_backend_character_equipment_loaded
		)


	if not backend_character_equipment_repository.equipment_load_failed.is_connected(
		_on_backend_character_equipment_load_failed
	):
		backend_character_equipment_repository.equipment_load_failed.connect(
			_on_backend_character_equipment_load_failed
		)

	if not backend_character_equipment_repository.equipment_item_equipped.is_connected(
		_on_backend_equipment_item_equipped
	):
		backend_character_equipment_repository.equipment_item_equipped.connect(
			_on_backend_equipment_item_equipped
		)


	if not backend_character_equipment_repository.equipment_item_equip_failed.is_connected(
		_on_backend_equipment_item_equip_failed
	):
		backend_character_equipment_repository.equipment_item_equip_failed.connect(
			_on_backend_equipment_item_equip_failed
		)


	if not backend_character_equipment_repository.equipment_item_unequipped.is_connected(
		_on_backend_equipment_item_unequipped
	):
		backend_character_equipment_repository.equipment_item_unequipped.connect(
			_on_backend_equipment_item_unequipped
		)


	if not backend_character_equipment_repository.equipment_item_unequip_failed.is_connected(
		_on_backend_equipment_item_unequip_failed
	):
		backend_character_equipment_repository.equipment_item_unequip_failed.connect(
			_on_backend_equipment_item_unequip_failed
		)

	if not backend_item_transfer_repository.item_transferred.is_connected(
		_on_backend_item_transferred
	):
		backend_item_transfer_repository.item_transferred.connect(
			_on_backend_item_transferred
		)


	if not backend_item_transfer_repository.item_transfer_failed.is_connected(
		_on_backend_item_transfer_failed
	):
		backend_item_transfer_repository.item_transfer_failed.connect(
			_on_backend_item_transfer_failed
		)

	if not game_server.client_authenticated.is_connected(
		_on_client_authenticated
	):
		game_server.client_authenticated.connect(
			_on_client_authenticated
		)


	if not game_server.client_disconnected.is_connected(
		_on_client_disconnected
	):
		game_server.client_disconnected.connect(
			_on_client_disconnected
		)


	if not game_server.client_move_requested.is_connected(
		_on_client_move_requested
	):
		game_server.client_move_requested.connect(
			_on_client_move_requested
		)

	if not game_server.client_npc_interaction_requested.is_connected(
		_on_client_npc_interaction_requested
	):
		game_server.client_npc_interaction_requested.connect(
			_on_client_npc_interaction_requested
		)

	if not world_movement_system.movement_completed.is_connected(
		_on_authoritative_movement_completed
	):
		world_movement_system.movement_completed.connect(
			_on_authoritative_movement_completed
		)

	if not world_movement_system.movement_state_sampled.is_connected(
		_on_authoritative_movement_state_sampled
	):
		world_movement_system.movement_state_sampled.connect(
			_on_authoritative_movement_state_sampled
		)

	if not game_server.client_npc_service_end_requested.is_connected(
		_on_client_npc_service_end_requested
	):
		game_server.client_npc_service_end_requested.connect(
			_on_client_npc_service_end_requested
		)

	if not game_server.client_vault_item_move_requested.is_connected(
		_on_client_vault_item_move_requested
	):
		game_server.client_vault_item_move_requested.connect(
			_on_client_vault_item_move_requested
		)

	if not game_server.client_inventory_item_move_requested.is_connected(
		_on_client_inventory_item_move_requested
	):
		game_server.client_inventory_item_move_requested.connect(
			_on_client_inventory_item_move_requested
		)

	if not game_server.client_item_container_transfer_requested.is_connected(
		_on_client_item_container_transfer_requested
	):
		game_server.client_item_container_transfer_requested.connect(
			_on_client_item_container_transfer_requested
		)

	if not game_server.client_equipment_equip_requested.is_connected(
		_on_client_equipment_equip_requested
	):
		game_server.client_equipment_equip_requested.connect(
			_on_client_equipment_equip_requested
		)


	if not game_server.client_equipment_unequip_requested.is_connected(
		_on_client_equipment_unequip_requested
	):
		game_server.client_equipment_unequip_requested.connect(
			_on_client_equipment_unequip_requested
		)

# =========================================================
# AUTH REQUEST
# =========================================================

func _on_client_authentication_requested(
	peer_id: int,
	ticket: String
) -> void:
	backend_ticket_validator.validate_ticket(
		peer_id,
		ticket
	)


# =========================================================
# TICKET VALIDADO
# =========================================================

func _on_ticket_validated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> void:
	print(
		"ServerMain | Identidad validada | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		character_data.get(
			"name",
			"?"
		)
	)


	game_server.accept_authentication(
		peer_id,
		account_id,
		character_data
	)


# =========================================================
# TICKET RECHAZADO
# =========================================================

func _on_ticket_rejected(
	peer_id: int,
	message: String
) -> void:
	game_server.reject_authentication(
		peer_id,
		message
	)


# =========================================================
# PEER AUTENTICADO
# =========================================================

func _on_client_authenticated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
) -> void:
	var session := (
		world_session_registry.create_session(
			peer_id,
			account_id,
			character_data
		)
	)


	if session == null:
		push_error(
			(
				"ServerMain | No se pudo crear la sesión "
				+
				"de mundo para el peer %d."
			)
			%
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo crear la sesión de mundo."
		)


		return


	var snapshot_result := (
		game_server.send_world_snapshot(
			peer_id,
			session.to_snapshot()
		)
	)


	if snapshot_result != OK:
		push_error(
			(
				"ServerMain | No se pudo enviar el snapshot "
				+
				"de mundo al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				snapshot_result,
			]
		)


		world_session_registry.remove_session(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo iniciar la sesión de mundo."
		)


		return

	# -----------------------------------------------------
	# JUGADORES QUE YA ESTÁN EN EL MISMO MAPA
	# -----------------------------------------------------

	var existing_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			peer_id
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
	# ENVIAR ROSTER INICIAL AL NUEVO PLAYER
	# -----------------------------------------------------

	var presence_result := (
		game_server.send_world_presence_snapshot(
			peer_id,
			existing_players
		)
	)


	if presence_result != OK:
		push_error(
			(
				"ServerMain | No se pudo enviar el roster "
				+
				"de mundo al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				presence_result,
			]
		)


		world_session_registry.remove_session(
			peer_id
		)


		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo preparar la presencia del mundo."
		)


		return


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
					"ServerMain | No se pudo avisar al peer "
					+
					"%d sobre la entrada del peer %d. Error: %d"
				)
				%
				[
					existing_session.peer_id,
					peer_id,
					notify_result,
				]
			)

	print(
		"ServerMain | Snapshot de mundo enviado | Peer: ",
		peer_id
	)

	print(
		"ServerMain | Presencia de mundo preparada",
		" | Peer: ",
		peer_id,
		" | Remotos existentes: ",
		existing_players.size()
	)

	print(
		"ServerMain | Mundo autoritativo preparado | Peer: ",
		peer_id,
		" | Mapa: ",
		session.map_id,
		" | Posición: ",
		session.position
	)

	var inventory_load_result := (
		backend_character_inventory_repository.load_inventory(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	if inventory_load_result != OK:
		push_error(
			(
				"ServerMain | No se pudo iniciar "
				+
				"la carga del Inventory persistente."
				+
				" Error: %d"
			)
			%
			inventory_load_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo cargar el inventario "
				+
				"persistente."
			)
		)


		return


	var equipment_load_result := (
		backend_character_equipment_repository.load_equipment(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	if equipment_load_result != OK:
		push_error(
			(
				"ServerMain | No se pudo iniciar "
				+
				"la carga del Equipment persistente."
				+
				" Error: %d"
			)
			%
			equipment_load_result
		)


		game_server.reject_authenticated_peer(
			peer_id,
			(
				"No se pudo cargar el Equipment "
				+
				"persistente."
			)
		)


		return

# =========================================================
# PEER DESCONECTADO
# =========================================================

func _on_client_disconnected(
	peer_id: int
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var remaining_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			peer_id
		)
	)


	for remaining_session: PlayerWorldSession in remaining_sessions:
		if remaining_session == null:
			continue


		var result := (
			game_server.send_player_presence_left(
				remaining_session.peer_id,
				peer_id
			)
		)


		if result != OK:
			push_warning(
				(
					"ServerMain | No se pudo avisar al peer "
					+
					"%d sobre la salida del peer %d. Error: %d"
				)
				%
				[
					remaining_session.peer_id,
					peer_id,
					result,
				]
			)


	world_session_registry.remove_session(
		peer_id
	)


	print(
		"ServerMain | Presencia eliminada",
		" | Peer: ",
		peer_id
	)


# =========================================================
# RECHAZAR MOVIMIENTO
# =========================================================

func _reject_client_move(
	peer_id: int,
	request_id: int,
	session: PlayerWorldSession,
	target: Vector3,
	reason: String
) -> void:
	if session == null:
		return


	session.reject_move_request()


	var result := (
		game_server.send_movement_decision(
			peer_id,
			request_id,
			false,
			session.position,
			session.rotation_y,
			Vector3.ZERO,
			reason
		)
	)


	if result != OK:
		push_warning(
			(
				"ServerMain | No se pudo informar "
				+
				"el rechazo al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


	print(
		"ServerMain | Movimiento rechazado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Desde: ",
		session.position,
		" | Solicitado: ",
		target,
		" | Motivo: ",
		reason
	)


# =========================================================
# INTENCIÓN DE MOVIMIENTO
# =========================================================

func _on_client_move_requested(
	peer_id: int,
	request_id: int,
	target: Vector3
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el peer."
		)

		return

	# -----------------------------------------------------
	# REGISTRAR INTENCIÓN RAW
	# -----------------------------------------------------

	session.request_move_to(
		target
	)


	# -----------------------------------------------------
	# RESOLVER DESTINO CONTRA EL NAVMESH AUTORITATIVO
	# -----------------------------------------------------

	var resolution := (
		world_navigation_registry.resolve_reachable_target(
			session.map_id,
			session.position,
			target
		)
	)


	# -----------------------------------------------------
	# DESTINO NO RESOLVIBLE
	# -----------------------------------------------------

	if not bool(
		resolution.get(
			"ok",
			false
		)
	):
		var reason := String(
			resolution.get(
				"reason",
				"unknown"
			)
		)


		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			reason
		)


		return


	# -----------------------------------------------------
	# VALIDAR DESTINO RESUELTO
	# -----------------------------------------------------

	var resolved_value: Variant = (
		resolution.get(
			"resolved_target",
			null
		)
	)


	if typeof(resolved_value) != TYPE_VECTOR3:
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"resolved_target_invalid"
		)


		return


	var resolved_target: Vector3 = (
		resolved_value
	)


	# -----------------------------------------------------
	# VALIDAR PATH
	# -----------------------------------------------------

	var path_value: Variant = (
		resolution.get(
			"path",
			null
		)
	)


	if (
		typeof(path_value)
		!=
		TYPE_PACKED_VECTOR3_ARRAY
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_invalid"
		)


		return


	var authorized_path: PackedVector3Array = (
		path_value
	)


	if authorized_path.is_empty():
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_empty"
		)


		return


	# -----------------------------------------------------
	# CONSISTENCIA ENTRE PATH Y DESTINO RESUELTO
	# -----------------------------------------------------

	var path_final_target: Vector3 = (
		authorized_path[
			authorized_path.size() - 1
		]
	)


	if not path_final_target.is_equal_approx(
		resolved_target
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"resolved_target_mismatch"
		)


		return


	# -----------------------------------------------------
	# AUTORIZAR RUTA
	# -----------------------------------------------------

	if not session.authorize_move_path(
		authorized_path
	):
		_reject_client_move(
			peer_id,
			request_id,
			session,
			target,
			"path_authorization_failed"
		)


		return


	# -----------------------------------------------------
	# CONFIRMAR DECISIÓN AL CLIENTE
	# -----------------------------------------------------

	var decision_result := (
		game_server.send_movement_decision(
			peer_id,
			request_id,
			true,
			session.position,
			session.rotation_y,
			session.authorized_move_target
		)
	)


	if decision_result != OK:
		push_warning(
			(
				"ServerMain | No se pudo confirmar "
				+
				"el movimiento al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				decision_result,
			]
		)


	print(
		"ServerMain | Movimiento autorizado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Desde: ",
		session.position,
		" | Solicitado: ",
		target,
		" | Autorizado: ",
		session.authorized_move_target,
		" | Path points: ",
		int(
			resolution.get(
				"path_points",
				0
			)
		)
	)

# =========================================================
# REPLICAR MOVIMIENTO AL MAPA
# =========================================================

func _replicate_movement_state_to_map(
	peer_id: int,
	position: Vector3,
	rotation_y: float,
	moving: bool
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var target_peer_ids: Array[int] = [
		peer_id
	]


	var remote_sessions := (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			peer_id
		)
	)


	for remote_session: PlayerWorldSession in remote_sessions:
		if remote_session == null:
			continue


		target_peer_ids.append(
			remote_session.peer_id
		)


	var result := (
		game_server.send_movement_state_to_peers(
			peer_id,
			target_peer_ids,
			position,
			rotation_y,
			moving
		)
	)


	if result != OK:
		push_warning(
			(
				"ServerMain | No se pudo replicar "
				+
				"movimiento del peer %d al mapa. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)

# =========================================================
# MOVIMIENTO AUTORITATIVO COMPLETADO
# =========================================================

func _on_authoritative_movement_completed(
	peer_id: int,
	position: Vector3,
	rotation_y: float
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return

	_validate_active_npc_service_range(
		peer_id
	)

	# -----------------------------------------------------
	# REPLICAR ESTADO FINAL
	# -----------------------------------------------------

	_replicate_movement_state_to_map(
		peer_id,
		position,
		rotation_y,
		false
	)


	print(
		"ServerMain | Movimiento autoritativo completado",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Posición: ",
		position,
		" | Rotación Y: ",
		rotation_y
	)


# =========================================================
# REPLICACIÓN DE MOVIMIENTO
# =========================================================

func _on_authoritative_movement_state_sampled(
	peer_id: int,
	position: Vector3,
	rotation_y: float
) -> void:
	_validate_active_npc_service_range(
		peer_id
	)


	_replicate_movement_state_to_map(
		peer_id,
		position,
		rotation_y,
		true
	)

# =========================================================
# SOLICITUD DE INTERACCIÓN NPC
# =========================================================

func _on_client_npc_interaction_requested(
	peer_id: int,
	request_id: int,
	npc_id: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el peer."
		)


		return


	# -----------------------------------------------------
	# RESOLVER NPC DESDE LA FUENTE AUTORITATIVA
	# -----------------------------------------------------

	var npc_definition := (
		world_npc_registry.get_definition(
			npc_id
		)
	)


	if npc_definition == null:
		_reject_npc_interaction(
			peer_id,
			request_id,
			session,
			npc_id,
			"unknown_npc"
		)


		return


	# -----------------------------------------------------
	# VALIDAR MAPA
	# -----------------------------------------------------

	if (
		session.map_id
		!=
		npc_definition.map_id
	):
		_reject_npc_interaction(
			peer_id,
			request_id,
			session,
			npc_id,
			"wrong_map"
		)


		return


	# -----------------------------------------------------
	# DISTANCIA AUTORITATIVA X/Z
	# -----------------------------------------------------

	var player_position := Vector2(
		session.position.x,
		session.position.z
	)


	var npc_position := Vector2(
		npc_definition.position.x,
		npc_definition.position.z
	)


	var distance := (
		player_position.distance_to(
			npc_position
		)
	)


	if (
		distance
		>
		npc_definition.interaction_range
	):
		_reject_npc_interaction(
			peer_id,
			request_id,
			session,
			npc_id,
			"out_of_range",
			distance
		)


		return

	# -----------------------------------------------------
	# SESIÓN DE SERVICIO NPC
	# -----------------------------------------------------

	var started_new_service := false


	if session.has_active_npc_service():
		# -------------------------------------------------
		# MISMO SERVICIO YA ACTIVO
		#
		# La operación es idempotente:
		# no recreamos la sesión.
		# -------------------------------------------------

		if session.is_using_npc_service(
			npc_definition.npc_id,
			npc_definition.service_id
		):
			print(
				"ServerMain | Sesión de servicio NPC ya activa",
				" | Peer: ",
				peer_id,
				" | Personaje: ",
				session.character_name,
				" | NPC: ",
				session.active_npc_id,
				" | Servicio: ",
				session.active_service_id
			)

		else:
			# ---------------------------------------------
			# Existe OTRO servicio activo.
			#
			# No permitimos reemplazarlo silenciosamente.
			# ---------------------------------------------

			_reject_npc_interaction(
				peer_id,
				request_id,
				session,
				npc_id,
				"service_already_active",
				distance
			)


			return

	else:
		# -------------------------------------------------
		# CREAR NUEVA SESIÓN
		# -------------------------------------------------

		if not session.begin_npc_service(
			npc_definition.npc_id,
			npc_definition.service_id
		):
			_reject_npc_interaction(
				peer_id,
				request_id,
				session,
				npc_id,
				"service_session_failed",
				distance
			)


			return


		started_new_service = true


		print(
			"ServerMain | Sesión de servicio NPC iniciada",
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | NPC: ",
			session.active_npc_id,
			" | Servicio: ",
			session.active_service_id
		)


	# -----------------------------------------------------
	# INFORMAR AUTORIZACIÓN AL CLIENTE
	#
	# Sólo llegamos acá si:
	# - la sesión fue creada correctamente, o
	# - ya existía exactamente la misma sesión.
	# -----------------------------------------------------

	var decision_result := (
		game_server.send_npc_interaction_decision(
			peer_id,
			request_id,
			true,
			npc_definition.npc_id,
			npc_definition.service_id,
			""
		)
	)


	if decision_result != OK:
		# -------------------------------------------------
		# Sólo deshacemos una sesión NUEVA.
		#
		# Si era una sesión que ya existía previamente,
		# no debemos destruirla por fallar este segundo
		# envío.
		# -------------------------------------------------

		if started_new_service:
			session.end_npc_service()


		push_warning(
			(
				"ServerMain | No se pudo enviar la autorización "
				+
				"de interacción NPC al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				decision_result,
			]
		)


		return

	if npc_definition.service_id == "warehouse":
		var vault_result := (
			backend_vault_repository.load_vault(
				peer_id,
				session.account_id
			)
		)


		if vault_result != OK:
			print(
				"ServerMain | No se pudo iniciar carga de Vault",
				" | Peer: ",
				peer_id,
				" | Error: ",
				vault_result
			)

	# -----------------------------------------------------
	# INTERACCIÓN ACEPTADA
	# -----------------------------------------------------

	print(
		"ServerMain | Interacción NPC autorizada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | NPC: ",
		npc_definition.npc_id,
		" | Servicio: ",
		npc_definition.service_id,
		" | Mapa: ",
		session.map_id,
		" | Distancia: ",
		distance,
		" | Rango: ",
		npc_definition.interaction_range
	)

# =========================================================
# RECHAZAR INTERACCIÓN NPC
# =========================================================

func _reject_npc_interaction(
	peer_id: int,
	request_id: int,
	session: PlayerWorldSession,
	npc_id: String,
	reason: String,
	distance: float = -1.0
) -> void:
	if session == null:
		return


	var result := (
		game_server.send_npc_interaction_decision(
			peer_id,
			request_id,
			false,
			npc_id,
			"",
			reason
		)
	)


	if result != OK:
		push_warning(
			(
				"ServerMain | No se pudo enviar el rechazo "
				+
				"de interacción NPC al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


	print(
		"ServerMain | Interacción NPC rechazada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | NPC: ",
		npc_id,
		" | Motivo: ",
		reason,
		" | Distancia: ",
		distance
	)

# =========================================================
# FINALIZAR SERVICIO NPC
# =========================================================

func _on_client_npc_service_end_requested(
	peer_id: int
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el peer."
		)


		return


	if not session.has_active_npc_service():
		return


	var npc_id := (
		session.active_npc_id
	)


	var service_id := (
		session.active_service_id
	)


	session.end_npc_service()


	print(
		"ServerMain | Sesión de servicio NPC finalizada",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | NPC: ",
		npc_id,
		" | Servicio: ",
		service_id
	)

# =========================================================
# VALIDAR SESIÓN NPC ACTIVA
# =========================================================

func _validate_active_npc_service_range(
	peer_id: int
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if not session.has_active_npc_service():
		return


	var npc_definition := (
		world_npc_registry.get_definition(
			session.active_npc_id
		)
	)


	if npc_definition == null:
		_invalidate_active_npc_service(
			session,
			"npc_unavailable"
		)


		return


	if (
		session.map_id
		!=
		npc_definition.map_id
	):
		_invalidate_active_npc_service(
			session,
			"wrong_map"
		)


		return


	var player_position := Vector2(
		session.position.x,
		session.position.z
	)


	var npc_position := Vector2(
		npc_definition.position.x,
		npc_definition.position.z
	)


	var distance := (
		player_position.distance_to(
			npc_position
		)
	)


	if (
		distance
		<=
		npc_definition.interaction_range
	):
		return


	_invalidate_active_npc_service(
		session,
		"out_of_range",
		distance
	)


# =========================================================
# INVALIDAR SESIÓN NPC ACTIVA
# =========================================================

func _invalidate_active_npc_service(
	session: PlayerWorldSession,
	reason: String,
	distance: float = -1.0
) -> void:
	if session == null:
		return


	if not session.has_active_npc_service():
		return


	var npc_id := (
		session.active_npc_id
	)


	var service_id := (
		session.active_service_id
	)


	session.end_npc_service()


	var result := (
		game_server.send_npc_service_ended(
			session.peer_id,
			npc_id,
			service_id,
			reason
		)
	)


	if result != OK:
		push_warning(
			(
				"ServerMain | No se pudo informar "
				+
				"la finalización del servicio NPC "
				+
				"al peer %d. Error: %d"
			)
			%
			[
				session.peer_id,
				result,
			]
		)


	print(
		"ServerMain | Sesión de servicio NPC invalidada",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | NPC: ",
		npc_id,
		" | Servicio: ",
		service_id,
		" | Motivo: ",
		reason,
		" | Distancia: ",
		distance
	)

# =========================================================
# VAULT CARGADA DESDE BACKEND
# =========================================================

func _on_backend_vault_loaded(
	peer_id: int,
	account_id: int,
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


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return

	var validation_error := (
		ServerVaultSnapshotValidator.validate(
			snapshot
		)
	)


	if not validation_error.is_empty():
		print(
			"ServerMain | Snapshot de Vault rechazado",
			" | Peer: ",
			peer_id,
			" | Cuenta: ",
			account_id,
			" | Motivo: ",
			validation_error
		)


		_invalidate_active_npc_service(
			session,
			"invalid_vault_snapshot"
		)


		return

	if not session.set_active_vault_snapshot(
		snapshot
	):
		_invalidate_active_npc_service(
			session,
			"invalid_vault_session_snapshot"
		)


		return

	var items: Array = (
		snapshot.get(
			"items",
			[]
		)
	)


	print(
		"ServerMain | Vault persistente cargada",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		session.character_name,
		" | Items: ",
		items.size()
	)

	var send_result := (
		game_server.send_vault_snapshot(
			peer_id,
			snapshot
		)
	)


	if send_result != OK:
		push_warning(
			(
				"ServerMain | No se pudo enviar "
				+
				"el snapshot de Vault al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				send_result,
			]
		)


		return


	print(
		"ServerMain | Snapshot de Vault enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Items: ",
		items.size()
	)

# =========================================================
# ERROR AL CARGAR VAULT
# =========================================================

func _on_backend_vault_load_failed(
	peer_id: int,
	account_id: int,
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


	print(
		"ServerMain | No se pudo cargar Vault persistente",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Motivo: ",
		message
	)


	if session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		_invalidate_active_npc_service(
			session,
			"vault_backend_unavailable"
		)

# =========================================================
# ITEM DE VAULT MOVIDO EN BACKEND
# =========================================================

func _on_backend_vault_item_moved(
	peer_id: int,
	account_id: int,
	uid: String,
	item: Dictionary
) -> void:
	var session := world_session_registry.get_session(
		peer_id
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	print(
		"ServerMain | Posición de item Vault persistida",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	# -----------------------------------------------------
	# No modificamos un snapshot local.
	#
	# Volvemos a leer Laravel y usamos nuevamente el
	# estado persistente como fuente.
	# -----------------------------------------------------

	var reload_result := backend_vault_repository.load_vault(
		peer_id,
		account_id
	)


	if reload_result != OK:
		_invalidate_active_npc_service(
			session,
			"vault_reload_failed"
		)


# =========================================================
# MOVIMIENTO DE VAULT RECHAZADO
# =========================================================

func _on_backend_vault_item_move_failed(
	peer_id: int,
	account_id: int,
	uid: String,
	response_code: int,
	message: String
) -> void:
	var session := world_session_registry.get_session(
		peer_id
	)


	if session == null:
		return


	if session.account_id != account_id:
		return


	print(
		"ServerMain | Movimiento persistente de Vault rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	var reload_result := backend_vault_repository.load_vault(
		peer_id,
		account_id
	)


	if reload_result != OK:
		_invalidate_active_npc_service(
			session,
			"vault_reload_failed"
		)

func _request_vault_item_move(
	peer_id: int,
	snapshot: Dictionary,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> Error:
	var session := world_session_registry.get_session(
		peer_id
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return ERR_UNAVAILABLE


	var validation_error := (
		ServerVaultSnapshotValidator.validate_move(
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if not validation_error.is_empty():
		print(
			"ServerMain | Movimiento de Vault rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Motivo: ",
			validation_error
		)


		return ERR_INVALID_DATA


	return backend_vault_repository.move_vault_item(
		peer_id,
		session.account_id,
		uid,
		current_position,
		new_position
	)

# =========================================================
# SOLICITUD CLIENTE — MOVER ITEM EN VAULT
# =========================================================

func _on_client_vault_item_move_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		print(
			"ServerMain | Movimiento Vault rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: servicio Warehouse no activo"
		)


		return


	var snapshot := (
		session.get_active_vault_snapshot()
	)


	if snapshot.is_empty():
		print(
			"ServerMain | Movimiento Vault rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: no existe snapshot autoritativo"
		)


		var reload_result := (
			backend_vault_repository.load_vault(
				peer_id,
				session.account_id
			)
		)


		if reload_result != OK:
			_invalidate_active_npc_service(
				session,
				"vault_reload_failed"
			)


		return


	print(
		"ServerMain | Solicitud de movimiento Vault recibida",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		current_position,
		" | Hacia: ",
		new_position
	)


	var move_result := (
		_request_vault_item_move(
			peer_id,
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if move_result == OK:
		return


	print(
		"ServerMain | Movimiento Vault no iniciado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Error: ",
		move_result
	)


	# -----------------------------------------------------
	# Si la operación era inválida, reenviamos nuestro
	# último estado autoritativo.
	#
	# Así el cliente converge nuevamente sin mutar nada.
	# -----------------------------------------------------

	if move_result != ERR_BUSY:
		var resend_result := (
			game_server.send_vault_snapshot(
				peer_id,
				snapshot
			)
		)


		if resend_result != OK:
			push_warning(
				(
					"ServerMain | No se pudo reenviar "
					+
					"snapshot de Vault. Error: %d"
				)
				%
				resend_result
			)

# =========================================================
# EQUIPMENT PERSISTENTE CARGADO
# =========================================================

func _on_backend_character_equipment_loaded(
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
			"ServerMain | Equipment persistente rechazado",
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
				"ServerMain | No se pudo enviar "
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
		"ServerMain | Snapshot de Equipment enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Items: ",
		(
			snapshot.get(
				"items",
				[]
			)
			as Array
		).size()
	)

	print(
		"ServerMain | Equipment persistente cargado",
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
# EQUIPMENT PERSISTENTE — ERROR
# =========================================================

func _on_backend_character_equipment_load_failed(
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
		"ServerMain | Error cargando Equipment persistente",
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

# =========================================================
# INVENTORY PERSISTENTE CARGADO
# =========================================================

func _on_backend_character_inventory_loaded(
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
			"ServerMain | Inventory persistente rechazado",
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
				"ServerMain | No se pudo enviar "
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

	print(
		"ServerMain | Snapshot de Inventory enviado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Character ID: ",
		character_id,
		" | Items: ",
		(
			snapshot.get(
				"items",
				[]
			)
			as Array
		).size()
	)

	print(
		"ServerMain | Inventory persistente cargado",
		" | Peer: ",
		peer_id,
		" | Cuenta: ",
		account_id,
		" | Personaje: ",
		session.character_name,
		" | Character ID: ",
		character_id,
		" | Items: ",
		(
			snapshot.get(
				"items",
				[]
			)
			as Array
		).size()
	)

# =========================================================
# INVENTORY PERSISTENTE — ERROR
# =========================================================

func _on_backend_character_inventory_load_failed(
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
		"ServerMain | Error cargando Inventory persistente",
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
# REQUEST AUTORITATIVO DE MOVIMIENTO DE INVENTORY
# =========================================================

func _request_inventory_item_move(
	peer_id: int,
	snapshot: Dictionary,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var validation_error := (
		ServerCharacterInventorySnapshotValidator.validate_move(
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if not validation_error.is_empty():
		print(
			"ServerMain | Movimiento de Inventory rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Motivo: ",
			validation_error
		)


		return ERR_INVALID_DATA


	return backend_character_inventory_repository.move_inventory_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_position,
		new_position
	)

# =========================================================
# SOLICITUD CLIENTE — MOVER ITEM EN INVENTORY
# =========================================================

func _on_client_inventory_item_move_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var snapshot := (
		session.get_inventory_snapshot()
	)


	if snapshot.is_empty():
		print(
			"ServerMain | Movimiento Inventory rechazado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: no existe snapshot autoritativo"
		)


		var reload_result := (
			backend_character_inventory_repository.load_inventory(
				peer_id,
				session.account_id,
				session.character_id
			)
		)


		if reload_result != OK:
			game_server.reject_authenticated_peer(
				peer_id,
				"No se pudo recuperar el Inventory persistente."
			)


		return


	print(
		"ServerMain | Solicitud de movimiento Inventory recibida",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		current_position,
		" | Hacia: ",
		new_position
	)


	var move_result := (
		_request_inventory_item_move(
			peer_id,
			snapshot,
			uid,
			current_position,
			new_position
		)
	)


	if move_result == OK:
		return


	print(
		"ServerMain | Movimiento Inventory no iniciado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Error: ",
		move_result
	)


	if move_result != ERR_BUSY:
		var resend_result := (
			game_server.send_character_inventory_snapshot(
				peer_id,
				snapshot
			)
		)


		if resend_result != OK:
			push_warning(
				(
					"ServerMain | No se pudo reenviar "
					+
					"snapshot de Inventory. Error: %d"
				)
				%
				resend_result
			)

# =========================================================
# MOVIMIENTO DE INVENTORY RECHAZADO
# =========================================================

func _on_backend_character_inventory_item_move_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
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
		"ServerMain | Movimiento persistente de Inventory rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	var reload_result := (
		backend_character_inventory_repository.load_inventory(
			peer_id,
			account_id,
			character_id
		)
	)


	if reload_result != OK:
		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo recuperar el Inventory persistente."
		)

# =========================================================
# ITEM DE INVENTORY MOVIDO EN BACKEND
# =========================================================

func _on_backend_character_inventory_item_moved(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
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
		"ServerMain | Posición de item Inventory persistida",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	# -----------------------------------------------------
	# Igual que Vault:
	#
	# NO parcheamos manualmente el snapshot de sesión.
	# Volvemos a leer Laravel.
	# -----------------------------------------------------

	var reload_result := (
		backend_character_inventory_repository.load_inventory(
			peer_id,
			account_id,
			character_id
		)
	)


	if reload_result != OK:
		game_server.reject_authenticated_peer(
			peer_id,
			"No se pudo recargar el Inventory persistente."
		)

# =========================================================
# SOLICITUD CLIENTE — TRANSFERENCIA INVENTORY / VAULT
# =========================================================

func _on_client_item_container_transfer_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	# -----------------------------------------------------
	# VAULT SÓLO PUEDE MANIPULARSE DURANTE WAREHOUSE
	# -----------------------------------------------------

	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		print(
			"ServerMain | Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: servicio Warehouse no activo"
		)


		return


	# -----------------------------------------------------
	# INVENTORY AUTORITATIVO
	# -----------------------------------------------------

	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	if inventory_snapshot.is_empty():
		print(
			"ServerMain | Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: Inventory autoritativo no disponible"
		)


		var inventory_reload_result := (
			backend_character_inventory_repository.load_inventory(
				peer_id,
				session.account_id,
				session.character_id
			)
		)


		if (
			inventory_reload_result != OK
			and
			inventory_reload_result != ERR_BUSY
		):
			game_server.reject_authenticated_peer(
				peer_id,
				"No se pudo recuperar el Inventory persistente."
			)


		return


	# -----------------------------------------------------
	# VAULT AUTORITATIVA
	# -----------------------------------------------------

	var vault_snapshot := (
		session.get_active_vault_snapshot()
	)


	if vault_snapshot.is_empty():
		print(
			"ServerMain | Transferencia Inventory/Vault rechazada",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Motivo: Vault autoritativa no disponible"
		)


		var vault_reload_result := (
			backend_vault_repository.load_vault(
				peer_id,
				session.account_id
			)
		)


		if (
			vault_reload_result != OK
			and
			vault_reload_result != ERR_BUSY
		):
			_invalidate_active_npc_service(
				session,
				"vault_reload_failed"
			)


		return


	# -----------------------------------------------------
	# SIMULAR + VALIDAR LOS DOS CONTENEDORES
	# -----------------------------------------------------

	var validation := (
		ServerItemContainerTransferValidator.validate_transfer(
			inventory_snapshot,
			vault_snapshot,
			uid,
			source_container,
			target_container,
			current_position,
			new_position
		)
	)


	if not bool(
		validation.get(
			"ok",
			false
		)
	):
		print(
			"ServerMain | Transferencia Inventory/Vault rechazada antes del backend",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Desde: ",
			source_container,
			" ",
			current_position,
			" | Hacia: ",
			target_container,
			" ",
			new_position,
			" | Motivo: ",
			validation.get(
				"message",
				"unknown"
			)
		)


		_resend_item_container_snapshots(
			peer_id,
			session,
			inventory_snapshot,
			vault_snapshot
		)


		return


	print(
		"ServerMain | Transferencia Inventory/Vault validada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" ",
		current_position,
		" | Hacia: ",
		target_container,
		" ",
		new_position
	)


	# -----------------------------------------------------
	# PERSISTIR ATÓMICAMENTE EN LARAVEL
	# -----------------------------------------------------

	var transfer_result := (
		backend_item_transfer_repository.transfer_item(
			peer_id,
			session.account_id,
			session.character_id,
			uid,
			source_container,
			target_container,
			current_position,
			new_position
		)
	)


	if transfer_result == OK:
		return


	print(
		"ServerMain | Transferencia Inventory/Vault no iniciada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Error: ",
		transfer_result
	)


	if transfer_result != ERR_BUSY:
		_resend_item_container_snapshots(
			peer_id,
			session,
			inventory_snapshot,
			vault_snapshot
		)


# =========================================================
# TRANSFERENCIA PERSISTIDA EN BACKEND
# =========================================================

func _on_backend_item_transferred(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	item: Dictionary
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
		"ServerMain | Transferencia Inventory/Vault persistida",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" | Hacia: ",
		target_container,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	# -----------------------------------------------------
	# MUY IMPORTANTE:
	#
	# No aplicamos el candidate snapshot generado antes.
	# Laravel vuelve a ser la fuente definitiva.
	#
	# Recargamos Inventory y Vault desde persistencia.
	# -----------------------------------------------------

	_reload_item_container_snapshots(
		session
	)


# =========================================================
# TRANSFERENCIA RECHAZADA POR BACKEND
# =========================================================

func _on_backend_item_transfer_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	response_code: int,
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
		"ServerMain | Transferencia Inventory/Vault rechazada por backend",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Desde: ",
		source_container,
		" | Hacia: ",
		target_container,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	# -----------------------------------------------------
	# Puede ser, por ejemplo, un 409:
	#
	# la posición persistente cambió.
	#
	# No confiamos entonces en los snapshots anteriores;
	# recargamos desde Laravel.
	# -----------------------------------------------------

	_reload_item_container_snapshots(
		session
	)


# =========================================================
# RECARGAR INVENTORY + VAULT
# =========================================================

func _reload_item_container_snapshots(
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


	var inventory_result := (
		backend_character_inventory_repository.load_inventory(
			session.peer_id,
			session.account_id,
			session.character_id
		)
	)


	if (
		inventory_result != OK
		and
		inventory_result != ERR_BUSY
	):
		game_server.reject_authenticated_peer(
			session.peer_id,
			"No se pudo recargar el Inventory persistente."
		)


		return


	# -----------------------------------------------------
	# Si el Warehouse sigue activo, refrescamos Vault.
	#
	# Si el jugador cerró/se alejó mientras la operación
	# HTTP estaba en curso, no volvemos a abrirla.
	# -----------------------------------------------------

	if not session.is_using_npc_service(
		"warehouse_keeper",
		"warehouse"
	):
		return


	var vault_result := (
		backend_vault_repository.load_vault(
			session.peer_id,
			session.account_id
		)
	)


	if (
		vault_result != OK
		and
		vault_result != ERR_BUSY
	):
		_invalidate_active_npc_service(
			session,
			"vault_reload_failed"
		)


# =========================================================
# REENVIAR ÚLTIMOS SNAPSHOTS AUTORITATIVOS
# =========================================================

func _resend_item_container_snapshots(
	peer_id: int,
	session: PlayerWorldSession,
	inventory_snapshot: Dictionary,
	vault_snapshot: Dictionary
) -> void:
	if session == null:
		return


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
					"ServerMain | No se pudo reenviar "
					+
					"Inventory después de transferencia."
					+
					" Error: %d"
				)
				%
				inventory_result
			)


	if (
		session.is_using_npc_service(
			"warehouse_keeper",
			"warehouse"
		)
		and
		not vault_snapshot.is_empty()
	):
		var vault_result := (
			game_server.send_vault_snapshot(
				peer_id,
				vault_snapshot
			)
		)


		if vault_result != OK:
			push_warning(
				(
					"ServerMain | No se pudo reenviar "
					+
					"Vault después de transferencia."
					+
					" Error: %d"
				)
				%
				vault_result
			)

# =========================================================
# REQUEST AUTORITATIVO — EQUIP
# =========================================================

func _request_equipment_equip(
	peer_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: Variant
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if (
		inventory_snapshot.is_empty()
		or
		equipment_snapshot.is_empty()
	):
		return ERR_UNAVAILABLE


	var validation_result := (
		ServerEquipmentTransferValidator.validate_equip(
			inventory_snapshot,
			equipment_snapshot,
			uid,
			current_position,
			equipment_slot
		)
	)


	if not bool(
		validation_result.get(
			"ok",
			false
		)
	):
		print(
			"ServerMain | Equip rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Slot: ",
			equipment_slot,
			" | Motivo: ",
			validation_result.get(
				"message",
				"unknown"
			)
		)


		return ERR_INVALID_DATA


	return backend_character_equipment_repository.equip_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_position,
		equipment_slot
	)


# =========================================================
# REQUEST AUTORITATIVO — UNEQUIP
# =========================================================

func _request_equipment_unequip(
	peer_id: int,
	uid: String,
	current_equipment_slot: Variant,
	new_position: Vector2i
) -> Error:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return ERR_DOES_NOT_EXIST


	var inventory_snapshot := (
		session.get_inventory_snapshot()
	)


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if (
		inventory_snapshot.is_empty()
		or
		equipment_snapshot.is_empty()
	):
		return ERR_UNAVAILABLE


	var validation_result := (
		ServerEquipmentTransferValidator.validate_unequip(
			inventory_snapshot,
			equipment_snapshot,
			uid,
			current_equipment_slot,
			new_position
		)
	)


	if not bool(
		validation_result.get(
			"ok",
			false
		)
	):
		print(
			"ServerMain | Unequip rechazado antes del backend",
			" | Peer: ",
			peer_id,
			" | UID: ",
			uid,
			" | Slot: ",
			current_equipment_slot,
			" | Destino: ",
			new_position,
			" | Motivo: ",
			validation_result.get(
				"message",
				"unknown"
			)
		)


		return ERR_INVALID_DATA


	return backend_character_equipment_repository.unequip_item(
		peer_id,
		session.account_id,
		session.character_id,
		uid,
		current_equipment_slot,
		new_position
	)

# =========================================================
# RELOAD AUTORITATIVO INVENTORY + EQUIPMENT
# =========================================================

func _reload_character_item_snapshots(
	peer_id: int,
	reason: String
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	var inventory_result := (
		backend_character_inventory_repository.load_inventory(
			peer_id,
			session.account_id,
			session.character_id
		)
	)


	var equipment_result := (
		backend_character_equipment_repository.load_equipment(
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
			"ServerMain | No se pudo recargar estado "
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
	# seguir jugando con un snapshot que podría estar stale.
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
# BACKEND — ITEM EQUIPADO
# =========================================================

func _on_backend_equipment_item_equipped(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
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
		"ServerMain | Item equipado y persistido",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		item.get(
			"equipment_slot",
			"?"
		)
	)


	_reload_character_item_snapshots(
		peer_id,
		"equip_persisted"
	)

# =========================================================
# BACKEND — EQUIP RECHAZADO
# =========================================================

func _on_backend_equipment_item_equip_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
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
		"ServerMain | Equip persistente rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	_reload_character_item_snapshots(
		peer_id,
		"equip_rejected"
	)

# =========================================================
# BACKEND — ITEM DESEQUIPADO
# =========================================================

func _on_backend_equipment_item_unequipped(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
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
		"ServerMain | Item desequipado y persistido",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Posición: ",
		item.get(
			"grid_position",
			{}
		)
	)


	_reload_character_item_snapshots(
		peer_id,
		"unequip_persisted"
	)

# =========================================================
# BACKEND — UNEQUIP RECHAZADO
# =========================================================

func _on_backend_equipment_item_unequip_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
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
		"ServerMain | Unequip persistente rechazado",
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message
	)


	_reload_character_item_snapshots(
		peer_id,
		"unequip_rejected"
	)

# =========================================================
# CLIENT REQUEST — EQUIP
# =========================================================

func _on_client_equipment_equip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: String
) -> void:
	var result := (
		_request_equipment_equip(
			peer_id,
			uid,
			current_position,
			equipment_slot
		)
	)


	print(
		"ServerMain | Solicitud Equip procesada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		equipment_slot,
		" | Resultado: ",
		result
	)


	if (
		result == OK
		or
		result == ERR_BUSY
	):
		return


	_resend_character_item_snapshots(
		peer_id
	)

# =========================================================
# CLIENT REQUEST — UNEQUIP
# =========================================================

func _on_client_equipment_unequip_requested(
	peer_id: int,
	request_id: int,
	uid: String,
	current_equipment_slot: String,
	new_position: Vector2i
) -> void:
	var result := (
		_request_equipment_unequip(
			peer_id,
			uid,
			current_equipment_slot,
			new_position
		)
	)


	print(
		"ServerMain | Solicitud Unequip procesada",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | UID: ",
		uid,
		" | Slot: ",
		current_equipment_slot,
		" | Destino: ",
		new_position,
		" | Resultado: ",
		result
	)


	if (
		result == OK
		or
		result == ERR_BUSY
	):
		return


	_resend_character_item_snapshots(
		peer_id
	)

# =========================================================
# REENVIAR INVENTORY + EQUIPMENT ACTUALES
# =========================================================

func _resend_character_item_snapshots(
	peer_id: int
) -> void:
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
					"ServerMain | No se pudo reenviar "
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
					"ServerMain | No se pudo reenviar "
					+
					"Equipment. Error: %d"
				)
				%
				equipment_result
			)
