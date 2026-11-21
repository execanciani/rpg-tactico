class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://campaign_save.json"
const SAVE_VERSION := 6

static func save_game(payload: Dictionary, path := SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encode_payload(payload))
	file.close()
	return true

static func load_game(path := SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed := decode_payload(file.get_as_text())
	file.close()
	return parsed

static func encode_payload(payload: Dictionary) -> String:
	var versioned := payload.duplicate(true)
	versioned["version"] = SAVE_VERSION
	return JSON.stringify(versioned, "\t")

static func decode_payload(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {}
	var version := int(parsed.get("version", -1))
	if version < 3 or version > SAVE_VERSION:
		return {}
	parsed["version"] = SAVE_VERSION
	return parsed

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
