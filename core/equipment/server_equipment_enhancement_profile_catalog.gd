class_name ServerEquipmentEnhancementProfileCatalog
extends RefCounted


# =========================================================
# LÍMITES GLOBALES
# =========================================================

const GLOBAL_MIN_ENHANCEMENT_LEVEL: int = 0

const GLOBAL_MAX_ENHANCEMENT_LEVEL: int = 13


# =========================================================
# PROFILE IDS
# =========================================================

const ONE_HAND_WEAPON_V1: StringName = (
	&"one_hand_weapon_v1"
)

const LIGHT_ARMOR_V1: StringName = (
	&"light_armor_v1"
)


# =========================================================
# INTRINSIC STAT IDS
# =========================================================

const WEAPON_DAMAGE: StringName = (
	&"weapon_damage"
)

const ARMOR_RATING: StringName = (
	&"armor_rating"
)


const INTRINSIC_STAT_IDS: Array[StringName] = [
	WEAPON_DAMAGE,
	ARMOR_RATING,
]


# =========================================================
# DEFINICIONES
# =========================================================
#
# IMPORTANTE:
#
# Este catálogo NO contiene todavía las curvas numéricas
# de +1 ... +13.
#
# Define únicamente:
#
# - qué familia de Enhancement utiliza el Equipment;
# - cuál es su máximo;
# - qué categorías / modos son compatibles;
# - qué propiedad inherente del item será escalada;
# - qué requisitos primarios podrán crecer.
#
# Las curvas numéricas se agregarán en una etapa separada.
# =========================================================

const DEFINITIONS: Dictionary = {
	ONE_HAND_WEAPON_V1: {
		"max_enhancement_level": 13,

		"allowed_category_ids": [
			"weapon",
		],

		"allowed_hand_mode_ids": [
			"one_hand",
		],

		"intrinsic_stat_id": "weapon_damage",

		"intrinsic_definition_key": (
			"basic_attack_base_damage"
		),

		"requirement_growth_keys": [
			"strength",
		],
	},

	LIGHT_ARMOR_V1: {
		"max_enhancement_level": 13,

		"allowed_category_ids": [
			"head",
			"chest",
			"pants",
			"gloves",
			"boots",
		],

		"allowed_hand_mode_ids": [
			"none",
		],

		"intrinsic_stat_id": "armor_rating",

		"intrinsic_definition_key": (
			"base_armor_rating"
		),

		"requirement_growth_keys": [
			"strength",
			"agility",
		],
	},
}


# =========================================================
# NORMALIZAR PROFILE ID
# =========================================================

static func normalize_profile_id(
	value: Variant
) -> StringName:
	return StringName(
		String(
			value
		)
		.strip_edges()
		.to_lower()
	)


# =========================================================
# CONSULTAR
# =========================================================

static func has_definition(
	profile_id: Variant
) -> bool:
	return DEFINITIONS.has(
		normalize_profile_id(
			profile_id
		)
	)


static func get_definition(
	profile_id: Variant
) -> Dictionary:
	var normalized_profile_id := (
		normalize_profile_id(
			profile_id
		)
	)


	if not DEFINITIONS.has(
		normalized_profile_id
	):
		return {}


	var definition_value: Variant = (
		DEFINITIONS[
			normalized_profile_id
		]
	)


	if typeof(definition_value) != TYPE_DICTIONARY:
		return {}


	return (
		definition_value as Dictionary
	).duplicate(
		true
	)


# =========================================================
# VALIDAR CATÁLOGO
# =========================================================

static func validate_catalog() -> String:
	if DEFINITIONS.is_empty():
		return (
			"No existen Enhancement Profiles."
		)


	var seen_profile_ids: Dictionary = {}


	for raw_profile_id: Variant in (
		DEFINITIONS.keys()
	):
		var profile_id := (
			normalize_profile_id(
				raw_profile_id
			)
		)


		if profile_id.is_empty():
			return (
				"Existe Enhancement Profile sin ID."
			)


		if String(
			raw_profile_id
		) != String(
			profile_id
		):
			return (
				"Enhancement Profile ID no canónico: "
				+
				String(raw_profile_id)
			)


		if seen_profile_ids.has(
			profile_id
		):
			return (
				"Enhancement Profile duplicado: "
				+
				String(profile_id)
			)


		seen_profile_ids[
			profile_id
		] = true


		var definition := (
			get_definition(
				profile_id
			)
		)


		if definition.is_empty():
			return (
				"Enhancement Profile inválido: "
				+
				String(profile_id)
			)


		var validation_error := (
			_validate_profile_definition(
				profile_id,
				definition
			)
		)


		if not validation_error.is_empty():
			return validation_error


	return ""


# =========================================================
# VALIDAR PROFILE
# =========================================================

