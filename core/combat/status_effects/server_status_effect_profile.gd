class_name ServerStatusEffectProfile
extends RefCounted


# =========================================================
# CATEGORÍAS
# =========================================================

const CATEGORY_BUFF: String = "buff"

const CATEGORY_DEBUFF: String = "debuff"

const CATEGORY_DOT: String = "dot"

const CATEGORY_SOFT_CONTROL: String = "soft_control"

const CATEGORY_HARD_CONTROL: String = "hard_control"


# =========================================================
# STACKING
# =========================================================

const STACK_SINGLE: String = "single"

const STACK_LIMITED: String = "limited"

const STACK_INDEPENDENT_SOURCES: String = (
	"independent_sources"
)


# =========================================================
# REFRESH
# =========================================================

const REFRESH_REPLACE: String = "replace"

const REFRESH_REFRESH: String = "refresh"


# =========================================================
# ANTI-PERMACONTROL
# =========================================================

const MAX_HARD_CONTROL_DURATION_SECONDS: float = 3.0

const HARD_CONTROL_IMMUNITY_SECONDS: float = 1.5

const MAX_SOFT_CONTROL_DURATION_SECONDS: float = 10.0


# =========================================================
# LÍMITES
# =========================================================

const MAX_LIMITED_STACKS: int = 10

const MIN_RUNTIME_MULTIPLIER: float = 0.10

const MAX_RUNTIME_MULTIPLIER: float = 3.0


# =========================================================
# IDENTIDAD
# =========================================================

var effect_id: String = ""

var category: String = ""


# =========================================================
# DURACIÓN
# =========================================================

var duration_seconds: float = 0.0


# =========================================================
# POLICIES
# =========================================================

var stacking_policy: String = ""

var refresh_policy: String = ""

var max_stacks: int = 1


# =========================================================
# PERIODIC DAMAGE OPCIONAL
# =========================================================

var damage_profile: ServerSkillDamageProfile = null

var tick_interval_seconds: float = 0.0

var tick_count: int = 0


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
# CONSTRUCTOR
# =========================================================

func _init(
	p_effect_id: String = "",
	p_category: String = "",
	p_duration_seconds: float = 0.0,
	p_stacking_policy: String = STACK_SINGLE,
	p_refresh_policy: String = REFRESH_REFRESH,
	p_max_stacks: int = 1,
	p_damage_profile: ServerSkillDamageProfile = null,
	p_tick_interval_seconds: float = 0.0,
	p_tick_count: int = 0,
	p_movement_speed_multiplier: float = 1.0,
	p_attack_speed_multiplier: float = 1.0,
	p_blocks_movement: bool = false,
	p_blocks_actions: bool = false,
	p_blocks_skills: bool = false
) -> void:
	effect_id = (
		p_effect_id
		.strip_edges()
		.to_lower()
	)


	category = (
		p_category
		.strip_edges()
		.to_lower()
	)


	duration_seconds = (
		p_duration_seconds
	)


	stacking_policy = (
		p_stacking_policy
		.strip_edges()
		.to_lower()
	)


	refresh_policy = (
		p_refresh_policy
		.strip_edges()
		.to_lower()
	)


	max_stacks = p_max_stacks


	damage_profile = (
		p_damage_profile
	)


	tick_interval_seconds = (
		p_tick_interval_seconds
	)


	tick_count = p_tick_count


	movement_speed_multiplier = (
		p_movement_speed_multiplier
	)


	attack_speed_multiplier = (
		p_attack_speed_multiplier
	)


	blocks_movement = (
		p_blocks_movement
	)


	blocks_actions = (
		p_blocks_actions
	)


	blocks_skills = (
		p_blocks_skills
	)


# =========================================================
# FACTORY — PERIODIC DAMAGE
# =========================================================

static func create_periodic_damage(
	p_effect_id: String,
	p_damage_profile: ServerSkillDamageProfile,
	p_tick_interval_seconds: float,
	p_tick_count: int,
	p_refresh_policy: String = REFRESH_REPLACE,
	p_stacking_policy: String = STACK_SINGLE,
	p_max_stacks: int = 1
) -> ServerStatusEffectProfile:
	return ServerStatusEffectProfile.new(
		p_effect_id,
		CATEGORY_DOT,
		p_tick_interval_seconds
		*
		float(p_tick_count),
		p_stacking_policy,
		p_refresh_policy,
		p_max_stacks,
		p_damage_profile,
		p_tick_interval_seconds,
		p_tick_count,
		1.0,
		1.0,
		false,
		false,
		false
	)


# =========================================================
# FACTORY — HARD CONTROL
# =========================================================

static func create_hard_control(
	p_effect_id: String,
	p_duration_seconds: float,
	p_blocks_movement: bool,
	p_blocks_actions: bool,
	p_blocks_skills: bool
) -> ServerStatusEffectProfile:
	return ServerStatusEffectProfile.new(
		p_effect_id,
		CATEGORY_HARD_CONTROL,
		p_duration_seconds,
		STACK_SINGLE,
		REFRESH_REFRESH,
		1,
		null,
		0.0,
		0,
		1.0,
		1.0,
		p_blocks_movement,
		p_blocks_actions,
		p_blocks_skills
	)


# =========================================================
# FACTORY — MODIFIER
# =========================================================

static func create_modifier(
	p_effect_id: String,
	p_category: String,
	p_duration_seconds: float,
	p_movement_speed_multiplier: float,
	p_attack_speed_multiplier: float,
	p_stacking_policy: String = STACK_SINGLE,
	p_refresh_policy: String = REFRESH_REFRESH,
	p_max_stacks: int = 1
) -> ServerStatusEffectProfile:
	return ServerStatusEffectProfile.new(
		p_effect_id,
		p_category,
		p_duration_seconds,
		p_stacking_policy,
		p_refresh_policy,
		p_max_stacks,
		null,
		0.0,
		0,
		p_movement_speed_multiplier,
		p_attack_speed_multiplier,
		false,
		false,
		false
	)


