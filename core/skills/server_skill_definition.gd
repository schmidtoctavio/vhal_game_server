class_name ServerSkillDefinition
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var skill_id: String = ""


# =========================================================
# COSTOS
# =========================================================

var mana_cost: int = 0


# =========================================================
# COOLDOWN
# =========================================================

var cooldown_duration: float = 0.0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_skill_id: String = "",
	p_mana_cost: int = 0,
	p_cooldown_duration: float = 0.0
) -> void:
	skill_id = (
		p_skill_id
		.strip_edges()
		.to_lower()
	)

	mana_cost = p_mana_cost

	cooldown_duration = p_cooldown_duration


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		not skill_id.is_empty()
		and
		mana_cost >= 0
		and
		cooldown_duration >= 0.0
	)
