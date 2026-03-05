extends Area2D

var in_sight = false
var brody_position
var direction

var last_location
var last_safe_location
var monster_saved = false

var melee_pivot_offset = 1
var new_facing = 1
var last_facing_scale_x = 1
var bow_or_melee = 1          # If bow then -1 just to make sure it's not flipped

var facing = 1.0


var orbit_strength = 0.6          # 0 = pure chase, 1 = pure orbit
var desired_distance = 140.0      # ideal ranged distance
var noise = FastNoiseLite.new()


var hand1_base_pos
var hand2_base_pos

var target

var shadow = false
var pinatered = false

var bobbing = false

var attacking = false

var hand1_element 
var hand2_element

var lightable = false

var speed = 24

var _doing_movement = false
var _doing_footsteps = false

func _ready() -> void:
	randomize()
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	material = material.duplicate()
	set_tint()
	breathing()
	melee_pivot_offset = %WeaponPivot.position
	hand1_base_pos = %WitchHand1.position
	hand2_base_pos = %WitchHand2.position
	
	# Set Hand Elements :
	hand1_element = randi_range(1, 3)
	hand2_element = randi_range(1, 3)
	

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
		material.set_shader_parameter("tint_amount", 0.36)

func _physics_process(delta: float) -> void:
	if not get_parent().visible or not target:
		return
	
	brody_position = target.global_position
	
	update_facing()
	update_movement(delta)
	
	if not attacking:
		smooth_aim(delta)


# --- MOVEMENT ---------------------------------------------------------

func update_movement(delta: float) -> void:
	var dist = global_position.distance_to(brody_position)
	if dist <= 10.0:
		return
	
	var dir = get_dynamic_direction()
	dir = get_noisy_direction(dir, Engine.get_physics_frames())
	
	position += dir * speed * delta


func get_dynamic_direction() -> Vector2:
	var to_player = brody_position - global_position
	var dist = to_player.length()
	var chase = to_player.normalized()
	
	# Orbiting (perpendicular)
	var orbit = Vector2(-chase.y, chase.x) * orbit_strength
	
	# Maintain distance
	var push_out = Vector2.ZERO
	if dist < desired_distance:
		push_out = -chase * ((desired_distance - dist) / desired_distance)
	
	return (chase + orbit + push_out).normalized()


func get_noisy_direction(base: Vector2, t: float) -> Vector2:
	var angle_offset = noise.get_noise_1d(t * 0.8) * 0.25
	return base.rotated(angle_offset)


func update_facing() -> void:
	if shadow == false :
		var target_facing = -1.0 if brody_position.x < global_position.x else 1.0
		facing = lerp(facing, target_facing, 0.2)
		%Visuals.scale.x = facing


func smooth_aim(delta: float) -> void:
	var pivot = %WeaponPivot
	var target_angle = pivot.global_position.angle_to_point(brody_position)
	pivot.rotation = lerp_angle(pivot.rotation, target_angle, 0.25)



func fireatwill_hand1() :
	while get_parent().visible == true and shadow == false :
		var witch_projectile1 = preload("res://Scenes/Monsters/witch_projectile.tscn").instantiate()
		witch_projectile1.elemental_type = hand1_element 
		witch_projectile1.position = %WitchHand1.position  + Vector2(-11, 0)
		%WitchHand1.call_deferred("add_child", witch_projectile1)
		#witch_projectile1.draw_back()
		await get_tree().create_timer(2).timeout
		if is_instance_valid(witch_projectile1) :
			if shadow == false :
				push_hand_forward(%WitchHand1)
				# Reparent :
				var arrow_position = witch_projectile1.global_position
				var target_angle = witch_projectile1.global_rotation_degrees
				await get_tree().create_timer(0.05).timeout
				if is_instance_valid(witch_projectile1) :
					%WitchHand1.remove_child(witch_projectile1)
			
			
				#witch_projectile1.top_level = true
				get_tree().current_scene.add_child(witch_projectile1)
				witch_projectile1.global_position = arrow_position
				
				# LOOSE :
				witch_projectile1.apply_angle(target_angle)
				witch_projectile1.fly()

func fireatwill_hand2() :
	while get_parent().visible == true and shadow == false:
		var witch_projectile2 = preload("res://Scenes/Monsters/witch_projectile.tscn").instantiate()
		witch_projectile2.elemental_type = hand2_element 
		witch_projectile2.position = %WitchHand2.position + Vector2(10, -2)
		%WitchHand2.call_deferred("add_child", witch_projectile2)
		#witch_projectile2.draw_back()
		await get_tree().create_timer(2).timeout
		if is_instance_valid(witch_projectile2) :
			if shadow == false :
				push_hand_forward(%WitchHand2)
				# Reparent :
				var arrow_position = witch_projectile2.global_position
				var target_angle = witch_projectile2.global_rotation_degrees
				await get_tree().create_timer(0.05).timeout
				if is_instance_valid(witch_projectile2) :
					%WitchHand2.remove_child(witch_projectile2)
				
				
				#witch_projectile1.top_level = true
				get_tree().current_scene.add_child(witch_projectile2)
				witch_projectile2.global_position = arrow_position
				
				# LOOSE :
				witch_projectile2.apply_angle(target_angle)
				witch_projectile2.fly()

