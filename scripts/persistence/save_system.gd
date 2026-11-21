class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://campaign_save.json"
const SAVE_VERSION := 6
const BACKUP_SUFFIX := ".bak"
const TEMP_SUFFIX := ".tmp"

# Nunca truncar el guardado principal antes de escribir una copia temporal válida.
# Mantener un respaldo de la última versión legible para recuperar cortes de energía.
static func save_game(payload: Dictionary, path := SAVE_PATH) -> bool:
	var encoded := encode_payload(payload)
	if decode_payload(encoded).is_empty():
		return false
	var temp_path := path + TEMP_SUFFIX
	var backup_path := path + BACKUP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encoded)
	file.flush()
	file.close()
	if _load_exact(temp_path).is_empty():
		_remove_if_exists(temp_path)
		return false
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path) and not _load_exact(path).is_empty():
		if DirAccess.copy_absolute(absolute_path, absolute_backup) != OK:
			_remove_if_exists(temp_path)
			return false
	if DirAccess.rename_absolute(absolute_temp, absolute_path) != OK:
		# Algunos sistemas no permiten reemplazar un archivo existente con rename.
		# El respaldo se mantiene intacto incluso si este segundo paso falla.
		if DirAccess.copy_absolute(absolute_temp, absolute_path) != OK:
			_remove_if_exists(temp_path)
			return false
		_remove_if_exists(temp_path)
	return true

static func load_game(path := SAVE_PATH) -> Dictionary:
	var primary := _load_exact(path)
	if not primary.is_empty():
		return primary
	return _load_exact(path + BACKUP_SUFFIX)

static func _load_exact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed := decode_payload(file.get_as_text())
	file.close()
	return parsed

static func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

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
	# Las estructuras antiguas siguen siendo normalizadas por CampaignProfile.restore().
	# No convertir el número de versión si no se han migrado todos los campos.
	parsed["version"] = SAVE_VERSION
	return parsed

static func has_save() -> bool:
	return not load_game().is_empty()
