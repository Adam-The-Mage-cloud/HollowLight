extends Area2D

var health = 3

var in_sight = false
var brody_position
var direction

var target
var last_location
var last_safe_location
var monster_saved = false

var new_facing = 1
var last_facing_scale_x = 1       # If bow then -1 just to make sure it's not flipped


var shadow = false
var pinatered = false

var bobbing = false


var goblin_type

var lightable = false

var speed = 5

var _doing_movement = false
var _doing_footsteps = false

func _ready() -> void:
	randomize()
	material = material.duplicate()
	set_tint()
	footsteps()
	move_feet()
	realistic_movement()
	breathing()
	shadow_form()
	target = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	brody_position = global_position + Vector2(0, randf_range(-3050, 3050)) 


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
	if not get_parent().visible:
		return
	
	
	direction = (brody_position - global_position).normalized()

	new_facing = 1 
	if brody_position.x < global_position.x:
		new_facing = -1

	# Flip ONLY the visuals, not the pivot
	%Visuals.scale.x = new_facing

	# Movement
	if global_position.distance_to(brody_position) > 10.0:
		position += direction * speed * delta
	
	if target == global_position :
		fade()

func fade() :
	queue_free()



func realistic_movement() -> void:
	while (1) :
		var head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(%GoblinSprite, "rotation_degrees", -8.0, 0.10)
		head_tween.tween_property(%GoblinSprite, "rotation_degrees", 10.0, 0.20)
		head_tween.tween_property(%GoblinSprite, "rotation_degrees", 0.0, 0.10)

		var bob_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob_tween.tween_property(self, "global_position:y", global_position.y, 0.08)

		await get_tree().create_timer(randf_range(0.4, 0.7)).timeout



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

	breathe.tween_property(%GoblinSprite, "position:y", %GoblinSprite.position.y + down_offset, 0.7)


func shadow_form() :
	shadow = true
	lightable = true
	%visibility_collision.scale *= 2.4
	in_sight = true
	speed = 25


func _on_goblin_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true or area.name == "winged_torch" and lightable == true :
		# Knockback:
		if health <= 0 :
			drop_backpack_gold()
			speed = -50
			var rotation_tween_1 = create_tween()
			rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + 65, 1.2)
			global_position.y += randf_range(-3, 3)
			global_position.x += randf_range(-3, 3)
			var knockback_direction = (global_position - area.global_position).normalized()
			var knockback_movement = create_tween()
			knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			burn()
		health -= 1
		flash_white()
		var knockback_direction2 = (global_position - area.global_position).normalized()
		var knockback_movement2 = create_tween()
		knockback_movement2.tween_property(self, "position", position + knockback_direction2 * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		drop_backpack_gold()

func burn() :
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
		


func drop_backpack_gold() :
	# Drop Gold :
	var random_gold_amount = randi_range(10, 15)
	for i in random_gold_amount : 
		var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
		gold_piece.global_position = %visibility_collision.global_position
		gold_piece.launch_radius = 7.0
		get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", gold_piece)
		await get_tree().create_timer(0.008).timeout
	

func flash_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.6)


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


func _on_despawn_timer_timeout() -> void:
	var rotation_tween_1 = create_tween()
	rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + 65, 1.2)
	global_position.y += randf_range(-3, 3)
	global_position.x += randf_range(-3, 3)
	var knockback_direction = (global_position - global_position + Vector2(randf_range(-1, 1), randf_range(-1, 1))).normalized()
	var knockback_movement = create_tween()
	knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	burn()

func _on_check_brody_location_okay() :
	while is_instance_valid(self) :
		# Check if player stuck inside something :
		#if last_location == $".".global_position and %BrodyMapStuckCollision.get_overlapping_bodies().size() > 0 :
			#$".".global_position = last_safe_location
		if last_location == $".".global_position and %GoblinCollision.get_overlapping_areas().size() > 0 :
			$".".global_position = last_safe_location
		# Now check if player is not touching a floor tile :
		if is_on_floor_tile() == false :
			$".".global_position = last_safe_location
			burn()
		#if %FloorDetector.is_colliding() == false :
			#$".".global_position = last_safe_location
		else :
			last_safe_location = $".".global_position
	await get_tree().process_frame

func is_on_floor_tile() -> bool:
	var check_pos = global_position + Vector2(0, 0)
	
	for tm in get_tree().get_nodes_in_group("floors"):
		if tm.get_parent().visible == true :
			var local = tm.to_local(check_pos)
			var cell = tm.local_to_map(local)
			
			var data = tm.get_cell_tile_data(cell)
			if data != null:
				return true
	
	return false
