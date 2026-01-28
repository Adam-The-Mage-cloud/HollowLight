extends Area2D

var flying = true

var target
var brody_position
var direction
var speed = 30

var target_captured = false

var pinatered = false

var max_health = 2
var health = 2

func _ready() :
	# target = %Brody
	material = material.duplicate()
	realistic_movement()
	flapping()
	# Deviation of how they're titled towards the player :

func _physics_process(delta: float) -> void:
	if flying == true :
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
	var tween1 = create_tween()
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	# Turn on fire light
	light_mask = 1
	%OnFireLight.enabled = true
	# Calculate new burn target
	if health == 1 :
		drop_xp()
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
		drop_embers()
		drop_xp()
		pinatered = true
		flying = false
		#var scale_tween = create_tween() 
		#scale_tween.tween_property($".", "scale", Vector2(0,0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var rotation_tween_1 = create_tween()
		rotation_tween_1.tween_property(%WormBat, "rotation_degrees", %WormBat.rotation_degrees + 165, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var death_tween = create_tween()
		death_tween.tween_property(material, "shader_parameter/burn_amount", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.15).timeout
		#var rotation_tween_2 = create_tween()
		#rotation_tween_2.tween_property($".", "rotation_degrees", $".".rotation_degrees + 15, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var charcoal_tween = create_tween() 
		charcoal_tween.tween_property(material, "shader_parameter/charcoal_amount", 0.0, 0.4)
		await get_tree().create_timer(0.4).timeout
		queue_free()

# WORM BAT TAKING DAMAGE :
func _on_worm_bat_hitbox_area_entered(area: Area2D) -> void:
		# Knockback and 1/3 burnt flash from Torch
	if area.name == "Torch" :
		target_captured = false
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 36, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Take away 1/3 of health and some of appearance
		health -= 1
		burn_away()

# WORM BAT DEALING DAMAGE WITH MANDIBLES AND TRAPPING PLAYER IN :
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		target_captured = true
		while target_captured == true :
			body.caught_by_wormbat($".")
			body.global_position = $".".global_position
			await get_tree().create_timer(0.1).timeout


func _on_body_exited(_body: Node2D) -> void:
	target_captured = false

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Currency :
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func drop_embers() :
	if pinatered == false :
		# Drop Embers :
		var ember = preload("res://Scenes/Currencies/ember.tscn").instantiate()
		ember.global_position = $".".global_position
		get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", ember)


func drop_xp() :
	if pinatered == false :
		# Drop Gold / XP :
		var random_amount = 0
		if health > 0 :
			random_amount = randi_range(1, 1)
		else :
			random_amount = randi_range(2, 4)
			
		for i in random_amount : 
			var xp = preload("res://Scenes/Currencies/experience_orb.tscn").instantiate()
			xp.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", xp)
			await get_tree().create_timer(0.008).timeout
