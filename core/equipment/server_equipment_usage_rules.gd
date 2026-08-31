class_name ServerEquipmentUsageRules
extends RefCounted


# =========================================================
# KEYS DE USO
# =========================================================

const ALLOWED_CLASS_IDS_KEY: String = (
	"allowed_class_ids"
)

const BASE_REQUIREMENTS_KEY: String = (
	"base_requirements"
)


# =========================================================
# KEYS DE REQUIREMENTS
# =========================================================

const REQUIREMENT_LEVEL: String = (
	"level"
)

const REQUIREMENT_STRENGTH: String = (
	"strength"
)

const REQUIREMENT_AGILITY: String = (
	"agility"
)

const REQUIREMENT_VITALITY: String = (
	"vitality"
)

const REQUIREMENT_ENERGY: String = (
	"energy"
)


# =========================================================
# SEMÁNTICA
# =========================================================
#
# Este dominio define:
#
# - qué Classes pueden usar un Equipment;
# - cuáles son sus requisitos BASE en +0.
#
# Todavía NO:
#
# - aplica requisitos al equip live;
# - conoce enhancement_level;
# - calcula requisitos de +1 ... +13;
# - aplica modifiers del Equipment.
#
# Cuando los requisitos se conecten al gameplay se deberán
# comparar contra Permanent Primary Stats.
#
# Los bonuses otorgados por Equipment NO deben utilizarse
# para cumplir requisitos de Equipment.
# =========================================================


# =========================================================
# VALIDAR CONTRATO GLOBAL
# =========================================================

