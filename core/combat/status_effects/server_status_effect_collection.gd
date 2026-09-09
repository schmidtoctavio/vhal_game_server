class_name ServerStatusEffectCollection
extends RefCounted


# =========================================================
# STATE
# =========================================================

var effects_by_key: Dictionary = {}

var hard_control_immunity_until_msec: int = 0


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	if hard_control_immunity_until_msec < 0:
		return false


	for value: Variant in effects_by_key.values():
		var status_effect := (
			value
			as
			ServerStatusEffectRuntime
		)


		if status_effect == null:
			return false


		if not status_effect.is_valid():
			return false


	return true


# =========================================================
# APPLY
# =========================================================

func apply_status_effect(
	status_effect: ServerStatusEffectRuntime,
	now_msec: int
) -> Dictionary:
	if status_effect == null:
		return {
			"ok": false,
		}


	if not status_effect.is_valid():
		return {
			"ok": false,
		}


	if now_msec < 0:
		return {
			"ok": false,
		}


	var runtime_key := (
		status_effect.runtime_key
	)


	if runtime_key.is_empty():
		return {
			"ok": false,
		}


	# -----------------------------------------------------
	# STALE SAME EFFECT
	#
	# Normalmente lo limpia el scheduler antes.
	# Este bloque evita una carrera exacta en el borde
	# temporal de una nueva aplicación.
	# -----------------------------------------------------

	var existing := (
		get_status_effect_by_key(
			runtime_key
		)
	)


	if (
		existing != null
		and
		(
			existing.is_expired(
				now_msec
			)
			or
			existing.is_periodic_finished()
		)
	):
		if existing.is_hard_control():
			begin_hard_control_immunity(
				now_msec
			)


		effects_by_key.erase(
			runtime_key
		)


		existing = null


	# -----------------------------------------------------
	# HARD CONTROL IMMUNITY
	# -----------------------------------------------------

	if status_effect.is_hard_control():
		if is_hard_control_immune(
			now_msec
		):
			return {
				"ok": true,

				"changed": false,

				"operation": "immune",

				"status_effect": null,
			}


		var active_hard_control := (
			get_active_hard_control(
				now_msec
			)
		)


		if (
			active_hard_control != null
			and
			active_hard_control.runtime_key
			!=
			runtime_key
		):
			return {
				"ok": true,

				"changed": false,

				"operation": (
					"hard_control_active"
				),

				"status_effect": (
					active_hard_control
				),
			}


	# -----------------------------------------------------
	# NUEVO
	# -----------------------------------------------------

	if existing == null:
		effects_by_key[
			runtime_key
		] = status_effect


		return {
			"ok": true,

			"changed": true,

			"operation": "applied",

			"status_effect": status_effect,
		}


	# -----------------------------------------------------
	# REPLACE
	# -----------------------------------------------------

	if (
		existing.refresh_policy
		==
		ServerStatusEffectProfile.REFRESH_REPLACE
	):
		effects_by_key[
			runtime_key
		] = status_effect


		return {
			"ok": true,

			"changed": true,

			"operation": "replaced",

			"status_effect": status_effect,
		}


	# -----------------------------------------------------
	# REFRESH
	# -----------------------------------------------------

	var operation := "refreshed"


	if (
		existing.stacking_policy
		==
		ServerStatusEffectProfile.STACK_LIMITED
	):
		if existing.add_stack():
			operation = "stacked"

		else:
			operation = "refreshed_at_cap"


	if not existing.refresh_from(
		status_effect
	):
		return {
			"ok": false,
		}


	return {
		"ok": true,

		"changed": true,

		"operation": operation,

		"status_effect": existing,
	}


# =========================================================
# GET
# =========================================================

func get_status_effect_by_key(
	runtime_key: String
) -> ServerStatusEffectRuntime:
	var normalized_key := (
		runtime_key.strip_edges()
	)


	if normalized_key.is_empty():
		return null


	if not effects_by_key.has(
		normalized_key
	):
		return null


	return (
		effects_by_key[
			normalized_key
		]
		as
		ServerStatusEffectRuntime
	)


