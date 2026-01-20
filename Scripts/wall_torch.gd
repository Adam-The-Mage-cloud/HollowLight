extends Area2D

var lit = false 

func _ready() :
	#material = $".".material.duplicate()
	%WallTorchSprite.play("unlit")
	%MainFlame.emitting = false
	%MainFlameSecondary.emitting = false
	%WallTorchLight.enabled = false

func wall_torch_lit() :
	if lit == false :
		# Create a tween for both more particles to appear over time and more light to appear overtime :
		lit = true
		# Let Game Know Beacon is Lit :
		%WallTorchSprite.play("unlit")
		%WallTorchLight.enabled = true
		%MainFlame.emitting = true
		%MainFlameSecondary.emitting = true
		var intro_light_tween = create_tween()
		intro_light_tween.tween_property(%WallTorchLight, "energy", 0.8, 1.4)
		intro_light_tween.tween_property(%WallTorchLight, "texture_scale", 0.4, 1.4)
		
		var intro_particles_tween = create_tween()
		intro_particles_tween.tween_property(%MainFlame, "amount_ratio", 0.05, 1.4)
		intro_particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 0.05, 1.4)
		
		await get_tree().create_timer(2).timeout
		var light_tween = create_tween()
		light_tween.tween_property(%WallTorchLight, "energy", 2.4, 4.0)
		light_tween.tween_property(%WallTorchLight, "texture_scale", 1.0, 3.5)
		
		var particles_tween = create_tween()
		particles_tween.tween_property(%MainFlame, "amount_ratio", 1.00, 5.5)
		particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 1.00, 4.0)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		wall_torch_lit()
