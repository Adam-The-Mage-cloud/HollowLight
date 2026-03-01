extends Area2D

var in_sight = false
var brody_position
var direction
var velocity = Vector2.ZERO

var last_location
var last_safe_location
var monster_saved = false

var target
var out_of_range = true

var shadow = false
var target_captured = false
var pinatered = false

var bobbing = false

var flip_cooldown = 1.0
var flip_threshold = 12.0 
var is_lunging = false
var lunge_available = true
var lightable = false

var speed = 48

func _ready() :
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	material = material.duplicate()
	set_tint()
	breathing()
	tail_wag()
	randomize()

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

func _physics_process(delta):
	if get_parent().visible == true :
		if flip_cooldown > 0:
			flip_cooldown -= delta

		# No physics movement during lunge or recovery
		if is_lunging:
			return

		if target:
			brody_position = target.global_position
			direction = (brody_position - global_position).normalized()

			# Flip only when allowed
			if flip_cooldown <= 0:
				scale.x = 1 if brody_position.x > global_position.x else -1

			# Smooth movement
			var desired_velocity = direction * speed
			velocity = velocity.lerp(desired_velocity, delta * 8.0)

			if global_position.distance_to(brody_position) > 10:
				%DireWolfSprite.play("running")
				position += velocity * delta
			else:
				%DireWolfSprite.play("stationary")


