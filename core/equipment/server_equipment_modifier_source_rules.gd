class_name ServerEquipmentModifierSourceRules
extends RefCounted


# =========================================================
# DEFINITION / INSTANCE KEYS
# =========================================================

const FIXED_MODIFIERS_KEY: String = (
	"fixed_modifiers"
)

const STATE_KEY: String = (
	"state"
)

const ROLLED_MODIFIERS_STATE_KEY: String = (
	"rolled_modifiers"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# F22-I distingue dos fuentes de Stat Modifiers:
#
# FIXED MODIFIERS
# → pertenecen a Item Definition.
# → todas las instancias de ese item los poseen.
#
# ROLLED MODIFIERS
# → pertenecen a Item Instance.state.
# → son propios de una instancia concreta.
#
#
# Ejemplo conceptual:
#
# Definition:
#
# "fixed_modifiers": [
#     {
#         "stat_id": "agility",
#         "operation_id": "flat_add",
#         "value": 2,
#     },
# ]
#
#
# Instance:
#
# "state": {
#     "enhancement_level": 7,
#
#     "rolled_modifiers": [
#         {
#             "stat_id": "vitality",
#             "operation_id": "flat_add",
#             "value": 4,
#         },
#     ],
# }
#
#
# IMPORTANTE:
#
# Enhancement NO es un Stat Modifier.
#
# Base Item Stat NO es un Stat Modifier.
#
# Special Effects tampoco pertenecen a este contrato.
# =========================================================


# =========================================================
# VALIDAR CONTRATO GLOBAL
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# DEFINITIONS REALES
	# -----------------------------------------------------

	for raw_item_id: Variant in (
		ServerItemCatalog.DEFINITIONS.keys()
	):
		var item_id := String(
			raw_item_id
		).strip_edges()


		if item_id.is_empty():
			return (
				"Existe Item Definition sin ID."
			)


		var definition := (
			ServerItemCatalog.get_definition(
				item_id
			)
		)


		if definition.is_empty():
			return (
				"No se pudo resolver Definition: "
				+
				item_id
			)


		var is_equipment := (
			ServerEquipmentRules
			.is_equipment_definition(
				definition
			)
		)


		if not is_equipment:
			if definition.has(
				FIXED_MODIFIERS_KEY
			):
				return (
					item_id
					+
					" | Un item no-Equipment "
					+
					"no debe declarar fixed_modifiers."
				)


			continue


		var definition_error := (
			validate_definition(
				definition
			)
		)


		if not definition_error.is_empty():
			return (
				item_id
				+
				" | "
				+
				definition_error
			)


	# -----------------------------------------------------
	# FIXED MODIFIER POSITIVO
	# -----------------------------------------------------

	var valid_fixed_modifiers := [
		{
			"stat_id": "agility",
			"operation_id": "flat_add",
			"value": 2,
		},
	]


	var fixed_error := (
		validate_modifier_array(
			valid_fixed_modifiers,
			"fixed_modifiers"
		)
	)


	if not fixed_error.is_empty():
		return (
			"Fixed modifier válido rechazado: "
			+
			fixed_error
		)


	# -----------------------------------------------------
	# ROLLED MODIFIERS POSITIVOS
	# -----------------------------------------------------

	var helmet_definition := (
		ServerItemCatalog.get_definition(
			"leather_helmet"
		)
	)


	if helmet_definition.is_empty():
		return (
			"No existe leather_helmet para self-test."
		)


	var rolled_item := {
		"uid": "modifier-source-rolled-valid",

		"item_id": "leather_helmet",

		"state": {
			"enhancement_level": 7,

			"rolled_modifiers": [
				{
					"stat_id": "vitality",
					"operation_id": "flat_add",
					"value": 4,
				},

				{
					"stat_id": "armor_rating",
					"operation_id": "flat_add",
					"value": 8,
				},
			],
		},
	}


	var rolled_error := (
		validate_item_instance(
			rolled_item,
			helmet_definition
		)
	)


	if not rolled_error.is_empty():
		return (
			"Rolled modifiers válidos rechazados: "
			+
			rolled_error
		)


	var resolved_rolled := (
		get_rolled_modifiers(
			rolled_item,
			helmet_definition
		)
	)


	if resolved_rolled.size() != 2:
		return (
			"Rolled modifiers válidos no se "
			+
			"resolvieron correctamente."
		)


	# -----------------------------------------------------
	# LEGACY STATE []
	# -----------------------------------------------------

	var legacy_item := {
		"uid": "modifier-source-legacy",

		"item_id": "leather_helmet",

		"state": [],
	}


	var legacy_error := (
		validate_item_instance(
			legacy_item,
			helmet_definition
		)
	)


	if not legacy_error.is_empty():
		return (
			"State legacy [] fue rechazado: "
			+
			legacy_error
		)


	if not (
		get_rolled_modifiers(
			legacy_item,
			helmet_definition
		)
		.is_empty()
	):
		return (
			"State legacy [] produjo rolled modifiers."
		)


	# -----------------------------------------------------
	# DUPLICADO DENTRO DE LA MISMA FUENTE
	# -----------------------------------------------------

	var duplicate_modifiers := [
		{
			"stat_id": "vitality",
			"operation_id": "flat_add",
			"value": 2,
		},

		{
			"stat_id": "vitality",
			"operation_id": "flat_add",
			"value": 3,
		},
	]


	if (
		validate_modifier_array(
			duplicate_modifiers,
			"duplicate_self_test"
		)
		.is_empty()
	):
		return (
			"El contrato permitió modifiers duplicados "
			+
			"dentro de una misma fuente."
		)


	# -----------------------------------------------------
	# ROLLED MODIFIERS EN NON-EQUIPMENT
	# -----------------------------------------------------

	var potion_definition := (
		ServerItemCatalog.get_definition(
			"health_potion"
		)
	)


	if potion_definition.is_empty():
		return (
			"No existe health_potion para self-test."
		)


	var enhanced_potion := {
		"uid": "modifier-source-potion",

		"item_id": "health_potion",

		"state": {
			"rolled_modifiers": [
				{
					"stat_id": "vitality",
					"operation_id": "flat_add",
					"value": 1,
				},
			],
		},
	}


	if (
		validate_item_instance(
			enhanced_potion,
			potion_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió rolled_modifiers "
			+
			"en un item no-Equipment."
		)


	# -----------------------------------------------------
	# ROLLED MODIFIERS DEBEN SER ARRAY
	# -----------------------------------------------------

	var malformed_item := {
		"uid": "modifier-source-malformed",

		"item_id": "leather_helmet",

		"state": {
			"rolled_modifiers": {
				"stat_id": "vitality",
			},
		},
	}


	if (
		validate_item_instance(
			malformed_item,
			helmet_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió rolled_modifiers "
			+
			"con shape inválido."
		)


	return ""


# =========================================================
# VALIDAR ITEM DEFINITION
# =========================================================

static func validate_definition(
	definition: Dictionary
) -> String:
	if definition.is_empty():
		return (
			"Definition vacía."
		)


	if not (
		ServerEquipmentRules
		.is_equipment_definition(
			definition
		)
	):
		return (
			"La Definition no representa Equipment."
		)


	if not definition.has(
		FIXED_MODIFIERS_KEY
	):
		return (
			"Falta fixed_modifiers."
		)


	var modifiers_value: Variant = (
		definition[
			FIXED_MODIFIERS_KEY
		]
	)


	return (
		validate_modifier_array(
			modifiers_value,
			FIXED_MODIFIERS_KEY
		)
	)


# =========================================================
# VALIDAR ITEM INSTANCE
# =========================================================

static func validate_item_instance(
	item: Dictionary,
	definition: Dictionary
) -> String:
	if definition.is_empty():
		return (
			"Definition vacía."
		)


	var state_value: Variant = (
		item.get(
			STATE_KEY,
			null
		)
	)


	# -----------------------------------------------------
	# LEGACY: STATE AUSENTE / NULL
	# -----------------------------------------------------

	if typeof(state_value) == TYPE_NIL:
		return ""


	# -----------------------------------------------------
	# LEGACY: []
	# -----------------------------------------------------

	if typeof(state_value) == TYPE_ARRAY:
		var legacy_state: Array = (
			state_value as Array
		)


		if legacy_state.is_empty():
			return ""


		return (
			"state Array no vacío no está soportado."
		)


	# -----------------------------------------------------
	# CANÓNICO: DICTIONARY
	# -----------------------------------------------------

	if typeof(state_value) != TYPE_DICTIONARY:
		return (
			"state debe ser Dictionary, "
			+
			"null o [] legacy vacío."
		)


	var state: Dictionary = (
		state_value as Dictionary
	)


	if not state.has(
		ROLLED_MODIFIERS_STATE_KEY
	):
		return ""


	# -----------------------------------------------------
	# ROLLED MODIFIERS SON EXCLUSIVOS DE EQUIPMENT
	# -----------------------------------------------------

	if not (
		ServerEquipmentRules
		.is_equipment_definition(
			definition
		)
	):
		return (
			"Un item no-Equipment no puede declarar "
			+
			"rolled_modifiers."
		)


	var modifiers_value: Variant = (
		state[
			ROLLED_MODIFIERS_STATE_KEY
		]
	)


	return (
		validate_modifier_array(
			modifiers_value,
			ROLLED_MODIFIERS_STATE_KEY
		)
	)


# =========================================================
# VALIDAR ARRAY DE MODIFIERS
# =========================================================

static func validate_modifier_array(
	modifiers_value: Variant,
	source_label: String
) -> String:
	if typeof(modifiers_value) != TYPE_ARRAY:
		return (
			source_label
			+
			" debe ser Array."
		)


	var modifiers: Array = (
		modifiers_value as Array
	)


	var seen_modifier_keys: Dictionary = {}


	for modifier_value: Variant in modifiers:
		if typeof(modifier_value) != TYPE_DICTIONARY:
			return (
				source_label
				+
				" contiene modifier no-Dictionary."
			)


		var modifier: Dictionary = (
			modifier_value as Dictionary
		)


		var modifier_error := (
			ServerEquipmentStatModifierRules
			.validate_modifier(
				modifier
			)
		)


		if not modifier_error.is_empty():
			return (
				source_label
				+
				" | "
				+
				modifier_error
			)


		var stat_id := (
			ServerEquipmentStatModifierCatalog
			.normalize_stat_id(
				modifier[
					ServerEquipmentStatModifierRules
					.STAT_ID_KEY
				]
			)
		)


		var operation_id := (
			ServerEquipmentStatModifierCatalog
			.normalize_operation_id(
				modifier[
					ServerEquipmentStatModifierRules
					.OPERATION_ID_KEY
				]
			)
		)


		var modifier_key := (
			String(stat_id)
			+
			"|"
			+
			String(operation_id)
		)


		if seen_modifier_keys.has(
			modifier_key
		):
			return (
				source_label
				+
				" contiene modifier duplicado: "
				+
				modifier_key
			)


		seen_modifier_keys[
			modifier_key
		] = true


	return ""


# =========================================================
# FIXED MODIFIERS
# =========================================================

static func get_fixed_modifiers(
	definition: Dictionary
) -> Array:
	var validation_error := (
		validate_definition(
			definition
		)
	)


	if not validation_error.is_empty():
		return []


	var modifiers_value: Variant = (
		definition[
			FIXED_MODIFIERS_KEY
		]
	)


	return (
		modifiers_value as Array
	).duplicate(
		true
	)


# =========================================================
# ROLLED MODIFIERS
# =========================================================

static func get_rolled_modifiers(
	item: Dictionary,
	definition: Dictionary
) -> Array:
	var validation_error := (
		validate_item_instance(
			item,
			definition
		)
	)


	if not validation_error.is_empty():
		return []


	var state_value: Variant = (
		item.get(
			STATE_KEY,
			null
		)
	)


	if typeof(state_value) != TYPE_DICTIONARY:
		return []


	var state: Dictionary = (
		state_value as Dictionary
	)


	if not state.has(
		ROLLED_MODIFIERS_STATE_KEY
	):
		return []


	var modifiers_value: Variant = (
		state[
			ROLLED_MODIFIERS_STATE_KEY
		]
	)


	if typeof(modifiers_value) != TYPE_ARRAY:
		return []


	return (
		modifiers_value as Array
	).duplicate(
		true
	)


# =========================================================
# TODAS LAS FUENTES
# =========================================================

static func get_all_modifiers(
	item: Dictionary,
	definition: Dictionary
) -> Array:
	var definition_error := (
		validate_definition(
			definition
		)
	)


	if not definition_error.is_empty():
		return []


	var item_error := (
		validate_item_instance(
			item,
			definition
		)
	)


	if not item_error.is_empty():
		return []


	var result: Array = []


	var fixed_modifiers := (
		get_fixed_modifiers(
			definition
		)
	)


	for modifier: Variant in fixed_modifiers:
		result.append(
			(
				modifier as Dictionary
			).duplicate(
				true
			)
		)


	var rolled_modifiers := (
		get_rolled_modifiers(
			item,
			definition
		)
	)


	for modifier: Variant in rolled_modifiers:
		result.append(
			(
				modifier as Dictionary
			).duplicate(
				true
			)
		)


	return result
