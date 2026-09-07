class_name ActionApproachCoordinator
extends Node


# =========================================================
# CONFIGURACIÓN
# =========================================================

const RETARGET_INTERVAL_MSEC: int = 250

const TARGET_RETARGET_DISTANCE: float = 0.5

const APPROACH_STOP_MARGIN: float = 0.15

const NAVIGATION_RANGE_TOLERANCE: float = 0.25


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

var movement_coordinator: MovementCoordinator = null

var basic_attack_coordinator: BasicAttackCoordinator = null


# =========================================================
# ESTADO RUNTIME
# =========================================================

var configured: bool = false

var pending_basic_attacks: Dictionary = {}


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_mob_registry: WorldMobRegistry,
	p_movement_coordinator: MovementCoordinator,
	p_basic_attack_coordinator: BasicAttackCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_mob_registry == null:
		return false


	if p_movement_coordinator == null:
		return false


	if p_basic_attack_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	world_mob_registry = (
		p_world_mob_registry
	)

	movement_coordinator = (
		p_movement_coordinator
	)

	basic_attack_coordinator = (
		p_basic_attack_coordinator
	)


	_bind_signals()


	configured = true


	print(
		"ActionApproachCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not basic_attack_coordinator.basic_attack_request_started.is_connected(
		_on_basic_attack_request_started
	):
		basic_attack_coordinator.basic_attack_request_started.connect(
			_on_basic_attack_request_started
		)


	if not basic_attack_coordinator.basic_attack_approach_requested.is_connected(
		_on_basic_attack_approach_requested
	):
		basic_attack_coordinator.basic_attack_approach_requested.connect(
			_on_basic_attack_approach_requested
		)


	if not movement_coordinator.client_movement_intent_started.is_connected(
		_on_client_movement_intent_started
	):
		movement_coordinator.client_movement_intent_started.connect(
			_on_client_movement_intent_started
		)


	if not world_session_registry.session_removed.is_connected(
		_on_session_removed
	):
		world_session_registry.session_removed.connect(
			_on_session_removed
		)


	if not world_mob_registry.mob_died.is_connected(
		_on_mob_died
	):
		world_mob_registry.mob_died.connect(
			_on_mob_died
		)


	if not game_server.client_skill_cast_requested.is_connected(
		_on_client_skill_cast_requested
	):
		game_server.client_skill_cast_requested.connect(
			_on_client_skill_cast_requested
		)


	if not game_server.client_npc_interaction_requested.is_connected(
		_on_client_npc_interaction_requested
	):
		game_server.client_npc_interaction_requested.connect(
			_on_client_npc_interaction_requested
		)


	if not game_server.client_world_drop_pickup_requested.is_connected(
		_on_client_world_drop_pickup_requested
	):
		game_server.client_world_drop_pickup_requested.connect(
			_on_client_world_drop_pickup_requested
		)


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(
	_delta: float
) -> void:
	if not configured:
		return


	if pending_basic_attacks.is_empty():
		return


	var peer_ids: Array = (
		pending_basic_attacks.keys()
	)


	for peer_id_value: Variant in peer_ids:
		var peer_id := int(
			peer_id_value
		)


		_process_pending_basic_attack(
			peer_id,
			false
		)


# =========================================================
# BASIC ATTACK NUEVO
# =========================================================

func _on_basic_attack_request_started(
	peer_id: int,
	request_id: int
) -> void:
	if not pending_basic_attacks.has(
		peer_id
	):
		return


	var pending_state: Dictionary = (
		pending_basic_attacks[
			peer_id
		]
	)


	var previous_request_id := int(
		pending_state.get(
			"request_id",
			0
		)
	)


	if previous_request_id == request_id:
		return


	_cancel_pending_basic_attack(
		peer_id,
		"replaced_by_new_action",
		true
	)


# =========================================================
# APPROACH SOLICITADO POR BASIC ATTACK
# =========================================================

