class_name WorldDropCoordinator
extends Node


# =========================================================
# DEPENDENCIAS
# =========================================================

var world_mob_registry: WorldMobRegistry = null

var world_drop_registry: WorldDropRegistry = null


# =========================================================
# ESTADO
# =========================================================

var configured: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	p_world_mob_registry: WorldMobRegistry,
	p_world_drop_registry: WorldDropRegistry
) -> bool:
	if configured:
		return true


	if p_world_mob_registry == null:
		return false


	if p_world_drop_registry == null:
		return false


	world_mob_registry = (
		p_world_mob_registry
	)


	world_drop_registry = (
		p_world_drop_registry
	)


	if not world_mob_registry.mob_died.is_connected(
		_on_mob_died
	):
		world_mob_registry.mob_died.connect(
			_on_mob_died
		)


	configured = true


	print(
		"WorldDropCoordinator | Inicializado."
	)


	return true


# =========================================================
# MOB DIED
# =========================================================

func _on_mob_died(
	mob_entity_id: String,
	map_id: String,
	source: Dictionary,
	mob_snapshot: Dictionary
) -> void:
	if not configured:
		return


	if mob_snapshot.is_empty():
		return


	var mob_type_id := String(
		mob_snapshot.get(
			"mob_type_id",
			""
		)
	).strip_edges().to_lower()


	if mob_type_id.is_empty():
		return


	var world_value: Variant = (
		mob_snapshot.get(
			"world",
			null
		)
	)


	if typeof(world_value) != TYPE_DICTIONARY:
		return


	var world: Dictionary = (
		world_value
	)


	var position_value: Variant = (
		world.get(
			"position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		return


	var position_data: Dictionary = (
		position_value
	)


	if (
		not position_data.has("x")
		or
		not position_data.has("y")
		or
		not position_data.has("z")
	):
		return


	var death_position := Vector3(
		float(
			position_data["x"]
		),

		float(
			position_data["y"]
		),

		float(
			position_data["z"]
		)
	)


	var rolled_drops := (
		ServerMobDropCatalog.roll_drops(
			mob_type_id
		)
	)


	var created_count := 0


	for drop_data: Dictionary in rolled_drops:
		var item_id := String(
			drop_data.get(
				"item_id",
				""
			)
		).strip_edges().to_lower()


		var quantity := int(
			drop_data.get(
				"quantity",
				0
			)
		)


		var drop := (
			world_drop_registry.spawn_drop(
				item_id,
				quantity,
				map_id,
				death_position
			)
		)


		if drop == null:
			push_warning(
				(
					"WorldDropCoordinator | "
					+
					"No se pudo crear drop '%s'."
				)
				%
				item_id
			)


			continue


		created_count += 1


	print(
		"WorldDropCoordinator | Muerte procesada",
		" | Mob: ",
		mob_entity_id,
		" | Type: ",
		mob_type_id,
		" | Killer Character: ",
		int(
			source.get(
				"character_id",
				0
			)
		),
		" | Drops: ",
		created_count
	)
