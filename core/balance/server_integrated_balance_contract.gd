class_name ServerIntegratedBalanceContract
extends RefCounted


# =========================================================
# FOUNDATION
# =========================================================

const LEVEL_ONE: int = 1

const LEVEL_HUNDRED: int = 100

const TRAINING_GOBLIN_ARMOR: int = 100


# =========================================================
# VALIDAR BALANCE INTEGRADO
# =========================================================

static func validate_contract() -> String:
	var class_profile_error := (
		_validate_class_profiles()
	)

	var damage_context_error := (
		ServerDamageResolutionContext
		.validate_contract()
	)

	var damage_defense_error := (
		ServerDamageDefenseProfile
		.validate_contract()
	)


	if not damage_defense_error.is_empty():
		return (
			"Damage Defense | "
			+
			damage_defense_error
		)


	var resistance_mitigation_error := (
		ServerResistanceMitigationRules
		.validate_contract()
	)


	if not resistance_mitigation_error.is_empty():
		return (
			"Resistance Mitigation | "
			+
			resistance_mitigation_error
		)


	var character_damage_defense_error := (
		ServerCharacterDamageDefenseProfileResolver
		.validate_contract()
	)


	if not character_damage_defense_error.is_empty():
		return (
			"Character Damage Defense | "
			+
			character_damage_defense_error
		)


	var mob_damage_defense_error := (
		ServerMobDamageDefenseProfileResolver
		.validate_contract()
	)


	if not mob_damage_defense_error.is_empty():
		return (
			"Mob Damage Defense | "
			+
			mob_damage_defense_error
		)


	if not damage_context_error.is_empty():
		return (
			"Damage Domain | "
			+
			damage_context_error
		)

	if not class_profile_error.is_empty():
		return (
			"Class Profiles | "
			+
			class_profile_error
		)


	var equipment_error := (
		_validate_equipment_and_combat()
	)


	if not equipment_error.is_empty():
		return (
			"Equipment / Combat | "
			+
			equipment_error
		)


	var enhancement_error := (
		_validate_enhancement_balance()
	)


	if not enhancement_error.is_empty():
		return (
			"Enhancement | "
			+
			enhancement_error
		)


	var skill_error := (
		_validate_skill_balance()
	)


	if not skill_error.is_empty():
		return (
			"Skills | "
			+
			skill_error
		)


	return ""


# =========================================================
# CLASS PROFILES
# =========================================================