func _on_basic_attack_approach_requested(
	peer_id: int,
	request_id: int,
	target: Dictionary,
	_attack_range: float
) -> void:
	var entity_id := String(
		target.get(
			"entity_id",
			""
		)
	).strip_edges().to_lower()


	if entity_id.is_empty():
		basic_attack_coordinator.cancel_approached_basic_attack(
			peer_id,
			request_id,
			target,
			"target_not_found"
		)


		return


	pending_basic_attacks[
		peer_id
	] = {
		"request_id": request_id,

		"target": target.duplicate(
			true
		),

		"entity_id": entity_id,

		"last_target_position": Vector3.ZERO,

		"last_retarget_msec": 0,
	}


	print(
		"ActionApproachCoordinator | Approach started",
		" | Peer: ",
		peer_id,
		" | Request: ",
		request_id,
		" | Action: basic_attack",
		" | Entity: ",
		entity_id
	)


	_process_pending_basic_attack(
		peer_id,
		true
	)


# =========================================================
# PROCESAR ACTION PENDIENTE
# =========================================================

func _process_pending_basic_attack(
	peer_id: int,
	force_retarget: bool
) -> void:
	if not pending_basic_attacks.has(
		peer_id
	):
		return


	var pending_state: Dictionary = (
		pending_basic_attacks[
			peer_id
		]
	)


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		pending_basic_attacks.erase(
			peer_id
		)


		return


	if (
		session.vitals == null
		or
		not session.vitals.is_valid()
	):
		_cancel_pending_basic_attack(
			peer_id,
			"runtime_failure",
			true
		)


		return


	if session.vitals.hp <= 0:
		_cancel_pending_basic_attack(
			peer_id,
			"character_not_alive",
			true
		)


		return


	var entity_id := String(
		pending_state.get(
			"entity_id",
			""
		)
	).strip_edges().to_lower()


	if entity_id.is_empty():
		_cancel_pending_basic_attack(
			peer_id,
			"target_not_found",
			true
		)


		return


	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if mob == null:
		_cancel_pending_basic_attack(
			peer_id,
			"target_not_found",
			true
		)


		return


	if mob.map_id != session.map_id:
		_cancel_pending_basic_attack(
			peer_id,
			"target_wrong_map",
			true
		)


		return


	if not mob.is_alive():
		_cancel_pending_basic_attack(
			peer_id,
			"target_not_alive",
			true
		)


		return


	var attack_range := (
		basic_attack_coordinator
		.get_authoritative_attack_range(
			peer_id
		)
	)


	if attack_range <= 0.0:
		_cancel_pending_basic_attack(
			peer_id,
			"runtime_failure",
			true
		)


		return


	var player_position_2d := Vector2(
		session.position.x,
		session.position.z
	)


	var mob_position_2d := Vector2(
		mob.position.x,
		mob.position.z
	)


	var distance := (
		player_position_2d.distance_to(
			mob_position_2d
		)
	)


	# -----------------------------------------------------
	# EN RANGO
	# -----------------------------------------------------

	if distance <= attack_range:
		var request_id := int(
			pending_state.get(
				"request_id",
				0
			)
		)


		var target_value: Variant = (
			pending_state.get(
				"target",
				{}
			)
		)


		var target: Dictionary = {}


		if typeof(target_value) == TYPE_DICTIONARY:
			target = (
				target_value as Dictionary
			).duplicate(
				true
			)


		pending_basic_attacks.erase(
			peer_id
		)


		movement_coordinator.stop_action_approach_movement(
			peer_id
		)


		print(
			"ActionApproachCoordinator | Range reached",
			" | Peer: ",
			peer_id,
			" | Request: ",
			request_id,
			" | Action: basic_attack",
			" | Entity: ",
			entity_id,
			" | Distance: ",
			distance,
			" | Range: ",
			attack_range
		)


		basic_attack_coordinator.execute_approached_basic_attack(
			peer_id,
			request_id,
			target
		)


		return


	# -----------------------------------------------------
	# RETARGET
	# -----------------------------------------------------

	var now_msec := (
		Time.get_ticks_msec()
	)


	var last_retarget_msec := int(
		pending_state.get(
			"last_retarget_msec",
			0
		)
	)


	var last_target_position := (
		mob.position
	)


	var last_position_value: Variant = (
		pending_state.get(
			"last_target_position",
			null
		)
	)


	if typeof(last_position_value) == TYPE_VECTOR3:
		last_target_position = (
			last_position_value
		)


	var target_moved_distance := (
		Vector2(
			last_target_position.x,
			last_target_position.z
		)
		.distance_to(
			mob_position_2d
		)
	)


	var retarget_time_elapsed := (
		now_msec
		-
		last_retarget_msec
		>=
		RETARGET_INTERVAL_MSEC
	)


	var target_moved_enough := (
		target_moved_distance
		>=
		TARGET_RETARGET_DISTANCE
	)


	var movement_missing := (
		not session.has_authorized_move_target
	)


	if (
		not force_retarget
		and
		not movement_missing
		and
		not (
			retarget_time_elapsed
			and
			target_moved_enough
		)
	):
		return


	_retarget_basic_attack_approach(
		peer_id,
		session,
		mob,
		attack_range,
		now_msec
	)


