class_name ServerCharacterDerivedStatsState
extends RefCounted


# =========================================================
# SOURCE
#
# Derived Stats no poseen revision durable propia.
#
# Registramos desde qué estado autoritativo fueron
# construidos para poder detectar/reconstruir cuando:
#
# - cambia Primary Stats revision
# - cambia Level
# - cambia Reset
# =========================================================

var class_id: String = ""

var source_primary_stats_revision: int = 0

var level: int = 1

var reset_count: int = 0


# =========================================================
# VITALS DERIVADOS
# =========================================================

var max_hp: int = 1

var max_mp: int = 0

var hp_regeneration: int = 0

var mp_regeneration: int = 0


# =========================================================
# PODER DERIVADO
#
# Los coeficientes todavía NO pertenecen a este State.
#
# Este objeto almacena resultados autoritativos.
# Las fórmulas vivirán en Rules/Bootstrap.
# =========================================================

var physical_power: int = 0

var magic_power: int = 0

var healing_power: int = 0

# =========================================================
# CRITICAL DERIVADO
# =========================================================

var critical_strike_chance: float = 0.0

var critical_damage_multiplier: float = 1.5

# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_class_id: String,
	p_source_primary_stats_revision: int,
	p_level: int,
	p_reset_count: int,
	p_max_hp: int,
	p_max_mp: int,
	p_hp_regeneration: int,
	p_mp_regeneration: int,
	p_physical_power: int,
	p_magic_power: int,
	p_healing_power: int,
	p_critical_strike_chance: float,
	p_critical_damage_multiplier: float
) -> void:
	class_id = (
		p_class_id
		.strip_edges()
		.to_lower()
	)


	source_primary_stats_revision = (
		p_source_primary_stats_revision
	)

	level = p_level

	reset_count = p_reset_count


	max_hp = p_max_hp

	max_mp = p_max_mp

	hp_regeneration = p_hp_regeneration

	mp_regeneration = p_mp_regeneration


	physical_power = p_physical_power

	magic_power = p_magic_power

	healing_power = p_healing_power

	critical_strike_chance = (
		p_critical_strike_chance
	)

	critical_damage_multiplier = (
		p_critical_damage_multiplier
	)

# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if class_id.is_empty():
		return false


	if source_primary_stats_revision < 0:
		return false


	if level < 1:
		return false


	if reset_count < 0:
		return false


	if max_hp <= 0:
		return false


	if max_mp < 0:
		return false


	if hp_regeneration < 0:
		return false


	if mp_regeneration < 0:
		return false


	if physical_power < 0:
		return false


	if magic_power < 0:
		return false


	if healing_power < 0:
		return false

	if critical_strike_chance < 0.0:
		return false


	if critical_strike_chance > 1.0:
		return false


	if critical_damage_multiplier < 1.0:
		return false

	return true


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	return {
		"source": {
			"class_id": class_id,

			"primary_stats_revision": (
				source_primary_stats_revision
			),

			"level": level,

			"reset_count": reset_count,
		},

		"vitals": {
			"max_hp": max_hp,

			"max_mp": max_mp,

			"hp_regeneration": (
				hp_regeneration
			),

			"mp_regeneration": (
				mp_regeneration
			),
		},

		"power": {
			"physical": physical_power,

			"magic": magic_power,

			"healing": healing_power,
		},

		"critical": {
			"strike_chance": (
				critical_strike_chance
			),

			"damage_multiplier": (
				critical_damage_multiplier
			),
		},
	}
