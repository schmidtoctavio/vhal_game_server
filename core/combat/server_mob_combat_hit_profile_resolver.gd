class_name ServerMobCombatHitProfileResolver
extends RefCounted


static func resolve(
	definition: WorldMobDefinition
) -> ServerCombatHitProfile:
	if definition == null:
		return null


	if not definition.is_valid():
		return null


	var profile := (
		ServerCombatHitProfile.new(
			definition.base_accuracy_rating,
			definition.base_evasion_rating,
			definition.base_dodge_chance,
			definition.base_block_chance
		)
	)


	if not profile.is_valid():
		return null


	return profile
