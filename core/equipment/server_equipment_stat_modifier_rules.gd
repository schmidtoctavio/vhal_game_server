class_name ServerEquipmentStatModifierRules
extends RefCounted


# =========================================================
# MODIFIER KEYS
# =========================================================

const STAT_ID_KEY: String = (
	"stat_id"
)

const OPERATION_ID_KEY: String = (
	"operation_id"
)

const VALUE_KEY: String = (
	"value"
)


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var catalog_error := (
		ServerEquipmentStatModifierCatalog
		.validate_catalog()
	)


	if not catalog_error.is_empty():
		return (
			"Stat Modifier Catalog inválido: "
			+
			catalog_error
		)


	# -----------------------------------------------------
	# PRIMARY INT VÁLIDO
	# -----------------------------------------------------

	var vitality_modifier := {
		"stat_id": "vitality",
		"operation_id": "flat_add",
		"value": 4,
	}


	if not (
		validate_modifier(
			vitality_modifier
		).is_empty()
	):
		return (
			"Modifier foundation de VIT fue rechazado."
		)


	# -----------------------------------------------------
	# FLOAT VÁLIDO
	# -----------------------------------------------------

	var crit_modifier := {
		"stat_id": "critical_strike_chance",
		"operation_id": "flat_add",
		"value": 0.03,
	}


	if not (
		validate_modifier(
			crit_modifier
		).is_empty()
	):
		return (
			"Modifier foundation de Crit fue rechazado."
		)


	# -----------------------------------------------------
	# STAT DESCONOCIDO
	# -----------------------------------------------------

	var unknown_modifier := {
		"stat_id": "super_strength",
		"operation_id": "flat_add",
		"value": 5,
	}


	if (
		validate_modifier(
			unknown_modifier
		).is_empty()
	):
		return (
			"El contrato permitió stat_id desconocido."
		)


	# -----------------------------------------------------
	# OPERACIÓN NO SOPORTADA
	# -----------------------------------------------------

	var percent_modifier := {
		"stat_id": "vitality",
		"operation_id": "percent_add",
		"value": 10,
	}


	if (
		validate_modifier(
			percent_modifier
		).is_empty()
	):
		return (
			"El contrato permitió percent_add "
			+
			"antes de definir semántica porcentual."
		)


	# -----------------------------------------------------
	# INT TARGET CON FLOAT
	# -----------------------------------------------------

	var invalid_int_modifier := {
		"stat_id": "strength",
		"operation_id": "flat_add",
		"value": 2.5,
	}


	if (
		validate_modifier(
			invalid_int_modifier
		).is_empty()
	):
		return (
			"El contrato permitió float "
			+
			"en stat entero."
		)


	# -----------------------------------------------------
	# BONUS CERO
	# -----------------------------------------------------

	var zero_modifier := {
		"stat_id": "armor_rating",
		"operation_id": "flat_add",
		"value": 0,
	}


	if (
		validate_modifier(
			zero_modifier
		).is_empty()
	):
		return (
			"El contrato permitió modifier +0."
		)


	# -----------------------------------------------------
	# BONUS NEGATIVO
	# -----------------------------------------------------

	var negative_modifier := {
		"stat_id": "max_hp",
		"operation_id": "flat_add",
		"value": -100,
	}


	if (
		validate_modifier(
			negative_modifier
		).is_empty()
	):
		return (
			"El contrato permitió modifier negativo "
			+
			"en foundation de Equipment."
		)


	return ""


# =========================================================
# VALIDAR MODIFIER
# =========================================================

