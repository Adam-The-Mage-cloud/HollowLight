extends Area2D

var version_number

var target
var brody_position
var direction
var speed = 12

var pinatered = false

var burning = false

func _ready() :
	# Pick Random Appearance :
	material = material.duplicate()
	version_number = randi_range(1, 9)
	if version_number == 1 :
		%ShadowCollision.position = Vector2(-2, -0.5)
	if version_number == 2 :
		%ShadowCollision.position = Vector2(-1, 0)
	if version_number == 3 :
		%ShadowCollision.position = Vector2(-3.5, 0.5)
	if version_number == 4 :
		%ShadowCollision.position = Vector2(-4, 0)
	if version_number == 5 :
		%ShadowCollision.position = Vector2(-5.5, 1)
	if version_number == 6 :
		%ShadowCollision.position = Vector2(-6.5, 0)
		%OnFireLight.position.x -= 3
	if version_number == 7 :
		%ShadowCollision.position = Vector2(-6.5, 0)
		%OnFireLight.position.x -= 3
	if version_number == 8 :
		%ShadowCollision.position = Vector2(-9.25, 0)
		%OnFireLight.position.x -= 8
	if version_number == 9 :
		%ShadowCollision.position = Vector2(-6.75, 1)
		%OnFireLight.position.x -= 3
	%ShadowVersion.play("v" + str(version_number))
	# Deviation of how they're titled towards the player :
	%ShadowVersion.rotation_degrees = randf_range(60, 90)

func _physics_process(delta: float) -> void:
	# Look at Brody gradually (acting like a cloud) :
	if burning == false :
		var desired_angle = (target.global_position - global_position).angle()
		rotation = lerp_angle(rotation, desired_angle, 0.025)
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
			position += delta * speed * direction


func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		# Knockback:
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - area.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 4, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		on_fire()

func on_fire():
	burning = true
	
	var rotation_tween_1 = create_tween()
	rotation_tween_1.tween_property($".", "rotation_degrees", $".".rotation_degrees + randi_range(-45, 45), 1.00).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	var tween1 := create_tween()
	tween1.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.15)
	tween1.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.15)
	
	# Turn Light Mask on :
	#drop_currency()
	$".".light_mask = 1
	%OnFireLight.enabled = true
	
	var tween2 := create_tween()
	tween2.tween_property(material, "shader_parameter/burn_amount", 1.0, 1.0)
	
	var lighttween = create_tween()
	lighttween.tween_property(%OnFireLight, "texture_scale", 1.6, 0.0)
	lighttween.tween_property(%OnFireLight, "texture_scale", 0.0, 0.45)
	
	# Once finished then queue_free :
	tween2.finished.connect(func() :
		queue_free())

func drop_currency() :
	# Drop Embers :
	if pinatered == false :
		pinatered = true
		var ember = preload("res://Scenes/Currencies/ember.tscn").instantiate()
		ember.global_position = $".".global_position
		get_tree().current_scene.call_deferred("add_child", ember)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		body.darkness_consuming()
