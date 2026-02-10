extends Area2D

var in_sight = false
var brody_position
var direction

var melee_pivot_offset
var new_facing
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
	breathing()
	melee_pivot_offset = %WeaponPivot.position
	
	# Random Weapon Chooser:
	goblin_type = randi_range(1, 2)
	if goblin_type == 1 : # Then Archer :
		%MeleeArea.queue_free()
		%SlashArea.queue_free()
		%GoblinMelee.queue_free()
		if randi_range(1, 2) == 1 : # Crossbow :
			%GoblinRanged.play("crossbow")
		else :
			%GoblinRanged.play("bow")
			
	elif goblin_type == 2 : # Then Melee :
		var weapon_picker = randi_range(1, 3)
		if weapon_picker == 1 :
			%GoblinMelee.play("axe")
		elif weapon_picker == 2 :
			%GoblinMelee.play("club")
		elif weapon_picker == 3 :
			%GoblinMelee.play("pick")


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
	bow_or_melee = -1
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody":
		target = body
		in_sight = true
		footsteps()
		realistic_movement()
		if goblin_type == 1 :
			fire_at_will()


func _on_body_exited(body: Node2D) -> void:
	if body == target:
		in_sight = false
		target = null


func realistic_movement() -> void:
	if _doing_movement:
		return
	_doing_movement = true

	while in_sight:
		var head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", -2.0, 0.15)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", 2.0, 0.3)
		head_tween.tween_property(%GoblinHead, "rotation_degrees", 0.0, 0.15)

		var visual_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		visual_tween.tween_property(%GoblinMelee, "rotation_degrees", -randf_range(2.0, 5.0), 0.15)
		visual_tween.tween_property(%GoblinMelee, "rotation_degrees", randf_range(2.0, 5.0), 0.3)
		visual_tween.tween_property(%GoblinMelee, "rotation_degrees", 0.0, 0.15)

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
	%GoblinHeadShadow.visible = true
	%GoblinShadowSprite.visible = true
	%GoblinMeleeShadow.visible = true
	%GoblinHead.visible = false
	%GoblinSprite.visible = false
	%GoblinMelee.visible = false


func _on_goblin_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true or area.name == "winged_torch" :
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

func flash_white() :
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)

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
