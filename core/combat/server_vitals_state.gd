class_name ServerVitalsState
extends RefCounted


# =========================================================
# ESTADO
# =========================================================

var max_hp: int = 1

var hp: int = 1


var max_mp: int = 0

var mp: int = 0


# =========================================================
# CONSTRUCTOR
# =========================================================

func _init(
	p_max_hp: int = 1,
	p_max_mp: int = 0
) -> void:
	configure(
		p_max_hp,
		p_max_mp
	)


# =========================================================
# CONFIGURAR
# =========================================================

func configure(
	p_max_hp: int,
	p_max_mp: int
) -> bool:
	if p_max_hp <= 0:
		return false


	if p_max_mp < 0:
		return false


	max_hp = p_max_hp

	hp = max_hp


	max_mp = p_max_mp

	mp = max_mp


	return true


# =========================================================
# VALIDACIÓN
# =========================================================

func is_valid() -> bool:
	return (
		max_hp > 0
		and
		hp >= 0
		and
		hp <= max_hp
		and
		max_mp >= 0
		and
		mp >= 0
		and
		mp <= max_mp
	)


# =========================================================
# HP
# =========================================================

func set_hp(
	value: int
) -> void:
	hp = clampi(
		value,
		0,
		max_hp
	)


func restore_hp(
	amount: int
) -> int:
	if amount <= 0:
		return 0


	var previous_hp := hp


	set_hp(
		hp + amount
	)


	return (
		hp
		-
		previous_hp
	)


# =========================================================
# MP
# =========================================================

func set_mp(
	value: int
) -> void:
	mp = clampi(
		value,
		0,
		max_mp
	)


func has_enough_mana(
	amount: int
) -> bool:
	if amount < 0:
		return false


	return (
		mp >= amount
	)


func spend_mana(
	amount: int
) -> bool:
	if amount < 0:
		return false


	if not has_enough_mana(
		amount
	):
		return false


	mp -= amount


	return true


func restore_mp(
	amount: int
) -> int:
	if amount <= 0:
		return 0


	var previous_mp := mp


	set_mp(
		mp + amount
	)


	return (
		mp
		-
		previous_mp
	)


# =========================================================
# SNAPSHOT
# =========================================================

func to_snapshot() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,

		"mp": mp,
		"max_mp": max_mp,
	}
