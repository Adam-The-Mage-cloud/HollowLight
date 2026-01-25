extends Node2D

var Shadow_Cloud = preload("res://Scenes/the_shadow.tscn")

var is_touchscreen = false

var darkness_increase_per_second = 2

var room_finished = false

func _ready() :
	randomize()

# Wait For Touchscreen to be Pressed to turn on touchscreen settings :
func _input(event):
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
		%MonstersLayer.add_child(new_shadowcloud)
	if EventBus.total_current_darkness >= 5 :
		%ShadowSpawnTimer.wait_time = (10.0 / (EventBus.total_current_darkness / 5)) # THIS MIGHT NEED SOME TLC LOL AND THE DISTANCE RANGE ABOVE!


func _on_torch_wraith_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 3 :
			var TorchWraith = preload("res://Scenes/torch_wraith.tscn").instantiate()
			TorchWraith.global_position = %RegularFollowPath.global_position
			TorchWraith.target = %Brody
			%MonstersLayer.add_child(TorchWraith)
			%TorchWraithChance.wait_time += randf_range(-1, 1)


func _on_worm_bat_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 2 :
			var WormBat = preload("res://Scenes/worm_bat.tscn").instantiate()
			WormBat.global_position = %RegularFollowPath.global_position
			WormBat.target = %Brody
			%MonstersLayer.add_child(WormBat)
			if %WormBatChance.wait_time > 2 :
				%WormBatChance.wait_time += randf_range(-1, 1)
			else :
				%WormBatChance.wait_time += 3


func _on_darkness_checker_timeout() -> void:
	EventBus.total_current_darkness = clamp(EventBus.total_current_darkness + darkness_increase_per_second, 1.0, 100.0)
