class_name WorldMovementSystem
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal movement_completed(
	peer_id: int,
	position: Vector3,
	rotation_y: float
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

const MOVE_SPEED: float = 4.0

const WAYPOINT_REACHED_DISTANCE: float = 0.001

const MIN_DIRECTION_LENGTH_SQUARED: float = 0.000001


# =========================================================
# DEPENDENCIAS
# =========================================================

var session_registry: WorldSessionRegistry = null


# =========================================================
# ESTADO
# =========================================================

var initialized: bool = false


# =========================================================
# SETUP
# =========================================================

func setup(
	registry: WorldSessionRegistry
) -> bool:
	if registry == null:
		return false


	session_registry = registry

	initialized = true


	print(
		"WorldMovementSystem | Inicializado",
		" | Velocidad: ",
		MOVE_SPEED
	)


	return true


# =========================================================
# SERVER TICK
# =========================================================

func _physics_process(
	delta: float
) -> void:
	if not initialized:
		return


	if session_registry == null:
		return


	if delta <= 0.0:
		return


	var sessions := (
		session_registry.get_all_sessions()
	)


	for session: PlayerWorldSession in sessions:
		if session == null:
			continue


		if not session.has_authorized_move_target:
			continue


		_advance_session(
			session,
			delta
		)


# =========================================================
# AVANZAR SESIÓN
# =========================================================

func _advance_session(
	session: PlayerWorldSession,
	delta: float
) -> void:
	if session.authorized_path.is_empty():
		session.clear_move_request()

		return


	var remaining_distance := (
		MOVE_SPEED
		*
		delta
	)


	while (
		remaining_distance > 0.0
		and
		session.has_authorized_move_target
	):
		if (
			session.authorized_path_index
			>=
			session.authorized_path.size()
		):
			_complete_movement(
				session
			)

			return


		var waypoint: Vector3 = (
			session.authorized_path[
				session.authorized_path_index
			]
		)


		var current_position_2d := Vector2(
			session.position.x,
			session.position.z
		)


		var waypoint_position_2d := Vector2(
			waypoint.x,
			waypoint.z
		)


		var distance_to_waypoint := (
			current_position_2d.distance_to(
				waypoint_position_2d
			)
		)


		if (
			distance_to_waypoint
			<=
			WAYPOINT_REACHED_DISTANCE
		):
			session.authorized_path_index += 1

			continue


		var direction := (
			waypoint_position_2d
			-
			current_position_2d
		)


		if (
			direction.length_squared()
			>
			MIN_DIRECTION_LENGTH_SQUARED
		):
			session.rotation_y = atan2(
				-direction.x,
				-direction.y
			)


		var step_distance := minf(
			remaining_distance,
			distance_to_waypoint
		)


		var next_position_2d := (
			current_position_2d.move_toward(
				waypoint_position_2d,
				step_distance
			)
		)


		# -------------------------------------------------
		# La navegación está horneada a Y = 0.3,
		# pero PlayerWorldSession conserva la altura
		# física del personaje.
		#
		# En esta etapa la autoridad de locomoción ocurre
		# sobre X/Z, igual que el PlayerActor actual.
		# -------------------------------------------------

		session.position = Vector3(
			next_position_2d.x,
			session.position.y,
			next_position_2d.y
		)


		remaining_distance -= (
			step_distance
		)


		if (
			step_distance
			>=
			distance_to_waypoint
			-
			WAYPOINT_REACHED_DISTANCE
		):
			session.authorized_path_index += 1


			if (
				session.authorized_path_index
				>=
				session.authorized_path.size()
			):
				_complete_movement(
					session
				)

				return


# =========================================================
# COMPLETAR MOVIMIENTO
# =========================================================

func _complete_movement(
	session: PlayerWorldSession
) -> void:
	var final_target := (
		session.authorized_move_target
	)


	session.position = Vector3(
		final_target.x,
		session.position.y,
		final_target.z
	)


	var completed_peer_id := (
		session.peer_id
	)


	var completed_position := (
		session.position
	)


	var completed_rotation_y := (
		session.rotation_y
	)


	session.clear_move_request()


	movement_completed.emit(
		completed_peer_id,
		completed_position,
		completed_rotation_y
	)
