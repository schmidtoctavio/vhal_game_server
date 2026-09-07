class_name ServerCombatDamageContract
extends RefCounted


# =========================================================
# COMBAT DAMAGE CONTRACT
#
# Protege el pipeline integrado:
#
# Basic Attack
# Fire Ball
# Poison
#
# usando exactamente:
#
# Context Builder
# → Damage Defense Profile
# → Unified Damage Resolver
# =========================================================

static func validate_contract() -> String:
	var current_target_defense := (
		_build_current_target_defense()
	)


	if current_target_defense == null:
		return (
			"No se pudo construir la defensa "
			+
			"del target foundation."
		)


	var resistant_target_defense := (
		_build_resistant_target_defense()
	)


	if resistant_target_defense == null:
		return (
			"No se pudo construir el target "
			+
			"con resistencias."
		)


	var basic_attack_error := (
		_validate_basic_attack(
			current_target_defense
		)
	)


	if not basic_attack_error.is_empty():
		return (
			"Basic Attack | "
			+
			basic_attack_error
		)


	var fire_ball_error := (
		_validate_fire_ball(
			current_target_defense,
			resistant_target_defense
		)
	)


	if not fire_ball_error.is_empty():
		return (
			"Fire Ball | "
			+
			fire_ball_error
		)


	var poison_error := (
		_validate_poison(
			current_target_defense,
			resistant_target_defense
		)
	)


	if not poison_error.is_empty():
		return (
			"Poison | "
			+
			poison_error
		)


	return ""


# =========================================================
# BASIC ATTACK
# =========================================================

static func _validate_basic_attack(
	defense_profile: ServerDamageDefenseProfile
) -> String:
	var derived_stats := (
		ServerCharacterDerivedStatsState.new(
			"warrior",
			0,
			11,
			0,
			288,
			79,
			0,
			0,
			84,
			13,
			13,
			0.0,
			1.5,
			1.0,
			4.0
		)
	)


	if not derived_stats.is_valid():
		return (
			"No se pudo crear Warrior sintético."
		)


	var attack_profile := {
		"mode": "unarmed",

		"weapon_item_id": "",

		"base_damage": 500,
	}


	var context := (
		ServerBasicAttackDamageRules
		.build_resolution_context(
			attack_profile,
			derived_stats
		)
	)


	if (
		context == null
		or
		not context.is_valid()
	):
		return (
			"No se pudo construir Damage Context."
		)


	if context.raw_damage != 584:
		return (
			"Unarmed + Physical Power 84 "
			+
			"debe producir Raw Damage 584."
		)


	if (
		context.school
		!=
		ServerDamageTaxonomy.SCHOOL_PHYSICAL
	):
		return (
			"Basic Attack debe ser Physical."
		)


	if (
		context.element
		!=
		ServerDamageTaxonomy.ELEMENT_NONE
	):
		return (
			"Basic Attack foundation "
			+
			"debe usar Element none."
		)


	if (
		context.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_DIRECT
	):
		return (
			"Basic Attack debe ser Direct."
		)


	if not context.can_critical:
		return (
			"Basic Attack debe conservar "
			+
			"Critical eligibility."
		)


	var result := (
		ServerDamageResolver.resolve(
			context,
			defense_profile,
			0.0,
			1.5,
			0.5
		)
	)


	if (
		result == null
		or
		not result.is_valid()
	):
		return (
			"No se pudo resolver Basic Attack."
		)


	if result.critical_applied:
		return (
			"Critical Chance 0 no debe criticar."
		)


	if result.school_rating != 100:
		return (
			"Basic Attack debe consumir Armor 100."
		)


	if result.element_rating != 0:
		return (
			"Basic Attack / none no debe "
			+
			"consumir Element Resistance."
		)


	if result.final_damage != 530:
		return (
			"584 con Armor 100 "
			+
			"debe producir Final Damage 530."
		)


	return ""


