class_name BackendVaultRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal vault_loaded(
	peer_id: int,
	account_id: int,
	snapshot: Dictionary
)

signal vault_load_failed(
	peer_id: int,
	account_id: int,
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


	backend_url = backend_url.trim_suffix("/")


	internal_key = (
		OS.get_environment(
			INTERNAL_KEY_ENV
		).strip_edges()
	)


	if internal_key.is_empty():
		push_error(
			"BackendVaultRepository | Falta GAME_SERVER_INTERNAL_KEY."
		)


		return


	print(
		"BackendVaultRepository | Configuración cargada | Backend: ",
		backend_url
	)


func is_configured() -> bool:
	return (
		not backend_url.is_empty()
		and
		not internal_key.is_empty()
	)


# =========================================================
# CARGAR VAULT
# =========================================================

func load_vault(
	peer_id: int,
	account_id: int
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if account_id <= 0:
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
	] = account_id


	http_request.request_completed.connect(
		_on_request_completed.bind(
			http_request,
			peer_id,
			account_id
		)
	)


	var headers := PackedStringArray([
		"Accept: application/json",
		(
			"X-VHAL-Game-Server-Key: "
			+
			internal_key
		),
	])


	var request_error := (
		http_request.request(
			_get_vault_url(
				account_id
			),
			headers,
			HTTPClient.METHOD_GET
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

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			"Laravel no respondió correctamente."
		)


		return


	var parsed_response: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(parsed_response) != TYPE_DICTIONARY:
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
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
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			str(
				response.get(
					"message",
					"No se pudo cargar la Vault."
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


	if typeof(data_value) != TYPE_DICTIONARY:
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			"Respuesta de Vault sin datos."
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


	var container := String(
		data.get(
			"container",
			""
		)
	).strip_edges()


	var items_value: Variant = (
		data.get(
			"items",
			null
		)
	)


	if account_id != requested_account_id:
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			"El backend devolvió otra cuenta."
		)


		return


	if container != "vault":
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			"Contenedor de Vault inválido."
		)


		return


	if typeof(items_value) != TYPE_ARRAY:
		vault_load_failed.emit(
			peer_id,
			requested_account_id,
			"Items de Vault inválidos."
		)


		return


	var snapshot := {
		"account_id": account_id,
		"container": container,
		"items": (
			items_value as Array
		).duplicate(
			true
		),
	}


	vault_loaded.emit(
		peer_id,
		account_id,
		snapshot
	)


# =========================================================
# URL
# =========================================================

func _get_vault_url(
	account_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/"
		+
		str(account_id)
		+
		"/vault"
	)
