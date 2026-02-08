extends Control

func _ready() :
	# Player Spawns in Sanctuary :
	EventBus.last_room_complete.connect(_on_dungeon_ended) 
	EventBus.player_deaded.connect(_on_player_died)
	EventBus.new_crawl.connect(_loading_screen) 
	
	# Shops :
	EventBus.open_clives_shop.connect(open_clives_shop)
	
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
	%TotalXPText.text = str(EventBus.player_level)
	# BEGIN SERIES OF LOOT MENU ANIMATIONS:

func _on_player_died() -> void:
	EventBus.save_game()

	# Fade in the background (if you still want this visual)
	main_background_fadein()

	# Hide gameplay UI
	%TouchScreenLayer.visible = false

	# Skip loot screen entirely:
	%LootScreen.visible = false
	%XPOutlineFlasher.visible = false
	%TotalGoldText.visible = false
	%GainedGoldText.visible = false
	%TotalXPText.visible = false

	# Go straight to the travel menu
	open_adventure_menu()

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
	EventBus.total_acquired_goldpieces = end_value
		
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
	EventBus.total_acquired_experience = new_xp_total
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
	
	%Brody.make_darkness_invisible()
	EventBus.death_played = false
	EventBus.total_current_darkness = 0
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
	%Brody.make_darkness_visible()
	EventBus.death_played = false
	EventBus.total_current_darkness = 0
	EventBus.new_dungeon_crawl()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OPEN SHOPS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# >>>
# CLIVES SHOP (Uniques [Gems & Gold]) :
# >>>
func open_clives_shop() :
	# Set Item Prices :
	set_item_prices()
	
	# Update Gold & XP Values :
	%TotalGoldTextClives.text = str(EventBus.total_acquired_goldpieces)
	%TotalXPTextClives.text = str(EventBus.player_level)
	
	# Fade-IN Adventure Menu :
	%DashButton.visible = false
	%TouchScreenPress2.visible = false
	%Menus.visible = true
	%CliveShopScreen.visible = true
	check_clive_shop_status()
	clive_shop_fadein()
	
	# Animate All The Different Sprites To Move UP/DOWN etc :
	animate_winged_torch()
	animate_mystic_sword()

func check_clive_shop_status() :
	if EventBus.mystic_sword_purchased == true :
		%CliveItem1Price.visible = false
		%Item1BoughtTick.visible = true
		if EventBus.equipped_sidekick == "mystic_sword" :
			# Show as Equipped :
			%Item1Equipped.visible = true
			%Item1Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Item1Equipped.visible = false
			%Item1Unequipped.visible = true
		
	if EventBus.winged_torch_purchased == true :
		%CliveItem2Price.visible = false
		%Item2BoughtTick.visible = true
		if EventBus.equipped_sidekick == "winged_torch" :
			# Show as Equipped :
			%Item2Equipped.visible = true
			%Item2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Item2Equipped.visible = false
			%Item2Unequipped.visible = true

