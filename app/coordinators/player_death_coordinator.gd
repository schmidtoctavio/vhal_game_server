class_name PlayerDeathCoordinator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal player_died(
	peer_id: int,
	source: Dictionary
)

signal player_respawned(
	peer_id: int
)


# =========================================================
# POLICY
# =========================================================

const PLAYER_RESPAWN_DELAY_SECONDS: float = 3.0

const PLAYER_RESPAWN_DELAY_MSEC: int = 3000


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var character_runtime_state_coordinator: CharacterRuntimeStateCoordinator = null

var basic_attack_coordinator: BasicAttackCoordinator = null

var player_status_effect_coordinator: PlayerStatusEffectCoordinator = null

var mob_combat_coordinator: MobCombatCoordinator = null


# =========================================================
# RUNTIME
# =========================================================

var pending_player_respawns: Dictionary = {}

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_character_runtime_state_coordinator: CharacterRuntimeStateCoordinator,
	p_basic_attack_coordinator: BasicAttackCoordinator,
	p_player_status_effect_coordinator: PlayerStatusEffectCoordinator,
	p_mob_combat_coordinator: MobCombatCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_character_runtime_state_coordinator == null:
		return false


	if p_basic_attack_coordinator == null:
		return false


	if p_player_status_effect_coordinator == null:
		return false


	if p_mob_combat_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	character_runtime_state_coordinator = (
		p_character_runtime_state_coordinator
	)

	basic_attack_coordinator = (
		p_basic_attack_coordinator
	)

	player_status_effect_coordinator = (
		p_player_status_effect_coordinator
	)

	mob_combat_coordinator = (
		p_mob_combat_coordinator
	)


	_bind_signals()


	configured = true


	print(
		"PlayerDeathCoordinator | Inicializado",
		" | Respawn delay: ",
		PLAYER_RESPAWN_DELAY_SECONDS,
		" s"
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not (
		basic_attack_coordinator
		.player_damaged_by_player
		.is_connected(
			_on_player_damaged_by_player
		)
	):
		(
			basic_attack_coordinator
			.player_damaged_by_player
			.connect(
				_on_player_damaged_by_player
			)
		)


	if not (
		player_status_effect_coordinator
		.player_periodic_damage_applied
		.is_connected(
			_on_player_periodic_damage_applied
		)
	):
		(
			player_status_effect_coordinator
			.player_periodic_damage_applied
			.connect(
				_on_player_periodic_damage_applied
			)
		)


	if not (
		mob_combat_coordinator
		.player_damaged_by_mob
		.is_connected(
			_on_player_damaged_by_mob
		)
	):
		(
			mob_combat_coordinator
			.player_damaged_by_mob
			.connect(
				_on_player_damaged_by_mob
			)
		)


	if not world_session_registry.session_removed.is_connected(
		_on_session_removed
	):
		world_session_registry.session_removed.connect(
			_on_session_removed
		)


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


	_process_player_respawns(
		Time.get_ticks_msec()
	)


# =========================================================
# PvP BASIC ATTACK DAMAGE
# =========================================================

func _on_player_damaged_by_player(
	attacker_peer_id: int,
	target_peer_id: int,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	_schedule_player_death_if_needed(
		target_peer_id,
		{
			"kind": "pvp_basic_attack",
			"attacker_peer_id": attacker_peer_id,
		}
	)


# =========================================================
# PvP PERIODIC DAMAGE
# =========================================================

func _on_player_periodic_damage_applied(
	attacker_peer_id: int,
	target_peer_id: int,
	effect_id: String,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	_schedule_player_death_if_needed(
		target_peer_id,
		{
			"kind": "pvp_periodic_damage",
			"attacker_peer_id": attacker_peer_id,
			"effect_id": effect_id,
		}
	)


# =========================================================
# PvE MOB DAMAGE
# =========================================================

func _on_player_damaged_by_mob(
	peer_id: int,
	entity_id: String,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	_schedule_player_death_if_needed(
		peer_id,
		{
			"kind": "mob_attack",
			"entity_id": entity_id,
		}
	)


# =========================================================
# DETECTAR MUERTE
# =========================================================

func _schedule_player_death_if_needed(
	peer_id: int,
	source: Dictionary
) -> void:
	if peer_id <= 1:
		return


	if pending_player_respawns.has(
		peer_id
	):
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return


	if session.vitals == null:
		return


	if not session.vitals.is_valid():
		return


	if session.vitals.hp > 0:
		return


	session.clear_move_request()

	session.clear_status_effects()

	session.end_npc_service()


	pending_player_respawns[
		peer_id
	] = (
		Time.get_ticks_msec()
		+
		PLAYER_RESPAWN_DELAY_MSEC
	)


	player_died.emit(
		peer_id,
		source.duplicate(
			true
		)
	)


	mob_combat_coordinator.release_mobs_targeting_peer(
		peer_id,
		"target_dead"
	)


	_replicate_player_transform(
		session
	)


	print(
		"PlayerDeathCoordinator | Jugador derrotado",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Source: ",
		source,
		" | Respawn: ",
		PLAYER_RESPAWN_DELAY_SECONDS,
		" s"
	)


# =========================================================
# PROCESS RESPAWNS
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


		if session.vitals == null:
			continue


		if session.vitals.hp > 0:
			continue


		_respawn_session(
			session,
			"respawn",
			true,
			true
		)


# =========================================================
# RESPAWN
# =========================================================

func _respawn_session(
	session: PlayerWorldSession,
	reason: String,
	replicate: bool,
	persist: bool
) -> bool:
	if session == null:
		return false


	if session.vitals == null:
		return false


	if not session.vitals.is_valid():
		return false


	if session.vitals.max_hp <= 0:
		return false


	session.vitals.set_hp(
		session.vitals.max_hp
	)


	session.vitals.set_mp(
		session.vitals.max_mp
	)


	session.set_world_transform(
		WorldSessionRegistry.DEFAULT_SPAWN_POSITION,
		WorldSessionRegistry.DEFAULT_SPAWN_ROTATION_Y
	)


	session.clear_move_request()

	session.clear_status_effects()

	session.end_npc_service()


	pending_player_respawns.erase(
		session.peer_id
	)


	if replicate:
		player_respawned.emit(
			session.peer_id
		)


		_send_player_vitals(
			session
		)


		_replicate_player_transform(
			session
		)


	if persist:
		var checkpoint_result := (
			character_runtime_state_coordinator
			.checkpoint_session(
				session,
				reason
			)
		)


		if (
			checkpoint_result != OK
			and
			checkpoint_result != ERR_BUSY
		):
			push_warning(
				(
					"PlayerDeathCoordinator | "
					+
					"No se pudo iniciar checkpoint "
					+
					"de respawn. Error: %d"
				)
				%
				checkpoint_result
			)


	print(
		"PlayerDeathCoordinator | Jugador respawneado",
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
		session.vitals.max_mp,
		" | Reason: ",
		reason
	)


	return true


# =========================================================
# DISCONNECT SAFETY
# =========================================================

func prepare_session_for_disconnect(
	session: PlayerWorldSession
) -> bool:
	if session == null:
		return false


	if session.vitals == null:
		return false


	if session.vitals.hp > 0:
		return false


	pending_player_respawns.erase(
		session.peer_id
	)


	var recovered := (
		_respawn_session(
			session,
			"disconnect_recovery",
			false,
			false
		)
	)


	if not recovered:
		return false


	print(
		"PlayerDeathCoordinator | "
		+
		"Estado muerto normalizado antes de persistir",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name
	)


	return true


# =========================================================
# SESSION REMOVED
# =========================================================

func _on_session_removed(
	peer_id: int
) -> void:
	pending_player_respawns.erase(
		peer_id
	)


# =========================================================
# SEND VITALS
# =========================================================

func _send_player_vitals(
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


	if session.vitals == null:
		return


	var result := (
		game_server.send_character_vitals_updated(
			session.peer_id,
			session.character_id,
			session.vitals.to_snapshot()
		)
	)


	if result == OK:
		return


	push_warning(
		(
			"PlayerDeathCoordinator | "
			+
			"No se pudieron replicar Vitals. Error: %d"
		)
		%
		result
	)


# =========================================================
# REPLICAR TRANSFORM
# =========================================================

func _replicate_player_transform(
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


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


	if result == OK:
		return


	push_warning(
		(
			"PlayerDeathCoordinator | "
			+
			"No se pudo replicar Player Transform."
		)
	)
