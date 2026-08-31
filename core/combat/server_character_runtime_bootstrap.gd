class_name ServerCharacterRuntimeBootstrap
extends RefCounted


# =========================================================
# VITALES
#
# Desde F22-F2 los máximos ya NO nacen de defaults
# hardcodeados.
#
# Derived Stats es la fuente autoritativa runtime para:
#
# - Max HP
# - Max MP
#
# HP / MP actuales continúan perteneciendo a
# ServerVitalsState.
# =========================================================

static func create_vitals(
	derived_stats: ServerCharacterDerivedStatsState
) -> ServerVitalsState:
	if derived_stats == null:
		return null


	if not derived_stats.is_valid():
		return null


	return ServerVitalsState.new(
		derived_stats.max_hp,
		derived_stats.max_mp
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
