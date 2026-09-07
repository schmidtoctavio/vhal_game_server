class_name ServerDamageResolutionResult
extends RefCounted


# =========================================================
# SOURCE / TAXONOMY
# =========================================================

var source_kind: String = ""

var source_id: String = ""

var school: String = ""

var element: String = ""

var delivery: String = ""


# =========================================================
# DAMAGE BREAKDOWN
# =========================================================

var raw_damage: int = 0

var critical_applied: bool = false

var critical_roll: float = 0.0

var critical_multiplier: float = 1.0

var pre_mitigation_damage: int = 0


# =========================================================
# DEFENSE BREAKDOWN
# =========================================================

var school_rating: int = 0

var post_school_damage: int = 0

var element_rating: int = 0

var post_element_damage: int = 0


# =========================================================
# FINAL
# =========================================================

var final_damage: int = 0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_source_kind: String = "",
	p_source_id: String = "",
	p_school: String = "",
	p_element: String = "",
	p_delivery: String = "",
	p_raw_damage: int = 0,
	p_critical_applied: bool = false,
	p_critical_roll: float = 0.0,
	p_critical_multiplier: float = 1.0,
	p_pre_mitigation_damage: int = 0,
	p_school_rating: int = 0,
	p_post_school_damage: int = 0,
	p_element_rating: int = 0,
	p_post_element_damage: int = 0,
	p_final_damage: int = 0
) -> void:
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


	raw_damage = p_raw_damage

	critical_applied = p_critical_applied

	critical_roll = p_critical_roll

	critical_multiplier = p_critical_multiplier

	pre_mitigation_damage = (
		p_pre_mitigation_damage
	)

	school_rating = p_school_rating

	post_school_damage = (
		p_post_school_damage
	)

	element_rating = p_element_rating

	post_element_damage = (
		p_post_element_damage
	)

	final_damage = p_final_damage


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		not source_kind.is_empty()

		and

		not source_id.is_empty()

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

		raw_damage > 0

		and

		critical_roll >= 0.0

		and

		critical_roll <= 1.0

		and

		critical_multiplier >= 1.0

		and

		pre_mitigation_damage > 0

		and

		school_rating >= 0

		and

		post_school_damage > 0

		and

		element_rating >= 0

		and

		post_element_damage > 0

		and

		final_damage > 0
	)


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"source": {
			"kind": source_kind,
			"id": source_id,
		},

		"taxonomy": {
			"school": school,
			"element": element,
			"delivery": delivery,
		},

		"damage": {
			"raw": raw_damage,

			"critical": {
				"applied": critical_applied,
				"roll": critical_roll,
				"multiplier": critical_multiplier,
			},

			"pre_mitigation": (
				pre_mitigation_damage
			),

			"school": {
				"rating": school_rating,
				"post_damage": (
					post_school_damage
				),
			},

			"element": {
				"rating": element_rating,
				"post_damage": (
					post_element_damage
				),
			},

			"final": final_damage,
		},
	}
