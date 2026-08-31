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
# IMPORTANTE:
#
# Este catálogo define tanto la identidad del Enhancement
# Profile como sus curvas foundation de +0 ... +13.
#
# Las curvas almacenan BONUS ACUMULADO.
#
# Ejemplo:
#
# Base Armor = 20
# Bonus en +7 = 7
# Armor intrínseco resuelto = 27
#
# Enhancement NO reemplaza el valor base del item.
#
# Tampoco representa random/fixed modifiers.
# Es una capa independiente.
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
		"intrinsic_bonus_by_level": [
			0,
			20,
			40,
			60,
			80,
			100,
			125,
			150,
			180,
			220,
			270,
			330,
			400,
			500,
		],

		"requirement_bonus_by_level": {
			"strength": [
				0,
				0,
				1,
				1,
				2,
				2,
				3,
				4,
				5,
				6,
				8,
				10,
				12,
				15,
			],
		},
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
		"intrinsic_bonus_by_level": [
			0,
			1,
			2,
			3,
			4,
			5,
			6,
			7,
			9,
			11,
			14,
			17,
			21,
			26,
		],

		"requirement_bonus_by_level": {
			"strength": [
				0,
				0,
				0,
				1,
				1,
				2,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				10,
			],

			"agility": [
				0,
				0,
				0,
				0,
				1,
				1,
				2,
				2,
				3,
				3,
				4,
				5,
				6,
				8,
			],
		},
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

	# -----------------------------------------------------
	# INTRINSIC BONUS CURVE
	# -----------------------------------------------------

	var intrinsic_curve_error := (
		_validate_cumulative_int_curve(
			profile_id,
			"intrinsic_bonus_by_level",
			definition.get(
				"intrinsic_bonus_by_level",
				null
			),
			max_level
		)
	)


	if not intrinsic_curve_error.is_empty():
		return intrinsic_curve_error


	# -----------------------------------------------------
	# REQUIREMENT BONUS CURVES
	# -----------------------------------------------------

	var requirement_curves_value: Variant = (
		definition.get(
			"requirement_bonus_by_level",
			null
		)
	)


	if (
		typeof(requirement_curves_value)
		!=
		TYPE_DICTIONARY
	):
		return (
			String(profile_id)
			+
			" | requirement_bonus_by_level "
			+
			"debe ser Dictionary."
		)


	var requirement_curves: Dictionary = (
		requirement_curves_value as Dictionary
	)


	if (
		requirement_curves.size()
		!=
		growth_keys.size()
	):
		return (
			String(profile_id)
			+
			" | requirement_bonus_by_level "
			+
			"no coincide con requirement_growth_keys."
		)


	for raw_growth_key: Variant in growth_keys:
		var growth_key := String(
			raw_growth_key
		)


		if not requirement_curves.has(
			growth_key
		):
			return (
				String(profile_id)
				+
				" | Falta curva para requirement: "
				+
				growth_key
			)


		var curve_error := (
			_validate_cumulative_int_curve(
				profile_id,
				(
					"requirement_bonus_by_level."
					+
					growth_key
				),
				requirement_curves[
					growth_key
				],
				max_level
			)
		)


		if not curve_error.is_empty():
			return curve_error


	for raw_curve_key: Variant in (
		requirement_curves.keys()
	):
		var curve_key := String(
			raw_curve_key
		).strip_edges().to_lower()


		if not seen_growth_keys.has(
			curve_key
		):
			return (
				String(profile_id)
				+
				" | Curva declarada para "
				+
				"requirement no habilitado: "
				+
				curve_key
			)


	return ""

# =========================================================
# VALIDAR CURVA ACUMULADA
# =========================================================

static func _validate_cumulative_int_curve(
	profile_id: StringName,
	curve_label: String,
	curve_value: Variant,
	max_level: int
) -> String:
	if typeof(curve_value) != TYPE_ARRAY:
		return (
			String(profile_id)
			+
			" | "
			+
			curve_label
			+
			" debe ser Array."
		)


	var curve: Array = (
		curve_value as Array
	)


	var expected_size := (
		max_level
		+
		1
	)


	if curve.size() != expected_size:
		return (
			String(profile_id)
			+
			" | "
			+
			curve_label
			+
			" debe contener exactamente "
			+
			str(expected_size)
			+
			" valores."
		)


	var previous_value := 0


	for level in range(
		curve.size()
	):
		var raw_value: Variant = (
			curve[
				level
			]
		)


		if typeof(raw_value) != TYPE_INT:
			return (
				String(profile_id)
				+
				" | "
				+
				curve_label
				+
				" contiene valor no-int en +"
				+
				str(level)
				+
				"."
			)


		var value := int(
			raw_value
		)


		if value < 0:
			return (
				String(profile_id)
				+
				" | "
				+
				curve_label
				+
				" contiene valor negativo en +"
				+
				str(level)
				+
				"."
			)


		if level == 0:
			if value != 0:
				return (
					String(profile_id)
					+
					" | "
					+
					curve_label
					+
					" debe comenzar en 0."
				)


			previous_value = value


			continue


		if value < previous_value:
			return (
				String(profile_id)
				+
				" | "
				+
				curve_label
				+
				" decrece en +"
				+
				str(level)
				+
				"."
			)


		previous_value = value


	return ""
