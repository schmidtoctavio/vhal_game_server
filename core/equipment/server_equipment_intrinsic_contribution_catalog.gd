class_name ServerEquipmentIntrinsicContributionCatalog
extends RefCounted


# =========================================================
# SCOPE IDS
# =========================================================
#
# CHARACTER_ADDITIVE
# → el intrinsic de todos los items equipados se suma
#   a una contribución global del personaje.
#
# SLOT_LOCAL
# → el intrinsic continúa perteneciendo al slot/item
#   concreto que lo aporta.
# =========================================================

const CHARACTER_ADDITIVE: StringName = (
	&"character_additive"
)

const SLOT_LOCAL: StringName = (
	&"slot_local"
)


const SCOPE_IDS: Array[StringName] = [
	CHARACTER_ADDITIVE,
	SLOT_LOCAL,
]


# =========================================================
# DEFINITIONS
# =========================================================

const DEFINITIONS: Dictionary = {
	ServerEquipmentEnhancementProfileCatalog.ARMOR_RATING: {
		"scope_id": "character_additive",
	},

	ServerEquipmentEnhancementProfileCatalog.WEAPON_DAMAGE: {
		"scope_id": "slot_local",
	},
}


# =========================================================
# NORMALIZAR
# =========================================================

static func normalize_intrinsic_stat_id(
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
	intrinsic_stat_id: Variant
) -> bool:
	return DEFINITIONS.has(
		normalize_intrinsic_stat_id(
			intrinsic_stat_id
		)
	)


static func get_definition(
	intrinsic_stat_id: Variant
) -> Dictionary:
	var normalized_id := (
		normalize_intrinsic_stat_id(
			intrinsic_stat_id
		)
	)


	if not DEFINITIONS.has(
		normalized_id
	):
		return {}


	var definition_value: Variant = (
		DEFINITIONS[
			normalized_id
		]
	)


	if typeof(definition_value) != TYPE_DICTIONARY:
		return {}


	return (
		definition_value as Dictionary
	).duplicate(
		true
	)


static func get_scope_id(
	intrinsic_stat_id: Variant
) -> StringName:
	var definition := (
		get_definition(
			intrinsic_stat_id
		)
	)


	if definition.is_empty():
		return &""


	return StringName(
		String(
			definition.get(
				"scope_id",
				""
			)
		)
		.strip_edges()
		.to_lower()
	)


# =========================================================
# VALIDAR CATÁLOGO
# =========================================================

static func validate_catalog() -> String:
	if DEFINITIONS.is_empty():
		return (
			"Intrinsic Contribution Catalog vacío."
		)


	# Todos los intrinsic conocidos por Enhancement
	# deben poseer una política de contribución.

	for raw_intrinsic_stat_id: Variant in (
		ServerEquipmentEnhancementProfileCatalog
		.INTRINSIC_STAT_IDS
	):
		var intrinsic_stat_id := (
			normalize_intrinsic_stat_id(
				raw_intrinsic_stat_id
			)
		)


		if not DEFINITIONS.has(
			intrinsic_stat_id
		):
			return (
				"Falta Contribution Policy para intrinsic: "
				+
				String(intrinsic_stat_id)
			)


	# Y no permitimos policies para intrinsic inexistentes.

	for raw_intrinsic_stat_id: Variant in (
		DEFINITIONS.keys()
	):
		var intrinsic_stat_id := (
			normalize_intrinsic_stat_id(
				raw_intrinsic_stat_id
			)
		)


		if intrinsic_stat_id.is_empty():
			return (
				"Existe intrinsic_stat_id vacío."
			)


		if String(
			raw_intrinsic_stat_id
		) != String(
			intrinsic_stat_id
		):
			return (
				"intrinsic_stat_id no canónico: "
				+
				String(raw_intrinsic_stat_id)
			)


		if not (
			ServerEquipmentEnhancementProfileCatalog
			.INTRINSIC_STAT_IDS
			.has(
				intrinsic_stat_id
			)
		):
			return (
				"Contribution Policy para intrinsic "
				+
				"desconocido: "
				+
				String(intrinsic_stat_id)
			)


		var definition := (
			get_definition(
				intrinsic_stat_id
			)
		)


		if definition.is_empty():
			return (
				"Contribution Policy inválida: "
				+
				String(intrinsic_stat_id)
			)


		var scope_id := (
			get_scope_id(
				intrinsic_stat_id
			)
		)


		if not SCOPE_IDS.has(
			scope_id
		):
			return (
				String(intrinsic_stat_id)
				+
				" | scope_id inválido."
			)


		# ---------------------------------------------
		# CHARACTER ADDITIVE
		# ---------------------------------------------
		#
		# Debe existir también en el Stat Modifier
		# Catalog porque terminará alimentando el mismo
		# stat global.
		# ---------------------------------------------

		if scope_id == CHARACTER_ADDITIVE:
			if not (
				ServerEquipmentStatModifierCatalog
				.has_definition(
					intrinsic_stat_id
				)
			):
				return (
					String(intrinsic_stat_id)
					+
					" | character_additive requiere "
					+
					"Stat Modifier Definition."
				)


			var stat_definition := (
				ServerEquipmentStatModifierCatalog
				.get_definition(
					intrinsic_stat_id
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
				!=
				ServerEquipmentStatModifierCatalog
				.NUMERIC_INT
			):
				return (
					String(intrinsic_stat_id)
					+
					" | intrinsic character_additive "
					+
					"foundation debe ser int."
				)


	return ""
