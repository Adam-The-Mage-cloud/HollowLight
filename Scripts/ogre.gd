extends Area2D

var in_sight = false
var brody_position
var direction

var target

var bobbing = false

var speed = 12

func _ready() :
	material = material.duplicate()
	breathing()
	randomize()

func _physics_process(delta: float) -> void:
	if in_sight == true :
		# Moving : )
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
	if body.name == "Brody" :
		target = body
		in_sight = true
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
		body.ogre_slashed()
