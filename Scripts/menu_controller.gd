extends Control

func _ready() :
	# Player Spawns in Sanctuary :
	EventBus.last_room_complete.connect(_on_dungeon_ended) 
	EventBus.new_crawl.connect(_loading_screen) 
	# REMOVE THIS WHEN IT'S READY :
	#_on_dungeon_ended()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LOOT SCREEN AFTER DUNGEON :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_dungeon_ended() :
	EventBus.save_game()
	# Fade in Menu Background :
	main_background_fadein()
	# Fade in End of Dungeon Menu :
	loot_menu_fadein()
	%EndOfDungeonMenu.visible = true
	# Display The Initial Previous Gold Count pre-encounter and 0 for the newly acquired goldpieces :
	%TotalGoldText.text = str(EventBus.total_acquired_goldpieces)
	%GainedGoldText.text = str(0)
	# BEGIN SERIES OF LOOT MENU ANIMATIONS:


func loot_menu_fadein() :
	%LootScreen.visible = true
	var LootScreenFade_tween = create_tween()
	LootScreenFade_tween.tween_property(%LootScreen, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await LootScreenFade_tween.finished
	%XPOutlineFlasher.visible = true
	animate_gold_gain()


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
	print (start_value)
	var end_value = start_value + EventBus.total_new_acquired_goldpieces
	var gold_addon_duration = 2.0  # Seconds
	var gold_addon_tween = create_tween()
	gold_addon_tween.tween_method(
		func(value):
			%TotalGoldText.text = str(value),
		start_value,
		end_value,
		gold_addon_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var gained_gold_tween = create_tween()
	gained_gold_tween.tween_method(
		func(value):
			%GainedGoldText.text = "+" + str(value),
		0,
		EventBus.total_new_acquired_goldpieces,
		gold_addon_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(gold_addon_duration).timeout
	var descale_tween = create_tween()
	descale_tween.tween_property(%TotalGoldText, "scale", Vector2(0.75, 0.75), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var white_tween = create_tween()
	white_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# ADDUP END GOLDPIECES
	EventBus.total_acquired_goldpieces += end_value
		
	await get_tree().create_timer(1.0).timeout
	# When That Sequence is Finished, BEGIN XP ANIMATION :
	animate_xp_gain() 


func animate_xp_gain():
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
	EventBus.total_acquired_experience += new_xp_total
	EventBus.total_new_acquired_experience = 0
	
	# Signal for EventBus to begin the next menu (buttons!) :
	await get_tree().create_timer(0.8).timeout
	fade_lootscreen()
	EventBus.open_the_travel_menu()


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
	XPProgressBar_tween.tween_property(%XPOutlineFlasher.material, "shader_parameter/flash_amount", 1.0, 0.05)
	XPProgressBar_tween.tween_property(%XPOutlineFlasher.material, "shader_parameter/flash_amount", 0.0, 0.1)
	
	# Decrease Font Scale :
	XPFontScaler_tween.tween_property(%TotalXPText, "scale", Vector2(0.53, 0.53), 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func fade_lootscreen() :
	%XPOutlineFlasher.visible = false
	var LootScreenFade_tween = create_tween()
	LootScreenFade_tween.tween_property(%LootScreen, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Open Adventure Menu! :
	open_adventure_menu()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OPEN ADVENTURE Menu AND ITS ANIMATIONS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func open_adventure_menu() :
	# Fade-IN Adventure Menu :
	%EndOfDungeonMenu.visible = true
	adventure_menu_fadein()
	
	# Animate All The Different Sprites To Move UP/DOWN etc :
	animate_playertorch() 
	animated_homearrow()
	animated_homeletter()

func adventure_menu_fadein() :
	%AdventureScreen.visible = true
	var AdventureScreenFade_tween = create_tween()
	AdventureScreenFade_tween.tween_property(%AdventureScreen, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func animate_playertorch() :
	while %AdventureScreen.visible == true :
		var MovingPlayerTorch_tween = create_tween()
		MovingPlayerTorch_tween.tween_property(%MovingPlayerTorch, "position", Vector2(274.5, 97.0), 0.75).set_trans(Tween.TRANS_LINEAR)
		# When Moved Up, Move Down :
		await MovingPlayerTorch_tween.finished
		replayicon_flash_white()
		var MovingPlayerTorchDOWN_tween = create_tween()
		MovingPlayerTorchDOWN_tween.tween_property(%MovingPlayerTorch, "position", Vector2(274.5, 145.0), 2.25).set_trans(Tween.TRANS_LINEAR)
		await MovingPlayerTorchDOWN_tween.finished

func animated_homearrow() :
	while %AdventureScreen.visible == true :
		var HomeArrow_tween = create_tween()
		HomeArrow_tween.tween_property(%HomeArrow, "position", Vector2(130.5, 91.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# When Moved Up, Move Down :
		await HomeArrow_tween.finished
		var HomeArrowDOWN_tween = create_tween()
		HomeArrowDOWN_tween.tween_property(%HomeArrow, "position", Vector2(130.5, 110.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await HomeArrowDOWN_tween.finished

func animated_homeletter() :
	while %AdventureScreen.visible == true :
		var HomeLetter_tween = create_tween()
		HomeLetter_tween.tween_property(%HomeH, "position", Vector2(130.5, 56.0), 2.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# When Moved Up, Move Down :
		await HomeLetter_tween.finished
		var HomeLetterDOWN_tween = create_tween()
		HomeLetterDOWN_tween.tween_property(%HomeH, "position", Vector2(130.5, 60.0), 2.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await HomeLetterDOWN_tween.finished

func replayicon_flash_white() :
	var icon_flash = create_tween()
	icon_flash.tween_property(%ReplayIcon.material, "shader_parameter/flash_amount", 1.0, 0.05)
	icon_flash.tween_property(%ReplayIcon.material, "shader_parameter/flash_amount", 0.0, 0.1)
	# and spin 90 degrees :
	var icon_spin = create_tween()
	icon_spin.parallel().tween_property(%ReplayIcon, "rotation_degrees", rotation_degrees + 90, 1.2).as_relative()
	icon_spin.parallel().tween_property(%ReplayLog, "rotation_degrees", rotation_degrees + 90, 1.2).as_relative()
	# Play a woody particle drop off effect :
	%WoodSplinterParticles.emitting = true

func adventure_menu_fadeout() :
	var AdventureScreenFade_tween = create_tween()
	AdventureScreenFade_tween.tween_property(%AdventureScreen, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await AdventureScreenFade_tween.finished
	%AdventureScreen.visible = false

func _on_sanctuary_button_pressed() -> void:
	# Highlight in Yellow All Assets on That Side Then Fade :
	%HomeH.play("highlighted")
	%HomeArrow.play("highlighted")
	%AdventureMenuTent.play("highlighted")
	# Fade Out :
	adventure_menu_fadeout()
	main_background_fadeout()
	# Go To Sanctuary :
	await get_tree().create_timer(0.25).timeout
	%HomeH.play("default")
	%HomeArrow.play("default")
	%AdventureMenuTent.play("default")
	
	EventBus.spawn_the_sanctuary()

func _on_replay_dungeon_button_pressed() -> void:
	# Highlight in Yellow All Assets on That Side :
	%ReplayIcon.play("highlighted")
	%MovingPlayerTorch.play("highlighted")
	%Axes.play("highlighted")
	%ReplayLog.play("highlighted")
	# Fade Out :
	adventure_menu_fadeout()
	main_background_fadeout()
	# Begin New Dungeon :
	await get_tree().create_timer(0.25).timeout
	%ReplayIcon.play("default")
	%MovingPlayerTorch.play("default")
	%Axes.play("default")
	%ReplayLog.play("default")
	
	await get_tree().create_timer(0.6).timeout
	EventBus.new_dungeon_crawl()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# General Menu Fade Away :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func main_background_fadein() :
	%Menus.visible = true
	var MainMenuBackgroundFadeIn_tween = create_tween()
	MainMenuBackgroundFadeIn_tween.parallel().tween_property(%EndOfDungeonMenu, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	MainMenuBackgroundFadeIn_tween.parallel().tween_property(%SpaceBackground, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await MainMenuBackgroundFadeIn_tween.finished

func main_background_fadeout() :
	var MainMenuBackgroundFadeOut_tween = create_tween()
	MainMenuBackgroundFadeOut_tween.parallel().tween_property(%EndOfDungeonMenu, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	MainMenuBackgroundFadeOut_tween.parallel().tween_property(%SpaceBackground, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await MainMenuBackgroundFadeOut_tween.finished
	%Menus.visible = false

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Loading Screen :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _loading_screen() :
	pass
