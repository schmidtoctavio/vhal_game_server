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

var combat_runtime: WorldMobCombatRuntime = null

var status_effects_by_id: Dictionary = {}

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

	state.combat_runtime = (
		WorldMobCombatRuntime.new()
	)


	if not state.combat_runtime.is_valid():
		return null

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
		and
		combat_runtime != null
		and
		combat_runtime.is_valid()
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
# STATUS EFFECTS
# =========================================================

func apply_status_effect(
	status_effect: WorldMobStatusEffectRuntime
) -> bool:
	if status_effect == null:
		return false

	if not status_effect.is_valid():
		return false

	if not is_alive():
		return false

	# Foundation:
	#
	# Un solo efecto por effect_id.
	# Un nuevo Poison reemplaza/refresca al anterior.

	status_effects_by_id[
		status_effect.effect_id
	] = status_effect

	return true


func get_status_effects() -> Array[WorldMobStatusEffectRuntime]:
	var result: Array[WorldMobStatusEffectRuntime] = []

	for value: Variant in status_effects_by_id.values():
		var status_effect := (
			value
			as WorldMobStatusEffectRuntime
		)

		if status_effect == null:
			continue

		result.append(
			status_effect
		)

	return result


func remove_status_effect(
	effect_id: String
) -> void:
	status_effects_by_id.erase(
		effect_id
		.strip_edges()
		.to_lower()
	)


func clear_status_effects() -> void:
	status_effects_by_id.clear()

# =========================================================
# COMBAT RUNTIME
# =========================================================

func reset_combat() -> void:
	if combat_runtime == null:
		return


	combat_runtime.reset()

# =========================================================
# RESPAWN
# =========================================================

func respawn_at_spawn() -> bool:
	if definition == null:
		return false


	if vitals == null:
		return false


	if is_alive():
		return false


	clear_status_effects()
	reset_combat()

	vitals.set_hp(
		vitals.max_hp
	)


	vitals.set_mp(
		vitals.max_mp
	)


	set_world_transform(
		spawn_position,
		spawn_rotation_y
	)


	return is_alive()

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
