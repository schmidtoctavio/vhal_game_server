class_name ServerPrimaryStatBudgetRules
extends RefCounted


# =========================================================
# RESET POINTS
# =========================================================
#
# Contrato F22 aprobado.
#
# Reset todavía NO está implementado.
# Esta constante solamente permite validar correctamente
# el budget durable recibido desde Backend.
# =========================================================

const RESET_STAT_POINTS: int = 350


# =========================================================
# LEVEL POINTS
# =========================================================

static func get_level_points(
	level: int,
	stat_points_per_level: int
) -> int:
	if level < 1:
		return -1


	if stat_points_per_level <= 0:
		return -1


	return (
		(level - 1)
		*
		stat_points_per_level
	)


# =========================================================
# RESET POINTS
# =========================================================

static func get_reset_points(
	reset_count: int
) -> int:
	if reset_count < 0:
		return -1


	return (
		reset_count
		*
		RESET_STAT_POINTS
	)
