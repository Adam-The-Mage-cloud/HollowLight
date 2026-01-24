extends Area2D

# Script that contains the logic for all optional interactable assets on the ground :

# Predefined Themes :
var current_theme = 1 # Reg Gray Dungeon

# Predefined Types (if type isn't chosen to be 0 beforehand, randomly pick the type :
var type = 0
var chosen_skin_number = 0
# Type 1 = VASES / URNS
var vase_type = 0
var smashed = false
# Type 2 = CAMPFIRES
var campfire_type = 0
var alight = false

func _ready() :
	# Randomly Pick Interactable Based off Theme and Then Type (if specified) : 
	if EventBus.current_theme == 1 :
		if type == 0 : # Then let's pick the item randomly :
			type = randi_range(1, 2)
		
		# Let's Begin :
		if type == 1 : # VASES / URNS
			chosen_skin_number = randi_range(1, 1)
			%InteractableSprite.play("vase_" + str(chosen_skin_number))
			vase_type = chosen_skin_number
		
		elif type == 2 : # CAMPFIRES
			chosen_skin_number = randi_range(1, 2)
			%InteractableSprite.play("campfire_" + str(chosen_skin_number))


func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		if type == 1 and smashed == false : # THEN VASE / URN SO :
			# BREAK :
			smashed = true
			drop_loot()
			%VaseShatteredParticles.emitting = true
			%InteractableSprite.play("vase_" + str(chosen_skin_number) + "_broken")
		
		elif type == 2 and alight == false : # THEN CAMPFIRE :
			# SET ALIGHT :
			alight = true
			%MainFlame.emitting = true
			%MainFlameSecondary.emitting = true
			%FlameLight.enabled = true
			alight_flame()
			# Enable Darkness Healing Aura
			%DarknessRepellerCollision.call_deferred("set_disabled", false)
			
			if chosen_skin_number == 1 :
				%InteractableSprite.play("campfire_1_alight")
				%MainFlame.amount_ratio = 0.3
				%MainFlameSecondary.amount_ratio = 0.3
				%MainFlame.position = Vector2(0.1, 4.25)
				
			elif chosen_skin_number == 2 :
				%InteractableSprite.play("campfire_2_alight")
				pass

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Extra Effect Functions :
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func alight_flame() :
	var intro_light_tween = create_tween()
	intro_light_tween.tween_property(%FlameLight, "energy", 0.8, 1.4)
	intro_light_tween.tween_property(%FlameLight, "texture_scale", 0.4, 1.4)
	
	var intro_particles_tween = create_tween()
	intro_particles_tween.tween_property(%MainFlame, "amount_ratio", 0.05, 1.4)
	intro_particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 0.05, 1.4)
	
	await get_tree().create_timer(2).timeout
	var light_tween = create_tween()
	light_tween.tween_property(%FlameLight, "energy", 2.4, 4.0)
	light_tween.tween_property(%FlameLight, "texture_scale", 1.0, 3.5)
	
	var particles_tween = create_tween()
	particles_tween.tween_property(%MainFlame, "amount_ratio", 1.00, 5.5)
	particles_tween.tween_property(%MainFlameSecondary, "amount_ratio", 1.00, 4.0)


func drop_loot() : 
	# Drop XP :
	var random_xp_amount = randi_range(2, 4)
	for i in random_xp_amount : 
		var xp = preload("res://Scenes/Currencies/experience_orb.tscn").instantiate()
		xp.global_position = $".".global_position
		get_tree().current_scene.call_deferred("add_child", xp)
		await get_tree().create_timer(0.008).timeout
		
	# Drop Gold :
	var random_gold_amount = randi_range(2, 6)
	for i in random_gold_amount : 
		var gold_piece = preload("res://Scenes/Currencies/gold_piece.tscn").instantiate()
		gold_piece.global_position = $".".global_position
		get_tree().current_scene.call_deferred("add_child", gold_piece)
		await get_tree().create_timer(0.008).timeout

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
