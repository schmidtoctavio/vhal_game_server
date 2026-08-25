class_name WorldDropRuntimeState
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var entity_id: String = ""

var item_id: String = ""

var quantity: int = 0


# =========================================================
# MUNDO
# =========================================================

var map_id: String = ""

var position: Vector3 = Vector3.ZERO


# =========================================================
# CREAR
# =========================================================

static func create(
	new_entity_id: String,
	new_item_id: String,
	new_quantity: int,
	new_map_id: String,
	new_position: Vector3
) -> WorldDropRuntimeState:
	var normalized_entity_id := (
		new_entity_id
		.strip_edges()
		.to_lower()
	)


	var normalized_item_id := (
		new_item_id
		.strip_edges()
		.to_lower()
	)


	var normalized_map_id := (
		new_map_id.strip_edges()
	)


	if normalized_entity_id.is_empty():
		return null


	if normalized_item_id.is_empty():
		return null


	if normalized_map_id.is_empty():
		return null


	if new_quantity <= 0:
		return null


	if not ServerItemCatalog.has_definition(
		normalized_item_id
	):
		return null


	var item_definition := (
		ServerItemCatalog.get_definition(
			normalized_item_id
		)
	)


	if item_definition.is_empty():
		return null


	var max_stack := int(
		item_definition.get(
			"max_stack",
			0
		)
	)


	if (
		max_stack <= 0
		or
		new_quantity > max_stack
	):
		return null


	var state := WorldDropRuntimeState.new()


	state.entity_id = normalized_entity_id

	state.item_id = normalized_item_id

	state.quantity = new_quantity

	state.map_id = normalized_map_id

	state.position = new_position


	return state


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if entity_id.is_empty():
		return false


	if item_id.is_empty():
		return false


	if quantity <= 0:
		return false


	if map_id.is_empty():
		return false


	if not ServerItemCatalog.has_definition(
		item_id
	):
		return false


	var item_definition := (
		ServerItemCatalog.get_definition(
			item_id
		)
	)


	if item_definition.is_empty():
		return false


	var max_stack := int(
		item_definition.get(
			"max_stack",
			0
		)
	)


	if (
		max_stack <= 0
		or
		quantity > max_stack
	):
		return false


	return true


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"entity_id": entity_id,

		"entity_kind": "world_drop",

		"item": {
			"item_id": item_id,

			"quantity": quantity,
		},

		"world": {
			"map_id": map_id,

			"position": {
				"x": position.x,

				"y": position.y,

				"z": position.z,
			},
		},
	}
