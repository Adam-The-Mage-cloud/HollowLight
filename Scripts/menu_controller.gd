extends Control

func _ready() :
	# Player Spawns in Sanctuary :
	EventBus.last_room_complete.connect(_on_dungeon_ended) # REMOVE THIS WHEN IT'S READY
	_on_dungeon_ended()
	pass

func _on_dungeon_ended() :
	# Fade in End of Dungeon Menu :
	%EndOfDungeonMenu.visible = true
	# Display The Initial Previous Gold Count pre-encounter :
	%TotalGoldText.text = str(EventBus.total_acquired_goldpieces)
	# Animated the newly gained gold
	animate_gold_gain()
	%TotalXPText.visible = true
	%XPProgressBar.visible = true
	%XPProgressBar.visible = true

# This function adds the gained gold from the duneon to the preexisting player count, but slowly for the sake of the endgame animation :
func animate_gold_gain():
	# Fade in Total Previous Gold text, then after 2 seconds, start adding (change colour, size, move it left and right etc) :
	%TotalGoldText.visible = true
	
	# Previous Gold Number Fade In :
	%TotalGoldText.modulate.a = 0.0
	var fadein_tween = create_tween()
	fadein_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.6).timeout
	# Then Increase Scale of Text, and Turn Green :
	var green_tween = create_tween()
	green_tween.tween_property(%TotalGoldText, "modulate", Color(0.508, 0.99, 0.49, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var scale_tween = create_tween()
	scale_tween.tween_property(%TotalGoldText, "scale", Vector2(1.5, 1.5), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Gold Addon Animation :
	var start_value = EventBus.total_acquired_goldpieces
	var end_value = start_value + EventBus.total_new_acquired_goldpieces
	var gold_addon_duration = 2.0  # Seconds
	var tween = create_tween()
	tween.tween_method(
		func(value):
			%TotalGoldText.text = str(value),
		start_value,
		end_value,
		gold_addon_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(gold_addon_duration).timeout
	var descale_tween = create_tween()
	descale_tween.tween_property(%TotalGoldText, "scale", Vector2(0.75, 0.75), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var white_tween = create_tween()
	white_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Update the actual stored value at the end
	tween.finished.connect(func():
		EventBus.total_acquired_goldpieces = end_value)
		
	await get_tree().create_timer(1.0).timeout
	# When That Sequence is Finished, BEGIN XP ANIMATION :
	animate_xp_gain() 


func animate_xp_gain():
	var xp_to_add = 340  # placeholder
	EventBus.total_new_acquired_experience += xp_to_add
	
	var current_xp = EventBus.total_acquired_experience
	var new_xp_total = current_xp + EventBus.total_new_acquired_experience
	
	# Loop while we overflow past 100
	while new_xp_total >= 100:
		#var xp_needed = 100 - current_xp
		
		# Tween to 100 (level-up) :
		await tween_xp_bar(current_xp, 100)
		
		# Player Level Up :
		EventBus.player_level += 1
		%TotalXPText.text = str(EventBus.player_level)
		level_up_flashes()
		
		# Remove the 100 XP and then reset the bar :
		new_xp_total -= 100
		current_xp = 0
		%XPProgressBar.value = 0
		
	# Final tween for leftover XP (where the bar isn't fully filled) :
	await tween_xp_bar(current_xp, new_xp_total)
	
	# Update Stored XP
	EventBus.total_acquired_experience = new_xp_total
	EventBus.total_new_acquired_experience = 0


func tween_xp_bar(from_value: float, to_value: float) -> void:
	# Pre-Progress White Bar :
	%XPProgressBarHighlight.value = from_value
	var white_tween = create_tween()
	white_tween.tween_property(%XPProgressBarHighlight, "value", to_value, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await white_tween.finished
	
	# Actual Progress Bar
	%XPProgressBar.value = from_value
	var mainGain_tween = create_tween()
	mainGain_tween.tween_property(%XPProgressBar, "value", to_value, 1.05)
	await mainGain_tween.finished


# Helps Showcase Each Time A Level Up Occurs :
func level_up_flashes() :
	# Increase Font Scale :
	var XPFontScaler_tween = create_tween()
	XPFontScaler_tween.tween_property(%TotalXPText, "scale", Vector2(0.6, 0.6), 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var XPTextLevel_tween = create_tween()
	XPTextLevel_tween.tween_property(%TotalXPText.material, "shader_parameter/flash_amount", 1.0, 0.05)
	XPTextLevel_tween.tween_property(%TotalXPText.material, "shader_parameter/flash_amount", 0.0, 0.1)

	var XPProgressBar_tween = create_tween()
	XPProgressBar_tween.tween_property(%XPProgressBar.material, "shader_parameter/flash_amount", 1.0, 0.05)
	XPProgressBar_tween.tween_property(%XPProgressBar.material, "shader_parameter/flash_amount", 0.0, 0.1)
	
	# Decrease Font Scale :
	XPFontScaler_tween.tween_property(%TotalXPText, "scale", Vector2(0.53, 0.53), 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
