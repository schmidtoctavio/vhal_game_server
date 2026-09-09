class_name ServerPvpPolicy
extends RefCounted


# =========================================================
# POLICY IDS
# =========================================================

const TEST_TOWN_MAP_ID: String = "test_town"


# =========================================================
# SAFE ZONE TEMPORAL DE FOUNDATION
#
# test_town:
#
# Spawn = (0, 0, 0)
#
# Los primeros 3 metros alrededor del spawn quedan
# protegidos.
#
# Esta geometría existe exclusivamente en Game Server.
# El Client nunca decide si una posición es segura.
#
# Más adelante cada mapa podrá exportar/configurar sus
# regiones PvP sin cambiar el Combat Pipeline.
# =========================================================

const TEST_TOWN_SAFE_ZONE_CENTER: Vector3 = (
	Vector3.ZERO
)

const TEST_TOWN_SAFE_ZONE_RADIUS: float = 3.0


# =========================================================
# MAP POLICY
# =========================================================

static func is_pvp_enabled(
	map_id: String
) -> bool:
	var normalized_map_id := (
		map_id.strip_edges()
	)


	match normalized_map_id:
		TEST_TOWN_MAP_ID:
			return true


	return false


# =========================================================
# SAFE ZONE
# =========================================================

static func is_safe_zone(
	map_id: String,
	position: Vector3
) -> bool:
	var normalized_map_id := (
		map_id.strip_edges()
	)


	match normalized_map_id:
		TEST_TOWN_MAP_ID:
			var position_xz := Vector2(
				position.x,
				position.z
			)


			var center_xz := Vector2(
				TEST_TOWN_SAFE_ZONE_CENTER.x,
				TEST_TOWN_SAFE_ZONE_CENTER.z
			)


			return (
				position_xz.distance_to(
					center_xz
				)
				<=
				TEST_TOWN_SAFE_ZONE_RADIUS
			)


	return true


# =========================================================
# ENGAGEMENT
# =========================================================

static func validate_engagement(
	attacker: PlayerWorldSession,
	target: PlayerWorldSession
) -> String:
	if attacker == null:
		return "invalid_attacker"


	if target == null:
		return "target_not_found"


	if (
		attacker.peer_id <= 1
		or
		target.peer_id <= 1
	):
		return "invalid_target"


	# -----------------------------------------------------
	# SELF PvP
	# -----------------------------------------------------

	if attacker.peer_id == target.peer_id:
		return "cannot_target_self"


	# -----------------------------------------------------
	# ALIVE
	# -----------------------------------------------------

	if (
		attacker.vitals == null
		or
		attacker.vitals.hp <= 0
	):
		return "character_not_alive"


	if (
		target.vitals == null
		or
		target.vitals.hp <= 0
	):
		return "target_not_alive"


	# -----------------------------------------------------
	# MAP
	# -----------------------------------------------------

	if attacker.map_id != target.map_id:
		return "target_wrong_map"


	if not is_pvp_enabled(
		attacker.map_id
	):
		return "pvp_disabled"


	# -----------------------------------------------------
	# NPC SERVICE
	#
	# No iniciamos PvP mientras alguno está dentro de una
	# operación autoritativa de NPC/Vault/Trainer.
	# -----------------------------------------------------

	if attacker.has_active_npc_service():
		return "attacker_busy"


	if target.has_active_npc_service():
		return "target_busy"


	# -----------------------------------------------------
	# SAFE ZONE
	#
	# Ambos extremos deben estar fuera.
	# -----------------------------------------------------

	if is_safe_zone(
		attacker.map_id,
		attacker.position
	):
		return "attacker_safe_zone"


	if is_safe_zone(
		target.map_id,
		target.position
	):
		return "target_safe_zone"


	return ""


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	if not is_pvp_enabled(
		TEST_TOWN_MAP_ID
	):
		return (
			"test_town debe permitir PvP fuera de Safe Zone."
		)


	if is_pvp_enabled(
		"unknown_map"
	):
		return (
			"Un mapa sin policy explícita habilitó PvP."
		)


	if not is_safe_zone(
		TEST_TOWN_MAP_ID,
		Vector3.ZERO
	):
		return (
			"Spawn de test_town debe pertenecer a Safe Zone."
		)


	if not is_safe_zone(
		TEST_TOWN_MAP_ID,
		Vector3(
			3.0,
			0.0,
			0.0
		)
	):
		return (
			"El borde de Safe Zone debe seguir protegido."
		)


	if is_safe_zone(
		TEST_TOWN_MAP_ID,
		Vector3(
			3.01,
			0.0,
			0.0
		)
	):
		return (
			"Una posición exterior fue marcada Safe Zone."
		)


	if not is_safe_zone(
		"unknown_map",
		Vector3(
			100.0,
			0.0,
			100.0
		)
	):
		return (
			"Mapa desconocido debe ser seguro por defecto."
		)


	return ""
