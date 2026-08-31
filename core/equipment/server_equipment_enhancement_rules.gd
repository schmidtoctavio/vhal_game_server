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
