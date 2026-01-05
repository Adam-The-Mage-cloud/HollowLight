extends CharacterBody2D

var direction = Vector2.ZERO
var speed = 2000


func _physics_process(delta: float) -> void:
	# Check For Input :
	if Input.is_action_pressed("up") and Input.is_action_pressed("right") :
		direction = Vector2(1, -1)
		%BrodySprite.play("moving")
		
	elif Input.is_action_pressed("up") and Input.is_action_pressed("left") :
		direction = Vector2(-1, -1)
		%BrodySprite.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("right") :
		direction = Vector2(1, 1)
		%BrodySprite.play("moving")
		
	elif Input.is_action_pressed("down") and Input.is_action_pressed("left") :
		direction = Vector2(-1, 1)
		%BrodySprite.play("moving")
		
	elif Input.is_action_pressed("up") :
		direction = Vector2(0, -1)
		%BrodySprite.play("moving")
	elif Input.is_action_pressed("down") :
		direction = Vector2(0, 1)
		%BrodySprite.play("moving")
	elif Input.is_action_pressed("right") :
		direction = Vector2(1, 0)
		%BrodySprite.play("moving")
	elif Input.is_action_pressed("left") :
		direction = Vector2(-1, 0)
		%BrodySprite.play("moving")
		
	else :
		direction = Vector2.ZERO
		%BrodySprite.play("stationary")
	
	# Antenna Movement :
	if direction != Vector2.ZERO and %antenna.rotation_degrees > -25 :
		%antenna.rotation_degrees -= 225 * delta
	elif direction == Vector2.ZERO and %antenna.rotation_degrees <= 0 :
		%antenna.rotation_degrees += 225 * delta # until at degrees = 0
	
	# Movement :
	direction = direction.normalized()
	velocity = (direction * speed) * delta
	move_and_slide()