# =========================================================
# RETARGET AUTORITATIVO
# =========================================================

func _retarget_basic_attack_approach(
	peer_id: int,
	session: PlayerWorldSession,
	mob: WorldMobRuntimeState,
	attack_range: float,
	now_msec: int
) -> void:
	if not pending_basic_attacks.has(
		peer_id
	):
		return


	var approach_target := (
		_build_approach_target(
			session.position,
			mob.position,
			attack_range
		)
	)


	var movement_result := (
		movement_coordinator
		.begin_action_approach_movement(
			peer_id,
			approach_target
		)
	)


	if not bool(
		movement_result.get(
			"ok",
			false
		)
	):
		_cancel_pending_basic_attack(
			peer_id,
			"approach_unreachable",
			true
		)


		return


	var resolved_value: Variant = (
		movement_result.get(
			"resolved_target",
			null
		)
	)


	if typeof(resolved_value) != TYPE_VECTOR3:
		_cancel_pending_basic_attack(
			peer_id,
			"approach_unreachable",
			true
		)


		return


	var resolved_target: Vector3 = (
		resolved_value
	)


	var resolved_distance_to_mob := (
		Vector2(
			resolved_target.x,
			resolved_target.z
		)
		.distance_to(
			Vector2(
				mob.position.x,
				mob.position.z
			)
		)
	)


	if (
		resolved_distance_to_mob
		>
		attack_range
		+
		NAVIGATION_RANGE_TOLERANCE
	):
		_cancel_pending_basic_attack(
			peer_id,
			"approach_unreachable",
			true
		)


		return


	var pending_state: Dictionary = (
		pending_basic_attacks[
			peer_id
		]
	)


	pending_state[
		"last_target_position"
	] = mob.position

	pending_state[
		"last_retarget_msec"
	] = now_msec


	pending_basic_attacks[
		peer_id
	] = pending_state


# =========================================================
# CALCULAR PUNTO DE APPROACH
# =========================================================

func _build_approach_target(
	player_position: Vector3,
	target_position: Vector3,
	action_range: float
) -> Vector3:
	var target_to_player := Vector2(
		player_position.x
		-
		target_position.x,

		player_position.z
		-
		target_position.z
	)


	if target_to_player.length_squared() <= 0.000001:
		target_to_player = Vector2(
			1.0,
			0.0
		)
	else:
		target_to_player = (
			target_to_player.normalized()
		)


	var stop_distance := maxf(
		action_range
		-
		APPROACH_STOP_MARGIN,
		0.0
	)


	return Vector3(
		target_position.x
		+
		target_to_player.x
		*
		stop_distance,

		target_position.y,

		target_position.z
		+
		target_to_player.y
		*
		stop_distance
	)


