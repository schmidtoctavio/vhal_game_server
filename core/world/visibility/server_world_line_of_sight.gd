class_name ServerWorldLineOfSight
extends RefCounted


# =========================================================
# FOUNDATION
# =========================================================

const AXIS_EPSILON: float = 0.000001


# =========================================================
# GEOMETRÍA AUTORITATIVA DE VISIBILIDAD
#
# F28-B foundation:
#
# test_town posee actualmente un DebugObstacle:
#
# center = (4, 0, 0)
# size   = (2, 2, 2)
#
# Footprint XZ:
#
# x = 3 .. 5
# z = -1 .. 1
#
# El Client conserva la representación física/visual.
# El Game Server conserva la geometría necesaria para
# autoridad de gameplay.
# =========================================================

const BLOCKERS_BY_MAP: Dictionary = {
	"test_town": [
		{
			"blocker_id": "debug_obstacle",

			"min_x": 3.0,
			"max_x": 5.0,

			"min_z": -1.0,
			"max_z": 1.0,
		},
	],
}


# =========================================================
# CONSULTAR LOS
# =========================================================

static func has_line_of_sight(
	map_id: String,
	origin: Vector3,
	target: Vector3
) -> bool:
	var normalized_map_id := (
		map_id
		.strip_edges()
		.to_lower()
	)


	if normalized_map_id.is_empty():
		return false


	var blockers_value: Variant = (
		BLOCKERS_BY_MAP.get(
			normalized_map_id,
			[]
		)
	)


	if typeof(blockers_value) != TYPE_ARRAY:
		return false


	var blockers: Array = (
		blockers_value
	)


	var origin_xz := Vector2(
		origin.x,
		origin.z
	)

	var target_xz := Vector2(
		target.x,
		target.z
	)


	for blocker_value: Variant in blockers:
		if typeof(blocker_value) != TYPE_DICTIONARY:
			return false


		var blocker: Dictionary = (
			blocker_value
		)


		if not _is_blocker_valid(
			blocker
		):
			return false


		if _segment_intersects_blocker(
			origin_xz,
			target_xz,
			blocker
		):
			return false


	return true


# =========================================================
# VALIDAR BLOCKER
# =========================================================

static func _is_blocker_valid(
	blocker: Dictionary
) -> bool:
	var min_x := float(
		blocker.get(
			"min_x",
			0.0
		)
	)

	var max_x := float(
		blocker.get(
			"max_x",
			0.0
		)
	)

	var min_z := float(
		blocker.get(
			"min_z",
			0.0
		)
	)

	var max_z := float(
		blocker.get(
			"max_z",
			0.0
		)
	)


	return (
		max_x > min_x
		and
		max_z > min_z
	)


# =========================================================
# SEGMENTO VS RECTÁNGULO XZ
#
# Slab intersection:
#
# t = 0 → origin
# t = 1 → target
# =========================================================

static func _segment_intersects_blocker(
	origin: Vector2,
	target: Vector2,
	blocker: Dictionary
) -> bool:
	var min_x := float(
		blocker.get(
			"min_x",
			0.0
		)
	)

	var max_x := float(
		blocker.get(
			"max_x",
			0.0
		)
	)

	var min_z := float(
		blocker.get(
			"min_z",
			0.0
		)
	)

	var max_z := float(
		blocker.get(
			"max_z",
			0.0
		)
	)


	var delta := (
		target
		-
		origin
	)


	var t_min := 0.0
	var t_max := 1.0


	# -----------------------------------------------------
	# EJE X
	# -----------------------------------------------------

	if absf(
		delta.x
	) <= AXIS_EPSILON:
		if (
			origin.x < min_x
			or
			origin.x > max_x
		):
			return false

	else:
		var tx_1 := (
			(min_x - origin.x)
			/
			delta.x
		)

		var tx_2 := (
			(max_x - origin.x)
			/
			delta.x
		)


		var tx_min := minf(
			tx_1,
			tx_2
		)

		var tx_max := maxf(
			tx_1,
			tx_2
		)


		t_min = maxf(
			t_min,
			tx_min
		)

		t_max = minf(
			t_max,
			tx_max
		)


		if t_min > t_max:
			return false


	# -----------------------------------------------------
	# EJE Z
	# -----------------------------------------------------

	if absf(
		delta.y
	) <= AXIS_EPSILON:
		if (
			origin.y < min_z
			or
			origin.y > max_z
		):
			return false

	else:
		var tz_1 := (
			(min_z - origin.y)
			/
			delta.y
		)

		var tz_2 := (
			(max_z - origin.y)
			/
			delta.y
		)


		var tz_min := minf(
			tz_1,
			tz_2
		)

		var tz_max := maxf(
			tz_1,
			tz_2
		)


		t_min = maxf(
			t_min,
			tz_min
		)

		t_max = minf(
			t_max,
			tz_max
		)


		if t_min > t_max:
			return false


	return true


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# BLOQUEADO
	#
	# Línea vertical en XZ atravesando directamente
	# DebugObstacle.
	# -----------------------------------------------------

	if has_line_of_sight(
		"test_town",
		Vector3(
			4.0,
			0.0,
			-2.0
		),
		Vector3(
			4.0,
			0.0,
			3.0
		)
	):
		return (
			"DebugObstacle no bloqueó una línea "
			+
			"que atraviesa su footprint."
		)


	# -----------------------------------------------------
	# LIBRE
	# -----------------------------------------------------

	if not has_line_of_sight(
		"test_town",
		Vector3(
			0.0,
			0.0,
			0.0
		),
		Vector3(
			2.0,
			0.0,
			4.0
		)
	):
		return (
			"Una línea libre fue bloqueada incorrectamente."
		)


	# -----------------------------------------------------
	# MAPA SIN BLOCKERS REGISTRADOS
	# -----------------------------------------------------

	if not has_line_of_sight(
		"empty_test_map",
		Vector3.ZERO,
		Vector3(
			10.0,
			0.0,
			10.0
		)
	):
		return (
			"Un mapa sin blockers debe resolver LOS libre."
		)


	return ""
