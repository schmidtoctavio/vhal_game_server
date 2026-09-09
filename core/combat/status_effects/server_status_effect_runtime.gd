class_name ServerStatusEffectRuntime
extends RefCounted


# =========================================================
# IDENTIDAD
# =========================================================

var runtime_key: String = ""

var effect_id: String = ""

var category: String = ""


# =========================================================
# POLICIES
# =========================================================

var stacking_policy: String = ""

var refresh_policy: String = ""

var max_stacks: int = 1

var stack_count: int = 1


# =========================================================
# DAMAGE
# =========================================================

var damage_context: ServerDamageResolutionContext = null


# =========================================================
# PERIODIC
# =========================================================

var tick_interval_msec: int = 0

var ticks_remaining: int = 0

var next_tick_at_msec: int = 0


# =========================================================
# DURACIÓN
# =========================================================

var applied_at_msec: int = 0

var expires_at_msec: int = 0

var continuous_cap_at_msec: int = 0


# =========================================================
# SOURCE
# =========================================================

var source_identity: String = ""

var source: Dictionary = {}


# =========================================================
# MODIFIERS
# =========================================================

var movement_speed_multiplier: float = 1.0

var attack_speed_multiplier: float = 1.0


# =========================================================
# CONTROL
# =========================================================

var blocks_movement: bool = false

var blocks_actions: bool = false

var blocks_skills: bool = false


# =========================================================
# CREATE
# =========================================================

static func create(
	profile: ServerStatusEffectProfile,
	p_damage_context: ServerDamageResolutionContext,
	p_source: Dictionary,
	now_msec: int
) -> ServerStatusEffectRuntime:
	if profile == null:
		return null


	if not profile.is_valid():
		return null


	if now_msec < 0:
		return null


	if p_source.is_empty():
		return null


	# -----------------------------------------------------
	# PERIODIC DAMAGE
	# -----------------------------------------------------

	if profile.is_periodic_damage():
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

	else:
		if p_damage_context != null:
			return null


	var state := (
		ServerStatusEffectRuntime.new()
	)


	state.effect_id = (
		profile.effect_id
	)


	state.category = (
		profile.category
	)


	state.stacking_policy = (
		profile.stacking_policy
	)


	state.refresh_policy = (
		profile.refresh_policy
	)


	state.max_stacks = (
		profile.max_stacks
	)


	state.stack_count = 1


	state.source = (
		p_source.duplicate(
			true
		)
	)


	state.source_identity = (
		_resolve_source_identity(
			state.source
		)
	)


	if state.source_identity.is_empty():
		return null


	if (
		state.stacking_policy
		==
		ServerStatusEffectProfile
		.STACK_INDEPENDENT_SOURCES
	):
		state.runtime_key = (
			state.effect_id
			+
			"::"
			+
			state.source_identity
		)

	else:
		state.runtime_key = (
			state.effect_id
		)


	state.movement_speed_multiplier = (
		profile.movement_speed_multiplier
	)


	state.attack_speed_multiplier = (
		profile.attack_speed_multiplier
	)


	state.blocks_movement = (
		profile.blocks_movement
	)


	state.blocks_actions = (
		profile.blocks_actions
	)


	state.blocks_skills = (
		profile.blocks_skills
	)


	state.applied_at_msec = (
		now_msec
	)


	var duration_msec := maxi(
		ceili(
			profile.duration_seconds
			*
			1000.0
		),
		1
	)


	state.expires_at_msec = (
		now_msec
		+
		duration_msec
	)


	if profile.is_hard_control():
		state.continuous_cap_at_msec = (
			now_msec
			+
			maxi(
				ceili(
					ServerStatusEffectProfile
					.MAX_HARD_CONTROL_DURATION_SECONDS
					*
					1000.0
				),
				1
			)
		)


		state.expires_at_msec = mini(
			state.expires_at_msec,
			state.continuous_cap_at_msec
		)


	if profile.is_periodic_damage():
		state.damage_context = (
			_clone_damage_context(
				p_damage_context
			)
		)


		if state.damage_context == null:
			return null


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


	if not state.is_valid():
		return null


	return state


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if runtime_key.is_empty():
		return false


	if effect_id.is_empty():
		return false


	if source_identity.is_empty():
		return false


	if source.is_empty():
		return false


	if stack_count <= 0:
		return false


	if stack_count > max_stacks:
		return false


	if applied_at_msec < 0:
		return false


	if expires_at_msec <= applied_at_msec:
		return false


	if is_hard_control():
		if continuous_cap_at_msec <= applied_at_msec:
			return false


		if expires_at_msec > continuous_cap_at_msec:
			return false


	if is_periodic_damage():
		return (
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
			tick_interval_msec > 0
			and
			ticks_remaining >= 0
			and
			next_tick_at_msec > 0
		)


	return (
		damage_context == null
		and
		tick_interval_msec == 0
		and
		ticks_remaining == 0
		and
		next_tick_at_msec == 0
	)


# =========================================================
# TYPE
# =========================================================

func is_periodic_damage() -> bool:
	return (
		category
		==
		ServerStatusEffectProfile.CATEGORY_DOT
	)


func is_hard_control() -> bool:
	return (
		category
		==
		ServerStatusEffectProfile
		.CATEGORY_HARD_CONTROL
	)


# =========================================================
# DEADLINES
# =========================================================

func is_expired(
	now_msec: int
) -> bool:
	return (
		now_msec >= expires_at_msec
	)