static func _validate_class_profiles() -> String:
	var cases: Array[Dictionary] = [
		{
			"class_id": "warrior",
			"level": 1,
			"max_hp": 200,
			"max_mp": 60,
			"physical_power": 60,
			"magic_power": 10,
			"healing_power": 10,
		},
		{
			"class_id": "mage",
			"level": 1,
			"max_hp": 115,
			"max_mp": 295,
			"physical_power": 15,
			"magic_power": 90,
			"healing_power": 80,
		},
		{
			"class_id": "archer",
			"level": 1,
			"max_hp": 130,
			"max_mp": 130,
			"physical_power": 60,
			"magic_power": 15,
			"healing_power": 15,
		},
		{
			"class_id": "warrior",
			"level": 100,
			"max_hp": 992,
			"max_mp": 159,
			"physical_power": 258,
			"magic_power": 10,
			"healing_power": 10,
		},
		{
			"class_id": "mage",
			"level": 100,
			"max_hp": 610,
			"max_mp": 691,
			"physical_power": 114,
			"magic_power": 288,
			"healing_power": 179,
		},
		{
			"class_id": "archer",
			"level": 100,
			"max_hp": 724,
			"max_mp": 328,
			"physical_power": 258,
			"magic_power": 15,
			"healing_power": 15,
		},
	]


	for case_data: Dictionary in cases:
		var error := (
			_validate_class_profile_case(
				case_data
			)
		)


		if not error.is_empty():
			return error


	# -----------------------------------------------------
	# IDENTIDAD DE CLASE EN LEVEL 1
	# -----------------------------------------------------

	var warrior := (
		_build_derived_state(
			ServerClassStatsCatalog.WARRIOR_ID,
			LEVEL_ONE
		)
	)

	var mage := (
		_build_derived_state(
			ServerClassStatsCatalog.MAGE_ID,
			LEVEL_ONE
		)
	)

	var archer := (
		_build_derived_state(
			ServerClassStatsCatalog.ARCHER_ID,
			LEVEL_ONE
		)
	)


	if (
		warrior == null
		or
		mage == null
		or
		archer == null
	):
		return (
			"No se pudieron construir "
			+
			"los tres perfiles Level 1."
		)


	# Warrior conserva la mayor foundation de HP.

	if not (
		warrior.max_hp
		>
		archer.max_hp
		and
		archer.max_hp
		>
		mage.max_hp
	):
		return (
			"La identidad relativa de Max HP "
			+
			"Warrior > Archer > Mage cambió."
		)


	# Mage conserva la mayor foundation de MP.

	if not (
		mage.max_mp
		>
		archer.max_mp
		and
		archer.max_mp
		>
		warrior.max_mp
	):
		return (
			"La identidad relativa de Max MP "
			+
			"Mage > Archer > Warrior cambió."
		)


	# Mage domina Magic Power foundation.

	if not (
		mage.magic_power
		>
		archer.magic_power
		and
		archer.magic_power
		>
		warrior.magic_power
	):
		return (
			"La identidad relativa de Magic Power cambió."
		)


	# Mage domina Healing Power foundation.

	if not (
		mage.healing_power
		>
		archer.healing_power
		and
		archer.healing_power
		>
		warrior.healing_power
	):
		return (
			"La identidad relativa de Healing Power cambió."
		)


	# Archer conserva la mayor Attack Speed inicial.

	if not (
		archer.attack_speed_multiplier
		>
		warrior.attack_speed_multiplier
		and
		warrior.attack_speed_multiplier
		>
		mage.attack_speed_multiplier
	):
		return (
			"La identidad relativa de Attack Speed "
			+
			"Archer > Warrior > Mage cambió."
		)


	return ""


# =========================================================
# VALIDAR UN CLASS PROFILE
# =========================================================

static func _validate_class_profile_case(
	case_data: Dictionary
) -> String:
	var class_id := String(
		case_data.get(
			"class_id",
			""
		)
	)


	var level := int(
		case_data.get(
			"level",
			0
		)
	)


	var primary_stats := (
		_build_unallocated_primary(
			class_id,
			level
		)
	)


	if primary_stats == null:
		return (
			"No se pudo crear Primary Stats para "
			+
			class_id
			+
			" Level "
			+
			str(level)
			+
			"."
		)


	var derived_stats := (
		ServerCharacterDerivedStatsBootstrap
		.create_from_primary_stats(
			primary_stats
		)
	)


	if derived_stats == null:
		return (
			"No se pudo crear Derived Stats para "
			+
			class_id
			+
			" Level "
			+
			str(level)
			+
			"."
		)


	if not derived_stats.is_valid():
		return (
			"Derived Stats inválido para "
			+
			class_id
			+
			"."
		)


	if (
		derived_stats.max_hp
		!=
		int(
			case_data.get(
				"max_hp",
				-1
			)
		)
	):
		return (
			class_id
			+
			" Level "
			+
			str(level)
			+
			" alteró Max HP."
		)


	if (
		derived_stats.max_mp
		!=
		int(
			case_data.get(
				"max_mp",
				-1
			)
		)
	):
		return (
			class_id
			+
			" Level "
			+
			str(level)
			+
			" alteró Max MP."
		)


	if (
		derived_stats.physical_power
		!=
		int(
			case_data.get(
				"physical_power",
				-1
			)
		)
	):
		return (
			class_id
			+
			" Level "
			+
			str(level)
			+
			" alteró Physical Power."
		)


	if (
		derived_stats.magic_power
		!=
		int(
			case_data.get(
				"magic_power",
				-1
			)
		)
	):
		return (
			class_id
			+
			" Level "
			+
			str(level)
			+
			" alteró Magic Power."
		)


	if (
		derived_stats.healing_power
		!=
		int(
			case_data.get(
				"healing_power",
				-1
			)
		)
	):
		return (
			class_id
			+
			" Level "
			+
			str(level)
			+
			" alteró Healing Power."
		)


	if not is_zero_approx(
		derived_stats.critical_strike_chance
	):
		return (
			class_id
			+
			" obtuvo Critical Chance "
			+
			"fuera de la foundation actual."
		)


	if not is_equal_approx(
		derived_stats.critical_damage_multiplier,
		1.5
	):
		return (
			class_id
			+
			" alteró Critical Damage Multiplier."
		)


	if not is_equal_approx(
		derived_stats.movement_speed,
		4.0
	):
		return (
			class_id
			+
			" alteró Movement Speed foundation."
		)


	var class_definition := (
		ServerClassStatsCatalog.get_definition(
			class_id
		)
	)


	if class_definition == null:
		return (
			"No existe Class Definition para "
			+
			class_id
			+
			"."
		)


	var formula_agility := float(
		primary_stats.permanent_agility
	)


	var expected_attack_speed := (
		1.0
		+
		(
			class_definition.attack_speed_max_bonus
			*
			formula_agility
			/
			(
				formula_agility
				+
				class_definition
				.attack_speed_agility_half_saturation
			)
		)
	)


	if not is_equal_approx(
		derived_stats.attack_speed_multiplier,
		expected_attack_speed
	):
		return (
			class_id
			+
			" no respeta su fórmula de Attack Speed."
		)


	return ""


