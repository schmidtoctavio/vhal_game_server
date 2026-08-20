class_name BackendItemTransferRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal item_transferred(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	item: Dictionary
)


signal item_transfer_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	response_code: int,
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


# =========================================================
# CONTENEDORES
# =========================================================

const INVENTORY_CONTAINER: String = "inventory"
const VAULT_CONTAINER: String = "vault"


# =========================================================
# ESTADO
# =========================================================

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
# CONFIGURACIÓN
# =========================================================

func _load_runtime_config() -> void:
	var configured_backend_url := (
		OS.get_environment(
			BACKEND_URL_ENV
		).strip_edges()
	)


	if not configured_backend_url.is_empty():
		backend_url = configured_backend_url


	backend_url = backend_url.trim_suffix(
		"/"
	)


	internal_key = (
		OS.get_environment(
			INTERNAL_KEY_ENV
		).strip_edges()
	)


	if internal_key.is_empty():
		push_error(
			(
				"BackendItemTransferRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		(
			"BackendItemTransferRepository"
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
# TRANSFERIR ITEM
# =========================================================

func transfer_item(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	current_position: Vector2i,
	new_position: Vector2i
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if account_id <= 0:
		return ERR_INVALID_PARAMETER


	if character_id <= 0:
		return ERR_INVALID_PARAMETER


	var normalized_uid := (
		uid.strip_edges()
	)


	var normalized_source := (
		source_container.strip_edges().to_lower()
	)


	var normalized_target := (
		target_container.strip_edges().to_lower()
	)


	if normalized_uid.is_empty():
		return ERR_INVALID_PARAMETER


	if not _is_supported_container(
		normalized_source
	):
		return ERR_INVALID_PARAMETER


	if not _is_supported_container(
		normalized_target
	):
		return ERR_INVALID_PARAMETER


	if normalized_source == normalized_target:
		return ERR_INVALID_PARAMETER


	if not _is_position_inside_container(
		normalized_source,
		current_position
	):
		return ERR_INVALID_PARAMETER


	if not _is_position_inside_container(
		normalized_target,
		new_position
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
		_on_transfer_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			normalized_uid,
			normalized_source,
			normalized_target
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
		"source_container": normalized_source,

		"target_container": normalized_target,

		"current_grid_position": {
			"x": current_position.x,
			"y": current_position.y,
		},

		"new_grid_position": {
			"x": new_position.x,
			"y": new_position.y,
		},
	})


	var request_error := (
		http_request.request(
			_get_transfer_url(
				account_id,
				character_id,
				normalized_uid
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
# RESPUESTA
# =========================================================

func _on_transfer_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String,
	requested_source_container: String,
	requested_target_container: String
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
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"Laravel no respondió correctamente."
		)


		return


	var parsed_response: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(
		parsed_response
	) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"Respuesta inválida del backend."
		)


		return


	var response: Dictionary = (
		parsed_response
	)


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
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			String(
				response.get(
					"message",
					"No se pudo transferir el item."
				)
			)
		)


		return


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if typeof(
		data_value
	) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"Respuesta de transferencia sin datos."
		)


		return


	var data: Dictionary = (
		data_value
	)


	if int(
		data.get(
			"account_id",
			0
		)
	) != requested_account_id:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El backend devolvió otra cuenta."
		)


		return


	if int(
		data.get(
			"character_id",
			0
		)
	) != requested_character_id:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El backend devolvió otro personaje."
		)


		return


	var source_container := String(
		data.get(
			"source_container",
			""
		)
	).strip_edges()


	var target_container := String(
		data.get(
			"target_container",
			""
		)
	).strip_edges()


	if source_container != requested_source_container:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El backend devolvió otro contenedor de origen."
		)


		return


	if target_container != requested_target_container:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El backend devolvió otro contenedor de destino."
		)


		return


	var item_value: Variant = (
		data.get(
			"item",
			null
		)
	)


	if typeof(
		item_value
	) != TYPE_DICTIONARY:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"Respuesta sin item persistido."
		)


		return


	var item: Dictionary = (
		item_value
	)


	if String(
		item.get(
			"uid",
			""
		)
	).strip_edges() != requested_uid:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El backend devolvió otro item."
		)


		return


	if String(
		item.get(
			"container",
			""
		)
	).strip_edges() != requested_target_container:
		_emit_failure(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			requested_source_container,
			requested_target_container,
			response_code,
			"El item persistido quedó en otro contenedor."
		)


		return


	item_transferred.emit(
		peer_id,
		requested_account_id,
		requested_character_id,
		requested_uid,
		requested_source_container,
		requested_target_container,
		item.duplicate(
			true
		)
	)


# =========================================================
# ERROR
# =========================================================

func _emit_failure(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	source_container: String,
	target_container: String,
	response_code: int,
	message: String
) -> void:
	item_transfer_failed.emit(
		peer_id,
		account_id,
		character_id,
		uid,
		source_container,
		target_container,
		response_code,
		message
	)


# =========================================================
# URL
# =========================================================

func _get_transfer_url(
	account_id: int,
	character_id: int,
	uid: String
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/"
		+
		str(
			account_id
		)
		+
		"/characters/"
		+
		str(
			character_id
		)
		+
		"/items/"
		+
		uid
		+
		"/transfer"
	)


# =========================================================
# VALIDACIONES LOCALES
# =========================================================

func _is_supported_container(
	container: String
) -> bool:
	return (
		container == INVENTORY_CONTAINER
		or
		container == VAULT_CONTAINER
	)


func _is_position_inside_container(
	container: String,
	position: Vector2i
) -> bool:
	if (
		position.x < 0
		or
		position.x >= 8
		or
		position.y < 0
	):
		return false


	match container:
		INVENTORY_CONTAINER:
			return position.y < 8

		VAULT_CONTAINER:
			return position.y < 16


	return false
