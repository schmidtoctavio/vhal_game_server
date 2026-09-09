class_name ServerCombatEntityRef
extends RefCounted


# =========================================================
# PLAYER ENTITY REF
# =========================================================

const PLAYER_PREFIX: String = "player:"

const MAX_ENTITY_ID_LENGTH: int = 96


# =========================================================
# PLAYER
# =========================================================

static func make_player_entity_id(
	peer_id: int
) -> String:
	if peer_id <= 1:
		return ""


	return (
		PLAYER_PREFIX
		+
		str(peer_id)
	)


static func is_player_entity_id(
	entity_id: String
) -> bool:
	var normalized := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	if not normalized.begins_with(
		PLAYER_PREFIX
	):
		return false


	return (
		get_player_peer_id(
			normalized
		)
		>
		1
	)


static func get_player_peer_id(
	entity_id: String
) -> int:
	var normalized := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	if not normalized.begins_with(
		PLAYER_PREFIX
	):
		return -1


	var raw_peer_id := (
		normalized.substr(
			PLAYER_PREFIX.length()
		)
	)


	if raw_peer_id.is_empty():
		return -1


	if not raw_peer_id.is_valid_int():
		return -1


	var peer_id := int(
		raw_peer_id
	)


	if peer_id <= 1:
		return -1


	return peer_id


# =========================================================
# MOB
# =========================================================

static func is_mob_entity_id(
	entity_id: String
) -> bool:
	var normalized := (
		entity_id
		.strip_edges()
		.to_lower()
	)


	if normalized.is_empty():
		return false


	if (
		normalized.length()
		>
		MAX_ENTITY_ID_LENGTH
	):
		return false


	return not normalized.begins_with(
		PLAYER_PREFIX
	)


# =========================================================
# CONTRACT
# =========================================================

static func validate_contract() -> String:
	var player_ref := (
		make_player_entity_id(
			12345
		)
	)


	if player_ref != "player:12345":
		return (
			"Player Entity Ref no produjo player:12345."
		)


	if not is_player_entity_id(
		player_ref
	):
		return (
			"Player Entity Ref válido no fue reconocido."
		)


	if get_player_peer_id(
		player_ref
	) != 12345:
		return (
			"Player Entity Ref no recuperó Peer ID."
		)


	if is_player_entity_id(
		"player:1"
	):
		return (
			"Server Peer ID no debe ser target PvP."
		)


	if is_player_entity_id(
		"player:abc"
	):
		return (
			"Player Entity Ref no numérico fue aceptado."
		)


	if not is_mob_entity_id(
		"mob_test_town_001"
	):
		return (
			"Mob Entity Ref dejó de ser reconocido."
		)


	if is_mob_entity_id(
		player_ref
	):
		return (
			"Player Entity Ref fue confundido con Mob."
		)


	return ""