# =========================================================
# EQUIPMENT + BASIC ATTACK + ARMOR
# =========================================================

static func _validate_equipment_and_combat() -> String:
	var warrior_derived := (
		_build_derived_state(
			ServerClassStatsCatalog.WARRIOR_ID,
			LEVEL_ONE
		)
	)


	if warrior_derived == null:
		return (
			"No se pudo crear Warrior Level 1."
		)


	var cases: Array[Dictionary] = [
		{
			"label": "unarmed",
			"snapshot": _make_empty_equipment_snapshot(),
			"base_damage": 500,
			"pre_mitigation": 560,
			"post_mitigation": 509,
		},
		{
			"label": "bronze_sword_+0",
			"snapshot": _make_sword_snapshot(0),
			"base_damage": 1000,
			"pre_mitigation": 1060,
			"post_mitigation": 963,
		},
		{
			"label": "bronze_sword_+7",
			"snapshot": _make_sword_snapshot(7),
			"base_damage": 1150,
			"pre_mitigation": 1210,
			"post_mitigation": 1100,
		},
		{
			"label": "bronze_sword_+13",
			"snapshot": _make_sword_snapshot(13),
			"base_damage": 1500,
			"pre_mitigation": 1560,
			"post_mitigation": 1418,
		},
	]


	for case_data: Dictionary in cases:
		var profile := (
			ServerBasicAttackProfileResolver.resolve(
				case_data.get(
					"snapshot",
					{}
				)
			)
		)


		if profile.is_empty():
			return (
				"No se resolvió Basic Attack: "
				+
				String(
					case_data.get(
						"label",
						"?"
					)
				)
			)


		if (
			int(
				profile.get(
					"base_damage",
					0
				)
			)
			!=
			int(
				case_data.get(
					"base_damage",
					-1
				)
			)
		):
			return (
				String(
					case_data.get(
						"label",
						"?"
					)
				)
				+
				" alteró Base Damage."
			)


		var pre_mitigation := (
			ServerBasicAttackDamageRules
			.calculate_pre_mitigation_damage(
				profile,
				warrior_derived
			)
		)


		if (
			pre_mitigation
			!=
			int(
				case_data.get(
					"pre_mitigation",
					-1
				)
			)
		):
			return (
				String(
					case_data.get(
						"label",
						"?"
					)
				)
				+
				" alteró pre-mitigation damage."
			)


		var post_mitigation := (
			ServerPhysicalDamageMitigationRules
			.calculate_post_mitigation_damage(
				pre_mitigation,
				TRAINING_GOBLIN_ARMOR
			)
		)


		if (
			post_mitigation
			!=
			int(
				case_data.get(
					"post_mitigation",
					-1
				)
			)
		):
			return (
				String(
					case_data.get(
						"label",
						"?"
					)
				)
				+
				" alteró Armor Mitigation."
			)


	# -----------------------------------------------------
	# ATTACK SPEED DEBE ACELERAR EL ARMA
	# -----------------------------------------------------

	var sword_profile := (
		ServerBasicAttackProfileResolver.resolve(
			_make_sword_snapshot(
				0
			)
		)
	)


	var base_cooldown := float(
		sword_profile.get(
			"cooldown_duration_seconds",
			-1.0
		)
	)


	var effective_cooldown := (
		ServerBasicAttackSpeedRules
		.calculate_effective_cooldown_seconds(
			base_cooldown,
			warrior_derived.attack_speed_multiplier
		)
	)


	if (
		effective_cooldown <= 0.0
		or
		effective_cooldown >= base_cooldown
	):
		return (
			"Warrior Attack Speed no reduce "
			+
			"el cooldown efectivo del arma."
		)


	return ""


