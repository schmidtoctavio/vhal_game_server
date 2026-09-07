class_name WorldMobStatusEffectRuntime
extends RefCounted


var effect_id: String = ""


# =========================================================
# DAMAGE CONTEXT
# =========================================================

var damage_context: ServerDamageResolutionContext = null


# =========================================================
# LEGACY READ VIEW
#
# Se conserva temporalmente hasta F24-E.
#
# damage_per_tick
# =
# RAW damage por tick
# =========================================================

var damage_type: String = ""

var damage_per_tick: int = 0


# =========================================================
# SCHEDULER
# =========================================================

var tick_interval_msec: int = 0

var ticks_remaining: int = 0

var next_tick_at_msec: int = 0


# =========================================================
# SOURCE
# =========================================================

var source: Dictionary = {}


# =========================================================
# CREATE
# =========================================================

static func create(
	profile: ServerSkillStatusEffectProfile,
	p_damage_context: ServerDamageResolutionContext,
	p_source: Dictionary,
	now_msec: int
) -> WorldMobStatusEffectRuntime:
	if profile == null:
		return null


	if not profile.is_valid():
		return null


	if p_damage_context == null:
		return null


	if not p_damage_context.is_valid():
		return null


	if (
		p_damage_context.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_PERIODIC
	):
		return null


	if (
		p_damage_context.source_kind
		!=
		ServerDamageResolutionContext
			.SOURCE_STATUS_EFFECT
	):
		return null


	if (
		p_damage_context.source_id
		!=
		profile.effect_id
	):
		return null


	if profile.damage_profile == null:
		return null


	if (
		p_damage_context.school
		!=
		profile.damage_profile.school
	):
		return null


	if (
		p_damage_context.element
		!=
		profile.damage_profile.element
	):
		return null


	if now_msec < 0:
		return null


	var state := (
		WorldMobStatusEffectRuntime.new()
	)


	state.effect_id = profile.effect_id


	# -----------------------------------------------------
	# Copiamos el contexto para que el Status Runtime posea
	# su propio snapshot ofensivo.
	# -----------------------------------------------------

	state.damage_context = (
		ServerDamageResolutionContext.new(
			p_damage_context.raw_damage,
			p_damage_context.school,
			p_damage_context.element,
			p_damage_context.delivery,
			p_damage_context.can_critical,
			p_damage_context.source_kind,
			p_damage_context.source_id
		)
	)


	if (
		state.damage_context == null
		or
		not state.damage_context.is_valid()
	):
		return null


	# Legacy aliases temporales.

	state.damage_type = (
		profile.damage_type
	)


	state.damage_per_tick = (
		state.damage_context.raw_damage
	)


	state.tick_interval_msec = maxi(
		ceili(
			profile.tick_interval_seconds
			*
			1000.0
		),
		1
	)


	state.ticks_remaining = (
		profile.tick_count
	)


	state.next_tick_at_msec = (
		now_msec
		+
		state.tick_interval_msec
	)


	state.source = (
		p_source.duplicate(
			true
		)
	)


	if not state.is_valid():
		return null


	return state


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		not effect_id.is_empty()

		and

		damage_context != null

		and

		damage_context.is_valid()

		and

		damage_context.delivery
		==
		ServerDamageTaxonomy.DELIVERY_PERIODIC

		and

		damage_context.source_kind
		==
		ServerDamageResolutionContext
			.SOURCE_STATUS_EFFECT

		and

		damage_context.source_id
		==
		effect_id

		and

		damage_per_tick
		==
		damage_context.raw_damage

		and

		damage_per_tick > 0

		and

		tick_interval_msec > 0

		and

		ticks_remaining > 0

		and

		next_tick_at_msec > 0
	)


# =========================================================
# TICK
# =========================================================

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
