extends Area2D

var elemental_type

func _ready() :
	material = material.duplicate()
	# Pick ELEMENTAL type :
	print (elemental_type)
	if elemental_type == 1 : # FIRE :
		%BallSprite.play("Fire")
		fadein_fireparticles(%FireParticles)
		
	elif elemental_type == 2 : # ICE :
		%BallSprite.play("Ice")
		fadein_fireparticles(%IceParticles)
		
	elif elemental_type == 3 : # MYSTIC
		%BallSprite.play("Mystic")
		fadein_fireparticles(%MysticParticles)
	
	fadein()

func fadein_fireparticles(particles) :
	particles.emitting = true
	var amount_tween = create_tween()
	amount_tween.tween_property(particles, "amount_ratio", 1.0, 1.6)
	

func fadein() :
	var mat = material
	mat.set_shader_parameter("element_type", elemental_type)
	mat.set_shader_parameter("reveal", 0.0)
	
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/reveal", 1.0, 2.0)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		body.ogre_slashed(self)
		body.massive_knockback(self)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "brody_shield":
		queue_free()

func fly() :
	var max_deviation = deg_to_rad(16) # Max random deviation (in degrees)
	var deviation = randf_range(-max_deviation, max_deviation)
	var final_angle = global_rotation + deviation
	var direction = -Vector2.RIGHT.rotated(final_angle)
	
	var distance = 400
	
	var fly_straight_tween = create_tween()
	fly_straight_tween.tween_property(self, "global_position", global_position + direction * distance, 5.5)

func apply_angle(target_angle) :
	rotation_degrees = target_angle


func _on_despawn_timer_timeout() -> void:
	queue_free()
