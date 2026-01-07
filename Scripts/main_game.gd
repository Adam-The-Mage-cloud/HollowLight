extends Node2D

var Shadow_Cloud = preload("res://Scenes/the_shadow.tscn")

func _ready() :
	randomize()

func _on_shadow_spawn_timer_timeout() -> void:
	# Spawn another Shadow cloud :
	var new_shadowcloud = Shadow_Cloud.instantiate()
	new_shadowcloud.global_position = Vector2(randf_range(0, 320), randf_range(0, 144))
	new_shadowcloud.target = %Brody
	add_child(new_shadowcloud)
	 
