class_name CharacterRegenCoordinator
extends Node


# =========================================================
# POLICY — F26-E
# =========================================================

const REGEN_TICK_INTERVAL_SECONDS: float = 1.0

const COMBAT_EXIT_DELAY_SECONDS: float = 5.0

const COMBAT_EXIT_DELAY_MSEC: int = 5000


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

var basic_attack_coordinator: BasicAttackCoordinator = null

var skill_cast_coordinator: SkillCastCoordinator = null

var player_status_effect_coordinator: PlayerStatusEffectCoordinator = null

var mob_combat_coordinator: MobCombatCoordinator = null


# =========================================================
# RUNTIME
#
# peer_id -> last_hostile_activity_msec
#
# Este estado existe solamente dentro del Game Server.
# No forma parte del checkpoint durable de HP/MP.
# =========================================================

var combat_last_hostile_activity_msec: Dictionary = {}

var active_hostile_mobs_by_peer: Dictionary = {}

var regen_tick_accumulator: float = 0.0

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_mob_registry: WorldMobRegistry,
	p_basic_attack_coordinator: BasicAttackCoordinator,
	p_skill_cast_coordinator: SkillCastCoordinator,
	p_player_status_effect_coordinator: PlayerStatusEffectCoordinator,
	p_mob_combat_coordinator: MobCombatCoordinator
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	if p_world_mob_registry == null:
		return false


	if p_basic_attack_coordinator == null:
		return false

	if p_skill_cast_coordinator == null:
		return false


	if p_player_status_effect_coordinator == null:
		return false

	if p_mob_combat_coordinator == null:
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)

	world_mob_registry = (
		p_world_mob_registry
	)

	basic_attack_coordinator = (
		p_basic_attack_coordinator
	)

	skill_cast_coordinator = (
		p_skill_cast_coordinator
	)


	player_status_effect_coordinator = (
		p_player_status_effect_coordinator
	)

	mob_combat_coordinator = (
		p_mob_combat_coordinator
	)


	if not world_session_registry.session_removed.is_connected(
		_on_session_removed
	):
		world_session_registry.session_removed.connect(
			_on_session_removed
		)


	if not world_mob_registry.mob_damaged.is_connected(
		_on_world_mob_damaged
	):
		world_mob_registry.mob_damaged.connect(
			_on_world_mob_damaged
		)


	if not world_mob_registry.mob_died.is_connected(
		_on_world_mob_died
	):
		world_mob_registry.mob_died.connect(
			_on_world_mob_died
		)


	if not (
		basic_attack_coordinator
		.valid_offensive_action_against_mob
		.is_connected(
			_on_valid_offensive_action_against_mob
		)
	):
		(
			basic_attack_coordinator
			.valid_offensive_action_against_mob
			.connect(
				_on_valid_offensive_action_against_mob
			)
		)

	if not (
		basic_attack_coordinator
		.valid_offensive_action_against_player
		.is_connected(
			_on_valid_offensive_action_against_player
		)
	):
		(
			basic_attack_coordinator
			.valid_offensive_action_against_player
			.connect(
				_on_valid_offensive_action_against_player
			)
		)

	if not (
		skill_cast_coordinator
		.valid_offensive_skill_against_player
		.is_connected(
			_on_valid_offensive_skill_against_player
		)
	):
		(
			skill_cast_coordinator
			.valid_offensive_skill_against_player
			.connect(
				_on_valid_offensive_skill_against_player
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

	if not mob_combat_coordinator.player_mob_aggro_acquired.is_connected(
		_on_player_mob_aggro_acquired
	):
		mob_combat_coordinator.player_mob_aggro_acquired.connect(
			_on_player_mob_aggro_acquired
		)


	if not mob_combat_coordinator.player_mob_aggro_released.is_connected(
		_on_player_mob_aggro_released
	):
		mob_combat_coordinator.player_mob_aggro_released.connect(
			_on_player_mob_aggro_released
		)


	if not mob_combat_coordinator.player_damaged_by_mob.is_connected(
		_on_player_damaged_by_mob
	):
		mob_combat_coordinator.player_damaged_by_mob.connect(
			_on_player_damaged_by_mob
		)


	if not mob_combat_coordinator.player_died.is_connected(
		_on_player_died
	):
		mob_combat_coordinator.player_died.connect(
			_on_player_died
		)


	if not mob_combat_coordinator.player_respawned.is_connected(
		_on_player_respawned
	):
		mob_combat_coordinator.player_respawned.connect(
			_on_player_respawned
		)


	configured = true


	print(
		"CharacterRegenCoordinator | Inicializado",
		" | Regen tick: ",
		REGEN_TICK_INTERVAL_SECONDS,
		" s",
		" | Combat timeout: ",
		COMBAT_EXIT_DELAY_SECONDS,
		" s"
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


	_update_combat_timeouts(
		now_msec
	)


	regen_tick_accumulator += (
		delta
	)


	if (
		regen_tick_accumulator
		<
		REGEN_TICK_INTERVAL_SECONDS
	):
		return


	regen_tick_accumulator = fmod(
		regen_tick_accumulator,
		REGEN_TICK_INTERVAL_SECONDS
	)


	_process_regen_tick()


# =========================================================
# REGEN TICK
# =========================================================

func _process_regen_tick() -> void:
	for session: PlayerWorldSession in (
		world_session_registry.get_all_sessions()
	):
		_apply_regen_to_session(
			session
		)


func _apply_regen_to_session(
	session: PlayerWorldSession
) -> void:
	if session == null:
		return


	if session.peer_id <= 1:
		return


	if session.vitals == null:
		return


	if not session.vitals.is_valid():
		return


	# Muerto = sin regeneración.

	if session.vitals.hp <= 0:
		return


	# F26-E: HP y MP regeneran solamente fuera de combate.

	if _is_in_combat(
		session.peer_id
	):
		return


	if session.derived_stats == null:
		return


	if not session.derived_stats.is_valid():
		return


	var hp_regeneration := (
		session.derived_stats.hp_regeneration
	)


	var mp_regeneration := (
		session.derived_stats.mp_regeneration
	)


	if (
		hp_regeneration <= 0
		and
		mp_regeneration <= 0
	):
		return


	var previous_hp := (
		session.vitals.hp
	)


	var previous_mp := (
		session.vitals.mp
	)


	var restored_hp := 0

	var restored_mp := 0


	if (
		hp_regeneration > 0
		and
		session.vitals.hp < session.vitals.max_hp
	):
		restored_hp = (
			session.vitals.restore_hp(
				hp_regeneration
			)
		)


	if (
		mp_regeneration > 0
		and
		session.vitals.mp < session.vitals.max_mp
	):
		restored_mp = (
			session.vitals.restore_mp(
				mp_regeneration
			)
		)


	# No hubo mutación real: no emitimos paquete ni log.

	if (
		restored_hp <= 0
		and
		restored_mp <= 0
	):
		return


	_send_player_vitals(
		session
	)


	print(
		"CharacterRegenCoordinator | Regen tick",
		" | Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | HP: ",
		previous_hp,
		" -> ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp,
		" | HP Regen: ",
		hp_regeneration,
		" | MP: ",
		previous_mp,
		" -> ",
		session.vitals.mp,
		"/",
		session.vitals.max_mp,
		" | MP Regen: ",
		mp_regeneration
	)


# =========================================================
# COMBAT ACTIVITY
# =========================================================

func _register_hostile_activity(
	peer_id: int,
	reason: String
) -> void:
	if peer_id <= 1:
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


	if session.vitals.hp <= 0:
		return


	var entered_combat := (
		not combat_last_hostile_activity_msec.has(
			peer_id
		)
	)


	combat_last_hostile_activity_msec[
		peer_id
	] = Time.get_ticks_msec()


	if not entered_combat:
		return


	print(
		"CharacterRegenCoordinator | Combat entered",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Reason: ",
		reason
	)


func _update_combat_timeouts(
	now_msec: int
) -> void:
	for raw_peer_id: Variant in (
		combat_last_hostile_activity_msec.keys()
	):
		var peer_id := int(
			raw_peer_id
		)


		var session := (
			world_session_registry.get_session(
				peer_id
			)
		)


		if session == null:
			_clear_combat_state(
				peer_id,
				"session_missing",
				false
			)

			continue


		if (
			session.vitals == null
			or
			session.vitals.hp <= 0
		):
			_clear_combat_state(
				peer_id,
				"dead",
				true
			)

			continue


		# Mientras un mob conserve aggro autoritativo sobre el
		# personaje, continúa en combate aunque no haya recibido
		# daño durante los últimos segundos.

		if _has_active_hostile_mob(
			peer_id
		):
			continue


		var last_activity_msec := int(
			combat_last_hostile_activity_msec[
				peer_id
			]
		)


		if (
			now_msec
			-
			last_activity_msec
			<
			COMBAT_EXIT_DELAY_MSEC
		):
			continue


		_clear_combat_state(
			peer_id,
			"timeout",
			true
		)


func _clear_combat_state(
	peer_id: int,
	reason: String,
	log_transition: bool
) -> void:
	var had_combat_state := (
		combat_last_hostile_activity_msec.has(
			peer_id
		)
		or
		active_hostile_mobs_by_peer.has(
			peer_id
		)
	)


	combat_last_hostile_activity_msec.erase(
		peer_id
	)

	active_hostile_mobs_by_peer.erase(
		peer_id
	)


	if not had_combat_state:
		return


	if not log_transition:
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	print(
		"CharacterRegenCoordinator | Combat ended",
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		(
			session.character_name
			if
			session != null
			else
			"?"
		),
		" | Reason: ",
		reason
	)


func _is_in_combat(
	peer_id: int
) -> bool:
	return (
		combat_last_hostile_activity_msec.has(
			peer_id
		)
		or
		_has_active_hostile_mob(
			peer_id
		)
	)


# =========================================================
# AUTORITATIVE COMBAT HOOKS
# =========================================================

func _on_valid_offensive_action_against_mob(
	peer_id: int,
	entity_id: String
) -> void:
	_register_hostile_activity(
		peer_id,
		(
			"basic_attack:"
			+
			entity_id
		)
	)

func _on_valid_offensive_action_against_player(
	attacker_peer_id: int,
	target_peer_id: int
) -> void:
	_register_hostile_activity(
		attacker_peer_id,
		(
			"pvp_basic_attack:"
			+
			str(
				target_peer_id
			)
		)
	)


	_register_hostile_activity(
		target_peer_id,
		(
			"pvp_targeted_by:"
			+
			str(
				attacker_peer_id
			)
		)
	)

func _on_valid_offensive_skill_against_player(
	attacker_peer_id: int,
	target_peer_id: int,
	skill_id: String
) -> void:
	_register_hostile_activity(
		attacker_peer_id,
		(
			"pvp_skill:"
			+
			skill_id
			+
			":"
			+
			str(target_peer_id)
		)
	)


	_register_hostile_activity(
		target_peer_id,
		(
			"pvp_targeted_by_skill:"
			+
			skill_id
			+
			":"
			+
			str(attacker_peer_id)
		)
	)


func _on_player_periodic_damage_applied(
	attacker_peer_id: int,
	target_peer_id: int,
	effect_id: String,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	_register_hostile_activity(
		target_peer_id,
		(
			"pvp_periodic_received:"
			+
			effect_id
			+
			":"
			+
			str(attacker_peer_id)
		)
	)


	_register_hostile_activity(
		target_peer_id,
		(
			"pvp_periodic_received:"
			+
			effect_id
			+
			":"
			+
			str(attacker_peer_id)
		)
	)

func _on_player_mob_aggro_acquired(
	peer_id: int,
	entity_id: String
) -> void:
	_register_hostile_activity(
		peer_id,
		(
			"mob_aggro:"
			+
			entity_id
		)
	)


	if not combat_last_hostile_activity_msec.has(
		peer_id
	):
		return


	_add_active_hostile_mob(
		peer_id,
		entity_id
	)


func _on_player_mob_aggro_released(
	peer_id: int,
	entity_id: String
) -> void:
	_remove_active_hostile_mob(
		peer_id,
		entity_id
	)


	# El timeout de 5 s comienza desde la última interacción
	# hostil. Liberar aggro es el cierre autoritativo del
	# engagement del mob.

	_register_hostile_activity(
		peer_id,
		(
			"mob_aggro_released:"
			+
			entity_id
		)
	)


func _on_world_mob_damaged(
	entity_id: String,
	_map_id: String,
	source: Dictionary,
	_mob_snapshot: Dictionary,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	var source_peer_id := int(
		source.get(
			"peer_id",
			-1
		)
	)


	if source_peer_id <= 1:
		return


	_register_hostile_activity(
		source_peer_id,
		(
			"mob_damage:"
			+
			entity_id
		)
	)


func _on_world_mob_died(
	entity_id: String,
	_map_id: String,
	_source: Dictionary,
	_mob_snapshot: Dictionary
) -> void:
	for raw_peer_id: Variant in (
		active_hostile_mobs_by_peer.keys()
	):
		var peer_id := int(
			raw_peer_id
		)


		if not _peer_has_active_hostile_mob(
			peer_id,
			entity_id
		):
			continue


		_remove_active_hostile_mob(
			peer_id,
			entity_id
		)


		_register_hostile_activity(
			peer_id,
			(
				"mob_died:"
				+
				entity_id
			)
		)


func _on_player_damaged_by_mob(
	peer_id: int,
	entity_id: String,
	applied_damage: int
) -> void:
	if applied_damage <= 0:
		return


	_register_hostile_activity(
		peer_id,
		(
			"damage_received:"
			+
			entity_id
		)
	)


func _on_player_died(
	peer_id: int
) -> void:
	_clear_combat_state(
		peer_id,
		"death",
		true
	)


func _on_player_respawned(
	peer_id: int
) -> void:
	# Safety reset: nunca conservar un lock previo al respawn.

	_clear_combat_state(
		peer_id,
		"respawn",
		false
	)


func _on_session_removed(
	peer_id: int
) -> void:
	_clear_combat_state(
		peer_id,
		"session_removed",
		false
	)


# =========================================================
# ACTIVE MOB AGGRO RUNTIME
# =========================================================

func _add_active_hostile_mob(
	peer_id: int,
	entity_id: String
) -> void:
	if peer_id <= 1:
		return


	var normalized_entity_id := (
		entity_id.strip_edges().to_lower()
	)


	if normalized_entity_id.is_empty():
		return


	var active_mobs: Dictionary = (
		active_hostile_mobs_by_peer.get(
			peer_id,
			{}
		)
	)


	active_mobs[
		normalized_entity_id
	] = true


	active_hostile_mobs_by_peer[
		peer_id
	] = active_mobs


func _remove_active_hostile_mob(
	peer_id: int,
	entity_id: String
) -> void:
	if not active_hostile_mobs_by_peer.has(
		peer_id
	):
		return


	var normalized_entity_id := (
		entity_id.strip_edges().to_lower()
	)


	var active_mobs_value: Variant = (
		active_hostile_mobs_by_peer[
			peer_id
		]
	)


	if typeof(active_mobs_value) != TYPE_DICTIONARY:
		active_hostile_mobs_by_peer.erase(
			peer_id
		)

		return


	var active_mobs: Dictionary = (
		active_mobs_value as Dictionary
	)


	active_mobs.erase(
		normalized_entity_id
	)


	if active_mobs.is_empty():
		active_hostile_mobs_by_peer.erase(
			peer_id
		)

		return


	active_hostile_mobs_by_peer[
		peer_id
	] = active_mobs


func _has_active_hostile_mob(
	peer_id: int
) -> bool:
	if not active_hostile_mobs_by_peer.has(
		peer_id
	):
		return false


	var active_mobs_value: Variant = (
		active_hostile_mobs_by_peer[
			peer_id
		]
	)


	if typeof(active_mobs_value) != TYPE_DICTIONARY:
		return false


	var active_mobs: Dictionary = (
		active_mobs_value as Dictionary
	)


	return not active_mobs.is_empty()


func _peer_has_active_hostile_mob(
	peer_id: int,
	entity_id: String
) -> bool:
	if not active_hostile_mobs_by_peer.has(
		peer_id
	):
		return false


	var active_mobs_value: Variant = (
		active_hostile_mobs_by_peer[
			peer_id
		]
	)


	if typeof(active_mobs_value) != TYPE_DICTIONARY:
		return false


	var normalized_entity_id := (
		entity_id.strip_edges().to_lower()
	)


	var active_mobs: Dictionary = (
		active_mobs_value as Dictionary
	)


	return active_mobs.has(
		normalized_entity_id
	)


# =========================================================
# VITALS REPLICATION
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
				"CharacterRegenCoordinator | "
				+
				"No se pudieron replicar Player Vitals."
			)
		)
