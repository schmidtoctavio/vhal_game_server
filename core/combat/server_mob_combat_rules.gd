class_name ServerMobCombatRules
extends RefCounted


static func distance_xz(
	origin: Vector3,
	target: Vector3
) -> float:
	return Vector2(
		origin.x,
		origin.z
	).distance_to(
		Vector2(
			target.x,
			target.z
		)
	)


static func can_aggro(
	definition: WorldMobDefinition,
	mob_position: Vector3,
	target_position: Vector3
) -> bool:
	if definition == null:
		return false


	if not definition.is_valid():
		return false


	if not definition.has_pve_combat_profile():
		return false


	return (
		distance_xz(
			mob_position,
			target_position
		)
		<=
		definition.aggro_radius
	)


static func is_in_attack_range(
	definition: WorldMobDefinition,
	mob_position: Vector3,
	target_position: Vector3
) -> bool:
	if definition == null:
		return false


	if not definition.has_pve_combat_profile():
		return false


	return (
		distance_xz(
			mob_position,
			target_position
		)
		<=
		definition.attack_range
	)


static func is_leash_broken(
	definition: WorldMobDefinition,
	spawn_position: Vector3,
	mob_position: Vector3,
	target_position: Vector3
) -> bool:
	if definition == null:
		return true


	if not definition.has_pve_combat_profile():
		return true


	var mob_distance_from_spawn := (
		distance_xz(
			spawn_position,
			mob_position
		)
	)


	var target_distance_from_spawn := (
		distance_xz(
			spawn_position,
			target_position
		)
	)


	return (
		mob_distance_from_spawn
		>
		definition.leash_radius

		or

		target_distance_from_spawn
		>
		definition.leash_radius
	)