static func validate_contract() -> String:
	for raw_item_id: Variant in (
		ServerItemCatalog.DEFINITIONS.keys()
	):
		if typeof(raw_item_id) != TYPE_STRING:
			return (
				"ServerItemCatalog contiene "
				+
				"un item_id que no es String."
			)


		var item_id := String(
			raw_item_id
		).strip_edges()


		if item_id.is_empty():
			return (
				"ServerItemCatalog contiene "
				+
				"un item_id vacío."
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


		var category_value: Variant = (
			definition.get(
				"equipment_category_id",
				"none"
			)
		)


		if not (
			ServerEquipmentCategoryCatalog
			.is_valid_category_id(
				category_value
			)
		):
			return (
				item_id
				+
				" | equipment_category_id inválido."
			)


		var category_id := (
			ServerEquipmentCategoryCatalog
			.normalize_category_id(
				category_value
			)
		)


		# -------------------------------------------------
		# ITEMS QUE NO SON EQUIPMENT
		# -------------------------------------------------

		if (
			category_id
			==
			ServerEquipmentCategoryCatalog.NONE
		):
			if definition.has(
				ALLOWED_CLASS_IDS_KEY
			):
				return (
					item_id
					+
					" | Un item no-Equipment "
					+
					"no debe declarar allowed_class_ids."
				)


			if definition.has(
				BASE_REQUIREMENTS_KEY
			):
				return (
					item_id
					+
					" | Un item no-Equipment "
					+
					"no debe declarar base_requirements."
				)


			continue


		# -------------------------------------------------
		# EQUIPMENT
		# -------------------------------------------------

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


		# -------------------------------------------------
		# SELF-TEST DEL FILTRO DE CLASS
		# -------------------------------------------------

		var allowed_class_ids := (
			get_allowed_class_ids(
				definition
			)
		)


		for class_id: String in (
			ServerClassStatsCatalog
			.get_all_class_ids()
		):
			var expected := (
				allowed_class_ids.has(
					class_id
				)
			)


			var actual := (
				can_class_use_definition(
					definition,
					class_id
				)
			)


			if actual != expected:
				return (
					item_id
					+
					" | El filtro de Class "
					+
					"no respeta allowed_class_ids "
					+
					"para "
					+
					class_id
					+
					"."
				)


	return ""


# =========================================================
# VALIDAR USAGE DE UNA DEFINITION
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


	# -----------------------------------------------------
	# ALLOWED CLASSES
	# -----------------------------------------------------

	if not definition.has(
		ALLOWED_CLASS_IDS_KEY
	):
		return (
			"Falta allowed_class_ids."
		)


	var allowed_value: Variant = (
		definition[
			ALLOWED_CLASS_IDS_KEY
		]
	)


	if typeof(allowed_value) != TYPE_ARRAY:
		return (
			"allowed_class_ids debe ser Array."
		)


	var allowed_class_ids: Array = (
		allowed_value as Array
	)


	if allowed_class_ids.is_empty():
		return (
			"allowed_class_ids no puede estar vacío."
		)


	var seen_class_ids: Dictionary = {}


	for raw_class_id: Variant in allowed_class_ids:
		var class_value_type := (
			typeof(raw_class_id)
		)


		if (
			class_value_type != TYPE_STRING
			and
			class_value_type != TYPE_STRING_NAME
		):
			return (
				"allowed_class_ids contiene "
				+
				"un valor que no es String."
			)


		var original_class_id := String(
			raw_class_id
		)


		var normalized_class_id := (
			original_class_id
			.strip_edges()
			.to_lower()
		)


		if normalized_class_id.is_empty():
			return (
				"allowed_class_ids contiene "
				+
				"un class_id vacío."
			)


		if (
			original_class_id
			!=
			normalized_class_id
		):
			return (
				"Class ID no canónico: "
				+
				original_class_id
			)


		if seen_class_ids.has(
			normalized_class_id
		):
			return (
				"Class duplicada en allowed_class_ids: "
				+
				normalized_class_id
			)


		if not (
			ServerClassStatsCatalog.has_definition(
				normalized_class_id
			)
		):
			return (
				"Class inexistente: "
				+
				normalized_class_id
			)


		seen_class_ids[
			normalized_class_id
		] = true


	# -----------------------------------------------------
	# BASE REQUIREMENTS
	# -----------------------------------------------------

	if not definition.has(
		BASE_REQUIREMENTS_KEY
	):
		return (
			"Falta base_requirements."
		)


	var requirements_value: Variant = (
		definition[
			BASE_REQUIREMENTS_KEY
		]
	)


	if (
		typeof(requirements_value)
		!=
		TYPE_DICTIONARY
	):
		return (
			"base_requirements debe ser Dictionary."
		)


	var requirements := (
		requirements_value as Dictionary
	)


	if requirements.size() != 5:
		return (
			"base_requirements debe contener "
			+
			"exactamente Level, STR, AGI, VIT y ENE."
		)


	var requirement_keys: Array[String] = [
		REQUIREMENT_LEVEL,
		REQUIREMENT_STRENGTH,
		REQUIREMENT_AGILITY,
		REQUIREMENT_VITALITY,
		REQUIREMENT_ENERGY,
	]


	for requirement_key: String in (
		requirement_keys
	):
		if not requirements.has(
			requirement_key
		):
			return (
				"Falta requirement: "
				+
				requirement_key
			)


		var requirement_value: Variant = (
			requirements[
				requirement_key
			]
		)


		if typeof(requirement_value) != TYPE_INT:
			return (
				"Requirement "
				+
				requirement_key
				+
				" debe ser int."
			)


		var numeric_value := int(
			requirement_value
		)


		if (
			requirement_key
			==
			REQUIREMENT_LEVEL
		):
			if numeric_value < 1:
				return (
					"Level requerido debe ser >= 1."
				)


			continue


		if numeric_value < 0:
			return (
				"Requirement "
				+
				requirement_key
				+
				" no puede ser negativo."
			)


	return ""


# =========================================================
# CONSULTAR CLASSES PERMITIDAS
# =========================================================

static func get_allowed_class_ids(
	definition: Dictionary
) -> PackedStringArray:
	var result := PackedStringArray()


	if not (
		validate_definition(
			definition
		).is_empty()
	):
		return result


	var allowed_class_ids: Array = (
		definition[
			ALLOWED_CLASS_IDS_KEY
		]
	)


	for raw_class_id: Variant in allowed_class_ids:
		result.append(
			String(
				raw_class_id
			)
			.strip_edges()
			.to_lower()
		)


	return result


# =========================================================
# ¿CLASS PUEDE USAR DEFINITION?
# =========================================================

static func can_class_use_definition(
	definition: Dictionary,
	class_id: Variant
) -> bool:
	if not (
		validate_definition(
			definition
		).is_empty()
	):
		return false


	var normalized_class_id := (
		String(
			class_id
		)
		.strip_edges()
		.to_lower()
	)


	if normalized_class_id.is_empty():
		return false


	if not (
		ServerClassStatsCatalog.has_definition(
			normalized_class_id
		)
	):
		return false


	return (
		get_allowed_class_ids(
			definition
		).has(
			normalized_class_id
		)
	)


# =========================================================
# CONSULTAR REQUIREMENTS BASE
# =========================================================

static func get_base_requirements(
	definition: Dictionary
) -> Dictionary:
	if not (
		validate_definition(
			definition
		).is_empty()
	):
		return {}


	var requirements: Dictionary = (
		definition[
			BASE_REQUIREMENTS_KEY
		]
	)


	return requirements.duplicate(
		true
	)
