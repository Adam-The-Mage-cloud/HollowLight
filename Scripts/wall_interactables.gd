extends Area2D

# Script that contains the logic for all optional interactable assets on the ground :

# Predefined Themes :
var current_theme = 1 # Reg Gray Dungeon

# Predefined Types (if type isn't chosen to be 0 beforehand, randomly pick the type :
var type = 0
var chosen_skin_number = 0
# Type 1 = WALL TORCHES
var vase_type = 0
var alight = false
# Type 2 = PAINTINGS
var campfire_type = 0
var smashed = false


func _ready() :
	# Randomly Pick Interactable Based off Theme and Then Type (if specified) : 
		if EventBus.current_theme == 2 :
			%WallInteractableSprite.modulate = Color(0.067, 0.988, 0.988)
		elif EventBus.current_theme == 3 :
			%WallInteractableSprite.modulate = Color(0.976, 0.192, 0.298, 1.0)
		elif EventBus.current_theme == 4 :
			%WallInteractableSprite.modulate = Color(0.0, 0.306, 0.078, 1.0)
	#if EventBus.current_theme == 1 :
		if type == 0 : # Then let's pick the item randomly :
			type = randi_range(1, 1)
		
		# Let's Begin :
		if type == 1 : # WALL TORCH
			chosen_skin_number = randi_range(1, 1)
			%WallInteractableSprite.play("walltorch_" + str(chosen_skin_number))
			vase_type = chosen_skin_number
		
		elif type == 2 : # PAINTING
			chosen_skin_number = randi_range(1, 2)
			%WallInteractableSprite.play("campfire_" + str(chosen_skin_number))


func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		if type == 1 and alight == false : # THEN WALL TORCH SO :
			# ALIGHT WALLTORCH :
			%DarknessRepellerCollision.call_deferred("set_disabled", false)
			alight = true
			%WallTorchLight.enabled = true
			alight_flame()
			%MainFlame.emitting = true
			%MainFlameSecondary.emitting = true
			
		elif type == 2 : # THEN PAINTING :
			# DO NOTHING :
			pass
	elif EventBus.intro == true :
		# ALIGHT WALLTORCH :
		%DarknessRepellerCollision.call_deferred("set_disabled", false)
		alight = true
		%WallTorchLight.enabled = true
		alight_flame()
		%MainFlame.emitting = true
		%MainFlameSecondary.emitting = true


# Extra Effect Functions :
func alight_flame() :
	var intro_light_tween = create_tween()
	intro_light_tween.tween_property(%WallTorchLight, "energy", 0.8, 1.4)
	intro_light_tween.tween_property(%WallTorchLight, "texture_scale", 0.4, 1.4)
	
	var intro_particles_tween = create_tween()
	intro_particles_tween.tween_property(%MainFlame, "amount_ratio", 0.05, 1.4)
	intro_particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 0.05, 1.4)
	
	await get_tree().create_timer(2).timeout
	var light_tween = create_tween()
	light_tween.tween_property(%WallTorchLight, "energy", 2.4, 4.0)
	light_tween.tween_property(%WallTorchLight, "texture_scale", 1.0, 3.5)
	
	var particles_tween = create_tween()
	particles_tween.tween_property(%MainFlame, "amount_ratio", 1.00, 5.5)
	particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 1.00, 4.0)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DARKNESS REDUCING AURA INTERACTABLES :
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_darkness_repeller_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		# Darkness Level Decreasing :
		body.resting()
		%DarknessReducer.start()

func _on_darkness_repeller_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		# Stop Darkness Level Decreasing :
		body.nolonger_resting()
		%DarknessReducer.stop()

func _on_darkness_reducer_timeout() -> void:
	EventBus.total_current_darkness -= 2


func _on_body_entered(body: Node2D) -> void:
	# Destroy if ontop of door :
	if body.name == "DoorArea" :
		queue_free()
