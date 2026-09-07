class_name MobCombatCoordinator
extends Node

# =========================================================
# SIGNALS
# =========================================================

signal player_mob_aggro_acquired(
	peer_id: int,
	entity_id: String
)

signal player_mob_aggro_released(
	peer_id: int,
	entity_id: String
)

signal player_damaged_by_mob(
	peer_id: int,
	entity_id: String,
	applied_damage: int
)

signal player_died(
	peer_id: int
)

signal player_respawned(
	peer_id: int
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

const MOB_STATE_SAMPLE_INTERVAL: float = 0.10

const REPATH_INTERVAL_MSEC: int = 250

const WAYPOINT_REACHED_DISTANCE: float = 0.01

const RETURN_REACHED_DISTANCE: float = 0.05

const MIN_DIRECTION_LENGTH_SQUARED: float = 0.000001


const PLAYER_RESPAWN_DELAY_SECONDS: float = 3.0

const PLAYER_RESPAWN_DELAY_MSEC: int = 3000


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_navigation_registry: WorldNavigationRegistry = null

var world_mob_registry: WorldMobRegistry = null


# =========================================================
# ESTADO
# =========================================================

var configured: bool = false

var mob_state_sample_accumulator: float = 0.0

var pending_player_respawns: Dictionary = {}


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_navigation_registry: WorldNavigationRegistry,
	p_world_mob_registry: WorldMobRegistry
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_navigation_registry == null:
		return false


	if p_world_mob_registry == null:
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	world_navigation_registry = (
		p_world_navigation_registry
	)

	world_mob_registry = (
		p_world_mob_registry
	)


	if not world_mob_registry.mob_damaged.is_connected(
		_on_mob_damaged
	):
		world_mob_registry.mob_damaged.connect(
			_on_mob_damaged
		)


	configured = true


	print(
		"MobCombatCoordinator | Inicializado."
	)


	return true


# =========================================================
# SERVER TICK
# =========================================================

func _physics_process(
	delta: float
) -> void:
	if not configured:
		return


	if delta <= 0.0:
		return


	var now_msec := (
		Time.get_ticks_msec()
	)


	_process_player_respawns(
		now_msec
	)


	for mob: WorldMobRuntimeState in (
		world_mob_registry.get_all_mobs()
	):
		_process_mob(
			mob,
			delta,
			now_msec
		)


	mob_state_sample_accumulator += (
		delta
	)


	if (
		mob_state_sample_accumulator
		<
		MOB_STATE_SAMPLE_INTERVAL
	):
		return


	mob_state_sample_accumulator = fmod(
		mob_state_sample_accumulator,
		MOB_STATE_SAMPLE_INTERVAL
	)


	_replicate_moving_mobs()


# =========================================================
# PROCESS MOB
# =========================================================

func _process_mob(
	mob: WorldMobRuntimeState,
	delta: float,
	now_msec: int
) -> void:
	if mob == null:
		return


	if not mob.is_valid():
		return


	if mob.definition == null:
		return


	if not mob.definition.has_pve_combat_profile():
		return


	if mob.combat_runtime == null:
		return


	if not mob.is_alive():
		mob.reset_combat()

		return


	var runtime := (
		mob.combat_runtime
	)


	if (
		runtime.state
		==
		WorldMobCombatRuntime.STATE_RETURNING
	):
		_process_return_to_spawn(
			mob,
			delta,
			now_msec
		)

		return


	var target := (
		_get_current_target(
			mob
		)
	)


	# -----------------------------------------------------
	# TARGET ANTERIOR YA NO VÁLIDO
	# -----------------------------------------------------

	if (
		target == null
		and
		runtime.target_peer_id > 1
	):
		_release_target_and_return(
			mob,
			"target_invalid"
		)


		_process_return_to_spawn(
			mob,
			delta,
			now_msec
		)


		return


	# -----------------------------------------------------
	# BUSCAR AGGRO POR PROXIMIDAD
	# -----------------------------------------------------

	if target == null:
		target = (
			_find_nearest_aggro_target(
				mob
			)
		)


		if target == null:
			var distance_from_spawn := (
				ServerMobCombatRules
				.distance_xz(
					mob.position,
					mob.spawn_position
				)
			)


			if (
				distance_from_spawn
				>
				RETURN_REACHED_DISTANCE
			):
				mob.combat_runtime.begin_returning()


				_process_return_to_spawn(
					mob,
					delta,
					now_msec
				)


			return


		_acquire_target(
			mob,
			target,
			"proximity"
		)


	# -----------------------------------------------------
	# LEASH
	# -----------------------------------------------------

	if ServerMobCombatRules.is_leash_broken(
		mob.definition,
		mob.spawn_position,
		mob.position,
		target.position
	):
		_release_target_and_return(
			mob,
			"leash"
		)


		_process_return_to_spawn(
			mob,
			delta,
			now_msec
		)


		return


	# -----------------------------------------------------
	# ATTACK RANGE
	# -----------------------------------------------------

	if ServerMobCombatRules.is_in_attack_range(
		mob.definition,
		mob.position,
		target.position
	):
		var was_attacking := (
			runtime.state
			==
			WorldMobCombatRuntime.STATE_ATTACKING
		)


		runtime.begin_attacking()


		_face_mob_toward(
			mob,
			target.position
		)


		if not was_attacking:
			_broadcast_mob_state(
				mob
			)


			print(
				"MobCombatCoordinator | Rango de ataque alcanzado",
				" | Entity: ",
				mob.entity_id,
				" | Target: ",
				target.character_name
			)


		_try_mob_attack(
			mob,
			target,
			now_msec
		)


		return


	# -----------------------------------------------------
	# CHASE
	# -----------------------------------------------------

	var was_chasing := (
		runtime.state
		==
		WorldMobCombatRuntime.STATE_CHASING
	)


	runtime.begin_chasing()


	if not was_chasing:
		print(
			"MobCombatCoordinator | Persecución iniciada",
			" | Entity: ",
			mob.entity_id,
			" | Target: ",
			target.character_name
		)


	if not _ensure_navigation_path(
		mob,
		target.position,
		now_msec
	):
		_release_target_and_return(
			mob,
			"path_not_found"
		)


		return


	_advance_mob_along_path(
		mob,
		delta
	)


# =========================================================
# TARGET ACTUAL
# =========================================================

func _get_current_target(
	mob: WorldMobRuntimeState
) -> PlayerWorldSession:
	if mob == null:
		return null


	if mob.combat_runtime == null:
		return null


	var peer_id := (
		mob.combat_runtime.target_peer_id
	)


	if peer_id <= 1:
		return null


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return null


	if session.map_id != mob.map_id:
		return null


	if session.vitals == null:
		return null


	if not session.vitals.is_valid():
		return null


	if session.vitals.hp <= 0:
		return null


	return session


# =========================================================
# BUSCAR TARGET
# =========================================================

func _find_nearest_aggro_target(
	mob: WorldMobRuntimeState
) -> PlayerWorldSession:
	var nearest: PlayerWorldSession = null

	var nearest_distance := INF


	for session: PlayerWorldSession in (
		world_session_registry.get_sessions_in_map(
			mob.map_id
		)
	):
		if session == null:
			continue


		if session.vitals == null:
			continue


		if session.vitals.hp <= 0:
			continue


		if not ServerMobCombatRules.can_aggro(
			mob.definition,
			mob.position,
			session.position
		):
			continue


		var distance := (
			ServerMobCombatRules.distance_xz(
				mob.position,
				session.position
			)
		)


		if distance >= nearest_distance:
			continue


		nearest = session

		nearest_distance = distance


	return nearest


# =========================================================
# AGGRO
# =========================================================

func _acquire_target(
	mob: WorldMobRuntimeState,
	session: PlayerWorldSession,
	reason: String
) -> void:
	if (
		mob == null
		or
		session == null
	):
		return


	if not mob.combat_runtime.acquire_target(
		session.peer_id
	):
		return

	player_mob_aggro_acquired.emit(
		session.peer_id,
		mob.entity_id
	)


	print(
		"MobCombatCoordinator | Aggro adquirido",
		" | Entity: ",
		mob.entity_id,
		" | Target Peer: ",
		session.peer_id,
		" | Target: ",
		session.character_name,
		" | Reason: ",
		reason
	)


func _release_target_and_return(
	mob: WorldMobRuntimeState,
	reason: String
) -> void:
	if mob == null:
		return


	if mob.combat_runtime == null:
		return


	var previous_peer_id := (
		mob.combat_runtime.target_peer_id
	)


	mob.combat_runtime.release_target(
		true
	)

	if previous_peer_id > 1:
		player_mob_aggro_released.emit(
			previous_peer_id,
			mob.entity_id
		)


	print(
		"MobCombatCoordinator | Aggro liberado",
		" | Entity: ",
		mob.entity_id,
		" | Previous Peer: ",
		previous_peer_id,
		" | Reason: ",
		reason
	)


# =========================================================
# DAMAGE → AGGRO
# =========================================================

func _on_mob_damaged(
	entity_id: String,
	map_id: String,
	source: Dictionary,
	_mob_snapshot: Dictionary,
	applied_damage: int
) -> void:
	if not configured:
		return


	if applied_damage <= 0:
		return


	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if mob == null:
		return


	if not mob.is_alive():
		return


	if mob.map_id != map_id:
		return


	if not mob.definition.has_pve_combat_profile():
		return


	if mob.combat_runtime.target_peer_id > 1:
		return


	var source_peer_id := int(
		source.get(
			"peer_id",
			-1
		)
	)


	if source_peer_id <= 1:
		return


	var session := (
		world_session_registry.get_session(
			source_peer_id
		)
	)


	if session == null:
		return


	if session.map_id != mob.map_id:
		return


	if session.vitals.hp <= 0:
		return


	if ServerMobCombatRules.is_leash_broken(
		mob.definition,
		mob.spawn_position,
		mob.position,
		session.position
	):
		return


	_acquire_target(
		mob,
		session,
		"damage"
	)


# =========================================================
# RETURN TO SPAWN
# =========================================================

func _process_return_to_spawn(
	mob: WorldMobRuntimeState,
	delta: float,
	now_msec: int
) -> void:
	if mob == null:
		return


	var distance := (
		ServerMobCombatRules.distance_xz(
			mob.position,
			mob.spawn_position
		)
	)


	if (
		distance
		<=
		RETURN_REACHED_DISTANCE
	):
		mob.set_world_transform(
			mob.spawn_position,
			mob.spawn_rotation_y
		)


		mob.combat_runtime.finish_returning()


		_broadcast_mob_state(
			mob
		)


		print(
			"MobCombatCoordinator | Regreso completado",
			" | Entity: ",
			mob.entity_id,
			" | Spawn: ",
			mob.spawn_position
		)


		return


	if not _ensure_navigation_path(
		mob,
		mob.spawn_position,
		now_msec
	):
		return


	_advance_mob_along_path(
		mob,
		delta
	)


# =========================================================
# NAVIGATION PATH
# =========================================================

func _ensure_navigation_path(
	mob: WorldMobRuntimeState,
	target_position: Vector3,
	now_msec: int
) -> bool:
	if mob == null:
		return false


	var runtime := (
		mob.combat_runtime
	)


	if not runtime.should_repath(
		now_msec
	):
		return true


	var resolution := (
		world_navigation_registry
		.resolve_reachable_target(
			mob.map_id,
			mob.position,
			target_position
		)
	)


	if not bool(
		resolution.get(
			"ok",
			false
		)
	):
		return false


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
		return false


	var path: PackedVector3Array = (
		path_value
	)


	if path.is_empty():
		return false


	return runtime.set_navigation_path(
		path,
		now_msec
		+
		REPATH_INTERVAL_MSEC
	)


# =========================================================
# MOVE MOB
# =========================================================

func _advance_mob_along_path(
	mob: WorldMobRuntimeState,
	delta: float
) -> bool:
	if mob == null:
		return false


	if mob.combat_runtime == null:
		return false


	if not mob.combat_runtime.has_navigation_path():
		return false


	var remaining_distance := (
		mob.definition.combat_movement_speed
		*
		delta
	)


	var moved := false


	while (
		remaining_distance > 0.0

		and

		mob.combat_runtime.has_navigation_path()
	):
		var waypoint: Vector3 = (
			mob.combat_runtime.navigation_path[
				mob.combat_runtime.navigation_path_index
			]
		)


		var current_position_2d := Vector2(
			mob.position.x,
			mob.position.z
		)


		var waypoint_position_2d := Vector2(
			waypoint.x,
			waypoint.z
		)


		var distance_to_waypoint := (
			current_position_2d.distance_to(
				waypoint_position_2d
			)
		)


		if (
			distance_to_waypoint
			<=
			WAYPOINT_REACHED_DISTANCE
		):
			mob.combat_runtime.navigation_path_index += 1

			continue


		var direction := (
			waypoint_position_2d
			-
			current_position_2d
		)


		var next_rotation_y := (
			mob.rotation_y
		)


		if (
			direction.length_squared()
			>
			MIN_DIRECTION_LENGTH_SQUARED
		):
			next_rotation_y = atan2(
				-direction.x,
				-direction.y
			)


		var step_distance := minf(
			remaining_distance,
			distance_to_waypoint
		)


		var next_position_2d := (
			current_position_2d.move_toward(
				waypoint_position_2d,
				step_distance
			)
		)


		mob.set_world_transform(
			Vector3(
				next_position_2d.x,
				mob.position.y,
				next_position_2d.y
			),
			next_rotation_y
		)


		moved = true


		remaining_distance -= (
			step_distance
		)


		if (
			step_distance
			>=
			distance_to_waypoint
			-
			WAYPOINT_REACHED_DISTANCE
		):
			mob.combat_runtime.navigation_path_index += 1


	if (
		not mob.combat_runtime.has_navigation_path()
	):
		mob.combat_runtime.clear_navigation()


	return moved


# =========================================================
# FACE TARGET
# =========================================================

func _face_mob_toward(
	mob: WorldMobRuntimeState,
	target_position: Vector3
) -> void:
	var direction := Vector2(
		target_position.x - mob.position.x,
		target_position.z - mob.position.z
	)


	if (
		direction.length_squared()
		<=
		MIN_DIRECTION_LENGTH_SQUARED
	):
		return


	mob.rotation_y = atan2(
		-direction.x,
		-direction.y
	)


# =========================================================
# MOB ATTACK
# =========================================================

func _try_mob_attack(
	mob: WorldMobRuntimeState,
	session: PlayerWorldSession,
	now_msec: int
) -> void:
	var runtime := (
		mob.combat_runtime
	)


	if not runtime.can_attack(
		now_msec
	):
		return


	if not runtime.start_attack_cooldown(
		mob.definition.attack_cooldown_seconds,
		now_msec
	):
		return


	var equipment_snapshot := (
		session.get_equipment_snapshot()
	)


	if equipment_snapshot.is_empty():
		runtime.reset_attack_cooldown()

		return


	var attacker_hit_profile := (
		ServerMobCombatHitProfileResolver
		.resolve(
			mob.definition
		)
	)


	var defender_hit_profile := (
		ServerCharacterCombatHitProfileResolver
		.resolve(
			session.primary_stats,
			equipment_snapshot
		)
	)


	var defender_damage_profile := (
		ServerCharacterDamageDefenseProfileResolver
		.resolve(
			equipment_snapshot
		)
	)


	var damage_context := (
		ServerMobBasicAttackRules
		.build_resolution_context(
			mob.definition
		)
	)


	if (
		attacker_hit_profile == null
		or
		defender_hit_profile == null
		or
		defender_damage_profile == null
		or
		damage_context == null
	):
		runtime.reset_attack_cooldown()

		return


	var hit_roll := randf()

	var dodge_roll := randf()

	var block_roll := randf()


	var hit_resolution := (
		ServerHitResolutionRules.resolve(
			attacker_hit_profile,
			defender_hit_profile,
			hit_roll,
			dodge_roll,
			block_roll
		)
	)


	if hit_resolution == null:
		runtime.reset_attack_cooldown()

		return


	if not hit_resolution.deals_damage():
		print(
			"MobCombatCoordinator | Mob Attack resuelto sin daño",
			" | Entity: ",
			mob.entity_id,
			" | Target: ",
			session.character_name,
			" | Accuracy: ",
			attacker_hit_profile.accuracy_rating,
			" | Evasion: ",
			defender_hit_profile.evasion_rating,
			" | Hit Chance: ",
			hit_resolution.hit_chance,
			" | Hit Roll: ",
			hit_resolution.hit_roll,
			" | Dodge Chance: ",
			hit_resolution.dodge_chance,
			" | Dodge Roll: ",
			hit_resolution.dodge_roll,
			" | Outcome: ",
			hit_resolution.outcome
		)


		return


	var damage_resolution := (
		ServerDamageResolver.resolve(
			damage_context,
			defender_damage_profile,
			0.0,
			1.5,
			0.0,
			hit_resolution.damage_multiplier
		)
	)


	if damage_resolution == null:
		runtime.reset_attack_cooldown()

		return


	var applied_damage := (
		session.vitals.apply_damage(
			damage_resolution.final_damage
		)
	)


	if applied_damage <= 0:
		return

	player_damaged_by_mob.emit(
		session.peer_id,
		mob.entity_id,
		applied_damage
	)


	_send_player_vitals(
		session
	)


	print(
		"MobCombatCoordinator | Mob Attack ejecutado",
		" | Entity: ",
		mob.entity_id,
		" | Mob: ",
		mob.definition.display_name,
		" | Target: ",
		session.character_name,
		" | Accuracy: ",
		attacker_hit_profile.accuracy_rating,
		" | Evasion: ",
		defender_hit_profile.evasion_rating,
		" | Hit Chance: ",
		hit_resolution.hit_chance,
		" | Hit Roll: ",
		hit_resolution.hit_roll,
		" | Dodge Chance: ",
		hit_resolution.dodge_chance,
		" | Dodge Roll: ",
		hit_resolution.dodge_roll,
		" | Block Chance: ",
		hit_resolution.block_chance,
		" | Block Roll: ",
		hit_resolution.block_roll,
		" | Outcome: ",
		hit_resolution.outcome,
		" | Raw Damage: ",
		damage_resolution.raw_damage,
		" | Outcome Multiplier: ",
		hit_resolution.damage_multiplier,
		" | Post Outcome: ",
		damage_resolution.post_outcome_damage,
		" | Armor: ",
		damage_resolution.school_rating,
		" | Final Damage: ",
		damage_resolution.final_damage,
		" | Applied Damage: ",
		applied_damage,
		" | HP: ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp
	)


	if session.vitals.hp <= 0:
		_handle_player_death(
			session,
			mob,
			now_msec
		)


# =========================================================
# PLAYER VITALS
# =========================================================

func _send_player_vitals(
	session: PlayerWorldSession
) -> void:
	var result := (
		game_server.send_character_vitals_updated(
			session.peer_id,
			session.character_id,
			session.vitals.to_snapshot()
		)
	)


	if result != OK:
		push_warning(
			(
				"MobCombatCoordinator | "
				+
				"No se pudieron replicar Player Vitals."
			)
		)


# =========================================================
# PLAYER DEATH
# =========================================================

func _handle_player_death(
	session: PlayerWorldSession,
	mob: WorldMobRuntimeState,
	now_msec: int
) -> void:
	if pending_player_respawns.has(
		session.peer_id
	):
		return


	session.clear_move_request()


	pending_player_respawns[
		session.peer_id
	] = (
		now_msec
		+
		PLAYER_RESPAWN_DELAY_MSEC
	)

	player_died.emit(
		session.peer_id
	)


	_replicate_player_transform(
		session
	)


	_release_mobs_targeting_peer(
		session.peer_id
	)


	print(
		"MobCombatCoordinator | Jugador derrotado",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | Killer: ",
		mob.entity_id,
		" | Respawn: ",
		PLAYER_RESPAWN_DELAY_SECONDS,
		" s"
	)


# =========================================================
# PLAYER RESPAWN
# =========================================================

func _process_player_respawns(
	now_msec: int
) -> void:
	var due_peer_ids: Array[int] = []


	for raw_peer_id: Variant in (
		pending_player_respawns.keys()
	):
		var peer_id := int(
			raw_peer_id
		)


		var deadline := int(
			pending_player_respawns[
				peer_id
			]
		)


		if now_msec < deadline:
			continue


		due_peer_ids.append(
			peer_id
		)


	for peer_id: int in due_peer_ids:
		pending_player_respawns.erase(
			peer_id
		)


		var session := (
			world_session_registry.get_session(
				peer_id
			)
		)


		if session == null:
			continue


		if session.vitals.hp > 0:
			continue


		session.vitals.set_hp(
			session.vitals.max_hp
		)


		session.vitals.set_mp(
			session.vitals.max_mp
		)


		session.position = (
			WorldSessionRegistry
			.DEFAULT_SPAWN_POSITION
		)


		session.rotation_y = (
			WorldSessionRegistry
			.DEFAULT_SPAWN_ROTATION_Y
		)


		session.clear_move_request()

		player_respawned.emit(
			session.peer_id
		)

		_send_player_vitals(
			session
		)


		_replicate_player_transform(
			session
		)


		print(
			"MobCombatCoordinator | Jugador respawneado",
			" | Peer: ",
			session.peer_id,
			" | Personaje: ",
			session.character_name,
			" | Posición: ",
			session.position,
			" | HP: ",
			session.vitals.hp,
			"/",
			session.vitals.max_hp,
			" | MP: ",
			session.vitals.mp,
			"/",
			session.vitals.max_mp
		)


# =========================================================
# RELEASE MOBS TARGETING PLAYER
# =========================================================

func _release_mobs_targeting_peer(
	peer_id: int
) -> void:
	for mob: WorldMobRuntimeState in (
		world_mob_registry.get_all_mobs()
	):
		if mob == null:
			continue


		if mob.combat_runtime == null:
			continue


		if (
			mob.combat_runtime.target_peer_id
			!=
			peer_id
		):
			continue


		_release_target_and_return(
			mob,
			"target_dead"
		)


# =========================================================
# PLAYER TRANSFORM REPLICATION
# =========================================================

func _replicate_player_transform(
	session: PlayerWorldSession
) -> void:
	var target_peer_ids: Array[int] = [
		session.peer_id
	]


	for remote_session: PlayerWorldSession in (
		world_session_registry.get_sessions_in_map(
			session.map_id,
			session.peer_id
		)
	):
		if remote_session == null:
			continue


		target_peer_ids.append(
			remote_session.peer_id
		)


	var result := (
		game_server.send_movement_state_to_peers(
			session.peer_id,
			target_peer_ids,
			session.position,
			session.rotation_y,
			false
		)
	)


	if result != OK:
		push_warning(
			(
				"MobCombatCoordinator | "
				+
				"No se pudo replicar Player Transform."
			)
		)


# =========================================================
# MOB NETWORK SAMPLE
# =========================================================

func _replicate_moving_mobs() -> void:
	for mob: WorldMobRuntimeState in (
		world_mob_registry.get_all_mobs()
	):
		if mob == null:
			continue


		if not mob.is_alive():
			continue


		if mob.combat_runtime == null:
			continue


		if (
			mob.combat_runtime.state
			!=
			WorldMobCombatRuntime.STATE_CHASING

			and

			mob.combat_runtime.state
			!=
			WorldMobCombatRuntime.STATE_RETURNING
		):
			continue


		_broadcast_mob_state(
			mob
		)


func _broadcast_mob_state(
	mob: WorldMobRuntimeState
) -> void:
	var snapshot := (
		mob.to_snapshot()
	)


	if snapshot.is_empty():
		return


	for session: PlayerWorldSession in (
		world_session_registry.get_sessions_in_map(
			mob.map_id
		)
	):
		if session == null:
			continue


		var result := (
			game_server.send_mob_state_updated(
				session.peer_id,
				snapshot
			)
		)


		if result != OK:
			continue
