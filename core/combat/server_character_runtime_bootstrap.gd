class_name ServerCharacterRuntimeBootstrap
extends RefCounted


# =========================================================
# DEFAULTS TEMPORALES DE VITALS
#
# Estos valores todavía representan Foundation.
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
# Desde F21 el ownership ya NO nace del catálogo completo.
#
# learned_skill_ids proviene del ownership durable del
# personaje almacenado en Laravel/MySQL y transportado
# mediante el game-session ticket.
#
# El Game Server sigue validando semánticamente cada ID
# contra ServerSkillCatalog.
# =========================================================

static func create_skill_runtime(
	learned_skill_ids: PackedStringArray = PackedStringArray()
) -> ServerSkillRuntimeState:
	var skill_runtime := (
		ServerSkillRuntimeState.new()
	)


	for skill_id: String in learned_skill_ids:
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
