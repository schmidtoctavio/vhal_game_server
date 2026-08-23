class_name NpcServiceCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_npc_registry: WorldNpcRegistry = null

var vault_coordinator: VaultCoordinator = null


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
	p_world_npc_registry: WorldNpcRegistry,
	p_vault_coordinator: VaultCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_npc_registry == null:
		return false


	if p_vault_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = p_world_session_registry

	world_npc_registry = p_world_npc_registry

	vault_coordinator = p_vault_coordinator


	_bind_signals()


	configured = true


	print(
		"NpcServiceCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_npc_interaction_requested.is_connected(
		_on_client_npc_interaction_requested
	):
		game_server.client_npc_interaction_requested.connect(
			_on_client_npc_interaction_requested
		)


	if not game_server.client_npc_service_end_requested.is_connected(
		_on_client_npc_service_end_requested
	):
		game_server.client_npc_service_end_requested.connect(
			_on_client_npc_service_end_requested
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
		return


	var npc_definition := (
		world_npc_registry.get_definition(
			npc_id
		)
	)


	# -----------------------------------------------------
	# NPC EXISTENTE
	# -----------------------------------------------------

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
	# MISMO MAPA
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
		# La operación es idempotente.
		# -------------------------------------------------

		if session.is_using_npc_service(
			npc_definition.npc_id,
			npc_definition.service_id
		):
			print(
				"NpcServiceCoordinator | "
				+
				"Sesión de servicio NPC ya activa",
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
			"NpcServiceCoordinator | Sesión de servicio NPC iniciada",
			" | Peer: ",
			peer_id,
			" | Personaje: ",
			session.character_name,
			" | NPC: ",
			npc_definition.npc_id,
			" | Servicio: ",
			npc_definition.service_id
		)


	# -----------------------------------------------------
	# AUTORIZACIÓN AL CLIENTE
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
		# -------------------------------------------------

		if started_new_service:
			session.end_npc_service()


		push_warning(
			(
				"NpcServiceCoordinator | "
				+
				"No se pudo enviar la autorización NPC "
				+
				"al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				decision_result,
			]
		)


		return


	print(
		"NpcServiceCoordinator | Interacción NPC autorizada",
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


	# -----------------------------------------------------
	# SERVICIO WAREHOUSE
	# -----------------------------------------------------

	if npc_definition.service_id == "warehouse":
		var vault_result := (
			vault_coordinator.load_active_vault(
				peer_id
			)
		)


		if vault_result != OK:
			print(
				"NpcServiceCoordinator | "
				+
				"No se pudo iniciar carga de Vault",
				" | Peer: ",
				peer_id,
				" | Error: ",
				vault_result
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
				"NpcServiceCoordinator | "
				+
				"No se pudo enviar rechazo NPC "
				+
				"al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


	print(
		"NpcServiceCoordinator | Interacción NPC rechazada",
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
		(
			" | Distancia: %f" % distance
			if
			distance >= 0.0
			else
			""
		)
	)


# =========================================================
# FINALIZAR SERVICIO POR PEDIDO DEL CLIENTE
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
		"NpcServiceCoordinator | Sesión de servicio NPC finalizada",
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

func validate_active_service_range(
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
		invalidate_active_service(
			session,
			"npc_unavailable"
		)


		return


	if (
		session.map_id
		!=
		npc_definition.map_id
	):
		invalidate_active_service(
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


	invalidate_active_service(
		session,
		"out_of_range",
		distance
	)


# =========================================================
# INVALIDAR SESIÓN NPC ACTIVA
# =========================================================

func invalidate_active_service(
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
				"NpcServiceCoordinator | "
				+
				"No se pudo informar invalidación NPC "
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
		"NpcServiceCoordinator | Sesión de servicio NPC invalidada",
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
		(
			" | Distancia: %f" % distance
			if
			distance >= 0.0
			else
			""
		)
	)