# =========================================================
# FIRE BALL
# =========================================================

static func _validate_fire_ball(
	current_target_defense: ServerDamageDefenseProfile,
	resistant_target_defense: ServerDamageDefenseProfile
) -> String:
	var definition := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.FIRE_BALL_ID
		)
	)


	if definition == null:
		return (
			"No se pudo resolver Fire Ball."
		)


	var derived_stats := (
		ServerCharacterDerivedStatsState.new(
			"mage",
			0,
			1,
			0,
			115,
			295,
			0,
			0,
			15,
			90,
			80,
			0.0,
			1.5,
			1.0,
			4.0
		)
	)


	if not derived_stats.is_valid():
		return (
			"No se pudo crear Mage sintético."
		)


	var context := (
		ServerSkillDamageRules
		.build_resolution_context(
			definition,
			derived_stats
		)
	)


	if (
		context == null
		or
		not context.is_valid()
	):
		return (
			"No se pudo construir Damage Context."
		)


	if context.raw_damage != 90:
		return (
			"Magic Power 90 debe producir "
			+
			"Fire Ball Raw Damage 90."
		)


	if (
		context.school
		!=
		ServerDamageTaxonomy.SCHOOL_MAGICAL
	):
		return (
			"Fire Ball debe ser Magical."
		)


	if (
		context.element
		!=
		ServerDamageTaxonomy.ELEMENT_FIRE
	):
		return (
			"Fire Ball debe utilizar Fire."
		)


	if (
		context.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_DIRECT
	):
		return (
			"Fire Ball debe ser Direct."
		)


	if context.can_critical:
		return (
			"Fire Ball foundation "
			+
			"no debe criticar."
		)


	var current_result := (
		ServerDamageResolver.resolve(
			context,
			current_target_defense
		)
	)


	if (
		current_result == null
		or
		not current_result.is_valid()
	):
		return (
			"No se pudo resolver Fire Ball "
			+
			"contra target actual."
		)


	# Training Goblin actual:
	#
	# MR 0
	# Fire Resistance 0
	#
	# 90 → 90.

	if current_result.school_rating != 0:
		return (
			"Training target debe tener MR 0."
		)


	if current_result.element_rating != 0:
		return (
			"Training target debe tener "
			+
			"Fire Resistance 0."
		)


	if current_result.final_damage != 90:
		return (
			"Fire Ball sin resistencias "
			+
			"debe conservar Damage 90."
		)


	var resistant_result := (
		ServerDamageResolver.resolve(
			context,
			resistant_target_defense
		)
	)


	if (
		resistant_result == null
		or
		not resistant_result.is_valid()
	):
		return (
			"No se pudo resolver Fire Ball "
			+
			"contra target resistente."
		)


	# Raw 90
	#
	# MR 80:
	#
	# floor(90000 / 1080)
	# = 83
	#
	# Fire 50:
	#
	# floor(83000 / 1050)
	# = 79

	if resistant_result.school_rating != 80:
		return (
			"Fire Ball debe consumir MR 80."
		)


	if resistant_result.post_school_damage != 83:
		return (
			"Fire Ball con MR 80 "
			+
			"debe producir 83 tras School."
		)


	if resistant_result.element_rating != 50:
		return (
			"Fire Ball debe consumir "
			+
			"Fire Resistance 50."
		)


	if resistant_result.final_damage != 79:
		return (
			"Fire Ball resistente "
			+
			"debe producir Final Damage 79."
		)


	return ""


# =========================================================
# POISON
# =========================================================