func push_hand_forward(hand: Node2D, distance: float = 6.0, duration: float = 0.15) -> void:
	# Forward in local space is along the pivot's -X (because of your look_at + flip logic)
	var forward_dir = Vector2.LEFT.rotated(%WeaponPivot.rotation)
	var start_pos: Vector2 = hand.position
	var target_pos: Vector2 = start_pos + forward_dir * distance

	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(hand, "position", target_pos, duration)
	t.tween_property(hand, "position", start_pos, duration)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody"and in_sight == false :
		target = body
		in_sight = true
		footsteps()
		move_feet()
		realistic_movement()
		fireatwill_hand1()
		fireatwill_hand2()
		hand_idle_motion()

func hand_idle_motion() -> void:
	while in_sight:
		var h1 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		h1.tween_property(%WitchHand1, "position:y", hand1_base_pos.y - 1.0, 0.4)
		h1.tween_property(%WitchHand1, "position:y", hand1_base_pos.y, 0.4)
		
		var h2 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		h2.tween_property(%WitchHand2, "position:y", hand2_base_pos.y - 1.0, 0.4)
		h2.tween_property(%WitchHand2, "position:y", hand2_base_pos.y, 0.4)
		
		await get_tree().create_timer(randf_range(0.4, 0.8)).timeout

func realistic_movement() -> void:
	if _doing_movement:
		return
	_doing_movement = true

	while in_sight:
		var head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(%WitchHead, "rotation_degrees", -2.0, 0.15)
		head_tween.tween_property(%WitchHead, "rotation_degrees", 2.0, 0.3)
		head_tween.tween_property(%WitchHead, "rotation_degrees", 0.0, 0.15)
		
		# Soft bob
		var bob_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob_tween.tween_property(self, "global_position:y", global_position.y + 1.5, 0.35)
		bob_tween.tween_property(self, "global_position:y", global_position.y, 0.35)

		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout

	_doing_movement = false


func footsteps() -> void:
	if _doing_footsteps:
		return
	_doing_footsteps = true
	
	while in_sight:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.33).timeout
		%FootStepParticlesLeft.emitting = false
		
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.33).timeout
		%FootStepParticlesRight.emitting = false
	
	_doing_footsteps = false

func move_feet():
	var left_rest = %WitchLegL.position
	var right_rest = %WitchLegR.position

	while get_parent().visible:

		# LEFT LEG (up while right goes down)
		var left = create_tween()
		left.tween_property(
			%WitchLegL, "position",
			left_rest + Vector2(0.5, -2.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(
			%WitchLegL, "position",
			left_rest + Vector2(-0.5, 1.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(%WitchLegL, "position", left_rest, 0.1)

		# RIGHT LEG (down while left goes up)
		var right = create_tween()
		right.tween_property(
			%WitchLegR, "position",
			right_rest + Vector2(0.5, 2.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(
			%WitchLegR, "position",
			right_rest + Vector2(-0.5, -1.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(%WitchLegR, "position", right_rest, 0.1)

		# Wait for one full cycle
		await get_tree().create_timer(0.9).timeout

func breathing() -> void:
	if bobbing:
		return
	bobbing = true

	var breathe = create_tween().set_loops() # infinite
	breathe.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var up_offset = 0.4
	var down_offset = -0.4

	breathe.tween_property(%WitchSprite, "position:y", %WitchSprite.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%WitchHead, "position:y", %WitchHead.position.y + up_offset, 0.7)

	breathe.tween_property(%WitchSprite, "position:y", %WitchSprite.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%WitchHead, "position:y", %WitchHead.position.y + down_offset, 0.7)

func _on_melee_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false :
		body.ogre_slashed($".")

func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()
	# Drop Gold at this point?

func shadow_form() :
	flash_white()
	%WitchCollision.scale *= Vector2(1.00, 0.75)
	%WitchCollision.position += Vector2(0, -4)
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
	%WitchShadowSprite.visible = true
	%WitchHead.visible = false
	%WitchSprite.visible = false
	%WeaponPivot.visible = false
	%WitchLegL.visible = false
	%WitchLegR.visible = false
	await get_tree().create_timer(0.005).timeout
	%visibility_collision.set_deferred("disabled", false)


func _on_witch_hit_box_area_entered(area: Area2D) -> void:
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
	EventBus.witches_burnt += 1
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

var out_of_range = true


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
