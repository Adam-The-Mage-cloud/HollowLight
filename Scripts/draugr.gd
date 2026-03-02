extends Area2D

const REST_ANGLE_RIGHT = 90
const REST_ANGLE_LEFT = 0

var last_location
var last_safe_location
var monster_saved = false

var in_sight = false
var brody_position
var direction

var start_angle = REST_ANGLE_LEFT
var melee_pivot_offset
var new_facing = 1
var last_facing_scale_x = 1
var bow_or_melee = 1          # If bow then -1 just to make sure it's not flipped

var target

var shadow = false
var pinatered = false

var bobbing = false

var attacking = false

var draugr_weapon_type = 1

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
	draugr_weapon_type = randi_range(1, 2)
	if draugr_weapon_type == 1 : # great-falchion :
		%DraugrMelee.play("greatfalchion")
		%SparkParticles.position = Vector2(2.524, 10.304)
		%GrindParticles.position = Vector2(2.524, 10.304)
	elif draugr_weapon_type == 2 : # great-axe :
		%DraugrMelee.play("greataxe")
		%SparkParticles.position = Vector2(2.524, 10.304)
		%GrindParticles.position = Vector2(-6.7, 14.735)

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

	# Determine facing
	new_facing = 1
	if brody_position.x < global_position.x:
		new_facing = -1

	# Flip ONLY the visuals
	%Visuals.scale.x = new_facing

	# Movement
	if global_position.distance_to(brody_position) > 10.0:
		position += direction * speed * delta

	var pivot = %WeaponPivot

	# --- DRAGGING POSE WHEN NOT ATTACKING ---
	if not attacking:
		# Always drag bottom-right relative to sprite
		var drag_angle = deg_to_rad(0) * new_facing
		pivot.rotation = drag_angle
		
		if new_facing == 1:
			start_angle = REST_ANGLE_RIGHT
		else:
			start_angle = REST_ANGLE_LEFT
			
		pivot.rotation_degrees = start_angle


func slash() -> void:
	attacking = true
	await get_tree().process_frame
	
	var pivot = %WeaponPivot
	var visual = %DraugrMelee
	var slash_tween = create_tween()
	
	var dir = new_facing
	
	# --- ANGLES ---
	var up_angle = 0
	var slam_angle = 0
	
	if dir == 1:
		up_angle = -30        # overhead upswing
		slam_angle = 140      # heavy downward chop
	else:
		up_angle = 210        # overhead upswing mirrored
		slam_angle = -40      # heavy downward chop mirrored
	
	var anticipation = 12 * dir
	var upswing_time = 0.25
	var slam_time = 0.35
	var recovery_time = 0.35
	
	visual.rotation_degrees = 0
	
	# 0. Snap to start
	pivot.rotation_degrees = start_angle
	
	# 1. Anticipation dip
	slash_tween.tween_property(
		pivot, "rotation_degrees",
		start_angle - anticipation,
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Upswing to overhead
	slash_tween.tween_property(
		pivot, "rotation_degrees",
		up_angle,
		upswing_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Downward slam
	slash_tween.tween_property(
		pivot, "rotation_degrees",
		slam_angle,
		slam_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	
	# 4. Recovery to resting angle
	slash_tween.tween_property(
		pivot, "rotation_degrees",
		start_angle,
		recovery_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Hitbox timing
	await get_tree().create_timer(0.1).timeout
	%MeleeArea.monitoring = true
	await slash_tween.finished
	%SparkParticles.emitting = true
	%MeleeArea.monitoring = false
	
	attacking = false
	realistic_movement()


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


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody"and in_sight == false :
		target = body
		in_sight = true
		footsteps()
		move_feet()
		realistic_movement()

func _on_body_exited(body: Node2D) -> void:
	in_sight = false
	#target = null


func realistic_movement() -> void:
	if _doing_movement:
		return
	_doing_movement = true

	while in_sight and not attacking:
		
		# Head sway
		var head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(%DraugrHead, "rotation_degrees", -2.0, 0.15)
		head_tween.tween_property(%DraugrHead, "rotation_degrees", 2.0, 0.3)
		head_tween.tween_property(%DraugrHead, "rotation_degrees", 0.0, 0.15)

		# Body bob
		var bob_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob_tween.tween_property(self, "global_position:y", global_position.y + 1.5, 0.35)
		bob_tween.tween_property(self, "global_position:y", global_position.y, 0.35)

		# Weapon bob (heavy drag)
		var weapon_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		weapon_tween.tween_property(
			%WeaponPivot, "rotation_degrees",
			start_angle + (randf_range(3, 7) * -new_facing),
			0.35
		)
		weapon_tween.tween_property(
			%WeaponPivot, "rotation_degrees",
			start_angle,
			0.35
		)

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
	var left_rest = %DraugrLegL.position
	var right_rest = %DraugrLegR.position

	while get_parent().visible:

		# LEFT LEG (up while right goes down)
		var left = create_tween()
		left.tween_property(
			%DraugrLegL, "position",
			left_rest + Vector2(0.5, -2.0), 0.72
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(
			%DraugrLegL, "position",
			left_rest + Vector2(-0.5, 1.0), 0.72
		).set_trans(Tween.TRANS_SINE)
		left.tween_property(%DraugrLegL, "position", left_rest, 0.72)

		# RIGHT LEG (down while left goes up)
		var right = create_tween()
		right.tween_property(
			%DraugrLegR, "position",
			right_rest + Vector2(0.5, 2.0), 0.72
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(
			%DraugrLegR, "position",
			right_rest + Vector2(-0.5, -1.0), 0.72
		).set_trans(Tween.TRANS_SINE)
		right.tween_property(%DraugrLegR, "position", right_rest, 0.72)

		# Wait for one full cycle
		await get_tree().create_timer(1.4).timeout

func breathing() -> void:
	if bobbing:
		return
	bobbing = true

	var breathe = create_tween().set_loops() # infinite
	breathe.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var up_offset = 0.4
	var down_offset = -0.4

	breathe.tween_property(%DraugrSprite, "position:y", %DraugrSprite.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + up_offset, 0.7)
	breathe.parallel().tween_property(%DraugrHead, "position:y", %DraugrHead.position.y + up_offset, 0.7)

	breathe.tween_property(%DraugrSprite, "position:y", %DraugrSprite.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%WeaponPivot, "position:y", %WeaponPivot.position.y + down_offset, 0.7)
	breathe.parallel().tween_property(%DraugrHead, "position:y", %DraugrHead.position.y + down_offset, 0.7)

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
	%DraugrShadowSprite.visible = true
	%DraugrHead.visible = false
	%DraugrSprite.visible = false
	%WeaponPivot.visible = false
	%DraugrLegL.visible = false
	%DraugrLegR.visible = false


func _on_draugr_hit_box_area_entered(area: Area2D) -> void:
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
	EventBus.draugr_burnt += 1
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
