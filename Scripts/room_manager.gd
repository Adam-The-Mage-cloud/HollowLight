extends Node2D

var current_room = false

func load_room(scene_path):
	# Remove old room
	if current_room:
		current_room.queue_free()
	
	# Load new room
	var room = load(scene_path).instantiate()
	$RoomContainer.add_child(room)
	current_room = room
	
	# Tell the room it has been entered
	room.enter_room()


func _on_doors_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
