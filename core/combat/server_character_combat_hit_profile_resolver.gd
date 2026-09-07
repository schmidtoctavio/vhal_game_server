class_name ServerCharacterCombatHitProfileResolver
extends RefCounted


const BASE_ACCURACY_RATING: int = 100

const ACCURACY_PER_AGILITY: int = 2

const EVASION_PER_AGILITY: int = 1


static func resolve(
	primary_stats: ServerCharacterPrimaryStatsState,
	equipment_snapshot: Dictionary
) -> ServerCombatHitProfile:
	if primary_stats == null:
		return null


	if not primary_stats.is_valid():
		return null


	if equipment_snapshot.is_empty():
		return null


	var contributions := (
		ServerEquipmentResolvedContributionRules
		.resolve_equipment_snapshot(
			equipment_snapshot
		)
	)


	if contributions.is_empty():
		return null


	var effective_primary := (
		ServerCharacterEffectivePrimaryStatsRules
		.resolve(
			primary_stats,
			contributions
		)
	)


	if effective_primary.is_empty():
		return null


	var agility_value: Variant = (
		ServerCharacterEffectivePrimaryStatsRules
		.get_effective_value(
			effective_primary,
			ServerEquipmentStatModifierCatalog.AGILITY
		)
	)


	if typeof(agility_value) != TYPE_INT:
		return null


	var effective_agility := int(
		agility_value
	)


	if effective_agility < 0:
		return null


	var accuracy_bonus := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
				.ACCURACY_RATING
		)
	)


	var evasion_bonus := (
		_get_int_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
				.EVASION_RATING
		)
	)


	var dodge_bonus := (
		_get_number_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
				.DODGE_CHANCE
		)
	)


	var block_bonus := (
		_get_number_stat(
			contributions,
			ServerEquipmentStatModifierCatalog
				.BLOCK_CHANCE
		)
	)


	if (
		accuracy_bonus < 0
		or
		evasion_bonus < 0
		or
		dodge_bonus < 0.0
		or
		block_bonus < 0.0
	):
		return null


	var profile := (
		ServerCombatHitProfile.new(
			BASE_ACCURACY_RATING
			+
			(
				effective_agility
				*
				ACCURACY_PER_AGILITY
			)
			+
			accuracy_bonus,

			(
				effective_agility
				*
				EVASION_PER_AGILITY
			)
			+
			evasion_bonus,

			clampf(
				dodge_bonus,
				0.0,
				1.0
			),

			clampf(
				block_bonus,
				0.0,
				1.0
			)
		)
	)


	if not profile.is_valid():
		return null


	return profile


static func _get_int_stat(
	contributions: Dictionary,
	stat_id: Variant
) -> int:
	var value: Variant = (
		ServerEquipmentResolvedContributionRules
		.get_stat_total(
			contributions,
			stat_id
		)
	)


	if typeof(value) != TYPE_INT:
		return -1


	return int(
		value
	)


static func _get_number_stat(
	contributions: Dictionary,
	stat_id: Variant
) -> float:
	var value: Variant = (
		ServerEquipmentResolvedContributionRules
		.get_stat_total(
			contributions,
			stat_id
		)
	)


	if (
		typeof(value) != TYPE_INT
		and
		typeof(value) != TYPE_FLOAT
	):
		return -1.0


	return float(
		value
	)
