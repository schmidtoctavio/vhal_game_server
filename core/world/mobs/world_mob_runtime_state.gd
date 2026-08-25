class_name WorldMobRuntimeState
extends RefCounted


# =========================================================
# IDENTIDAD DE INSTANCIA
# =========================================================

var entity_id: String = ""

var definition: WorldMobDefinition = null


# =========================================================
# MUNDO
# =========================================================

var map_id: String = ""

var spawn_position: Vector3 = Vector3.ZERO

var spawn_rotation_y: float = 0.0


var position: Vector3 = Vector3.ZERO

var rotation_y: float = 0.0


# =========================================================
# COMBATE
# =========================================================

var vitals: ServerVitalsState = null


# =========================================================
# CREAR
# =========================================================

static func create(
	new_entity_id: String,
	new_definition: WorldMobDefinition,
	new_map_id: String,
	new_spawn_position: Vector3,
	new_spawn_rotation_y: float
) -> WorldMobRuntimeState:
	if new_definition == null:
		return null


	if not new_definition.is_valid():
		return null


	var state := WorldMobRuntimeState.new()


	state.entity_id = (
		new_entity_id
		.strip_edges()
		.to_lower()
	)


	state.definition = new_definition


	state.map_id = (
		new_map_id
		.strip_edges()
	)


	state.spawn_position = (
		new_spawn_position
	)

	state.spawn_rotation_y = (
		new_spawn_rotation_y
	)


	state.position = (
		new_spawn_position
	)

	state.rotation_y = (
		new_spawn_rotation_y
	)


	# -----------------------------------------------------
	# Primer mob:
	#
	# HP real.
	# Sin MP por ahora.
	#
	# Reutilizamos el mismo primitive de vitals que ya usa
	# el runtime autoritativo del jugador.
	# -----------------------------------------------------

	state.vitals = ServerVitalsState.new(
		new_definition.max_hp,
		0
	)


	return state


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		not entity_id.is_empty()
		and
		definition != null
		and
		definition.is_valid()
		and
		not map_id.is_empty()
		and
		vitals != null
		and
		vitals.is_valid()
	)


# =========================================================
# VIDA
# =========================================================

func is_alive() -> bool:
	if vitals == null:
		return false


	return (
		vitals.hp > 0
	)

func apply_damage(
	amount: int
) -> int:
	if amount <= 0:
		return 0


	if not is_alive():
		return 0


	if vitals == null:
		return 0


	return vitals.apply_damage(
		amount
	)

# =========================================================
# TRANSFORM
# =========================================================

func set_world_transform(
	new_position: Vector3,
	new_rotation_y: float
) -> void:
	position = new_position

	rotation_y = new_rotation_y


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"entity_id": entity_id,

		"entity_kind": "mob",

		"mob_type_id": (
			definition.mob_type_id
		),

		"display_name": (
			definition.display_name
		),

		"level": (
			definition.level
		),

		"alive": is_alive(),

		"vitals": (
			vitals.to_snapshot()
		),

		"world": {
			"map_id": map_id,

			"position": {
				"x": position.x,
				"y": position.y,
				"z": position.z,
			},

			"rotation_y": rotation_y,
		},
	}
