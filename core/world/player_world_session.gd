class_name PlayerWorldSession
extends RefCounted


# =========================================================
# IDENTIDAD DE RED
# =========================================================

var peer_id: int = -1

var account_id: int = -1

var character_id: int = -1

var latest_world_drop_pickup_request_id: int = 0

# =========================================================
# PERSONAJE
# =========================================================

var character_name: String = ""

var class_id: String = ""

var level: int = 1

var experience: int = 0

# =========================================================
# RUNTIME DURABLE
# =========================================================

var runtime_revision: int = 0

var runtime_bootstrap_valid: bool = true

# =========================================================
# VITALES AUTORITATIVOS
# =========================================================

var vitals: ServerVitalsState = null


# =========================================================
# SKILLS AUTORITATIVAS
# =========================================================

var skill_runtime: ServerSkillRuntimeState = null

var basic_attack_runtime: ServerBasicAttackRuntimeState = null

var latest_skill_cast_request_id: int = 0

var latest_skill_learning_request_id: int = 0

var latest_basic_attack_request_id: int = 0


# =========================================================
# REQUESTS DE APRENDIZAJE DE SKILLS
# =========================================================

func accept_skill_learning_request_id(
	request_id: int
) -> bool:
	if request_id <= 0:
		return false


	if request_id <= latest_skill_learning_request_id:
		return false


	latest_skill_learning_request_id = request_id


	return true

# =========================================================
# REQUESTS DE SKILLS
# =========================================================

func accept_skill_cast_request_id(
	request_id: int
) -> bool:
	if request_id <= 0:
		return false


	if request_id <= latest_skill_cast_request_id:
		return false


	latest_skill_cast_request_id = request_id


	return true


# =========================================================
# REQUESTS DE BASIC ATTACK
# =========================================================

func accept_basic_attack_request_id(
	request_id: int
) -> bool:
	if request_id <= 0:
		return false


	if request_id <= latest_basic_attack_request_id:
		return false


	latest_basic_attack_request_id = request_id


	return true

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
# EQUIPMENT AUTORITATIVO DEL PERSONAJE
# =========================================================

var equipment_snapshot: Dictionary = {}

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
# SNAPSHOT AUTORITATIVO DE EQUIPMENT
# =========================================================

func set_equipment_snapshot(
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
	).strip_edges() != "equipment":
		return false


	if typeof(
		snapshot.get(
			"items",
			null
		)
	) != TYPE_ARRAY:
		return false


	equipment_snapshot = snapshot.duplicate(
		true
	)


	return true


func get_equipment_snapshot() -> Dictionary:
	return equipment_snapshot.duplicate(
		true
	)


func clear_equipment_snapshot() -> void:
	equipment_snapshot = {}

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

	experience = int(
		character_data.get(
			"experience",
			0
		)
	)

	# -----------------------------------------------------
	# RUNTIME AUTORITATIVO DEL PERSONAJE
	# -----------------------------------------------------

	vitals = (
		ServerCharacterRuntimeBootstrap.create_vitals()
	)


	skill_runtime = (
		_create_skill_runtime_from_character_data(
			character_data
		)
	)

	basic_attack_runtime = (
		ServerCharacterRuntimeBootstrap.create_basic_attack_runtime()
	)

	map_id = (
		p_map_id.strip_edges()
	)

	position = p_position

	rotation_y = p_rotation_y

	_apply_persisted_runtime(
		character_data
	)

# =========================================================
# RESTAURAR SKILL OWNERSHIP DURABLE
# =========================================================

func _create_skill_runtime_from_character_data(
	character_data: Dictionary
) -> ServerSkillRuntimeState:
	var skills_value: Variant = (
		character_data.get(
			"skills",
			null
		)
	)


	if typeof(skills_value) != TYPE_DICTIONARY:
		return null


	var skills: Dictionary = (
		skills_value
	)


	var learned_skill_ids_value: Variant = (
		skills.get(
			"learned_skill_ids",
			null
		)
	)


	if typeof(learned_skill_ids_value) != TYPE_ARRAY:
		return null


	var learned_skill_ids := (
		PackedStringArray()
	)

	var seen_skill_ids: Dictionary = {}


	for skill_id_value: Variant in (
		learned_skill_ids_value
		as Array
	):
		if typeof(skill_id_value) != TYPE_STRING:
			return null


		var skill_id := String(
			skill_id_value
		).strip_edges().to_lower()


		if skill_id.is_empty():
			return null


		if seen_skill_ids.has(
			skill_id
		):
			return null


		seen_skill_ids[
			skill_id
		] = true


		learned_skill_ids.append(
			skill_id
		)


	return (
		ServerCharacterRuntimeBootstrap.create_skill_runtime(
			learned_skill_ids
		)
	)

