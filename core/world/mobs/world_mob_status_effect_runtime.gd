class_name WorldMobStatusEffectRuntime
extends RefCounted


var effect_id: String = ""

var damage_type: String = ""

var damage_per_tick: int = 0

var tick_interval_msec: int = 0

var ticks_remaining: int = 0

var next_tick_at_msec: int = 0

var source: Dictionary = {}


static func create(
	profile: ServerSkillStatusEffectProfile,
	p_damage_per_tick: int,
	p_source: Dictionary,
	now_msec: int
) -> WorldMobStatusEffectRuntime:
	if profile == null:
		return null

	if not profile.is_valid():
		return null

	if p_damage_per_tick <= 0:
		return null

	if now_msec < 0:
		return null

	var state := (
		WorldMobStatusEffectRuntime.new()
	)

	state.effect_id = profile.effect_id

	state.damage_type = profile.damage_type

	state.damage_per_tick = p_damage_per_tick

	state.tick_interval_msec = maxi(
		ceili(
			profile.tick_interval_seconds
			*
			1000.0
		),
		1
	)

	state.ticks_remaining = profile.tick_count

	state.next_tick_at_msec = (
		now_msec
		+
		state.tick_interval_msec
	)

	state.source = p_source.duplicate(
		true
	)

	if not state.is_valid():
		return null

	return state


func is_valid() -> bool:
	return (
		not effect_id.is_empty()
		and
		not damage_type.is_empty()
		and
		damage_per_tick > 0
		and
		tick_interval_msec > 0
		and
		ticks_remaining > 0
		and
		next_tick_at_msec > 0
	)


func is_due(
	now_msec: int
) -> bool:
	return (
		not is_finished()
		and
		now_msec >= next_tick_at_msec
	)


func consume_due_tick(
	now_msec: int
) -> bool:
	if not is_due(
		now_msec
	):
		return false

	ticks_remaining -= 1

	next_tick_at_msec += (
		tick_interval_msec
	)

	return true


func is_finished() -> bool:
	return (
		ticks_remaining <= 0
	)
