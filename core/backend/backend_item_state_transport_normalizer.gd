class_name BackendItemStateTransportNormalizer
extends RefCounted


# =========================================================
# KEYS
# =========================================================

const STATE_KEY: String = "state"

const ENHANCEMENT_LEVEL_KEY: String = (
	"enhancement_level"
)


# =========================================================
# NORMALIZAR ARRAY DE ITEMS DESDE JSON
# =========================================================
#
# JSON es una frontera de transporte.
#
# El dominio interno de VHAL sí distingue:
#
# int
# float
#
# Por eso normalizamos únicamente campos cuyo contrato
# semántico exige entero.
#
# IMPORTANTE:
#
# - 1.0  -> 1
# - 7.0  -> 7
# - 1.5  permanece float y el dominio lo rechazará
# - "1"  permanece String y el dominio lo rechazará
#
# No corregimos datos inválidos silenciosamente.
# =========================================================

static func normalize_items(
	items: Array
) -> Array:
	var normalized_items: Array = []


	for item_value: Variant in items:
		if typeof(item_value) != TYPE_DICTIONARY:
			normalized_items.append(
				item_value
			)


			continue


		normalized_items.append(
			normalize_item(
				item_value as Dictionary
			)
		)


	return normalized_items


# =========================================================
# NORMALIZAR ITEM DESDE JSON
# =========================================================

static func normalize_item(
	item: Dictionary
) -> Dictionary:
	var normalized_item := (
		item.duplicate(
			true
		)
	)


	var state_value: Variant = (
		normalized_item.get(
			STATE_KEY,
			null
		)
	)


	if typeof(state_value) != TYPE_DICTIONARY:
		return normalized_item


	var state: Dictionary = (
		state_value as Dictionary
	).duplicate(
		true
	)


	if not state.has(
		ENHANCEMENT_LEVEL_KEY
	):
		return normalized_item


	var level_value: Variant = (
		state[
			ENHANCEMENT_LEVEL_KEY
		]
	)


	# -----------------------------------------------------
	# Ya es dominio canónico.
	# -----------------------------------------------------

	if typeof(level_value) == TYPE_INT:
		return normalized_item


	# -----------------------------------------------------
	# Sólo FLOAT proveniente de JSON puede normalizarse.
	#
	# Otros tipos permanecen intactos para que las reglas
	# de dominio puedan rechazarlos.
	# -----------------------------------------------------

	if typeof(level_value) != TYPE_FLOAT:
		return normalized_item


	var float_level := float(
		level_value
	)


	# -----------------------------------------------------
	# No convertimos 1.5 -> 1.
	#
	# Sólo un número matemáticamente entero puede cruzar
	# la frontera como int.
	# -----------------------------------------------------

	if float_level != floor(
		float_level
	):
		return normalized_item


	state[
		ENHANCEMENT_LEVEL_KEY
	] = int(
		float_level
	)


	normalized_item[
		STATE_KEY
	] = state


	return normalized_item
