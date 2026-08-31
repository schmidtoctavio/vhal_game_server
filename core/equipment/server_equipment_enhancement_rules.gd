class_name ServerEquipmentEnhancementRules
extends RefCounted


# =========================================================
# DEFINITION KEYS
# =========================================================

const ENHANCEMENT_PROFILE_ID_KEY: String = (
	"enhancement_profile_id"
)


# =========================================================
# VALIDAR CONTRATO GLOBAL
# =========================================================

static func validate_contract() -> String:
	var profile_catalog_error := (
		ServerEquipmentEnhancementProfileCatalog
		.validate_catalog()
	)


	if not profile_catalog_error.is_empty():
		return (
			"Enhancement Profile Catalog inválido: "
			+
			profile_catalog_error
		)


	for raw_item_id: Variant in (
		ServerItemCatalog.DEFINITIONS.keys()
	):
		var item_id := String(
			raw_item_id
		).strip_edges()


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
				ENHANCEMENT_PROFILE_ID_KEY
			):
				return (
					item_id
					+
					" | Un item no-Equipment "
					+
					"no debe declarar "
					+
					"enhancement_profile_id."
				)


			continue


		var validation_error := (
			validate_definition(
				definition
			)
		)


		if not validation_error.is_empty():
			return (
				item_id
				+
				" | "
				+
				validation_error
			)

	var instance_state_contract_error := (
		ServerEquipmentEnhancementInstanceRules
		.validate_contract()
	)


	if not instance_state_contract_error.is_empty():
		return (
			"Enhancement Instance State Contract inválido: "
			+
			instance_state_contract_error
		)

	var scaling_contract_error := (
		_validate_scaling_resolution_contract()
	)


	if not scaling_contract_error.is_empty():
		return (
			"Enhancement Scaling Contract inválido: "
			+
			scaling_contract_error
		)

	return ""


# =========================================================
# VALIDAR DEFINITION
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
			"La Definition no representa "
			+
			"Equipment válido."
		)


	if not definition.has(
		ENHANCEMENT_PROFILE_ID_KEY
	):
		return (
			"Falta enhancement_profile_id."
		)


	var raw_profile_id: Variant = (
		definition[
			ENHANCEMENT_PROFILE_ID_KEY
		]
	)


	var profile_id := (
		ServerEquipmentEnhancementProfileCatalog
		.normalize_profile_id(
			raw_profile_id
		)
	)


	if profile_id.is_empty():
		return (
			"enhancement_profile_id vacío."
		)


	if String(
		raw_profile_id
	) != String(
		profile_id
	):
		return (
			"enhancement_profile_id no canónico."
		)


	if not (
		ServerEquipmentEnhancementProfileCatalog
		.has_definition(
			profile_id
		)
	):
		return (
			"Enhancement Profile inexistente: "
			+
			String(profile_id)
		)


	var profile := (
		ServerEquipmentEnhancementProfileCatalog
		.get_definition(
			profile_id
		)
	)


	# -----------------------------------------------------
	# CATEGORY COMPATIBILITY
	# -----------------------------------------------------

	var category_id := (
		ServerEquipmentCategoryCatalog
		.normalize_category_id(
			definition.get(
				"equipment_category_id",
				"none"
			)
		)
	)


	var allowed_categories: Array = (
		profile.get(
			"allowed_category_ids",
			[]
		)
	)


	if not allowed_categories.has(
		String(category_id)
	):
		return (
			"Enhancement Profile "
			+
			String(profile_id)
			+
			" incompatible con category "
			+
			String(category_id)
			+
			"."
		)


	# -----------------------------------------------------
	# HAND MODE COMPATIBILITY
	# -----------------------------------------------------

	var hand_mode_id := (
		ServerHandEquipModeCatalog
		.normalize_mode_id(
			definition.get(
				"hand_equip_mode_id",
				"none"
			)
		)
	)


	var allowed_hand_modes: Array = (
		profile.get(
			"allowed_hand_mode_ids",
			[]
		)
	)


	if not allowed_hand_modes.has(
		String(hand_mode_id)
	):
		return (
			"Enhancement Profile "
			+
			String(profile_id)
			+
			" incompatible con hand mode "
			+
			String(hand_mode_id)
			+
			"."
		)


	# -----------------------------------------------------
	# INTRINSIC BASE STAT
	# -----------------------------------------------------

	var intrinsic_definition_key := String(
		profile.get(
			"intrinsic_definition_key",
			""
		)
	).strip_edges()


	if intrinsic_definition_key.is_empty():
		return (
			"Enhancement Profile sin "
			+
			"intrinsic_definition_key."
		)


	if not definition.has(
		intrinsic_definition_key
	):
		return (
			"Falta stat base requerido por Enhancement: "
			+
			intrinsic_definition_key
		)


	var intrinsic_value: Variant = (
		definition[
			intrinsic_definition_key
		]
	)


	if typeof(intrinsic_value) != TYPE_INT:
		return (
			"Stat base "
			+
			intrinsic_definition_key
			+
			" debe ser int."
		)


	if int(
		intrinsic_value
	) <= 0:
		return (
			"Stat base "
			+
			intrinsic_definition_key
			+
			" debe ser > 0."
		)


	# -----------------------------------------------------
	# REQUIREMENT GROWTH CHANNELS
	# -----------------------------------------------------

	var base_requirements := (
		ServerEquipmentUsageRules
		.get_base_requirements(
			definition
		)
	)


	if base_requirements.is_empty():
		return (
			"No se pudieron resolver "
			+
			"base_requirements."
		)


	var growth_keys: Array = (
		profile.get(
			"requirement_growth_keys",
			[]
		)
	)


	for raw_growth_key: Variant in growth_keys:
		var growth_key := String(
			raw_growth_key
		)


		if not base_requirements.has(
			growth_key
		):
			return (
				"Requirement growth sin "
				+
				"base requirement: "
				+
				growth_key
			)


	return ""


