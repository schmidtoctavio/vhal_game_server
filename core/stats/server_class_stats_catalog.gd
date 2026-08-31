class_name ServerClassStatsCatalog
extends RefCounted


# =========================================================
# CLASS IDS
# =========================================================

const WARRIOR_ID: String = "warrior"

const MAGE_ID: String = "mage"

const ARCHER_ID: String = "archer"


# =========================================================
# FOUNDATION ACTUAL
# =========================================================
#
# Estos valores pertenecen al contrato F22 aprobado.
#
# No significan que todas las clases futuras deban tener
# necesariamente el mismo total o Points per Level.
#
# La Definition permite esos valores por clase.
# =========================================================

const FOUNDATION_STARTING_STAT_TOTAL: int = 75

const FOUNDATION_STAT_POINTS_PER_LEVEL: int = 5


# =========================================================
# DEFINICIONES
# =========================================================

static func get_definition(
	class_id: String
) -> ServerClassStatsDefinition:
	var normalized_class_id := (
		class_id
		.strip_edges()
		.to_lower()
	)


	match normalized_class_id:
		WARRIOR_ID:
			return ServerClassStatsDefinition.new(
				WARRIOR_ID,
				25,
				15,
				25,
				10,
				5,
				100,
				8,
				4,
				30,
				1,
				3,
				10,
				2,
				2,
				0,
				0,
				0,
				1,
				0,
				0,
				1
			)


		MAGE_ID:
			return ServerClassStatsDefinition.new(
				MAGE_ID,
				10,
				15,
				15,
				35,
				5,
				70,
				5,
				3,
				120,
				4,
				5,
				5,
				1,
				1,
				0,
				20,
				2,
				2,
				10,
				1,
				2
			)


		ARCHER_ID:
			return ServerClassStatsDefinition.new(
				ARCHER_ID,
				15,
				30,
				15,
				15,
				5,
				85,
				6,
				3,
				70,
				2,
				4,
				15,
				2,
				1,
				1,
				0,
				0,
				1,
				0,
				0,
				1
			)


	return null


# =========================================================
# CONSULTAS
# =========================================================

static func has_definition(
	class_id: String
) -> bool:
	return (
		get_definition(
			class_id
		)
		!=
		null
	)


static func get_all_class_ids() -> PackedStringArray:
	return PackedStringArray(
		[
			WARRIOR_ID,
			MAGE_ID,
			ARCHER_ID,
		]
	)


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	var seen_class_ids: Dictionary = {}


	for class_id: String in get_all_class_ids():
		var normalized_class_id := (
			class_id
			.strip_edges()
			.to_lower()
		)


		if normalized_class_id.is_empty():
			return (
				"Existe un class_id vacío."
			)


		if seen_class_ids.has(
			normalized_class_id
		):
			return (
				"Class duplicada: "
				+
				normalized_class_id
			)


		seen_class_ids[
			normalized_class_id
		] = true


		var definition := (
			get_definition(
				normalized_class_id
			)
		)


		if definition == null:
			return (
				"No existe definición para Class: "
				+
				normalized_class_id
			)


		if not definition.is_valid():
			return (
				"Definición inválida para Class: "
				+
				normalized_class_id
			)


		if (
			definition.class_id
			!=
			normalized_class_id
		):
			return (
				"El class_id de la definición "
				+
				"no coincide: "
				+
				normalized_class_id
			)


		if (
			definition.get_starting_stat_total()
			!=
			FOUNDATION_STARTING_STAT_TOTAL
		):
			return (
				"El total de Stats base de "
				+
				normalized_class_id
				+
				" debe ser "
				+
				str(
					FOUNDATION_STARTING_STAT_TOTAL
				)
				+
				"."
			)


		if (
			definition.stat_points_per_level
			!=
			FOUNDATION_STAT_POINTS_PER_LEVEL
		):
			return (
				"Los Stat Points por Level de "
				+
				normalized_class_id
				+
				" deben ser "
				+
				str(
					FOUNDATION_STAT_POINTS_PER_LEVEL
				)
				+
				"."
			)


	return ""
