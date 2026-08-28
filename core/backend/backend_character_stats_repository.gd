class_name BackendCharacterStatsRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal primary_stats_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary,
	stats_snapshot: Dictionary,
	idempotent: bool
)


signal primary_stats_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary,
	response_code: int,
	reason: String,
	message: String,
	context: Dictionary
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
				"BackendCharacterStatsRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		"BackendCharacterStatsRepository"
		+
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

func _get_stats_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/%d/characters/%d/stats"
		%
		[
			account_id,
			character_id,
		]
	)


# =========================================================
# PERSISTIR ALLOCATION
# =========================================================

func persist_allocation(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary
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


	var normalized_next := (
		_normalize_allocated(
			next_allocated
		)
	)


	if normalized_next.is_empty():
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
			expected_revision,
			normalized_next
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
		"expected_revision": (
			expected_revision
		),

		"next": (
			normalized_next
		),
	})


	var request_error := (
		http_request.request(
			_get_stats_url(
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
	expected_revision: int,
	next_allocated: Dictionary
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"backend_unavailable",
			"Laravel no respondió correctamente.",
			{}
		)


		return


	var body_text := (
		body.get_string_from_utf8()
	)


	var json := JSON.new()


	var parse_error := (
		json.parse(
			body_text
		)
	)


	if parse_error != OK:
		var failure_reason := (
			"invalid_backend_response"
		)

		var failure_message := (
			"Respuesta inválida del backend."
		)


		if response_code >= 500:
			failure_reason = (
				"backend_unavailable"
			)

			failure_message = (
				"Backend no disponible."
			)


		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			failure_reason,
			failure_message,
			{}
		)


		return


	var parsed: Variant = (
		json.data
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"invalid_backend_response",
			"Respuesta inválida del backend.",
			{}
		)


		return


	var response: Dictionary = (
		parsed as Dictionary
	)


	var ok := bool(
		response.get(
			"ok",
			false
		)
	)


	if (
		response_code != 200
		or
		not ok
	):
		var context: Dictionary = {}


		var error_data_value: Variant = (
			response.get(
				"data",
				null
			)
		)


		if typeof(error_data_value) == TYPE_DICTIONARY:
			context = (
				error_data_value as Dictionary
			).duplicate(
				true
			)


		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			String(
				context.get(
					"reason",
					"primary_stats_persist_failed"
				)
			),
			String(
				response.get(
					"message",
					"No se pudo persistir Primary Stats."
				)
			),
			context
		)


		return


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"invalid_backend_response",
			"Respuesta sin datos de Primary Stats.",
			{}
		)


		return


	var data: Dictionary = (
		data_value
	)


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
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"identity_mismatch",
			"Identidad de Primary Stats inválida.",
			data.duplicate(
				true
			)
		)


		return


	var stats_value: Variant = (
		data.get(
			"stats",
			null
		)
	)


	if typeof(stats_value) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"invalid_backend_response",
			"Respuesta sin snapshot de Primary Stats.",
			data.duplicate(
				true
			)
		)


		return


	var stats_snapshot: Dictionary = (
		stats_value as Dictionary
	).duplicate(
		true
	)


	var returned_revision := int(
		stats_snapshot.get(
			"revision",
			-1
		)
	)


	if (
		returned_revision
		!=
		expected_revision + 1
	):
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"confirmation_mismatch",
			"Laravel confirmó una revisión inesperada.",
			stats_snapshot
		)


		return


	var allocated_value: Variant = (
		stats_snapshot.get(
			"allocated",
			null
		)
	)


	if typeof(allocated_value) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"invalid_backend_response",
			"Snapshot sin allocation válida.",
			stats_snapshot
		)


		return


	var returned_allocated := (
		_normalize_allocated(
			allocated_value
		)
	)


	if (
		returned_allocated.is_empty()
		or
		returned_allocated != next_allocated
	):
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			expected_revision,
			next_allocated,
			response_code,
			"confirmation_mismatch",
			"Laravel confirmó otra allocation.",
			stats_snapshot
		)


		return


	primary_stats_persisted.emit(
		peer_id,
		account_id,
		character_id,
		expected_revision,
		next_allocated.duplicate(
			true
		),
		stats_snapshot,
		bool(
			data.get(
				"idempotent",
				false
			)
		)
	)


# =========================================================
# NORMALIZAR ALLOCATED
# =========================================================

func _normalize_allocated(
	value: Variant
) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}


	var source: Dictionary = (
		value
	)


	var required_keys := [
		"strength",
		"agility",
		"vitality",
		"energy",
	]


	var normalized: Dictionary = {}


	for key: String in required_keys:
		if not source.has(
			key
		):
			return {}


		var stat_value: Variant = (
			source[
				key
			]
		)


		if typeof(stat_value) != TYPE_INT:
			return {}


		var stat := int(
			stat_value
		)


		if stat < 0:
			return {}


		normalized[
			key
		] = stat


	return normalized


# =========================================================
# FAILURE
# =========================================================

func _emit_failure(
	peer_id: int,
	account_id: int,
	character_id: int,
	expected_revision: int,
	next_allocated: Dictionary,
	response_code: int,
	reason: String,
	message: String,
	context: Dictionary
) -> void:
	primary_stats_persist_failed.emit(
		peer_id,
		account_id,
		character_id,
		expected_revision,
		next_allocated.duplicate(
			true
		),
		response_code,
		reason.strip_edges(),
		message.strip_edges(),
		context.duplicate(
			true
		)
	)
