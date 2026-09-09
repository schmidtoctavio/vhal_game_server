class_name ServerStatusEffectContract
extends RefCounted


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	# -----------------------------------------------------
	# ANTI-PERMACONTROL
	# -----------------------------------------------------

	if (
		ServerStatusEffectProfile
		.MAX_HARD_CONTROL_DURATION_SECONDS
		<=
		0.0
	):
		return (
			"Hard Control debe poseer duration cap."
		)


	if (
		ServerStatusEffectProfile
		.HARD_CONTROL_IMMUNITY_SECONDS
		<=
		0.0
	):
		return (
			"Hard Control debe poseer immunity window."
		)


	var invalid_long_stun := (
		ServerStatusEffectProfile
		.create_hard_control(
			"contract_long_stun",
			4.0,
			true,
			true,
			true
		)
	)


	if invalid_long_stun.is_valid():
		return (
			"Hard Control superior al cap fue aceptado."
		)


	# -----------------------------------------------------
	# SOFT CONTROL
	# -----------------------------------------------------

	var slow_profile := (
		ServerStatusEffectProfile.create_modifier(
			"contract_slow",
			ServerStatusEffectProfile
				.CATEGORY_SOFT_CONTROL,
			4.0,
			0.50,
			1.0
		)
	)


	if not slow_profile.is_valid():
		return (
			"No se pudo crear Soft Control válido."
		)


	var slow_runtime := (
		ServerStatusEffectRuntime.create(
			slow_profile,
			null,
			{
				"kind": "contract",
				"character_id": 1,
			},
			1000
		)
	)


	if slow_runtime == null:
		return (
			"No se pudo crear runtime de Soft Control."
		)


	var slow_collection := (
		ServerStatusEffectCollection.new()
	)


	var slow_result := (
		slow_collection.apply_status_effect(
			slow_runtime,
			1000
		)
	)


	if not bool(
		slow_result.get(
			"changed",
			false
		)
	):
		return (
			"Soft Control no fue aplicado."
		)


	if not is_equal_approx(
		slow_collection
			.get_movement_speed_multiplier(
				1000
			),
		0.50
	):
		return (
			"Soft Control no modificó Movement Speed."
		)


	# -----------------------------------------------------
	# REPLACE POLICY
	# -----------------------------------------------------

	var replace_profile := (
		ServerStatusEffectProfile.create_modifier(
			"contract_replace_debuff",
			ServerStatusEffectProfile.CATEGORY_DEBUFF,
			5.0,
			0.90,
			1.0,
			ServerStatusEffectProfile.STACK_SINGLE,
			ServerStatusEffectProfile.REFRESH_REPLACE,
			1
		)
	)


	if not replace_profile.is_valid():
		return (
			"No se pudo crear Status Effect Replace."
		)


	var replace_collection := (
		ServerStatusEffectCollection.new()
	)


	var replace_runtime_first := (
		ServerStatusEffectRuntime.create(
			replace_profile,
			null,
			{
				"kind": "contract",
				"character_id": 30,
			},
			1000
		)
	)


	if replace_runtime_first == null:
		return (
			"No se pudo crear primer runtime Replace."
		)


	var replace_first_result := (
		replace_collection.apply_status_effect(
			replace_runtime_first,
			1000
		)
	)


	if String(
		replace_first_result.get(
			"operation",
			""
		)
	) != "applied":
		return (
			"Primer Replace debe aplicar normalmente."
		)


	var replace_runtime_second := (
		ServerStatusEffectRuntime.create(
			replace_profile,
			null,
			{
				"kind": "contract",
				"character_id": 31,
			},
			2000
		)
	)


	if replace_runtime_second == null:
		return (
			"No se pudo crear segundo runtime Replace."
		)


	var replace_second_result := (
		replace_collection.apply_status_effect(
			replace_runtime_second,
			2000
		)
	)


	if String(
		replace_second_result.get(
			"operation",
			""
		)
	) != "replaced":
		return (
			"Replace Policy no reemplazó el runtime anterior."
		)


	if replace_collection.get_all().size() != 1:
		return (
			"Replace Policy creó múltiples runtimes."
		)


	var replaced_effect := (
		replace_collection.get_all()[0]
	)


	if replaced_effect.source_identity != "character:31":
		return (
			"Replace Policy no actualizó Source Attribution."
		)


	if replaced_effect.expires_at_msec != 7000:
		return (
			"Replace Policy no reinició correctamente Duration."
		)

	# -----------------------------------------------------
	# LIMITED STACKS
	# -----------------------------------------------------

	var stack_profile := (
		ServerStatusEffectProfile.create_modifier(
			"contract_speed_buff",
			ServerStatusEffectProfile.CATEGORY_BUFF,
			5.0,
			1.10,
			1.0,
			ServerStatusEffectProfile.STACK_LIMITED,
			ServerStatusEffectProfile.REFRESH_REFRESH,
			3
		)
	)


	if not stack_profile.is_valid():
		return (
			"No se pudo crear Buff stackeable."
		)


	var stack_collection := (
		ServerStatusEffectCollection.new()
	)


	for application_index in range(4):
		var runtime := (
			ServerStatusEffectRuntime.create(
				stack_profile,
				null,
				{
					"kind": "contract",
					"character_id": 2,
				},
				1000
				+
				application_index
				*
				100
			)
		)


		if runtime == null:
			return (
				"No se pudo crear runtime stackeable."
			)


		var result := (
			stack_collection.apply_status_effect(
				runtime,
				1000
				+
				application_index
				*
				100
			)
		)


		if not bool(
			result.get(
				"ok",
				false
			)
		):
			return (
				"No se pudo aplicar stack."
			)


	var stacked_effects := (
		stack_collection.get_all()
	)


	if stacked_effects.size() != 1:
		return (
			"Limited Stack creó múltiples runtimes."
		)


	if stacked_effects[0].stack_count != 3:
		return (
			"Limited Stack no respetó max_stacks 3."
		)


	if not is_equal_approx(
		stack_collection
			.get_movement_speed_multiplier(
				1400
			),
		pow(
			1.10,
			3.0
		)
	):
		return (
			"Limited Stack no acumuló modifier."
		)


	# -----------------------------------------------------
	# INDEPENDENT SOURCES
	# -----------------------------------------------------

	var source_profile := (
		ServerStatusEffectProfile.create_modifier(
			"contract_attack_debuff",
			ServerStatusEffectProfile.CATEGORY_DEBUFF,
			5.0,
			1.0,
			0.90,
			ServerStatusEffectProfile
				.STACK_INDEPENDENT_SOURCES,
			ServerStatusEffectProfile.REFRESH_REFRESH,
			1
		)
	)


	if not source_profile.is_valid():
		return (
			"No se pudo crear Debuff por Source."
		)


	var source_collection := (
		ServerStatusEffectCollection.new()
	)


	for character_id in [10, 11]:
		var source_runtime := (
			ServerStatusEffectRuntime.create(
				source_profile,
				null,
				{
					"kind": "contract",
					"character_id": character_id,
				},
				2000
			)
		)


		if source_runtime == null:
			return (
				"No se pudo crear runtime por Source."
			)


		var source_result := (
			source_collection.apply_status_effect(
				source_runtime,
				2000
			)
		)


		if not bool(
			source_result.get(
				"changed",
				false
			)
		):
			return (
				"Independent Source no fue aplicado."
			)


	if source_collection.get_all().size() != 2:
		return (
			"Independent Sources no conservó dos Sources."
		)


	# -----------------------------------------------------
	# HARD CONTROL
	# -----------------------------------------------------

	var stun_profile := (
		ServerStatusEffectProfile.create_hard_control(
			"contract_stun",
			1.25,
			true,
			true,
			true
		)
	)


	if not stun_profile.is_valid():
		return (
			"No se pudo crear Hard Control válido."
		)


	var stun_collection := (
		ServerStatusEffectCollection.new()
	)


	var stun_runtime := (
		ServerStatusEffectRuntime.create(
			stun_profile,
			null,
			{
				"kind": "contract",
				"character_id": 20,
			},
			1000
		)
	)


	if stun_runtime == null:
		return (
			"No se pudo crear runtime de Hard Control."
		)


	var stun_result := (
		stun_collection.apply_status_effect(
			stun_runtime,
			1000
		)
	)


	if not bool(
		stun_result.get(
			"changed",
			false
		)
	):
		return (
			"Hard Control no fue aplicado."
		)


	if not stun_collection.is_movement_blocked(
		1000
	):
		return (
			"Hard Control no bloqueó movement."
		)


	if not stun_collection.are_actions_blocked(
		1000
	):
		return (
			"Hard Control no bloqueó actions."
		)


	if not stun_collection.are_skills_blocked(
		1000
	):
		return (
			"Hard Control no bloqueó skills."
		)


	# -----------------------------------------------------
	# CONTINUOUS HARD CONTROL CAP
	# -----------------------------------------------------

	var refresh_one := (
		ServerStatusEffectRuntime.create(
			stun_profile,
			null,
			{
				"kind": "contract",
				"character_id": 20,
			},
			2000
		)
	)


	var refresh_two := (
		ServerStatusEffectRuntime.create(
			stun_profile,
			null,
			{
				"kind": "contract",
				"character_id": 20,
			},
			2900
		)
	)


	if (
		refresh_one == null
		or
		refresh_two == null
	):
		return (
			"No se pudo preparar refresh de Hard Control."
		)


	if not stun_runtime.refresh_from(
		refresh_one
	):
		return (
			"No se pudo refrescar Hard Control."
		)


	if not stun_runtime.refresh_from(
		refresh_two
	):
		return (
			"No se pudo refrescar Hard Control al cap."
		)


	if (
		stun_runtime.expires_at_msec
		>
		4000
	):
		return (
			"Hard Control superó continuous duration cap."
		)


	# -----------------------------------------------------
	# IMMUNITY WINDOW
	# -----------------------------------------------------

	var immunity_collection := (
		ServerStatusEffectCollection.new()
	)


	immunity_collection.begin_hard_control_immunity(
		5000
	)


	var immune_runtime := (
		ServerStatusEffectRuntime.create(
			stun_profile,
			null,
			{
				"kind": "contract",
				"character_id": 21,
			},
			5500
		)
	)


	if immune_runtime == null:
		return (
			"No se pudo crear Hard Control para immunity."
		)


	var immune_result := (
		immunity_collection.apply_status_effect(
			immune_runtime,
			5500
		)
	)


	if String(
		immune_result.get(
			"operation",
			""
		)
	) != "immune":
		return (
			"Hard Control Immunity no rechazó recontrol."
		)


	# -----------------------------------------------------
	# POISON — REGRESIÓN
	# -----------------------------------------------------

	var poison := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.POISON_ID
		)
	)


	if (
		poison == null
		or
		poison.status_effect_profile == null
	):
		return (
			"Poison perdió Status Effect Profile."
		)


	if (
		poison.status_effect_profile.category
		!=
		ServerStatusEffectProfile.CATEGORY_DOT
	):
		return (
			"Poison debe seguir siendo DoT."
		)


	if (
		poison.status_effect_profile.stacking_policy
		!=
		ServerStatusEffectProfile.STACK_SINGLE
	):
		return (
			"Poison debe conservar Single Stack."
		)


	if (
		poison.status_effect_profile.refresh_policy
		!=
		ServerStatusEffectProfile.REFRESH_REPLACE
	):
		return (
			"Poison debe conservar Replace."
		)


	# -----------------------------------------------------
	# FIRE BALL — HARD CC REAL
	# -----------------------------------------------------

	var fire_ball := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.FIRE_BALL_ID
		)
	)


	if (
		fire_ball == null
		or
		fire_ball.status_effect_profile == null
	):
		return (
			"Fire Ball no posee Hard Control Profile."
		)


	if (
		fire_ball.status_effect_profile.category
		!=
		ServerStatusEffectProfile.CATEGORY_HARD_CONTROL
	):
		return (
			"Fire Ball CC debe ser Hard Control."
		)


	if not is_equal_approx(
		fire_ball.status_effect_profile.duration_seconds,
		1.25
	):
		return (
			"Fire Ball Stun debe durar 1.25 segundos."
		)


	# -----------------------------------------------------
	# PERIODIC DAMAGE CONTRACT
	# -----------------------------------------------------

	var periodic_error := (
		ServerSkillPeriodicDamageRules
		.validate_contract()
	)


	if not periodic_error.is_empty():
		return (
			"Periodic Damage Contract inválido: "
			+
			periodic_error
		)


	return ""
