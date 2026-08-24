class_name ServerSkillDefinition
extends RefCounted


# =========================================================
# TARGETS SOPORTADOS
# =========================================================

const TARGET_SELF: String = "self"

const TARGET_ENTITY: String = "entity"


# =========================================================
# IDENTIDAD
# =========================================================

var skill_id: String = ""


# =========================================================
# TARGETING
# =========================================================

var target_kind: String = TARGET_SELF


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
	p_cooldown_duration: float = 0.0,
	p_target_kind: String = TARGET_SELF
) -> void:
	skill_id = (
		p_skill_id
		.strip_edges()
		.to_lower()
	)


	mana_cost = p_mana_cost


	cooldown_duration = (
		p_cooldown_duration
	)


	target_kind = (
		p_target_kind
		.strip_edges()
		.to_lower()
	)


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

		and
		(
			target_kind == TARGET_SELF
			or
			target_kind == TARGET_ENTITY
		)
	)
