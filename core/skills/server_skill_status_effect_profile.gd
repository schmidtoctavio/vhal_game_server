class_name ServerSkillStatusEffectProfile
extends RefCounted


const REFRESH_REPLACE: String = "replace"


var effect_id: String = ""

var damage_profile: ServerSkillDamageProfile = null

var tick_interval_seconds: float = 0.0

var tick_count: int = 0

var refresh_policy: String = ""


# =========================================================
# LEGACY DAMAGE TYPE
#
# WorldMobStatusEffectRuntime y los payloads actuales
# todavía consumen este shorthand.
# =========================================================

var damage_type: String:
	get:
		if damage_profile == null:
			return ""


		return damage_profile.damage_type


func _init(
	p_effect_id: String = "",
	p_damage_profile: ServerSkillDamageProfile = null,
	p_tick_interval_seconds: float = 0.0,
	p_tick_count: int = 0,
	p_refresh_policy: String = REFRESH_REPLACE
) -> void:
	effect_id = (
		p_effect_id
		.strip_edges()
		.to_lower()
	)


	damage_profile = (
		p_damage_profile
	)


	tick_interval_seconds = (
		p_tick_interval_seconds
	)


	tick_count = (
		p_tick_count
	)


	refresh_policy = (
		p_refresh_policy
		.strip_edges()
		.to_lower()
	)


func get_duration_seconds() -> float:
	return (
		tick_interval_seconds
		*
		float(tick_count)
	)


func is_valid() -> bool:
	return (
		not effect_id.is_empty()

		and

		damage_profile != null

		and

		damage_profile.is_valid()

		and

		damage_profile.delivery
		==
		ServerDamageTaxonomy.DELIVERY_PERIODIC

		and

		tick_interval_seconds > 0.0

		and

		tick_count > 0

		and

		refresh_policy
		==
		REFRESH_REPLACE
	)