# =========================================================
# ENHANCEMENT BALANCE
# =========================================================

static func _validate_enhancement_balance() -> String:
	var sword_definition := (
		ServerItemCatalog.get_definition(
			"bronze_sword"
		)
	)


	var helmet_definition := (
		ServerItemCatalog.get_definition(
			"leather_helmet"
		)
	)


	if sword_definition.is_empty():
		return "Bronze Sword Definition inexistente."


	if helmet_definition.is_empty():
		return "Leather Helmet Definition inexistente."


	# -----------------------------------------------------
	# LAS CURVAS SON FLAT BONUS, NO PORCENTAJES
	# -----------------------------------------------------

	var sword_zero := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"bronze_sword",
				0
			),
			sword_definition
		)
	)

	var sword_seven := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"bronze_sword",
				7
			),
			sword_definition
		)
	)

	var sword_thirteen := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"bronze_sword",
				13
			),
			sword_definition
		)
	)


	if (
		sword_zero != 1000
		or
		sword_seven != 1150
		or
		sword_thirteen != 1500
	):
		return (
			"Bronze Sword Enhancement "
			+
			"alteró su curva flat de Weapon Damage."
		)


	var helmet_zero := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"leather_helmet",
				0
			),
			helmet_definition
		)
	)

	var helmet_seven := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"leather_helmet",
				7
			),
			helmet_definition
		)
	)

	var helmet_thirteen := (
		ServerEquipmentEnhancementRules
		.get_resolved_intrinsic_value(
			_make_equipment_item(
				"leather_helmet",
				13
			),
			helmet_definition
		)
	)


	if (
		helmet_zero != 20
		or
		helmet_seven != 27
		or
		helmet_thirteen != 46
	):
		return (
			"Leather Helmet Enhancement "
			+
			"alteró su curva flat de Armor Rating."
		)


	# -----------------------------------------------------
	# MONOTONICIDAD
	# -----------------------------------------------------

	var sword_curve_error := (
		_validate_monotonic_enhancement_curve(
			sword_definition,
			"Bronze Sword"
		)
	)


	if not sword_curve_error.is_empty():
		return sword_curve_error


	var helmet_curve_error := (
		_validate_monotonic_enhancement_curve(
			helmet_definition,
			"Leather Helmet"
		)
	)


	if not helmet_curve_error.is_empty():
		return helmet_curve_error


	# -----------------------------------------------------
	# REQUIREMENT GROWTH
	# -----------------------------------------------------

	var sword_strength_bonus := (
		ServerEquipmentEnhancementRules
		.get_requirement_bonus_at_level(
			sword_definition,
			ServerEquipmentUsageRules.REQUIREMENT_STRENGTH,
			13
		)
	)


	if sword_strength_bonus != 15:
		return (
			"Bronze Sword +13 dejó de agregar "
			+
			"15 STR de requirement."
		)


	var warrior_primary := (
		_build_unallocated_primary(
			ServerClassStatsCatalog.WARRIOR_ID,
			LEVEL_ONE
		)
	)


	if warrior_primary == null:
		return (
			"No se pudo crear Warrior para "
			+
			"Equipment Usage Audit."
		)


	var sword_zero_usage := (
		ServerEquipmentUsageRules.validate_item_usage(
			_make_equipment_item(
				"bronze_sword",
				0
			),
			warrior_primary
		)
	)


	if not sword_zero_usage.is_empty():
		return (
			"Warrior base no puede usar Bronze Sword +0: "
			+
			sword_zero_usage
		)


	var sword_thirteen_usage := (
		ServerEquipmentUsageRules.validate_item_usage(
			_make_equipment_item(
				"bronze_sword",
				13
			),
			warrior_primary
		)
	)


	if (
		sword_thirteen_usage
		!=
		"insufficient_strength"
	):
		return (
			"Bronze Sword +13 debía exigir "
			+
			"STR adicional al Warrior base."
		)


	return ""


