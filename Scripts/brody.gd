extends CharacterBody2D

var direction = Vector2.ZERO
var speed = 2000

var weapon_equipped = false
var torch_equipped = true

var bobbing = false

var dash_available = true

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
		%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("up") and Input.is_action_pressed("left") :
		direction = Vector2(-1, -1)
		%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("right") :
		direction = Vector2(1, 1)
		%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("left") :
		direction = Vector2(-1, 1)
		%BrodySprite.play("moving")
		%feet.play("moving")
		
	elif Input.is_action_pressed("up") :
		direction = Vector2(0, -1)
		%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("down") :
		direction = Vector2(0, 1)
		%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("right") :
		direction = Vector2(1, 0)
		%BrodySprite.play("moving")
		%feet.play("moving")
	elif Input.is_action_pressed("left") :
		direction = Vector2(-1, 0)
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

func dash_ability() :
	# When player hits the button/shift :
	if dash_available == true :
		dash_available = false
		%DashCooldown.start()
		speed = 3000
		for i in range(9) :
			await get_tree().create_timer(0.005).timeout
			speed *= 1.135
		await get_tree().create_timer(0.14).timeout
		for i in range(4) :
			await get_tree().create_timer(0.03).timeout
			speed /= 2
		await get_tree().create_timer(0.04).timeout
		speed = 2000
	else :
		# Emit failed puff of smoke
		pass

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
