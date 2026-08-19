class_name ServerItemCatalog
extends RefCounted


# =========================================================
# DEFINICIONES AUTORITATIVAS
# =========================================================
#
# El cliente puede tener iconos, nombres, tooltips, etc.
#
# El Game Server sólo necesita, por ahora, propiedades que
# afectan reglas autoritativas.
# =========================================================

const DEFINITIONS: Dictionary = {
	"bronze_sword": {
		"grid_width": 1,
		"grid_height": 3,
		"max_stack": 1,
	},

	"health_potion": {
		"grid_width": 1,
		"grid_height": 1,
		"max_stack": 50,
	},

	"leather_helmet": {
		"grid_width": 2,
		"grid_height": 2,
		"max_stack": 1,
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