# =========================================================
# PROFILE DE UNA DEFINITION
# =========================================================

static func get_profile_id(
	definition: Dictionary
) -> StringName:
	if not (
		validate_definition(
			definition
		).is_empty()
	):
		return &""


	return (
		ServerEquipmentEnhancementProfileCatalog
		.normalize_profile_id(
			definition[
				ENHANCEMENT_PROFILE_ID_KEY
			]
		)
	)


static func get_profile_definition(
	definition: Dictionary
) -> Dictionary:
	var profile_id := (
		get_profile_id(
			definition
		)
	)


	if profile_id.is_empty():
		return {}


	return (
		ServerEquipmentEnhancementProfileCatalog
		.get_definition(
			profile_id
		)
	)


# =========================================================
# MAX ENHANCEMENT
# =========================================================

static func get_max_enhancement_level(
	definition: Dictionary
) -> int:
	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return -1


	return int(
		profile.get(
			"max_enhancement_level",
			-1
		)
	)


# =========================================================
# INTRINSIC STAT
# =========================================================

static func get_intrinsic_stat_id(
	definition: Dictionary
) -> StringName:
	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return &""


	return StringName(
		String(
			profile.get(
				"intrinsic_stat_id",
				""
			)
		)
	)


static func get_base_intrinsic_value(
	definition: Dictionary
) -> int:
	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return -1


	var definition_key := String(
		profile.get(
			"intrinsic_definition_key",
			""
		)
	)


	if definition_key.is_empty():
		return -1


	return int(
		definition.get(
			definition_key,
			-1
		)
	)


# =========================================================
# REQUIREMENT GROWTH CHANNELS
# =========================================================

static func get_requirement_growth_keys(
	definition: Dictionary
) -> PackedStringArray:
	var result := PackedStringArray()


	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return result


	var growth_keys: Array = (
		profile.get(
			"requirement_growth_keys",
			[]
		)
	)


	for raw_growth_key: Variant in growth_keys:
		result.append(
			String(
				raw_growth_key
			)
		)


	return result