static func _validate_poison(
	current_target_defense: ServerDamageDefenseProfile,
	resistant_target_defense: ServerDamageDefenseProfile
) -> String:
	var definition := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.POISON_ID
		)
	)


	if definition == null:
		return (
			"No se pudo resolver Poison."
		)


	var derived_stats := (
		ServerCharacterDerivedStatsState.new(
			"archer",
			0,
			10,
			0,
			184,
			148,
			0,
			0,
			93,
			15,
			15,
			0.0,
			1.5,
			1.0,
			4.0
		)
	)


	if not derived_stats.is_valid():
		return (
			"No se pudo crear Archer sintético."
		)


	var context := (
		ServerSkillPeriodicDamageRules
		.build_tick_resolution_context(
			definition,
			derived_stats
		)
	)


	if (
		context == null
		or
		not context.is_valid()
	):
		return (
			"No se pudo construir "
			+
			"Periodic Damage Context."
		)


	if context.raw_damage != 18:
		return (
			"Physical Power 93 debe producir "
			+
			"Poison Raw Damage 18."
		)


	if (
		context.school
		!=
		ServerDamageTaxonomy.SCHOOL_MAGICAL
	):
		return (
			"Poison debe ser Magical."
		)


	if (
		context.element
		!=
		ServerDamageTaxonomy.ELEMENT_POISON
	):
		return (
			"Poison debe utilizar "
			+
			"Poison Element."
		)


	if (
		context.delivery
		!=
		ServerDamageTaxonomy.DELIVERY_PERIODIC
	):
		return (
			"Poison debe ser Periodic."
		)


	if context.can_critical:
		return (
			"Poison foundation "
			+
			"no debe criticar por tick."
		)


	var current_result := (
		ServerDamageResolver.resolve(
			context,
			current_target_defense
		)
	)


	if (
		current_result == null
		or
		not current_result.is_valid()
	):
		return (
			"No se pudo resolver Poison "
			+
			"contra target actual."
		)


	if current_result.final_damage != 18:
		return (
			"Poison sin resistencias "
			+
			"debe conservar Damage 18."
		)


	var resistant_result := (
		ServerDamageResolver.resolve(
			context,
			resistant_target_defense
		)
	)


	if (
		resistant_result == null
		or
		not resistant_result.is_valid()
	):
		return (
			"No se pudo resolver Poison "
			+
			"contra target resistente."
		)


	# Raw 18
	#
	# MR 80:
	# floor(18000 / 1080)
	# = 16
	#
	# Poison 30:
	# floor(16000 / 1030)
	# = 15

	if resistant_result.school_rating != 80:
		return (
			"Poison debe consumir MR 80."
		)


	if resistant_result.post_school_damage != 16:
		return (
			"Poison con MR 80 "
			+
			"debe producir 16 tras School."
		)


	if resistant_result.element_rating != 30:
		return (
			"Poison debe consumir "
			+
			"Poison Resistance 30."
		)


	if resistant_result.final_damage != 15:
		return (
			"Poison resistente "
			+
			"debe producir Final Damage 15."
		)


	return ""


# =========================================================
# CURRENT TRAINING TARGET
# =========================================================

static func _build_current_target_defense() -> ServerDamageDefenseProfile:
	var definition := (
		WorldMobDefinition.create(
			"combat_damage_current",
			"Combat Damage Current",
			1,
			5000,
			0,
			5.0,

			# Armor
			100
		)
	)


	if (
		definition == null
		or
		not definition.is_valid()
	):
		return null


	return (
		ServerMobDamageDefenseProfileResolver
		.resolve(
			definition
		)
	)


# =========================================================
# RESISTANT TARGET
# =========================================================

static func _build_resistant_target_defense() -> ServerDamageDefenseProfile:
	var definition := (
		WorldMobDefinition.create(
			"combat_damage_resistant",
			"Combat Damage Resistant",
			1,
			5000,
			0,
			5.0,

			# Armor
			100,

			# Magic Resistance
			80,

			# Fire
			50,

			# Cold
			0,

			# Lightning
			0,

			# Poison
			30
		)
	)


	if (
		definition == null
		or
		not definition.is_valid()
	):
		return null


	return (
		ServerMobDamageDefenseProfileResolver
		.resolve(
			definition
		)
	)
