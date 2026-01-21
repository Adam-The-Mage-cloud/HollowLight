extends Area2D

var player_tracking = false

var target 
var brody_position

var direction
var speed = 16

func _on_body_entered(body: Node2D) -> void:
	player_tracking = true
	target = body

func _physics_process(delta: float) -> void:
	if player_tracking == true :
		# Move toward player :
		var desired_angle = (target.global_position - global_position).angle()
		rotation = lerp_angle(rotation, desired_angle, 0.025)
		# Moving : )
		brody_position = target.global_position
		direction = (brody_position - global_position).normalized()
		# Potentially Flip Horizontally :
		if brody_position.x > global_position.x :
			$".".scale.x = -1
		else :
			$".".scale.x = 1
		# Now we have the direction to Brody we can move towards it with :
		position += delta * speed * direction


func _on_body_exited(_body: Node2D) -> void:
	player_tracking = false


func _on_pickup_area_body_entered(_body: Node2D) -> void:
	EventBus.emit_signal("ember_acquired")
	queue_free()
