class_name ServerHitResolutionResult
extends RefCounted


const OUTCOME_HIT: String = "hit"

const OUTCOME_MISS: String = "miss"

const OUTCOME_DODGE: String = "dodge"

const OUTCOME_BLOCK: String = "block"


var outcome: String = ""

var hit_chance: float = 0.0

var hit_roll: float = 0.0

var dodge_chance: float = 0.0

var dodge_roll: float = 0.0

var block_chance: float = 0.0

var block_roll: float = 0.0

var damage_multiplier: float = 0.0


func _init(
	p_outcome: String = "",
	p_hit_chance: float = 0.0,
	p_hit_roll: float = 0.0,
	p_dodge_chance: float = 0.0,
	p_dodge_roll: float = 0.0,
	p_block_chance: float = 0.0,
	p_block_roll: float = 0.0,
	p_damage_multiplier: float = 0.0
) -> void:
	outcome = (
		p_outcome
		.strip_edges()
		.to_lower()
	)


	hit_chance = p_hit_chance

	hit_roll = p_hit_roll

	dodge_chance = p_dodge_chance

	dodge_roll = p_dodge_roll

	block_chance = p_block_chance

	block_roll = p_block_roll

	damage_multiplier = p_damage_multiplier


func is_valid() -> bool:
	if (
		outcome != OUTCOME_HIT
		and
		outcome != OUTCOME_MISS
		and
		outcome != OUTCOME_DODGE
		and
		outcome != OUTCOME_BLOCK
	):
		return false


	if (
		hit_chance < 0.0
		or
		hit_chance > 1.0
		or
		hit_roll < 0.0
		or
		hit_roll > 1.0
		or
		dodge_chance < 0.0
		or
		dodge_chance > 1.0
		or
		dodge_roll < 0.0
		or
		dodge_roll > 1.0
		or
		block_chance < 0.0
		or
		block_chance > 1.0
		or
		block_roll < 0.0
		or
		block_roll > 1.0
		or
		damage_multiplier < 0.0
		or
		damage_multiplier > 1.0
	):
		return false


	if (
		outcome == OUTCOME_MISS
		or
		outcome == OUTCOME_DODGE
	):
		return is_zero_approx(
			damage_multiplier
		)


	if outcome == OUTCOME_BLOCK:
		return (
			damage_multiplier > 0.0
			and
			damage_multiplier < 1.0
		)


	if outcome == OUTCOME_HIT:
		return is_equal_approx(
			damage_multiplier,
			1.0
		)


	return false


func deals_damage() -> bool:
	return (
		outcome == OUTCOME_HIT
		or
		outcome == OUTCOME_BLOCK
	)


func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"outcome": outcome,

		"hit": {
			"chance": hit_chance,
			"roll": hit_roll,
		},

		"dodge": {
			"chance": dodge_chance,
			"roll": dodge_roll,
		},

		"block": {
			"chance": block_chance,
			"roll": block_roll,
		},

		"damage_multiplier": (
			damage_multiplier
		),
	}
