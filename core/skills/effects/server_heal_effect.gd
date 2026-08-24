class_name ServerHealEffect
extends RefCounted


# =========================================================
# CONFIGURACIÓN TEMPORAL DE FOUNDATION
# =========================================================

const BASE_HEAL_AMOUNT: int = 20_000


# =========================================================
# APLICAR HEAL
# =========================================================

static func apply(
	vitals: ServerVitalsState
) -> int:
	if vitals == null:
		return 0


	if not vitals.is_valid():
		return 0


	return vitals.restore_hp(
		BASE_HEAL_AMOUNT
	)
