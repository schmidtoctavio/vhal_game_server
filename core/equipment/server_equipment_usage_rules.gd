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
# - cuáles son sus requisitos BASE en +0;
# - elegibilidad de uso de una instancia concreta;
# - requisitos resueltos según Enhancement.
#
#
# La elegibilidad SIEMPRE se compara contra:
#
# Permanent Primary Stats
#
# Nunca contra Effective Primary.
#
#
# Por lo tanto:
#
# Equipment Bonuses NO pueden utilizarse para cumplir
# requisitos de otro Equipment ni del propio item.
#
#
# Todavía NO:
#
# - persiste Equipment;
# - mueve items entre containers;
# - modifica snapshots.
#
# Esa integración pertenece al Coordinator.
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

	# =====================================================
	# ITEM USAGE ELIGIBILITY
	# =====================================================

	var warrior_primary := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			7,
			11,
			0,
			25,
			15,
			25,
			10,
			2,
			0,
			2,
			3,
			5,
			200,
			50,
			0,
			0,
			50,
			7,
			43
		)
	)


	if (
		warrior_primary == null
		or
		not warrior_primary.is_valid()
	):
		return (
			"Equipment Usage Eligibility "
			+
			"no pudo crear Warrior foundation."
		)


	# -----------------------------------------------------
	# SWORD +0
	#
	# Required STR = 15
	# Permanent STR = 27
	#
	# Debe permitir.
	# -----------------------------------------------------

	var sword_plus_zero := {
		"uid": "usage-sword-zero",

		"item_id": "bronze_sword",

		"quantity": 1,

		"state": {
			"enhancement_level": 0,
		},
	}


	var sword_zero_error := (
		validate_item_usage(
			sword_plus_zero,
			warrior_primary
		)
	)


	if not sword_zero_error.is_empty():
		return (
			"Bronze Sword +0 fue rechazada: "
			+
			sword_zero_error
		)


	# -----------------------------------------------------
	# SWORD +13
	#
	# Base STR     15
	# Enhance     +15
	# Required     30
	#
	# Permanent STR = 27
	#
	# Debe rechazar.
	# -----------------------------------------------------

	var sword_plus_thirteen := {
		"uid": "usage-sword-thirteen",

		"item_id": "bronze_sword",

		"quantity": 1,

		"state": {
			"enhancement_level": 13,
		},
	}


	var sword_thirteen_error := (
		validate_item_usage(
			sword_plus_thirteen,
			warrior_primary
		)
	)


	if (
		sword_thirteen_error
		!=
		"insufficient_strength"
	):
		return (
			"Bronze Sword +13 con Permanent STR 27 "
			+
			"debía requerir STR 30."
		)


	# -----------------------------------------------------
	# WARRIOR CON PERMANENT STR 30
	# -----------------------------------------------------

	var strong_warrior_primary := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			8,
			11,
			0,
			25,
			15,
			25,
			10,
			5,
			0,
			2,
			3,
			5,
			200,
			50,
			0,
			0,
			50,
			10,
			40
		)
	)


	if (
		strong_warrior_primary == null
		or
		not strong_warrior_primary.is_valid()
	):
		return (
			"Equipment Usage Eligibility "
			+
			"no pudo crear Strong Warrior."
		)


	var strong_warrior_error := (
		validate_item_usage(
			sword_plus_thirteen,
			strong_warrior_primary
		)
	)


	if not strong_warrior_error.is_empty():
		return (
			"Bronze Sword +13 fue rechazada "
			+
			"con Permanent STR 30: "
			+
			strong_warrior_error
		)

	# =====================================================
	# SNAPSHOT USAGE ELIGIBILITY
	# =====================================================

	var empty_equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


	var empty_snapshot_error := (
		validate_equipment_snapshot_usage(
			empty_equipment_snapshot,
			warrior_primary
		)
	)


	if not empty_snapshot_error.is_empty():
		return (
			"Equipment vacío fue rechazado por Usage: "
			+
			empty_snapshot_error
		)


	# -----------------------------------------------------
	# SWORD +0 EQUIPADA
	#
	# Permanent STR 27
	# Requirement STR 15
	#
	# Snapshot completo debe ser válido.
	# -----------------------------------------------------

	var valid_equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-usage-sword-zero",

				"item_id": "bronze_sword",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 0,
				},
			},
		],
	}


	var valid_snapshot_error := (
		validate_equipment_snapshot_usage(
			valid_equipment_snapshot,
			warrior_primary
		)
	)


	if not valid_snapshot_error.is_empty():
		return (
			"Equipment Snapshot válido fue rechazado: "
			+
			valid_snapshot_error
		)


	# -----------------------------------------------------
	# SWORD +13 EQUIPADA
	#
	# Permanent STR 27
	# Requirement STR 30
	#
	# Aunque el snapshot sea estructuralmente válido,
	# Usage Eligibility debe rechazarlo.
	# -----------------------------------------------------

	var invalid_usage_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "snapshot-usage-sword-thirteen",

				"item_id": "bronze_sword",

				"quantity": 1,

				"equipment_slot": "main_hand",

				"state": {
					"enhancement_level": 13,
				},
			},
		],
	}


	var invalid_snapshot_error := (
		validate_equipment_snapshot_usage(
			invalid_usage_snapshot,
			warrior_primary
		)
	)


	if invalid_snapshot_error.is_empty():
		return (
			"Equipment Snapshot permitió Bronze Sword +13 "
			+
			"con Permanent STR 27."
		)


	if not invalid_snapshot_error.contains(
		"reason=insufficient_strength"
	):
		return (
			"Equipment Snapshot rechazó Sword +13 "
			+
			"por motivo inesperado: "
			+
			invalid_snapshot_error
		)


	# -----------------------------------------------------
	# MISMO SNAPSHOT + STR 30
	#
	# Ahora sí debe permitir.
	# -----------------------------------------------------

	var strong_snapshot_error := (
		validate_equipment_snapshot_usage(
			invalid_usage_snapshot,
			strong_warrior_primary
		)
	)


	if not strong_snapshot_error.is_empty():
		return (
			"Equipment Snapshot rechazó Sword +13 "
			+
			"con Permanent STR 30: "
			+
			strong_snapshot_error
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

# =========================================================
# VALIDAR USO DE UNA INSTANCIA
# =========================================================
#
# Valida:
#
# Item Instance
# +
# Character Permanent Primary
#
# contra:
#
# Class
# +
# Level
# +
# Requirements resueltos por Enhancement.
#
#
# Retorna:
#
# ""
# → puede utilizarlo.
#
# reason_id
# → no puede utilizarlo.
# =========================================================

static func validate_item_usage(
	item: Dictionary,
	primary_stats: ServerCharacterPrimaryStatsState
) -> String:
	if item.is_empty():
		return "invalid_item"


	if primary_stats == null:
		return "invalid_primary_stats"


	if not primary_stats.is_valid():
		return "invalid_primary_stats"


	var item_id := String(
		item.get(
			"item_id",
			""
		)
	).strip_edges()


	if item_id.is_empty():
		return "invalid_item"


	var definition := (
		ServerItemCatalog.get_definition(
			item_id
		)
	)


	if definition.is_empty():
		return "unknown_item"


	if not (
		validate_definition(
			definition
		).is_empty()
	):
		return "invalid_definition"


	# -----------------------------------------------------
	# CLASS
	# -----------------------------------------------------

	if not can_class_use_definition(
		definition,
		primary_stats.class_id
	):
		return "class_not_allowed"


	# -----------------------------------------------------
	# REQUIREMENTS RESUELTOS
	#
	# +0 usa base_requirements.
	#
	# +1 ... +13 agrega únicamente las curvas definidas
	# por Enhancement Profile.
	# -----------------------------------------------------

	var requirements := (
		ServerEquipmentEnhancementRules
		.get_resolved_requirements(
			item,
			definition
		)
	)


	if requirements.is_empty():
		return "invalid_requirements"


	var required_level := int(
		requirements.get(
			REQUIREMENT_LEVEL,
			-1
		)
	)


	var required_strength := int(
		requirements.get(
			REQUIREMENT_STRENGTH,
			-1
		)
	)


	var required_agility := int(
		requirements.get(
			REQUIREMENT_AGILITY,
			-1
		)
	)


	var required_vitality := int(
		requirements.get(
			REQUIREMENT_VITALITY,
			-1
		)
	)


	var required_energy := int(
		requirements.get(
			REQUIREMENT_ENERGY,
			-1
		)
	)


	if (
		required_level < 1
		or
		required_strength < 0
		or
		required_agility < 0
		or
		required_vitality < 0
		or
		required_energy < 0
	):
		return "invalid_requirements"


	# -----------------------------------------------------
	# LEVEL
	# -----------------------------------------------------

	if primary_stats.level < required_level:
		return "insufficient_level"


	# -----------------------------------------------------
	# PERMANENT PRIMARY
	#
	# IMPORTANTE:
	#
	# No usar Effective Primary acá.
	# Equipment Bonuses quedan deliberadamente afuera.
	# -----------------------------------------------------

	if (
		primary_stats.permanent_strength
		<
		required_strength
	):
		return "insufficient_strength"


	if (
		primary_stats.permanent_agility
		<
		required_agility
	):
		return "insufficient_agility"


	if (
		primary_stats.permanent_vitality
		<
		required_vitality
	):
		return "insufficient_vitality"


	if (
		primary_stats.permanent_energy
		<
		required_energy
	):
		return "insufficient_energy"


	return ""

# =========================================================
# VALIDAR USO DE EQUIPMENT SNAPSHOT COMPLETO
# =========================================================
#
# Verifica que TODOS los items actualmente equipados
# puedan ser usados por el estado Primary permanente
# del personaje.
#
#
# Esto sirve para:
#
# - Login
# - Equipment reload
# - Resync durable
#
#
# Un snapshot estructuralmente válido puede igualmente
# ser inválido desde Usage Eligibility.
# =========================================================

static func validate_equipment_snapshot_usage(
	snapshot: Dictionary,
	primary_stats: ServerCharacterPrimaryStatsState
) -> String:
	if primary_stats == null:
		return "invalid_primary_stats"


	if not primary_stats.is_valid():
		return "invalid_primary_stats"


	var snapshot_error := (
		ServerEquipmentSnapshotValidator
		.validate(
			snapshot
		)
	)


	if not snapshot_error.is_empty():
		return (
			"invalid_equipment_snapshot: "
			+
			snapshot_error
		)


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return "invalid_equipment_items"


	var items: Array = (
		items_value as Array
	)


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "invalid_equipment_item"


		var item: Dictionary = (
			item_value as Dictionary
		)


		var usage_error := (
			validate_item_usage(
				item,
				primary_stats
			)
		)


		if usage_error.is_empty():
			continue


		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		var item_id := String(
			item.get(
				"item_id",
				""
			)
		).strip_edges()


		return (
			"item_usage_invalid"
			+
			" | uid="
			+
			uid
			+
			" | item_id="
			+
			item_id
			+
			" | reason="
			+
			usage_error
		)


	return ""
