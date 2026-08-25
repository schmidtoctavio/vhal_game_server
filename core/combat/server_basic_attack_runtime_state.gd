class_name ServerBasicAttackRuntimeState
extends RefCounted


var cooldown_until_msec: int = 0


func get_cooldown_remaining_seconds() -> float:
	var now_msec := (
		Time.get_ticks_msec()
	)


	if cooldown_until_msec <= now_msec:
		return 0.0


	return (
		float(
			cooldown_until_msec
			-
			now_msec
		)
		/
		1000.0
	)


func is_cooldown_active() -> bool:
	return (
		get_cooldown_remaining_seconds()
		>
		0.0
	)


func start_cooldown(
	duration_seconds: float
) -> bool:
	if duration_seconds < 0.0:
		return false


	if is_cooldown_active():
		return false


	var duration_msec := ceili(
		duration_seconds
		*
		1000.0
	)


	cooldown_until_msec = (
		Time.get_ticks_msec()
		+
		maxi(
			duration_msec,
			0
		)
	)


	return true


func reset() -> void:
	cooldown_until_msec = 0


func is_valid() -> bool:
	return (
		cooldown_until_msec >= 0
	)
