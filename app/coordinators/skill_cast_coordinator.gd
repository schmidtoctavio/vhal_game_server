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


	var target_kind := String(
		target.get(
			"kind",
			""
		)
	).strip_edges().to_lower()


	# -----------------------------------------------------
	# F16-B
	#
	# El único target soportado por esta etapa es self.
	#
	# Esto NO ejecuta la skill.
	# Esto NO valida mana.
	# Esto NO valida cooldown.
	# Esto NO modifica HP/MP.
	# -----------------------------------------------------

	if target_kind != "self":
		print(
			"SkillCastCoordinator | Target todavía no soportado",
			" | Request: ",
			request_id,
			" | Peer: ",
			peer_id,
			" | Skill: ",
			skill_id,
			" | Target: ",
			target_kind
		)


		return


	print(
		"SkillCastCoordinator | Intención de cast recibida",
		" | Request: ",
		request_id,
		" | Peer: ",
		peer_id,
		" | Personaje: ",
		session.character_name,
		" | Skill: ",
		skill_id,
		" | Target: ",
		target_kind,
		" | HP: ",
		session.vitals.hp,
		"/",
		session.vitals.max_hp,
		" | MP: ",
		session.vitals.mp,
		"/",
		session.vitals.max_mp
	)
