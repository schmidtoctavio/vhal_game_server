class_name ServerPveEnemyCombatContract
extends RefCounted


static func validate_contract() -> String:
	var mob_definition := (
		WorldMobDefinition.create(
			"training_combat_contract",
			"Training Combat Contract",
			1,
			5000,
			50,
			3.0,

			# Damage Defense
			100,
			0,
			0,
			0,
			0,
			0,

			# Hit Profile
			100,
			0,
			0.0,
			0.0,

			# PvE Combat
			5.0,
			10.0,
			2.5,
			1.5,
			1.25,
			200
		)
	)


	if (
		mob_definition == null
		or
		not mob_definition.is_valid()
	):
		return "Mob PvE Definition inválida."


	if not mob_definition.has_pve_combat_profile():
		return "Mob PvE Combat Profile no fue habilitado."


	# -----------------------------------------------------
	# AGGRO / RANGE / LEASH
	# -----------------------------------------------------

	if not ServerMobCombatRules.can_aggro(
		mob_definition,
		Vector3.ZERO,
		Vector3(
			3.0,
			0.0,
			4.0
		)
	):
		return "Target a distancia 5 debe generar Aggro."


	if not ServerMobCombatRules.is_in_attack_range(
		mob_definition,
		Vector3.ZERO,
		Vector3(
			1.5,
			0.0,
			0.0
		)
	):
		return "Target a 1.5 debe estar en Attack Range."


	if ServerMobCombatRules.is_in_attack_range(
		mob_definition,
		Vector3.ZERO,
		Vector3(
			1.6,
			0.0,
			0.0
		)
	):
		return "Target a 1.6 no debe estar en Attack Range."


	if not ServerMobCombatRules.is_leash_broken(
		mob_definition,
		Vector3.ZERO,
		Vector3(
			5.0,
			0.0,
			0.0
		),
		Vector3(
			10.1,
			0.0,
			0.0
		)
	):
		return "Target fuera de Leash 10 debe romper Aggro."


	# -----------------------------------------------------
	# RUNTIME
	# -----------------------------------------------------

	var runtime := (
		WorldMobCombatRuntime.new()
	)


	if not runtime.is_valid():
		return "Mob Combat Runtime inicial inválido."


	if not runtime.acquire_target(
		42
	):
		return "Mob Combat Runtime no adquirió target."


	if not runtime.begin_attacking():
		return "Mob Combat Runtime no entró en Attack."


	if not runtime.can_attack(
		1000
	):
		return "Mob debe poder atacar sin cooldown previo."


	if not runtime.start_attack_cooldown(
		1.25,
		1000
	):
		return "No se pudo iniciar Mob Attack Cooldown."


	if runtime.can_attack(
		2000
	):
		return "Mob atacó antes de terminar Cooldown."


	if not runtime.can_attack(
		2250
	):
		return "Mob no liberó Cooldown a 2250 ms."


	runtime.release_target(
		true
	)


	if (
		runtime.state
		!=
		WorldMobCombatRuntime.STATE_RETURNING
	):
		return "Release debe enviar Mob a Returning."


	# -----------------------------------------------------
	# PLAYER FOUNDATION
	#
	# AGI 15
	# →
	# Evasion 15
	# -----------------------------------------------------

	var primary_stats := (
		ServerCharacterPrimaryStatsState.new(
			"warrior",
			7,
			11,
			0,
			25,
			15,
			25,
			10,
			2,
			0,
			2,
			3,
			5,
			200,
			50,
			0,
			0,
			50,
			7,
			43
		)
	)


	if not primary_stats.is_valid():
		return "Player Primary Stats foundation inválido."


	var empty_equipment := {
		"account_id": 1,
		"character_id": 1,
		"container": "equipment",
		"items": [],
	}


	var defender_hit_profile := (
		ServerCharacterCombatHitProfileResolver
		.resolve(
			primary_stats,
			empty_equipment
		)
	)


	if defender_hit_profile == null:
		return "No se pudo resolver Player Hit Profile."


	if defender_hit_profile.evasion_rating != 15:
		return "Player AGI 15 debe producir Evasion 15."


	var attacker_hit_profile := (
		ServerMobCombatHitProfileResolver
		.resolve(
			mob_definition
		)
	)


	if attacker_hit_profile == null:
		return "No se pudo resolver Mob Hit Profile."


	if attacker_hit_profile.accuracy_rating != 100:
		return "Mob Accuracy debe resolver 100."


	var hit_result := (
		ServerHitResolutionRules.resolve(
			attacker_hit_profile,
			defender_hit_profile,
			0.50,
			0.50,
			0.50
		)
	)


	if hit_result == null:
		return "No se pudo resolver Mob Hit."


	# 100 / (100 + 15)

	if not is_equal_approx(
		hit_result.hit_chance,
		100.0 / 115.0
	):
		return "Mob Hit Chance foundation incorrecto."


	if (
		hit_result.outcome
		!=
		ServerHitResolutionResult.OUTCOME_HIT
	):
		return "Roll foundation debe producir Hit."


	# -----------------------------------------------------
	# DAMAGE
	# -----------------------------------------------------

	var damage_context := (
		ServerMobBasicAttackRules
		.build_resolution_context(
			mob_definition
		)
	)


	if damage_context == null:
		return "No se pudo construir Mob Damage Context."


	if damage_context.raw_damage != 200:
		return "Mob Raw Damage debe resolver 200."


	if (
		damage_context.school
		!=
		ServerDamageTaxonomy.SCHOOL_PHYSICAL
	):
		return "Mob Basic Attack debe ser Physical."


	if damage_context.can_critical:
		return "Mob Basic Attack foundation no debe criticar."


	var player_damage_defense := (
		ServerCharacterDamageDefenseProfileResolver
		.resolve(
			empty_equipment
		)
	)


	if player_damage_defense == null:
		return "No se pudo resolver Player Damage Defense."


	var damage_result := (
		ServerDamageResolver.resolve(
			damage_context,
			player_damage_defense,
			0.0,
			1.5,
			0.0,
			hit_result.damage_multiplier
		)
	)


	if damage_result == null:
		return "No se pudo resolver Mob Damage."


	if damage_result.final_damage != 200:
		return (
			"Mob 200 contra Armor 0 "
			+
			"debe producir Final Damage 200."
		)


	# -----------------------------------------------------
	# PLAYER VITALS
	# -----------------------------------------------------

	var vitals := (
		ServerVitalsState.new(
			1184,
			183
		)
	)


	var applied_damage := (
		vitals.apply_damage(
			damage_result.final_damage
		)
	)


	if applied_damage != 200:
		return "Player debe recibir Damage 200."


	if vitals.hp != 984:
		return "Player HP debe resolver 1184 → 984."


	return ""
