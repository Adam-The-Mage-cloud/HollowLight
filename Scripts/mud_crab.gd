extends Area2D

var leg_rest_rotations = {}
var leg_rest_positions = {}
var original_left_pincer_rotation
var original_left_pincer_transform
var original_right_pincer_rotation
var original_right_pincer_transform

var last_location
var last_safe_location
var monster_saved = false

var in_sight = false
var brody_position
var direction

var target

var target_captured = false
var pincing = false

var shadow = false
var pinatered = false

var bobbing = false

var lightable = false

var speed = 12

func _ready() :
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	material = material.duplicate()
	set_tint()
	breathing()
	randomize()
	
	leg_rest_rotations[%LegL1] = %LegL1.rotation_degrees
	leg_rest_rotations[%LegL2] = %LegL2.rotation_degrees
	leg_rest_rotations[%LegL3] = %LegL3.rotation_degrees
	leg_rest_rotations[%LegR1] = %LegR1.rotation_degrees
	leg_rest_rotations[%LegR2] = %LegR2.rotation_degrees
	leg_rest_rotations[%LegR3] = %LegR3.rotation_degrees
	leg_rest_positions[%LegL1] = %LegL1.position
	leg_rest_positions[%LegL2] = %LegL2.position
	leg_rest_positions[%LegL3] = %LegL3.position
	leg_rest_positions[%LegR1] = %LegR1.position
	leg_rest_positions[%LegR2] = %LegR2.position
	leg_rest_positions[%LegR3] = %LegR3.position
	
	original_left_pincer_rotation = %PincerPivotL.rotation_degrees
	original_left_pincer_transform = %PincerPivotL.position
	original_right_pincer_rotation = %PincerPivotR.rotation_degrees
	original_right_pincer_transform = %PincerPivotR.position

func set_tint() :
	if EventBus.current_theme == 2 : # Ice :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.067, 0.988, 0.988))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.12)
	elif EventBus.current_theme == 3 : # Hell :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.976, 0.192, 0.298, 1.0))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.12)
	elif EventBus.current_theme == 4 : # Overgrown :
		# Set tint color (RGB)
		material.set_shader_parameter("tint_color", Color(0.0, 0.306, 0.078, 1.0))
		# Set tint strength
		material.set_shader_parameter("tint_amount", 0.12)

func _physics_process(delta: float) -> void:
	if get_parent().visible == true :
		# Moving : )
		if brody_position != null :
			
			var desired_angle = (target.global_position - global_position).angle()
			rotation = lerp_angle(rotation, desired_angle, 0.025) 
			brody_position = target.global_position
			direction = (brody_position - global_position).normalized()
			# Now we have the direction to Brody we can move towards it with :
			if global_position.distance_to(brody_position) > 10 :
				position += delta * speed * direction
			# move to brody

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		target = body
		in_sight = true
		footsteps()
		animate_pincers()
		realistic_movement()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		in_sight = false

func realistic_movement():
	while in_sight:
		brody_position = target.global_position
		
		# Animate all legs at once
		animate_leg(%LegL1)
		animate_leg(%LegL2)
		animate_leg(%LegL3)
		animate_leg(%LegR1)
		animate_leg(%LegR2)
		animate_leg(%LegR3)
		
		await get_tree().create_timer(randf_range(0.24, 0.36)).timeout

func animate_leg(leg: Node2D):
	var t = create_tween()
	t.set_parallel(true)
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var original_rotation = leg_rest_rotations[leg]
	var original_pos = leg_rest_positions[leg]

	# Wiggle rotation
	t.tween_property(leg, "rotation_degrees", original_rotation + randf_range(-12, 12), 0.15)

	# Move leg slightly inward/outward (local X)
	t.tween_property(leg, "position:x", original_pos.x + randf_range(-1, 1), 0.15)

	# Return to rest pose
	t.tween_property(leg, "rotation_degrees", original_rotation, 0.05)
	t.tween_property(leg, "position:x", original_pos.x, 0.05)