# =========================================================
# RESTAURAR RUNTIME DURABLE
# =========================================================

func _apply_persisted_runtime(
	character_data: Dictionary
) -> void:
	var runtime_value: Variant = (
		character_data.get(
			"runtime",
			null
		)
	)


	# -----------------------------------------------------
	# Sin checkpoint durable.
	#
	# Es un personaje nuevo o todavía nunca fue guardado.
	#
	# Conservamos:
	# - mapa foundation
	# - spawn foundation
	# - Vitals foundation
	# -----------------------------------------------------

	if runtime_value == null:
		runtime_revision = 0

		return


	if typeof(runtime_value) != TYPE_DICTIONARY:
		runtime_bootstrap_valid = false

		return


	var runtime: Dictionary = (
		runtime_value
	)


	var revision := int(
		runtime.get(
			"revision",
			0
		)
	)


	if revision <= 0:
		runtime_bootstrap_valid = false

		return


	# =====================================================
	# WORLD
	# =====================================================

	var world_value: Variant = (
		runtime.get(
			"world",
			null
		)
	)


	if typeof(world_value) != TYPE_DICTIONARY:
		runtime_bootstrap_valid = false

		return


	var world: Dictionary = (
		world_value
	)


	var persisted_map_id := String(
		world.get(
			"map_id",
			""
		)
	).strip_edges()


	if persisted_map_id.is_empty():
		runtime_bootstrap_valid = false

		return


	var position_value: Variant = (
		world.get(
			"position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		runtime_bootstrap_valid = false

		return


	var persisted_position: Dictionary = (
		position_value
	)


	var restored_position := Vector3(
		float(
			persisted_position.get(
				"x",
				0.0
			)
		),
		float(
			persisted_position.get(
				"y",
				0.0
			)
		),
		float(
			persisted_position.get(
				"z",
				0.0
			)
		)
	)


	var restored_rotation_y := float(
		world.get(
			"rotation_y",
			0.0
		)
	)


	# =====================================================
	# VITALS
	# =====================================================

	var vitals_value: Variant = (
		runtime.get(
			"vitals",
			null
		)
	)


	if typeof(vitals_value) != TYPE_DICTIONARY:
		runtime_bootstrap_valid = false

		return


	var persisted_vitals: Dictionary = (
		vitals_value
	)


	var restored_hp := int(
		persisted_vitals.get(
			"hp",
			-1
		)
	)


	var restored_mp := int(
		persisted_vitals.get(
			"mp",
			-1
		)
	)


	if (
		restored_hp < 0
		or
		restored_mp < 0
	):
		runtime_bootstrap_valid = false

		return


	if vitals == null:
		runtime_bootstrap_valid = false

		return


	# -----------------------------------------------------
	# Aplicar estado.
	#
	# set_hp / set_mp realizan clamp contra los máximos
	# calculados actualmente por el Game Server.
	#
	# Eso es intencional:
	#
	# si en el futuro cambian stats/equipment/max vitals,
	# un checkpoint viejo nunca podrá restaurar HP/MP por
	# encima de los máximos actuales.
	# -----------------------------------------------------

	runtime_revision = revision

	map_id = persisted_map_id

	position = restored_position

	rotation_y = restored_rotation_y


	vitals.set_hp(
		restored_hp
	)

	vitals.set_mp(
		restored_mp
	)

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
		ServerCharacterProgressionRules.is_state_valid(
			level,
			experience
		)
		and
		not class_id.is_empty()
		and
		not map_id.is_empty()
		and
		vitals != null
		and
		vitals.is_valid()
		and
		skill_runtime != null
		and
		skill_runtime.is_valid()
		and
		basic_attack_runtime != null
		and
		basic_attack_runtime.is_valid()
		and
		runtime_bootstrap_valid
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
# SNAPSHOT RUNTIME PERSISTENTE
# =========================================================

func to_persistent_runtime_state() -> Dictionary:
	if vitals == null:
		return {}


	return {
		"world": {
			"map_id": map_id,

			"position": {
				"x": position.x,
				"y": position.y,
				"z": position.z,
			},

			"rotation_y": rotation_y,
		},

		"vitals": {
			"hp": vitals.hp,
			"mp": vitals.mp,
		},
	}

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

		"progression": {
			"level": level,

			"experience": experience,

			"experience_required": (
				ServerCharacterProgressionRules
				.get_experience_required(
					level
				)
			),
		},

		"skills": {
			"learned_skill_ids": Array(
				skill_runtime.get_learned_skill_ids()
			),
		},

		"vitals": vitals.to_snapshot(),

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

func accept_world_drop_pickup_request_id(
	request_id: int
) -> bool:
	if request_id <= 0:
		return false


	if request_id <= latest_world_drop_pickup_request_id:
		return false


	latest_world_drop_pickup_request_id = request_id


	return true
