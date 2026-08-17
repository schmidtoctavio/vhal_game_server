extends Node


# =========================================================
# REFERENCIAS
# =========================================================

@onready var game_server: GameServer = (
	$GameServer
)

@onready var backend_ticket_validator: BackendTicketValidator = (
	$BackendTicketValidator
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

	if backend_ticket_validator == null:
		push_error(
			"ServerMain | No existe BackendTicketValidator."
		)


		get_tree().quit(
			2
		)


		return


	if not backend_ticket_validator.is_configured():
		push_error(
			"ServerMain | BackendTicketValidator no configurado."
		)


		get_tree().quit(
			3
		)


		return

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
