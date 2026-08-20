class_name PlayerWorldSession
extends RefCounted


# =========================================================
# IDENTIDAD DE RED
# =========================================================

var peer_id: int = -1

var account_id: int = -1

var character_id: int = -1


# =========================================================
# PERSONAJE
# =========================================================

var character_name: String = ""

var class_id: String = ""

var level: int = 1


# =========================================================
# MUNDO AUTORITATIVO
# =========================================================

var map_id: String = ""

var position: Vector3 = Vector3.ZERO

var rotation_y: float = 0.0

# =========================================================
# SERVICIO NPC AUTORITATIVO
# =========================================================

var active_npc_id: String = ""

var active_service_id: String = ""


# =========================================================
# ESTADO AUTORITATIVO DE VAULT
# =========================================================

var active_vault_snapshot: Dictionary = {}

# =========================================================
# INVENTARIO AUTORITATIVO DEL PERSONAJE
# =========================================================

var inventory_snapshot: Dictionary = {}

# =========================================================
# INICIAR SERVICIO NPC
# =========================================================

func begin_npc_service(
	npc_id: String,
	service_id: String
) -> bool:
	var normalized_npc_id := (
		npc_id.strip_edges()
	)


	var normalized_service_id := (
		service_id.strip_edges()
	)


	if normalized_npc_id.is_empty():
		return false


	if normalized_service_id.is_empty():
		return false


	active_npc_id = normalized_npc_id

	active_service_id = normalized_service_id


	return true


# =========================================================
# FINALIZAR SERVICIO NPC
# =========================================================

func end_npc_service() -> void:
	active_npc_id = ""

	active_service_id = ""

	active_vault_snapshot = {}


# =========================================================
# CONSULTAR SERVICIO NPC
# =========================================================

func has_active_npc_service() -> bool:
	return (
		not active_npc_id.is_empty()
		and
		not active_service_id.is_empty()
	)


func is_using_npc_service(
	npc_id: String,
	service_id: String
) -> bool:
	if not has_active_npc_service():
		return false


	return (
		active_npc_id
		==
		npc_id.strip_edges()
		and
		active_service_id
		==
		service_id.strip_edges()
	)

# =========================================================
# SNAPSHOT AUTORITATIVO DE VAULT
# =========================================================

func set_active_vault_snapshot(
	snapshot: Dictionary
) -> bool:
	if snapshot.is_empty():
		return false


	if int(
		snapshot.get(
			"account_id",
			0
		)
	) != account_id:
		return false


	if String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges() != "vault":
		return false


	if typeof(
		snapshot.get(
			"items",
			null
		)
	) != TYPE_ARRAY:
		return false


	active_vault_snapshot = snapshot.duplicate(
		true
	)


	return true


func get_active_vault_snapshot() -> Dictionary:
	return active_vault_snapshot.duplicate(
		true
	)


func clear_active_vault_snapshot() -> void:
	active_vault_snapshot = {}

# =========================================================
# SNAPSHOT AUTORITATIVO DE INVENTORY
# =========================================================

func set_inventory_snapshot(
	snapshot: Dictionary
) -> bool:
	if snapshot.is_empty():
		return false


	if int(
		snapshot.get(
			"account_id",
			0
		)
	) != account_id:
		return false


	if int(
		snapshot.get(
			"character_id",
			0
		)
	) != character_id:
		return false


	if String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges() != "inventory":
		return false


	if typeof(
		snapshot.get(
			"items",
			null
		)
	) != TYPE_ARRAY:
		return false


	inventory_snapshot = snapshot.duplicate(
		true
	)


	return true


func get_inventory_snapshot() -> Dictionary:
	return inventory_snapshot.duplicate(
		true
	)


func clear_inventory_snapshot() -> void:
	inventory_snapshot = {}

# =========================================================
# INTENCIÓN DE MOVIMIENTO
# =========================================================

var requested_move_target: Vector3 = Vector3.ZERO

var has_requested_move_target: bool = false

var authorized_move_target: Vector3 = Vector3.ZERO

var has_authorized_move_target: bool = false

var authorized_path: PackedVector3Array = (
	PackedVector3Array()
)

var authorized_path_index: int = 0

# =========================================================
# REGISTRAR INTENCIÓN DE MOVIMIENTO
# =========================================================

func request_move_to(
	target: Vector3
) -> void:
	requested_move_target = target

	has_requested_move_target = true


	# -----------------------------------------------------
	# Una nueva intención invalida cualquier autorización
	# anterior hasta que el servidor vuelva a resolverla.
	# -----------------------------------------------------

	authorized_move_target = Vector3.ZERO

	has_authorized_move_target = false

	authorized_path = PackedVector3Array()

	authorized_path_index = 0

func authorize_move_path(
	path: PackedVector3Array
) -> bool:
	if path.is_empty():
		return false


	authorized_path = path

	authorized_path_index = (
		1
		if
		path.size() > 1
		else
		0
	)


	authorized_move_target = (
		path[
			path.size() - 1
		]
	)


	has_authorized_move_target = true

	has_requested_move_target = false


	return true


func reject_move_request() -> void:
	requested_move_target = Vector3.ZERO

	has_requested_move_target = false

	authorized_move_target = Vector3.ZERO

	has_authorized_move_target = false

	authorized_path = PackedVector3Array()

	authorized_path_index = 0

func clear_move_request() -> void:
	requested_move_target = Vector3.ZERO

	has_requested_move_target = false

	authorized_move_target = Vector3.ZERO

	has_authorized_move_target = false

	authorized_path = PackedVector3Array()

	authorized_path_index = 0

# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_peer_id: int,
	p_account_id: int,
	character_data: Dictionary,
	p_map_id: String,
	p_position: Vector3 = Vector3.ZERO,
	p_rotation_y: float = 0.0
) -> void:
	peer_id = p_peer_id

	account_id = p_account_id


	character_id = int(
		character_data.get(
			"id",
			-1
		)
	)


	character_name = String(
		character_data.get(
			"name",
			""
		)
	)


	class_id = String(
		character_data.get(
			"class_id",
			""
		)
	)


	level = int(
		character_data.get(
			"level",
			1
		)
	)


	map_id = (
		p_map_id.strip_edges()
	)

	position = p_position

	rotation_y = p_rotation_y


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		peer_id > 1
		and
		account_id > 0
		and
		character_id > 0
		and
		not character_name.is_empty()
		and
		not class_id.is_empty()
		and
		not map_id.is_empty()
	)


# =========================================================
# ACTUALIZAR TRANSFORM
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
	return {
		"peer_id": peer_id,
		"account_id": account_id,

		"character": {
			"id": character_id,
			"name": character_name,
			"class_id": class_id,
			"level": level,
		},

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

# =========================================================
# SNAPSHOT PÚBLICO DE PRESENCIA
# =========================================================

func to_presence_snapshot() -> Dictionary:
	return {
		"peer_id": peer_id,

		"character": {
			"id": character_id,
			"name": character_name,
			"class_id": class_id,
			"level": level,
		},

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
