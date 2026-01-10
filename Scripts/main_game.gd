extends Node2D

var Shadow_Cloud = preload("res://Scenes/the_shadow.tscn")

var current_sanity_volume = 4 # How many, and how long 
var current_sanity_scale = 2 # How big of a cloud they should spawn as in line with sanity volume

var room_finished = false

func _ready() :
	randomize()

func _on_shadow_spawn_timer_timeout() -> void:
	# Spawn another Shadow cloud :
	%RegularFollowPath.progress_ratio = randf_range(0, 1)
	var initial_spawn_position = %RegularFollowPath.global_position
	for i in range(current_sanity_volume + randf_range(current_sanity_scale, current_sanity_scale + 1)) :
		var new_shadowcloud = Shadow_Cloud.instantiate()
		new_shadowcloud.global_position = initial_spawn_position + Vector2(current_sanity_scale * randf_range(-7.5,7.5), current_sanity_scale * randf_range(-7.5, 7.5))
		new_shadowcloud.target = %Brody
		add_child(new_shadowcloud)
	%ShadowSpawnTimer.wait_time = 10.0 / current_sanity_scale


func _on_torch_wraith_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 3 :
			var TorchWraith = preload("res://Scenes/torch_wraith.tscn").instantiate()
			TorchWraith.global_position = %RegularFollowPath.global_position
			TorchWraith.target = %Brody
			add_child(TorchWraith)
			%TorchWraithChance.wait_time += randf_range(-1, 1)

func _on_worm_bat_chance_timeout() -> void:
	if room_finished == false :
		%RegularFollowPath.progress_ratio = randf_range(0, 1)
		if randi_range(1, 5) == 2 :
			var WormBat = preload("res://Scenes/worm_bat.tscn").instantiate()
			WormBat.global_position = %RegularFollowPath.global_position
			WormBat.target = %Brody
			add_child(WormBat)
			%WormBatChance.wait_time += randf_range(-1, 1)
