class_name CharacterProgressionCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var world_session_registry: WorldSessionRegistry = null

var world_mob_registry: WorldMobRegistry = null

var progression_repository: BackendCharacterProgressionRepository = null

var game_server: GameServer = null

# =========================================================
# PENDING
# =========================================================

var pending_by_peer: Dictionary = {}

var queued_experience_by_peer: Dictionary = {}


var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_game_server: GameServer,
	p_world_session_registry: WorldSessionRegistry,
	p_world_mob_registry: WorldMobRegistry,
	p_progression_repository: BackendCharacterProgressionRepository
) -> bool:
	if configured:
		return true


	if (
		p_game_server == null
		or
		p_world_session_registry == null
		or
		p_world_mob_registry == null
		or
		p_progression_repository == null
	):
		return false

	game_server = p_game_server

	world_session_registry = (
		p_world_session_registry
	)


	world_mob_registry = (
		p_world_mob_registry
	)


	progression_repository = (
		p_progression_repository
	)


	if not world_mob_registry.mob_died.is_connected(
		_on_mob_died
	):
		world_mob_registry.mob_died.connect(
			_on_mob_died
		)


	if not progression_repository.progression_persisted.is_connected(
		_on_progression_persisted
	):
		progression_repository.progression_persisted.connect(
			_on_progression_persisted
		)


	if not progression_repository.progression_persist_failed.is_connected(
		_on_progression_persist_failed
	):
		progression_repository.progression_persist_failed.connect(
			_on_progression_persist_failed
		)


	configured = true


	print(
		"CharacterProgressionCoordinator | Inicializado."
	)


	return true


# =========================================================
# MOB DIED
# =========================================================

func _on_mob_died(
	entity_id: String,
	map_id: String,
	source: Dictionary,
	_mob_snapshot: Dictionary
) -> void:
	if not configured:
		return


	var peer_id := int(
		source.get(
			"peer_id",
			-1
		)
	)


	var character_id := int(
		source.get(
			"character_id",
			0
		)
	)


	if (
		peer_id <= 1
		or
		character_id <= 0
	):
		return


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if session == null:
		return

	if session.level >= ServerCharacterProgressionRules.MAX_LEVEL:
		return

	if session.character_id != character_id:
		return


	if session.map_id != map_id:
		return


	var mob := (
		world_mob_registry.get_mob(
			entity_id
		)
	)


	if (
		mob == null
		or
		mob.definition == null
	):
		return


	var reward := (
		mob.definition.experience_reward
	)


	if reward <= 0:
		return


	var queued := int(
		queued_experience_by_peer.get(
			peer_id,
			0
		)
	)


	queued_experience_by_peer[
		peer_id
	] = (
		queued
		+
		reward
	)


	print(
		"CharacterProgressionCoordinator | Recompensa EXP detectada",
		" | Mob: ",
		entity_id,
		" | Character ID: ",
		character_id,
		" | EXP: +",
		reward,
		" | Queue: ",
		queued_experience_by_peer[
			peer_id
		]
	)


	_try_start_persistence(
		peer_id
	)


# =========================================================
# INTENTAR PERSISTENCIA
# =========================================================

