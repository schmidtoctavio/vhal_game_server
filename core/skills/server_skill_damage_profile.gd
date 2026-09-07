class_name ServerSkillDamageProfile
extends RefCounted


# =========================================================
# DAMAGE TAXONOMY
# =========================================================

var school: String = ""

var element: String = (
	ServerDamageTaxonomy.ELEMENT_NONE
)

var delivery: String = (
	ServerDamageTaxonomy.DELIVERY_DIRECT
)

var can_critical: bool = false


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_school: String = "",
	p_element: String = ServerDamageTaxonomy.ELEMENT_NONE,
	p_delivery: String = ServerDamageTaxonomy.DELIVERY_DIRECT,
	p_can_critical: bool = false
) -> void:
	school = (
		p_school
		.strip_edges()
		.to_lower()
	)


	element = (
		p_element
		.strip_edges()
		.to_lower()
	)


	delivery = (
		p_delivery
		.strip_edges()
		.to_lower()
	)


	can_critical = p_can_critical


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		ServerDamageTaxonomy.is_valid_school(
			school
		)

		and

		ServerDamageTaxonomy.is_valid_element(
			element
		)

		and

		ServerDamageTaxonomy.is_valid_delivery(
			delivery
		)
	)


# =========================================================
# RESOLUTION CONTEXT
# =========================================================

func build_resolution_context(
	raw_damage: int,
	source_kind: String,
	source_id: String
) -> ServerDamageResolutionContext:
	if not is_valid():
		return null


	if raw_damage <= 0:
		return null


	var context := (
		ServerDamageResolutionContext.new(
			raw_damage,
			school,
			element,
			delivery,
			can_critical,
			source_kind,
			source_id
		)
	)


	if not context.is_valid():
		return null


	return context
