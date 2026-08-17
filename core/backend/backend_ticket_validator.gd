class_name BackendTicketValidator
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal ticket_validated(
	peer_id: int,
	account_id: int,
	character_data: Dictionary
)

signal ticket_rejected(
	peer_id: int,
	message: String
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

const DEFAULT_BACKEND_URL: String = (
	"http://127.0.0.1:8080"
)

const BACKEND_URL_ENV: String = (
	"VHAL_BACKEND_URL"
)

const INTERNAL_KEY_ENV: String = (
	"GAME_SERVER_INTERNAL_KEY"
)

const CONSUME_TICKET_PATH: String = (
	"/api/internal/game-session/tickets/consume"
)


# =========================================================
# ESTADO
# =========================================================

var backend_url: String = (
	DEFAULT_BACKEND_URL
)

var internal_key: String = ""


# =========================================================
# CICLO DE VIDA
# =========================================================

func _ready() -> void:
	_load_runtime_config()


# =========================================================
# CONFIGURACIÓN DE RUNTIME
# =========================================================

func _load_runtime_config() -> void:
	var configured_backend_url := (
		OS.get_environment(
			BACKEND_URL_ENV
		).strip_edges()
	)


	if not configured_backend_url.is_empty():
		backend_url = (
			configured_backend_url
		)


	backend_url = (
		backend_url.trim_suffix("/")
	)


	internal_key = (
		OS.get_environment(
			INTERNAL_KEY_ENV
		).strip_edges()
	)


	if internal_key.is_empty():
		push_error(
			"BackendTicketValidator | Falta GAME_SERVER_INTERNAL_KEY."
		)

		return


	print(
		"BackendTicketValidator | Configuración cargada | Backend: ",
		backend_url
	)


# =========================================================
# ESTADO
# =========================================================

func is_configured() -> bool:
	return (
		not backend_url.is_empty()
		and
		not internal_key.is_empty()
	)


# =========================================================
# VALIDAR TICKET
# =========================================================

func validate_ticket(
	peer_id: int,
	ticket: String
) -> void:
	if peer_id <= 1:
		ticket_rejected.emit(
			peer_id,
			"Peer inválido."
		)

		return


	var normalized_ticket := (
		ticket.strip_edges()
	)


	if normalized_ticket.length() != 64:
		ticket_rejected.emit(
			peer_id,
			"Formato de ticket inválido."
		)

		return


	if not is_configured():
		ticket_rejected.emit(
			peer_id,
			"Game Server sin configuración interna."
		)

		return


	# -----------------------------------------------------
	# Usamos un HTTPRequest independiente por validación.
	#
	# Varios peers pueden intentar autenticarse al mismo
	# tiempo y un único HTTPRequest no admite requests
	# simultáneos.
	# -----------------------------------------------------

	var http_request := HTTPRequest.new()


	add_child(
		http_request
	)


	http_request.request_completed.connect(
		_on_request_completed.bind(
			http_request,
			peer_id
		)
	)


	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		(
			"X-VHAL-Game-Server-Key: "
			+
			internal_key
		),
	])


	var body := JSON.stringify({
		"ticket": normalized_ticket,
	})


	var request_error := (
		http_request.request(
			_get_consume_ticket_url(),
			headers,
			HTTPClient.METHOD_POST,
			body
		)
	)


	if request_error != OK:
		http_request.queue_free()


		ticket_rejected.emit(
			peer_id,
			"No se pudo iniciar la validación del ticket."
		)


# =========================================================
# RESULTADO HTTP
# =========================================================

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int
) -> void:
	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		ticket_rejected.emit(
			peer_id,
			"Laravel no respondió correctamente."
		)

		return


	var response_text := (
		body.get_string_from_utf8()
	)


	var parsed_response: Variant = (
		JSON.parse_string(
			response_text
		)
	)


	if (
		typeof(
			parsed_response
		)
		!=
		TYPE_DICTIONARY
	):
		ticket_rejected.emit(
			peer_id,
			"Respuesta inválida del backend."
		)

		return


	var response: Dictionary = (
		parsed_response
	)


	if (
		response_code
		!=
		200
		or
		not bool(
			response.get(
				"ok",
				false
			)
		)
	):
		var message := str(
			response.get(
				"message",
				"Ticket rechazado."
			)
		)


		ticket_rejected.emit(
			peer_id,
			message
		)

		return


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if (
		typeof(
			data_value
		)
		!=
		TYPE_DICTIONARY
	):
		ticket_rejected.emit(
			peer_id,
			"Respuesta del backend sin datos."
		)

		return


	var data: Dictionary = (
		data_value
	)


	var account_id := int(
		data.get(
			"account_id",
			0
		)
	)


	var character_value: Variant = (
		data.get(
			"character",
			null
		)
	)


	if (
		account_id
		<=
		0
		or
		typeof(
			character_value
		)
		!=
		TYPE_DICTIONARY
	):
		ticket_rejected.emit(
			peer_id,
			"Identidad inválida devuelta por el backend."
		)

		return


	var character_data: Dictionary = (
		character_value
	)


	ticket_validated.emit(
		peer_id,
		account_id,
		character_data
	)


# =========================================================
# URL
# =========================================================

func _get_consume_ticket_url() -> String:
	return (
		backend_url
		+
		CONSUME_TICKET_PATH
	)