func clive_shop_fadein() :
	%CliveShopScreen.visible = true
	var AdventureScreenFade_tween = create_tween()
	AdventureScreenFade_tween.tween_property(%CliveShopScreen, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_item_prices() :
	if EventBus.mystic_sword_purchased == false :
		%CliveItem1Price.text = str(EventBus.mystic_sword_price) + "g"
	if EventBus.winged_torch_purchased == false :
		%CliveItem2Price.text = str(EventBus.winged_torch_price) + "g"

func animate_winged_torch() :
	if EventBus.winged_torch_purchased == false :
		while %CliveShopScreen.visible == true :
			var MovingWingedTorch_tween = create_tween()
			MovingWingedTorch_tween.tween_property(%WingedTorch, "position", Vector2(14.0, 100.0), 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			# When Moved Up, Move Down :
			await MovingWingedTorch_tween.finished
			replayicon_flash_white()
			var MovingWingedTorchDOWN_tween = create_tween()
			MovingWingedTorchDOWN_tween.tween_property(%WingedTorch, "position", Vector2(14, 103.5), 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await MovingWingedTorchDOWN_tween.finished

func animate_mystic_sword() :
	if EventBus.mystic_sword_purchased == false :
		while %CliveShopScreen.visible == true :
			var MovingMysticFlyingSword_tween = create_tween()
			MovingMysticFlyingSword_tween.tween_property(%MysticFlyingSword, "position", Vector2(16.16, 82.75), 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			# When Moved Up, Move Down :
			await MovingMysticFlyingSword_tween.finished
			replayicon_flash_white()
			var MovingMysticFlyingSwordDOWN_tween = create_tween()
			MovingMysticFlyingSwordDOWN_tween.tween_property(%MysticFlyingSword, "position", Vector2(16.16, 85), 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await MovingMysticFlyingSwordDOWN_tween.finished

# BUY / EQUIP MYSTIC SWORD :
func _on_clive_item_1_button_pressed() -> void:
	if EventBus.mystic_sword_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.mystic_sword_price :
			EventBus.total_acquired_goldpieces -= EventBus.mystic_sword_price
			%TotalGoldTextClives.text = str(EventBus.total_acquired_goldpieces)
			EventBus.mystic_sword_purchased = true
			# Update Look of Item 1 Slot :
			EventBus.equipped_sidekick = "mystic_sword"
			%CliveItem1Price.visible = false
			%Item1BoughtTick.visible = true
			%Item1Equipped.visible = true
			
			# Show Other Sidekick Slots as Unequipped :
			%Item2Equipped.visible = false
			%Item2Unequipped.visible = true
			#%Item3Equipped.visible = false
			#%Item3Unequipped.visible = true
			$"../..".despawn_sidekick()
			$"../..".spawn_mystic_sword()
			
	else :
		if EventBus.equipped_sidekick != "mystic_sword" :
			# Just Equip :
			$"../..".despawn_sidekick()
			$"../..".spawn_mystic_sword()
			EventBus.equipped_sidekick = "mystic_sword"
			%Item1Equipped.visible = true
			%Item1Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			%Item2Equipped.visible = false
			%Item2Unequipped.visible = true
			#%Item3Equipped.visible = false
			#%Item3Unequipped.visible = true
			$"../..".despawn_sidekick()
		else :
			# Unequip :
			$"../..".despawn_sidekick()
			EventBus.equipped_sidekick = "none"
			%Item1Equipped.visible = false
			%Item1Unequipped.visible = true
		

# BUY / EQUIP WINGED TORCH :
func _on_clive_item_2_button_pressed() -> void:
	if EventBus.winged_torch_purchased == false :
		# Purchase & Equip winged_torch
		if EventBus.total_acquired_goldpieces >= EventBus.winged_torch_price:
			EventBus.total_acquired_goldpieces -= EventBus.winged_torch_price
			%TotalGoldTextClives.text = str(EventBus.total_acquired_goldpieces)
			EventBus.winged_torch_purchased = true
			# Update Look of Item 2 Slot :
			EventBus.equipped_sidekick = "winged_torch"
			%CliveItem2Price.visible = false
			%Item2BoughtTick.visible = true
			
			# Show Other Sidekick Slots as Unequipped :
			%Item1Equipped.visible = false
			%Item1Unequipped.visible = true
			#%Item3Equipped.visible = false
			#%Item3Unequipped.visible = true
			$"../..".despawn_sidekick()
			$"../..".spawn_winged_torch()
			
	else :
		if EventBus.equipped_sidekick != "winged_torch" :
			# Just Equip :
			$"../..".despawn_sidekick()
			$"../..".spawn_winged_torch()
			EventBus.equipped_sidekick = "winged_torch"
			%Item2Equipped.visible = true
			%Item2Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			%Item1Equipped.visible = false
			%Item1Unequipped.visible = true
			#%Item3Equipped.visible = false
			#%Item3Unequipped.visible = true
		else :
			# Unequip :
			EventBus.equipped_sidekick = "none"
			%Item2Equipped.visible = false
			%Item2Unequipped.visible = true
			$"../..".despawn_sidekick()

func _on_clive_item_3_button_pressed() -> void:
	pass # Replace with function body.

# >>>
# GENERAL CLOSE BUTTON :
# >>>
func _on_close_menu_button_pressed() -> void:
	# SHOPS :
	EventBus.save_game()
	%DashButton.visible = true
	%TouchScreenPress2.visible = true
	# > For Clives Shop :
	%CliveShopScreen.visible = false
	var AdventureScreenFade_tween = create_tween()
	AdventureScreenFade_tween.tween_property(%CliveShopScreen, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


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