# =========================================================
# MOVIMIENTO MANUAL
# =========================================================

func _on_client_movement_intent_started(
	peer_id: int,
	_request_id: int
) -> void:
	_cancel_pending_basic_attack(
		peer_id,
		"replaced_by_movement",
		true
	)


# =========================================================
# SKILL MANUAL
# =========================================================

func _on_client_skill_cast_requested(
	peer_id: int,
	_request_id: int,
	_skill_id: String,
	_target: Dictionary
) -> void:
	_cancel_pending_basic_attack(
		peer_id,
		"replaced_by_skill_cast",
		true
	)


# =========================================================
# NPC INPUT
# =========================================================

func _on_client_npc_interaction_requested(
	peer_id: int,
	_request_id: int,
	_npc_id: String
) -> void:
	_cancel_pending_basic_attack(
		peer_id,
		"replaced_by_npc_interaction",
		true
	)


# =========================================================
# DROP INPUT
# =========================================================

func _on_client_world_drop_pickup_requested(
	peer_id: int,
	_request_id: int,
	_entity_id: String
) -> void:
	_cancel_pending_basic_attack(
		peer_id,
		"replaced_by_world_drop_pickup",
		true
	)


# =========================================================
# MOB MUERTO
# =========================================================

func _on_mob_died(
	entity_id: String,
	_map_id: String,
	_source: Dictionary,
	_mob_snapshot: Dictionary
) -> void:
	var normalized_entity_id := (
		entity_id.strip_edges().to_lower()
	)


	if normalized_entity_id.is_empty():
		return


	var peer_ids: Array = (
		pending_basic_attacks.keys()
	)


	for peer_id_value: Variant in peer_ids:
		var peer_id := int(
			peer_id_value
		)


		if not pending_basic_attacks.has(
			peer_id
		):
			continue


		var pending_state: Dictionary = (
			pending_basic_attacks[
				peer_id
			]
		)


		var pending_entity_id := String(
			pending_state.get(
				"entity_id",
				""
			)
		).strip_edges().to_lower()


		if pending_entity_id != normalized_entity_id:
			continue


		_cancel_pending_basic_attack(
			peer_id,
			"target_not_alive",
			true
		)


# =========================================================
# SESSION REMOVED
# =========================================================

func _on_session_removed(
	peer_id: int
) -> void:
	if not pending_basic_attacks.has(
		peer_id
	):
		return


	pending_basic_attacks.erase(
		peer_id
	)


# =========================================================
# CANCELAR
# =========================================================

func _cancel_pending_basic_attack(
	peer_id: int,
	reason: String,
	send_result: bool
) -> void:
	if not pending_basic_attacks.has(
		peer_id
	):
		return


	var pending_state: Dictionary = (
		pending_basic_attacks[
			peer_id
		]
	)


	var request_id := int(
		pending_state.get(
			"request_id",
			0
		)
	)


	var entity_id := String(
		pending_state.get(
			"entity_id",
			""
		)
	)


	var target: Dictionary = {}


	var target_value: Variant = (
		pending_state.get(
			"target",
			{}
		)
	)


	if typeof(target_value) == TYPE_DICTIONARY:
		target = (
			target_value as Dictionary
		).duplicate(
			true
		)


	pending_basic_attacks.erase(
		peer_id
	)


	movement_coordinator.stop_action_approach_movement(
		peer_id
	)


	if (
		send_result
		and
		request_id > 0
	):
		basic_attack_coordinator.cancel_approached_basic_attack(
			peer_id,
			request_id,
			target,
			reason
		)


	print(
		"ActionApproachCoordinator | Approach cancelled",
		" | Peer: ",
		peer_id,
		" | Request: ",
		request_id,
		" | Action: basic_attack",
		" | Entity: ",
		entity_id,
		" | Reason: ",
		reason
	)
