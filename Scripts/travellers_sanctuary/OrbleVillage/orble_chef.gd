extends CharacterBody2D

# Movement Variables :
var direction = Vector2.ZERO
var speed = 2000

var orble_moving = false
var orble_cheffing = false

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 256

var orble_look = "default"

var first_speech = true

var old_pos = Vector2.ZERO

func _ready() -> void:
	randomize()
	home_position = global_position
	%ChefSprite.play("stationary")
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func bobble_hat():
	if !orble_moving:
		%ChefsHat.rotation_degrees = 0.0
		return
	
	var bobble = create_tween()
	bobble.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	bobble.tween_property(%ChefsHat, "rotation_degrees", randf_range(-6,0), 0.24)
	
	bobble.tween_property(%ChefsHat, "rotation_degrees", randf_range(0,6), 0.48)
	
	bobble.tween_property(%ChefsHat, "rotation_degrees", 0.0, 0.24) # Reset
	
	bobble.tween_callback(func ():
		if orble_moving == true :
			bobble_hat()
		else:
			%ChefsHat.rotation_degrees = 0.0)


func stir_pot():
	if !orble_cheffing:
		%CauldronLadle.rotation_degrees = 0.0
		return

	var stir = create_tween()
	stir.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var step = 2 + randf_range(-2, 2)  # Randomness = Imperfection !!!
	var a1 = step
	var a2 = step * 2
	var a3 = step * 3
	var a4 = step * 4

	stir.tween_property(%CauldronLadle, "rotation_degrees", a1, 0.18)
	stir.tween_property(%CauldronLadle, "rotation_degrees", a2, 0.18)
	stir.tween_property(%CauldronLadle, "rotation_degrees", a3, 0.18)
	stir.tween_property(%CauldronLadle, "rotation_degrees", a4, 0.18)

	stir.tween_callback(func():
		if orble_cheffing:
			stir_pot()
		else:
			%CauldronLadle.rotation_degrees = 180.0)


func _physics_process(delta: float) -> void:
	# Update velocity from direction
	velocity = direction * speed * delta

	# Move using physics
	move_and_slide()

	# Clamp inside patrol boundary
	var clamped_pos = global_position
	clamped_pos.x = clamp(clamped_pos.x, home_position.x - patrol_size, home_position.x + patrol_size)
	clamped_pos.y = clamp(clamped_pos.y, home_position.y - patrol_size, home_position.y + patrol_size)

	# If clamping changed the position → border reached
	if clamped_pos != global_position and direction != Vector2.ZERO:
		_on_movement_time_timer_timeout()

	# Apply the clamp
	global_position = clamped_pos

	# Footsteps
	if direction != Vector2.ZERO:
		footsteps_activated()


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	%ChefSprite.play("stationary")
	
	direction = Vector2.ZERO
	orble_moving = false
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func moving() :
	%ChefSprite.play("moving")
	orble_moving = true
	bobble_hat()


func footsteps_activated() :
	while direction != Vector2.ZERO:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.2).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.2).timeout


func _on_direction_timer_timeout() -> void:
	if EventBus.sanctuary_under_attack == false and orble_cheffing == false:
		%MovementTimeTimer.wait_time = randf_range(0.6, 3.8)
		%MovementTimeTimer.start()
		
		if randi_range(1, 2) == 1 : # Then move :
			
			direction = Vector2(randf_range(-0.65, 0.65), randf_range(-0.65, 0.65))
			
			moving()
			
		else : # LET'S STRETCH OR REST :
				%ChefSprite.play("sleeping")


func _on_propose_time_timeout() -> void:
	if randi_range(1, 12) == 1 : # THEN PROPOSE TO THE FOREST
		print("happening")
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %sanctuary_ritual_site.global_position - $".".global_position
		direction = direction.normalized()
		moving()


func _on_interaction_area_area_entered(area: Node2D) -> void:
	if area.name == "CheffingArea" :
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		direction = Vector2.ZERO
		%ChefSprite.play("stationary")
		# THEN WE TWEEN THE CHEF TO JUMP UP ON THE STEPLADDER :
		var jump_up = create_tween()
		jump_up.tween_property($".", "global_position", area.global_position + Vector2(0, -10), 1.0)
		await jump_up.finished
		
		# NOW START STIRRING THE CAULDRON :
		orble_cheffing = true
		var ladle_lower = create_tween().set_parallel(true)
		ladle_lower.tween_property(%CauldronLadle, "rotation_degrees", 0, 1.0)
		ladle_lower.tween_property(%CauldronLadle, "position", Vector2(-11.0, 14.5), 1.0)
		ladle_lower.tween_property(%CauldronLadle, "scale:x", 1.0, 1.0)
		await ladle_lower.finished
		stir_pot()
		area.get_parent().stirring()
		
		await get_tree().create_timer(randf_range(13.0, 24.0)).timeout
		orble_cheffing = false
		area.get_parent().stop_stirring()
		var ladle_raise = create_tween().set_parallel(true)
		ladle_raise.tween_property(%CauldronLadle, "rotation_degrees", 180, 1.0)
		ladle_raise.tween_property(%CauldronLadle, "position", Vector2(-12.0, -4.0), 1.0)
		ladle_raise.tween_property(%CauldronLadle, "scale:x", -1.0, 1.0)
		%DirectionTimer.start()
		%MovementTimeTimer.start()
		
		await ladle_raise.finished
		# JUMP DOWN :
		jump_down()

func jump_down():
	var start_pos = position
	var end_pos = position + Vector2(7, 14)
	
	# Height of the jump
	var jump_height = -22.0
	
	# Tween container
	var jump = create_tween()
	jump.set_parallel(true)
	
	# Vertical arc (up → down)
	jump.tween_property(self, "position:y", start_pos.y + jump_height, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	jump.tween_property(self, "position:y", end_pos.y, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Horizontal drift (start → end)
	jump.tween_property(self, "position:x", end_pos.x, 0.60)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await jump.finished
	
	start_pos = position
	end_pos = position + Vector2(7, 14)
	
	# Tween container
	var jump2 = create_tween()
	jump2.set_parallel(true)
	
	# Vertical arc (up → down)
	jump2.tween_property(self, "position:y", start_pos.y + jump_height, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	jump2.tween_property(self, "position:y", end_pos.y, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Horizontal drift (start → end)
	jump2.tween_property(self, "position:x", end_pos.x, 0.60)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_cooking_time_timeout() -> void:
	if randi_range(1, 4) == 4 and orble_cheffing == false : # THEN GO TO COOK
		print("happening")
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %orble_chefstation.global_position - $".".global_position
		direction = direction.normalized()
		moving()
