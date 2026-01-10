extends Area2D

var lit = false

func _ready() :
	EventBus.emit_signal("beacon_spawned")
	%BrazierSprite.play("unlit")
	%MainFlame.emitting = false
	%MainFlameSecondary.emitting = false
	%BrazierLight.enabled = false

func brazier_lit() :
	if lit == false :
		# Create a tween for both more particles to appear over time and more light to appear overtime :
		lit = true
		# Let Game Know Beacon is Lit :
		EventBus.beacon_lit.emit()
		%BrazierSprite.play("lit")
		%BrazierLight.enabled = true
		%MainFlame.emitting = true
		%MainFlameSecondary.emitting = true
		var intro_light_tween = create_tween()
		intro_light_tween.tween_property(%BrazierLight, "energy", 0.8, 1.4)
		intro_light_tween.tween_property(%BrazierLight, "texture_scale", 0.4, 1.4)
		
		var intro_particles_tween = create_tween()
		intro_particles_tween.tween_property(%MainFlame, "amount_ratio", 0.05, 1.4)
		intro_particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 0.05, 1.4)
		
		await get_tree().create_timer(2).timeout
		var light_tween = create_tween()
		light_tween.tween_property(%BrazierLight, "energy", 2.4, 4.0)
		light_tween.tween_property(%BrazierLight, "texture_scale", 1.0, 3.5)
		
		var particles_tween = create_tween()
		particles_tween.tween_property(%MainFlame, "amount_ratio", 1.00, 5.5)
		particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 1.00, 4.0)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		brazier_lit()
