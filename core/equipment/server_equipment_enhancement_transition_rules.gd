class_name ServerEquipmentEnhancementTransitionRules
extends RefCounted


# =========================================================
# RESULT KEYS
# =========================================================

const OK_KEY: String = "ok"

const MESSAGE_KEY: String = "message"

const ITEM_KEY: String = "item"

const CURRENT_LEVEL_KEY: String = (
	"current_level"
)

const NEXT_LEVEL_KEY: String = (
	"next_level"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Esta capa representa exclusivamente una transición
# determinista de Enhancement:
#
# +N
# →
# +(N + 1)
#
#
# Responsabilidades:
#
# - validar la instancia actual;
# - resolver Current Enhancement Level;
# - respetar Max Enhancement Level;
# - construir una COPIA candidata;
# - preservar el resto de state;
# - canonicalizar state legacy a Dictionary.
#
#
# NO:
#
# - muta el item original;
# - persiste;
# - consume materiales;
# - calcula costo;
# - tira RNG;
# - decide success/failure probabilístico;
# - valida si el personaje puede equiparlo.
#
# Es únicamente una transición de estado candidata.
# =========================================================


# =========================================================
# CONSTRUIR SIGUIENTE CANDIDATO
# =========================================================

static func build_next_level_candidate(
	item: Dictionary
) -> Dictionary:
	if item.is_empty():
		return _failure(
			"invalid_item"
		)


	var item_id := String(
		item.get(
			"item_id",
			""
		)
	).strip_edges()


	if item_id.is_empty():
		return _failure(
			"invalid_item_id"
		)


	var definition := (
		ServerItemCatalog.get_definition(
			item_id
		)
	)


	if definition.is_empty():
		return _failure(
			"unknown_item"
		)


	if not (
		ServerEquipmentRules
		.is_equipment_definition(
			definition
		)
	):
		return _failure(
			"item_is_not_equipment"
		)


	var instance_error := (
		ServerEquipmentEnhancementInstanceRules
		.validate_item_instance(
			item,
			definition
		)
	)


	if not instance_error.is_empty():
		return _failure(
			(
				"invalid_enhancement_state: "
				+
				instance_error
			)
		)


	var current_level := (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			item,
			definition
		)
	)


	if current_level < 0:
		return _failure(
			"invalid_current_level"
		)


	var max_level := (
		ServerEquipmentEnhancementRules
		.get_max_enhancement_level(
			definition
		)
	)


	if max_level < 0:
		return _failure(
			"invalid_max_level"
		)


	if current_level >= max_level:
		return _failure(
			"max_enhancement_reached"
		)


	var next_level := (
		current_level
		+
		1
	)


	if next_level > max_level:
		return _failure(
			"next_level_out_of_range"
		)


	# -----------------------------------------------------
	# COPIA PROFUNDA
	#
	# El item original nunca debe ser mutado.
	# -----------------------------------------------------

	var candidate := (
		item.duplicate(
			true
		)
	)


	# -----------------------------------------------------
	# STATE
	#
	# Legacy válido:
	#
	# missing / null / [] / {}
	#
	# pasa a representación canónica Dictionary cuando
	# aparece el primer Enhancement explícito.
	# -----------------------------------------------------

	var state_value: Variant = (
		candidate.get(
			ServerEquipmentEnhancementInstanceRules.STATE_KEY,
			null
		)
	)


	var next_state: Dictionary = {}


	if typeof(state_value) == TYPE_DICTIONARY:
		next_state = (
			(state_value as Dictionary)
			.duplicate(
				true
			)
		)


	elif typeof(state_value) == TYPE_NIL:
		next_state = {}


	elif typeof(state_value) == TYPE_ARRAY:
		var legacy_state: Array = (
			state_value as Array
		)


		if not legacy_state.is_empty():
			return _failure(
				"invalid_legacy_state"
			)


		next_state = {}


	else:
		return _failure(
			"invalid_state_type"
		)


	next_state[
		ServerEquipmentEnhancementInstanceRules
		.ENHANCEMENT_LEVEL_STATE_KEY
	] = next_level


	candidate[
		ServerEquipmentEnhancementInstanceRules.STATE_KEY
	] = next_state


	# -----------------------------------------------------
	# VALIDAR CANDIDATO RESULTANTE
	# -----------------------------------------------------

	var candidate_error := (
		ServerEquipmentEnhancementInstanceRules
		.validate_item_instance(
			candidate,
			definition
		)
	)


	if not candidate_error.is_empty():
		return _failure(
			(
				"invalid_candidate: "
				+
				candidate_error
			)
		)


	var resolved_candidate_level := (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			candidate,
			definition
		)
	)


	if resolved_candidate_level != next_level:
		return _failure(
			"candidate_level_mismatch"
		)


	return _success(
		item,
		candidate,
		current_level,
		next_level
	)


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# LEGACY +0
	#
	# state ausente
	# →
	# +1 explícito
	# -----------------------------------------------------

	var legacy_sword := {
		"uid": "transition-legacy-sword",

		"item_id": "bronze_sword",

		"quantity": 1,
	}


	var legacy_result := (
		build_next_level_candidate(
			legacy_sword
		)
	)


	if not bool(
		legacy_result.get(
			OK_KEY,
			false
		)
	):
		return (
			"Legacy +0 no pudo transicionar a +1: "
			+
			String(
				legacy_result.get(
					MESSAGE_KEY,
					""
				)
			)
		)


	if int(
		legacy_result.get(
			CURRENT_LEVEL_KEY,
			-1
		)
	) != 0:
		return (
			"Legacy Sword no resolvió Current Level 0."
		)


	if int(
		legacy_result.get(
			NEXT_LEVEL_KEY,
			-1
		)
	) != 1:
		return (
			"Legacy Sword no resolvió Next Level 1."
		)


	var legacy_candidate: Dictionary = (
		legacy_result.get(
			ITEM_KEY,
			{}
		)
	)


	if legacy_candidate.is_empty():
		return (
			"Legacy Sword no produjo candidato."
		)


	var sword_definition := (
		ServerItemCatalog.get_definition(
			"bronze_sword"
		)
	)


	if sword_definition.is_empty():
		return (
			"No existe bronze_sword."
		)


	if (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			legacy_candidate,
			sword_definition
		)
		!=
		1
	):
		return (
			"Legacy Sword candidate no quedó en +1."
		)


	# -----------------------------------------------------
	# INPUT INMUTABLE
	# -----------------------------------------------------

	if legacy_sword.has(
		ServerEquipmentEnhancementInstanceRules.STATE_KEY
	):
		return (
			"Enhancement Transition mutó el item original."
		)


	# -----------------------------------------------------
	# +7 → +8
	#
	# Debe preservar rolled_modifiers.
	# -----------------------------------------------------

	var sword_plus_seven := {
		"uid": "transition-sword-seven",

		"item_id": "bronze_sword",

		"quantity": 1,

		"state": {
			"enhancement_level": 7,

			"rolled_modifiers": [
				{
					"stat_id": "strength",
					"operation_id": "flat_add",
					"value": 3,
				},
			],
		},
	}


	var seven_result := (
		build_next_level_candidate(
			sword_plus_seven
		)
	)


	if not bool(
		seven_result.get(
			OK_KEY,
			false
		)
	):
		return (
			"Sword +7 no pudo transicionar a +8: "
			+
			String(
				seven_result.get(
					MESSAGE_KEY,
					""
				)
			)
		)


	if int(
		seven_result.get(
			CURRENT_LEVEL_KEY,
			-1
		)
	) != 7:
		return (
			"Sword +7 resolvió Current Level incorrecto."
		)


	if int(
		seven_result.get(
			NEXT_LEVEL_KEY,
			-1
		)
	) != 8:
		return (
			"Sword +7 no resolvió Next Level 8."
		)


	var eight_candidate: Dictionary = (
		seven_result.get(
			ITEM_KEY,
			{}
		)
	)


	if eight_candidate.is_empty():
		return (
			"Sword +7 no produjo candidato +8."
		)


	var eight_state_value: Variant = (
		eight_candidate.get(
			ServerEquipmentEnhancementInstanceRules.STATE_KEY,
			null
		)
	)


	if typeof(eight_state_value) != TYPE_DICTIONARY:
		return (
			"Sword +8 candidate no tiene state Dictionary."
		)


	var eight_state: Dictionary = (
		eight_state_value as Dictionary
	)


	var rolled_value: Variant = (
		eight_state.get(
			"rolled_modifiers",
			null
		)
	)


	if typeof(rolled_value) != TYPE_ARRAY:
		return (
			"Enhancement Transition perdió rolled_modifiers."
		)


	var rolled_modifiers: Array = (
		rolled_value as Array
	)


	if rolled_modifiers.size() != 1:
		return (
			"Enhancement Transition alteró rolled_modifiers."
		)


	# -----------------------------------------------------
	# ORIGINAL +7 SIGUE EN +7
	# -----------------------------------------------------

	if (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			sword_plus_seven,
			sword_definition
		)
		!=
		7
	):
		return (
			"Enhancement Transition mutó Sword +7 original."
		)


	# -----------------------------------------------------
	# +13
	#
	# Ya está en máximo.
	# -----------------------------------------------------

	var sword_plus_thirteen := {
		"uid": "transition-sword-thirteen",

		"item_id": "bronze_sword",

		"quantity": 1,

		"state": {
			"enhancement_level": 13,
		},
	}


	var max_result := (
		build_next_level_candidate(
			sword_plus_thirteen
		)
	)


	if bool(
		max_result.get(
			OK_KEY,
			false
		)
	):
		return (
			"Enhancement Transition permitió +13 → +14."
		)


	if String(
		max_result.get(
			MESSAGE_KEY,
			""
		)
	) != "max_enhancement_reached":
		return (
			"Sword +13 fue rechazada por motivo inesperado."
		)


	# -----------------------------------------------------
	# NO-EQUIPMENT
	# -----------------------------------------------------

	var potion := {
		"uid": "transition-potion",

		"item_id": "health_potion",

		"quantity": 1,
	}


	var potion_result := (
		build_next_level_candidate(
			potion
		)
	)


	if bool(
		potion_result.get(
			OK_KEY,
			false
		)
	):
		return (
			"Enhancement Transition permitió Health Potion."
		)


	if String(
		potion_result.get(
			MESSAGE_KEY,
			""
		)
	) != "item_is_not_equipment":
		return (
			"Health Potion fue rechazada "
			+
			"por motivo inesperado."
		)


	return ""


# =========================================================
# RESULT HELPERS
# =========================================================

static func _success(
	original_item: Dictionary,
	candidate: Dictionary,
	current_level: int,
	next_level: int
) -> Dictionary:
	if original_item.is_empty():
		return {}


	if candidate.is_empty():
		return {}


	return {
		OK_KEY: true,

		MESSAGE_KEY: "",

		ITEM_KEY: candidate,

		CURRENT_LEVEL_KEY: current_level,

		NEXT_LEVEL_KEY: next_level,
	}


static func _failure(
	message: String
) -> Dictionary:
	return {
		OK_KEY: false,

		MESSAGE_KEY: message,

		ITEM_KEY: {},

		CURRENT_LEVEL_KEY: -1,

		NEXT_LEVEL_KEY: -1,
	}
