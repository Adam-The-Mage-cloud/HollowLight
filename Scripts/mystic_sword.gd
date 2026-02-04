extends Node2D

enum State { ORBIT, SEEK, RETURN }

@export var player: Node2D

# Wandering around Brody behaviour :
@export var wander_radius = 12.0
@export var wander_speed = 1.2
@export var leash_strength = 1.6

# Seeking behaviour variables :
@export var seek_speed: float = 90.0
@export var seek_accel: float = 240.0

# Rotation and rotation bob variables :
@export var turn_speed: float = 5.0
@export var bob_amount: float = 4.0
@export var bob_speed: float = 2.0

var state: State = State.ORBIT
var target_enemy: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var return_timer = 0.0

# Wandering noise variables :
var wander_offset = Vector2.ZERO
var wander_noise = FastNoiseLite.new()
var wander_time = 0.0

func _ready() -> void:
	randomize()
	player = get_tree().current_scene.get_node("Brody")
	add_to_group("PlayerSidekick")

func _process(delta: float) -> void:
	match state:
		State.ORBIT:
			_orbit(delta)
		State.SEEK:
			_seek(delta)
		State.RETURN:
			_return_to_orbit(delta)

# ---------------------------------------------------------
# ORBIT MODE — A wandering spectral companion feel :
# ---------------------------------------------------------
func _orbit(delta: float) -> void:
	if player == null:
		return

	wander_time += delta * wander_speed

	# Wandering :
	var noise_x = wander_noise.get_noise_1d(wander_time)
	var noise_y = wander_noise.get_noise_1d(wander_time + 100.0)
	wander_offset = Vector2(noise_x, noise_y) * wander_radius

	# Magical bobbing feel :
	var bob = Vector2(0, sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_amount)

	# Desired position :
	var desired_pos = player.global_position + wander_offset + bob

	# Smooth drifting toward desired position :
	var to_desired = desired_pos - global_position
	global_position += to_desired * delta * leash_strength

	# Smooth rotation toward movement direction :
	if to_desired.length() > 0.01:
		_smooth_rotate(to_desired.angle(), delta)

# ---------------------------------------------------------
# SEEK MODE
# ---------------------------------------------------------
func _seek(delta: float) -> void:
	if not is_instance_valid(target_enemy):
		_switch_to_return()
		return

	var to_target = target_enemy.global_position - global_position
	var dist = to_target.length()

	if dist < 10.0:
		_switch_to_return()
		return

	# Accelerate toward target :
	var desired = to_target.normalized() * seek_speed
	velocity = velocity.move_toward(desired, seek_accel * delta)

	global_position += velocity * delta

	# Smooth turning with slight magical overshootiness :
	var target_angle = velocity.angle()
	_smooth_rotate(target_angle, delta, 0.15)

# ---------------------------------------------------------
# RETURN TO ORBIT MODE
# ---------------------------------------------------------
func _return_to_orbit(delta: float) -> void:
	if player == null:
		return

	return_timer += delta

	# Move back towards Brody :
	var desired_pos = player.global_position
	var to_player = desired_pos - global_position

	if to_player.length() < 8.0:
		state = State.ORBIT
		velocity = Vector2.ZERO
		return

	velocity = velocity.move_toward(to_player.normalized() * seek_speed * 0.6, seek_accel * delta)
	global_position += velocity * delta

	_smooth_rotate(velocity.angle(), delta)

# ---------------------------------------------------------
# ROTATION HELPERS
# ---------------------------------------------------------
func _smooth_rotate(target_angle: float, delta: float, overshoot = 0.0) -> void:
	target_angle += sin(Time.get_ticks_msec() * 0.001 * 3.0) * overshoot
	rotation = lerp_angle(rotation, target_angle, turn_speed * delta)

# ---------------------------------------------------------
# STATE SWITCHING
# ---------------------------------------------------------
func _switch_to_seek(enemy: Node2D) -> void:
	target_enemy = enemy
	state = State.SEEK

func _switch_to_return() -> void:
	target_enemy = null
	state = State.RETURN
	return_timer = 0.0

# ---------------------------------------------------------
# SIGNAL: Enemy enters detection area
# ---------------------------------------------------------
func _on_enemy_radar_area_entered(area: Area2D) -> void:
	if area.get_parent().visible == true :
		_switch_to_seek(area)
