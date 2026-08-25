class_name BackendCharacterProgressionRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal progression_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	previous_level: int,
	previous_experience: int,
	level: int,
	experience: int,
	idempotent: bool
)


signal progression_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	response_code: int,
	message: String,
	current_progression: Dictionary
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


var backend_url: String = (
	DEFAULT_BACKEND_URL
)

var internal_key: String = ""

var pending_peers: Dictionary = {}


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	_load_runtime_config()


# =========================================================
# CONFIG
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
			(
				"BackendCharacterProgressionRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		(
			"BackendCharacterProgressionRepository"
			+
			" | Configuración cargada | Backend: "
		),
		backend_url
	)


func is_configured() -> bool:
	return (
		not backend_url.is_empty()
		and
		not internal_key.is_empty()
	)


# =========================================================
# URL
# =========================================================

func _get_progression_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/%d/characters/%d/progression"
		%
		[
			account_id,
			character_id,
		]
	)


# =========================================================
# PERSISTIR
# =========================================================

func persist_progression(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_level: int,
	expected_experience: int,
	next_level: int,
	next_experience: int
) -> Error:
	if (
		peer_id <= 1
		or
		account_id <= 0
		or
		character_id <= 0
	):
		return ERR_INVALID_PARAMETER


	if not ServerCharacterProgressionRules.is_state_valid(
		expected_level,
		expected_experience
	):
		return ERR_INVALID_PARAMETER


	if not ServerCharacterProgressionRules.is_state_valid(
		next_level,
		next_experience
	):
		return ERR_INVALID_PARAMETER


	if not is_configured():
		return ERR_UNAVAILABLE


	if pending_peers.has(
		peer_id
	):
		return ERR_BUSY


	var http_request := HTTPRequest.new()


	add_child(
		http_request
	)


	pending_peers[
		peer_id
	] = true


	http_request.request_completed.connect(
		_on_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			expected_level,
			expected_experience,
			next_level,
			next_experience
		)
	)


	var headers := PackedStringArray([
		"Accept: application/json",
		"Content-Type: application/json",
		(
			"X-VHAL-Game-Server-Key: "
			+
			internal_key
		),
	])


	var request_body := JSON.stringify({
		"expected": {
			"level": expected_level,

			"experience": expected_experience,
		},

		"next": {
			"level": next_level,

			"experience": next_experience,
		},
	})


	var request_error := (
		http_request.request(
			_get_progression_url(
				account_id,
				character_id
			),
			headers,
			HTTPClient.METHOD_PATCH,
			request_body
		)
	)


	if request_error != OK:
		pending_peers.erase(
			peer_id
		)


		http_request.queue_free()


		return request_error


	return OK


# =========================================================
# RESULTADO
# =========================================================

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_level: int,
	expected_experience: int,
	next_level: int,
	next_experience: int
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Laravel no respondió correctamente.",
			{}
		)


		return


	var parsed: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Respuesta inválida del backend.",
			{}
		)


		return


	var response: Dictionary = parsed


	if (
		response_code != 200
		or
		not bool(
			response.get(
				"ok",
				false
			)
		)
	):
		var current_progression: Dictionary = {}


		var error_data_value: Variant = (
			response.get(
				"data",
				null
			)
		)


		if typeof(error_data_value) == TYPE_DICTIONARY:
			var error_data: Dictionary = (
				error_data_value
			)


			var current_value: Variant = (
				error_data.get(
					"current",
					null
				)
			)


			if typeof(current_value) == TYPE_DICTIONARY:
				current_progression = (
					current_value
					as Dictionary
				).duplicate(
					true
				)


			if typeof(current_value) == TYPE_DICTIONARY:
				current_progression = (
					current_value
					as Dictionary
				).duplicate(
					true
				)


		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			String(
				response.get(
					"message",
					"No se pudo persistir la progresión."
				)
			),
			current_progression
		)


		return


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Respuesta sin datos de progresión.",
			{}
		)


		return


	var data: Dictionary = data_value


	if (
		int(
			data.get(
				"account_id",
				0
			)
		) != account_id
		or
		int(
			data.get(
				"character_id",
				0
			)
		) != character_id
	):
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Identidad de progresión inválida.",
			{}
		)


		return


	var progression_value: Variant = (
		data.get(
			"progression",
			null
		)
	)


	if typeof(progression_value) != TYPE_DICTIONARY:
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Respuesta sin progression.",
			{}
		)


		return


	var progression: Dictionary = (
		progression_value
	)


	var returned_level := int(
		progression.get(
			"level",
			0
		)
	)


	var returned_experience := int(
		progression.get(
			"experience",
			-1
		)
	)


	if (
		returned_level != next_level
		or
		returned_experience != next_experience
	):
		progression_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			response_code,
			"Laravel confirmó otro estado de progresión.",
			progression.duplicate(
				true
			)
		)


		return


	progression_persisted.emit(
		peer_id,
		account_id,
		character_id,
		expected_level,
		expected_experience,
		returned_level,
		returned_experience,
		bool(
			data.get(
				"idempotent",
				false
			)
		)
	)
