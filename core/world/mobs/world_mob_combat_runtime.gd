class_name WorldMobCombatRuntime
extends RefCounted


const STATE_IDLE: String = "idle"

const STATE_CHASING: String = "chasing"

const STATE_ATTACKING: String = "attacking"

const STATE_RETURNING: String = "returning"


const VALID_STATES: Array[String] = [
	STATE_IDLE,
	STATE_CHASING,
	STATE_ATTACKING,
	STATE_RETURNING,
]


var state: String = STATE_IDLE

var target_peer_id: int = -1


# =========================================================
# ATTACK COOLDOWN
# =========================================================

var next_attack_at_msec: int = 0


# =========================================================
# NAVIGATION
# =========================================================

var navigation_path: PackedVector3Array = (
	PackedVector3Array()
)

var navigation_path_index: int = 0

var next_repath_at_msec: int = 0


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if not VALID_STATES.has(
		state
	):
		return false


	if (
		target_peer_id != -1
		and
		target_peer_id <= 1
	):
		return false


	if (
		state == STATE_CHASING
		or
		state == STATE_ATTACKING
	):
		if target_peer_id <= 1:
			return false


	if (
		state == STATE_IDLE
		or
		state == STATE_RETURNING
	):
		if target_peer_id != -1:
			return false


	if next_attack_at_msec < 0:
		return false


	if next_repath_at_msec < 0:
		return false


	if navigation_path_index < 0:
		return false


	if navigation_path.is_empty():
		if navigation_path_index != 0:
			return false

	else:
		if (
			navigation_path_index
			>
			navigation_path.size()
		):
			return false


	return true


# =========================================================
# TARGET
# =========================================================

func acquire_target(
	peer_id: int
) -> bool:
	if peer_id <= 1:
		return false


	target_peer_id = peer_id

	state = STATE_CHASING


	clear_navigation()


	return true


func release_target(
	return_to_spawn: bool = true
) -> void:
	target_peer_id = -1


	state = (
		STATE_RETURNING
		if
		return_to_spawn
		else
		STATE_IDLE
	)


	clear_navigation()


# =========================================================
# STATE
# =========================================================

func begin_chasing() -> bool:
	if target_peer_id <= 1:
		return false


	state = STATE_CHASING


	return true


func begin_attacking() -> bool:
	if target_peer_id <= 1:
		return false


	state = STATE_ATTACKING


	clear_navigation()


	return true


func begin_returning() -> void:
	target_peer_id = -1

	state = STATE_RETURNING


	clear_navigation()


func finish_returning() -> void:
	target_peer_id = -1

	state = STATE_IDLE


	clear_navigation()


# =========================================================
# ATTACK COOLDOWN
# =========================================================

func can_attack(
	now_msec: int
) -> bool:
	if now_msec < 0:
		return false


	return (
		now_msec
		>=
		next_attack_at_msec
	)


func start_attack_cooldown(
	duration_seconds: float,
	now_msec: int
) -> bool:
	if duration_seconds <= 0.0:
		return false


	if now_msec < 0:
		return false


	var duration_msec := maxi(
		ceili(
			duration_seconds
			*
			1000.0
		),
		1
	)


	next_attack_at_msec = (
		now_msec
		+
		duration_msec
	)


	return true


func reset_attack_cooldown() -> void:
	next_attack_at_msec = 0


# =========================================================
# NAVIGATION
# =========================================================

func should_repath(
	now_msec: int
) -> bool:
	if now_msec < 0:
		return false


	return (
		not has_navigation_path()
		or
		now_msec >= next_repath_at_msec
	)


func set_navigation_path(
	path: PackedVector3Array,
	next_repath_msec: int
) -> bool:
	if path.is_empty():
		return false


	if next_repath_msec < 0:
		return false


	navigation_path = (
		path.duplicate()
	)


	navigation_path_index = (
		1
		if
		navigation_path.size() > 1
		else
		0
	)


	next_repath_at_msec = (
		next_repath_msec
	)


	return true


func has_navigation_path() -> bool:
	return (
		not navigation_path.is_empty()

		and

		navigation_path_index
		<
		navigation_path.size()
	)


func clear_navigation() -> void:
	navigation_path = (
		PackedVector3Array()
	)

	navigation_path_index = 0

	next_repath_at_msec = 0


# =========================================================
# RESET
# =========================================================

func reset() -> void:
	state = STATE_IDLE

	target_peer_id = -1

	next_attack_at_msec = 0


	clear_navigation()
