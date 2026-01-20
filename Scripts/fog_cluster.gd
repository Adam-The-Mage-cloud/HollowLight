extends Node2D

@onready var t = 1.0 # our time variable (for randomness)

func _ready() -> void:
	%FogTexture.material = %FogTexture.material.duplicate()
	%FogTexture.modulate.a = randf_range(0.1, 0.3)
	%FogTexture.scale = Vector2.ONE * randf_range(0.8, 3.6)
	%FogTexture.rotation = randf_range(0, TAU)
	%FogTexture.material.set_shader_parameter("noise_scale", randf_range(0.8, 1.2))
	%FogTexture.material.set_shader_parameter("distortion_amount", randf_range(0.01, 0.03))
	%FogTexture.material.set_shader_parameter("softness", randf_range(8.0, 14.0))
	%FogTexture.material.set_shader_parameter("intensity", randf_range(0.125, 0.275))

func _process(delta: float) -> void:
	#position += Vector2(2, -2) * delta
	rotation += 0.01 * delta
	#scale += Vector2(0.02, 0.02) * sin(t * 0.5)
	t += delta # like a clock
