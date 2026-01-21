extends Area2D

var player_tracking = false

var target 
var brody_position

var direction
var speed = 40

var launch_radius: float = 32.0
var launch_height: float = 24.0
var launch_time: float = 0.35

func _ready():
	var tween = create_tween()
	
	# --- 1. Pick a random landing point around the spawn ---
	var angle = randf() * TAU
	var radius = randf() * launch_radius
	var landing_offset = Vector2(cos(angle), sin(angle)) * radius
	var landing_pos = global_position + landing_offset
	
	# Upward Launch Arc :
	var peak_pos = global_position + Vector2(0, -launch_height)
	
	# Fly Up then Down :
	tween.tween_property(self, "global_position", peak_pos, launch_time * 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", landing_pos, launch_time * 0.6)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
		
	# Rotation :
	var spin_amount = randf_range(1.0, 3.0) * TAU
	tween.parallel().tween_property(self, "rotation", rotation + spin_amount, launch_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

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
	EventBus.emit_signal("experience_orb_acquired")
	queue_free()

func flash_white() :
	pass
