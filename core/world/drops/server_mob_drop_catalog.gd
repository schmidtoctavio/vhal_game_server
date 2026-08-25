class_name ServerMobDropCatalog
extends RefCounted


# =========================================================
# DROP TABLES
# =========================================================
#
# Foundation:
#
# Training Goblin
# → Health Potion x1
# → 100%
#
# El 100% es deliberado para que F18-A sea testeable.
# =========================================================

const DROP_TABLES: Dictionary = {
	"training_goblin": [
		{
			"item_id": "health_potion",

			"chance": 1.0,

			"quantity_min": 1,

			"quantity_max": 1,
		},
	],
}


# =========================================================
# VALIDAR CONTRATO
# =========================================================

static func validate_contract() -> String:
	for mob_type_value: Variant in DROP_TABLES.keys():
		var mob_type_id := String(
			mob_type_value
		).strip_edges().to_lower()


		if mob_type_id.is_empty():
			return "Existe un mob_type_id vacío."


		var entries_value: Variant = (
			DROP_TABLES[
				mob_type_value
			]
		)


		if typeof(entries_value) != TYPE_ARRAY:
			return (
				"Drop table inválida para '%s'."
				%
				mob_type_id
			)


		var entries: Array = (
			entries_value
		)


		for entry_value: Variant in entries:
			if typeof(entry_value) != TYPE_DICTIONARY:
				return (
					"Drop entry inválido para '%s'."
					%
					mob_type_id
				)


			var entry: Dictionary = (
				entry_value
			)


			var item_id := String(
				entry.get(
					"item_id",
					""
				)
			).strip_edges().to_lower()


			if item_id.is_empty():
				return (
					"Drop sin item_id para '%s'."
					%
					mob_type_id
				)


			if not ServerItemCatalog.has_definition(
				item_id
			):
				return (
					"Item de drop desconocido '%s'."
					%
					item_id
				)


			var chance := float(
				entry.get(
					"chance",
					-1.0
				)
			)


			if (
				chance < 0.0
				or
				chance > 1.0
			):
				return (
					"Chance inválida para '%s'."
					%
					item_id
				)


			var quantity_min := int(
				entry.get(
					"quantity_min",
					0
				)
			)


			var quantity_max := int(
				entry.get(
					"quantity_max",
					0
				)
			)


			if (
				quantity_min <= 0
				or
				quantity_max < quantity_min
			):
				return (
					"Cantidad inválida para '%s'."
					%
					item_id
				)


			var item_definition := (
				ServerItemCatalog.get_definition(
					item_id
				)
			)


			var max_stack := int(
				item_definition.get(
					"max_stack",
					0
				)
			)


			if quantity_max > max_stack:
				return (
					"Drop de '%s' supera max_stack."
					%
					item_id
				)


	return ""


# =========================================================
# ROLL
# =========================================================

static func roll_drops(
	mob_type_id: String
) -> Array[Dictionary]:
	var normalized_mob_type_id := (
		mob_type_id
		.strip_edges()
		.to_lower()
	)


	var result: Array[Dictionary] = []


	if normalized_mob_type_id.is_empty():
		return result


	if not DROP_TABLES.has(
		normalized_mob_type_id
	):
		return result


	var entries: Array = (
		DROP_TABLES[
			normalized_mob_type_id
		]
	)


	for entry_value: Variant in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue


		var entry: Dictionary = (
			entry_value
		)


		var chance := float(
			entry.get(
				"chance",
				0.0
			)
		)


		if randf() > chance:
			continue


		var quantity_min := int(
			entry.get(
				"quantity_min",
				1
			)
		)


		var quantity_max := int(
			entry.get(
				"quantity_max",
				quantity_min
			)
		)


		var quantity := randi_range(
			quantity_min,
			quantity_max
		)


		result.append(
			{
				"item_id": String(
					entry.get(
						"item_id",
						""
					)
				).strip_edges().to_lower(),

				"quantity": quantity,
			}
		)


	return result