static func validate_modifier(
	modifier: Dictionary
) -> String:
	if modifier.is_empty():
		return (
			"Modifier vacío."
		)


	if modifier.size() != 3:
		return (
			"Modifier debe contener exactamente "
			+
			"stat_id, operation_id y value."
		)


	# -----------------------------------------------------
	# STAT
	# -----------------------------------------------------

	if not modifier.has(
		STAT_ID_KEY
	):
		return (
			"Falta stat_id."
		)


	var raw_stat_id: Variant = (
		modifier[
			STAT_ID_KEY
		]
	)


	var stat_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_stat_id(
			raw_stat_id
		)
	)


	if stat_id.is_empty():
		return (
			"stat_id vacío."
		)


	if String(
		raw_stat_id
	) != String(
		stat_id
	):
		return (
			"stat_id no canónico."
		)


	if not (
		ServerEquipmentStatModifierCatalog
		.has_definition(
			stat_id
		)
	):
		return (
			"stat_id inexistente: "
			+
			String(stat_id)
		)


	# -----------------------------------------------------
	# OPERATION
	# -----------------------------------------------------

	if not modifier.has(
		OPERATION_ID_KEY
	):
		return (
			"Falta operation_id."
		)


	var raw_operation_id: Variant = (
		modifier[
			OPERATION_ID_KEY
		]
	)


	var operation_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_operation_id(
			raw_operation_id
		)
	)


	if operation_id.is_empty():
		return (
			"operation_id vacío."
		)


	if String(
		raw_operation_id
	) != String(
		operation_id
	):
		return (
			"operation_id no canónico."
		)


	if not (
		ServerEquipmentStatModifierCatalog
		.OPERATION_IDS
		.has(
			operation_id
		)
	):
		return (
			"operation_id no soportado: "
			+
			String(operation_id)
		)


	# -----------------------------------------------------
	# VALUE
	# -----------------------------------------------------

	if not modifier.has(
		VALUE_KEY
	):
		return (
			"Falta value."
		)


	var value: Variant = (
		modifier[
			VALUE_KEY
		]
	)


	var stat_definition := (
		ServerEquipmentStatModifierCatalog
		.get_definition(
			stat_id
		)
	)


	if stat_definition.is_empty():
		return (
			"No se pudo resolver stat definition."
		)


	var numeric_kind := StringName(
		String(
			stat_definition.get(
				"numeric_kind",
				""
			)
		)
	)


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_INT
	):
		if typeof(value) != TYPE_INT:
			return (
				"value debe ser int para "
				+
				String(stat_id)
				+
				"."
			)


		if int(value) <= 0:
			return (
				"value debe ser > 0."
			)


		return ""


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_NUMBER
	):
		if (
			typeof(value) != TYPE_INT
			and
			typeof(value) != TYPE_FLOAT
		):
			return (
				"value debe ser numérico para "
				+
				String(stat_id)
				+
				"."
			)


		if float(value) <= 0.0:
			return (
				"value debe ser > 0."
			)


		return ""


	return (
		"numeric_kind no soportado."
	)


# =========================================================
# CONSULTAR DOMAIN
# =========================================================

static func get_domain_id(
	stat_id: Variant
) -> StringName:
	var definition := (
		ServerEquipmentStatModifierCatalog
		.get_definition(
			stat_id
		)
	)


	if definition.is_empty():
		return &""


	return StringName(
		String(
			definition.get(
				"domain_id",
				""
			)
		)
	)


# =========================================================
# CONSULTAR VALUE NORMALIZADO
# =========================================================

static func get_numeric_value(
	modifier: Dictionary
) -> Variant:
	if not (
		validate_modifier(
			modifier
		).is_empty()
	):
		return null


	var stat_id := (
		ServerEquipmentStatModifierCatalog
		.normalize_stat_id(
			modifier[
				STAT_ID_KEY
			]
		)
	)


	var stat_definition := (
		ServerEquipmentStatModifierCatalog
		.get_definition(
			stat_id
		)
	)


	var numeric_kind := StringName(
		String(
			stat_definition.get(
				"numeric_kind",
				""
			)
		)
	)


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_INT
	):
		return int(
			modifier[
				VALUE_KEY
			]
		)


	if (
		numeric_kind
		==
		ServerEquipmentStatModifierCatalog
		.NUMERIC_NUMBER
	):
		return float(
			modifier[
				VALUE_KEY
			]
		)


	return null
