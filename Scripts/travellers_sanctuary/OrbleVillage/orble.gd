extends CharacterBody2D

# State Machine Time :
enum {
	STATE_WANDER,
	STATE_SLEEP,
	STATE_PROPOSE,
	STATE_CELEBRATE
}

var state = STATE_WANDER


# Movement Variables :
var direction = Vector2.ZERO
var speed = 24

var orble_proposing = false

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 256

var orble_look = "default"

var first_speech = true

var old_pos = Vector2.ZERO
var target_position: Vector2
var stuck_time = 0.0
var last_position = Vector2.ZERO

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
	# STATES WITH NO DIRECTION :
	if state == STATE_SLEEP:
		%FervourProduced.emitting = false
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if state == STATE_PROPOSE:
		# Move only toward ritual site
		%FervourProduced.emitting = false
		velocity = direction * speed
		move_and_slide()
		return
		
	if state == STATE_CELEBRATE:
		%FervourProduced.emitting = true
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# Time To Wanderrr :
	if state == STATE_WANDER:
		%FervourProduced.emitting = false
		# Gain Direction :
		if target_position == Vector2.ZERO:
			pick_new_target()
			
		var to_target = (target_position - global_position)
		var distance = to_target.length()
		
		# If close to target, change lol (carnage)
		if distance < 12:
			pick_new_target()
			to_target = (target_position - global_position)
		
		# Smooth steering with lerp to feel life like :
		var desired_direction = to_target.normalized()
		direction = direction.lerp(desired_direction, 0.03).normalized()
		
		# Apply all these things to velocity :
		velocity = direction * speed
		move_and_slide()
		
		# DETECTING WHEN STUCK :
		var moved = global_position.distance_to(last_position)
		
		if moved < 0.5 and direction != Vector2.ZERO:
			stuck_time += delta
		else:
			stuck_time = 0.0
		
		if stuck_time > 0.25:
			pick_new_target()
			stuck_time = 0.0
		
		last_position = global_position
		
		# Patrol idek whether this is helping
		var clamped = global_position
		clamped.x = clamp(clamped.x, home_position.x - patrol_size, home_position.x + patrol_size)
		clamped.y = clamp(clamped.y, home_position.y - patrol_size, home_position.y + patrol_size)
		
		if clamped != global_position:
			pick_new_target()
		
		global_position = clamped
		
		# Animations :
		if direction != Vector2.ZERO:
			footsteps_activated()
			%OrbleSprite.play(orble_look + "_moving")
		else:
			%OrbleSprite.play(orble_look + "_stationary")



func pick_new_target():
	# Pick a random point inside the patrol area
	var offset = Vector2(
		randf_range(-patrol_size, patrol_size),
		randf_range(-patrol_size, patrol_size)
	)
	target_position = home_position + offset


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	%OrbleSprite.play(str(orble_look) + "_stationary")
	
	direction = Vector2.ZERO
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func moving() :
	state = STATE_WANDER
	pick_new_target()
	
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
			
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			
			moving()
			
		else : # LET'S STRETCH OR REST :
			state = STATE_SLEEP
			%OrbleSprite.play(str(orble_look) + "_sleeping")


func _on_propose_time_timeout() -> void:
	if randi_range(1, 12) == 1 and not orble_proposing:
		orble_proposing = true
		state = STATE_PROPOSE
		
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		
		direction = (%sanctuary_ritual_site.global_position - global_position).normalized()
		%OrbleSprite.play(str(orble_look) + "_moving")



func _on_interaction_area_area_entered(area: Node2D) -> void:
	if area.name == "RitualArea":
		state = STATE_CELEBRATE
		direction = Vector2.ZERO
		
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		%OrbleSprite.play(orble_look + "_celebrating")
		
		await get_tree().create_timer(randf_range(9.0, 16.0)).timeout
		
		state = STATE_WANDER
		orble_proposing = false
		pick_new_target()
