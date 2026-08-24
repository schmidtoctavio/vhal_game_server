class_name SkillCastCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var game_server: GameServer = null

var world_session_registry: WorldSessionRegistry = null


# =========================================================
# ESTADO
# =========================================================

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


	_bind_signals()


	configured = true


	print(
		"SkillCastCoordinator | Inicializado."
	)


	return true


# =========================================================
# BIND
# =========================================================

func _bind_signals() -> void:
	if not game_server.client_skill_cast_requested.is_connected(
		_on_client_skill_cast_requested
	):
		game_server.client_skill_cast_requested.connect(
			_on_client_skill_cast_requested
		)


# =========================================================
# INTENCIÓN DE CAST
# =========================================================

func _on_client_skill_cast_requested(
	peer_id: int,
	request_id: int,
	skill_id: String,
	target: Dictionary
) -> void:
	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		game_server.reject_authenticated_peer(
			peer_id,
			"No existe una sesión de mundo para el cast."
		)


		return


	# -----------------------------------------------------
	# REQUEST ID
	# -----------------------------------------------------

	if not session.accept_skill_cast_request_id(
		request_id
	):
		_send_result(
			peer_id,
			request_id,
			skill_id,
			false,
			"stale_request",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# DEFINICIÓN AUTORITATIVA
	# -----------------------------------------------------

	var definition := (
		ServerSkillCatalog.get_definition(
			skill_id
		)
	)


	if definition == null:
		_send_result(
			peer_id,
			request_id,
			skill_id,
			false,
			"unknown_skill",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# SKILL APRENDIDA
	# -----------------------------------------------------

	if not session.skill_runtime.has_learned_skill(
		definition.skill_id
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"skill_not_learned",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# F16-C
	#
	# Por ahora sólo Heal posee ejecución real.
	# Fire Ball y Poison entrarán después.
	# -----------------------------------------------------

	if (
		definition.skill_id
		!=
		ServerSkillCatalog.HEAL_ID
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"skill_not_implemented",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# TARGET
	# -----------------------------------------------------

	var target_kind := String(
		target.get(
			"kind",
			""
		)
	).strip_edges().to_lower()


	if target_kind != "self":
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"invalid_target",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# ESTADO VITAL
	# -----------------------------------------------------

	if session.vitals.hp <= 0:
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"character_not_alive",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# COOLDOWN
	# -----------------------------------------------------

	var cooldown_remaining := (
		session
		.skill_runtime
		.get_cooldown_remaining_seconds(
			definition.skill_id
		)
	)


	if cooldown_remaining > 0.0:
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"cooldown_active",
			session,
			cooldown_remaining,
			{}
		)


		return


	# -----------------------------------------------------
	# MANA
	# -----------------------------------------------------

	if not session.vitals.has_enough_mana(
		definition.mana_cost
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"insufficient_mana",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# GASTAR MANA
	# -----------------------------------------------------

	if not session.vitals.spend_mana(
		definition.mana_cost
	):
		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"runtime_failure",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# INICIAR COOLDOWN
	# -----------------------------------------------------

	if not session.skill_runtime.start_cooldown(
		definition.skill_id,
		definition.cooldown_duration
	):
		# Si por alguna razón inesperada no podemos iniciar
		# el cooldown, devolvemos el mana consumido.
		session.vitals.restore_mp(
			definition.mana_cost
		)


		_send_result(
			peer_id,
			request_id,
			definition.skill_id,
			false,
			"runtime_failure",
			session,
			0.0,
			{}
		)


		return


	# -----------------------------------------------------
	# EJECUTAR HEAL
	# -----------------------------------------------------

	var restored_hp := (
		ServerHealEffect.apply(
			session.vitals
		)
	)


	cooldown_remaining = (
		session
		.skill_runtime
		.get_cooldown_remaining_seconds(
			definition.skill_id
		)
	)


	# -----------------------------------------------------
	# RESULTADO AUTORITATIVO
	# -----------------------------------------------------

	_send_result(
		peer_id,
		request_id,
		definition.skill_id,
		true,
		"ok",
		session,
		cooldown_remaining,
		{
			"kind": "heal",
			"amount": restored_hp,
		}
	)


	print(
		"SkillCastCoordinator | Cast autoritativo ejecutado",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Skill: ",
		definition.skill_id,
		" | Heal: ",
		restored_hp,
		" | HP: ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp,
		" | MP: ",
		session.vitals.mp,
		"/",
		session.vitals.max_mp,
		" | Cooldown: ",
		cooldown_remaining
	)


# =========================================================
# ENVIAR RESULTADO
# =========================================================

func _send_result(
	peer_id: int,
	request_id: int,
	skill_id: String,
	accepted: bool,
	reason: String,
	session: PlayerWorldSession,
	cooldown_remaining_seconds: float,
	effect: Dictionary
) -> void:
	if session == null:
		return


	if session.vitals == null:
		return


	var result := (
		game_server.send_skill_cast_result(
			peer_id,
			request_id,
			skill_id,
			accepted,
			reason,
			session.vitals.to_snapshot(),
			cooldown_remaining_seconds,
			effect
		)
	)


	if result != OK:
		push_warning(
			(
				"SkillCastCoordinator | "
				+
				"No se pudo enviar el resultado "
				+
				"del cast al peer %d. Error: %d"
			)
			%
			[
				peer_id,
				result,
			]
		)


		return


	print(
		"SkillCastCoordinator | Resultado enviado",
		" | Request: ",
		request_id,
		" | Skill: ",
		skill_id,
		" | Accepted: ",
		accepted,
		" | Reason: ",
		reason,
		" | Cooldown: ",
		cooldown_remaining_seconds
	)