func _try_start_persistence(
	peer_id: int
) -> void:
	if pending_by_peer.has(
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


	var queued_experience := int(
		queued_experience_by_peer.get(
			peer_id,
			0
		)
	)


	if queued_experience <= 0:
		return


	if not ServerCharacterProgressionRules.is_state_valid(
		session.level,
		session.experience
	):
		push_error(
			(
				"CharacterProgressionCoordinator | "
				+
				"Estado runtime de progresión inválido."
			)
		)


		return


	var next_state := (
		ServerCharacterProgressionRules.apply_experience(
			session.level,
			session.experience,
			queued_experience
		)
	)


	if next_state.is_empty():
		return


	var expected_level := session.level

	var expected_experience := (
		session.experience
	)


	var next_level := int(
		next_state.get(
			"level",
			0
		)
	)


	var next_experience := int(
		next_state.get(
			"experience",
			-1
		)
	)


	pending_by_peer[
		peer_id
	] = {
		"account_id": session.account_id,

		"character_id": session.character_id,

		"reward": queued_experience,

		"expected_level": expected_level,

		"expected_experience": expected_experience,

		"next_level": next_level,

		"next_experience": next_experience,
	}


	queued_experience_by_peer[
		peer_id
	] = 0


	var result := (
		progression_repository.persist_progression(
			peer_id,
			session.account_id,
			session.character_id,
			expected_level,
			expected_experience,
			next_level,
			next_experience
		)
	)


	if result == OK:
		print(
			"CharacterProgressionCoordinator | Persistencia iniciada",
			" | Peer: ",
			peer_id,
			" | Character ID: ",
			session.character_id,
			" | EXP ganada: ",
			queued_experience,
			" | Estado: ",
			expected_level,
			"/",
			expected_experience,
			" -> ",
			next_level,
			"/",
			next_experience
		)


		return


	pending_by_peer.erase(
		peer_id
	)


	queued_experience_by_peer[
		peer_id
	] = (
		int(
			queued_experience_by_peer.get(
				peer_id,
				0
			)
		)
		+
		queued_experience
	)


	push_warning(
		(
			"CharacterProgressionCoordinator | "
			+
			"No se pudo iniciar persistencia. Error: %d"
		)
		%
		result
	)


# =========================================================
# PERSISTENCIA CONFIRMADA
# =========================================================

func _on_progression_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	previous_level: int,
	previous_experience: int,
	level: int,
	experience: int,
	idempotent: bool
) -> void:
	if not pending_by_peer.has(
		peer_id
	):
		return


	var pending: Dictionary = (
		pending_by_peer[
			peer_id
		]
	)


	if (
		int(
			pending.get(
				"account_id",
				-1
			)
		) != account_id
		or
		int(
			pending.get(
				"character_id",
				-1
			)
		) != character_id
	):
		return


	var reward := int(
		pending.get(
			"reward",
			0
		)
	)


	pending_by_peer.erase(
		peer_id
	)


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	if (
		session != null
		and
		session.character_id == character_id
	):
		var level_changed := (
			level
			!=
			previous_level
		)


		var next_primary_stats := (
			session.primary_stats
		)

		var next_derived_stats := (
			session.derived_stats
		)

		# -------------------------------------------------
		# LEVEL UP → REBUILD DE BUDGET
		# -------------------------------------------------

		if level_changed:
			next_primary_stats = (
				ServerCharacterPrimaryStatsBootstrap
				.rebuild_for_progression(
					session.primary_stats,
					level,
					session.reset_count
				)
			)


			if next_primary_stats == null:
				push_error(
					(
						"CharacterProgressionCoordinator | "
						+
						"No se pudieron reconstruir "
						+
						"Primary Stats después del Level Up."
					)
				)


				game_server.reject_authenticated_peer(
					peer_id,
					(
						"No se pudo reconstruir "
						+
						"el estado de Primary Stats."
					)
				)


				return

			next_derived_stats = (
				ServerCharacterDerivedStatsBootstrap
				.create_from_primary_stats(
					next_primary_stats
				)
			)


			if next_derived_stats == null:
				push_error(
					(
						"CharacterProgressionCoordinator | "
						+
						"No se pudieron reconstruir "
						+
						"Derived Stats después del Level Up."
					)
				)


				game_server.reject_authenticated_peer(
					peer_id,
					(
						"No se pudo reconstruir "
						+
						"el estado de Derived Stats."
					)
				)


				return


			if (
				session.vitals == null
				or
				not session.vitals.is_valid()
			):
				push_error(
					(
						"CharacterProgressionCoordinator | "
						+
						"Vitals inválidos antes del Level Up."
					)
				)


				game_server.reject_authenticated_peer(
					peer_id,
					(
						"No se pudieron actualizar "
						+
						"los Vitals del personaje."
					)
				)


				return


			if not session.vitals.reconfigure_maximums(
				next_derived_stats.max_hp,
				next_derived_stats.max_mp
			):
				push_error(
					(
						"CharacterProgressionCoordinator | "
						+
						"No se pudieron reconfigurar "
						+
						"Vitals post Level Up."
					)
				)


				game_server.reject_authenticated_peer(
					peer_id,
					(
						"No se pudieron reconfigurar "
						+
						"los Vitals del personaje."
					)
				)


				return

		session.level = level

		session.experience = experience

		if level_changed:
			session.primary_stats = (
				next_primary_stats
			)

			session.derived_stats = (
				next_derived_stats
			)

		if level_changed:
			print(
				(
					"CharacterProgressionCoordinator | "
					+
					"Vitals reconfigurados post Level Up"
				),
				" | Character ID: ",
				character_id,
				" | HP: ",
				session.vitals.hp,
				"/",
				session.vitals.max_hp,
				" | MP: ",
				session.vitals.mp,
				"/",
				session.vitals.max_mp
			)

		if level_changed:
			print(
				(
					"CharacterProgressionCoordinator | "
					+
					"Derived Stats reconstruidos post Level Up"
				),
				" | Character ID: ",
				character_id,
				" | Source revision: ",
				session.derived_stats.source_primary_stats_revision,
				" | Level: ",
				session.derived_stats.level,
				" | Max HP/MP: ",
				session.derived_stats.max_hp,
				"/",
				session.derived_stats.max_mp,
				" | Power P/M/H: ",
				session.derived_stats.physical_power,
				"/",
				session.derived_stats.magic_power,
				"/",
				session.derived_stats.healing_power
			)

		var experience_required := (
			ServerCharacterProgressionRules
			.get_experience_required(
				level
			)
		)


		var levels_gained := maxi(
			level
			-
			previous_level,
			0
		)


		# -------------------------------------------------
		# PRIMERO PROGRESSION
		# -------------------------------------------------

		var replication_result := (
			game_server
			.send_character_progression_updated(
				peer_id,
				character_id,
				level,
				experience,
				experience_required,
				reward,
				levels_gained
			)
		)


		if replication_result != OK:
			push_warning(
				(
					"CharacterProgressionCoordinator | "
					+
					"No se pudo replicar Progression. "
					+
					"Error: %d"
				)
				%
				replication_result
			)


		# -------------------------------------------------
		# DESPUÉS PRIMARY STATS
		#
		# Ambos usan reliable/channel 0.
		# El Client debe aplicar primero el nuevo Level.
		# -------------------------------------------------

		elif level_changed:
			var stats_replication_result := (
				game_server.send_primary_stats_updated(
					peer_id,
					character_id,
					session.primary_stats.to_snapshot()
				)
			)


			if stats_replication_result != OK:
				push_warning(
					(
						"CharacterProgressionCoordinator | "
						+
						"No se pudieron replicar "
						+
						"Primary Stats post Level Up. "
						+
						"Error: %d"
					)
					%
					stats_replication_result
				)
			else:
				print(
					(
						"CharacterProgressionCoordinator | "
						+
						"Primary Stats reconstruidos "
						+
						"post Level Up"
					),
					" | Character ID: ",
					character_id,
					" | Level: ",
					level,
					" | Revision: ",
					session.primary_stats.revision,
					" | Points: ",
					session.primary_stats.spent_points,
					"/",
					session.primary_stats.total_points,
					" | Unspent: ",
					session.primary_stats.unspent_points
				)
				var vitals_replication_result := (
					game_server.send_character_vitals_updated(
						peer_id,
						character_id,
						session.vitals.to_snapshot()
					)
				)


				if vitals_replication_result != OK:
					push_warning(
						(
							"CharacterProgressionCoordinator | "
							+
							"No se pudieron replicar "
							+
							"Vitals post Level Up. "
							+
							"Error: %d"
						)
						%
						vitals_replication_result
					)
				else:
					print(
						(
							"CharacterProgressionCoordinator | "
							+
							"Vitals autoritativos replicados "
							+
							"post Level Up"
						),
						" | Character ID: ",
						character_id,
						" | HP: ",
						session.vitals.hp,
						"/",
						session.vitals.max_hp,
						" | MP: ",
						session.vitals.mp,
						"/",
						session.vitals.max_mp
					)


	print(
		"CharacterProgressionCoordinator | Progresión confirmada",
		" | Peer: ",
		peer_id,
		" | Character ID: ",
		character_id,
		" | EXP ganada: ",
		reward,
		" | Level: ",
		previous_level,
		" -> ",
		level,
		" | EXP: ",
		previous_experience,
		" -> ",
		experience,
		" | Idempotent: ",
		idempotent
	)


	if (
		session != null
		and
		int(
			queued_experience_by_peer.get(
				peer_id,
				0
			)
		) > 0
	):
		_try_start_persistence(
			peer_id
		)


