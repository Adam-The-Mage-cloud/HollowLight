extends CharacterBody2D

# Movement Variables :
var direction = Vector2.ZERO
var speed = 24

var orble_moving = false
var orble_serving = false
var orble_proposing = false
var at_shop = false

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 256

var orble_look = "default"

var raided = false

var first_speech = true

var old_pos = Vector2.ZERO

func _ready() -> void:
	randomize()
	home_position = global_position
	$".".add_to_group("orbles")
	%OrbleOverseerSprite.play("stationary")
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func _physics_process(delta: float) -> void:
	# Update velocity from direction
	velocity = direction * speed

	# Move using physics
	move_and_slide()

	# Footsteps
	if direction != Vector2.ZERO:
		footsteps_activated()


func player_interested() :
	if at_shop == false :
		speed = 60
		orble_serving = true
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %overseer_mission_board.global_position - $".".global_position
		direction = direction.normalized()
		moving()

func player_uninterested() :
	speed = 24
	orble_serving = false
	%DirectionTimer.start()
	%MovementTimeTimer.start()
	_on_direction_timer_timeout()


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	%OrbleOverseerSprite.play("stationary")
	
	direction = Vector2.ZERO
	orble_moving = false
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()

func run_upwards(boost = 2.0):
	while EventBus.raid_entity_count > 0 :
		direction = Vector2(0.25, -1) # straight upward
		speed = 24 * boost
		await get_tree().create_timer(0.2).timeout
	speed = 24
	_on_movement_time_timer_timeout()

func moving() :
	%OrbleOverseerSprite.play("moving")
	orble_moving = true


func footsteps_activated() :
	while direction != Vector2.ZERO:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.2).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.2).timeout


func _on_direction_timer_timeout() -> void:
	if EventBus.sanctuary_under_attack == false and orble_serving == false:
		%MovementTimeTimer.wait_time = randf_range(0.6, 3.8)
		%MovementTimeTimer.start()
		
		if randi_range(1, 2) == 1 : # Then move :
			
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			
			moving()
			
		else : # LET'S STRETCH OR REST :
				%OrbleOverseerSprite.play("sleeping")


func _on_propose_time_timeout() -> void:
	if randi_range(1, 12) == 1 and orble_proposing == false : # THEN PROPOSE TO THE FOREST
		orble_proposing = true
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %sanctuary_ritual_site.global_position - $".".global_position
		direction = direction.normalized()
		moving()


func _on_interaction_area_area_entered(area: Node2D) -> void:
	if area.name == "MissionBoardAccessArea" :
		at_shop = true
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		direction = Vector2.ZERO
		%OrbleOverseerSprite.play("stationary")
		
		# and just await player to leave so he can wander off again
	elif area.name == "RitualArea" :
		await get_tree().create_timer(randf_range(0.25, 0.65)).timeout
		direction = Vector2.ZERO
		%OrbleOverseerSprite.play("celebrating")
		await get_tree().create_timer(randf_range(9.0, 16.0)).timeout
		%DirectionTimer.start()
		%MovementTimeTimer.start()
		orble_proposing = false


func _on_mission_board_time_timeout() -> void:
	# Run To Billboard :
	if orble_serving == false :
		%DirectionTimer.stop()
		%MovementTimeTimer.stop()
		direction = %overseer_mission_board.global_position - global_position 
		direction = direction.normalized()
		moving()


func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area.name == "MissionBoardAccessArea" :
		at_shop = false
