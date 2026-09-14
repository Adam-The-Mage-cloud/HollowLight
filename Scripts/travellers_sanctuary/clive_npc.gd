extends CharacterBody2D

# Movement Variables :
var direction = Vector2.ZERO
var speed = 24

# Movement Boundary Variables :
var home_position = Vector2.ZERO
var patrol_size = 64 

var first_speech = true

var old_pos = Vector2.ZERO

func _ready() -> void:
	randomize()
	home_position = global_position
	%CliveSprite.play("stood_still_front")
	%DirectionTimer.start()
	random_speech()
	await get_tree().create_timer(4).timeout
	%SpeechTimer.start()


func _process(delta: float) -> void:
	var new_pos = global_position + direction * speed * delta
	old_pos = new_pos
	
	# Clamp inside the boundary
	new_pos.x = clamp(new_pos.x, home_position.x - patrol_size, home_position.x + patrol_size)
	new_pos.y = clamp(new_pos.y, home_position.y - patrol_size, home_position.y + patrol_size)
	
	# If clamping changed the position → border reached
	if new_pos != old_pos and direction != Vector2.ZERO:
		_on_movement_time_timer_timeout()
	
	# Footsteps
	if direction != Vector2.ZERO :
		footsteps_activated()
	
	global_position = new_pos


func _on_direction_movement_timer_timeout() -> void:
	%MovementTimeTimer.wait_time = randf_range(2.4, 3.6)
	%MovementTimeTimer.start()
	
	var possible_dirs: Array[Vector2] = []
	
	# Only choose directions that stay inside the square
	if global_position.y > home_position.y - patrol_size:
		possible_dirs.append(Vector2(0, -1))
	if global_position.y < home_position.y + patrol_size:
		possible_dirs.append(Vector2(0, 1))
	if global_position.x > home_position.x - patrol_size:
		possible_dirs.append(Vector2(-1, 0))
	if global_position.x < home_position.x + patrol_size:
		possible_dirs.append(Vector2(1, 0))
	
	# Pick a valid direction
	if possible_dirs.size() > 0:
		direction = possible_dirs.pick_random()
	else:
		direction = Vector2.ZERO
	
	check_direction_animation()


func _on_movement_time_timer_timeout() -> void:
	# Standing Animations
	if direction == Vector2(0, -1):
		%CliveSprite.play("stood_still_back")
	elif direction == Vector2(0, 1):
		%CliveSprite.play("stood_still_front")
	elif direction == Vector2(1, 0):
		%CliveSprite.play("stood_still_sideways")
		%CliveSprite.scale.x = 1
	elif direction == Vector2(-1, 0):
		%CliveSprite.play("stood_still_sideways")
		%CliveSprite.scale.x = -1
	
	direction = Vector2.ZERO
	%DirectionTimer.wait_time = randf_range(8, 13)
	%DirectionTimer.start()


func check_direction_animation() -> void:
	if direction == Vector2(0, -1):
		%CliveSprite.play("moving_up")
	elif direction == Vector2(0, 1):
		%CliveSprite.play("moving_down")
	elif direction == Vector2(1, 0):
		%CliveSprite.play("moving_sideways")
		%CliveSprite.scale.x = 1
	elif direction == Vector2(-1, 0):
		%CliveSprite.play("moving_sideways")
		%CliveSprite.scale.x = -1

func footsteps_activated() :
	while direction != Vector2.ZERO:
		%FootStepParticlesLeft.emitting = true
		await get_tree().create_timer(0.2).timeout
		%FootStepParticlesRight.emitting = true
		await get_tree().create_timer(0.2).timeout

# SPEECH BUBBLE MANAGEMENT :
func _on_speech_timer_timeout() -> void:
	# 1/3 Chance every 6 seconds :
	if randi_range(1, 2) == 2 :
		if randi_range(1, 3) == 1 or randi_range(1, 3) == 1 :
			random_speech()

func random_speech() :
	# Intialise Bubble & Text :
	%SpeechBubbleSprite.visible = true
	%SpeechBubbleSprite.scale = Vector2(0.85, 0.85)
	%SpeechBubbleSprite.modulate.a = 0.0
	
	# Choose Speech Text Randomly :
	var chosen_speech = randi_range(1, 16)
	if chosen_speech == 1 :
		%SpeechText.text = str("*hmph*, I miss my old Bessie")
	elif chosen_speech == 2 :
		%SpeechText.text = str("*sigh*, I never thought I'd see the day... ")
	elif chosen_speech == 3 :
		%SpeechText.text = str("Looking back, some storms I wish I had just rode out.")
	elif chosen_speech == 4 :
		%SpeechText.text = str("Sometimes it's the little deeds of ordinary folk...")
	elif chosen_speech == 5 :
		%SpeechText.text = str("Who you are is who you are when nobodies watching.")
	elif chosen_speech == 6 :
		%SpeechText.text = str("*shouting* LITTLE ORBLIT, COME VIEW MY WARES!")
	elif chosen_speech == 7 :
		%SpeechText.text = str("*grumbling*, I've spent one too many years on this road...")
	elif chosen_speech == 8 :
		%SpeechText.text = str("Wealth doesn't branch from gold; it comes from love.")
	elif chosen_speech == 9 :
		%SpeechText.text = str("*shyly*, it's pretty nice round here huh..?")
	elif chosen_speech == 10 :
		%SpeechText.text = str("I'm glad you're around Little Orblit...")
	elif chosen_speech == 11 :
		%SpeechText.text = str("*Valiantly*, our courage may fail, but it is not this day.")
	elif chosen_speech == 12 :
		%SpeechText.text = str("*pondering*,   I sure hope this forest one day recovers...")
	elif chosen_speech == 13 :
		%SpeechText.text = str("For such a small thing, you inspire me, Little Orblit...")
	elif chosen_speech == 14 :
		%SpeechText.text = str("...")
	elif chosen_speech == 15 :
		%SpeechText.text = str("*smiles gratefully*")
	elif chosen_speech == 16 :
		%SpeechText.text = str("*whistling 'one stormy night' *")
	
	if first_speech == true :
		%SpeechText.text = str("WELCOME BACK,       Little Orblit!")
		first_speech = false
	
	# Activate Speech Bubble Tween :
	var speech_bubble_tween = create_tween()
	speech_bubble_tween.set_parallel(true)
	
	speech_bubble_tween.tween_property(%SpeechBubbleSprite, "scale", Vector2(1, 1), 0.14).set_ease(Tween.EASE_OUT)
	speech_bubble_tween.tween_property(%SpeechBubbleSprite, "modulate:a", 1.0, 0.14).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(6).timeout
	var speech_tween_2 = create_tween()
	speech_tween_2.set_parallel(true)
	
	speech_tween_2.tween_property(%SpeechBubbleSprite, "scale", Vector2(0.9, 0.9), 0.12).set_ease(Tween.EASE_IN)
	speech_tween_2.tween_property(%SpeechBubbleSprite, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(0.12).timeout
	%SpeechBubbleSprite.visible = false


# ON BODY ENTERED (CLIVES SHOP OPENABLE)
func _on_shop_area_body_entered(body: Node2D) -> void:
	# Enable Shop Interaction Ability :
	if body.name == "Brody" :
		%CliveShopHey.playing = true
		EventBus.clives_shop_interactable = true

func _on_shop_area_body_exited(body: Node2D) -> void:
	# Disable Shop Interaction Ability :
	if body.name == "Brody" :
		EventBus.clives_shop_interactable = false
