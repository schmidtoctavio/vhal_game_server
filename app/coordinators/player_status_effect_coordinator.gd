class_name PlayerStatusEffectCoordinator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal player_periodic_damage_applied(
	attacker_peer_id: int,
	target_peer_id: int,
	effect_id: String,
	applied_damage: int
)


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null


# =========================================================
# SCHEDULER
# =========================================================

var status_effect_timer: Timer = null

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry
) -> bool:
	if configured:
		return true


	if p_game_server == null:
		return false


	if p_world_session_registry == null:
		return false


	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)


	if not _prepare_status_effect_scheduler():
		return false


	configured = true


	print(
		"PlayerStatusEffectCoordinator | Inicializado."
	)


	return true


# =========================================================
# PREPARAR SCHEDULER
# =========================================================

func _prepare_status_effect_scheduler() -> bool:
	if (
		status_effect_timer == null
		or
		not is_instance_valid(
			status_effect_timer
		)
	):
		status_effect_timer = Timer.new()

		status_effect_timer.name = (
			"StatusEffectTimer"
		)

		status_effect_timer.one_shot = true

		add_child(
			status_effect_timer
		)


	if not status_effect_timer.timeout.is_connected(
		_on_status_effect_timer_timeout
	):
		status_effect_timer.timeout.connect(
			_on_status_effect_timer_timeout
		)


	status_effect_timer.stop()


	return true


# =========================================================
# APLICAR STATUS EFFECT A PLAYER
# =========================================================

func apply_status_effect_to_player(
	target_peer_id: int,
	status_effect: ServerStatusEffectRuntime
) -> Dictionary:
	var session := (
		world_session_registry.get_session(
			target_peer_id
		)
	)


	if session == null:
		return {
			"ok": false,
		}


	if (
		session.vitals == null
		or
		not session.vitals.is_valid()
		or
		session.vitals.hp <= 0
	):
		return {
			"ok": false,
		}


	if status_effect == null:
		return {
			"ok": false,
		}


	var now_msec := (
		Time.get_ticks_msec()
	)


	var application := (
		session.apply_status_effect(
			status_effect,
			now_msec
		)
	)


	if not bool(
		application.get(
			"ok",
			false
		)
	):
		return application


	var applied_value: Variant = (
		application.get(
			"status_effect",
			null
		)
	)


	var applied_status := (
		applied_value
		as
		ServerStatusEffectRuntime
	)


	print(
		"PlayerStatusEffectCoordinator | Status Effect resuelto",
		" | Target Peer: ",
		target_peer_id,
		" | Personaje: ",
		session.character_name,
		" | Effect: ",
		status_effect.effect_id,
		" | Category: ",
		status_effect.category,
		" | Operation: ",
		String(
			application.get(
				"operation",
				""
			)
		),
		" | Changed: ",
		bool(
			application.get(
				"changed",
				false
			)
		),
		" | Stacks: ",
		(
			applied_status.stack_count
			if applied_status != null
			else 0
		)
	)


	_arm_next_status_effect_deadline()


	return application


# =========================================================
# ARMAR PRÓXIMO DEADLINE
# =========================================================

func _arm_next_status_effect_deadline() -> void:
	if status_effect_timer == null:
		return


	var nearest_deadline_msec := 0


	for session: PlayerWorldSession in (
		world_session_registry.get_all_sessions()
	):
		if session == null:
			continue


		if (
			session.vitals == null
			or
			session.vitals.hp <= 0
		):
			continue


		for status_effect: ServerStatusEffectRuntime in (
			session.get_status_effects()
		):
			if status_effect == null:
				continue


			var deadline := (
				status_effect.get_next_deadline_msec()
			)


			if deadline <= 0:
				continue


			if (
				nearest_deadline_msec == 0
				or
				deadline < nearest_deadline_msec
			):
				nearest_deadline_msec = deadline


	if nearest_deadline_msec <= 0:
		status_effect_timer.stop()

		return


	var remaining_msec := maxi(
		nearest_deadline_msec
		-
		Time.get_ticks_msec(),
		1
	)


	status_effect_timer.start(
		float(remaining_msec)
		/
		1000.0
	)


# =========================================================
# DEADLINE
# =========================================================

