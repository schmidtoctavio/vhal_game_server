class_name BackendCharacterEquipmentRepository
extends Node


# =========================================================
# SIGNALS — SNAPSHOT
# =========================================================

signal equipment_loaded(
	peer_id: int,
	account_id: int,
	character_id: int,
	snapshot: Dictionary
)


signal equipment_load_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	message: String
)


# =========================================================
# SIGNALS — EQUIP
# =========================================================

signal equipment_item_equipped(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
)


signal equipment_item_equip_failed(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	response_code: int,
	message: String
)


# =========================================================
# SIGNALS — UNEQUIP
# =========================================================

signal equipment_item_unequipped(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	item: Dictionary
)


signal equipment_item_unequip_failed(
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
				"BackendCharacterEquipmentRepository"
				+
				" | Falta GAME_SERVER_INTERNAL_KEY."
			)
		)


		return


	print(
		(
			"BackendCharacterEquipmentRepository"
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


func is_peer_pending(
	peer_id: int
) -> bool:
	return pending_peers.has(
		peer_id
	)


# =========================================================
# CARGAR EQUIPMENT
# =========================================================

func load_equipment(
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
	] = "load"


	http_request.request_completed.connect(
		_on_load_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id
		)
	)


	var request_error := (
		http_request.request(
			_get_equipment_url(
				account_id,
				character_id
			),
			_get_headers(
				false
			),
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
# RESPUESTA — LOAD
# =========================================================

func _on_load_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int
) -> void:
	_finish_request(
		peer_id,
		http_request
	)


	if result != HTTPRequest.RESULT_SUCCESS:
		equipment_load_failed.emit(
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
		equipment_load_failed.emit(
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
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			String(
				response.get(
					"message",
					"No se pudo cargar Equipment."
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
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Respuesta de Equipment sin datos."
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
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"El backend devolvió otra cuenta."
		)


		return


	if character_id != requested_character_id:
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"El backend devolvió otro personaje."
		)


		return


	if container != "equipment":
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Contenedor de Equipment inválido."
		)


		return


	if typeof(items_value) != TYPE_ARRAY:
		equipment_load_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			"Items de Equipment inválidos."
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


	equipment_loaded.emit(
		peer_id,
		account_id,
		character_id,
		snapshot
	)


# =========================================================
# EQUIPAR
# =========================================================

func equip_item(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	current_position: Vector2i,
	equipment_slot: Variant
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


	var normalized_slot := String(
		equipment_slot
	).strip_edges().to_lower()


	if normalized_slot.is_empty():
		return ERR_INVALID_PARAMETER


	if not _is_inventory_position_valid(
		current_position
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
	] = "equip"


	http_request.request_completed.connect(
		_on_equip_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			normalized_uid,
			normalized_slot
		)
	)


	var request_body := JSON.stringify({
		"current_grid_position": {
			"x": current_position.x,
			"y": current_position.y,
		},

		"equipment_slot": normalized_slot,
	})


	var request_error := (
		http_request.request(
			_get_equip_url(
				account_id,
				character_id,
				normalized_uid
			),
			_get_headers(
				true
			),
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
# RESPUESTA — EQUIP
# =========================================================

func _on_equip_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String,
	requested_slot: String
) -> void:
	_finish_request(
		peer_id,
		http_request
	)


	var parsed := (
		_parse_mutation_response(
			result,
			response_code,
			body,
			requested_account_id,
			requested_character_id,
			requested_uid,
			"inventory",
			"equipment"
		)
	)


	if not bool(
		parsed.get(
			"ok",
			false
		)
	):
		equipment_item_equip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			String(
				parsed.get(
					"message",
					"No se pudo equipar el item."
				)
			)
		)


		return


	var item: Dictionary = (
		parsed.get(
			"item",
			{}
		)
	)


	var returned_slot := String(
		item.get(
			"equipment_slot",
			""
		)
	).strip_edges()


	if returned_slot != requested_slot:
		equipment_item_equip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió otro equipment_slot."
		)


		return


	if item.has(
		"grid_position"
	):
		equipment_item_equip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió Equipment con grid_position."
		)


		return


	equipment_item_equipped.emit(
		peer_id,
		requested_account_id,
		requested_character_id,
		requested_uid,
		item
	)


# =========================================================
# DESEQUIPAR
# =========================================================

func unequip_item(
	peer_id: int,
	account_id: int,
	character_id: int,
	uid: String,
	current_equipment_slot: Variant,
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


	var normalized_slot := String(
		current_equipment_slot
	).strip_edges().to_lower()


	if normalized_slot.is_empty():
		return ERR_INVALID_PARAMETER


	if not _is_inventory_position_valid(
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
	] = "unequip"


	http_request.request_completed.connect(
		_on_unequip_request_completed.bind(
			http_request,
			peer_id,
			account_id,
			character_id,
			normalized_uid,
			new_position
		)
	)


	var request_body := JSON.stringify({
		"current_equipment_slot": normalized_slot,

		"new_grid_position": {
			"x": new_position.x,
			"y": new_position.y,
		},
	})


	var request_error := (
		http_request.request(
			_get_unequip_url(
				account_id,
				character_id,
				normalized_uid
			),
			_get_headers(
				true
			),
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
# RESPUESTA — UNEQUIP
# =========================================================

func _on_unequip_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest,
	peer_id: int,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String,
	requested_position: Vector2i
) -> void:
	_finish_request(
		peer_id,
		http_request
	)


	var parsed := (
		_parse_mutation_response(
			result,
			response_code,
			body,
			requested_account_id,
			requested_character_id,
			requested_uid,
			"equipment",
			"inventory"
		)
	)


	if not bool(
		parsed.get(
			"ok",
			false
		)
	):
		equipment_item_unequip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			String(
				parsed.get(
					"message",
					"No se pudo desequipar el item."
				)
			)
		)


		return


	var item: Dictionary = (
		parsed.get(
			"item",
			{}
		)
	)


	var position_value: Variant = (
		item.get(
			"grid_position",
			null
		)
	)


	if typeof(position_value) != TYPE_DICTIONARY:
		equipment_item_unequip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió Inventory sin grid_position."
		)


		return


	var position: Dictionary = (
		position_value
	)


	var returned_position := Vector2i(
		int(
			position.get(
				"x",
				-1
			)
		),
		int(
			position.get(
				"y",
				-1
			)
		)
	)


	if returned_position != requested_position:
		equipment_item_unequip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió otra posición de Inventory."
		)


		return


	if item.has(
		"equipment_slot"
	):
		equipment_item_unequip_failed.emit(
			peer_id,
			requested_account_id,
			requested_character_id,
			requested_uid,
			response_code,
			"El backend devolvió Inventory con equipment_slot."
		)


		return


	equipment_item_unequipped.emit(
		peer_id,
		requested_account_id,
		requested_character_id,
		requested_uid,
		item
	)


