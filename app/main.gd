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

@onready var character_item_state_coordinator: CharacterItemStateCoordinator = (
	$CharacterItemStateCoordinator
)

@onready var equipment_coordinator: EquipmentCoordinator = (
	$EquipmentCoordinator
)

@onready var inventory_coordinator: InventoryCoordinator = (
	$InventoryCoordinator
)

@onready var vault_coordinator: VaultCoordinator = (
	$VaultCoordinator
)

@onready var item_container_transfer_coordinator: ItemContainerTransferCoordinator = (
	$ItemContainerTransferCoordinator
)

@onready var npc_service_coordinator: NpcServiceCoordinator = (
	$NpcServiceCoordinator
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

	var equipment_snapshot_contract_error := (
		ServerEquipmentSnapshotValidator.validate_contract()
	)


	if not equipment_snapshot_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Snapshot Contract inválido: "
				+
				equipment_snapshot_contract_error
			)
		)


		get_tree().quit(
			13
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
			14
		)


		return


	print(
		"ServerMain | Equipment Domain Contract validado."
	)


	print(
		"ServerMain | Equipment Snapshot Contract validado."
	)


	print(
		"ServerMain | Equipment Transfer Contract validado."
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

	if character_item_state_coordinator == null:
		push_error(
			"ServerMain | No existe CharacterItemStateCoordinator."
		)


		get_tree().quit(
			15
		)


		return


	if not character_item_state_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository,
		backend_character_equipment_repository
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"CharacterItemStateCoordinator."
			)
		)


		get_tree().quit(
			15
		)


		return

	if equipment_coordinator == null:
		push_error(
			"ServerMain | No existe EquipmentCoordinator."
		)


		get_tree().quit(
			16
		)


		return


	if not equipment_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_equipment_repository,
		character_item_state_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar EquipmentCoordinator."
		)


		get_tree().quit(
			16
		)


		return

	if inventory_coordinator == null:
		push_error(
			"ServerMain | No existe InventoryCoordinator."
		)


		get_tree().quit(
			17
		)


		return


	if not inventory_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar InventoryCoordinator."
		)


		get_tree().quit(
			17
		)


		return

	if vault_coordinator == null:
		push_error(
			"ServerMain | No existe VaultCoordinator."
		)


		get_tree().quit(
			18
		)


		return


	if not vault_coordinator.setup(
		game_server,
		world_session_registry,
		backend_vault_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar VaultCoordinator."
		)


		get_tree().quit(
			18
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

	if item_container_transfer_coordinator == null:
		push_error(
			"ServerMain | No existe ItemContainerTransferCoordinator."
		)


		get_tree().quit(
			19
		)


		return


	if not item_container_transfer_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository,
		backend_item_transfer_repository,
		vault_coordinator
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"ItemContainerTransferCoordinator."
			)
		)


		get_tree().quit(
			19
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

	if npc_service_coordinator == null:
		push_error(
			"ServerMain | No existe NpcServiceCoordinator."
		)


		get_tree().quit(
			20
		)


		return


	if not npc_service_coordinator.setup(
		game_server,
		world_session_registry,
		world_npc_registry,
		vault_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar NpcServiceCoordinator."
		)


		get_tree().quit(
			20
		)


		return


	if not vault_coordinator.npc_service_invalidation_requested.is_connected(
		npc_service_coordinator.invalidate_active_service
	):
		vault_coordinator.npc_service_invalidation_requested.connect(
			npc_service_coordinator.invalidate_active_service
		)


	if not item_container_transfer_coordinator.npc_service_invalidation_requested.is_connected(
		npc_service_coordinator.invalidate_active_service
	):
		item_container_transfer_coordinator.npc_service_invalidation_requested.connect(
			npc_service_coordinator.invalidate_active_service
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

	var item_state_load_result := (
		character_item_state_coordinator.load_initial_snapshots(
			peer_id
		)
	)


	if item_state_load_result != OK:
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

	npc_service_coordinator.validate_active_service_range(
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
	npc_service_coordinator.validate_active_service_range(
		peer_id
	)


	_replicate_movement_state_to_map(
		peer_id,
		position,
		rotation_y,
		true
	)
