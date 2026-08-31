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
	new_base_armor_rating: int = 0
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

	if respawn_delay_seconds <= 0.0:
		return false

	if experience_reward < 0:
		return false

	return true
