extends Area2D

var in_sight = false
var brody_position
var direction

var target

var pinatered = false

var bobbing = false

var lightable = false

var speed = 12

func _ready() :
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	material = material.duplicate()
	breathing()
	randomize()

func _physics_process(delta: float) -> void:
	# Moving : )
	if brody_position != null :
		brody_position = target.global_position
		direction = (brody_position - global_position).normalized()
		# Potentially Flip Horizontally :
		if brody_position.x > global_position.x :
			$".".scale.x = -1
		else :
			$".".scale.x = 1
		# Now we have the direction to Brody we can move towards it with :
		if global_position.distance_to(brody_position) > 10 :
			%OgreSprite.play("moving")
			position += delta * speed * direction
		else :
			%OgreSprite.play("stationary")
		# move to brody

func slash() :
	var slash_tween = create_tween()
	# 1. Anticipation: raise the axe a bit first
	slash_tween.tween_property(%AxePivot, "rotation_degrees", 60, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2. Heavy downward swing: fast acceleration
	slash_tween.tween_property(%AxePivot, "rotation_degrees", -50, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 3. Follow-through: slight bounce back
	slash_tween.tween_property(%AxePivot, "rotation_degrees", randf_range(-4, 8), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.25).timeout
	%AxeArea.monitoring = true
	await get_tree().create_timer(0.40).timeout
	%AxeArea.monitoring = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and get_parent().visible == true :
		target = body
		in_sight = true
		footsteps()
		realistic_movement()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		in_sight = false
		%OgreSprite.play("stationary")

func realistic_movement() :
	%OgreSprite.play("moving")
	%OgreHead.play("angry")
	while in_sight == true :
		# HEAD AND AXE JIGGLE :
		brody_position = target.global_position
		var head_tween = create_tween()
		head_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		head_tween.tween_property(%OgreHead, "rotation_degrees", -2, 0.15)
		# Then rotate a little right
		head_tween.tween_property(%OgreHead, "rotation_degrees", 2, 0.3)
		# Return to center
		head_tween.tween_property(%OgreHead, "rotation_degrees", 0, 0.15)
		await get_tree().create_timer(randf_range(0.75, 1.25)).timeout
		global_position.y += 1.5
		var axe_tween = create_tween()
		axe_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate a little left
		axe_tween.tween_property(%AxePivot, "rotation_degrees", -randf_range(2, 5), 0.15)
		# Then rotate a little right
		axe_tween.tween_property(%AxePivot, "rotation_degrees", randf_range(2, 5), 0.3)
		# Return to center
		axe_tween.tween_property(%AxePivot, "rotation_degrees", 0, 0.15)
		await get_tree().create_timer(0.7).timeout
		global_position.y -= 1
	%OgreSprite.play("stationary")
	%OgreHead.play("unaware")

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
			%OgreSprite.position.y += 0.1
			%AxePivot.position.y += 0.1
			%OgreHead.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%OgreSprite.position.y += 0.05
			%AxePivot.position.y += 0.05
			%OgreHead.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%OgreSprite.position.y -= 0.1
			%AxePivot.position.y -= 0.1
			%OgreHead.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%OgreSprite.position.y -= 0.05
			%AxePivot.position.y -= 0.05
			%OgreHead.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()

func _on_axe_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		body.ogre_slashed($".")

func _on_all_beacons_lit() :
	if get_parent().visible == true :
		shadow_form()
	# Drop Gold at this point?

func shadow_form() :
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
	%OgreShadowSprite.play("moving")
	%OgreHeadShadow.visible = true
	%OgreShadowSprite.visible = true
	%OgreAxeShadow.visible = true
	%OgreHead.visible = false
	%OgreSprite.visible = false
	%OgreAxe.visible = false


func _on_axe_area_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true :
		# Knockback:
		speed = -50
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 20, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		burn()


func _on_ogre_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "Torch" and lightable == true :
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
	
	var tween2 := create_tween()
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
