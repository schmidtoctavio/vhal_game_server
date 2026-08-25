class_name ServerCharacterRuntimeBootstrap
extends RefCounted


# =========================================================
# DEFAULTS TEMPORALES F16
#
# Estos valores mantienen paridad con DebugPlayerStateFactory
# del cliente.
#
# NO representan balance definitivo.
# =========================================================

const DEFAULT_MAX_HP: int = 100000

const DEFAULT_MAX_MP: int = 350


# =========================================================
# VITALES
# =========================================================

static func create_vitals() -> ServerVitalsState:
	return ServerVitalsState.new(
		DEFAULT_MAX_HP,
		DEFAULT_MAX_MP
	)


# =========================================================
# SKILLS
#
# Temporalmente todos los personajes reciben las tres
# skills que ya existen en el cliente.
#
# Más adelante la propiedad real de skills vendrá de
# progresión/persistencia.
# =========================================================

static func create_skill_runtime() -> ServerSkillRuntimeState:
	var skill_runtime := (
		ServerSkillRuntimeState.new()
	)


	for skill_id: String in ServerSkillCatalog.get_all_skill_ids():
		if not skill_runtime.learn_skill(
			skill_id
		):
			return null


	return skill_runtime

# =========================================================
# BASIC ATTACK RUNTIME
# =========================================================

static func create_basic_attack_runtime() -> ServerBasicAttackRuntimeState:
	return ServerBasicAttackRuntimeState.new()
