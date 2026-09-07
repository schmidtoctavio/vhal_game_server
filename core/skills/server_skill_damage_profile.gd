class_name ServerSkillDamageProfile
extends RefCounted


# =========================================================
# LEGACY DAMAGE TYPES
#
# Compatibilidad temporal F23.
#
# El dominio canónico nuevo usa:
#
# school
# element
# delivery
# =========================================================

const DAMAGE_PHYSICAL: String = "physical"

const DAMAGE_MAGIC: String = "magic"

const DAMAGE_POISON: String = "poison"


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
# LEGACY VIEW
# =========================================================

var damage_type: String:
	get:
		if (
			element
			==
			ServerDamageTaxonomy.ELEMENT_POISON
		):
			return DAMAGE_POISON


		if (
			school
			==
			ServerDamageTaxonomy.SCHOOL_MAGICAL
		):
			return DAMAGE_MAGIC


		return DAMAGE_PHYSICAL


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_school_or_legacy_type: String = "",
	p_element: String = ServerDamageTaxonomy.ELEMENT_NONE,
	p_delivery: String = ServerDamageTaxonomy.DELIVERY_DIRECT,
	p_can_critical: bool = false
) -> void:
	var normalized_type := (
		p_school_or_legacy_type
		.strip_edges()
		.to_lower()
	)


	var resolved_school := normalized_type


	var resolved_element := (
		p_element
		.strip_edges()
		.to_lower()
	)


	var resolved_delivery := (
		p_delivery
		.strip_edges()
		.to_lower()
	)


	# -----------------------------------------------------
	# LEGACY:
	#
	# "magic"
	# →
	# magical
	# -----------------------------------------------------

	if normalized_type == DAMAGE_MAGIC:
		resolved_school = (
			ServerDamageTaxonomy.SCHOOL_MAGICAL
		)


	# -----------------------------------------------------
	# LEGACY:
	#
	# "poison"
	# →
	# magical / poison / periodic
	# -----------------------------------------------------

	elif normalized_type == DAMAGE_POISON:
		resolved_school = (
			ServerDamageTaxonomy.SCHOOL_MAGICAL
		)


		if (
			resolved_element
			==
			ServerDamageTaxonomy.ELEMENT_NONE
		):
			resolved_element = (
				ServerDamageTaxonomy.ELEMENT_POISON
			)


		if (
			resolved_delivery
			==
			ServerDamageTaxonomy.DELIVERY_DIRECT
		):
			resolved_delivery = (
				ServerDamageTaxonomy.DELIVERY_PERIODIC
			)


	school = resolved_school

	element = resolved_element

	delivery = resolved_delivery

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