# =========================================================
# PARSE MUTACIÓN
# =========================================================

func _parse_mutation_response(
	result: int,
	response_code: int,
	body: PackedByteArray,
	requested_account_id: int,
	requested_character_id: int,
	requested_uid: String,
	expected_source_container: String,
	expected_target_container: String
) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		return _mutation_failure(
			"Laravel no respondió correctamente."
		)


	var parsed_response: Variant = (
		JSON.parse_string(
			body.get_string_from_utf8()
		)
	)


	if typeof(parsed_response) != TYPE_DICTIONARY:
		return _mutation_failure(
			"Respuesta inválida del backend."
		)


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
		return _mutation_failure(
			String(
				response.get(
					"message",
					"Operación de Equipment rechazada."
				)
			)
		)


	var data_value: Variant = (
		response.get(
			"data",
			null
		)
	)


	if typeof(data_value) != TYPE_DICTIONARY:
		return _mutation_failure(
			"Respuesta de Equipment sin datos."
		)


	var data: Dictionary = (
		data_value
	)


	if int(
		data.get(
			"account_id",
			0
		)
	) != requested_account_id:
		return _mutation_failure(
			"El backend devolvió otra cuenta."
		)


	if int(
		data.get(
			"character_id",
			0
		)
	) != requested_character_id:
		return _mutation_failure(
			"El backend devolvió otro personaje."
		)


	if String(
		data.get(
			"source_container",
			""
		)
	).strip_edges() != expected_source_container:
		return _mutation_failure(
			"El backend devolvió otro contenedor de origen."
		)


	if String(
		data.get(
			"target_container",
			""
		)
	).strip_edges() != expected_target_container:
		return _mutation_failure(
			"El backend devolvió otro contenedor de destino."
		)


	var item_value: Variant = (
		data.get(
			"item",
			null
		)
	)


	if typeof(item_value) != TYPE_DICTIONARY:
		return _mutation_failure(
			"Respuesta de Equipment sin item."
		)


	var item: Dictionary = (
		item_value
	)


	if String(
		item.get(
			"uid",
			""
		)
	).strip_edges() != requested_uid:
		return _mutation_failure(
			"El backend devolvió otro uid."
		)


	return {
		"ok": true,
		"message": "",
		"item": item.duplicate(
			true
		),
	}


# =========================================================
# HEADERS
# =========================================================

func _get_headers(
	with_json_content_type: bool
) -> PackedStringArray:
	var headers := PackedStringArray([
		"Accept: application/json",

		(
			"X-VHAL-Game-Server-Key: "
			+
			internal_key
		),
	])


	if with_json_content_type:
		headers.append(
			"Content-Type: application/json"
		)


	return headers


# =========================================================
# FINALIZAR REQUEST
# =========================================================

func _finish_request(
	peer_id: int,
	http_request: HTTPRequest
) -> void:
	pending_peers.erase(
		peer_id
	)


	if is_instance_valid(
		http_request
	):
		http_request.queue_free()


# =========================================================
# VALIDACIÓN ESTRUCTURAL
# =========================================================

func _is_inventory_position_valid(
	position: Vector2i
) -> bool:
	return (
		position.x >= 0
		and
		position.x < 8
		and
		position.y >= 0
		and
		position.y < 8
	)


# =========================================================
# RESULTADO DE ERROR
# =========================================================

func _mutation_failure(
	message: String
) -> Dictionary:
	return {
		"ok": false,
		"message": message,
		"item": {},
	}


# =========================================================
# URLS
# =========================================================

func _get_equipment_url(
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
		"/equipment"
	)


func _get_equip_url(
	account_id: int,
	character_id: int,
	uid: String
) -> String:
	return (
		_get_equipment_url(
			account_id,
			character_id
		)
		+
		"/items/"
		+
		uid
		+
		"/equip"
	)


func _get_unequip_url(
	account_id: int,
	character_id: int,
	uid: String
) -> String:
	return (
		_get_equipment_url(
			account_id,
			character_id
		)
		+
		"/items/"
		+
		uid
		+
		"/unequip"
	)