func animate_pincers() :
	while in_sight == true :
		if pincing == false :
			var LeftPincerTween = create_tween()
			LeftPincerTween.tween_property(%PincerPivotL, "rotation_degrees", randf_range(-10, 10), randf_range(0.3, 0.5))
			LeftPincerTween.tween_property(%PincerPivotL, "rotation_degrees", original_left_pincer_rotation, randf_range(0.1, 0.24))
			
			LeftPincerTween.tween_property(%PincerPivotL, "position:y", original_left_pincer_transform.y + randf_range(-2, 2), randf_range(0.3, 0.5))
			LeftPincerTween.tween_property(%PincerPivotL, "position:y", original_left_pincer_transform.y, randf_range(0.1, 0.24))
			
			var RightPincerTween = create_tween()
			RightPincerTween.tween_property(%PincerPivotR, "rotation_degrees", randf_range(-10, 10), randf_range(0.3, 0.5))
			RightPincerTween.tween_property(%PincerPivotR, "rotation_degrees", original_right_pincer_rotation, randf_range(0.1, 0.24))
			
			RightPincerTween.tween_property(%PincerPivotR, "position:y", original_right_pincer_transform.y + randf_range(-2, 2), randf_range(0.3, 0.5))
			RightPincerTween.tween_property(%PincerPivotR, "position:y", original_right_pincer_transform.y, randf_range(0.1, 0.24))
			
			await RightPincerTween.finished
		else :
			await get_tree().create_timer(randf_range(0.24, 0.36)).timeout

func pince_attempt() :
	var LeftPincerTween = create_tween()
	LeftPincerTween.tween_property(%PincerPivotL, "rotation_degrees", randf_range(-10, 10), randf_range(0.3, 0.5))
	LeftPincerTween.tween_property(%PincerPivotL, "rotation_degrees", original_left_pincer_rotation, randf_range(0.1, 0.24))
	
	LeftPincerTween.tween_property(%PincerPivotL, "position:y", original_left_pincer_transform.y + randf_range(-20, -12), randf_range(0.08, 0.15))
	LeftPincerTween.tween_property(%PincerPivotL, "position:y", original_left_pincer_transform.y, randf_range(0.1, 0.24))
	
	var RightPincerTween = create_tween()
	RightPincerTween.tween_property(%PincerPivotR, "rotation_degrees", randf_range(-10, 10), randf_range(0.3, 0.5))
	RightPincerTween.tween_property(%PincerPivotR, "rotation_degrees", original_right_pincer_rotation, randf_range(0.1, 0.24))
	
	RightPincerTween.tween_property(%PincerPivotR, "position:y", original_right_pincer_transform.y + randf_range(-20, -12), randf_range(0.08, 0.15))
	RightPincerTween.tween_property(%PincerPivotR, "position:y", original_right_pincer_transform.y, randf_range(0.1, 0.24))
	
	await RightPincerTween.finished
	pincing = false

func footsteps() :
	while in_sight == true :
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.33).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.33).timeout

# Appearance :
func breathing() :
	if bobbing == false :
		bobbing = true
		for i in range(6) :
			%CrabSprite.position.y += 0.1
			%PincerPivotL.position.y += 0.1
			%PincerPivotR.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%CrabSprite.position.y += 0.05
			%PincerPivotL.position.y += 0.05
			%PincerPivotR.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%CrabSprite.position.y -= 0.1
			%PincerPivotL.position.y -= 0.1
			%PincerPivotR.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%CrabSprite.position.y -= 0.05
			%PincerPivotL.position.y -= 0.05
			%PincerPivotR.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()


func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()
	# Drop Gold at this point?

func shadow_form() :
	$"." .material.set("shader_parameter/cloud_amount", 1.00)
	%visibility_collision.set_deferred("disabled", true)
	shadow = true
	var first_flash = create_tween()
	first_flash.tween_property(material, "shader_parameter/susceptible_flash_amount", 1.0, 0.1)
	first_flash.tween_property(material, "shader_parameter/susceptible_flash_amount", 0.0, 0.2)
	$".".monitoring = false
	lightable = true
	%visibility_collision.scale *= 12.0
	in_sight = true
	speed = 85
	%FootStepParticlesLeft.visible = false
	%FootStepParticlesRight.visible = false
	%CrabShadowSprite.play("default")
	%CrabShadowSprite.visible = true
	%CrabSprite.visible = false
	%LegR1.visible = false
	%LegR2.visible = false
	%LegR3.visible = false
	%LegL1.visible = false
	%LegL2.visible = false
	%LegL3.visible = false
	%PincerPivotL.visible = false
	%PincerPivotR.visible = false
	await get_tree().create_timer(0.005).timeout
	%visibility_collision.set_deferred("disabled", false)