func get_all() -> Array[ServerStatusEffectRuntime]:
	var result: Array[ServerStatusEffectRuntime] = []


	var keys: Array = (
		effects_by_key.keys()
	)


	keys.sort()


	for key_value: Variant in keys:
		var key := String(
			key_value
		)


		var status_effect := (
			get_status_effect_by_key(
				key
			)
		)


		if status_effect == null:
			continue


		result.append(
			status_effect
		)


	return result


# =========================================================
# REMOVE
# =========================================================

func remove_status_effect_by_key(
	runtime_key: String
) -> ServerStatusEffectRuntime:
	var status_effect := (
		get_status_effect_by_key(
			runtime_key
		)
	)


	if status_effect == null:
		return null


	effects_by_key.erase(
		status_effect.runtime_key
	)


	return status_effect


func remove_status_effect(
	effect_id: String
) -> int:
	var normalized_effect_id := (
		effect_id
		.strip_edges()
		.to_lower()
	)


	if normalized_effect_id.is_empty():
		return 0


	var keys_to_remove: Array[String] = []


	for status_effect: ServerStatusEffectRuntime in get_all():
		if (
			status_effect.effect_id
			!=
			normalized_effect_id
		):
			continue


		keys_to_remove.append(
			status_effect.runtime_key
		)


	for runtime_key: String in keys_to_remove:
		effects_by_key.erase(
			runtime_key
		)


	return keys_to_remove.size()


func clear() -> void:
	effects_by_key.clear()

	hard_control_immunity_until_msec = 0


# =========================================================
# HARD CONTROL
# =========================================================

func get_active_hard_control(
	now_msec: int
) -> ServerStatusEffectRuntime:
	for status_effect: ServerStatusEffectRuntime in get_all():
		if not status_effect.is_hard_control():
			continue


		if status_effect.is_expired(
			now_msec
		):
			continue


		return status_effect


	return null


func begin_hard_control_immunity(
	now_msec: int
) -> void:
	if now_msec < 0:
		return


	var immunity_msec := maxi(
		ceili(
			ServerStatusEffectProfile
			.HARD_CONTROL_IMMUNITY_SECONDS
			*
			1000.0
		),
		1
	)


	hard_control_immunity_until_msec = maxi(
		hard_control_immunity_until_msec,
		now_msec
		+
		immunity_msec
	)


func is_hard_control_immune(
	now_msec: int
) -> bool:
	return (
		now_msec
		<
		hard_control_immunity_until_msec
	)


# =========================================================
# MOVEMENT MODIFIER
# =========================================================

func get_movement_speed_multiplier(
	now_msec: int
) -> float:
	var result := 1.0


	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		result *= (
			status_effect
			.get_effective_movement_speed_multiplier()
		)


	return clampf(
		result,
		ServerStatusEffectProfile
			.MIN_RUNTIME_MULTIPLIER,
		ServerStatusEffectProfile
			.MAX_RUNTIME_MULTIPLIER
	)


# =========================================================
# ATTACK SPEED MODIFIER
# =========================================================

func get_attack_speed_multiplier(
	now_msec: int
) -> float:
	var result := 1.0


	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		result *= (
			status_effect
			.get_effective_attack_speed_multiplier()
		)


	return clampf(
		result,
		ServerStatusEffectProfile
			.MIN_RUNTIME_MULTIPLIER,
		ServerStatusEffectProfile
			.MAX_RUNTIME_MULTIPLIER
	)


# =========================================================
# CONTROL FLAGS
# =========================================================

func is_movement_blocked(
	now_msec: int
) -> bool:
	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		if status_effect.blocks_movement:
			return true


	return false


func are_actions_blocked(
	now_msec: int
) -> bool:
	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		if status_effect.blocks_actions:
			return true


	return false


func are_skills_blocked(
	now_msec: int
) -> bool:
	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		if status_effect.blocks_skills:
			return true


	return false


# =========================================================
# SNAPSHOT
# =========================================================

func get_snapshots(
	now_msec: int
) -> Array:
	var result: Array = []


	for status_effect: ServerStatusEffectRuntime in get_all():
		if status_effect.is_expired(
			now_msec
		):
			continue


		var snapshot := (
			status_effect.to_snapshot(
				now_msec
			)
		)


		if snapshot.is_empty():
			continue


		result.append(
			snapshot
		)


	return result
