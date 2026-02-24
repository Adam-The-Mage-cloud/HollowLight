extends Node2D

var already_opened = false
var room_complete = true
var last_room = false

# Flashing Allocator :
var knight_flashing = false
var torch_flashing = false
var door_flashing = false

var speech = 1

var floor_positions: Array[Vector2i] = []
var frontwall_positions: Array[Vector2i] = []

func _ready() :
	EventBus.intro = true
	EventBus.game_over_chance = 0.25
	
	$".".add_to_group("rooms")
	%TileMapFloor.add_to_group("floors")
	
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
	
	themify()
	
	# Spawn Next Room :
	EventBus.beacon_count_reset()
	_spawn_next_room()
	
	await get_tree().create_timer(2.00).timeout
	# Open Eyes Animation (Shader for Animatable Shape and Tweens) :
	var mat = %EyeLids.material
	var tween = create_tween()
	
	# Start closed
	mat.set("shader_parameter/open_amount", 0.02)
	
	# 1. Fast snap open
	tween.tween_property(mat, "shader_parameter/open_amount", 0.85, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# 2. Overshoot (open a bit too far)
	tween.tween_property(mat, "shader_parameter/open_amount", 1.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 3. Settle back to natural open
	tween.tween_property(mat, "shader_parameter/open_amount", 0.9, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# 4. Tiny blink after a short delay
	tween.tween_interval(0.3)
	
	tween.parallel().tween_property(mat, "shader_parameter/open_amount", 0.7, 0.72)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	tween.parallel().tween_property(mat, "shader_parameter/open_amount", 1.0, 0.72)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	tween.parallel().tween_property(mat, "shader_parameter/fade", 0.0, 0.72)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# START DIALOGUE :
	await get_tree().create_timer(2.00).timeout
	knight_flashing = true
	speech = 1
	speecher()
	
	await get_tree().create_timer(4.2).timeout
	speech = 2
	speecher()
	
	await get_tree().create_timer(4.2).timeout
	speech = 3
	speecher()
	
	await get_tree().create_timer(4.2).timeout
	knight_flashing = false
	torch_flashing = true
	speech = 4
	speecher()
	
	await get_tree().create_timer(10.0).timeout
	var bg = %ManualBackground
	
	# Start slightly above and transparent
	bg.modulate.a = 0.0
	bg.position.y -= 20
	
	var t = create_tween()
	t.set_parallel(true)
	
	# Fade in
	t.tween_property(bg, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	t.tween_property(bg, "position:y", bg.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await t.finished
	await get_tree().create_timer(9.0).timeout
	
	# Fade and slide back up
	var t2 = create_tween()
	t2.set_parallel(true)
	
	t2.tween_property(bg, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	t2.tween_property(bg, "position:y", bg.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await t2.finished
	
	var bgm = %MonsterBackground
	
	# Start slightly above and transparent
	bgm.modulate.a = 0.0
	bgm.position.y -= 20
	
	var tm = create_tween()
	tm.set_parallel(true)
	
	# Fade in
	tm.tween_property(bgm, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	tm.tween_property(bgm, "position:y", bgm.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await tm.finished
	await get_tree().create_timer(9.0).timeout
	
	# Fade and slide back up
	var t2m = create_tween()
	t2m.set_parallel(true)
	
	t2m.tween_property(bgm, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	t2m.tween_property(bgm, "position:y", bgm.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	# DOOR NOW OPENABLE :
	%DoorCollision.disabled = false
	door_flashing = true
	flash_white(%DoorArea)

func speecher() :
	# Intialise Bubble & Text :
	%SpeechBubbleSprite.visible = true
	%SpeechBubbleSprite.scale = Vector2(0.85, 0.85)
	%SpeechBubbleSprite.modulate.a = 0.0
	# Choose Speech Text :
	if speech == 1 :
		%SpeechText.text = str("my body is broken little Orblit...")
	if speech == 2 :
		%SpeechText.text = str("I go to dine in the halls of my forebears...")
	if speech == 3 :
		%SpeechText.text = str("You must get out of here...")
	if speech == 4 :
		%SpeechText.text = str("Pick up my torch, GO!")
	
	# Activate Speech Bubble Tween :
	var speech_bubble_tween = create_tween()
	speech_bubble_tween.set_parallel(true)
	
	speech_bubble_tween.tween_property(%SpeechBubbleSprite, "scale", Vector2(2, 2), 0.14).set_ease(Tween.EASE_OUT)
	speech_bubble_tween.tween_property(%SpeechBubbleSprite, "modulate:a", 1.0, 0.14).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(4).timeout
	var speech_tween_2 = create_tween()
	speech_tween_2.set_parallel(true)
	
	speech_tween_2.tween_property(%SpeechBubbleSprite, "scale", Vector2(0.9, 0.9), 0.12).set_ease(Tween.EASE_IN)
	speech_tween_2.tween_property(%SpeechBubbleSprite, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(0.12).timeout
	%SpeechBubbleSprite.visible = false

func flash_white(entity) :
	var tween = create_tween()
	tween.tween_property(entity.material, "shader_parameter/flash_amount", 1.0, 0.3)
	
	# Fade back down
	tween.tween_property(entity.material, "shader_parameter/flash_amount", 0.0, 0.3)

func themify() :
	if EventBus.current_theme == 2 : # Ice
		%TileMapFrontFaceWall.modulate = Color(0.004, 0.929, 0.855, 1.0)
		%TileMapRoomOutline.modulate = Color(0.004, 0.582, 0.582, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.002, 0.431, 0.431, 1.0)
		%TileMapFloor.modulate = Color(0.067, 0.988, 0.988)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapFloorCover.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.517, 0.999, 0.996, 1.0)
		%EnvironmentalLights.modulate = Color(0.067, 0.988, 0.988)
		%WallInteractables.modulate = Color(0.067, 0.988, 0.988)
		%FloorInteractables.modulate = Color(0.067, 0.988, 0.988)
		%Mist.modulate = Color(0.067, 0.988, 0.988)
		%DoorArea.modulate = Color(0.067, 0.988, 0.988)
	
	if EventBus.current_theme == 3 : # Hell
		%TileMapFrontFaceWall.modulate = Color(0.995, 0.552, 0.554, 1.0)
		%TileMapRoomOutline.modulate = Color(0.779, 0.078, 0.207, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.506, 0.03, 0.12, 1.0)
		%TileMapFloor.modulate = Color(0.976, 0.192, 0.298, 1.0)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapFloorCover.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.992, 0.435, 0.454, 1.0)
		%EnvironmentalLights.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%WallInteractables.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%FloorInteractables.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%Mist.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%DoorArea.modulate = Color(0.976, 0.192, 0.298, 1.0)

	if EventBus.current_theme == 4 : # Overgrown
		%TileMapFrontFaceWall.modulate = Color(0.0, 0.373, 0.103, 1.0)
		%TileMapRoomOutline.modulate = Color(0.0, 0.26, 0.061, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.0, 0.154, 0.024, 1.0)
		%TileMapFloor.modulate = Color(0.0, 0.306, 0.078, 1.0)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapFloorCover.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%EnvironmentalLights.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%WallInteractables.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%FloorInteractables.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%Mist.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%DoorArea.modulate = Color(0.0, 0.306, 0.078, 1.0)

func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and not already_opened and room_complete:
		%DoorFlashingTimer.stop()
		already_opened = true
		%DoorBreakParticles.emitting = true
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


func _on_flash_allocator_timeout() -> void:
	if knight_flashing == true :
		flash_white(%FallenTank)
	elif torch_flashing == true :
		flash_white(%TorchShield)
	elif door_flashing == true :
		flash_white(%DoorArea)
