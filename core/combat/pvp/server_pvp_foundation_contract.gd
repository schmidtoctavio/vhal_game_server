class_name ServerPvpFoundationContract
extends RefCounted


static func validate_contract() -> String:
	var entity_ref_error := (
		ServerCombatEntityRef
		.validate_contract()
	)


	if not entity_ref_error.is_empty():
		return (
			"Combat Entity Ref inválido: "
			+
			entity_ref_error
		)


	var policy_error := (
		ServerPvpPolicy
		.validate_contract()
	)


	if not policy_error.is_empty():
		return (
			"PvP Policy inválida: "
			+
			policy_error
		)


	return ""
