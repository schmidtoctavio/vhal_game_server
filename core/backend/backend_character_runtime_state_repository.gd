class_name BackendCharacterRuntimeStateRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal runtime_state_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	revision: int,
	runtime_state: Dictionary,
	idempotent: bool
)


signal runtime_state_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	response_code: int,
	message: String,
	current_runtime: Dictionary
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


var backend_url: String = DEFAULT_BACKEND_URL

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
		backend_url = configured_backend_url


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
				"BackendCharacterRuntimeStateRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)

		return


	print(
		"BackendCharacterRuntimeStateRepository",
		" | Configuración cargada | Backend: ",
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

func _get_runtime_state_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/%d/characters/%d/runtime-state"
		%
		[
			account_id,
			character_id,
		]
	)


# =========================================================
# PERSISTIR
# =========================================================

func persist_runtime_state(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	state: Dictionary
) -> Error:
	if (
		peer_id <= 1
		or
		account_id <= 0
		or
		character_id <= 0
		or
		expected_revision < 0
	):
		return ERR_INVALID_PARAMETER


	if state.is_empty():
		return ERR_INVALID_PARAMETER


	var world_value: Variant = (
		state.get(
			"world",
			null
		)
	)


	var vitals_value: Variant = (
		state.get(
			"vitals",
			null
		)
	)


	if (
		typeof(world_value) != TYPE_DICTIONARY
		or
		typeof(vitals_value) != TYPE_DICTIONARY
	):
		return ERR_INVALID_PARAMETER


	var world: Dictionary = world_value

	var vitals: Dictionary = vitals_value


	if String(
		world.get(
			"map_id",
			""
		)
	).strip_edges().is_empty():
		return ERR_INVALID_PARAMETER


	if int(
		vitals.get(
			"hp",
			-1
		)
	) < 0:
		return ERR_INVALID_PARAMETER


	if int(
		vitals.get(
			"mp",
			-1
		)
	) < 0:
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
			expected_revision
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
		"expected_revision": expected_revision,

		"state": state,
	})


	var request_error := (
		http_request.request(
			_get_runtime_state_url(
				account_id,
				character_id
			),
			headers,
			HTTPClient.METHOD_PUT,
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
	expected_revision: int
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			"Laravel no respondió correctamente.",
			{}
		)

		return


	var parsed: Variant = JSON.parse_string(
		body.get_string_from_utf8()
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
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
		var current_runtime: Dictionary = {}


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
				current_runtime = (
					current_value
					as Dictionary
				).duplicate(
					true
				)


		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			String(
				response.get(
					"message",
					"No se pudo persistir el runtime."
				)
			),
			current_runtime
		)

		return


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			"Respuesta sin datos runtime.",
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
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			"Identidad runtime inválida.",
			{}
		)

		return


	var runtime_value: Variant = (
		data.get(
			"runtime",
			null
		)
	)


	if typeof(runtime_value) != TYPE_DICTIONARY:
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			"Respuesta sin runtime.",
			{}
		)

		return


	var runtime_state: Dictionary = (
		runtime_value
	)


	var returned_revision := int(
		runtime_state.get(
			"revision",
			0
		)
	)


	if (
		returned_revision <= 0
		or
		(
			returned_revision != expected_revision
			and
			returned_revision != expected_revision + 1
		)
	):
		runtime_state_persist_failed.emit(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			response_code,
			"Laravel confirmó una revisión runtime inesperada.",
			runtime_state.duplicate(
				true
			)
		)

		return


	runtime_state_persisted.emit(
		peer_id,
		account_id,
		character_id,
		expected_revision,
		returned_revision,
		runtime_state.duplicate(
			true
		),
		bool(
			data.get(
				"idempotent",
				false
			)
		)
	)