# =========================================================
# HELPERS
# =========================================================

func is_periodic_damage() -> bool:
	return (
		category
		==
		CATEGORY_DOT
	)


func is_hard_control() -> bool:
	return (
		category
		==
		CATEGORY_HARD_CONTROL
	)


func get_duration_seconds() -> float:
	return duration_seconds


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if effect_id.is_empty():
		return false


	if not _is_valid_category(
		category
	):
		return false


	if duration_seconds <= 0.0:
		return false


	if not _is_valid_stacking_policy(
		stacking_policy
	):
		return false


	if not _is_valid_refresh_policy(
		refresh_policy
	):
		return false


	if (
		movement_speed_multiplier
		<
		MIN_RUNTIME_MULTIPLIER
		or
		movement_speed_multiplier
		>
		MAX_RUNTIME_MULTIPLIER
	):
		return false


	if (
		attack_speed_multiplier
		<
		MIN_RUNTIME_MULTIPLIER
		or
		attack_speed_multiplier
		>
		MAX_RUNTIME_MULTIPLIER
	):
		return false


	# -----------------------------------------------------
	# STACKING
	# -----------------------------------------------------

	if (
		stacking_policy
		==
		STACK_LIMITED
	):
		if (
			max_stacks < 2
			or
			max_stacks > MAX_LIMITED_STACKS
		):
			return false


		if (
			refresh_policy
			!=
			REFRESH_REFRESH
		):
			return false

	else:
		if max_stacks != 1:
			return false


	# -----------------------------------------------------
	# DoT
	# -----------------------------------------------------

	if is_periodic_damage():
		if damage_profile == null:
			return false


		if not damage_profile.is_valid():
			return false


		if (
			damage_profile.delivery
			!=
			ServerDamageTaxonomy.DELIVERY_PERIODIC
		):
			return false


		if tick_interval_seconds <= 0.0:
			return false


		if tick_count <= 0:
			return false


		if not is_equal_approx(
			duration_seconds,
			tick_interval_seconds
			*
			float(tick_count)
		):
			return false


		if (
			stacking_policy
			==
			STACK_LIMITED
		):
			return false


		if (
			not is_equal_approx(
				movement_speed_multiplier,
				1.0
			)
			or
			not is_equal_approx(
				attack_speed_multiplier,
				1.0
			)
		):
			return false


		if (
			blocks_movement
			or
			blocks_actions
			or
			blocks_skills
		):
			return false


		return true


	# -----------------------------------------------------
	# NO DoT
	# -----------------------------------------------------

	if damage_profile != null:
		return false


	if tick_interval_seconds != 0.0:
		return false


	if tick_count != 0:
		return false


	# -----------------------------------------------------
	# HARD CONTROL
	# -----------------------------------------------------

	if is_hard_control():
		if (
			duration_seconds
			>
			MAX_HARD_CONTROL_DURATION_SECONDS
		):
			return false


		if (
			stacking_policy
			!=
			STACK_SINGLE
		):
			return false


		if (
			refresh_policy
			!=
			REFRESH_REFRESH
		):
			return false


		if (
			not is_equal_approx(
				movement_speed_multiplier,
				1.0
			)
			or
			not is_equal_approx(
				attack_speed_multiplier,
				1.0
			)
		):
			return false


		if not (
			blocks_movement
			or
			blocks_actions
			or
			blocks_skills
		):
			return false


		return true


	# -----------------------------------------------------
	# Sólo Hard Control puede bloquear directamente.
	# -----------------------------------------------------

	if (
		blocks_movement
		or
		blocks_actions
		or
		blocks_skills
	):
		return false


	# -----------------------------------------------------
	# SOFT CONTROL
	# -----------------------------------------------------

	if (
		category
		==
		CATEGORY_SOFT_CONTROL
	):
		if (
			duration_seconds
			>
			MAX_SOFT_CONTROL_DURATION_SECONDS
		):
			return false


		return (
			movement_speed_multiplier < 1.0
			or
			attack_speed_multiplier < 1.0
		)


	# -----------------------------------------------------
	# BUFF
	# -----------------------------------------------------

	if (
		category
		==
		CATEGORY_BUFF
	):
		return (
			movement_speed_multiplier > 1.0
			or
			attack_speed_multiplier > 1.0
		)


	# -----------------------------------------------------
	# DEBUFF
	# -----------------------------------------------------

	if (
		category
		==
		CATEGORY_DEBUFF
	):
		return (
			movement_speed_multiplier < 1.0
			or
			attack_speed_multiplier < 1.0
		)


	return false


# =========================================================
# VALIDAR ENUMS
# =========================================================

static func _is_valid_category(
	value: String
) -> bool:
	return (
		value == CATEGORY_BUFF
		or
		value == CATEGORY_DEBUFF
		or
		value == CATEGORY_DOT
		or
		value == CATEGORY_SOFT_CONTROL
		or
		value == CATEGORY_HARD_CONTROL
	)


static func _is_valid_stacking_policy(
	value: String
) -> bool:
	return (
		value == STACK_SINGLE
		or
		value == STACK_LIMITED
		or
		value == STACK_INDEPENDENT_SOURCES
	)


static func _is_valid_refresh_policy(
	value: String
) -> bool:
	return (
		value == REFRESH_REPLACE
		or
		value == REFRESH_REFRESH
	)
