extends Area2D

var flying = true

var target
var brody_position
var direction
var speed = 30

var max_health = 2
var health = 2

func _ready() :
	target = %Brody
	material = material.duplicate()
	realistic_movement()
	flapping()
	# Deviation of how they're titled towards the player :

func _physics_process(delta: float) -> void:
	# Look at Brody gradually (acting like a cloud) :
	var desired_angle = (target.global_position - global_position).angle() - PI/2
	rotation = lerp_angle(rotation, desired_angle, 0.05)
	# Moving : )
	brody_position = target.global_position
	direction = (brody_position - global_position).normalized()
	# Potentially Flip Horizontally :
	if brody_position.x > global_position.x :
		$".".scale.x = -1
	else :
		$".".scale.x = 1
	# Now we have the direction to Brody we can move towards it with :
	if global_position.distance_to(brody_position) > 10 :
		position += delta * speed * direction


func _on_area_entered(area: Area2D) -> void:
	# Knockback and 1/3 burnt flash from Torch
	if area.name == "Torch" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 36, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Take away 1/3 of health and some of appearance
		health -= 1
		burn_away()

func realistic_movement() :
	while flying == true :
		var original_rotation = rotation_degrees
		var bobble = create_tween()
		bobble.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		bobble.tween_property($".", "rotation_degrees", rotation_degrees + -randf_range(1, 2), 0.15)
		# Then rotate a little right
		if flying == true :
			bobble.tween_property($".", "rotation_degrees", rotation_degrees + randf_range(1, 2), 0.3)
		# Return to center
		if flying == true :
			bobble.tween_property($".", "rotation_degrees", original_rotation, 0.15)
		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout

func flapping() :
	while flying == true :
		var rightwingflap = create_tween()
		rightwingflap.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate left
		rightwingflap.tween_property(%LeftAnchor, "rotation_degrees", -45, 0.5)
		# Then rotate right
		rightwingflap.tween_property(%LeftAnchor, "rotation_degrees", 45, 1.0)
		# Return to center
		rightwingflap.tween_property(%LeftAnchor, "rotation_degrees", 0, 0.5)
		var leftwingflap = create_tween()
		leftwingflap.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate left
		leftwingflap.tween_property(%RightAnchor, "rotation_degrees", 45, 0.5)
		# Then rotate right
		leftwingflap.tween_property(%RightAnchor, "rotation_degrees", -45, 1.0)
		# Return to center
		leftwingflap.tween_property(%RightAnchor, "rotation_degrees", 0, 0.5)
		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout

func burn_away() :
	# Flash effect
	var tween1 := create_tween()
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	# Turn on fire light
	light_mask = 1
	%OnFireLight.enabled = true
	# Calculate new burn target
	if health == 1 :
		%MonsterBurningParticles.emitting = true
		%MonsterBurningLeft.emitting = true
		%MonsterBurningRight.emitting = true
		%MonsterBurningParticles.amount_ratio = 1.0
		%MonsterBurningLeft.amount_ratio = 1.0
		%MonsterBurningRight.amount_ratio = 1.0
		%OnFireLight.texture.width = 64
		%OnFireLight.texture.height = 64
	# Fire light animation
	var lighttween = create_tween()
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.0, 0.45)
	if health <= 0:
		flying = false
		#var scale_tween = create_tween()
		#scale_tween.tween_property($".", "scale", Vector2(0,0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var rotation_tween_1 = create_tween()
		rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + 165, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var death_tween = create_tween()
		death_tween.tween_property(material, "shader_parameter/burn_amount", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.15).timeout
		#var rotation_tween_2 = create_tween()
		#rotation_tween_2.tween_property($".", "rotation_degrees", $".".rotation_degrees + 15, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var charcoal_tween = create_tween()
		charcoal_tween.tween_property(material, "shader_parameter/charcoal_amount", 0.0, 0.4)
		await get_tree().create_timer(0.4).timeout
		queue_free()
