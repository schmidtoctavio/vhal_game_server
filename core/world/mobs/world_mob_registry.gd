class_name WorldMobRegistry
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal mob_died(
	entity_id: String,
	map_id: String,
	source: Dictionary,
	mob_snapshot: Dictionary
)

signal mob_respawned(
	entity_id: String,
	map_id: String,
	mob_snapshot: Dictionary
)

# =========================================================
# DEFINICIONES
# =========================================================

var definitions_by_type_id: Dictionary = {}


# =========================================================
# INSTANCIAS DE MUNDO
# =========================================================

var mobs_by_entity_id: Dictionary = {}

# =========================================================
# RESPAWN SCHEDULER
# =========================================================

var pending_respawn_deadlines_msec: Dictionary = {}

var respawn_timer: Timer = null

# =========================================================
# INICIALIZACIÓN
# =========================================================

func initialize() -> Error:
	definitions_by_type_id.clear()

	mobs_by_entity_id.clear()

	pending_respawn_deadlines_msec.clear()


	if not _prepare_respawn_scheduler():
		return ERR_CANT_CREATE

	# -----------------------------------------------------
	# DEFINICIÓN TEMPORAL DEL PRIMER MOB
	#
	# Estos valores todavía NO son balance definitivo.
	# -----------------------------------------------------

	var training_goblin := (
		WorldMobDefinition.create(
			"training_goblin",
			"Training Goblin",
			1,
			5_000,
			50,
			3.0,
			100
		)
	)


	if not _register_definition(
		training_goblin
	):
		return ERR_INVALID_DATA


	# -----------------------------------------------------
	# PRIMERA INSTANCIA REAL DE MUNDO
	# -----------------------------------------------------

	var first_goblin := (
		WorldMobRuntimeState.create(
			"mob_test_town_001",
			training_goblin,
			"test_town",
			Vector3(
				4.0,
				0.0,
				4.0
			),
			0.0
		)
	)


	if not _register_mob(
		first_goblin
	):
		return ERR_INVALID_DATA


	print(
		"WorldMobRegistry | Inicializado",
		" | Definiciones: ",
		definitions_by_type_id.size(),
		" | Mobs: ",
		mobs_by_entity_id.size()
	)


	print(
		"WorldMobRegistry | Mob preparado",
		" | Entity: ",
		first_goblin.entity_id,
		" | Type: ",
		first_goblin.definition.mob_type_id,
		" | Nombre: ",
		first_goblin.definition.display_name,
		" | Nivel: ",
		first_goblin.definition.level,
		" | Mapa: ",
		first_goblin.map_id,
		" | Posición: ",
		first_goblin.position,
		" | HP: ",
		first_goblin.vitals.hp,
		"/",
		first_goblin.vitals.max_hp,
		" | Base Armor: ",
		first_goblin.definition.base_armor_rating
	)


	return OK

# =========================================================
# PREPARAR RESPAWN SCHEDULER
# =========================================================

func _prepare_respawn_scheduler() -> bool:
	if (
		respawn_timer == null
		or
		not is_instance_valid(
			respawn_timer
		)
	):
		respawn_timer = Timer.new()

		respawn_timer.name = (
			"RespawnTimer"
		)

		respawn_timer.one_shot = true

		add_child(
			respawn_timer
		)


	if not respawn_timer.timeout.is_connected(
		_on_respawn_timer_timeout
	):
		respawn_timer.timeout.connect(
			_on_respawn_timer_timeout
		)


	respawn_timer.stop()


	return true

# =========================================================
# PROGRAMAR RESPAWN
# =========================================================

func _schedule_mob_respawn(
	mob: WorldMobRuntimeState
) -> bool:
	if mob == null:
		return false


	if mob.is_alive():
		return false


	if mob.definition == null:
		return false


	var delay_seconds := (
		mob.definition.respawn_delay_seconds
	)


	if delay_seconds <= 0.0:
		return false


	if pending_respawn_deadlines_msec.has(
		mob.entity_id
	):
		return true


	var delay_msec := maxi(
		ceili(
			delay_seconds
			*
			1000.0
		),
		1
	)


	var deadline_msec := (
		Time.get_ticks_msec()
		+
		delay_msec
	)


	pending_respawn_deadlines_msec[
		mob.entity_id
	] = deadline_msec


	print(
		"WorldMobRegistry | Respawn programado",
		" | Entity: ",
		mob.entity_id,
		" | Delay: ",
		delay_seconds,
		" s"
	)


	_arm_next_respawn()


	return true

# =========================================================
# ARMAR PRÓXIMO RESPAWN
# =========================================================

func _arm_next_respawn() -> void:
	if respawn_timer == null:
		return


	if pending_respawn_deadlines_msec.is_empty():
		respawn_timer.stop()


		return


	var nearest_deadline_msec: int = 0


	for deadline_value: Variant in (
		pending_respawn_deadlines_msec.values()
	):
		var deadline_msec := int(
			deadline_value
		)


		if deadline_msec <= 0:
			continue


		if (
			nearest_deadline_msec == 0
			or
			deadline_msec
			<
			nearest_deadline_msec
		):
			nearest_deadline_msec = (
				deadline_msec
			)


	if nearest_deadline_msec <= 0:
		respawn_timer.stop()


		return


	var remaining_msec := maxi(
		nearest_deadline_msec
		-
		Time.get_ticks_msec(),
		1
	)


	respawn_timer.start(
		float(
			remaining_msec
		)
		/
		1000.0
	)

# =========================================================
# EJECUTAR RESPAWNS VENCIDOS
# =========================================================

