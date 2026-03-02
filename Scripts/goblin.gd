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

var target

var shadow = false
var pinatered = false

var bobbing = false

var attacking = false

var goblin_type

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
	
	# Random Weapon Chooser:
	goblin_type = randi_range(1, 2)
	if goblin_type == 1 : # Then Archer :
		%SlashArea.monitoring = false
		%GoblinMelee.visible = false
		if randi_range(1, 2) == 1 : # Crossbow :
			%GoblinRanged.play("crossbow")
		else :
			%GoblinRanged.play("bow")
			
	elif goblin_type == 2 : # Then Melee :
		%GoblinRanged.visible = false
		var weapon_picker = randi_range(1, 3)
		if weapon_picker == 1 :
			%GoblinMelee.play("axe")
		elif weapon_picker == 2 :
			%GoblinMelee.play("club")
		elif weapon_picker == 3 :
			%GoblinMelee.play("pick")

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
	if not get_parent().visible:
		return

	if not target:
		return

	brody_position = target.global_position
	direction = (brody_position - global_position).normalized()

	new_facing = 1 * bow_or_melee
	if brody_position.x < global_position.x:
		new_facing = -1 * bow_or_melee

	# Flip ONLY the visuals, not the pivot
	%Visuals.scale.x = new_facing

	# Movement
	if global_position.distance_to(brody_position) > 10.0:
		position += direction * speed * delta

	# Aim pivot only when not attacking
	if not attacking:
		%WeaponPivot.look_at(brody_position)
		if bow_or_melee != - 1 :
			if new_facing < 0:
				%WeaponPivot.rotation += PI
				%WeaponPivot.scale.x = -new_facing
			else :
				%WeaponPivot.scale.x = -new_facing


func slash() -> void:
	attacking = true

	var pivot = %WeaponPivot
	var visual = %GoblinMelee
	var slash_tween = create_tween()

	# Capture stable baseline
	var base_rot = pivot.rotation_degrees

	# Facing direction
	var dir = new_facing

	# --- CONTROLLED VARIATION ---
	var anticipation_amount = randf_range(70, 120)   # degrees
	var impact_amount       = randf_range(120, 160)   # degrees
	var follow_through      = randf_range(140, 160)   # degrees

	# Weapon exaggeration
	var weapon_anticipation = anticipation_amount * 2
	var weapon_impact       = -impact_amount * 2

	visual.rotation_degrees = 0

	# --- 1. ANTICIPATION (pull back) ---
	if abs(pivot.rotation_degrees - base_rot) >= 15.0 or abs(pivot.rotation_degrees - base_rot) <= -15.0 :
		slash_tween.tween_property(
			visual, "rotation_degrees",
			weapon_anticipation * dir / 6, 0.36
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		slash_tween.parallel().tween_property(
			pivot, "rotation_degrees",
			base_rot + anticipation_amount * dir, 0.36
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	elif pivot.rotation_degrees <= 90 :
		slash_tween.tween_property(
			visual, "rotation_degrees",
			weapon_anticipation * dir / 6, 0.36
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		slash_tween.parallel().tween_property(
			pivot, "rotation_degrees",
			base_rot + anticipation_amount * dir, 0.36
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# --- 2. IMPACT (fast, heavy) ---
	slash_tween.tween_property(
		visual, "rotation_degrees",
		weapon_impact * dir / 6, 0.24
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	speed *= 3

	slash_tween.parallel().tween_property(
		pivot, "rotation_degrees",
		base_rot - impact_amount * dir * 1.4, 0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# --- 3. FOLLOW-THROUGH (loose, sloppy goblin recovery) ---
	slash_tween.tween_property(
		visual, "rotation_degrees",
		follow_through * dir / 6, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	slash_tween.parallel().tween_property(
		pivot, "rotation_degrees",
		base_rot + follow_through * 0.3 * dir, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# --- 4. RETURN TO NEUTRAL (smooth, not instant) ---
	slash_tween.tween_property(
		pivot, "rotation_degrees",
		base_rot, 0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Hitbox
	await get_tree().create_timer(0.15).timeout
	speed /= 3
	%MeleeArea.monitoring = true
	await get_tree().create_timer(0.25).timeout
	%MeleeArea.monitoring = false

	attacking = false


func _on_slash_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = false
		while out_of_range == false :
			if attacking == false :
				slash()
			await get_tree().create_timer(randf_range(1.0, 1.2)).timeout


func _on_slash_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = true


func fire_at_will() :
	while get_parent().visible == true:
		bow_or_melee = -1
		var goblin_arrow = preload("res://Scenes/Monsters/goblin_arrow.tscn").instantiate()
		goblin_arrow.position = %GoblinRanged.position + Vector2(-3, 0)
		%GoblinRanged.call_deferred("add_child", goblin_arrow)
		
		#goblin_arrow.draw_back()
		await get_tree().create_timer(2).timeout
		# Reparent :
		if is_instance_valid(goblin_arrow) :
			var arrow_position = goblin_arrow.global_position
			var target_angle = goblin_arrow.global_rotation_degrees
			await get_tree().create_timer(0.05).timeout
			%GoblinRanged.remove_child(goblin_arrow)
			
			#goblin_arrow.top_level = true
			get_tree().current_scene.add_child(goblin_arrow)
			goblin_arrow.global_position = arrow_position
			
			# LOOSE :
			goblin_arrow.apply_angle(target_angle)
			goblin_arrow.fly()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody"and in_sight == false :
		target = body
		in_sight = true
		footsteps()
		move_feet()
		realistic_movement()
		if goblin_type == 1 :
			fire_at_will()


func realistic_movement() -> void:
	if _doing_movement:
		return
	_doing_movement = true

	while in_sight:
		var head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", -2.0, 0.15)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", 2.0, 0.3)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", 0.0, 0.15)
		
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
	var left_rest = %GoblinLegL.position
	var right_rest = %GoblinLegR.position

	while get_parent().visible:

		# LEFT LEG (up while right goes down)
		var left = create_tween()
		left.tween_property(
			%GoblinLegL, "position",
			left_rest + Vector2(0.5, -2.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(
			%GoblinLegL, "position",
			left_rest + Vector2(-0.5, 1.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(%GoblinLegL, "position", left_rest, 0.1)

		# RIGHT LEG (down while left goes up)
		var right = create_tween()
		right.tween_property(
			%GoblinLegR, "position",
			right_rest + Vector2(0.5, 2.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(
			%GoblinLegR, "position",
			right_rest + Vector2(-0.5, -1.0), 0.48
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(%GoblinLegR, "position", right_rest, 0.1)

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

	breathe.tween_property(%GoblinSprite, "position:y", %GoblinSprite.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%GoblinHead, "position:y", %GoblinHead.position.y + up_offset, 0.7)

	breathe.tween_property(%GoblinSprite, "position:y", %GoblinSprite.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%GoblinHead, "position:y", %GoblinHead.position.y + down_offset, 0.7)

func _on_melee_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false :
		body.ogre_slashed($".")

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
	%visibility_collision.scale *= 2.4
	in_sight = true
	speed = 50
	%FootStepParticlesLeft.visible = false
	%FootStepParticlesRight.visible = false
	%GoblinShadowSprite.visible = true
	%GoblinHead.visible = false
	%GoblinSprite.visible = false
	%WeaponPivot.visible = false
	%GoblinLegL.visible = false
	%GoblinLegR.visible = false


func _on_goblin_hit_box_area_entered(area: Area2D) -> void:
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

func flash_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/tint_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/tint_amount", 0.12, 0.1)

func flash_actual_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)

func burn() :
	EventBus.goblins_burnt += 1
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