func _on_status_effect_timer_timeout() -> void:
	var now_msec := (
		Time.get_ticks_msec()
	)


	for session: PlayerWorldSession in (
		world_session_registry.get_all_sessions()
	):
		if session == null:
			continue


		if (
			session.vitals == null
			or
			session.vitals.hp <= 0
		):
			session.clear_status_effects()

			continue


		var status_effects := (
			session.get_status_effects()
		)


		for status_effect: ServerStatusEffectRuntime in (
			status_effects
		):
			if status_effect == null:
				continue


			if status_effect.is_periodic_damage():
				while (
					session.vitals.hp > 0
					and
					status_effect.is_due(
						now_msec
					)
				):
					if not _process_periodic_status_tick(
						session,
						status_effect,
						now_msec
					):
						break


				if session.vitals.hp <= 0:
					session.clear_status_effects()

					break


			if (
				status_effect.is_periodic_finished()
				or
				status_effect.is_expired(
					now_msec
				)
			):
				_expire_status_effect(
					session,
					status_effect,
					now_msec
				)


	_arm_next_status_effect_deadline()


# =========================================================
# PERIODIC DAMAGE
# =========================================================

func _process_periodic_status_tick(
	target_session: PlayerWorldSession,
	status_effect: ServerStatusEffectRuntime,
	now_msec: int
) -> bool:
	if target_session == null:
		return false


	if status_effect == null:
		return false


	if not status_effect.is_periodic_damage():
		return false


	if status_effect.damage_context == null:
		_remove_invalid_status_effect(
			target_session,
			status_effect
		)


		return false


	var equipment_snapshot := (
		target_session.get_equipment_snapshot()
	)


	if equipment_snapshot.is_empty():
		_remove_invalid_status_effect(
			target_session,
			status_effect
		)


		return false


	var defense_profile := (
		ServerCharacterDamageDefenseProfileResolver
		.resolve(
			equipment_snapshot
		)
	)


	if (
		defense_profile == null
		or
		not defense_profile.is_valid()
	):
		_remove_invalid_status_effect(
			target_session,
			status_effect
		)


		return false


	var damage_resolution := (
		ServerDamageResolver.resolve(
			status_effect.damage_context,
			defense_profile
		)
	)


	if (
		damage_resolution == null
		or
		not damage_resolution.is_valid()
	):
		_remove_invalid_status_effect(
			target_session,
			status_effect
		)


		return false


	if not status_effect.consume_due_tick(
		now_msec
	):
		return false


	var applied_damage := (
		target_session.vitals.apply_damage(
			damage_resolution.final_damage
		)
	)


	if applied_damage <= 0:
		return false


	_send_player_vitals(
		target_session
	)


	var attacker_peer_id := int(
		status_effect.source.get(
			"peer_id",
			-1
		)
	)


	if attacker_peer_id > 1:
		player_periodic_damage_applied.emit(
			attacker_peer_id,
			target_session.peer_id,
			status_effect.effect_id,
			applied_damage
		)


	print(
		"PlayerStatusEffectCoordinator | Status Effect Tick",
		" | Target Peer: ",
		target_session.peer_id,
		" | Personaje: ",
		target_session.character_name,
		" | Effect: ",
		status_effect.effect_id,
		" | Raw Damage: ",
		damage_resolution.raw_damage,
		" | School: ",
		damage_resolution.school,
		" | Element: ",
		damage_resolution.element,
		" | Final Damage: ",
		damage_resolution.final_damage,
		" | Applied Damage: ",
		applied_damage,
		" | Ticks restantes: ",
		status_effect.ticks_remaining,
		" | HP: ",
		target_session.vitals.hp,
		"/",
		target_session.vitals.max_hp
	)


	return true


# =========================================================
# EXPIRAR
# =========================================================

func _expire_status_effect(
	session: PlayerWorldSession,
	status_effect: ServerStatusEffectRuntime,
	now_msec: int
) -> void:
	if session == null:
		return


	if status_effect == null:
		return


	if status_effect.is_hard_control():
		session.begin_hard_control_immunity(
			now_msec
		)


	var removed := (
		session.remove_status_effect_by_key(
			status_effect.runtime_key
		)
	)


	if removed == null:
		return


	print(
		"PlayerStatusEffectCoordinator | Status Effect expirado",
		" | Target Peer: ",
		session.peer_id,
		" | Personaje: ",
		session.character_name,
		" | Effect: ",
		status_effect.effect_id,
		" | Category: ",
		status_effect.category
	)


# =========================================================
# REMOVE INVALID
# =========================================================

func _remove_invalid_status_effect(
	session: PlayerWorldSession,
	status_effect: ServerStatusEffectRuntime
) -> void:
	if session == null:
		return


	if status_effect == null:
		return


	session.remove_status_effect_by_key(
		status_effect.runtime_key
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
			"PlayerStatusEffectCoordinator | "
			+
			"No se pudieron replicar Vitals. Error: %d"
		)
		%
		result
	)