func _on_respawn_timer_timeout() -> void:
	var now_msec := (
		Time.get_ticks_msec()
	)


	var due_entity_ids: Array[String] = []


	for entity_value: Variant in (
		pending_respawn_deadlines_msec.keys()
	):
		var entity_id := String(
			entity_value
		)


		var deadline_msec := int(
			pending_respawn_deadlines_msec[
				entity_id
			]
		)


		if deadline_msec > now_msec:
			continue


		due_entity_ids.append(
			entity_id
		)


	for entity_id: String in due_entity_ids:
		pending_respawn_deadlines_msec.erase(
			entity_id
		)


		var mob := get_mob(
			entity_id
		)


		if mob == null:
			continue


		if mob.is_alive():
			continue


		if not mob.respawn_at_spawn():
			push_warning(
				(
					"WorldMobRegistry | "
					+
					"No se pudo respawnear mob '%s'."
				)
				%
				entity_id
			)


			continue


		var mob_snapshot := (
			mob.to_snapshot()
		)


		if mob_snapshot.is_empty():
			push_warning(
				(
					"WorldMobRegistry | "
					+
					"Snapshot inválido tras respawn '%s'."
				)
				%
				entity_id
			)


			continue


		print(
			"WorldMobRegistry | Respawn autoritativo confirmado",
			" | Entity: ",
			mob.entity_id,
			" | Mapa: ",
			mob.map_id,
			" | Posición: ",
			mob.position,
			" | HP: ",
			mob.vitals.hp,
			"/",
			mob.vitals.max_hp
		)


		mob_respawned.emit(
			mob.entity_id,
			mob.map_id,
			mob_snapshot.duplicate(
				true
			)
		)


	_arm_next_respawn()

# =========================================================
# REGISTRAR DEFINICIÓN
# =========================================================

func _register_definition(
	definition: WorldMobDefinition
) -> bool:
	if definition == null:
		return false


	if not definition.is_valid():
		return false


	if definitions_by_type_id.has(
		definition.mob_type_id
	):
		return false


	definitions_by_type_id[
		definition.mob_type_id
	] = definition


	return true


# =========================================================
# REGISTRAR MOB
# =========================================================

func _register_mob(
	mob: WorldMobRuntimeState
) -> bool:
	if mob == null:
		return false


	if not mob.is_valid():
		return false


	if mobs_by_entity_id.has(
		mob.entity_id
	):
		return false


	mobs_by_entity_id[
		mob.entity_id
	] = mob


	return true


# =========================================================
# CONSULTAR DEFINICIÓN
# =========================================================

func get_definition(
	mob_type_id: String
) -> WorldMobDefinition:
	var normalized_id := (
		mob_type_id
		.strip_edges()
		.to_lower()
	)


	if normalized_id.is_empty():
		return null


	if not definitions_by_type_id.has(
		normalized_id
	):
		return null


	return (
		definitions_by_type_id[
			normalized_id
		]
		as WorldMobDefinition
	)


# =========================================================
# CONSULTAR MOB
# =========================================================

func get_mob(
	entity_id: String
) -> WorldMobRuntimeState:
	var normalized_id := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	if normalized_id.is_empty():
		return null


	if not mobs_by_entity_id.has(
		normalized_id
	):
		return null


	return (
		mobs_by_entity_id[
			normalized_id
		]
		as WorldMobRuntimeState
	)

# =========================================================
# DAMAGE AUTORITATIVO DE MOB
# =========================================================

func apply_damage_to_mob(
	entity_id: String,
	amount: int,
	source: Dictionary
) -> Dictionary:
	if amount <= 0:
		return {}


	var mob := (
		get_mob(
			entity_id
		)
	)


	if mob == null:
		return {}


	if not mob.is_alive():
		return {
			"applied_damage": 0,

			"died": false,
		}


	var was_alive := (
		mob.is_alive()
	)


	var applied_damage := (
		mob.apply_damage(
			amount
		)
	)


	if applied_damage <= 0:
		return {}


	var died := (
		was_alive
		and
		not mob.is_alive()
	)


	# -----------------------------------------------------
	# TRANSICIÓN ALIVE → DEAD
	#
	# Este bloque sólo puede ocurrir una vez durante esta
	# vida del mob porque, luego de llegar a HP 0,
	# is_alive() será false.
	# -----------------------------------------------------

	if died:
		var mob_snapshot := (
			mob.to_snapshot()
		)


		var normalized_source := (
			source.duplicate(
				true
			)
		)


		print(
			"WorldMobRegistry | Muerte autoritativa confirmada",
			" | Entity: ",
			mob.entity_id,
			" | Type: ",
			mob.definition.mob_type_id,
			" | Mapa: ",
			mob.map_id,
			" | Source: ",
			String(
				normalized_source.get(
					"kind",
					"unknown"
				)
			),
			" | HP: ",
			mob.vitals.hp,
			"/",
			mob.vitals.max_hp
		)


		mob_died.emit(
			mob.entity_id,
			mob.map_id,
			normalized_source,
			mob_snapshot.duplicate(
				true
			)
		)

		if not _schedule_mob_respawn(
			mob
		):
			push_warning(
				(
					"WorldMobRegistry | "
					+
					"No se pudo programar respawn para '%s'."
				)
				%
				mob.entity_id
			)

	return {
		"applied_damage": (
			applied_damage
		),

		"died": died,
	}

# =========================================================
# MOBS DE MAPA
# =========================================================

func get_mobs_in_map(
	map_id: String
) -> Array[WorldMobRuntimeState]:
	var normalized_map_id := (
		map_id
		.strip_edges()
	)


	var result: Array[WorldMobRuntimeState] = []


	if normalized_map_id.is_empty():
		return result


	for value: Variant in mobs_by_entity_id.values():
		var mob := (
			value
			as WorldMobRuntimeState
		)


		if mob == null:
			continue


		if mob.map_id != normalized_map_id:
			continue


		result.append(
			mob
		)


	return result
