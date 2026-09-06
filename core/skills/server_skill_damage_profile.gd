class_name ServerSkillDamageProfile
extends RefCounted


# =========================================================
# DAMAGE TYPES
# =========================================================

const DAMAGE_PHYSICAL: String = "physical"

const DAMAGE_MAGIC: String = "magic"

const DAMAGE_POISON: String = "poison"

# =========================================================
# DAMAGE TYPE
# =========================================================

var damage_type: String = ""


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_damage_type: String = ""
) -> void:
	damage_type = (
		p_damage_type
		.strip_edges()
		.to_lower()
	)


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		damage_type == DAMAGE_PHYSICAL
		or
		damage_type == DAMAGE_MAGIC
		or
		damage_type == DAMAGE_POISON
	)
