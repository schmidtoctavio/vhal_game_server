class_name ServerItemContainerTransferValidator
extends RefCounted


# =========================================================
# CONTENEDORES
# =========================================================

const INVENTORY_CONTAINER: String = "inventory"
const VAULT_CONTAINER: String = "vault"


# =========================================================
# VALIDAR TRANSFERENCIA
# =========================================================

static func validate_transfer(
	inventory_snapshot: Dictionary,
	vault_snapshot: Dictionary,
	uid: String,
	source_container: String,
	target_container: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> Dictionary:
	var normalized_uid := (
		uid.strip_edges()
	)


	var normalized_source := (
		source_container.strip_edges().to_lower()
	)


	var normalized_target := (
		target_container.strip_edges().to_lower()
	)


	# -----------------------------------------------------
	# PARÁMETROS BÁSICOS
	# -----------------------------------------------------

	if normalized_uid.is_empty():
		return _failure(
			"uid vacío"
		)


	if not _is_supported_container(
		normalized_source
	):
		return _failure(
			"contenedor de origen inválido"
		)


	if not _is_supported_container(
		normalized_target
	):
		return _failure(
			"contenedor de destino inválido"
		)


	if normalized_source == normalized_target:
		return _failure(
			"origen y destino deben ser diferentes"
		)


	# -----------------------------------------------------
	# VALIDAR SNAPSHOT ACTUAL DE INVENTORY
	# -----------------------------------------------------

	var inventory_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_snapshot
		)
	)


	if not inventory_error.is_empty():
		return _failure(
			(
				"Inventory autoritativo inválido: "
				+
				inventory_error
			)
		)


	# -----------------------------------------------------
	# VALIDAR SNAPSHOT ACTUAL DE VAULT
	# -----------------------------------------------------

	var vault_error := (
		ServerVaultSnapshotValidator.validate(
			vault_snapshot
		)
	)


	if not vault_error.is_empty():
		return _failure(
			(
				"Vault autoritativa inválida: "
				+
				vault_error
			)
		)


	# -----------------------------------------------------
	# AMBOS CONTENEDORES DEBEN PERTENECER A LA MISMA CUENTA
	# -----------------------------------------------------

	var inventory_account_id := int(
		inventory_snapshot.get(
			"account_id",
			0
		)
	)


	var vault_account_id := int(
		vault_snapshot.get(
			"account_id",
			0
		)
	)


	if inventory_account_id != vault_account_id:
		return _failure(
			(
				"Inventory y Vault pertenecen "
				+
				"a cuentas diferentes"
			)
		)


	# -----------------------------------------------------
	# GENERAR CANDIDATOS
	# -----------------------------------------------------

	var inventory_candidate := (
		inventory_snapshot.duplicate(
			true
		)
	)


	var vault_candidate := (
		vault_snapshot.duplicate(
			true
		)
	)


	var source_candidate: Dictionary


	if normalized_source == INVENTORY_CONTAINER:
		source_candidate = inventory_candidate
	else:
		source_candidate = vault_candidate


	var target_candidate: Dictionary


	if normalized_target == INVENTORY_CONTAINER:
		target_candidate = inventory_candidate
	else:
		target_candidate = vault_candidate


	var source_items_value: Variant = (
		source_candidate.get(
			"items",
			null
		)
	)


	var target_items_value: Variant = (
		target_candidate.get(
			"items",
			null
		)
	)


	if typeof(source_items_value) != TYPE_ARRAY:
		return _failure(
			"items del contenedor de origen inválidos"
		)


	if typeof(target_items_value) != TYPE_ARRAY:
		return _failure(
			"items del contenedor de destino inválidos"
		)


	var source_items: Array = (
		source_items_value as Array
	)


	var target_items: Array = (
		target_items_value as Array
	)


	# -----------------------------------------------------
	# LOCALIZAR ITEM EN ORIGEN
	# -----------------------------------------------------

	var source_index: int = -1

	var moved_item: Dictionary = {}


	for index in range(
		source_items.size()
	):
		var item_value: Variant = (
			source_items[
				index
			]
		)


		if typeof(item_value) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en contenedor de origen"
			)


		var item: Dictionary = (
			item_value
		)


		if String(
			item.get(
				"uid",
				""
			)
		).strip_edges() != normalized_uid:
			continue


		source_index = index

		moved_item = item.duplicate(
			true
		)


		break


	if source_index < 0:
		return _failure(
			(
				"uid no encontrado en "
				+
				normalized_source
				+
				": "
				+
				normalized_uid
			)
		)


	# -----------------------------------------------------
	# VALIDAR POSICIÓN ACTUAL
	# -----------------------------------------------------

	var current_position_value: Variant = (
		moved_item.get(
			"grid_position",
			null
		)
	)


	if typeof(
		current_position_value
	) != TYPE_DICTIONARY:
		return _failure(
			"grid_position actual inválida"
		)


	var stored_position: Dictionary = (
		current_position_value
	)


	var stored_grid_position := Vector2i(
		int(
			stored_position.get(
				"x",
				-1
			)
		),
		int(
			stored_position.get(
				"y",
				-1
			)
		)
	)


	if stored_grid_position != current_position:
		return _failure(
			"posición actual del item no coincide"
		)


	# -----------------------------------------------------
	# EL MISMO UID NO PUEDE EXISTIR YA EN DESTINO
	# -----------------------------------------------------

	for target_item_value in target_items:
		if typeof(
			target_item_value
		) != TYPE_DICTIONARY:
			return _failure(
				"item inválido en contenedor de destino"
			)


		var target_item: Dictionary = (
			target_item_value
		)


		if String(
			target_item.get(
				"uid",
				""
			)
		).strip_edges() == normalized_uid:
			return _failure(
				(
					"el uid ya existe en "
					+
					normalized_target
				)
			)


	# -----------------------------------------------------
	# SIMULAR TRANSFERENCIA
	# -----------------------------------------------------

	source_items.remove_at(
		source_index
	)


	moved_item[
		"grid_position"
	] = {
		"x": new_position.x,
		"y": new_position.y,
	}


	target_items.append(
		moved_item
	)


	source_candidate[
		"items"
	] = source_items


	target_candidate[
		"items"
	] = target_items


	# -----------------------------------------------------
	# VALIDAR INVENTORY RESULTANTE
	# -----------------------------------------------------

	var candidate_inventory_error := (
		ServerCharacterInventorySnapshotValidator.validate(
			inventory_candidate
		)
	)


	if not candidate_inventory_error.is_empty():
		return _failure(
			(
				"transferencia dejaría Inventory inválido: "
				+
				candidate_inventory_error
			)
		)


	# -----------------------------------------------------
	# VALIDAR VAULT RESULTANTE
	# -----------------------------------------------------

	var candidate_vault_error := (
		ServerVaultSnapshotValidator.validate(
			vault_candidate
		)
	)


	if not candidate_vault_error.is_empty():
		return _failure(
			(
				"transferencia dejaría Vault inválida: "
				+
				candidate_vault_error
			)
		)


	# -----------------------------------------------------
	# RESULTADO
	# -----------------------------------------------------

	return {
		"ok": true,

		"message": "",

		"source_container": normalized_source,

		"target_container": normalized_target,

		"item": moved_item.duplicate(
			true
		),

		"inventory_snapshot": (
			inventory_candidate.duplicate(
				true
			)
		),

		"vault_snapshot": (
			vault_candidate.duplicate(
				true
			)
		),
	}


# =========================================================
# CONTENEDOR SOPORTADO
# =========================================================

static func _is_supported_container(
	container: String
) -> bool:
	return (
		container == INVENTORY_CONTAINER
		or
		container == VAULT_CONTAINER
	)


# =========================================================
# ERROR
# =========================================================

static func _failure(
	message: String
) -> Dictionary:
	return {
		"ok": false,
		"message": message,
		"source_container": "",
		"target_container": "",
		"item": {},
		"inventory_snapshot": {},
		"vault_snapshot": {},
	}
