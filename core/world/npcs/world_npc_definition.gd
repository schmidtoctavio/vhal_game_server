class_name WorldNpcDefinition
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var npc_id: String = ""

var service_id: String = ""


# =========================================================
# MUNDO
# =========================================================

var map_id: String = ""

var position: Vector3 = Vector3.ZERO

var rotation_y: float = 0.0


# =========================================================
# INTERACCIÓN
# =========================================================

var interaction_range: float = 0.0


# =========================================================
# CREAR
# =========================================================

static func create(
	new_npc_id: String,
	new_service_id: String,
	new_map_id: String,
	new_position: Vector3,
	new_rotation_y: float,
	new_interaction_range: float
) -> WorldNpcDefinition:
	var definition := WorldNpcDefinition.new()


	definition.npc_id = (
		new_npc_id.strip_edges()
	)

	definition.service_id = (
		new_service_id.strip_edges()
	)

	definition.map_id = (
		new_map_id.strip_edges()
	)

	definition.position = (
		new_position
	)

	definition.rotation_y = (
		new_rotation_y
	)

	definition.interaction_range = (
		maxf(
			new_interaction_range,
			0.0
		)
	)


	return definition


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if npc_id.is_empty():
		return false


	if service_id.is_empty():
		return false


	if map_id.is_empty():
		return false


	if interaction_range <= 0.0:
		return false


	return true
