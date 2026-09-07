class_name ServerDamageDefenseProfile
extends RefCounted


# =========================================================
# SCHOOL DEFENSE
# =========================================================

var armor_rating: int = 0

var magic_resistance_rating: int = 0


# =========================================================
# ELEMENTAL DEFENSE
# =========================================================

var fire_resistance_rating: int = 0

var cold_resistance_rating: int = 0

var lightning_resistance_rating: int = 0

var poison_resistance_rating: int = 0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_armor_rating: int = 0,
	p_magic_resistance_rating: int = 0,
	p_fire_resistance_rating: int = 0,
	p_cold_resistance_rating: int = 0,
	p_lightning_resistance_rating: int = 0,
	p_poison_resistance_rating: int = 0
) -> void:
	armor_rating = p_armor_rating

	magic_resistance_rating = (
		p_magic_resistance_rating
	)

	fire_resistance_rating = (
		p_fire_resistance_rating
	)

	cold_resistance_rating = (
		p_cold_resistance_rating
	)

	lightning_resistance_rating = (
		p_lightning_resistance_rating
	)

	poison_resistance_rating = (
		p_poison_resistance_rating
	)


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		armor_rating >= 0

		and
		magic_resistance_rating >= 0

		and
		fire_resistance_rating >= 0

		and
		cold_resistance_rating >= 0

		and
		lightning_resistance_rating >= 0

		and
		poison_resistance_rating >= 0
	)


# =========================================================
# SCHOOL RATING
# =========================================================

func get_school_rating(
	school: String
) -> int:
	match school:
		ServerDamageTaxonomy.SCHOOL_PHYSICAL:
			return armor_rating

		ServerDamageTaxonomy.SCHOOL_MAGICAL:
			return magic_resistance_rating


	return -1


# =========================================================
# ELEMENT RATING
# =========================================================

func get_element_rating(
	element: String
) -> int:
	match element:
		ServerDamageTaxonomy.ELEMENT_NONE:
			return 0

		ServerDamageTaxonomy.ELEMENT_FIRE:
			return fire_resistance_rating

		ServerDamageTaxonomy.ELEMENT_COLD:
			return cold_resistance_rating

		ServerDamageTaxonomy.ELEMENT_LIGHTNING:
			return lightning_resistance_rating

		ServerDamageTaxonomy.ELEMENT_POISON:
			return poison_resistance_rating


	return -1


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"armor_rating": armor_rating,

		"magic_resistance_rating": (
			magic_resistance_rating
		),

		"elemental_resistance": {
			"fire": fire_resistance_rating,

			"cold": cold_resistance_rating,

			"lightning": (
				lightning_resistance_rating
			),

			"poison": poison_resistance_rating,
		},
	}


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	var empty_profile := (
		ServerDamageDefenseProfile.new()
	)


	if not empty_profile.is_valid():
		return (
			"No se pudo crear Defense Profile vacío."
		)


	if (
		empty_profile.get_school_rating(
			ServerDamageTaxonomy.SCHOOL_PHYSICAL
		)
		!=
		0
	):
		return (
			"Defense foundation debe comenzar "
			+
			"con Armor 0."
		)


	if (
		empty_profile.get_school_rating(
			ServerDamageTaxonomy.SCHOOL_MAGICAL
		)
		!=
		0
	):
		return (
			"Defense foundation debe comenzar "
			+
			"con Magic Resistance 0."
		)


	var profile := (
		ServerDamageDefenseProfile.new(
			100,
			80,
			25,
			15,
			10,
			30
		)
	)


	if not profile.is_valid():
		return (
			"No se pudo crear Damage Defense Profile."
		)


	if (
		profile.get_school_rating(
			ServerDamageTaxonomy.SCHOOL_PHYSICAL
		)
		!=
		100
	):
		return "Physical School no resolvió Armor 100."


	if (
		profile.get_school_rating(
			ServerDamageTaxonomy.SCHOOL_MAGICAL
		)
		!=
		80
	):
		return (
			"Magical School no resolvió "
			+
			"Magic Resistance 80."
		)


	if (
		profile.get_element_rating(
			ServerDamageTaxonomy.ELEMENT_FIRE
		)
		!=
		25
	):
		return "Fire Resistance no resolvió 25."


	if (
		profile.get_element_rating(
			ServerDamageTaxonomy.ELEMENT_COLD
		)
		!=
		15
	):
		return "Cold Resistance no resolvió 15."


	if (
		profile.get_element_rating(
			ServerDamageTaxonomy.ELEMENT_LIGHTNING
		)
		!=
		10
	):
		return (
			"Lightning Resistance no resolvió 10."
		)


	if (
		profile.get_element_rating(
			ServerDamageTaxonomy.ELEMENT_POISON
		)
		!=
		30
	):
		return "Poison Resistance no resolvió 30."


	if (
		profile.get_element_rating(
			ServerDamageTaxonomy.ELEMENT_NONE
		)
		!=
		0
	):
		return (
			"Element none debe resolver Resistance 0."
		)


	return ""
