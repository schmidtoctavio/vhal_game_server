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

var status_effects: ServerStatusEffectCollection = null


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


	state.vitals = ServerVitalsState.new(
		new_definition.max_hp,
		0
	)


	state.combat_runtime = (
		WorldMobCombatRuntime.new()
	)


	if not state.combat_runtime.is_valid():
		return null


	state.status_effects = (
		ServerStatusEffectCollection.new()
	)


	if not state.status_effects.is_valid():
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
		and
		status_effects != null
		and
		status_effects.is_valid()
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
	status_effect: ServerStatusEffectRuntime,
	now_msec: int
) -> Dictionary:
	if status_effects == null:
		return {
			"ok": false,
		}


	if not is_alive():
		return {
			"ok": false,
		}


	return status_effects.apply_status_effect(
		status_effect,
		now_msec
	)


func get_status_effects() -> Array[ServerStatusEffectRuntime]:
	if status_effects == null:
		return []


	return status_effects.get_all()


func remove_status_effect_by_key(
	runtime_key: String
) -> ServerStatusEffectRuntime:
	if status_effects == null:
		return null


	return status_effects.remove_status_effect_by_key(
		runtime_key
	)


func remove_status_effect(
	effect_id: String
) -> int:
	if status_effects == null:
		return 0


	return status_effects.remove_status_effect(
		effect_id
	)


func clear_status_effects() -> void:
	if status_effects == null:
		return


	status_effects.clear()


func begin_hard_control_immunity(
	now_msec: int
) -> void:
	if status_effects == null:
		return


	status_effects.begin_hard_control_immunity(
		now_msec
	)


func is_hard_control_immune(
	now_msec: int
) -> bool:
	if status_effects == null:
		return false


	return status_effects.is_hard_control_immune(
		now_msec
	)


# =========================================================
# STATUS EFFECT CONSUMERS
# =========================================================

func get_movement_speed_multiplier() -> float:
	if status_effects == null:
		return 1.0


	return status_effects.get_movement_speed_multiplier(
		Time.get_ticks_msec()
	)


func get_attack_speed_multiplier() -> float:
	if status_effects == null:
		return 1.0


	return status_effects.get_attack_speed_multiplier(
		Time.get_ticks_msec()
	)


func is_movement_blocked() -> bool:
	if status_effects == null:
		return false


	return status_effects.is_movement_blocked(
		Time.get_ticks_msec()
	)


func are_actions_blocked() -> bool:
	if status_effects == null:
		return false


	return status_effects.are_actions_blocked(
		Time.get_ticks_msec()
	)


func are_skills_blocked() -> bool:
	if status_effects == null:
		return false


	return status_effects.are_skills_blocked(
		Time.get_ticks_msec()
	)


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


	var status_effect_snapshots: Array = []


	if status_effects != null:
		status_effect_snapshots = (
			status_effects.get_snapshots(
				Time.get_ticks_msec()
			)
		)


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

		"status_effects": (
			status_effect_snapshots
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