static func _validate_profile_definition(
	profile_id: StringName,
	definition: Dictionary
) -> String:
	# -----------------------------------------------------
	# MAX LEVEL
	# -----------------------------------------------------

	var max_level_value: Variant = (
		definition.get(
			"max_enhancement_level",
			null
		)
	)


	if typeof(max_level_value) != TYPE_INT:
		return (
			String(profile_id)
			+
			" | max_enhancement_level debe ser int."
		)


	var max_level := int(
		max_level_value
	)


	if (
		max_level <= GLOBAL_MIN_ENHANCEMENT_LEVEL
		or
		max_level > GLOBAL_MAX_ENHANCEMENT_LEVEL
	):
		return (
			String(profile_id)
			+
			" | max_enhancement_level fuera de rango."
		)


	# -----------------------------------------------------
	# CATEGORIES
	# -----------------------------------------------------

	var categories_value: Variant = (
		definition.get(
			"allowed_category_ids",
			null
		)
	)


	if typeof(categories_value) != TYPE_ARRAY:
		return (
			String(profile_id)
			+
			" | allowed_category_ids debe ser Array."
		)


	var category_ids: Array = (
		categories_value as Array
	)


	if category_ids.is_empty():
		return (
			String(profile_id)
			+
			" | allowed_category_ids vacío."
		)


	var seen_categories: Dictionary = {}


	for raw_category_id: Variant in category_ids:
		var category_id := (
			ServerEquipmentCategoryCatalog
			.normalize_category_id(
				raw_category_id
			)
		)


		if not (
			ServerEquipmentCategoryCatalog
			.is_equipment_category(
				category_id
			)
		):
			return (
				String(profile_id)
				+
				" | categoría inválida: "
				+
				String(raw_category_id)
			)


		if String(
			raw_category_id
		) != String(
			category_id
		):
			return (
				String(profile_id)
				+
				" | categoría no canónica: "
				+
				String(raw_category_id)
			)


		if seen_categories.has(
			category_id
		):
			return (
				String(profile_id)
				+
				" | categoría duplicada: "
				+
				String(category_id)
			)


		seen_categories[
			category_id
		] = true


	# -----------------------------------------------------
	# HAND MODES
	# -----------------------------------------------------

	var hand_modes_value: Variant = (
		definition.get(
			"allowed_hand_mode_ids",
			null
		)
	)


	if typeof(hand_modes_value) != TYPE_ARRAY:
		return (
			String(profile_id)
			+
			" | allowed_hand_mode_ids debe ser Array."
		)


	var hand_mode_ids: Array = (
		hand_modes_value as Array
	)


	if hand_mode_ids.is_empty():
		return (
			String(profile_id)
			+
			" | allowed_hand_mode_ids vacío."
		)


	var seen_hand_modes: Dictionary = {}


	for raw_hand_mode_id: Variant in hand_mode_ids:
		var hand_mode_id := (
			ServerHandEquipModeCatalog
			.normalize_mode_id(
				raw_hand_mode_id
			)
		)


		if not (
			ServerHandEquipModeCatalog
			.is_valid_mode_id(
				hand_mode_id
			)
		):
			return (
				String(profile_id)
				+
				" | hand mode inválido: "
				+
				String(raw_hand_mode_id)
			)


		if String(
			raw_hand_mode_id
		) != String(
			hand_mode_id
		):
			return (
				String(profile_id)
				+
				" | hand mode no canónico: "
				+
				String(raw_hand_mode_id)
			)


		if seen_hand_modes.has(
			hand_mode_id
		):
			return (
				String(profile_id)
				+
				" | hand mode duplicado: "
				+
				String(hand_mode_id)
			)


		seen_hand_modes[
			hand_mode_id
		] = true


	# -----------------------------------------------------
	# INTRINSIC STAT
	# -----------------------------------------------------

	var intrinsic_stat_id := StringName(
		String(
			definition.get(
				"intrinsic_stat_id",
				""
			)
		)
		.strip_edges()
		.to_lower()
	)


	if not INTRINSIC_STAT_IDS.has(
		intrinsic_stat_id
	):
		return (
			String(profile_id)
			+
			" | intrinsic_stat_id inválido."
		)


	var intrinsic_definition_key := String(
		definition.get(
			"intrinsic_definition_key",
			""
		)
	).strip_edges()


	if intrinsic_definition_key.is_empty():
		return (
			String(profile_id)
			+
			" | intrinsic_definition_key vacío."
		)


	# -----------------------------------------------------
	# REQUIREMENT GROWTH CHANNELS
	# -----------------------------------------------------

	var growth_keys_value: Variant = (
		definition.get(
			"requirement_growth_keys",
			null
		)
	)


	if typeof(growth_keys_value) != TYPE_ARRAY:
		return (
			String(profile_id)
			+
			" | requirement_growth_keys debe ser Array."
		)


	var growth_keys: Array = (
		growth_keys_value as Array
	)


	var valid_requirement_keys: Array[String] = [
		ServerEquipmentUsageRules.REQUIREMENT_STRENGTH,
		ServerEquipmentUsageRules.REQUIREMENT_AGILITY,
		ServerEquipmentUsageRules.REQUIREMENT_VITALITY,
		ServerEquipmentUsageRules.REQUIREMENT_ENERGY,
	]


	var seen_growth_keys: Dictionary = {}


	for raw_growth_key: Variant in growth_keys:
		var growth_key := String(
			raw_growth_key
		).strip_edges().to_lower()


		if not valid_requirement_keys.has(
			growth_key
		):
			return (
				String(profile_id)
				+
				" | requirement growth inválido: "
				+
				growth_key
			)


		if String(
			raw_growth_key
		) != growth_key:
			return (
				String(profile_id)
				+
				" | requirement growth no canónico: "
				+
				String(raw_growth_key)
			)


		if seen_growth_keys.has(
			growth_key
		):
			return (
				String(profile_id)
				+
				" | requirement growth duplicado: "
				+
				growth_key
			)


		seen_growth_keys[
			growth_key
		] = true


	return ""
