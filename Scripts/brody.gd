extends CharacterBody2D

var max_health = 5
var health = 5

var direction = Vector2.ZERO
var speed = 2240

var weapon_equipped = false
var torch_equipped = true

var bobbing = false

var dash_available = true
var dashing = false

func _ready() :
	breathing()

func _physics_process(delta: float) -> void:
	# Change Tool :
	if Input.is_action_just_pressed("tool_switch") :
		initialise_swap_tool() 
	# Check for Dash :
	if Input.is_action_pressed("dash") :
		dash_ability()
	# Check For Input :
	if Input.is_action_pressed("up") and Input.is_action_pressed("right") :
		direction = Vector2(1, -1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("up") and Input.is_action_pressed("left") :
		direction = Vector2(-1, -1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("right") :
		direction = Vector2(1, 1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("left") :
		direction = Vector2(-1, 1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("up") :
		direction = Vector2(0, -1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("down") :
		direction = Vector2(0, 1)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("right") :
		direction = Vector2(1, 0)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("left") :
		direction = Vector2(-1, 0)
		if dashing == false :
			%BrodySprite.play("moving")
		%feet.play("moving")
		
	else :
		direction = Vector2.ZERO
		%BrodySprite.play("stationary")
		%feet.play("stationary")
	
	# Antenna Movement :
	if direction != Vector2.ZERO and %antenna.rotation_degrees > -25 :
		%antenna.rotation_degrees -= 225 * delta
	elif direction == Vector2.ZERO and %antenna.rotation_degrees <= 0 :
		%antenna.rotation_degrees += 225 * delta # until at degrees = 0
	
	# Movement :
	direction = direction.normalized()
	velocity = (direction * speed) * delta
	move_and_slide()

func dash_ability():
	if dash_available == true:
		#flash_white()

		var target_angle = velocity.angle() * 180 / PI

		# --- Lean Into Direction (anticipation) ---
		var lean = create_tween()
		lean.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		lean.tween_property(%BrodySprite, "rotation_degrees", target_angle - 20, 0.08)

		# --- Roll Spin ---
		var roll_tween = create_tween()
		roll_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var current = %BrodySprite.rotation_degrees
		var spins = 1  # number of full rotations

		# Compute the next clean landing angle (smooth, no snapping)
		var target = (floor(current / 360.0) + spins) * 0 # CHANGE THIS 0 TO 360 ONCE THE ROLL ANIMATION IS ADDED IN 

		# Add a tiny overshoot for natural motion
		var overshoot = target + 18

		# Spin with overshoot
		roll_tween.tween_property(%BrodySprite, "rotation_degrees", overshoot, 0.22)

		# Ease back into the final clean angle
		roll_tween.tween_property(%BrodySprite, "rotation_degrees", target, 0.12)

		# --- Squash & Stretch ---
		var squash = create_tween()
		squash.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		squash.tween_property(%BrodySprite, "scale", Vector2(1.3, 0.8), 0.1)
		squash.tween_property(%BrodySprite, "scale", Vector2(1, 1), 0.2)

		# --- Dash Logic ---
		dashing = true
		dash_available = false
		%DashCooldown.start()
		speed = 3000
		%feet.visible = false
		%BrodySprite.play("roll")

		# Acceleration phase
		for i in range(9):
			await get_tree().create_timer(0.005).timeout
			speed *= 1.135

		# Deceleration phase
		await get_tree().create_timer(0.18).timeout
		for i in range(4):
			await get_tree().create_timer(0.03).timeout
			speed /= 2

		await get_tree().create_timer(0.04).timeout
		speed = 2000

		# Reset state
		dashing = false
		%feet.visible = true
		%BrodySprite.play("moving")

func initialise_swap_tool() :
	if weapon_equipped == false :
		torch_equipped = false
		weapon_equipped = true
		%Torch.now_unequipped()
		%weapon.now_equipped()
	else :
		weapon_equipped = false
		torch_equipped = true
		%weapon.now_unequipped()
		%Torch.now_equipped()

func _on_dash_cooldown_timeout() -> void:
	dash_available = true

# Appearance :
func breathing() :
	if bobbing == false :
		bobbing = true
		for i in range(6) :
			%BrodySprite.position.y += 0.1
			%antenna.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%BrodySprite.position.y += 0.05
			%antenna.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%BrodySprite.position.y -= 0.1
			%antenna.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%BrodySprite.position.y -= 0.05
			%antenna.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()

func check_alive() :
	if health <= 0 :
		pass
		#queue_free()
		#get_tree().pause()

func flash_white():
	var tween := create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)

func got_torch_wraithed() :
	health -= 1
	flash_white()
	check_alive()

func ogre_slashed() :
	health -= 2
	flash_white()
	check_alive()
