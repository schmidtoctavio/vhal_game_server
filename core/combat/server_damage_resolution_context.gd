class_name ServerDamageResolutionContext
extends RefCounted


# =========================================================
# SOURCE KINDS
# =========================================================

const SOURCE_BASIC_ATTACK: String = "basic_attack"

const SOURCE_SKILL: String = "skill"

const SOURCE_STATUS_EFFECT: String = "status_effect"


# =========================================================
# DAMAGE
# =========================================================

var raw_damage: int = 0

var school: String = ""

var element: String = ""

var delivery: String = ""

var can_critical: bool = false


# =========================================================
# SOURCE
# =========================================================

var source_kind: String = ""

var source_id: String = ""


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_raw_damage: int = 0,
	p_school: String = "",
	p_element: String = "",
	p_delivery: String = "",
	p_can_critical: bool = false,
	p_source_kind: String = "",
	p_source_id: String = ""
) -> void:
	raw_damage = p_raw_damage


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


	source_kind = (
		p_source_kind
		.strip_edges()
		.to_lower()
	)


	source_id = (
		p_source_id
		.strip_edges()
		.to_lower()
	)


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		raw_damage > 0

		and

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

		and

		(
			source_kind == SOURCE_BASIC_ATTACK
			or
			source_kind == SOURCE_SKILL
			or
			source_kind == SOURCE_STATUS_EFFECT
		)

		and

		not source_id.is_empty()
	)


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"raw_damage": raw_damage,

		"school": school,

		"element": element,

		"delivery": delivery,

		"can_critical": can_critical,

		"source": {
			"kind": source_kind,
			"id": source_id,
		},
	}


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	var taxonomy_error := (
		ServerDamageTaxonomy.validate_contract()
	)


	if not taxonomy_error.is_empty():
		return taxonomy_error


	var physical_context := (
		ServerDamageResolutionContext.new(
			100,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			true,
			SOURCE_BASIC_ATTACK,
			"bronze_sword"
		)
	)


	if not physical_context.is_valid():
		return (
			"No se pudo crear Physical Damage Context."
		)


	var fire_context := (
		ServerDamageResolutionContext.new(
			100,
			ServerDamageTaxonomy.SCHOOL_MAGICAL,
			ServerDamageTaxonomy.ELEMENT_FIRE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			false,
			SOURCE_SKILL,
			"fire_ball"
		)
	)


	if not fire_context.is_valid():
		return (
			"No se pudo crear Fire Damage Context."
		)


	var poison_context := (
		ServerDamageResolutionContext.new(
			100,
			ServerDamageTaxonomy.SCHOOL_MAGICAL,
			ServerDamageTaxonomy.ELEMENT_POISON,
			ServerDamageTaxonomy.DELIVERY_PERIODIC,
			false,
			SOURCE_STATUS_EFFECT,
			"poison"
		)
	)


	if not poison_context.is_valid():
		return (
			"No se pudo crear Poison Damage Context."
		)


	return ""
