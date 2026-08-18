class_name WorldNavigationRegistry
extends Node


# =========================================================
# MAPAS
# =========================================================

const TEST_TOWN_MAP_ID: String = (
	"test_town"
)

const TEST_TOWN_NAVIGATION: NavigationMesh = preload(
	"res://core/world/maps/test_town/navigation/test_town_navigation.tres"
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

const DEFAULT_NAVIGATION_LAYERS: int = 1

const MAX_SYNC_FRAMES: int = 60


# =========================================================
# ESTADO
# =========================================================

var navigation_maps: Dictionary = {}

var initialized: bool = false


# =========================================================
# INICIALIZAR
# =========================================================

func initialize() -> Error:
	if initialized:
		return OK


	print(
		"WorldNavigationRegistry | Inicializando navegación..."
	)


	var register_result := (
		_register_map(
			TEST_TOWN_MAP_ID,
			TEST_TOWN_NAVIGATION
		)
	)


	if register_result != OK:
		push_error(
			(
				"WorldNavigationRegistry | "
				+
				"No se pudo registrar test_town. Error: %d"
			)
			%
			register_result
		)

		return register_result


	var map_rid := (
		get_navigation_map(
			TEST_TOWN_MAP_ID
		)
	)


	if not map_rid.is_valid():
		push_error(
			"WorldNavigationRegistry | "
			+
			"El RID de test_town no es válido."
		)

		return ERR_CANT_CREATE


	# -----------------------------------------------------
	# ESPERAR SINCRONIZACIÓN
	# -----------------------------------------------------
	#
	# No asumimos que NavigationServer3D estará preparado
	# después de exactamente uno o dos frames.
	# -----------------------------------------------------

	var synchronized := false


	for frame_index in range(
		MAX_SYNC_FRAMES
	):
		var iteration_id := (
			NavigationServer3D.map_get_iteration_id(
				map_rid
			)
		)


		if iteration_id > 0:
			synchronized = true

			print(
				"WorldNavigationRegistry | "
				+
				"Mapa sincronizado",
				" | Frame de espera: ",
				frame_index,
				" | Iteración: ",
				iteration_id
			)

			break


		await get_tree().physics_frame


	if not synchronized:
		push_error(
			"WorldNavigationRegistry | "
			+
			"test_town no logró sincronizarse."
		)

		return ERR_TIMEOUT


	# -----------------------------------------------------
	# SELF TEST
	# -----------------------------------------------------

	var requested_start := Vector3(
		0.0,
		0.3,
		0.0
	)


	var requested_target := Vector3(
		8.0,
		0.3,
		0.0
	)


	# -----------------------------------------------------
	# Proyectamos explícitamente ambos puntos sobre el
	# NavigationMesh para evitar problemas por estar
	# exactamente sobre un borde de polígono.
	# -----------------------------------------------------

	var navigation_start := (
		NavigationServer3D.map_get_closest_point(
			map_rid,
			requested_start
		)
	)


	var navigation_target := (
		NavigationServer3D.map_get_closest_point(
			map_rid,
			requested_target
		)
	)


	print(
		"WorldNavigationRegistry | Self-test",
		" | Inicio: ",
		navigation_start,
		" | Destino: ",
		navigation_target
	)


	var test_path := (
		NavigationServer3D.map_get_path(
			map_rid,
			navigation_start,
			navigation_target,
			true,
			DEFAULT_NAVIGATION_LAYERS
		)
	)


	if test_path.is_empty():
		push_error(
			"WorldNavigationRegistry | "
			+
			"El self-test no pudo resolver una ruta."
		)

		return ERR_CANT_RESOLVE


	initialized = true


	print(
		"WorldNavigationRegistry | Mapa listo",
		" | Map ID: ",
		TEST_TOWN_MAP_ID,
		" | Iteración: ",
		NavigationServer3D.map_get_iteration_id(
			map_rid
		),
		" | Test path points: ",
		test_path.size()
	)


	return OK


# =========================================================
# REGISTRAR MAPA
# =========================================================

func _register_map(
	map_id: String,
	navigation_mesh: NavigationMesh
) -> Error:
	var normalized_map_id := (
		map_id.strip_edges()
	)


	if normalized_map_id.is_empty():
		return ERR_INVALID_PARAMETER


	if navigation_mesh == null:
		return ERR_INVALID_PARAMETER


	if navigation_maps.has(
		normalized_map_id
	):
		return ERR_ALREADY_EXISTS


	print(
		"WorldNavigationRegistry | Registrando mapa: ",
		normalized_map_id
	)


	var map_rid := (
		NavigationServer3D.map_create()
	)


	if not map_rid.is_valid():
		return ERR_CANT_CREATE


	# -----------------------------------------------------
	# Dedicated server:
	#
	# Queremos que la construcción inicial del mapa sea
	# determinista y no quede pendiente en un hilo async.
	# -----------------------------------------------------

	NavigationServer3D.map_set_use_async_iterations(
		map_rid,
		false
	)


	NavigationServer3D.map_set_cell_size(
		map_rid,
		navigation_mesh.cell_size
	)


	NavigationServer3D.map_set_cell_height(
		map_rid,
		navigation_mesh.cell_height
	)


	var region_rid := (
		NavigationServer3D.region_create()
	)


	if not region_rid.is_valid():
		NavigationServer3D.free_rid(
			map_rid
		)

		return ERR_CANT_CREATE


	NavigationServer3D.region_set_use_async_iterations(
		region_rid,
		false
	)


	NavigationServer3D.region_set_navigation_layers(
		region_rid,
		DEFAULT_NAVIGATION_LAYERS
	)


	NavigationServer3D.region_set_navigation_mesh(
		region_rid,
		navigation_mesh
	)


	NavigationServer3D.region_set_transform(
		region_rid,
		Transform3D.IDENTITY
	)


	NavigationServer3D.region_set_map(
		region_rid,
		map_rid
	)


	NavigationServer3D.map_set_active(
		map_rid,
		true
	)


	navigation_maps[
		normalized_map_id
	] = {
		"map_rid": map_rid,
		"region_rid": region_rid,
	}


	print(
		"WorldNavigationRegistry | "
		+
		"RID de mapa y región creados."
	)


	return OK


# =========================================================
# CONSULTAR MAPA
# =========================================================

func has_map(
	map_id: String
) -> bool:
	return navigation_maps.has(
		map_id.strip_edges()
	)


func get_navigation_map(
	map_id: String
) -> RID:
	var normalized_map_id := (
		map_id.strip_edges()
	)


	if not navigation_maps.has(
		normalized_map_id
	):
		return RID()


	var data: Dictionary = (
		navigation_maps[
			normalized_map_id
		]
	)


	var map_rid: RID = (
		data.get(
			"map_rid",
			RID()
		)
	)


	return map_rid


func is_map_ready(
	map_id: String
) -> bool:
	var map_rid := (
		get_navigation_map(
			map_id
		)
	)


	if not map_rid.is_valid():
		return false


	return (
		NavigationServer3D.map_get_iteration_id(
			map_rid
		)
		>
		0
	)


# =========================================================
# BUSCAR RUTA
# =========================================================

func find_path(
	map_id: String,
	origin: Vector3,
	target: Vector3
) -> PackedVector3Array:
	var map_rid := (
		get_navigation_map(
			map_id
		)
	)


	if not map_rid.is_valid():
		return PackedVector3Array()


	if not is_map_ready(
		map_id
	):
		return PackedVector3Array()


	return (
		NavigationServer3D.map_get_path(
			map_rid,
			origin,
			target,
			true,
			DEFAULT_NAVIGATION_LAYERS
		)
	)

# =========================================================
# RESOLVER DESTINO ALCANZABLE
# =========================================================

func resolve_reachable_target(
	map_id: String,
	origin: Vector3,
	requested_target: Vector3
) -> Dictionary:
	if not has_map(
		map_id
	):
		return {
			"ok": false,
			"reason": "map_not_found",
		}


	if not is_map_ready(
		map_id
	):
		return {
			"ok": false,
			"reason": "map_not_ready",
		}


	var path := find_path(
		map_id,
		origin,
		requested_target
	)


	if path.is_empty():
		return {
			"ok": false,
			"reason": "path_not_found",
		}


	var resolved_target: Vector3 = (
		path[
			path.size() - 1
		]
	)


	return {
		"ok": true,

		"requested_target": requested_target,

		"resolved_target": resolved_target,

		"path_points": path.size(),
	}

# =========================================================
# CLEANUP
# =========================================================

func shutdown() -> void:
	for data_value: Variant in navigation_maps.values():
		if typeof(data_value) != TYPE_DICTIONARY:
			continue


		var data: Dictionary = (
			data_value
		)


		var region_rid: RID = (
			data.get(
				"region_rid",
				RID()
			)
		)


		if region_rid.is_valid():
			NavigationServer3D.free_rid(
				region_rid
			)


		var map_rid: RID = (
			data.get(
				"map_rid",
				RID()
			)
		)


		if map_rid.is_valid():
			NavigationServer3D.free_rid(
				map_rid
			)


	navigation_maps.clear()

	initialized = false


func _exit_tree() -> void:
	shutdown()
