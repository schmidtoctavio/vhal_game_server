class_name ServerItemCatalog
extends RefCounted


# =========================================================
# DEFINICIONES AUTORITATIVAS
# =========================================================
#
# Sólo almacenamos metadata que afecta reglas del servidor.
#
# No:
# - iconos
# - textos
# - tooltips
# - presentación
#
# Sí:
# - tamaño
# - stack
# - clasificación de Equipment
# - modo de mano
# =========================================================

const DEFINITIONS: Dictionary = {
	"bronze_sword": {
		"grid_width": 1,
		"grid_height": 3,
		"max_stack": 1,

		"equipment_category_id": "weapon",
		"hand_equip_mode_id": "one_hand",

		"basic_attack_mode_id": "melee",
	},

	"health_potion": {
		"grid_width": 1,
		"grid_height": 1,
		"max_stack": 50,

		"equipment_category_id": "none",
		"hand_equip_mode_id": "none",
		"basic_attack_mode_id": "none",
	},

	"leather_helmet": {
		"grid_width": 2,
		"grid_height": 2,
		"max_stack": 1,

		"equipment_category_id": "head",
		"hand_equip_mode_id": "none",
		"basic_attack_mode_id": "none",
	},
}


# =========================================================
# CONSULTAR
# =========================================================

static func has_definition(
	item_id: String
) -> bool:
	var normalized_id := (
		item_id.strip_edges()
	)


	return DEFINITIONS.has(
		normalized_id
	)


static func get_definition(
	item_id: String
) -> Dictionary:
	var normalized_id := (
		item_id.strip_edges()
	)


	if not DEFINITIONS.has(
		normalized_id
	):
		return {}


	var definition_value: Variant = (
		DEFINITIONS[
			normalized_id
		]
	)


	if typeof(definition_value) != TYPE_DICTIONARY:
		return {}


	return (
		definition_value as Dictionary
	).duplicate(
		true
	)
