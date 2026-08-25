class_name BackendCharacterInventoryRepository
extends Node


# =========================================================
# SIGNALS
# =========================================================

signal inventory_loaded(
	peer_id: int,
	account_id: int,
	character_id: int,
	snapshot: Dictionary
)

signal inventory_load_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	message: String
)

signal inventory_item_moved(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
)


signal inventory_item_move_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
	message: String
)

signal inventory_item_granted(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary,
	idempotent: bool
)


signal inventory_item_grant_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
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
			(
				"BackendCharacterInventoryRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		(
			"BackendCharacterInventoryRepository"
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
# CARGAR INVENTARIO
# =========================================================

func load_inventory(
	peer_id: int,
	account_id: int,
	character_id: int
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if account_id <= 0:
		return ERR_INVALID_PARAMETER


	if character_id <= 0:
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
			character_id
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
			_get_inventory_url(
				account_id,
				character_id
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
	requested_account_id: int,
	requested_character_id: int
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Laravel no respondió correctamente."
		)


		return


	var parsed_response: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(parsed_response) != TYPE_DICTIONARY:
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
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
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			String(
				response.get(
					"message",
					"No se pudo cargar el Inventory."
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
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Respuesta de Inventory sin datos."
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


	var character_id := int(
		data.get(
			"character_id",
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
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"El backend devolvió otra cuenta."
		)


		return


	if character_id != requested_character_id:
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"El backend devolvió otro personaje."
		)


		return


	if container != "inventory":
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Contenedor de Inventory inválido."
		)


		return


	if typeof(items_value) != TYPE_ARRAY:
		inventory_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Items de Inventory inválidos."
		)


		return


	var snapshot := {
		"account_id": account_id,
		"character_id": character_id,
		"container": container,
		"items": (
			items_value as Array
		).duplicate(
			true
		),
	}


	inventory_loaded.emit(
		peer_id,
		account_id,
		character_id,
		snapshot
	)


# =========================================================
# URL
# =========================================================

func _get_inventory_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/"
		+
		str(account_id)
		+
		"/characters/"
		+
		str(character_id)
		+
		"/inventory"
	)

func _get_inventory_items_url(
	account_id: int,
	character_id: int
) -> String:
	return (
		_get_inventory_url(
			account_id,
			character_id
		)
		+
		"/items"
	)

# =========================================================
# GRANT ITEM A INVENTORY
# =========================================================

func grant_inventory_item(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item_id: String,
	quantity: int,
	grid_position: Vector2i
) -> Error:
	if peer_id <= 1:
		return ERR_INVALID_PARAMETER


	if (
		account_id <= 0
		or
		character_id <= 0
	):
		return ERR_INVALID_PARAMETER


	var normalized_uid := (
		uid.strip_edges().to_lower()
	)


	var normalized_item_id := (
		item_id
		.strip_edges()
		.to_lower()
	)


	if not ServerPersistentItemUidGenerator.is_valid_uuid(
		normalized_uid
	):
		return ERR_INVALID_PARAMETER


	if normalized_item_id.is_empty():
		return ERR_INVALID_PARAMETER


	if quantity <= 0:
		return ERR_INVALID_PARAMETER


	if (
		grid_position.x < 0
		or
		grid_position.x >= 8
		or
		grid_position.y < 0
		or
		grid_position.y >= 8
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
		_on_grant_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			normalized_uid,
			normalized_item_id,
			quantity,
			grid_position
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
		"uid": normalized_uid,

		"item_id": normalized_item_id,

		"quantity": quantity,

		"grid_position": {
			"x": grid_position.x,
			"y": grid_position.y,
		},
	})


	var request_error := http_request.request(
		_get_inventory_items_url(
			account_id,
			character_id
		),
		headers,
		HTTPClient.METHOD_POST,
		request_body
	)


	if request_error != OK:
		pending_peers.erase(
			peer_id
		)

		http_request.queue_free()


		return request_error


	return OK

