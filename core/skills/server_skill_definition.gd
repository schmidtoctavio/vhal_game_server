class_name ServerSkillDefinition
extends RefCounted


# =========================================================
# TARGETS SOPORTADOS
# =========================================================

const TARGET_SELF: String = "self"

const TARGET_ENTITY: String = "entity"

const TARGET_POSITION: String = "position"


# =========================================================
# IDENTIDAD
# =========================================================

var skill_id: String = ""


# =========================================================
# TARGETING
# =========================================================

var target_kind: String = TARGET_SELF

var cast_range: float = 0.0

var area_radius: float = 0.0


# =========================================================
# COSTOS
# =========================================================

var mana_cost: int = 0


# =========================================================
# COOLDOWN
# =========================================================

var cooldown_duration: float = 0.0


# =========================================================
# SCALING
# =========================================================

var scaling_profile: ServerSkillScalingProfile = null


# =========================================================
# DAMAGE
# =========================================================

var damage_profile: ServerSkillDamageProfile = null

var status_effect_profile: ServerSkillStatusEffectProfile = null


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_skill_id: String = "",
	p_mana_cost: int = 0,
	p_cooldown_duration: float = 0.0,
	p_target_kind: String = TARGET_SELF,
	p_scaling_profile: ServerSkillScalingProfile = null,
	p_damage_profile: ServerSkillDamageProfile = null,
	p_cast_range: float = 0.0,
	p_status_effect_profile: ServerSkillStatusEffectProfile = null,
	p_area_radius: float = 0.0
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


	scaling_profile = (
		p_scaling_profile
	)


	damage_profile = (
		p_damage_profile
	)


	cast_range = (
		p_cast_range
	)


	status_effect_profile = (
		p_status_effect_profile
	)


	area_radius = (
		p_area_radius
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
			or
			target_kind == TARGET_POSITION
		)

		and
		(
			scaling_profile == null
			or
			scaling_profile.is_valid()
		)

		and
		(
			damage_profile == null
			or
			damage_profile.is_valid()
		)

		and
		cast_range >= 0.0

		and
		area_radius >= 0.0

		and
		(
			status_effect_profile == null
			or
			status_effect_profile.is_valid()
		)
	)
