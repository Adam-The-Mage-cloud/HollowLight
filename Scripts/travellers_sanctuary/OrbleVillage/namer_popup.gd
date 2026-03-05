extends Node2D

var orble_count: int = -1
var orble_name: String = ""

func _ready():
	%NameEnter.text = ""
	%NameEnter.grab_focus()

	# Find first empty slot
	for i in range(EventBus.max_orble_count):
		if EventBus.orbles[i] == "":
			orble_count = i
			break

	if orble_count == -1:
		push_error("No empty Orble slot available!")
		queue_free()
		return


func _on_accept_name_button_pressed() -> void:
	if orble_name.strip_edges() == "":
		orble_name = "Orble"

	EventBus.orbles[orble_count] = orble_name
	EventBus.save_game()

	get_tree().current_scene.orble_named(orble_name)
	queue_free()


func _on_name_enter_text_changed(new_text: String) -> void:
	orble_name = new_text
