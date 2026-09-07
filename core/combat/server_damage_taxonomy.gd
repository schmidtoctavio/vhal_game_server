class_name ServerDamageTaxonomy
extends RefCounted


# =========================================================
# DAMAGE SCHOOL
# =========================================================

const SCHOOL_PHYSICAL: String = "physical"

const SCHOOL_MAGICAL: String = "magical"


# =========================================================
# DAMAGE ELEMENT
# =========================================================

const ELEMENT_NONE: String = "none"

const ELEMENT_FIRE: String = "fire"

const ELEMENT_COLD: String = "cold"

const ELEMENT_LIGHTNING: String = "lightning"

const ELEMENT_POISON: String = "poison"


# =========================================================
# DELIVERY
# =========================================================

const DELIVERY_DIRECT: String = "direct"

const DELIVERY_PERIODIC: String = "periodic"


# =========================================================
# VALIDACIÓN
# =========================================================

static func is_valid_school(
	value: String
) -> bool:
	return (
		value == SCHOOL_PHYSICAL
		or
		value == SCHOOL_MAGICAL
	)


static func is_valid_element(
	value: String
) -> bool:
	return (
		value == ELEMENT_NONE
		or
		value == ELEMENT_FIRE
		or
		value == ELEMENT_COLD
		or
		value == ELEMENT_LIGHTNING
		or
		value == ELEMENT_POISON
	)


static func is_valid_delivery(
	value: String
) -> bool:
	return (
		value == DELIVERY_DIRECT
		or
		value == DELIVERY_PERIODIC
	)


static func validate_contract() -> String:
	var schools := PackedStringArray(
		[
			SCHOOL_PHYSICAL,
			SCHOOL_MAGICAL,
		]
	)


	var elements := PackedStringArray(
		[
			ELEMENT_NONE,
			ELEMENT_FIRE,
			ELEMENT_COLD,
			ELEMENT_LIGHTNING,
			ELEMENT_POISON,
		]
	)


	var deliveries := PackedStringArray(
		[
			DELIVERY_DIRECT,
			DELIVERY_PERIODIC,
		]
	)


	var seen: Dictionary = {}


	for school: String in schools:
		if not is_valid_school(
			school
		):
			return (
				"Damage School inválida: "
				+
				school
			)


		if seen.has(
			school
		):
			return (
				"Damage School duplicada: "
				+
				school
			)


		seen[school] = true


	seen.clear()


	for element: String in elements:
		if not is_valid_element(
			element
		):
			return (
				"Damage Element inválido: "
				+
				element
			)


		if seen.has(
			element
		):
			return (
				"Damage Element duplicado: "
				+
				element
			)


		seen[element] = true


	seen.clear()


	for delivery: String in deliveries:
		if not is_valid_delivery(
			delivery
		):
			return (
				"Damage Delivery inválido: "
				+
				delivery
			)


		if seen.has(
			delivery
		):
			return (
				"Damage Delivery duplicado: "
				+
				delivery
			)


		seen[delivery] = true


	return ""
