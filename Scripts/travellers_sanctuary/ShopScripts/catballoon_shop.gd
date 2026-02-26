extends Node2D

func _ready() :
	open_balloonist_shop()

# >>>
# Balloonist SHOP (Uniques [Gems & Gold]) :
# >>>
func open_balloonist_shop() :
	# Set Item Prices :
	set_item_prices()
	
	# Update Gold & XP Values :
	%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
	%TotalXPTextCat.text = str(EventBus.player_level)
	
	# Swoop-in Shop :
	check_balloonist_shop_status()
	var bgs = $"."
	
	# Start slightly above and transparent
	bgs.modulate.a = 0.0
	bgs.position.y -= 20
	
	var tb = create_tween().parallel()
	tb.set_parallel(true)
	
	# Fade in
	tb.tween_property(bgs, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	tb.tween_property(bgs, "position:y", bgs.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await tb.finished
	
	await get_tree().create_timer(12.0).timeout
	
		# Fade and slide back up
	var tb2 = create_tween()
	tb2.set_parallel(true)
	
	tb2.tween_property(bgs, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb2.tween_property(bgs, "position:y", bgs.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb2.finished


# > Cat Balloonist :
# >> Outfits :
var gladiator_brody_purchased = false
var liquified_brody_purchased = false
var samurai_brody_purchased = false
# >> Torches :
var walltorch_torch_purchased = false
var wizardstaff_torch_purchased = false
# >> Shields :
var bluevariant_shield_purchased = false
var nurnincrest_shield_purchased = false
var holyeffigee_shield_purchased = false

# Currently Equipped Player Inventory :
var equipped_sidekick
var shield_acquired
var equipped_torch
var equipped_brodyoutfit

func check_balloonist_shop_status() :
	# Outfits :
	if EventBus.gladiator_brody_purchased == true :
		%Outfit1Price.visible = false
		%Outfit1BoughtTick.visible = true
		if EventBus.equipped_brodyoutfit == "gladiator" :
			# Show as Equipped :
			%Outfit1Equipped.visible = true
			%Outfit1Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Outfit1Equipped.visible = false
			%Outfit1Unequipped.visible = true
			
	if EventBus.liquified_brody_purchased == true :
		%Outfit2Price.visible = false
		%Outfit2BoughtTick.visible = true
		if EventBus.equipped_brodyoutfit == "liquified" :
			# Show as Equipped :
			%Outfit2Equipped.visible = true
			%Outfit2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Outfit2Equipped.visible = false
			%Outfit2Unequipped.visible = true
			
	if EventBus.samurai_brody_purchased == true :
		%Outfit3Price.visible = false
		%Outfit3BoughtTick.visible = true
		if EventBus.equipped_brodyoutfit == "samurai" :
			# Show as Equipped :
			%Outfit3Equipped.visible = true
			%Outfit3Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Outfit3Equipped.visible = false
			%Outfit3Unequipped.visible = true
	
	# Shields :
	if EventBus.bluevariant_shield_purchased == true :
		%Shield1Price.visible = false
		%Shield1BoughtTick.visible = true
		if EventBus.shield_acquired == "bluevariant" :
			# Show as Equipped :
			%Shield1Equipped.visible = true
			%Shield1Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Shield1Equipped.visible = false
			%Shield1Unequipped.visible = true
	if EventBus.nurnincrest_shield_purchased == true :
		%Shield2Price.visible = false
		%Shield2BoughtTick.visible = true
		if EventBus.shield_acquired == "nuinencrest" :
			# Show as Equipped :
			%Shield2Equipped.visible = true
			%Shield2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Shield2Equipped.visible = false
			%Shield2Unequipped.visible = true
	if EventBus.holyeffigee_shield_purchased == true :
		%Shield3Price.visible = false
		%Shield3BoughtTick.visible = true
		if EventBus.shield_acquired == "holyeffigee" :
			# Show as Equipped :
			%Shield3Equipped.visible = true
			%Shield3Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Shield3Equipped.visible = false
			%Shield3Unequipped.visible = true
	
	# Torches :
	if EventBus.walltorch_torch_purchased == true :
		%Torch1Price.visible = false
		%Torch1BoughtTick.visible = true
		if EventBus.equipped_torch == "walltorch" :
			# Show as Equipped :
			%Torch1Equipped.visible = true
			%Torch1Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Torch1Equipped.visible = false
			%Torch1Unequipped.visible = true
	if EventBus.wizardstaff_torch_purchased == true :
		%Torch2Price.visible = false
		%Torch2BoughtTick.visible = true
		if EventBus.equipped_torch == "wizardstaff" :
			# Show as Equipped :
			%Torch2Equipped.visible = true
			%Torch2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Torch2Equipped.visible = false
			%Torch2Unequipped.visible = true

# > Cat Balloonist :
# >> Outfits :
#var gladiator_brody_purchased = false
#var liquified_brody_purchased = false
#var samurai_brody_purchased = false
# >> Torches :
#var walltorch_torch_purchased = false
#var wizardstaff_torch_purchased = false
# >> Shields :
#var bluevariant_shield_purchased = false
#var nurnincrest_shield_purchased = false
#var holyeffigee_shield_purchased = false

func set_item_prices() :
	if EventBus.gladiator_brody_purchased == false :
		%CliveItem1Price.text = str(EventBus.mystic_sword_price) + "g"
	if EventBus.winged_torch_purchased == false :
		%CliveItem2Price.text = str(EventBus.winged_torch_price) + "g"


# BUY / EQUIP MYSTIC SWORD :
func _on_balloonist_item_1_button_pressed() -> void:
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
func _on_balloonist_item_2_button_pressed() -> void:
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

func _on_balloonist_item_3_button_pressed() -> void:
	pass # Replace with function body.

# >>>
# GENERAL CLOSE BUTTON :
# >>>
func _on_close_menu_button_pressed() -> void:
	# SHOPS :
	EventBus.save_game()
	EventBus.currently_interacting = false
	%DashButton.visible = true
	%TouchScreenPress2.visible = true
	# > For Clives Shop :
	%CliveShopScreen.visible = false
	var AdventureScreenFade_tween = create_tween()
	AdventureScreenFade_tween.tween_property(%CliveShopScreen, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
