extends Area2D

var lit = false

func _ready() :
	material = $".".material.duplicate()
	set_tint()
	
	%BrazierSprite.play("unlit")
	%MainFlame.emitting = false
	%MainFlameSecondary.emitting = false
	%BrazierLight.enabled = false

func set_tint() :
	if EventBus.current_theme == 1 : # Reg :
		material.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, 1.0))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.04)
	elif EventBus.current_theme == 2 : # Ice :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.067, 0.988, 0.988))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.04)
	elif EventBus.current_theme == 3 : # Hell :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.976, 0.192, 0.298, 1.0))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.04)
	elif EventBus.current_theme == 4 : # Overgrown :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.0, 0.306, 0.078, 1.0))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.04)


# This function is to stop braziers being counted before they are visible (blocking doors and the player from succeeding) :
func now_visible() :
	EventBus.emit_signal("beacon_spawned")
	add_to_group("braziers")
	visible = true

func brazier_lit() :
	if lit == false :
		# Create a tween for both more particles to appear over time and more light to appear overtime :
		lit = true
		# Let Game Know Beacon is Lit :
		EventBus.beacon_lit.emit()
		remove_from_group("braziers")
		%BrazierSprite.play("lit")
		%DarknessRepellerCollision.call_deferred("set_disabled", false)
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
	if area.name == "Torch" and $".".visible == true :
		brazier_lit()
		%FlashingTimer.stop()


func flash_white():
	var mat = $".".material
	if mat == null:
		return
		
	# Flash up to white
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/flash_amount", 1.0, 0.3)
	
	# Fade back down
	tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)
	
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(mat, "shader_parameter/flash_amount", 1.0, 0.3)
	
	# Fade back down
	tween2.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)


func _on_flashing_timer_timeout() :
	if lit == false :
		flash_white()


func _on_darkness_repeller_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		# Darkness Level Decreasing :
		body.resting()
		%DarknessReducer.start()


func _on_darkness_repeller_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		# Stop Darkness Level Decreasing :
		body.nolonger_resting()
		%DarknessReducer.stop()


func _on_darkness_reducer_timeout() -> void:
	EventBus.total_current_darkness -= 2
