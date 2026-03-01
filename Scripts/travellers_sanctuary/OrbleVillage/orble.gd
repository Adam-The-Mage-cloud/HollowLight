extends CharacterBody2D

# Movement Variables :
var direction = Vector2.ZERO
var speed = 2000

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 256

var orble_look = "default"

var first_speech = true

var old_pos = Vector2.ZERO

func _ready() -> void:
	randomize()
	assign_outfit()
	home_position = global_position
	%OrbleSprite.play(str(orble_look) + "_stationary")
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func assign_outfit() :
	var orble_look_identifier = randi_range(1, 3)
	if orble_look_identifier == 1 : # regular green :
		orble_look = "default"
	elif orble_look_identifier == 2 : # blue :
		orble_look = "blue"
	elif orble_look_identifier == 3 : # purple :
		orble_look = "purple"


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
	%OrbleSprite.play(str(orble_look) + "_stationary")
	
	direction = Vector2.ZERO
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func moving() :
	%OrbleSprite.play(str(orble_look) + "_moving")


func footsteps_activated() :
	while direction != Vector2.ZERO:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.2).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.2).timeout


func _on_direction_timer_timeout() -> void:
	if EventBus.sanctuary_under_attack == false :
		%MovementTimeTimer.wait_time = randf_range(0.6, 3.6)
		%MovementTimeTimer.start()
		
		if randi_range(1, 2) == 1 : # Then move :
			
			direction = Vector2(randf_range(-0.65, 0.65), randf_range(-0.65, 0.65))
			
			moving()
			
		else : # LET'S STRETCH OR REST :
				%OrbleSprite.play(str(orble_look) + "_sleeping")


func _on_propose_time_timeout() -> void:
	if randi_range(1, 12) == 1 : # THEN PROPOSE TO THE FOREST
		print("happening")
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %sanctuary_ritual_site.global_position - $".".global_position
		direction = direction.normalized()
		moving()


func _on_interaction_area_area_entered(area: Node2D) -> void:
	if area.name == "RitualArea" :
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		direction = Vector2.ZERO
		%OrbleSprite.play(str(orble_look) + "_celebrating")
		await get_tree().create_timer(randf_range(9.0, 16.0)).timeout
		%DirectionTimer.start()
		%MovementTimeTimer.start()