func lunge():
	is_lunging = true
	lunge_available = false
	flip_cooldown = 0.6

	%DireWolfHead.play("biting")

	# Lock direction NOW
	if target:
		direction = (target.global_position - global_position).normalized()

	var lunge_direction = direction
	var locked_scale_x = scale.x
	var target_rot = 12 if locked_scale_x == 1 else -12

	# Store stable starting position
	var start_pos = global_position

	var t = create_tween()

	# ---------------------------------------------------------
	# 1. ANTICIPATION — crouch
	# ---------------------------------------------------------
	t.tween_property(
		self, "scale",
		Vector2(locked_scale_x, 0.88),
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# ---------------------------------------------------------
	# 2. LUNGE — THROUGH the player
	# ---------------------------------------------------------
	if target:
		var through_point = target.global_position + lunge_direction * 24

		t.tween_property(
			self, "global_position",
			through_point,
			0.36
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Rotation burst
	t.parallel().tween_property(
		self, "rotation_degrees",
		target_rot,
		0.36
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# ---------------------------------------------------------
	# 3. RECOVERY — straighten + stand up
	# ---------------------------------------------------------
	t.tween_property(
		self, "rotation_degrees",
		0,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	t.parallel().tween_property(
		self, "scale",
		Vector2(locked_scale_x, 1.0),
		0.18
	)

	bite()

	await t.finished

	# Pullback happens while still in lunge state
	await pull_back()

	# Now physics can resume
	is_lunging = false

	# Small cooldown before next lunge
	await get_tree().create_timer(0.4).timeout
	lunge_available = true

func bite() :
	var bite_tween = create_tween()
	# 1. Anticipation: raise the axe a bit first
	bite_tween.tween_property(%DireWolfHead, "rotation_degrees", 60, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2. Heavy downward swing: fast acceleration
	bite_tween.tween_property(%DireWolfHead, "rotation_degrees", -50, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 3. Follow-through: slight bounce back
	bite_tween.tween_property(%DireWolfHead, "rotation_degrees", randf_range(-4, 8), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.25).timeout
	%BiteArea.monitoring = true
	await get_tree().create_timer(0.40).timeout
	%BiteArea.monitoring = false

func pull_back():
	%DireWolfHead.play("normal")
	if not target:
		return

	var knockback_direction = (global_position - target.global_position).normalized()
	var start = global_position
	var end = start + knockback_direction * 16

	var t = create_tween()
	t.tween_property(
		self, "global_position",
		end,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await t.finished

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		target = body
		in_sight = true
		footsteps()
		realistic_movement()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		in_sight = false
		%DireWolfSprite.play("stationary")

func realistic_movement() :
	while in_sight == true :
		# HEAD AND AXE JIGGLE :
		brody_position = target.global_position
		var head_tween = create_tween()
		head_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		head_tween.tween_property(%DireWolfHead, "rotation_degrees", -2, 0.15)
		# Then rotate a little right
		head_tween.tween_property(%DireWolfHead, "rotation_degrees", 2, 0.3)
		# Return to center
		head_tween.tween_property(%DireWolfHead, "rotation_degrees", 0, 0.15)
		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout

func tail_wag() :
	while get_parent().visible == true :
		var tail_tween = create_tween()
		tail_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if randi_range(1, 2) == 1 :
			# Rotate a little left
			tail_tween.tween_property(%TailPivot, "rotation_degrees", -randf_range(4, 6), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else :
			# Then rotate a little right
			tail_tween.tween_property(%TailPivot, "rotation_degrees", randf_range(4, 6), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Return to center
		tail_tween.tween_property(%TailPivot, "rotation_degrees", 0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tail_tween.finished

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
			%DireWolfSprite.position.y += 0.1
			%DireWolfHead.position.y += 0.1
			%DireWolfHead.position.y += 0.1
			%TailPivot.position.y += 0.1
			%TailPivot.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%DireWolfSprite.position.y += 0.05
			%DireWolfHead.position.y += 0.05
			%DireWolfHead.position.y += 0.05
			%TailPivot.position.y += 0.05
			%TailPivot.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%DireWolfSprite.position.y -= 0.1
			%DireWolfHead.position.y -= 0.1
			%DireWolfHead.position.y -= 0.1
			%TailPivot.position.y -= 0.1
			%TailPivot.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%DireWolfSprite.position.y -= 0.05
			%DireWolfHead.position.y -= 0.05
			%DireWolfHead.position.y -= 0.05
			%TailPivot.position.y -= 0.05
			%TailPivot.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()

func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()
	# Drop Gold at this point?

func shadow_form() :
	shadow = true
	var first_flash = create_tween()
	first_flash.tween_property(material, "shader_parameter/susceptible_flash_amount", 1.0, 0.1)
	first_flash.tween_property(material, "shader_parameter/susceptible_flash_amount", 0.0, 0.2)
	$".".monitoring = false
	lightable = true
	%DireWolfVisibility.scale *= 2.4
	in_sight = true
	speed = 50
	%FootStepParticlesLeft.visible = false
	%FootStepParticlesRight.visible = false
	%DireWolfShadowSprite.play("darkness")
	%DireWolfShadowSprite.visible = true
	%DireWolfHead.visible = false
	%DireWolfSprite.visible = false
	
	%TailPivot.visible = false

func _on_lunge_area_body_entered(body):
	if body.name == "Brody":
		out_of_range = false
		try_lunge()

func try_lunge():
	while out_of_range == false and shadow == false :
		if lunge_available == false :
			pass
		else :
			lunge()
		await get_tree().create_timer(randf_range(0.7, 1.4)).timeout
		try_lunge()

func _on_lunge_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = true

func _on_wolf_hitbox_area_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true or area.name == "winged_torch" and lightable == true :
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
		knockback_movement.tween_property(self, "position", position + knockback_direction * 4, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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


func _on_bite_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false and body.brody_hittable == true :
		target_captured = true
		
		# Smooth pull tween
		var t = create_tween()
		t.set_trans(Tween.TRANS_SINE)
		t.set_ease(Tween.EASE_OUT)
		
		# Pull Brody toward the bite point over 0.25 seconds
		t.tween_property(body, "global_position", %BiteArea.global_position, 0.25)
		
		# Wait for the tween to finish
		await t.finished
		
		# Now hold him in place gently (no teleporting)
		while target_captured and not body.brody_saved:
			# Soft follow instead of hard snap
			body.global_position = body.global_position.lerp(%BiteArea.global_position, 0.4)
			
			# Random escape chance
			if randi_range(1, 32) == 12:
				target_captured = false
		
			await get_tree().process_frame
		
		body.slowed()


func flash_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/tint_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/tint_amount", 0.12, 0.1)

func flash_actual_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)


func burn() :
	EventBus.dire_wolves_burnt += 1
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
		var random_gold_amount = randi_range(3, 9)
		for i in random_gold_amount : 
			var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
			gold_piece.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", gold_piece)
			await get_tree().create_timer(0.008).timeout
			
		# Drop Embers :
		var ember = preload("res://Scenes/Currencies/ember.tscn").instantiate()
		ember.global_position = $".".global_position
		get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", ember)

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
