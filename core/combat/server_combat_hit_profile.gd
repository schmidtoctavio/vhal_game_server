class_name ServerCombatHitProfile
extends RefCounted


var accuracy_rating: int = 100

var evasion_rating: int = 0

var dodge_chance: float = 0.0

var block_chance: float = 0.0


func _init(
	p_accuracy_rating: int = 100,
	p_evasion_rating: int = 0,
	p_dodge_chance: float = 0.0,
	p_block_chance: float = 0.0
) -> void:
	accuracy_rating = p_accuracy_rating

	evasion_rating = p_evasion_rating

	dodge_chance = p_dodge_chance

	block_chance = p_block_chance


func is_valid() -> bool:
	return (
		accuracy_rating > 0

		and

		evasion_rating >= 0

		and

		dodge_chance >= 0.0

		and

		dodge_chance <= 1.0

		and

		block_chance >= 0.0

		and

		block_chance <= 1.0
	)


func to_snapshot() -> Dictionary:
	if not is_valid():
		return {}


	return {
		"accuracy_rating": accuracy_rating,

		"evasion_rating": evasion_rating,

		"dodge_chance": dodge_chance,

		"block_chance": block_chance,
	}
