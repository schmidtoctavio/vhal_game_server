extends Node


# =========================================================
# REFERENCIAS
# =========================================================

@onready var game_server: GameServer = (
	$GameServer
)


# =========================================================
# START
# =========================================================

func _ready() -> void:
	if game_server == null:
		push_error(
			"ServerMain | No existe GameServer."
		)


		get_tree().quit(
			1
		)


		return


	var result := game_server.start()


	if result != OK:
		push_error(
			"ServerMain | No se pudo iniciar el servidor."
		)


		get_tree().quit(
			result
		)


		return


	print(
		"ServerMain | VHAL Game Server iniciado."
	)
