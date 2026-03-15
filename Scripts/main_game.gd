extends Node2D

var Shadow_Cloud = preload("res://Scenes/Monsters/the_shadow.tscn")

var is_touchscreen = true
var touchscreen_available = true

var selected_orble

var raid_active = false

var darkness_increase_per_second = 12.4

var room_finished = false

func _ready() :
	randomize()
	# Connect Main Game To Certain Gameplay Events (For Node Removal/Performance etc e.g. Dungeon Reset / Sanctuary Spawn)
	EventBus.last_room_complete.connect(_on_dungeon_ended)
	EventBus.new_crawl.connect(_on_new_dungeon_crawl)
	EventBus.spawn_sanctuary.connect(_on_spawning_sanctuary)
	EventBus.camera_reset.connect(camera_reset)           
	EventBus.new_dungeon_touchscreen.connect(new_dungeon_touchscreen)
	
	# IF FIRST TIME LOADING THE GAME AND PLAYER IS LVL 0 - PLAY DUNGEON INTRO :
	if EventBus.total_acquired_experience == 0 and EventBus.player_level == 1 :
		EventBus.intro = true
		var intro_room = preload("res://Scenes/custom_rooms/intro_room.tscn").instantiate()
		intro_room.z_index = 0
		%Brody.global_position = intro_room.global_position + Vector2(160, 72)
		%RoomsToBeDeleted.add_child(intro_room)
		
		%TouchScreenLayer.visible = false
		%GameplayUI.visible = false
		
		# AWAIT PLAYER MOVEMENT TO BE REENABLED :
		%Torch.visible = false
		touchscreen_available = false
		%Brody.input_enabled = true
		
		# MAX DARKNESS BUT NOT DEADABLE :
		EventBus.total_current_darkness = 60.0
		
		var cam = %BrodyCam
		
		# Zoom in
		cam.zoom = Vector2(2.0, 2.0)
		cam.offset = Vector2(24.0, -8.0)
		
		var camera_tween2 = create_tween()
		camera_tween2.tween_property(cam, "zoom", Vector2(1.6875, 1.6875), 6.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await camera_tween2.finished
		var camera_tween3 = create_tween().set_parallel(true)
		camera_tween3.tween_property(cam, "zoom", Vector2(1.75, 1.75), 8.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		camera_tween3.tween_property(cam, "offset", Vector2(30, -20), 8.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await camera_tween3.finished
		var camera_tween4 = create_tween().set_parallel(true)
		camera_tween4.tween_property(cam, "zoom", Vector2(1.6875, 1.6875), 4.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		camera_tween4.tween_property(cam, "offset", Vector2(0, 0), 4.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await camera_tween4.finished
		
		# Tween camera back to default
		var camera_tween = create_tween()
		camera_tween.tween_property(cam, "zoom", Vector2(1.6875, 1.6875), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		camera_tween.tween_property(cam, "offset", Vector2(0.0, 0.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		%Torch.visible = true
		
		%Brody.input_enabled = true
		touchscreen_available = true
		
		# Move Joystick :
		await get_tree().create_timer(2.0).timeout
		var movement_fadeintween = create_tween()
		movement_fadeintween.tween_property(%MoveJoystickText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		
		EventBus.sanctuary = true
		%TouchScreenLayer.visible = true
		%StaminaBarGreen.visible = false
		%ShieldButton.visible = false
		%TorchJoystickSpriteHighlighted.visible = false
		%TorchJoystickSprite.visible = false
		%DashButton.visible = false
		%BrodyJoystickSpriteHighlighted.visible = true
		%BrodyJoystickSprite.visible = true
		%BrodyJoystickSpriteHighlighted.z_index = 1
		
		await movement_fadeintween.finished 
		await get_tree().create_timer(0.5).timeout
		var movement_fadeouttween = create_tween()
		movement_fadeouttween.tween_property(%MoveJoystickText, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.5)
		
		# Torch Joystick :
		await get_tree().create_timer(1.5).timeout
		var torch_fadeintween = create_tween()
		torch_fadeintween.tween_property(%TorchJoystickText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		
		%TorchJoystickSpriteHighlighted.visible = true
		%BrodyJoystickSpriteHighlighted.visible = false
		%TorchJoystickSprite.visible = true
		%BrodyJoystickSpriteHighlighted.z_index = -2
		%TorchJoystickSpriteHighlighted.z_index = 1
		
		await torch_fadeintween.finished 
		await get_tree().create_timer(0.5).timeout
		var torch_fadeouttween = create_tween()
		torch_fadeouttween.tween_property(%TorchJoystickText, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.5)
		
		# Dash Joystick :
		await get_tree().create_timer(1.5).timeout
		var dash_fadeintween = create_tween()
		dash_fadeintween.tween_property(%DashButtonText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		
		%DashHighlighted.visible = true
		%DashButton.visible = true
		touchscreen_available = true
		%TorchJoystickSpriteHighlighted.z_index = -2
		%BrodyCam.zoom = Vector2(1.6875, 1.6875)
		
		await dash_fadeintween.finished 
		await get_tree().create_timer(0.5).timeout
		var dash_fadeouttween = create_tween()
		dash_fadeouttween.tween_property(%DashButtonText, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.5)
		
		await get_tree().create_timer(1.5).timeout
		EventBus.sanctuary = false
		%DashHighlighted.visible = false
		%StaminaBarGreen.visible = true
		%GameplayUI.visible = true
	   
	else :
		# Start in Sanctuary :
		%Torch.lower_torch_light()
		var spawn_sanctuary = preload("res://Scenes/custom_rooms/the_sanctuary.tscn").instantiate()
		spawn_sanctuary.global_position = Vector2(-0.0, 0.0)
		%Brody.global_position = Vector2(136, 90)
		%RoomsToBeDeleted.add_child(spawn_sanctuary)
		_set_sanctuary_properties()


func tell_to_dash() :
	# Dash Joystick :
	await get_tree().create_timer(1.5).timeout
	var dash_fadeintween = create_tween()
	dash_fadeintween.tween_property(%DashButtonText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	
	%DashHighlighted.visible = true
	%DashButton.visible = true
	touchscreen_available = true
	%TorchJoystickSpriteHighlighted.z_index = -2
	%BrodyCam.zoom = Vector2(1.6875, 1.6875)
	
	await dash_fadeintween.finished 
	await get_tree().create_timer(0.5).timeout
	var dash_fadeouttween = create_tween()
	dash_fadeouttween.tween_property(%DashButtonText, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.5)
	
	await get_tree().create_timer(1.5).timeout
	EventBus.sanctuary = false
	%DashHighlighted.visible = false
	%StaminaBarGreen.visible = true
	%GameplayUI.visible = true


# Wait For Touchscreen to be Pressed to turn on touchscreen settings :
func _input(event):
	if touchscreen_available == true and EventBus.currently_interacting == false :
		if event is InputEventScreenTouch:
			is_touchscreen = true
			EventBus.touchscreen_enacted = true
			%BrodyCam.zoom = Vector2(1.6875, 1.6875)
			%TouchScreenLayer.visible = true

func _process(_delta: float) -> void: 
	%DarknessEffect.modulate.a = EventBus.total_current_darkness / 100
	
	# Show Interact Button or Don't :
	if EventBus.sanctuary == true :
		if EventBus.tutorial_replay_available == true or EventBus.dungeon_crawl_button_available == true or EventBus.clives_shop_interactable == true or EventBus.catballoon_shop_interactable == true or EventBus.jackie_shop_interactable == true or EventBus.cheffing_station_interactable == true or EventBus.mission_board_interactable == true :
			if EventBus.currently_interacting == false :
				%DashButton.visible = false
				%InteractButton.visible = true
		else :
			%DashButton.visible = true
			%InteractButton.visible = false
	else :
		%DashButton.visible = true
		%InteractButton.visible = false

func _on_shadow_spawn_timer_timeout() -> void:
	# Spawn another Shadow cloud :
	%RegularFollowPath.progress_ratio = randf_range(0, 1)
	var initial_spawn_position = %RegularFollowPath.global_position
	for i in range(2, EventBus.total_current_darkness / 8) :
		var new_shadowcloud = Shadow_Cloud.instantiate()
		new_shadowcloud.global_position = initial_spawn_position + Vector2(EventBus.total_current_darkness / 65 * randf_range(-7.5,7.5), EventBus.total_current_darkness / 65 * randf_range(-7.5, 7.5))
		new_shadowcloud.target = %Brody
		%MonstersToBeGone.add_child(new_shadowcloud)
	if EventBus.total_current_darkness >= 5 :
		%ShadowSpawnTimer.wait_time = (10.0 / (EventBus.total_current_darkness / 5)) # THIS MIGHT NEED SOME TLC LOL AND THE DISTANCE RANGE ABOVE!


func _on_torch_wraith_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 3 :
			var TorchWraith = preload("res://Scenes/Monsters/torch_wraith.tscn").instantiate()
			TorchWraith.global_position = %RegularFollowPath.global_position
			TorchWraith.target = %Brody
			%MonstersToBeGone.add_child(TorchWraith)
			%TorchWraithChance.wait_time += randf_range(-1, 1)


func _on_worm_bat_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 2 :
			var WormBat = preload("res://Scenes/Monsters/worm_bat.tscn").instantiate()
			WormBat.global_position = %RegularFollowPath.global_position
			WormBat.target = %Brody
			%MonstersToBeGone.add_child(WormBat)
			if %WormBatChance.wait_time > 2 :
				%WormBatChance.wait_time += randf_range(-1, 1)
			else :
				%WormBatChance.wait_time += 3


func _on_darkness_checker_timeout() -> void:
	EventBus.total_current_darkness = clamp(EventBus.total_current_darkness + ((darkness_increase_per_second / 20) / sqrt(EventBus.amount_fortify_darkness_upgraded + 1)), 1.0, 100.0)
	%DarknessBar.modulate.a = EventBus.total_current_darkness / 200

# CAMERA RESET :
func camera_reset() :
	%BrodyCam.enabled = true
	touchscreen_available = true
	%TouchScreenLayer.visible = true

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SPAWN WEAPONS / SIDEKICKS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func spawn_mystic_sword() :
	var mystic_sword = preload("res://Scenes/mystic_sword.tscn").instantiate()
	call_deferred("add_child", mystic_sword)

func spawn_winged_torch() :
	var winged_torch = preload("res://Scenes/winged_torch.tscn").instantiate()
	call_deferred("add_child", winged_torch)

func despawn_sidekick() :
	for node in get_tree().get_nodes_in_group("PlayerSidekick"):
		node.queue_free()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GAMEPLAY EVENTS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# DUNGEON CRAWLING :
func _on_dungeon_ended() :
	# If any rooms around, delete them :
	delete_current_memory()
	# STOP TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
	%DarknessChecker.stop()
	%ShadowSpawnTimer.stop()
	%TorchWraithChance.stop()
	%WormBatChance.stop()
	# Take Brody's Torch/Weapons Away :
	%Torch.visible = false
	# Turn off DarknessLayer Effect :
	%DarknessLayer.visible = false
	# Turn Off GameplayUI :
	%GameplayUI.visible = false
	# Turn Off ability for Touchscreen Controls (Temporarily) 
	touchscreen_available = false
	%TouchScreenLayer.visible = false
	%ShieldButton.visible = false
	
	EventBus.total_rooms = 0
	EventBus.dungeons_completed += 1
	EventBus.weekly_dungeons_completed += 1

func _on_new_dungeon_crawl() :
	# Delete Previous Instances (e.g. Sanctuary) :
	delete_current_memory()
	for node in get_tree().get_nodes_in_group("deletables_sanctuary"):
		node.queue_free()
	# DISPLAY LOADING SCREEN and let LoadingOverlay handle the rest :
	%LoadingOverlay.show_loading()
	# Start With Spawning Trapdoor Room :
	var new_room = preload("res://Scenes/custom_rooms/trapdoor_room.tscn").instantiate()
	new_room.z_index = 0
	%Brody.global_position = new_room.global_position + Vector2(124, 16)
	%RoomsToBeDeleted.call_deferred("add_child", new_room)
	
	EventBus.sanctuary = false
	# Update GameplayUI Tracker Values :
	EventBus.total_new_fervour = 0
	%IndicatorDirector.levelled_used_xp = 0.0
	%IndicatorDirector.temporary_level = 0
	
	# If Intro Then Wait 6 Seconds Then Explain Darkness, Speed, Gold, XP :
	if EventBus.player_level < 3 :
		EventBus.intro = true
		touchscreen_available = false
		%TouchScreenLayer.visible = false
		%BrodyCam.enabled = false
		while EventBus.last_room == false :
			await get_tree().create_timer(0.05).timeout
		var helper = preload("res://Scenes/dungeon_helper.tscn").instantiate()
		helper.global_position = %Brody.global_position + Vector2(0, 0)
		call_deferred("add_child", helper)
		
		await get_tree().create_timer(17.0).timeout
		# START TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
		%DarknessChecker.start()
		%ShadowSpawnTimer.start()
		%TorchWraithChance.start()
		%WormBatChance.start()
		# Brody Cam :
		%BrodyCam.zoom = Vector2(1.6875, 1.6875)
		# Give Brody His Torch/Weapons :
		%Torch.visible = true
		# Turn ON DarknessLayer Effect :
		%DarknessLayer.visible = true
		# Turn ON GameplayUI :
		%GameplayUI.visible = true
		# Enable ability for Touchscreen Controls (Temporarily) 
		touchscreen_available = true
		%TouchScreenLayer.visible = true
		%TorchJoystickBase.visible = true
		%TorchJoystickSprite.visible = true
		%ShieldButton.visible = true
		EventBus.intro = false
		
	else :
		# START TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
		%DarknessChecker.start()
		%ShadowSpawnTimer.start()
		%TorchWraithChance.start()
		%WormBatChance.start()
		# Brody Cam :
		%BrodyCam.zoom = Vector2(1.6875, 1.6875)
		# Give Brody His Torch/Weapons :
		%Torch.visible = true
		# Turn ON DarknessLayer Effect :
		%DarknessLayer.visible = true
		# Turn ON GameplayUI :
		%GameplayUI.visible = true
		# Enable ability for Touchscreen Controls (Temporarily) 
		touchscreen_available = true
		%TouchScreenLayer.visible = true
		%TorchJoystickBase.visible = true
		%TorchJoystickSprite.visible = true
		%ShieldButton.visible = true

func sanctuary_raid_started() :
	raid_active = true
	# Give Brody His Torch/Weapons :
	%Torch.visible = true
	# Enable ability for Touchscreen Controls (Temporarily) 
	%TorchJoystickBase.visible = true
	%TorchJoystickSprite.visible = true
	%ShieldButton.visible = true
	%GoblinAttackText.visible = true
	raid_shake()
	raid_flashing()

func raid_shake() :
	# Shaking:
	while raid_active == true :
		%Brody.camera_shake_small()
		await get_tree().create_timer(1.5).timeout

func raid_flashing() :
	# Flashing:
	while raid_active == true :
		%GoblinAttackText.flash_white()
		await get_tree().create_timer(1.5).timeout

func sanctuary_raid_finished() :
	raid_active = false
	# Give Brody His Torch/Weapons :
	%Torch.visible = false
	# Enable ability for Touchscreen Controls (Temporarily) 
	%TorchJoystickBase.visible = false
	%TorchJoystickSprite.visible = false
	%ShieldButton.visible = false
	%GoblinAttackText.visible = false

func introduce_orble(orble) :
	orble.global_position = %Brody.global_position + Vector2(-24, 0)
	orble.newly_spawned = true
	selected_orble = orble
	
	# Disable Touchscreen :
	%TouchScreenLayer.visible = false
	
	# Send camera in :
	%BrodyCam.offset = Vector2(-20, 0)
	%BrodyCam.zoom = Vector2(2.0, 2.0)
	
	# Open keyboard and give orble a name :
	var namepopup = preload("res://Scenes/travellers_sanctuary/OrbleVillage/namer_popup.tscn").instantiate()
	call_deferred("add_child", namepopup)

func orble_named(orble_particular) :
	selected_orble.name_visible(orble_particular)
	selected_orble.newly_spawned = false
	
	if EventBus.orbles_to_introduce <= 0 :
		# Reset Camera / Touchscreen etc :
		var cam_tween = create_tween()
		cam_tween.tween_property(%BrodyCam, "zoom", Vector2(1.5, 1.5), 1.0)
		cam_tween.tween_property(%BrodyCam, "offset", Vector2(0.0, 0.0), 1.0)
		%TouchScreenLayer.visible = true

func new_dungeon_touchscreen() :
	%TouchScreenPress1.visible = true
	%TorchJoystickBase.visible = true
	%TorchJoystickSprite.visible = true
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # SANCTUARY :
func _on_spawning_sanctuary() :
	delete_current_memory()
	_set_sanctuary_properties()
	var new_sanctuary = preload("res://Scenes/custom_rooms/the_sanctuary.tscn").instantiate()
	new_sanctuary.z_index = 0
	new_sanctuary.global_position = Vector2(0, 0)
	%Brody.global_position = new_sanctuary.global_position + Vector2(136, 90)
	%RoomsToBeDeleted.call_deferred("add_child", new_sanctuary)

func _set_sanctuary_properties() :
	# If Intro Set Camera :
	if EventBus.intro == true :
		%BrodyCam.enabled = false
	# START TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
	%ShadowSpawnTimer.stop()
	%TorchWraithChance.stop()
	%WormBatChance.stop()
	# Camera :
	%BrodyCam.zoom = Vector2(1.5, 1.5)
	# Give Brody His Torch/Weapons :
	%Torch.visible = false
	# Turn ON DarknessLayer Effect :
	%DarknessLayer.visible = false  
	# Turn ON GameplayUI :
	%GameplayUI.visible = false
	# Enable ability for Touchscreen Controls (Temporarily) 
	touchscreen_available = false
	%TouchScreenLayer.visible = true
	%TorchJoystickSpriteHighlighted.visible = false
	%TorchJoystickBase.visible = false
	%TorchJoystickSprite.visible = false
	%ShieldButton.visible = false
	%StaminaBarGreen.visible = false

func shop_closed() :
	EventBus.save_game()
	EventBus.currently_interacting = false
	%DashButton.visible = true
	%TouchScreenPress2.visible = true
	%TouchScreenLayer.visible = true
	%Brody.input_enabled = true

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MEMORY / LOADING :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func delete_current_memory() :
	# If any rooms around, delete them :
	var deletable_rooms = %RoomsToBeDeleted.get_children()
	for entity in deletable_rooms:
		entity.queue_free()
	# If any monsters/entities around, delete them :
	var deletable_creatures = %MonstersToBeGone.get_children()
	for deletables in deletable_creatures :
		deletables.queue_free()
	# Delete Any Other Assets Spawned In Real Time (e.g. Currency) :
	var deletable_entities = %EntitiesToBeDeleted.get_children()
	for deletables in deletable_entities :
		deletables.queue_free()

func loading_screen() :
	delete_current_memory()
