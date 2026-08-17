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
# INTENCIÓN DE MOVIMIENTO
# =========================================================

var requested_move_target: Vector3 = Vector3.ZERO

var has_requested_move_target: bool = false

# =========================================================
# REGISTRAR INTENCIÓN DE MOVIMIENTO
# =========================================================

func request_move_to(
	target: Vector3
) -> void:
	requested_move_target = target

	has_requested_move_target = true


func clear_move_request() -> void:
	requested_move_target = Vector3.ZERO

	has_requested_move_target = false

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
