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

# This function adds the gained gold from the duneon to the preexisting player count, but slowly for the sake of the endgame animation :
func animate_gold_gain():
	# Fade in Total Previous Gold text, then after 2 seconds, start adding (change colour, size, move it left and right etc) :
	%TotalGoldText.visible = true
	
	# Previous Gold Number Fade In :
	%TotalGoldText.modulate.a = 0.0
	var fadein_tween = create_tween()
	fadein_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.2).timeout
	# Then Increase Scale of Text, and Turn Green :
	var green_tween = create_tween()
	green_tween.tween_property(%TotalGoldText, "modulate", Color(0.508, 0.99, 0.49, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var scale_tween = create_tween()
	scale_tween.tween_property(%TotalGoldText, "scale", Vector2(6.0, 6.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Gold Addon Animation :
	var start_value = EventBus.total_acquired_goldpieces
	var end_value = start_value + EventBus.total_new_acquired_goldpieces
	var gold_addon_duration = 3.0  # Seconds
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
	descale_tween.tween_property(%TotalGoldText, "scale", Vector2(2.0, 2.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var white_tween = create_tween()
	white_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Update the actual stored value at the end
	tween.finished.connect(func():
		EventBus.total_acquired_goldpieces = end_value)
