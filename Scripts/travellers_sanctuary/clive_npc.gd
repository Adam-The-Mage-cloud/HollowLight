extends CharacterBody2D

# Movement Variables :
var direction = Vector2.ZERO
var speed = 24

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 64 

var old_pos = Vector2.ZERO

func _ready() -> void:
	randomize()
	home_position = global_position
	%CliveSprite.play("stood_still_front")
	%DirectionTimer.start()


func _process(delta: float) -> void:
	var new_pos = global_position + direction * speed * delta
	old_pos = new_pos
	
	# Clamp inside the boundary
	new_pos.x = clamp(new_pos.x, home_position.x - patrol_size, home_position.x + patrol_size)
	new_pos.y = clamp(new_pos.y, home_position.y - patrol_size, home_position.y + patrol_size)
	
	# If clamping changed the position → border reached
	if new_pos != old_pos and direction != Vector2.ZERO:
		_on_movement_time_timer_timeout()
	
	global_position = new_pos


func _on_direction_movement_timer_timeout() -> void:
	%MovementTimeTimer.wait_time = randf_range(2.4, 3.6)
	%MovementTimeTimer.start()
	
	var possible_dirs: Array[Vector2] = []
	
	# Only choose directions that stay inside the square
	if global_position.y > home_position.y - patrol_size:
		possible_dirs.append(Vector2(0, -1))
	if global_position.y < home_position.y + patrol_size:
		possible_dirs.append(Vector2(0, 1))
	if global_position.x > home_position.x - patrol_size:
		possible_dirs.append(Vector2(-1, 0))
	if global_position.x < home_position.x + patrol_size:
		possible_dirs.append(Vector2(1, 0))
	
	# Pick a valid direction
	if possible_dirs.size() > 0:
		direction = possible_dirs.pick_random()
	else:
		direction = Vector2.ZERO
	
	check_direction_animation()


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	if direction == Vector2(0, -1):
		%CliveSprite.play("stood_still_back")
	elif direction == Vector2(0, 1):
		%CliveSprite.play("stood_still_front")
	elif direction == Vector2(1, 0):
		%CliveSprite.play("stood_still_sideways")
		scale.x = 1
	elif direction == Vector2(-1, 0):
		%CliveSprite.play("stood_still_sideways")
		scale.x = -1
	
	direction = Vector2.ZERO
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func check_direction_animation() -> void:
	if direction == Vector2(0, -1):
		%CliveSprite.play("moving_up")
	elif direction == Vector2(0, 1):
		%CliveSprite.play("moving_down")
	elif direction == Vector2(1, 0):
		%CliveSprite.play("moving_sideways")
		scale.x = 1
	elif direction == Vector2(-1, 0):
		%CliveSprite.play("moving_sideways")
		scale.x = -1

# ON BODY ENTERED (LOAD MENU)
func load_dialogue() :
	# Load Dialogue of which we can then access the shop :
	# access_clives_shop()
	pass

func access_clives_shop() :
	# NORMAL AFFORDABLE ITEMS / UPGRADES / COSMETICS
	# MICRO-TRANSACTIONS
	pass
