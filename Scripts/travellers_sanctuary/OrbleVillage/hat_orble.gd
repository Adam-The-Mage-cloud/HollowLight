extends CharacterBody2D

var health = 2
var orble_name

var raided = false

signal orble_named(name)

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

var orble_proposing = false

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 256
var speed = 12

var orble_look = "default"

var first_speech = true

var old_pos = Vector2.ZERO
var target_position: Vector2
var stuck_time = 0.0
var last_position = Vector2.ZERO

var collected = false
var newly_spawned = false

func _ready() -> void:
	randomize()
	material = material.duplicate()
	home_position = global_position
	$".".add_to_group("orbles")
	
	%HatOrbleSprite.play("stationary")
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()
	
	if EventBus.sanctuary == false :
		flash_actual_white()
		
	#if newly_spawned == true :
		#pass

func name_visible(name) :
	%OrbleNameTag.visible = true
	%OrbleNameTag.text = name
	orble_name = name
	emit_signal("orble_named", name)

func _physics_process(delta: float) -> void:
	# STATES WITH NO DIRECTION :
	if EventBus.sanctuary == true and newly_spawned == false :
		if state == STATE_SLEEP:
			%FervourProduced.emitting = false
			velocity = Vector2.ZERO
			move_and_slide()
			return
			
		elif state == STATE_PROPOSE:
			# Move only toward ritual site
			%FervourProduced.emitting = false
			velocity = direction * speed
			move_and_slide()
			return
			
		elif state == STATE_CELEBRATE:
			%FervourProduced.emitting = true
			velocity = Vector2.ZERO
			move_and_slide()
			return
			
		# Time To Wanderrr :
		elif state == STATE_WANDER:
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
				%HatOrbleSprite.play("moving")
			else:
				%HatOrbleSprite.play("stationary")

func check_health(area) :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)
	
	# knockback :
	var knockback_direction = (global_position - area.global_position).normalized()
	var knockback_movement = create_tween()
	knockback_movement.tween_property(self, "position", position + knockback_direction * 24.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	health -= 1
	if health <= 0 :
		death()

func death() :
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Slow, reverent spin
	tween.tween_property($".", "rotation_degrees", $".".rotation_degrees + 180, 1.44)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Rise upward
	tween.tween_property($".", "position:y", $".".position.y - 30, 1.44)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Divine expansion instead of shrinking
	tween.tween_property($".", "scale", Vector2(0, 0), 1.44)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Fade out at the peak
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 1.44)
	
	
	await tween.finished
	
	# Find Orble in the orble Array and make "" :
	for i in range (EventBus.max_orble_count) :
		if EventBus.orbles[i] == orble_name :
			EventBus.orbles[i] = ""
	
	queue_free()

func pick_new_target():
	# Pick a random point inside the patrol area
	var offset = Vector2(
		randf_range(-patrol_size, patrol_size),
		randf_range(-patrol_size, patrol_size)
	)
	target_position = home_position + offset


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	%HatOrbleSprite.play("stationary")
	
	direction = Vector2.ZERO
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func moving() :
	state = STATE_WANDER
	pick_new_target()
	
	%HatOrbleSprite.play("moving")

func run_upwards(boost = 2.0):
	while EventBus.raid_entity_count > 0 :
		state = STATE_WANDER
		direction = Vector2(0.25, -1)
		speed = 24 * boost
		await get_tree().create_timer(0.2).timeout
	speed = 24
	_on_movement_time_timer_timeout()

func footsteps_activated() :
	while direction != Vector2.ZERO:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.2).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.2).timeout


func _on_direction_timer_timeout() -> void:
	if EventBus.sanctuary_under_attack == false  and EventBus.sanctuary == true :
		%MovementTimeTimer.wait_time = randf_range(0.6, 3.6)
		%MovementTimeTimer.start()
		
		if randi_range(1, 2) == 1 : # Then move :
			
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			
			moving()
			
		else : # LET'S STRETCH OR REST :
			state = STATE_SLEEP
			%HatOrbleSprite.play("sleeping")

func create_stack(partner) :
	%DirectionTimer.stop()
	%MovementTimeTimer.stop()
	direction = global_position - partner.global_position
	await get_tree().create_timer(0.35).timeout
	direction = Vector2.ZERO
	global_position = partner.global_position + Vector2(0, -2)
	
	await get_tree().create_timer(4.4).timeout
	%DirectionTimer.start()
	%MovementTimeTimer.start()

func _on_propose_time_timeout() -> void:
	if randi_range(1, 12) == 1 and not orble_proposing and EventBus.sanctuary == true :
		orble_proposing = true
		state = STATE_PROPOSE
		
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		
		if get_parent().get_node("sanctuary_ritual_site") != null :
			direction = (get_parent().get_node("sanctuary_ritual_site").global_position - global_position).normalized()
		%HatOrbleSprite.play("moving")

func flash_actual_white() :
	while EventBus.sanctuary == false and collected == false:
		var tween = create_tween()
		tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
		tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)
		await get_tree().create_timer(0.9).timeout

func _on_interaction_area_area_entered(area: Node2D) -> void:
	if area.name == "RitualArea":
		state = STATE_CELEBRATE
		direction = Vector2.ZERO
		
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		%HatOrbleSprite.play("celebrating")
		
		await get_tree().create_timer(randf_range(9.0, 16.0)).timeout
		
		state = STATE_WANDER
		orble_proposing = false
		pick_new_target()



func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and EventBus.sanctuary == false :
		collected = true
		EventBus.orbles_rescued += 1
		EventBus.orbles_to_introduce += 1
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Slow, reverent spin
		tween.tween_property($".", "rotation_degrees", $".".rotation_degrees + 180, 1.44)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		# Rise upward
		tween.tween_property($".", "position:y", $".".position.y - 30, 1.44)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		# Divine expansion instead of shrinking
		tween.tween_property($".", "scale", Vector2(0, 0), 1.44)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Fade out at the peak
		tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 1.44)
		
		
		await tween.finished
		queue_free()
	
	elif body.name == "orble" :
		if randi_range(2, 2) == 2 : 
			body.create_stack($".")
