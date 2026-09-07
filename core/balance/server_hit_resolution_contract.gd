class_name ServerHitResolutionContract
extends RefCounted


static func validate_contract() -> String:
	var primary_stats := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			7,
			11,
			0,
			25,
			15,
			25,
			10,
			2,
			0,
			2,
			3,
			5,
			200,
			50,
			0,
			0,
			50,
			7,
			43
		)
	)


	if not primary_stats.is_valid():
		return (
			"No se pudo crear Primary Stats foundation."
		)


	var empty_equipment := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",
		"items": [],
	}


	var empty_profile := (
		ServerCharacterCombatHitProfileResolver
		.resolve(
			primary_stats,
			empty_equipment
		)
	)


	if empty_profile == null:
		return (
			"No se pudo resolver Hit Profile vacío."
		)


	# Effective AGI 15:
	#
	# Accuracy = 100 + 15 * 2 = 130
	# Evasion  = 15

	if empty_profile.accuracy_rating != 130:
		return (
			"AGI 15 debe resolver Accuracy 130."
		)


	if empty_profile.evasion_rating != 15:
		return (
			"AGI 15 debe resolver Evasion 15."
		)


	if not is_zero_approx(
		empty_profile.dodge_chance
	):
		return "Equipment vacío debe resolver Dodge 0."


	if not is_zero_approx(
		empty_profile.block_chance
	):
		return "Equipment vacío debe resolver Block 0."


	var equipment_snapshot := {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			{
				"uid": "hit-profile-helmet",

				"item_id": "leather_helmet",

				"quantity": 1,

				"equipment_slot": "head",

				"state": {
					"enhancement_level": 0,

					"rolled_modifiers": [
						{
							"stat_id": "agility",
							"operation_id": "flat_add",
							"value": 5,
						},

						{
							"stat_id": "accuracy_rating",
							"operation_id": "flat_add",
							"value": 10,
						},

						{
							"stat_id": "evasion_rating",
							"operation_id": "flat_add",
							"value": 20,
						},

						{
							"stat_id": "dodge_chance",
							"operation_id": "flat_add",
							"value": 0.10,
						},

						{
							"stat_id": "block_chance",
							"operation_id": "flat_add",
							"value": 0.25,
						},
					],
				},
			},
		],
	}


	var attacker_profile := (
		ServerCharacterCombatHitProfileResolver
		.resolve(
			primary_stats,
			equipment_snapshot
		)
	)


	if attacker_profile == null:
		return (
			"No se pudo resolver Equipment Hit Profile."
		)


	# Effective AGI:
	#
	# 15 + 5 = 20
	#
	# Accuracy:
	# 100 + 20 * 2 + 10 = 150
	#
	# Evasion:
	# 20 + 20 = 40

	if attacker_profile.accuracy_rating != 150:
		return "Equipment Hit Profile debe resolver Accuracy 150."


	if attacker_profile.evasion_rating != 40:
		return "Equipment Hit Profile debe resolver Evasion 40."


	if not is_equal_approx(
		attacker_profile.dodge_chance,
		0.10
	):
		return "Equipment Dodge debe resolver 0.10."


	if not is_equal_approx(
		attacker_profile.block_chance,
		0.25
	):
		return "Equipment Block debe resolver 0.25."


	var target_definition := (
		WorldMobDefinition.create(
			"hit_resolution_target",
			"Hit Resolution Target",
			1,
			100,
			0,
			5.0,

			0,
			0,
			0,
			0,
			0,
			0,

			150,
			50,
			0.25,
			0.50
		)
	)


	var defender_profile := (
		ServerMobCombatHitProfileResolver
		.resolve(
			target_definition
		)
	)


	if defender_profile == null:
		return "No se pudo resolver Mob Hit Profile."


	# 150 / (150 + 50) = 0.75

	var expected_hit_chance := 0.75


	if not is_equal_approx(
		ServerHitResolutionRules
		.calculate_hit_chance(
			attacker_profile.accuracy_rating,
			defender_profile.evasion_rating
		),
		expected_hit_chance
	):
		return "Hit Chance debe resolver 0.75."


	# -----------------------------------------------------
	# MISS
	# -----------------------------------------------------

	var miss_result := (
		ServerHitResolutionRules.resolve(
			attacker_profile,
			defender_profile,
			0.80,
			0.90,
			0.90
		)
	)


	if (
		miss_result == null
		or
		miss_result.outcome
		!=
		ServerHitResolutionResult.OUTCOME_MISS
	):
		return "Hit Roll 0.80 debe producir Miss."


	if miss_result.deals_damage():
		return "Miss no debe producir Damage."


	# -----------------------------------------------------
	# DODGE
	# -----------------------------------------------------

	var dodge_result := (
		ServerHitResolutionRules.resolve(
			attacker_profile,
			defender_profile,
			0.50,
			0.10,
			0.90
		)
	)


	if (
		dodge_result == null
		or
		dodge_result.outcome
		!=
		ServerHitResolutionResult.OUTCOME_DODGE
	):
		return "Dodge Roll 0.10 debe producir Dodge."


	if dodge_result.deals_damage():
		return "Dodge no debe producir Damage."


	# -----------------------------------------------------
	# BLOCK
	# -----------------------------------------------------

	var block_result := (
		ServerHitResolutionRules.resolve(
			attacker_profile,
			defender_profile,
			0.50,
			0.30,
			0.10
		)
	)


	if (
		block_result == null
		or
		block_result.outcome
		!=
		ServerHitResolutionResult.OUTCOME_BLOCK
	):
		return "Block Roll 0.10 debe producir Block."


	if not block_result.deals_damage():
		return "Block debe conservar Damage parcial."


	if not is_equal_approx(
		block_result.damage_multiplier,
		0.50
	):
		return "Block foundation debe usar multiplier 0.50."


	# -----------------------------------------------------
	# HIT
	# -----------------------------------------------------

	var hit_result := (
		ServerHitResolutionRules.resolve(
			attacker_profile,
			defender_profile,
			0.50,
			0.30,
			0.90
		)
	)


	if (
		hit_result == null
		or
		hit_result.outcome
		!=
		ServerHitResolutionResult.OUTCOME_HIT
	):
		return "Caso limpio debe producir Hit."


	# -----------------------------------------------------
	# BLOCK → DAMAGE PIPELINE
	#
	# Raw 100
	# Block 50 %
	# → 50
	#
	# Armor 100
	# → floor(50 * 1000 / 1100)
	# → 45
	# -----------------------------------------------------

	var damage_context := (
		ServerDamageResolutionContext.new(
			100,
			ServerDamageTaxonomy.SCHOOL_PHYSICAL,
			ServerDamageTaxonomy.ELEMENT_NONE,
			ServerDamageTaxonomy.DELIVERY_DIRECT,
			true,
			ServerDamageResolutionContext
				.SOURCE_BASIC_ATTACK,
			"block_test"
		)
	)


	var damage_defense := (
		ServerDamageDefenseProfile.new(
			100
		)
	)


	var blocked_damage := (
		ServerDamageResolver.resolve(
			damage_context,
			damage_defense,
			0.0,
			1.5,
			0.50,
			block_result.damage_multiplier
		)
	)


	if blocked_damage == null:
		return "No se pudo resolver Block Damage."


	if blocked_damage.post_outcome_damage != 50:
		return "Block debe resolver Raw 100 → 50."


	if blocked_damage.final_damage != 45:
		return (
			"Block 50 + Armor 100 "
			+
			"debe resolver Final Damage 45."
		)


	return ""
