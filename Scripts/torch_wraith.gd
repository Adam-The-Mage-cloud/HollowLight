extends Area2D

var target
var in_sight

var direction = Vector2.ZERO
var brody_position

var health = 3

var speed = 20

func _ready() :
	material = material.duplicate()
	target = %Brody
	pass

func _physics_process(delta: float) -> void:
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

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		body.got_torch_wraithed()
		# Wraith Knockback:
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = -(global_position - body.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 36, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pass

func realistic_movement() :
	while in_sight == true :
		var bobble = create_tween()
		bobble.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		bobble.tween_property($".", "rotation_degrees", -randf_range(1, 2), 0.15)
		# Then rotate a little right
		bobble.tween_property($".", "rotation_degrees", randf_range(1, 2), 0.3)
		# Return to center
		bobble.tween_property($".", "rotation_degrees", 0, 0.15)
		var arm1wobble = create_tween()
		arm1wobble.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		arm1wobble.tween_property(%Arm1, "rotation_degrees", -randf_range(1, 3), 0.15)
		# Then rotate a little right
		arm1wobble.tween_property(%Arm1, "rotation_degrees", randf_range(1, 3), 0.3)
		# Return to center
		arm1wobble.tween_property(%Arm1, "rotation_degrees", 0, 0.15)
		var arm2bobble = create_tween()
		arm2bobble.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		arm2bobble.tween_property(%Arm2, "rotation_degrees", -randf_range(1, 3), 0.15)
		# Then rotate a little right
		arm2bobble.tween_property(%Arm2, "rotation_degrees", randf_range(1, 3), 0.3)
		# Return to center
		arm2bobble.tween_property(%Arm2, "rotation_degrees", 0, 0.15)
		%Arm1.speed_scale = randf_range(0.6, 1)
		%Arm2.speed_scale = randf_range(0.6, 1)
		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout


func _on_area_entered(area: Area2D) -> void:
	# Knockback and 1/3 burnt flash from Torch
	if area.name == "Torch" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 36, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Take away 1/3 of health and some of appearance
		health -= 1
		burn_away()

func burn_away() :
	# Flash effect
	var tween1 := create_tween()
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	# Turn on fire light
	light_mask = 1
	%OnFireLight.enabled = true
	# Calculate new burn target
	if health == 2 :
		%MonsterBurningParticles.amount_ratio = 0.3
		%OnFireLight.texture.width = 32
		%OnFireLight.texture.height = 32
	else :
		%MonsterBurningParticles.amount_ratio = 1.0
		%OnFireLight.texture.width = 48
		%OnFireLight.texture.height = 48
	# Fire light animation
	var lighttween = create_tween()
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.0, 0.45)
	if health <= 0:
		var scale_tween = create_tween()
		scale_tween.tween_property($".", "scale", Vector2(0,0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var death_tween = create_tween()
		death_tween.tween_property(material, "shader_parameter/burn_amount", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.3).timeout
		queue_free()
