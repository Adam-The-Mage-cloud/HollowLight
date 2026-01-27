extends TextureRect

@export var scroll_speed = Vector2(0.0035, 0) # pixels per second
var uv_offset = Vector2.ZERO

func _process(delta):
	uv_offset += scroll_speed * delta
	material.set_shader_parameter("uv_offset", uv_offset)
