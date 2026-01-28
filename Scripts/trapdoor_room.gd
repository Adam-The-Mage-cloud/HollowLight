extends Node2D

var already_opened = false
var room_complete = true
var last_room = false

var floor_positions: Array[Vector2i] = []
var frontwall_positions: Array[Vector2i] = []

func _ready() :
	$".".add_to_group("rooms")
	
	# Build the Arrays from what tiles I've placed down customally :
	# Analyse Floor
	for cell in %TileMapFloor.get_used_cells():
		floor_positions.append(cell)
	
	# Analyse Frontwalls
	for cell in %TileMapFrontFaceWall.get_used_cells():
		frontwall_positions.append(cell)
	# Door :
	%DoorArea.material = %DoorArea.material.duplicate()
	%DoorArea.add_to_group("doors")
	%DoorArea.unlocked = true
	
	# Spawn Next Room :
	EventBus.beacon_count_reset()
	_spawn_next_room()


func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and not already_opened and room_complete:
		%DoorFlashingTimer.stop()
		already_opened = true
		%DoorArea.remove_from_group("doors")
		%DoorArea.unlocked = true
		%DoorSprite.play("DarkSteelSmashed")
		%DoorStopperCollision.set_deferred("disabled", true)
		
		if last_room == true:
			EventBus.last_room_passed()
			return
		
		else :
			# SWITCH TO NEXT ROOM :
			EventBus.beacon_count_reset()
			
			var rooms = get_tree().current_scene.get_node("RoomsToBeDeleted").get_children()
			var index = rooms.find($".")
			
			if index != -1 and index + 1 < rooms.size():
				var next_room = rooms[index + 1]
				
				# Show next room :
				EventBus.current_room = next_room
				next_room.visible = true
				
				# Tell EventBus How many beacons are in the next room, by getting ebacons to activate :
				var new_rooms_beacons = next_room.get_node("Beacons").get_children()
				for i in new_rooms_beacons :
					i.now_visible()


func _spawn_next_room() :
	EventBus.last_room = false
	var scene = load("res://Scenes/procedural_room.tscn")
	var new_room = scene.instantiate()
	new_room.door_origin = %DoorArea.global_position
	new_room.z_index = 0
	new_room.first_room = false
	EventBus.total_rooms -= 1
	
	# Send Old Floor Positions :
	var world_floor_positions: Array[Vector2] = []
	for p in floor_positions:
		var local_pixel = %TileMapFloor.map_to_local(p)
		var world_pos = %TileMapFloor.to_global(local_pixel)
		world_floor_positions.append(world_pos)
	new_room.previous_floor_world_positions = world_floor_positions
	
	# Send Old FrontWall Positions :
	var world_frontwall_positions: Array[Vector2] = []
	for p in frontwall_positions:
		var local_pixel = %TileMapFloor.map_to_local(p)
		var world_pos = %TileMapFloor.to_global(local_pixel)
		world_frontwall_positions.append(world_pos)
	new_room.previous_frontwall_world_positions = world_frontwall_positions
	
	# Make Invisible  :
	new_room.visible = false
	
	await get_tree().process_frame
	get_tree().current_scene.get_node("RoomsToBeDeleted").call_deferred("add_child", new_room)
