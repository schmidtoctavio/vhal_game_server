class_name ServerInventoryPlacementResolver
extends RefCounted


const INVALID_POSITION := Vector2i(
	-1,
	-1
)


static func find_first_available(
	inventory_snapshot: Dictionary,
	persistent_uid: String,
	item_id: String,
	quantity: int
) -> Vector2i:
	var snapshot_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_snapshot
		)
	)


	if not snapshot_error.is_empty():
		return INVALID_POSITION


	if not ServerPersistentItemUidGenerator.is_valid_uuid(
		persistent_uid
	):
		return INVALID_POSITION


	var normalized_item_id := (
		item_id
		.strip_edges()
		.to_lower()
	)


	if normalized_item_id.is_empty():
		return INVALID_POSITION


	if quantity <= 0:
		return INVALID_POSITION


	# -----------------------------------------------------
	# No duplicamos aquí toda la lógica de multicelda.
	#
	# Probamos cada posición y dejamos que el validador
	# canónico determine si el candidate es válido.
	# -----------------------------------------------------

	for y in range(
		ServerCharacterInventorySnapshotValidator.INVENTORY_ROWS
	):
		for x in range(
			ServerCharacterInventorySnapshotValidator.INVENTORY_COLUMNS
		):
			var candidate := (
				inventory_snapshot.duplicate(
					true
				)
			)


			var items: Array = (
				candidate.get(
					"items",
					[]
				)
			)


			items.append({
				"uid": persistent_uid,

				"item_id": normalized_item_id,

				"quantity": quantity,

				"grid_position": {
					"x": x,
					"y": y,
				},

				"state": {},
			})


			candidate["items"] = items


			var validation_error := (
				ServerCharacterInventorySnapshotValidator.validate(
					candidate
				)
			)


			if validation_error.is_empty():
				return Vector2i(
					x,
					y
				)


	return INVALID_POSITION
