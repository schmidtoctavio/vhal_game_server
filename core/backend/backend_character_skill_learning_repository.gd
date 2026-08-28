class_name BackendCharacterSkillLearningRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal skill_learning_persisted(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	idempotent: bool
)


signal skill_learning_persist_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
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
				"BackendCharacterSkillLearningRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		(
			"BackendCharacterSkillLearningRepository"
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

func _get_learning_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/%d/characters/%d/skills/learn"
		%
		[
			account_id,
			character_id,
		]
	)


# =========================================================
# PERSISTIR APRENDIZAJE
# =========================================================

func persist_learning(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String
) -> Error:
	var normalized_skill_id := (
		skill_id
		.strip_edges()
		.to_lower()
	)

	var normalized_scroll_uid := (
		scroll_uid
		.strip_edges()
		.to_lower()
	)

	var normalized_scroll_item_id := (
		scroll_item_id
		.strip_edges()
		.to_lower()
	)


	if (
		peer_id <= 1
		or
		account_id <= 0
		or
		character_id <= 0
		or
		normalized_skill_id.is_empty()
		or
		normalized_scroll_uid.is_empty()
		or
		normalized_scroll_item_id.is_empty()
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
			normalized_skill_id,
			normalized_scroll_uid,
			normalized_scroll_item_id
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
		"skill_id": normalized_skill_id,

		"scroll_uid": normalized_scroll_uid,

		"scroll_item_id": normalized_scroll_item_id,
	})


	var request_error := (
		http_request.request(
			_get_learning_url(
				account_id,
				character_id
			),
			headers,
			HTTPClient.METHOD_POST,
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
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String
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
			skill_id,
			scroll_uid,
			scroll_item_id,
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


		# -------------------------------------------------
		# Un 5xx no-JSON suele significar que el proxy
		# respondió mientras Laravel estaba indisponible.
		# -------------------------------------------------

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
			skill_id,
			scroll_uid,
			scroll_item_id,
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
			skill_id,
			scroll_uid,
			scroll_item_id,
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
		not ok
		or
		(
			response_code != 200
			and
			response_code != 201
		)
	):
		var error_data: Dictionary = {}


		var error_data_value: Variant = (
			response.get(
				"data",
				null
			)
		)


		if typeof(error_data_value) == TYPE_DICTIONARY:
			error_data = (
				error_data_value as Dictionary
			).duplicate(
				true
			)


		_emit_failure(
			peer_id,
			account_id,
			character_id,
			skill_id,
			scroll_uid,
			scroll_item_id,
			response_code,
			String(
				error_data.get(
					"reason",
					"skill_learning_persist_failed"
				)
			),
			String(
				response.get(
					"message",
					"No se pudo persistir el aprendizaje."
				)
			),
			error_data
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
			skill_id,
			scroll_uid,
			scroll_item_id,
			response_code,
			"invalid_backend_response",
			"Respuesta sin datos de aprendizaje.",
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
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			skill_id,
			scroll_uid,
			scroll_item_id,
			response_code,
			"identity_mismatch",
			"Identidad de aprendizaje inválida.",
			data.duplicate(
				true
			)
		)


		return


	var skill_value: Variant = (
		data.get(
			"skill",
			null
		)
	)


	if typeof(skill_value) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			skill_id,
			scroll_uid,
			scroll_item_id,
			response_code,
			"invalid_backend_response",
			"Respuesta sin skill aprendida.",
			data.duplicate(
				true
			)
		)


		return


	var skill: Dictionary = skill_value


	var returned_skill_id := String(
		skill.get(
			"skill_id",
			""
		)
	).strip_edges().to_lower()


	var returned_scroll_uid := String(
		skill.get(
			"learned_from_item_uid",
			""
		)
	).strip_edges().to_lower()


	var returned_scroll_item_id := String(
		skill.get(
			"learned_from_item_id",
			""
		)
	).strip_edges().to_lower()


	if (
		returned_skill_id != skill_id
		or
		returned_scroll_uid != scroll_uid
		or
		returned_scroll_item_id != scroll_item_id
	):
		_emit_failure(
			peer_id,
			account_id,
			character_id,
			skill_id,
			scroll_uid,
			scroll_item_id,
			response_code,
			"confirmation_mismatch",
			"Laravel confirmó otro aprendizaje.",
			data.duplicate(
				true
			)
		)


		return


	skill_learning_persisted.emit(
		peer_id,
		account_id,
		character_id,
		returned_skill_id,
		returned_scroll_uid,
		returned_scroll_item_id,
		bool(
			data.get(
				"idempotent",
				false
			)
		)
	)


# =========================================================
# FAILURE
# =========================================================

func _emit_failure(
	peer_id: int,
	account_id: int,
	character_id: int,
	skill_id: String,
	scroll_uid: String,
	scroll_item_id: String,
	response_code: int,
	reason: String,
	message: String,
	context: Dictionary
) -> void:
	skill_learning_persist_failed.emit(
		peer_id,
		account_id,
		character_id,
		skill_id,
		scroll_uid,
		scroll_item_id,
		response_code,
		reason,
		message,
		context
	)
