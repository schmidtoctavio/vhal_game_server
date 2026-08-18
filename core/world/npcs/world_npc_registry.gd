class_name WorldNpcRegistry
extends Node


# =========================================================
# NPCs
# =========================================================

var npc_definitions: Dictionary = {}


# =========================================================
# INICIALIZACIÓN
# =========================================================

func initialize() -> Error:
	npc_definitions.clear()


	var warehouse_keeper := (
		WorldNpcDefinition.create(
			"warehouse_keeper",
			"warehouse",
			"test_town",
			Vector3(
				-3.0,
				0.0,
				-3.0
			),
			0.0,
			2.5
		)
	)


	if not _register_definition(
		warehouse_keeper
	):
		return ERR_INVALID_DATA


	print(
		"WorldNpcRegistry | Inicializado",
		" | NPCs: ",
		npc_definitions.size()
	)


	return OK


# =========================================================
# REGISTRAR
# =========================================================

func _register_definition(
	definition: WorldNpcDefinition
) -> bool:
	if definition == null:
		return false


	if not definition.is_valid():
		return false


	if npc_definitions.has(
		definition.npc_id
	):
		return false


	npc_definitions[
		definition.npc_id
	] = definition


	return true


# =========================================================
# CONSULTAR
# =========================================================

func get_definition(
	npc_id: String
) -> WorldNpcDefinition:
	var normalized_id := (
		npc_id.strip_edges()
	)


	if normalized_id.is_empty():
		return null


	if not npc_definitions.has(
		normalized_id
	):
		return null


	return (
		npc_definitions[
			normalized_id
		]
		as WorldNpcDefinition
	)


# =========================================================
# EXISTENCIA
# =========================================================

func has_npc(
	npc_id: String
) -> bool:
	return (
		get_definition(
			npc_id
		)
		!=
		null
	)
