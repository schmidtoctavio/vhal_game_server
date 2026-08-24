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


# =========================================================
# CREAR
# =========================================================

static func create(
	new_mob_type_id: String,
	new_display_name: String,
	new_level: int,
	new_max_hp: int
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


	return true
