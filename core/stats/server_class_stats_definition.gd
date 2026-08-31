class_name ServerClassStatsDefinition
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var class_id: String = ""


# =========================================================
# PRIMARY STATS BASE
# =========================================================

var starting_strength: int = 0

var starting_agility: int = 0

var starting_vitality: int = 0

var starting_energy: int = 0


# =========================================================
# PROGRESIÓN
# =========================================================

var stat_points_per_level: int = 0

# =========================================================
# DERIVED VITALS — BALANCE DE CLASE
# =========================================================

var base_max_hp: int = 0

var hp_per_level: int = 0

var hp_per_vitality: int = 0


var base_max_mp: int = 0

var mp_per_level: int = 0

var mp_per_energy: int = 0

# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_class_id: String = "",
	p_starting_strength: int = 0,
	p_starting_agility: int = 0,
	p_starting_vitality: int = 0,
	p_starting_energy: int = 0,
	p_stat_points_per_level: int = 0,
	p_base_max_hp: int = 0,
	p_hp_per_level: int = 0,
	p_hp_per_vitality: int = 0,
	p_base_max_mp: int = 0,
	p_mp_per_level: int = 0,
	p_mp_per_energy: int = 0
) -> void:
	class_id = (
		p_class_id
		.strip_edges()
		.to_lower()
	)


	starting_strength = (
		p_starting_strength
	)


	starting_agility = (
		p_starting_agility
	)


	starting_vitality = (
		p_starting_vitality
	)


	starting_energy = (
		p_starting_energy
	)


	stat_points_per_level = (
		p_stat_points_per_level
	)

	base_max_hp = (
		p_base_max_hp
	)

	hp_per_level = (
		p_hp_per_level
	)

	hp_per_vitality = (
		p_hp_per_vitality
	)


	base_max_mp = (
		p_base_max_mp
	)

	mp_per_level = (
		p_mp_per_level
	)

	mp_per_energy = (
		p_mp_per_energy
	)

# =========================================================
# TOTAL DE STATS BASE
# =========================================================

func get_starting_stat_total() -> int:
	return (
		starting_strength
		+
		starting_agility
		+
		starting_vitality
		+
		starting_energy
	)


# =========================================================
# VALIDACIÓN GENERAL
# =========================================================

func is_valid() -> bool:
	return (
		not class_id.is_empty()

		and
		starting_strength >= 0

		and
		starting_agility >= 0

		and
		starting_vitality >= 0

		and
		starting_energy >= 0

		and
		stat_points_per_level > 0

		and
		base_max_hp > 0

		and
		hp_per_level >= 0

		and
		hp_per_vitality > 0

		and
		base_max_mp >= 0

		and
		mp_per_level >= 0

		and
		mp_per_energy > 0
	)
