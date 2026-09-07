class_name ServerHitResolutionRules
extends RefCounted


# Evitamos foundations que puedan llegar a evasión
# absoluta mediante un único secondary stat.

const MAX_DODGE_CHANCE: float = 0.75

const MAX_BLOCK_CHANCE: float = 0.75


# Block foundation:
#
# el ataque conecta pero conserva 50 % del daño
# antes de Critical + Mitigation.

const BLOCK_DAMAGE_MULTIPLIER: float = 0.50


static func calculate_hit_chance(
	accuracy_rating: int,
	evasion_rating: int
) -> float:
	if accuracy_rating <= 0:
		return -1.0


	if evasion_rating < 0:
		return -1.0


	if evasion_rating == 0:
		return 1.0


	return clampf(
		float(accuracy_rating)
		/
		float(
			accuracy_rating
			+
			evasion_rating
		),
		0.0,
		1.0
	)


static func resolve(
	attacker_profile: ServerCombatHitProfile,
	defender_profile: ServerCombatHitProfile,
	hit_roll: float,
	dodge_roll: float,
	block_roll: float
) -> ServerHitResolutionResult:
	if (
		attacker_profile == null
		or
		defender_profile == null
	):
		return null


	if (
		not attacker_profile.is_valid()
		or
		not defender_profile.is_valid()
	):
		return null


	if (
		hit_roll < 0.0
		or
		hit_roll > 1.0
		or
		dodge_roll < 0.0
		or
		dodge_roll > 1.0
		or
		block_roll < 0.0
		or
		block_roll > 1.0
	):
		return null


	var hit_chance := (
		calculate_hit_chance(
			attacker_profile.accuracy_rating,
			defender_profile.evasion_rating
		)
	)


	if hit_chance < 0.0:
		return null


	var effective_dodge_chance := minf(
		defender_profile.dodge_chance,
		MAX_DODGE_CHANCE
	)


	var effective_block_chance := minf(
		defender_profile.block_chance,
		MAX_BLOCK_CHANCE
	)


	var outcome := (
		ServerHitResolutionResult.OUTCOME_HIT
	)


	var damage_multiplier := 1.0


	if hit_roll >= hit_chance:
		outcome = (
			ServerHitResolutionResult.OUTCOME_MISS
		)

		damage_multiplier = 0.0


	elif dodge_roll < effective_dodge_chance:
		outcome = (
			ServerHitResolutionResult.OUTCOME_DODGE
		)

		damage_multiplier = 0.0


	elif block_roll < effective_block_chance:
		outcome = (
			ServerHitResolutionResult.OUTCOME_BLOCK
		)

		damage_multiplier = (
			BLOCK_DAMAGE_MULTIPLIER
		)


	var result := (
		ServerHitResolutionResult.new(
			outcome,
			hit_chance,
			hit_roll,
			effective_dodge_chance,
			dodge_roll,
			effective_block_chance,
			block_roll,
			damage_multiplier
		)
	)


	if not result.is_valid():
		return null


	return result
