class_name ServerVaultSnapshotValidator
extends RefCounted


# =========================================================
# VAULT
# =========================================================

const VAULT_COLUMNS: int = 8
const VAULT_ROWS: int = 16


# =========================================================
# VALIDAR
# =========================================================
#
# Retorna:
#
# ""
#     snapshot válido.
#
# cualquier otro String
#     motivo del rechazo.
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


	var container := String(
		snapshot.get(
			"container",
			""
		)
	).strip_edges()


	if container != "vault":
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


	var occupied_cells: Dictionary = {}

	var known_uids: Dictionary = {}


	for item_value in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			return "item inválido"


		var item: Dictionary = (
			item_value
		)


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


		var quantity := int(
			item.get(
				"quantity",
				0
			)
		)


		var max_stack := int(
			definition.get(
				"max_stack",
				1
			)
		)


		if quantity <= 0:
			return (
				"cantidad inválida: "
				+
				uid
			)


		if quantity > max_stack:
			return (
				"stack excedido: "
				+
				uid
			)


		var position_value: Variant = (
			item.get(
				"grid_position",
				null
			)
		)


		if typeof(position_value) != TYPE_DICTIONARY:
			return (
				"grid_position inválida: "
				+
				uid
			)


		var position: Dictionary = (
			position_value
		)


		var grid_x := int(
			position.get(
				"x",
				-1
			)
		)


		var grid_y := int(
			position.get(
				"y",
				-1
			)
		)


		var grid_width := int(
			definition.get(
				"grid_width",
				1
			)
		)


		var grid_height := int(
			definition.get(
				"grid_height",
				1
			)
		)


		if (
			grid_x < 0
			or
			grid_y < 0
		):
			return (
				"posición negativa: "
				+
				uid
			)


		if (
			grid_x + grid_width
			>
			VAULT_COLUMNS
		):
			return (
				"item fuera de Vault en X: "
				+
				uid
			)


		if (
			grid_y + grid_height
			>
			VAULT_ROWS
		):
			return (
				"item fuera de Vault en Y: "
				+
				uid
			)


		# =================================================
		# SUPERPOSICIONES
		# =================================================

		for offset_y in range(
			grid_height
		):
			for offset_x in range(
				grid_width
			):
				var cell_x := (
					grid_x
					+
					offset_x
				)


				var cell_y := (
					grid_y
					+
					offset_y
				)


				var cell_key := (
					str(cell_x)
					+
					":"
					+
					str(cell_y)
				)


				if occupied_cells.has(
					cell_key
				):
					return (
						"superposición entre "
						+
						String(
							occupied_cells[
								cell_key
							]
						)
						+
						" y "
						+
						uid
					)


				occupied_cells[
					cell_key
				] = uid


	return ""
