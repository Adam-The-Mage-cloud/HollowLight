extends Area2D

var health = 3 
var wager = 1.0

var in_sight = false
var brody_position
var direction
var velocity = Vector2.ZERO

var target

var last_location
var last_safe_location
var monster_saved = false

var target_captured = false
var pincing = false

var shadow = false
var pinatered = false
var shadow_pinatered = false

var bobbing = false

var lightable = false
var flip_cooldown = 1.0
var flip_threshold = 12.0 
var is_lunging = false
var lunge_available = true

var speed = 48

func _ready() :
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	material = material.duplicate()
	set_tint()
	breathing()
	if EventBus.intro == true :
		slow_down()
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
		material.set_shader_parameter("tint_amount", 0.36)

func _physics_process(delta: float) -> void:
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
				position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		target = body
		in_sight = true
		footsteps()
		realistic_movement()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		in_sight = false

func slow_down() :
	speed /= 4

func realistic_movement():
	while in_sight:
		brody_position = target.global_position
		
		await get_tree().create_timer(randf_range(0.24, 0.36)).timeout


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
			%GrindSprite.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%GrindSprite.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%GrindSprite.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%GrindSprite.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()


func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()


func shadow_form() :
	%DarknessLight.enabled = true
	flash_white()
	%GrindCollision.scale *= Vector2(1.35, 1.0)
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
	%GrindShadowSprite.play("default")
	%GrindShadowSprite.visible = true
	%GrindSprite.visible = false
	await get_tree().create_timer(0.005).timeout
	%visibility_collision.set_deferred("disabled", false)


func _on_grind_hit_box_area_entered(area: Area2D) -> void:
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
		knockback_movement.tween_property(self, "position", position + knockback_direction * (area.effort * 24.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) # 4 is default
		knockback_movement.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		knockback_movement.tween_property(self, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_white()
		health -= 1
		$".".light_mask = 1
		%OnFireLight.enabled = true
		# Calculate new burn target
		if health == 2 :
			drop_currency()
			%MonsterBurningParticles.amount_ratio = 0.3
			%OnFireLight.texture.width = 32
			%OnFireLight.texture.height = 32
		else :
			drop_currency()
			%MonsterBurningParticles.amount_ratio = 1.0
			%OnFireLight.texture.width = 48
			%OnFireLight.texture.height = 48
		# Fire light animation
		var lighttween = create_tween()
		lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
		lighttween.tween_property(%OnFireLight, "texture_scale", 1.0, 0.45)
	
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
	EventBus.grindstonters_burnt += 1
	var tween1 = create_tween()
	tween1.tween_property(material, "shader_parameter/flash_color", Vector3(0.95, 0.65, 0.25), 0.25)
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	
	# Turn Light Mask on :aaaaaa
	$".".light_mask = 1
	%OnFireLight.enabled = true
	# Drop Currencies :
	wager = 2.0
	drop_currency()
	shadow_pinatered = true
	
	var tween2 := create_tween()
	tween2.tween_property(material, "shader_parameter/burn_amount", 1.0, 1.0)
	
	var lighttween = create_tween()
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
	lighttween.tween_property(%OnFireLight, "texture_scale", 0.0, 0.45)
	
	# Once finished then queue_free :
	tween2.finished.connect(func() :
		queue_free())


func drop_currency() :
	if pinatered == false or shadow == true :
		if shadow_pinatered == false :
			# Drop XP :
			pinatered = true
			var random_xp_amount = randi_range(1 * wager, 3 * wager)
			for i in random_xp_amount : 
				var xp = preload("res://Scenes/Currencies/experience_orb.tscn").instantiate()
				xp.global_position = $".".global_position
				get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", xp)
				await get_tree().create_timer(0.008).timeout
				
			# Drop Gold :
			var random_gold_amount = randi_range(1 * wager, (2 + (EventBus.amount_lootchance_upgraded / 3) * wager))
			for i in random_gold_amount : 
				var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
				gold_piece.global_position = $".".global_position
				get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", gold_piece)
				await get_tree().create_timer(0.008).timeout
				
			# Drop Embers :
			var ember = preload("res://Scenes/Currencies/ember.tscn").instantiate()
			ember.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", ember)
			
			if randi_range(1, 48) == 2 :
				var FervourScene = preload("res://Scenes/travellers_sanctuary/OrbleVillage/fervour_collection.tscn")
				var fervour = FervourScene.instantiate()
				fervour.global_position = $".".global_position
				call_deferred("add_child", fervour)


func _on_grind_hit_box_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true and shadow == false :
		body.grindstone_bounce(self)


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