func _on_crab_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true :
		# Knockback:
		speed = -50
		var rotation_tween_1 = create_tween()
		rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + 65, 1.2)
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * (area.effort * 24.0) * 2, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		burn()
	elif area.name == "winged_torch" and lightable == true :
		# Knockback:
		speed = -50
		var rotation_tween_1 = create_tween()
		rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + 65, 1.2)
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		burn()
	elif area.name == "Torch" and lightable == false :
		# Mini Knockback
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * (area.effort * 24.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_white()
	
	# Player Pets :
	# Mystic Sword Bloody Knockback :
	elif area.name == "mystic_sword" and lightable == false :
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 32, 1.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_white()
	
	elif area.name == "brody_shield" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_actual_white()


func flash_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/tint_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/tint_amount", 0.12, 0.1)

func flash_actual_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)


func burn() :
	EventBus.mudcrabs_burnt += 1
	var tween1 = create_tween()
	tween1.tween_property(material, "shader_parameter/flash_color", Vector3(0.95, 0.65, 0.25), 0.25)
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	
	# Turn Light Mask on :aaaaaa
	$".".light_mask = 1
	%OnFireLight.enabled = true
	# Drop Currencies :
	drop_currency()
	
	var tween2 = create_tween()
	tween2.tween_property(material, "shader_parameter/burn_amount", 1.0, 1.0)
	
	var lighttween = create_tween()
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
	lighttween.tween_property(%OnFireLight, "texture_scale", 0.0, 0.45)
	
	# Once finished then queue_free :
	tween2.finished.connect(func() :
		queue_free())
		

func drop_currency() :
	if pinatered == false :
		pinatered = true
		# Drop XP :
		var random_xp_amount = randi_range(3, 6)
		for i in random_xp_amount : 
			var xp = preload("res://Scenes/Currencies/experience_orb.tscn").instantiate()
			xp.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", xp)
			await get_tree().create_timer(0.008).timeout
			
		# Drop Gold :
		var random_gold_amount = randi_range(2, (4 + (EventBus.amount_lootchance_upgraded / 3)))
		for i in random_gold_amount : 
			var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
			gold_piece.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", gold_piece)
			await get_tree().create_timer(0.008).timeout
			
		# Drop Embers :
		var ember = preload("res://Scenes/Currencies/ember.tscn").instantiate()
		ember.global_position = $".".global_position
		get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", ember)


func _on_pincer_activation_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		pincing = true
		pince_attempt()


func _on_pincer_r_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false and body.brody_hittable == true :
		if randi_range(1,2) == 1 : # PUNCH BACK :
			body.crab_punch(self)
		else : # Grab and Spin :
			var stuck_position
			if randi_range(1, 2) == 1 :
				stuck_position = %PincerRHitbox
			else :
				stuck_position = %PincerLHitbox
			target_captured = true
			while target_captured == true and body.brody_saved == false :
				body.global_position = stuck_position.global_position
				rotation_degrees += 1
				if randi_range(1, 64) == 12 :
					target_captured = false
				await get_tree().process_frame
			body.crab_punch(self)
			body.slowed()


func _on_pincer_l_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false :
		if randi_range(1,2) == 1 : # PUNCH BACK :
			body.crab_punch(self)
		else : # Grab and Spin :
			var stuck_position
			if randi_range(1, 2) == 1 :
				stuck_position = %PincerRHitbox
			else :
				stuck_position = %PincerLHitbox
			target_captured = true
			while target_captured == true and body.brody_saved == false :
				body.global_position = stuck_position.global_position
				rotation_degrees += 1
				if randi_range(1, 32) == 12 :
					target_captured = false
				await get_tree().process_frame
			body.crab_punch(self)
			body.slowed()


# CHECK ENEMY WITHIN MAP BOUNDS :
func _on_check_location_okay() :
	while is_instance_valid(self) :
		# Check if player stuck inside something :
		#if last_location == $".".global_position and %BrodyMapStuckCollision.get_overlapping_bodies().size() > 0 :
			#$".".global_position = last_safe_location
		if last_location == $".".global_position and %MapStuckCollision.get_overlapping_areas().size() > 0 :
			$".".global_position = last_safe_location
			monster_saved = true
		# Now check if player is not touching a floor tile :
		if is_on_floor_tile() == false :
			$".".global_position = last_safe_location
		#if %FloorDetector.is_colliding() == false :
			#$".".global_position = last_safe_location
		else :
			last_safe_location = $".".global_position
			monster_saved = false
		await get_tree().process_frame

func is_on_floor_tile() -> bool:
	var check_pos = global_position + Vector2(0, 8)
	
	for tm in get_tree().current_scene.get_nodes_in_group("floors"):
		var local = tm.to_local(check_pos)
		var cell = tm.local_to_map(local)
		
		var data = tm.get_cell_tile_data(cell)
		if data != null:
			return true
	
	return false