# =========================================================
# MONOTONICIDAD DE ENHANCEMENT
# =========================================================

static func _validate_monotonic_enhancement_curve(
	definition: Dictionary,
	label: String
) -> String:
	var max_level := (
		ServerEquipmentEnhancementRules
		.get_max_enhancement_level(
			definition
		)
	)


	if max_level <= 0:
		return (
			label
			+
			" no posee max Enhancement válido."
		)


	var previous_bonus := (
		ServerEquipmentEnhancementRules
		.get_intrinsic_bonus_at_level(
			definition,
			0
		)
	)


	if previous_bonus != 0:
		return (
			label
			+
			" debe comenzar con bonus 0 en +0."
		)


	for enhancement_level: int in range(
		1,
		max_level + 1
	):
		var current_bonus := (
			ServerEquipmentEnhancementRules
			.get_intrinsic_bonus_at_level(
				definition,
				enhancement_level
			)
		)


		if current_bonus <= previous_bonus:
			return (
				label
				+
				" dejó de crecer entre +"
				+
				str(enhancement_level - 1)
				+
				" y +"
				+
				str(enhancement_level)
				+
				"."
			)


		previous_bonus = current_bonus


	return ""


# =========================================================
# SKILL BALANCE
# =========================================================

static func _validate_skill_balance() -> String:
	var heal_definition := (
		ServerSkillCatalog.get_definition(
			ServerSkillCatalog.HEAL_ID
		)
	)


	if heal_definition == null:
		return "Heal Definition inexistente."


	var mage_derived := (
		_build_derived_state(
			ServerClassStatsCatalog.MAGE_ID,
			LEVEL_ONE
		)
	)


	if mage_derived == null:
		return (
			"No se pudo crear Mage para Skill Scaling."
		)


	var mage_heal := (
		ServerSkillScalingResolver
		.calculate_effect_value(
			heal_definition.scaling_profile,
			mage_derived
		)
	)


	if mage_heal != 80:
		return (
			"Heal de Mage Level 1 dejó de resolver 80."
		)


	var warrior_derived := (
		_build_derived_state(
			ServerClassStatsCatalog.WARRIOR_ID,
			LEVEL_ONE
		)
	)


	if warrior_derived == null:
		return (
			"No se pudo crear Warrior para Skill Scaling."
		)


	var warrior_heal := (
		ServerSkillScalingResolver
		.calculate_effect_value(
			heal_definition.scaling_profile,
			warrior_derived
		)
	)


	if warrior_heal != 10:
		return (
			"Heal de Warrior Level 1 dejó de resolver 10."
		)


	# -----------------------------------------------------
	# BALANCE ACTUAL DE LEARNING
	# -----------------------------------------------------

	var learning_error := (
		_validate_learning_balance_values()
	)


	if not learning_error.is_empty():
		return learning_error


	# -----------------------------------------------------
	# TODA SKILL DEBE SER ALCANZABLE EN SU MINIMUM LEVEL
	#
	# Desde el perfil base de cada Class permitida,
	# los puntos disponibles a ese Level deben alcanzar
	# para cubrir el déficit de Primary Requirements.
	# -----------------------------------------------------

	for skill_id: String in (
		ServerSkillLearningCatalog.get_all_skill_ids()
	):
		var learning_definition := (
			ServerSkillLearningCatalog.get_definition(
				skill_id
			)
		)


		if learning_definition == null:
			return (
				"Learning Definition inexistente: "
				+
				skill_id
			)


		if not learning_definition.meets_level_requirement(
			learning_definition.minimum_level
		):
			return (
				skill_id
				+
				" rechaza su propio minimum_level."
			)


		if (
			learning_definition.minimum_level > 1
			and
			learning_definition.meets_level_requirement(
				learning_definition.minimum_level - 1
			)
		):
			return (
				skill_id
				+
				" acepta Level por debajo "
				+
				"de su minimum_level."
			)


		for class_id: String in (
			learning_definition.allowed_class_ids
		):
			var primary_stats := (
				_build_unallocated_primary(
					class_id,
					learning_definition.minimum_level
				)
			)


			if primary_stats == null:
				return (
					skill_id
					+
					" no pudo construir Class "
					+
					class_id
					+
					" en minimum_level."
				)


			var required_points := (
				_get_required_allocation_points(
					learning_definition
					.primary_stat_requirements,
					primary_stats
				)
			)


			if required_points < 0:
				return (
					skill_id
					+
					" produjo déficit de Stats inválido."
				)


			if (
				required_points
				>
				primary_stats.unspent_points
			):
				return (
					skill_id
					+
					" es inalcanzable para "
					+
					class_id
					+
					" en su minimum_level."
				)


	# -----------------------------------------------------
	# RESET-SAFE USAGE
	# -----------------------------------------------------

	var heal_learning := (
		ServerSkillLearningCatalog.get_definition(
			ServerSkillCatalog.HEAL_ID
		)
	)


	if heal_learning == null:
		return (
			"No existe Heal Learning Definition."
		)


	var warrior_level_five := (
		_build_unallocated_primary(
			ServerClassStatsCatalog.WARRIOR_ID,
			5
		)
	)


	if warrior_level_five == null:
		return (
			"No se pudo crear Warrior Level 5."
		)


	var learning_stat_error := (
		heal_learning
		.validate_primary_stat_requirements(
			warrior_level_five
		)
	)


	if (
		learning_stat_error
		!=
		"energy_requirement_not_met"
	):
		return (
			"Warrior Level 5 base debía requerir "
			+
			"Energy adicional para aprender Heal."
		)


	var runtime := (
		ServerSkillRuntimeState.new()
	)


	if not runtime.learn_skill(
		ServerSkillCatalog.HEAL_ID
	):
		return (
			"No se pudo preparar ownership "
			+
			"de Heal para Reset-Safe Audit."
		)


	var usage_error := (
		ServerSkillUsageRules.validate_cast_usage(
			heal_definition,
			runtime
		)
	)


	if not usage_error.is_empty():
		return (
			"Skill aprendida volvió a exigir "
			+
			"Learning Requirements durante Usage: "
			+
			usage_error
		)


	return ""


