class_name WorldMobDefinition
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var mob_type_id: String = ""

var display_name: String = ""


# =========================================================
# PROGRESIÓN / COMBATE BASE
# =========================================================

var level: int = 1

var max_hp: int = 1

var base_armor_rating: int = 0

var base_magic_resistance_rating: int = 0

var base_fire_resistance_rating: int = 0

var base_cold_resistance_rating: int = 0

var base_lightning_resistance_rating: int = 0

var base_poison_resistance_rating: int = 0

var base_accuracy_rating: int = 100

var base_evasion_rating: int = 0

var base_dodge_chance: float = 0.0

var base_block_chance: float = 0.0

# =========================================================
# PvE COMBAT LOOP
# =========================================================

var aggro_radius: float = 0.0

var leash_radius: float = 0.0

var combat_movement_speed: float = 0.0

var attack_range: float = 0.0

var attack_cooldown_seconds: float = 0.0

var base_attack_damage: int = 0

var experience_reward: int = 0

var respawn_delay_seconds: float = 5.0


# =========================================================
# CREAR
# =========================================================

static func create(
	new_mob_type_id: String,
	new_display_name: String,
	new_level: int,
	new_max_hp: int,
	new_experience_reward: int,
	new_respawn_delay_seconds: float = 5.0,
	new_base_armor_rating: int = 0,
	new_base_magic_resistance_rating: int = 0,
	new_base_fire_resistance_rating: int = 0,
	new_base_cold_resistance_rating: int = 0,
	new_base_lightning_resistance_rating: int = 0,
	new_base_poison_resistance_rating: int = 0,
	new_base_accuracy_rating: int = 100,
	new_base_evasion_rating: int = 0,
	new_base_dodge_chance: float = 0.0,
	new_base_block_chance: float = 0.0,
	new_aggro_radius: float = 0.0,
	new_leash_radius: float = 0.0,
	new_combat_movement_speed: float = 0.0,
	new_attack_range: float = 0.0,
	new_attack_cooldown_seconds: float = 0.0,
	new_base_attack_damage: int = 0
) -> WorldMobDefinition:
	var definition := WorldMobDefinition.new()


	definition.mob_type_id = (
		new_mob_type_id
		.strip_edges()
		.to_lower()
	)


	definition.display_name = (
		new_display_name
		.strip_edges()
	)


	definition.level = new_level

	definition.max_hp = new_max_hp

	definition.base_armor_rating = (
		new_base_armor_rating
	)

	definition.base_magic_resistance_rating = (
		new_base_magic_resistance_rating
	)

	definition.base_fire_resistance_rating = (
		new_base_fire_resistance_rating
	)

	definition.base_cold_resistance_rating = (
		new_base_cold_resistance_rating
	)

	definition.base_lightning_resistance_rating = (
		new_base_lightning_resistance_rating
	)

	definition.base_poison_resistance_rating = (
		new_base_poison_resistance_rating
	)

	definition.base_accuracy_rating = (
		new_base_accuracy_rating
	)

	definition.base_evasion_rating = (
		new_base_evasion_rating
	)

	definition.base_dodge_chance = (
		new_base_dodge_chance
	)

	definition.base_block_chance = (
		new_base_block_chance
	)

	definition.aggro_radius = (
		new_aggro_radius
	)

	definition.leash_radius = (
		new_leash_radius
	)

	definition.combat_movement_speed = (
		new_combat_movement_speed
	)

	definition.attack_range = (
		new_attack_range
	)

	definition.attack_cooldown_seconds = (
		new_attack_cooldown_seconds
	)

	definition.base_attack_damage = (
		new_base_attack_damage
	)

	definition.experience_reward = (
		new_experience_reward
	)

	definition.respawn_delay_seconds = (
		new_respawn_delay_seconds
	)


	return definition


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if mob_type_id.is_empty():
		return false


	if display_name.is_empty():
		return false


	if level <= 0:
		return false


	if max_hp <= 0:
		return false


	if base_armor_rating < 0:
		return false


	if base_magic_resistance_rating < 0:
		return false


	if base_fire_resistance_rating < 0:
		return false


	if base_cold_resistance_rating < 0:
		return false


	if base_lightning_resistance_rating < 0:
		return false


	if base_poison_resistance_rating < 0:
		return false

	if base_accuracy_rating <= 0:
		return false


	if base_evasion_rating < 0:
		return false


	if (
		base_dodge_chance < 0.0
		or
		base_dodge_chance > 1.0
	):
		return false


	if (
		base_block_chance < 0.0
		or
		base_block_chance > 1.0
	):
		return false

	if aggro_radius < 0.0:
		return false


	if leash_radius < 0.0:
		return false


	if combat_movement_speed < 0.0:
		return false


	if attack_range < 0.0:
		return false


	if attack_cooldown_seconds < 0.0:
		return false


	if base_attack_damage < 0:
		return false


	var has_any_pve_combat_value := (
		aggro_radius > 0.0

		or
		leash_radius > 0.0

		or
		combat_movement_speed > 0.0

		or
		attack_range > 0.0

		or
		attack_cooldown_seconds > 0.0

		or
		base_attack_damage > 0
	)


	if (
		has_any_pve_combat_value
		and
		not has_pve_combat_profile()
	):
		return false

	if respawn_delay_seconds <= 0.0:
		return false


	if experience_reward < 0:
		return false


	return true


# =========================================================
# PvE COMBAT PROFILE
# =========================================================

func has_pve_combat_profile() -> bool:
	return (
		aggro_radius > 0.0

		and

		leash_radius >= aggro_radius

		and

		combat_movement_speed > 0.0

		and

		attack_range > 0.0

		and

		attack_range <= aggro_radius

		and

		attack_cooldown_seconds > 0.0

		and

		base_attack_damage > 0
	)
