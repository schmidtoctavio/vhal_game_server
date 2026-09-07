class_name ServerMobBasicAttackRules
extends RefCounted


static func build_resolution_context(
	definition: WorldMobDefinition
) -> ServerDamageResolutionContext:
	if definition == null:
		return null


	if not definition.is_valid():
		return null


	if not definition.has_pve_combat_profile():
		return null


	var context := (
		ServerDamageResolutionContext.new(
			definition.base_attack_damage,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			false,
			ServerDamageResolutionContext
				.SOURCE_BASIC_ATTACK,
			definition.mob_type_id
		)
	)


	if not context.is_valid():
		return null


	return context