# =========================================================
# BALANCE ACTUAL DE LEARNING
# =========================================================

static func _validate_learning_balance_values() -> String:
	var fire_ball := (
		ServerSkillLearningCatalog.get_definition(
			ServerSkillCatalog.FIRE_BALL_ID
		)
	)

	var poison := (
		ServerSkillLearningCatalog.get_definition(
			ServerSkillCatalog.POISON_ID
		)
	)

	var heal := (
		ServerSkillLearningCatalog.get_definition(
			ServerSkillCatalog.HEAL_ID
		)
	)


	if (
		fire_ball == null
		or
		poison == null
		or
		heal == null
	):
		return (
			"No se pudieron resolver "
			+
			"Learning Definitions foundation."
		)


	if (
		fire_ball.minimum_level != 10
		or
		not fire_ball.is_class_allowed(
			ServerClassStatsCatalog.MAGE_ID
		)
		or
		fire_ball
		.primary_stat_requirements
		.minimum_energy
		!=
		50
	):
		return (
			"Fire Ball Learning Balance cambió."
		)


	if (
		poison.minimum_level != 10
		or
		not poison.is_class_allowed(
			ServerClassStatsCatalog.ARCHER_ID
		)
		or
		poison
		.primary_stat_requirements
		.minimum_agility
		!=
		45
	):
		return (
			"Poison Learning Balance cambió."
		)


	if (
		heal.minimum_level != 5
		or
		heal
		.primary_stat_requirements
		.minimum_energy
		!=
		20
	):
		return (
			"Heal Learning Balance cambió."
		)


	for class_id: String in (
		ServerClassStatsCatalog.get_all_class_ids()
	):
		if not heal.is_class_allowed(
			class_id
		):
			return (
				"Heal dejó de permitir Class: "
				+
				class_id
			)


	return ""


