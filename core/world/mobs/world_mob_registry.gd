class_name WorldMobRegistry
extends Node


# =========================================================
# DEFINICIONES
# =========================================================

var definitions_by_type_id: Dictionary = {}


# =========================================================
# INSTANCIAS DE MUNDO
# =========================================================

var mobs_by_entity_id: Dictionary = {}


# =========================================================
# INICIALIZACIÓN
# =========================================================

func initialize() -> Error:
	definitions_by_type_id.clear()

	mobs_by_entity_id.clear()


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
			50_000
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
		first_goblin.vitals.max_hp
	)


	return OK


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