func is_periodic_finished() -> bool:
	return (
		is_periodic_damage()
		and
		ticks_remaining <= 0
	)


func get_next_deadline_msec() -> int:
	var deadline := (
		expires_at_msec
	)


	if (
		is_periodic_damage()
		and
		ticks_remaining > 0
		and
		next_tick_at_msec > 0
	):
		deadline = mini(
			deadline,
			next_tick_at_msec
		)


	return deadline


# =========================================================
# PERIODIC TICK
# =========================================================

func is_due(
	now_msec: int
) -> bool:
	return (
		is_periodic_damage()
		and
		ticks_remaining > 0
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


# =========================================================
# STACK
# =========================================================

func add_stack() -> bool:
	if (
		stacking_policy
		!=
		ServerStatusEffectProfile.STACK_LIMITED
	):
		return false


	if stack_count >= max_stacks:
		return false


	stack_count += 1


	return true


# =========================================================
# REFRESH
# =========================================================

func refresh_from(
	incoming: ServerStatusEffectRuntime
) -> bool:
	if incoming == null:
		return false


	if not incoming.is_valid():
		return false


	if incoming.runtime_key != runtime_key:
		return false


	if incoming.effect_id != effect_id:
		return false


	if incoming.category != category:
		return false


	if (
		incoming.stacking_policy
		!=
		stacking_policy
	):
		return false


	if (
		incoming.refresh_policy
		!=
		refresh_policy
	):
		return false


	if incoming.max_stacks != max_stacks:
		return false


	if not is_equal_approx(
		incoming.movement_speed_multiplier,
		movement_speed_multiplier
	):
		return false


	if not is_equal_approx(
		incoming.attack_speed_multiplier,
		attack_speed_multiplier
	):
		return false


	if (
		incoming.blocks_movement
		!=
		blocks_movement
		or
		incoming.blocks_actions
		!=
		blocks_actions
		or
		incoming.blocks_skills
		!=
		blocks_skills
	):
		return false


	source_identity = (
		incoming.source_identity
	)


	source = (
		incoming.source.duplicate(
			true
		)
	)


	if incoming.is_periodic_damage():
		damage_context = (
			_clone_damage_context(
				incoming.damage_context
			)
		)


		if damage_context == null:
			return false


		tick_interval_msec = (
			incoming.tick_interval_msec
		)


		ticks_remaining = (
			incoming.ticks_remaining
		)


		next_tick_at_msec = (
			incoming.next_tick_at_msec
		)


	# -----------------------------------------------------
	# HARD CONTROL
	#
	# Conserva el comienzo de la cadena.
	# Nunca puede extenderse por encima del cap continuo.
	# -----------------------------------------------------

	if is_hard_control():
		expires_at_msec = mini(
			incoming.expires_at_msec,
			continuous_cap_at_msec
		)

	else:
		applied_at_msec = (
			incoming.applied_at_msec
		)


		expires_at_msec = (
			incoming.expires_at_msec
		)


	return is_valid()


# =========================================================
# EFFECTIVE MODIFIERS
# =========================================================

func get_effective_movement_speed_multiplier() -> float:
	return pow(
		movement_speed_multiplier,
		float(stack_count)
	)


func get_effective_attack_speed_multiplier() -> float:
	return pow(
		attack_speed_multiplier,
		float(stack_count)
	)


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot(
	now_msec: int
) -> Dictionary:
	if not is_valid():
		return {}


	var remaining_msec := maxi(
		expires_at_msec
		-
		now_msec,
		0
	)


	return {
		"runtime_key": runtime_key,

		"effect_id": effect_id,

		"category": category,

		"stacks": stack_count,

		"max_stacks": max_stacks,

		"remaining_duration_seconds": (
			float(remaining_msec)
			/
			1000.0
		),

		"source": source.duplicate(
			true
		),

		"modifiers": {
			"movement_speed_multiplier": (
				get_effective_movement_speed_multiplier()
			),

			"attack_speed_multiplier": (
				get_effective_attack_speed_multiplier()
			),
		},

		"control": {
			"blocks_movement": blocks_movement,

			"blocks_actions": blocks_actions,

			"blocks_skills": blocks_skills,
		},

		"periodic": {
			"enabled": is_periodic_damage(),

			"ticks_remaining": ticks_remaining,

			"tick_interval_seconds": (
				float(tick_interval_msec)
				/
				1000.0
			),
		},
	}


# =========================================================
# SOURCE IDENTITY
# =========================================================

static func _resolve_source_identity(
	p_source: Dictionary
) -> String:
	var character_id := int(
		p_source.get(
			"character_id",
			0
		)
	)


	if character_id > 0:
		return (
			"character:%d"
			%
			character_id
		)


	var peer_id := int(
		p_source.get(
			"peer_id",
			0
		)
	)


	if peer_id > 1:
		return (
			"peer:%d"
			%
			peer_id
		)


	var source_kind := String(
		p_source.get(
			"kind",
			""
		)
	).strip_edges().to_lower()


	if not source_kind.is_empty():
		return (
			"kind:"
			+
			source_kind
		)


	return ""


# =========================================================
# CLONE DAMAGE CONTEXT
# =========================================================

static func _clone_damage_context(
	context: ServerDamageResolutionContext
) -> ServerDamageResolutionContext:
	if context == null:
		return null


	if not context.is_valid():
		return null


	return ServerDamageResolutionContext.new(
		context.raw_damage,
		context.school,
		context.element,
		context.delivery,
		context.can_critical,
		context.source_kind,
		context.source_id
	)
