extends Node2D

var Shadow_Cloud = preload("res://Scenes/the_shadow.tscn")

var is_touchscreen = false
var touchscreen_available = true

var darkness_increase_per_second = 3.5

var room_finished = false

func _ready() :
	randomize()
	# Connect Main Game To Certain Gameplay Events (For Node Removal/Performance etc e.g. Dungeon Reset / Sanctuary Spawn)
	EventBus.last_room_complete.connect(_on_dungeon_ended)
	EventBus.new_crawl.connect(_on_new_dungeon_crawl)
	EventBus.spawn_sanctuary.connect(_on_spawning_sanctuary)
	
	# Start in Sanctuary :
	_set_sanctuary_properties()

# Wait For Touchscreen to be Pressed to turn on touchscreen settings :
func _input(event):
	if touchscreen_available == true :
		if event is InputEventScreenTouch:
			is_touchscreen = true
			%BrodyCam.zoom = Vector2(1.5, 1.5)
			%TouchScreenLayer.visible = true

func _process(_delta: float) -> void: 
	%DarknessEffect.modulate.a = EventBus.total_current_darkness / 100

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
			var TorchWraith = preload("res://Scenes/torch_wraith.tscn").instantiate()
			TorchWraith.global_position = %RegularFollowPath.global_position
			TorchWraith.target = %Brody
			%MonstersToBeGone.add_child(TorchWraith)
			%TorchWraithChance.wait_time += randf_range(-1, 1)


func _on_worm_bat_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 2 :
			var WormBat = preload("res://Scenes/worm_bat.tscn").instantiate()
			WormBat.global_position = %RegularFollowPath.global_position
			WormBat.target = %Brody
			%MonstersToBeGone.add_child(WormBat)
			if %WormBatChance.wait_time > 2 :
				%WormBatChance.wait_time += randf_range(-1, 1)
			else :
				%WormBatChance.wait_time += 3


func _on_darkness_checker_timeout() -> void:
	EventBus.total_current_darkness = clamp(EventBus.total_current_darkness + darkness_increase_per_second, 1.0, 100.0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GAMEPLAY EVENTS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# DUNGEON CRAWLING :
func _on_dungeon_ended() :
	# If any rooms around, delete them :
	delete_current_memory()
	# STOP TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
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

func _on_new_dungeon_crawl() :
	# Delete Previous Instances (e.g. Sanctuary) :
	delete_current_memory()
	# DISPLAY LOADING SCREEN and let LoadingOverlay handle the rest :
	%LoadingOverlay.show_loading()
	# Start With Spawning Trapdoor Room :
	var new_room = preload("res://Scenes/custom_rooms/trapdoor_room.tscn").instantiate()
	new_room.z_index = 0
	%Brody.global_position = new_room.global_position + Vector2(140, 14)
	%RoomsToBeDeleted.call_deferred("add_child", new_room)
	
	# START TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
	%ShadowSpawnTimer.start()
	%TorchWraithChance.start()
	%WormBatChance.start()
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
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # SANCTUARY :
func _on_spawning_sanctuary() :
	_set_sanctuary_properties()
	var new_sanctuary = preload("res://Scenes/custom_rooms/the_sanctuary.tscn").instantiate()
	new_sanctuary.z_index = 0
	%Brody.global_position = new_sanctuary.global_position + Vector2(140, 14)
	%RoomsToBeDeleted.call_deferred("add_child", new_sanctuary)

func _set_sanctuary_properties() :
	# START TIMERS / GAMEPLAY ONGOING THINGS / ENTITIES :
	%ShadowSpawnTimer.stop()
	%TorchWraithChance.stop()
	%WormBatChance.stop()
	# Give Brody His Torch/Weapons :
	%Torch.visible = false
	# Turn ON DarknessLayer Effect :
	%DarknessLayer.visible = false
	# Turn ON GameplayUI :
	%GameplayUI.visible = false
	# Enable ability for Touchscreen Controls (Temporarily) 
	touchscreen_available = true
	%TouchScreenLayer.visible = true
	%TorchJoystickBase.visible = false
	%TorchJoystickSprite.visible = false

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
