class_name ServerSkillRuntimeState
extends RefCounted


# =========================================================
# ESTADO
# =========================================================

var learned_skill_ids: Dictionary = {}

var cooldown_until_msec_by_skill: Dictionary = {}


# =========================================================
# SKILLS APRENDIDAS
# =========================================================

func learn_skill(
	skill_id: String
) -> bool:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	if normalized_skill_id.is_empty():
		return false


	if not ServerSkillCatalog.has_definition(
		normalized_skill_id
	):
		return false


	learned_skill_ids[
		normalized_skill_id
	] = true


	return true


func has_learned_skill(
	skill_id: String
) -> bool:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	return learned_skill_ids.has(
		normalized_skill_id
	)


func get_learned_skill_ids() -> PackedStringArray:
	var result := PackedStringArray()


	for skill_id_value: Variant in learned_skill_ids.keys():
		result.append(
			String(
				skill_id_value
			)
		)


	result.sort()


	return result


# =========================================================
# COOLDOWN
# =========================================================

func is_on_cooldown(
	skill_id: String,
	now_msec: int = -1
) -> bool:
	return (
		get_cooldown_remaining_seconds(
			skill_id,
			now_msec
		)
		>
		0.0
	)


func get_cooldown_remaining_seconds(
	skill_id: String,
	now_msec: int = -1
) -> float:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	if not cooldown_until_msec_by_skill.has(
		normalized_skill_id
	):
		return 0.0


	var resolved_now_msec := (
		_resolve_now_msec(
			now_msec
		)
	)


	var cooldown_until_msec := int(
		cooldown_until_msec_by_skill[
			normalized_skill_id
		]
	)


	var remaining_msec := (
		cooldown_until_msec
		-
		resolved_now_msec
	)


	if remaining_msec <= 0:
		cooldown_until_msec_by_skill.erase(
			normalized_skill_id
		)

		return 0.0


	return (
		float(
			remaining_msec
		)
		/
		1000.0
	)


func start_cooldown(
	skill_id: String,
	duration_seconds: float,
	now_msec: int = -1
) -> bool:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)


	if not has_learned_skill(
		normalized_skill_id
	):
		return false


	if duration_seconds < 0.0:
		return false


	if duration_seconds == 0.0:
		cooldown_until_msec_by_skill.erase(
			normalized_skill_id
		)

		return true


	var resolved_now_msec := (
		_resolve_now_msec(
			now_msec
		)
	)


	var duration_msec := int(
		round(
			duration_seconds
			*
			1000.0
		)
	)


	cooldown_until_msec_by_skill[
		normalized_skill_id
	] = (
		resolved_now_msec
		+
		duration_msec
	)


	return true


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	for skill_id_value: Variant in learned_skill_ids.keys():
		var skill_id := String(
			skill_id_value
		)


		if not ServerSkillCatalog.has_definition(
			skill_id
		):
			return false


	for skill_id_value: Variant in cooldown_until_msec_by_skill.keys():
		var skill_id := String(
			skill_id_value
		)


		if not has_learned_skill(
			skill_id
		):
			return false


		var cooldown_until_value: Variant = (
			cooldown_until_msec_by_skill[
				skill_id
			]
		)


		if typeof(
			cooldown_until_value
		) != TYPE_INT:
			return false


		if int(
			cooldown_until_value
		) < 0:
			return false


	return true


# =========================================================
# CLOCK
# =========================================================

func _resolve_now_msec(
	now_msec: int
) -> int:
	if now_msec >= 0:
		return now_msec


	return Time.get_ticks_msec()
