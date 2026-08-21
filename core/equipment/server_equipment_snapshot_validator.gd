class_name ServerEquipmentSnapshotValidator
extends RefCounted


# =========================================================
# VALIDAR SNAPSHOT
# =========================================================

static func validate(
	snapshot: Dictionary
) -> String:
	var account_id := int(
		snapshot.get(
			"account_id",
			0
		)
	)


	if account_id <= 0:
		return "account_id inválido"


	var character_id := int(
		snapshot.get(
			"character_id",
			0
		)
	)


	if character_id <= 0:
		return "character_id inválido"


	var container := String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges()


	if container != "equipment":
		return "container inválido"


	var items_value: Variant = (
		snapshot.get(
			"items",
			null
		)
	)


	if typeof(items_value) != TYPE_ARRAY:
		return "items inválido"


	var items: Array = (
		items_value as Array
	)


	var known_uids: Dictionary = {}

	var items_by_slot: Dictionary = {}

	var definitions_by_slot: Dictionary = {}


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "item inválido"


		var item: Dictionary = (
			item_value
		)


		# -------------------------------------------------
		# UID
		# -------------------------------------------------

		var uid := String(
			item.get(
				"uid",
				""
			)
		).strip_edges()


		if uid.is_empty():
			return "item sin uid"


		if known_uids.has(
			uid
		):
			return (
				"uid duplicado: "
				+
				uid
			)


		known_uids[
			uid
		] = true


		# -------------------------------------------------
		# ITEM ID / DEFINITION
		# -------------------------------------------------

		var item_id := String(
			item.get(
				"item_id",
				""
			)
		).strip_edges()


		if item_id.is_empty():
			return (
				"item sin item_id: "
				+
				uid
			)


		var definition := (
			ServerItemCatalog.get_definition(
				item_id
			)
		)


		if definition.is_empty():
			return (
				"item_id desconocido: "
				+
				item_id
			)


		if not ServerEquipmentRules.is_equipment_definition(
			definition
		):
			return (
				"item no es Equipment: "
				+
				item_id
			)


		# -------------------------------------------------
		# QUANTITY
		# -------------------------------------------------

		var quantity := int(
			item.get(
				"quantity",
				0
			)
		)


		if quantity != 1:
			return (
				"cantidad de Equipment inválida: "
				+
				uid
			)


		if int(
			definition.get(
				"max_stack",
				1
			)
		) != 1:
			return (
				"definición Equipment stackable no soportada: "
				+
				item_id
			)


		# -------------------------------------------------
		# EQUIPMENT SLOT
		# -------------------------------------------------

		var raw_slot_id := String(
			item.get(
				"equipment_slot",
				""
			)
		).strip_edges()


		var slot_id := (
			ServerEquipmentSlotCatalog.normalize_slot_id(
				raw_slot_id
			)
		)


		if not ServerEquipmentSlotCatalog.is_valid_slot_id(
			slot_id
		):
			return (
				"equipment_slot inválido: "
				+
				raw_slot_id
			)


		if raw_slot_id != String(
			slot_id
		):
			return (
				"equipment_slot no canónico: "
				+
				raw_slot_id
			)


		if items_by_slot.has(
			slot_id
		):
			return (
				"slot duplicado: "
				+
				raw_slot_id
			)


		if not ServerEquipmentRules.can_definition_use_slot(
			definition,
			slot_id
		):
			return (
				"item incompatible con slot: "
				+
				item_id
				+
				" -> "
				+
				raw_slot_id
			)


		# -------------------------------------------------
		# EQUIPMENT NO USA GRID POSITION
		# -------------------------------------------------

		if item.has(
			"grid_position"
		):
			return (
				"Equipment contiene grid_position: "
				+
				uid
			)


		items_by_slot[
			slot_id
		] = item


		definitions_by_slot[
			slot_id
		] = definition


	# =====================================================
	# RESERVAS DERIVADAS
	# =====================================================

	for slot_value: Variant in items_by_slot.keys():
		var slot_id := (
			ServerEquipmentSlotCatalog.normalize_slot_id(
				slot_value
			)
		)


		var definition: Dictionary = (
			definitions_by_slot[
				slot_value
			]
		)


		var reserved_slots := (
			ServerEquipmentRules.get_reserved_slot_ids(
				definition,
				slot_id
			)
		)


		for reserved_slot: StringName in reserved_slots:
			if items_by_slot.has(
				reserved_slot
			):
				return (
					"slot reservado ocupado: "
					+
					String(reserved_slot)
				)


	return ""
