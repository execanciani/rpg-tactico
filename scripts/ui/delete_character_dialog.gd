class_name DeleteCharacterDialog
extends ConfirmationDialog

signal character_delete_confirmed(character_id: String)

var pending_character_id := ""

func _ready() -> void:
	title = "Confirmar eliminación"
	ok_button_text = "ELIMINAR"
	cancel_button_text = "CANCELAR"
	confirmed.connect(func(): character_delete_confirmed.emit(pending_character_id))

func request_delete(character_id: String, character_name: String) -> void:
	pending_character_id = character_id
	dialog_text = "¿Eliminar definitivamente a %s?\nEsta acción no se puede deshacer." % character_name
	popup_centered(Vector2i(520, 220))
