class_name ServerMobDamageDefenseProfileResolver
extends RefCounted


# =========================================================
# RESOLVER
# =========================================================

static func resolve(
	definition: WorldMobDefinition
) -> ServerDamageDefenseProfile:
	if definition == null:
		return null


	if not definition.is_valid():
		return null


	var profile := (
		ServerDamageDefenseProfile.new(
			definition.base_armor_rating,

			definition
			.base_magic_resistance_rating,

			definition
			.base_fire_resistance_rating,

			definition
			.base_cold_resistance_rating,

			definition
			.base_lightning_resistance_rating,

			definition
			.base_poison_resistance_rating
		)
	)


	if not profile.is_valid():
		return null


	return profile


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	var definition := (
		WorldMobDefinition.create(
			"damage_defense_test",
			"Damage Defense Test",
			1,
			100,
			0,
			5.0,

			100,
			80,
			25,
			15,
			10,
			30
		)
	)


	if definition == null:
		return (
			"No se pudo crear Mob Definition sintética."
		)


	if not definition.is_valid():
		return (
			"Mob Definition defensiva inválida."
		)


	var profile := (
		resolve(
			definition
		)
	)


	if profile == null:
		return (
			"No se pudo resolver Mob Damage Defense Profile."
		)


	if profile.armor_rating != 100:
		return "Mob Armor no resolvió 100."


	if profile.magic_resistance_rating != 80:
		return (
			"Mob Magic Resistance no resolvió 80."
		)


	if profile.fire_resistance_rating != 25:
		return (
			"Mob Fire Resistance no resolvió 25."
		)


	if profile.cold_resistance_rating != 15:
		return (
			"Mob Cold Resistance no resolvió 15."
		)


	if profile.lightning_resistance_rating != 10:
		return (
			"Mob Lightning Resistance no resolvió 10."
		)


	if profile.poison_resistance_rating != 30:
		return (
			"Mob Poison Resistance no resolvió 30."
		)


	return ""