func _on_grant_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String,
	requested_item_id: String,
	requested_quantity: int,
	requested_position: Vector2i
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Laravel no respondió correctamente."
		)


		return


	var parsed: Variant = JSON.parse_string(
		body.get_string_from_utf8()
	)


	if typeof(parsed) != TYPE_DICTIONARY:
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Respuesta inválida del backend."
		)


		return


	var response: Dictionary = parsed


	if (
		(
			response_code != 200
			and
			response_code != 201
		)
		or
		not bool(
			response.get(
				"ok",
				false
			)
		)
	):
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			String(
				response.get(
					"message",
					"No se pudo persistir el item."
				)
			)
		)


		return


	var data_value: Variant = response.get(
		"data",
		null
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Respuesta sin datos de Inventory."
		)


		return


	var data: Dictionary = data_value


	if (
		int(data.get("account_id", 0))
		!=
		requested_account_id
		or
		int(data.get("character_id", 0))
		!=
		requested_character_id
		or
		String(data.get("container", ""))
		!=
		"inventory"
	):
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Identidad de Inventory devuelta inválida."
		)


		return


	var item_value: Variant = data.get(
		"item",
		null
	)


	if typeof(item_value) != TYPE_DICTIONARY:
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Respuesta sin item persistido."
		)


		return


	var item: Dictionary = item_value

	var position_value: Variant = item.get(
		"grid_position",
		null
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Item persistido sin posición."
		)


		return


	var returned_position: Dictionary = (
		position_value
	)


	if (
		String(item.get("uid", "")).to_lower()
		!=
		requested_uid
		or
		String(item.get("item_id", "")).to_lower()
		!=
		requested_item_id
		or
		int(item.get("quantity", 0))
		!=
		requested_quantity
		or
		int(returned_position.get("x", -1))
		!=
		requested_position.x
		or
		int(returned_position.get("y", -1))
		!=
		requested_position.y
	):
		inventory_item_grant_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend confirmó otro estado de item."
		)


		return


	inventory_item_granted.emit(
		peer_id,
		requested_account_id,
		requested_character_id,
		requested_uid,
		item.duplicate(
			true
		),
		bool(
			data.get(
				"idempotent",
				false
			)
		)
	)

# =========================================================
# MOVER ITEM DENTRO DE INVENTORY
# =========================================================

func move_inventory_item(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
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


	if normalized_uid.is_empty():
		return ERR_INVALID_PARAMETER


	if (
		current_position.x < 0
		or
		current_position.x >= 8
		or
		current_position.y < 0
		or
		current_position.y >= 8
	):
		return ERR_INVALID_PARAMETER


	if (
		new_position.x < 0
		or
		new_position.x >= 8
		or
		new_position.y < 0
		or
		new_position.y >= 8
	):
		return ERR_INVALID_PARAMETER


	if current_position == new_position:
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
		_on_move_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			normalized_uid
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
			_get_inventory_item_position_url(
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
# RESPUESTA DE MOVIMIENTO
# =========================================================

func _on_move_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


	if result != HTTPRequest.RESULT_SUCCESS:
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Laravel no respondió correctamente."
		)


		return


	var parsed_response: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(parsed_response) != TYPE_DICTIONARY:
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
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
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			String(
				response.get(
					"message",
					"No se pudo mover el item de Inventory."
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
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"Respuesta de movimiento sin datos."
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
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
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
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió otro personaje."
		)


		return


	if String(
		data.get(
			"container",
			""
		)
	).strip_edges() != "inventory":
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió otro contenedor."
		)


		return


	var item_value: Variant = (
		data.get(
			"item",
			null
		)
	)


	if typeof(item_value) != TYPE_DICTIONARY:
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
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
		inventory_item_move_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió otro item."
		)


		return


	inventory_item_moved.emit(
		peer_id,
		requested_account_id,
		requested_character_id,
		requested_uid,
		item.duplicate(
			true
		)
	)


# =========================================================
# URL DE POSICIÓN DE ITEM
# =========================================================

func _get_inventory_item_position_url(
	account_id: int,
	character_id: int,
	uid: String
) -> String:
	return (
		backend_url
		+
		"/api/internal/accounts/"
		+
		str(account_id)
		+
		"/characters/"
		+
		str(character_id)
		+
		"/inventory/items/"
		+
		uid
		+
		"/position"
	)
