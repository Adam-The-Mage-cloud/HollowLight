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

var wander_timer = 0.0
var wander_offset = Vector2.ZERO
var velocity = Vector2.ZERO
var noise = FastNoiseLite.new()
var unique_id = randi()  # give each goblin its own noise seed

var target

var shadow = false
var pinatered = false

var bobbing = false

var attacking = false

var goblin_type

var lightable = false

var speed = 24
var health = 3

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
	await get_tree().create_timer(randf_range(0.05, 1.0)).timeout
	%TurnedVisibleSound.playing = true

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

	# --- Target tracking ---
	brody_position = target.global_position
	var to_brody = brody_position - global_position
	var direction = to_brody.normalized()

	# --- Facing ---
	var new_facing = bow_or_melee
	if brody_position.x < global_position.x:
		new_facing = -bow_or_melee

	%Visuals.scale.x = new_facing

	# ----------------------------------------------------
	# 1) SEPARATION FORCE (prevents bunching)
	# ----------------------------------------------------
	var separation_force = Vector2.ZERO
	var separation_radius = 32.0   # tune this
	var separation_strength = 1.2  # tune this

	for other in get_parent().get_children():
		if other == self:
			continue
		if not other is Area2D:
			continue

		var dist = global_position.distance_to(other.global_position)
		if dist < separation_radius and dist > 0:
			var push = (global_position - other.global_position).normalized()
			push *= (separation_radius - dist) / separation_radius
			separation_force += push

	separation_force *= separation_strength

	# ----------------------------------------------------
	# 2) WANDER (irregular movement)
	# ----------------------------------------------------
	wander_timer -= delta
	if wander_timer <= 0.0:
		var angle = randf_range(-1.0, 1.0) * 1.4   # wider angle = more irregular
		wander_offset = Vector2.RIGHT.rotated(angle) * 0.55
		wander_timer = randf_range(0.25, 0.9)      # faster changes = more chaos

	# ----------------------------------------------------
	# 3) FINAL STEERING BLEND
	# ----------------------------------------------------
	var final_dir = (direction + wander_offset + separation_force).normalized()

	# Add inertia for weight
	velocity = velocity.lerp(final_dir * speed, 0.12)

	# --- Movement ---
	if global_position.distance_to(brody_position) > 10.0:
		position += velocity * delta

	# --- Weapon pivot ---
	if not attacking:
		%WeaponPivot.look_at(brody_position)

		if bow_or_melee != -1:
			if new_facing < 0:
				%WeaponPivot.rotation += PI
				%WeaponPivot.scale.x = -new_facing
			else:
				%WeaponPivot.scale.x = -new_facing



func slash() -> void:
	%AttackSound.playing = true
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
	elif body.has_method("check_health") :
		body.check_health($".")


func _on_slash_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = true


func fire_at_will() :
	while get_parent().visible == true:
		%AttackSound.playing = true
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
	elif body.has_method("check_health") :
		body.check_health($".")

func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()
	# Drop Gold at this point?

func shadow_form() :
	flash_white()
	%GoblinCollision.scale *= Vector2(1.0, 0.5)
	%GoblinCollision.position += Vector2(0, -2)
	$"." .material.set("shader_parameter/cloud_amount", 0.25)
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
	%GoblinShadowSprite.visible = true
	%GoblinHead.visible = false
	%GoblinSprite.visible = false
	%WeaponPivot.visible = false
	%GoblinLegL.visible = false
	%GoblinLegR.visible = false
	await get_tree().create_timer(0.005).timeout
	%visibility_collision.set_deferred("disabled", false)

func _on_goblin_hit_box_area_entered(area: Area2D) -> void:
	# Knockback and 1/3 burnt flash from Torch
	if area.name == "Torch" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * (area.effort * 24.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		health -= 1
		burn_away()
		
	if area.name == "mystic_sword" or area.name == "winged_torch" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * (area.effort * 24.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Take away 1/3 of health and some of appearance
		health -= 1
		burn_away()
	elif area.name == "brody_shield" :
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func burn_away() :
	%goblinDeath.playing = true
	# Flash effect
	var tween1 = create_tween()
	tween1.tween_property(material, "shader_parameter/tint_amount", 0.8, 0.15)
	tween1.tween_property(material, "shader_parameter/tint_amount", 0.0, 0.15)
	# Turn on fire light
	light_mask = 1
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
	if health <= 0:
		EventBus.torch_wraiths_burnt += 1
		drop_currency()
		pinatered = true
		var rotation_tween = create_tween()
		rotation_tween.tween_property($".", "rotation_degrees", $".".rotation_degrees + 540, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var scale_tween = create_tween()
		scale_tween.tween_property($".", "scale", Vector2(0,0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var death_tween = create_tween()
		death_tween.tween_property(material, "shader_parameter/burn_amount", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.3).timeout
		EventBus.raid_entity_count -= 1
		if EventBus.raid_entity_count == 0 :
			get_tree().current_scene.sanctuary_raid_finished()
		await get_tree().create_timer(0.3).timeout
		queue_free()

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
		EventBus.raid_entity_count -= 1
		if EventBus.raid_entity_count == 0 :
			get_tree().current_scene.sanctuary_raid_finished()
		queue_free())
		

func drop_currency() :
	if pinatered == false :
		pinatered = true
		# Drop XP :
		var random_xp_amount = randi_range(1, 2)
		for i in random_xp_amount : 
			var xp = preload("res://Scenes/Currencies/experience_orb.tscn").instantiate()
			xp.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", xp)
			await get_tree().create_timer(0.008).timeout
			
		# Drop Gold :
		var random_gold_amount = randi_range(1, (1 + (EventBus.amount_lootchance_upgraded / 3)))
		for i in random_gold_amount : 
			var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
			gold_piece.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", gold_piece)
			await get_tree().create_timer(0.008).timeout
		
		# Drop Fervour :
		if randi_range(1, 4) == 2 :
			var fervour = preload("res://Scenes/travellers_sanctuary/OrbleVillage/fervour_collection.tscn").instantiate()
			fervour.global_position = $".".global_position
			get_tree().current_scene.get_node("EntitiesToBeDeleted").call_deferred("add_child", fervour)

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
