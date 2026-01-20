extends Area2D

func _ready() :
	randomize()
	var scale_value_x = randf_range(0.5, 6)
	var scale_value_y = randf_range(0.5, 6)
	if randi_range(1, 2) == 2 :
		scale_value_x *= 1.24
	else  :
		scale_value_y *= 1.24
	$".".scale = Vector2(scale_value_x, scale_value_y)
	%OutsideLightArea.energy = randf_range(0.4, 12)
	
	var light_scale_x = randf_range(0.14, 0.22)
	var light_scale_y = randf_range(0.14, 0.22)
	%OutsideLightArea.scale = Vector2(light_scale_x, light_scale_y)