# =========================================================
# PUNTOS NECESARIOS PARA CUMPLIR REQUIREMENTS
# =========================================================

static func _get_required_allocation_points(
	requirements: ServerSkillPrimaryStatRequirements,
	primary_stats: ServerCharacterPrimaryStatsState
) -> int:
	if requirements == null:
		return -1


	if primary_stats == null:
		return -1


	if not requirements.is_valid():
		return -1


	if not primary_stats.is_valid():
		return -1


	return (
		maxi(
			0,
			requirements.minimum_strength
			-
			primary_stats.permanent_strength
		)
		+
		maxi(
			0,
			requirements.minimum_agility
			-
			primary_stats.permanent_agility
		)
		+
		maxi(
			0,
			requirements.minimum_vitality
			-
			primary_stats.permanent_vitality
		)
		+
		maxi(
			0,
			requirements.minimum_energy
			-
			primary_stats.permanent_energy
		)
	)


# =========================================================
# BUILD PRIMARY SIN ALLOCATION
# =========================================================

static func _build_unallocated_primary(
	class_id: String,
	level: int
) -> ServerCharacterPrimaryStatsState:
	var definition := (
		ServerClassStatsCatalog.get_definition(
			class_id
		)
	)


	if definition == null:
		return null


	if level < 1:
		return null


	var level_points := (
		ServerPrimaryStatBudgetRules.get_level_points(
			level,
			definition.stat_points_per_level
		)
	)


	var reset_points := (
		ServerPrimaryStatBudgetRules.get_reset_points(
			0
		)
	)


	if (
		level_points < 0
		or
		reset_points < 0
	):
		return null


	var total_points := (
		level_points
		+
		reset_points
	)


	var state := (
		ServerCharacterPrimaryStatsState.new(
			class_id,
			0,
			level,
			0,
			definition.starting_strength,
			definition.starting_agility,
			definition.starting_vitality,
			definition.starting_energy,
			0,
			0,
			0,
			0,
			definition.stat_points_per_level,
			ServerPrimaryStatBudgetRules.RESET_STAT_POINTS,
			level_points,
			reset_points,
			0,
			total_points,
			0,
			total_points
		)
	)


	if not state.is_valid():
		return null


	return state


# =========================================================
# BUILD DERIVED SIN EQUIPMENT
# =========================================================

static func _build_derived_state(
	class_id: String,
	level: int
) -> ServerCharacterDerivedStatsState:
	var primary_stats := (
		_build_unallocated_primary(
			class_id,
			level
		)
	)


	if primary_stats == null:
		return null


	return (
		ServerCharacterDerivedStatsBootstrap
		.create_from_primary_stats(
			primary_stats
		)
	)


# =========================================================
# ITEMS / SNAPSHOTS SINTÉTICOS
# =========================================================

static func _make_equipment_item(
	item_id: String,
	enhancement_level: int
) -> Dictionary:
	return {
		"uid": (
			"f22-k-"
			+
			item_id
			+
			"-"
			+
			str(enhancement_level)
		),

		"item_id": item_id,

		"quantity": 1,

		"state": {
			"enhancement_level": enhancement_level,
		},
	}


static func _make_empty_equipment_snapshot() -> Dictionary:
	return {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [],
	}


static func _make_sword_snapshot(
	enhancement_level: int
) -> Dictionary:
	var item := (
		_make_equipment_item(
			"bronze_sword",
			enhancement_level
		)
	)


	item[
		"equipment_slot"
	] = "main_hand"


	return {
		"account_id": 1,

		"character_id": 1,

		"container": "equipment",

		"items": [
			item,
		],
	}
