class_name ServerEquipmentEnhancementInstanceRules
extends RefCounted


# =========================================================
# INSTANCE STATE
# =========================================================

const STATE_KEY: String = (
	"state"
)

const ENHANCEMENT_LEVEL_STATE_KEY: String = (
	"enhancement_level"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Enhancement Level pertenece a la INSTANCIA durable.
#
# No:
#
# leather_helmet_plus_7
#
# Sí:
#
# item_id = leather_helmet
# state = {
#     "enhancement_level": 7
# }
#
#
# COMPATIBILIDAD LEGACY:
#
# Los ItemInstance existentes pueden tener:
#
# - state inexistente
# - state = null
# - state = []
# - state = {}
#
# Todos representan Enhancement +0.
#
# Un Array no vacío NO es estado canónico soportado.
#
# Hacia adelante, el estado estructurado de una instancia
# debe representarse mediante Dictionary / JSON Object.
# =========================================================


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var sword_definition := (
		ServerItemCatalog.get_definition(
			"bronze_sword"
		)
	)


	if sword_definition.is_empty():
		return (
			"No existe bronze_sword para self-test."
		)


	var max_level := (
		ServerEquipmentEnhancementRules
		.get_max_enhancement_level(
			sword_definition
		)
	)


	if max_level < 0:
		return (
			"No se pudo resolver Max Enhancement "
			+
			"para bronze_sword."
		)


	# -----------------------------------------------------
	# LEGACY — STATE AUSENTE
	# -----------------------------------------------------

	var legacy_missing_state := {
		"uid": "enhancement-legacy-missing",
		"item_id": "bronze_sword",
	}


	var legacy_missing_error := (
		validate_item_instance(
			legacy_missing_state,
			sword_definition
		)
	)


	if not legacy_missing_error.is_empty():
		return (
			"State legacy ausente rechazado: "
			+
			legacy_missing_error
		)


	if (
		get_enhancement_level(
			legacy_missing_state,
			sword_definition
		)
		!=
		0
	):
		return (
			"State legacy ausente no resolvió +0."
		)


	# -----------------------------------------------------
	# LEGACY — ARRAY VACÍO
	# -----------------------------------------------------

	var legacy_array_state := {
		"uid": "enhancement-legacy-array",
		"item_id": "bronze_sword",

		"state": [],
	}


	var legacy_array_error := (
		validate_item_instance(
			legacy_array_state,
			sword_definition
		)
	)


	if not legacy_array_error.is_empty():
		return (
			"State legacy [] rechazado: "
			+
			legacy_array_error
		)


	if (
		get_enhancement_level(
			legacy_array_state,
			sword_definition
		)
		!=
		0
	):
		return (
			"State legacy [] no resolvió +0."
		)


	# -----------------------------------------------------
	# DICTIONARY VACÍO
	# -----------------------------------------------------

	var empty_dictionary_state := {
		"uid": "enhancement-empty-dictionary",
		"item_id": "bronze_sword",

		"state": {},
	}


	var empty_dictionary_error := (
		validate_item_instance(
			empty_dictionary_state,
			sword_definition
		)
	)


	if not empty_dictionary_error.is_empty():
		return (
			"State {} rechazado: "
			+
			empty_dictionary_error
		)


	if (
		get_enhancement_level(
			empty_dictionary_state,
			sword_definition
		)
		!=
		0
	):
		return (
			"State {} no resolvió +0."
		)


	# -----------------------------------------------------
	# +0 EXPLÍCITO
	# -----------------------------------------------------

	var explicit_zero_item := {
		"uid": "enhancement-explicit-zero",
		"item_id": "bronze_sword",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: 0,
		},
	}


	var explicit_zero_error := (
		validate_item_instance(
			explicit_zero_item,
			sword_definition
		)
	)


	if not explicit_zero_error.is_empty():
		return (
			"Enhancement +0 explícito rechazado: "
			+
			explicit_zero_error
		)


	if (
		get_enhancement_level(
			explicit_zero_item,
			sword_definition
		)
		!=
		0
	):
		return (
			"Enhancement +0 explícito "
			+
			"se resolvió incorrectamente."
		)


	# -----------------------------------------------------
	# MAX VÁLIDO
	# -----------------------------------------------------

	var explicit_max_item := {
		"uid": "enhancement-explicit-max",
		"item_id": "bronze_sword",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: max_level,
		},
	}


	var explicit_max_error := (
		validate_item_instance(
			explicit_max_item,
			sword_definition
		)
	)


	if not explicit_max_error.is_empty():
		return (
			"Enhancement máximo válido rechazado: "
			+
			explicit_max_error
		)


	if (
		get_enhancement_level(
			explicit_max_item,
			sword_definition
		)
		!=
		max_level
	):
		return (
			"Enhancement máximo se resolvió "
			+
			"incorrectamente."
		)


	# -----------------------------------------------------
	# NEGATIVO
	# -----------------------------------------------------

	var negative_item := {
		"uid": "enhancement-negative",
		"item_id": "bronze_sword",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: -1,
		},
	}


	if (
		validate_item_instance(
			negative_item,
			sword_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió Enhancement negativo."
		)


	# -----------------------------------------------------
	# MAYOR AL MAX
	# -----------------------------------------------------

	var over_max_item := {
		"uid": "enhancement-over-max",
		"item_id": "bronze_sword",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: (
				max_level
				+
				1
			),
		},
	}


	if (
		validate_item_instance(
			over_max_item,
			sword_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió Enhancement "
			+
			"por encima del máximo."
		)


	# -----------------------------------------------------
	# FLOAT NO ES LEVEL
	# -----------------------------------------------------

	var float_item := {
		"uid": "enhancement-float",
		"item_id": "bronze_sword",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: 1.0,
		},
	}


	if (
		validate_item_instance(
			float_item,
			sword_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió Enhancement "
			+
			"no entero."
		)


	# -----------------------------------------------------
	# ARRAY NO VACÍO NO ES STATE CANÓNICO
	# -----------------------------------------------------

	var invalid_array_state := {
		"uid": "enhancement-invalid-array",
		"item_id": "bronze_sword",

		"state": [
			1,
		],
	}


	if (
		validate_item_instance(
			invalid_array_state,
			sword_definition
		)
		.is_empty()
	):
		return (
			"El contrato permitió state Array no vacío."
		)


	# -----------------------------------------------------
	# NO-EQUIPMENT NO PUEDE TENER ENHANCEMENT
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
		"uid": "enhancement-potion",
		"item_id": "health_potion",

		"state": {
			ENHANCEMENT_LEVEL_STATE_KEY: 1,
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
			"El contrato permitió Enhancement "
			+
			"en un item no-Equipment."
		)


	return ""


# =========================================================
# VALIDAR ESTADO DE INSTANCIA
# =========================================================

static func validate_item_instance(
	item: Dictionary,
	definition: Dictionary
) -> String:
	if definition.is_empty():
		return (
			"Definition vacía."
		)


	var is_equipment := (
		ServerEquipmentRules
		.is_equipment_definition(
			definition
		)
	)


	var state_value: Variant = (
		item.get(
			STATE_KEY,
			null
		)
	)


	# -----------------------------------------------------
	# LEGACY NULL / AUSENTE
	# -----------------------------------------------------

	if typeof(state_value) == TYPE_NIL:
		return ""


	# -----------------------------------------------------
	# LEGACY []
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
	# CANÓNICO = DICTIONARY
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


	# -----------------------------------------------------
	# SIN ENHANCEMENT DECLARADO = +0
	# -----------------------------------------------------

	if not state.has(
		ENHANCEMENT_LEVEL_STATE_KEY
	):
		return ""


	# -----------------------------------------------------
	# NO-EQUIPMENT NO ADMITE ENHANCEMENT
	# -----------------------------------------------------

	if not is_equipment:
		return (
			"Un item no-Equipment no puede declarar "
			+
			"enhancement_level."
		)


	var enhancement_value: Variant = (
		state[
			ENHANCEMENT_LEVEL_STATE_KEY
		]
	)


	if typeof(enhancement_value) != TYPE_INT:
		return (
			"enhancement_level debe ser int."
		)


	var enhancement_level := int(
		enhancement_value
	)


	var max_level := (
		ServerEquipmentEnhancementRules
		.get_max_enhancement_level(
			definition
		)
	)


	if max_level < 0:
		return (
			"No se pudo resolver "
			+
			"max_enhancement_level."
		)


	if (
		enhancement_level
		<
		ServerEquipmentEnhancementProfileCatalog
		.GLOBAL_MIN_ENHANCEMENT_LEVEL
	):
		return (
			"enhancement_level no puede ser negativo."
		)


	if enhancement_level > max_level:
		return (
			"enhancement_level fuera de rango. "
			+
			"Máximo: "
			+
			str(max_level)
		)


	return ""


# =========================================================
# RESOLVER ENHANCEMENT LEVEL
# =========================================================

static func get_enhancement_level(
	item: Dictionary,
	definition: Dictionary
) -> int:
	if not (
		ServerEquipmentRules
		.is_equipment_definition(
			definition
		)
	):
		return -1


	var validation_error := (
		validate_item_instance(
			item,
			definition
		)
	)


	if not validation_error.is_empty():
		return -1


	var state_value: Variant = (
		item.get(
			STATE_KEY,
			null
		)
	)


	if typeof(state_value) != TYPE_DICTIONARY:
		return 0


	var state: Dictionary = (
		state_value as Dictionary
	)


	if not state.has(
		ENHANCEMENT_LEVEL_STATE_KEY
	):
		return 0


	return int(
		state[
			ENHANCEMENT_LEVEL_STATE_KEY
		]
	)