# =========================================================
# PERSISTENCIA FALLIDA
# =========================================================

func _on_progression_persist_failed(
	peer_id: int,
	_account_id: int,
	character_id: int,
	response_code: int,
	message: String,
	current_progression: Dictionary
) -> void:
	if not pending_by_peer.has(
		peer_id
	):
		return


	var pending: Dictionary = (
		pending_by_peer[
			peer_id
		]
	)


	var reward := int(
		pending.get(
			"reward",
			0
		)
	)


	pending_by_peer.erase(
		peer_id
	)


	var session := (
		world_session_registry.get_session(
			peer_id
		)
	)


	# -----------------------------------------------------
	# STALE RECOVERY
	# -----------------------------------------------------

	if (
		response_code == 409
		and
		not current_progression.is_empty()
		and
		session != null
		and
		session.character_id == character_id
	):
		var current_level := int(
			current_progression.get(
				"level",
				0
			)
		)


		var current_experience := int(
			current_progression.get(
				"experience",
				-1
			)
		)


		if ServerCharacterProgressionRules.is_state_valid(
			current_level,
			current_experience
		):
			session.level = current_level

			session.experience = (
				current_experience
			)


			queued_experience_by_peer[
				peer_id
			] = (
				int(
					queued_experience_by_peer.get(
						peer_id,
						0
					)
				)
				+
				reward
			)


			print(
				"CharacterProgressionCoordinator | Stale recuperado",
				" | Character ID: ",
				character_id,
				" | Level: ",
				current_level,
				" | EXP: ",
				current_experience,
				" | Reward reencolada: ",
				reward
			)


			call_deferred(
				"_try_start_persistence",
				peer_id
			)


			return


	# -----------------------------------------------------
	# OTRO ERROR
	#
	# No descartamos la recompensa dentro de esta sesión.
	# Queda en cola y puede reintentarse ante una próxima
	# recompensa/evento.
	# -----------------------------------------------------

	if session != null:
		queued_experience_by_peer[
			peer_id
		] = (
			int(
				queued_experience_by_peer.get(
					peer_id,
					0
				)
			)
			+
			reward
		)


	push_warning(
		"CharacterProgressionCoordinator | Persistencia rechazada",
		" | Character ID: ",
		character_id,
		" | HTTP: ",
		response_code,
		" | Motivo: ",
		message,
		" | Reward retenida: ",
		reward
	)