# =========================================================
# INTRINSIC BONUS POR LEVEL
# =========================================================

static func get_intrinsic_bonus_at_level(
	definition: Dictionary,
	enhancement_level: int
) -> int:
	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return -1


	var max_level := int(
		profile.get(
			"max_enhancement_level",
			-1
		)
	)


	if (
		enhancement_level < 0
		or
		enhancement_level > max_level
	):
		return -1


	var curve_value: Variant = (
		profile.get(
			"intrinsic_bonus_by_level",
			null
		)
	)


	if typeof(curve_value) != TYPE_ARRAY:
		return -1


	var curve: Array = (
		curve_value as Array
	)


	if enhancement_level >= curve.size():
		return -1


	var bonus_value: Variant = (
		curve[
			enhancement_level
		]
	)


	if typeof(bonus_value) != TYPE_INT:
		return -1


	return int(
		bonus_value
	)


# =========================================================
# INTRINSIC VALUE RESUELTO
# =========================================================

static func get_resolved_intrinsic_value(
	item: Dictionary,
	definition: Dictionary
) -> int:
	var enhancement_level := (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			item,
			definition
		)
	)


	if enhancement_level < 0:
		return -1


	var base_value := (
		get_base_intrinsic_value(
			definition
		)
	)


	if base_value < 0:
		return -1


	var bonus := (
		get_intrinsic_bonus_at_level(
			definition,
			enhancement_level
		)
	)


	if bonus < 0:
		return -1


	return (
		base_value
		+
		bonus
	)


# =========================================================
# REQUIREMENT BONUS POR LEVEL
# =========================================================

static func get_requirement_bonus_at_level(
	definition: Dictionary,
	requirement_key: String,
	enhancement_level: int
) -> int:
	var normalized_key := (
		requirement_key
		.strip_edges()
		.to_lower()
	)


	var valid_keys: Array[String] = [
		ServerEquipmentUsageRules.REQUIREMENT_LEVEL,
		ServerEquipmentUsageRules.REQUIREMENT_STRENGTH,
		ServerEquipmentUsageRules.REQUIREMENT_AGILITY,
		ServerEquipmentUsageRules.REQUIREMENT_VITALITY,
		ServerEquipmentUsageRules.REQUIREMENT_ENERGY,
	]


	if not valid_keys.has(
		normalized_key
	):
		return -1


	var profile := (
		get_profile_definition(
			definition
		)
	)


	if profile.is_empty():
		return -1


	var max_level := int(
		profile.get(
			"max_enhancement_level",
			-1
		)
	)


	if (
		enhancement_level < 0
		or
		enhancement_level > max_level
	):
		return -1


	var growth_keys := (
		get_requirement_growth_keys(
			definition
		)
	)


	if not growth_keys.has(
		normalized_key
	):
		return 0


	var curves_value: Variant = (
		profile.get(
			"requirement_bonus_by_level",
			null
		)
	)


	if typeof(curves_value) != TYPE_DICTIONARY:
		return -1


	var curves: Dictionary = (
		curves_value as Dictionary
	)


	if not curves.has(
		normalized_key
	):
		return -1


	var curve_value: Variant = (
		curves[
			normalized_key
		]
	)


	if typeof(curve_value) != TYPE_ARRAY:
		return -1


	var curve: Array = (
		curve_value as Array
	)


	if enhancement_level >= curve.size():
		return -1


	var bonus_value: Variant = (
		curve[
			enhancement_level
		]
	)


	if typeof(bonus_value) != TYPE_INT:
		return -1


	return int(
		bonus_value
	)


# =========================================================
# REQUIREMENTS RESUELTOS
# =========================================================

