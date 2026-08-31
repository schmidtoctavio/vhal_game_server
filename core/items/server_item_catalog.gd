class_name ServerItemCatalog
extends RefCounted

# =========================================================
# IDS
# =========================================================

const SKILL_SCROLL_FIRE_BALL_ID: String = (
	"skill_scroll_fire_ball"
)

const SKILL_SCROLL_POISON_ID: String = (
	"skill_scroll_poison"
)

const SKILL_SCROLL_HEAL_ID: String = (
	"skill_scroll_heal"
)

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
		"allowed_class_ids": [
			"warrior",
		],

		"base_requirements": {
			"level": 1,
			"strength": 15,
			"agility": 0,
			"vitality": 0,
			"energy": 0,
		},

		"enhancement_profile_id": (
			"one_hand_weapon_v1"
		),

		"fixed_modifiers": [],

		"basic_attack_mode_id": "melee",

		"basic_attack_base_damage": 1000,

		"basic_attack_range": 2.0,

		"basic_attack_cooldown_seconds": 0.9,
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

		"allowed_class_ids": [
			"warrior",
			"archer",
		],

		"base_requirements": {
			"level": 1,
			"strength": 15,
			"agility": 15,
			"vitality": 0,
			"energy": 0,
		},

		"enhancement_profile_id": (
			"light_armor_v1"
		),

		"fixed_modifiers": [
			{
				"stat_id": "super_strength",
				"operation_id": "flat_add",
				"value": 5,
			},
		],

		"base_armor_rating": 20,

		"basic_attack_mode_id": "none",
	},

	SKILL_SCROLL_FIRE_BALL_ID: {
		"grid_width": 1,
		"grid_height": 2,
		"max_stack": 1,

		"equipment_category_id": "none",
		"hand_equip_mode_id": "none",
		"basic_attack_mode_id": "none",
	},

	SKILL_SCROLL_POISON_ID: {
		"grid_width": 1,
		"grid_height": 2,
		"max_stack": 1,

		"equipment_category_id": "none",
		"hand_equip_mode_id": "none",
		"basic_attack_mode_id": "none",
	},

	SKILL_SCROLL_HEAL_ID: {
		"grid_width": 1,
		"grid_height": 2,
		"max_stack": 1,

		"equipment_category_id": "none",
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
