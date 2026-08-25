class_name WorldDropRegistry
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal world_drop_spawned(
	entity_id: String,
	map_id: String,
	drop_snapshot: Dictionary
)

signal world_drop_removed(
	entity_id: String,
	map_id: String
)

# =========================================================
# ESTADO
# =========================================================

var drops_by_entity_id: Dictionary = {}

var next_drop_sequence: int = 1


# =========================================================
# INICIALIZACIÓN
# =========================================================

func initialize() -> Error:
	drops_by_entity_id.clear()

	next_drop_sequence = 1


	print(
		"WorldDropRegistry | Inicializado."
	)


	return OK


# =========================================================
# CREAR DROP
# =========================================================

func spawn_drop(
	item_id: String,
	quantity: int,
	map_id: String,
	position: Vector3
) -> WorldDropRuntimeState:
	var entity_id := (
		"world_drop_%08d"
		%
		next_drop_sequence
	)

	var persistent_item_uid := (
		ServerPersistentItemUidGenerator.generate_uuid_v4()
	)


	if persistent_item_uid.is_empty():
		return null

	var drop := (
		WorldDropRuntimeState.create(
			entity_id,
			persistent_item_uid,
			item_id,
			quantity,
			map_id,
			position
		)
	)


	if drop == null:
		return null


	if not _register_drop(
		drop
	):
		return null


	next_drop_sequence += 1


	var snapshot := (
		drop.to_snapshot()
	)


	if snapshot.is_empty():
		drops_by_entity_id.erase(
			drop.entity_id
		)


		return null


	print(
		"WorldDropRegistry | Drop creado",
		" | Entity: ",
		drop.entity_id,
		" | Item: ",
		drop.item_id,
		" | Quantity: ",
		drop.quantity,
		" | Mapa: ",
		drop.map_id,
		" | Posición: ",
		drop.position,
		" | Persistent UID: ",
		drop.persistent_item_uid,
	)


	world_drop_spawned.emit(
		drop.entity_id,
		drop.map_id,
		snapshot.duplicate(
			true
		)
	)


	return drop


# =========================================================
# REGISTRAR
# =========================================================

func _register_drop(
	drop: WorldDropRuntimeState
) -> bool:
	if drop == null:
		return false


	if not drop.is_valid():
		return false


	if drops_by_entity_id.has(
		drop.entity_id
	):
		return false


	drops_by_entity_id[
		drop.entity_id
	] = drop


	return true


# =========================================================
# CONSULTAR
# =========================================================

func get_drop(
	entity_id: String
) -> WorldDropRuntimeState:
	var normalized_entity_id := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	if normalized_entity_id.is_empty():
		return null


	if not drops_by_entity_id.has(
		normalized_entity_id
	):
		return null


	return (
		drops_by_entity_id[
			normalized_entity_id
		]
		as WorldDropRuntimeState
	)

# =========================================================
# CONSUMIR DROP
# =========================================================

func consume_drop(
	entity_id: String
) -> WorldDropRuntimeState:
	var drop := get_drop(
		entity_id
	)


	if drop == null:
		return null


	drops_by_entity_id.erase(
		drop.entity_id
	)


	print(
		"WorldDropRegistry | Drop consumido",
		" | Entity: ",
		drop.entity_id,
		" | Item: ",
		drop.item_id,
		" | Quantity: ",
		drop.quantity
	)


	world_drop_removed.emit(
		drop.entity_id,
		drop.map_id
	)


	return drop

# =========================================================
# DROPS DE MAPA
# =========================================================

func get_drops_in_map(
	map_id: String
) -> Array[WorldDropRuntimeState]:
	var normalized_map_id := (
		map_id.strip_edges()
	)


	var result: Array[WorldDropRuntimeState] = []


	if normalized_map_id.is_empty():
		return result


	for value: Variant in drops_by_entity_id.values():
		var drop := (
			value
			as WorldDropRuntimeState
		)


		if drop == null:
			continue


		if not drop.is_valid():
			continue


		if drop.map_id != normalized_map_id:
			continue


		result.append(
			drop
		)


	return result