static func get_resolved_requirements(
	item: Dictionary,
	definition: Dictionary
) -> Dictionary:
	var enhancement_level := (
		ServerEquipmentEnhancementInstanceRules
		.get_enhancement_level(
			item,
			definition
		)
	)


	if enhancement_level < 0:
		return {}


	var base_requirements := (
		ServerEquipmentUsageRules
		.get_base_requirements(
			definition
		)
	)


	if base_requirements.is_empty():
		return {}


	var resolved := (
		base_requirements.duplicate(
			true
		)
	)


	var requirement_keys: Array[String] = [
		ServerEquipmentUsageRules.REQUIREMENT_LEVEL,
		ServerEquipmentUsageRules.REQUIREMENT_STRENGTH,
		ServerEquipmentUsageRules.REQUIREMENT_AGILITY,
		ServerEquipmentUsageRules.REQUIREMENT_VITALITY,
		ServerEquipmentUsageRules.REQUIREMENT_ENERGY,
	]


	for requirement_key: String in (
		requirement_keys
	):
		var bonus := (
			get_requirement_bonus_at_level(
				definition,
				requirement_key,
				enhancement_level
			)
		)


		if bonus < 0:
			return {}


		resolved[
			requirement_key
		] = (
			int(
				base_requirements[
					requirement_key
				]
			)
			+
			bonus
		)


	return resolved

# =========================================================
# SELF-TEST — SCALING RESOLUTION
# =========================================================

static func _validate_scaling_resolution_contract() -> String:
	var sword_definition := (
		ServerItemCatalog.get_definition(
			"bronze_sword"
		)
	)


	if sword_definition.is_empty():
		return (
			"No existe bronze_sword."
		)


	var sword_plus_zero := {
		"state": {
			"enhancement_level": 0,
		},
	}


	if (
		get_resolved_intrinsic_value(
			sword_plus_zero,
			sword_definition
		)
		!=
		1000
	):
		return (
			"Bronze Sword +0 no resolvió Damage 1000."
		)


	var sword_plus_thirteen := {
		"state": {
			"enhancement_level": 13,
		},
	}


	if (
		get_resolved_intrinsic_value(
			sword_plus_thirteen,
			sword_definition
		)
		!=
		1500
	):
		return (
			"Bronze Sword +13 no resolvió Damage 1500."
		)


	var sword_requirements := (
		get_resolved_requirements(
			sword_plus_thirteen,
			sword_definition
		)
	)


	if (
		int(
			sword_requirements.get(
				"strength",
				-1
			)
		)
		!=
		30
	):
		return (
			"Bronze Sword +13 no resolvió STR 30."
		)


	if (
		int(
			sword_requirements.get(
				"level",
				-1
			)
		)
		!=
		1
	):
		return (
			"Enhancement alteró Level requirement "
			+
			"de Bronze Sword."
		)


	var helmet_definition := (
		ServerItemCatalog.get_definition(
			"leather_helmet"
		)
	)


	if helmet_definition.is_empty():
		return (
			"No existe leather_helmet."
		)


	var helmet_plus_thirteen := {
		"state": {
			"enhancement_level": 13,
		},
	}


	if (
		get_resolved_intrinsic_value(
			helmet_plus_thirteen,
			helmet_definition
		)
		!=
		46
	):
		return (
			"Leather Helmet +13 no resolvió Armor 46."
		)


	var helmet_requirements := (
		get_resolved_requirements(
			helmet_plus_thirteen,
			helmet_definition
		)
	)


	if (
		int(
			helmet_requirements.get(
				"strength",
				-1
			)
		)
		!=
		25
	):
		return (
			"Leather Helmet +13 no resolvió STR 25."
		)


	if (
		int(
			helmet_requirements.get(
				"agility",
				-1
			)
		)
		!=
		23
	):
		return (
			"Leather Helmet +13 no resolvió AGI 23."
		)


	if (
		int(
			helmet_requirements.get(
				"level",
				-1
			)
		)
		!=
		1
	):
		return (
			"Enhancement alteró Level requirement "
			+
			"de Leather Helmet."
		)


	return ""
