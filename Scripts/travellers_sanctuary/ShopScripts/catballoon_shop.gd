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


func check_balloonist_shop_status() :
	# Outfits :
	if EventBus.gladiator_brody_purchased == true :
		%Outfit1Price.visible = false
		#%Outfit1BoughtTick.visible = true
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
		#%Outfit2BoughtTick.visible = true
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
		#%Outfit3BoughtTick.visible = true
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
		#%Shield1BoughtTick.visible = true
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
		#%Shield2BoughtTick.visible = true
		if EventBus.shield_acquired == "nurnincrest" :
			# Show as Equipped :
			%Shield2Equipped.visible = true
			%Shield2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Shield2Equipped.visible = false
			%Shield2Unequipped.visible = true
	if EventBus.holyeffigee_shield_purchased == true :
		%Shield3Price.visible = false
		#%Shield3BoughtTick.visible = true
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
		#%Torch1BoughtTick.visible = true
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
		#%Torch2BoughtTick.visible = true
		if EventBus.equipped_torch == "wizardstaff" :
			# Show as Equipped :
			%Torch2Equipped.visible = true
			%Torch2Unequipped.visible = false
		else :
			# Show as Unequipped :
			%Torch2Equipped.visible = false
			%Torch2Unequipped.visible = true


func set_item_prices() :
	if EventBus.gladiator_brody_purchased == false :
		%Outfit1Price.text = str(EventBus.gladiator_outfit_price) + "g"
	if EventBus.liquified_brody_purchased == false :
		%Outfit2Price.text = str(EventBus.liquified_outfit_price) + "g"
	if EventBus.samurai_brody_purchased == false :
		%Outfit3Price.text = str(EventBus.samurai_outfit_price) + "g"
		
	if EventBus.walltorch_torch_purchased == false :
		%Torch1Price.text = str(EventBus.walltorch_torch_price) + "g"
	if EventBus.wizardstaff_torch_purchased == false :
		%Torch2Price.text = str(EventBus.wizardstaff_torch_price) + "g"
		
	if EventBus.bluevariant_shield_purchased == false :
		%Shield1Price.text = str(EventBus.bluevariant_shield_price) + "g"
	if EventBus.nurnincrest_shield_purchased == false :
		%Shield2Price.text = str(EventBus.nurnincrest_shield_price) + "g"
	if EventBus.holyeffigee_shield_purchased == false :
		%Shield3Price.text = str(EventBus.holyeffigee_shield_price) + "g"


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
			#%Item1BoughtTick.visible = true
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


# >>>
# GENERAL CLOSE BUTTON :
# >>>
func _on_close_menu_button_pressed() -> void:
	# SHOPS :
	$"../..".shop_closed()
	# > For Clives Shop :
			# Fade and slide back up
	var bgs = $"."
	
	# Start slightly above and transparent
	bgs.modulate.a = 0.0
	bgs.position.y -= 20
	
	var tb2 = create_tween()
	tb2.set_parallel(true)
	
	tb2.tween_property(bgs, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb2.tween_property(bgs, "position:y", bgs.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb2.finished
	queue_free()

# ------------------------------------------------------------------------------
# BUTTONS :
# ------------------------------------------------------------------------------

# Outfits :
func _on_outfit_1_button_pressed() -> void: # Gladiator :
	if EventBus.gladiator_brody_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.gladiator_outfit_price :
			EventBus.total_acquired_goldpieces -= EventBus.gladiator_outfit_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.gladiator_brody_purchased = true
			# Update Look of Item Slot :
			EventBus.equipped_brodyoutfit = "gladiator"
			%Outfit1Price.visible = false
			#%Outfit1BoughtTick.visible = true
			%Outfit1Equipped.visible = true
			
			# Show Other Outfit Slots as Unequipped :
			if EventBus.liquified_brody_purchased == true :
				%Outfit2Equipped.visible = false
				%Outfit2Unequipped.visible = true
			if EventBus.samurai_brody_purchased == true :
				%Outfit3Equipped.visible = false
				%Outfit3Unequipped.visible = true
			$"../..".change_outfit()
			
	else :
		if EventBus.equipped_brodyoutfit != "gladiator" :
			# Just Equip :
			EventBus.equipped_brodyoutfit = "gladiator"
			%Outfit1Equipped.visible = true
			%Outfit1Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.liquified_brody_purchased == true :
				%Outfit2Equipped.visible = false
				%Outfit2Unequipped.visible = true
			if EventBus.samurai_brody_purchased == true :
				%Outfit3Equipped.visible = false
				%Outfit3Unequipped.visible = true
			$"../..".change_outfit()
		else :
			# Unequip :
			EventBus.equipped_brodyoutfit = "none"
			%Outfit1Equipped.visible = false
			%Outfit1Unequipped.visible = true
			$"../..".change_outfit()


func _on_outfit_2_button_pressed() -> void: # Liquified :
	if EventBus.liquified_brody_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.liquified_outfit_price :
			EventBus.total_acquired_goldpieces -= EventBus.liquified_outfit_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.liquified_brody_purchased = true
			# Update Look of Item Slot :
			EventBus.equipped_brodyoutfit = "liquified"
			%Outfit2Price.visible = false
			#%Outfit2BoughtTick.visible = true
			%Outfit2Equipped.visible = true
			
			# Show Other Outfit Slots as Unequipped :
			if EventBus.gladiator_brody_purchased == true :
				%Outfit1Equipped.visible = false
				%Outfit1Unequipped.visible = true
			if EventBus.samurai_brody_purchased == true :
				%Outfit3Equipped.visible = false
				%Outfit3Unequipped.visible = true
			$"../..".change_outfit()
			
	else :
		if EventBus.equipped_brodyoutfit != "liquified" :
			# Just Equip :
			EventBus.equipped_brodyoutfit = "liquified"
			%Outfit2Equipped.visible = true
			%Outfit2Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.gladiator_brody_purchased == true :
				%Outfit1Equipped.visible = false
				%Outfit1Unequipped.visible = true
			if EventBus.samurai_brody_purchased == true :
				%Outfit3Equipped.visible = false
				%Outfit3Unequipped.visible = true
			$"../..".change_outfit()
		else :
			# Unequip :
			EventBus.equipped_brodyoutfit = "none"
			%Outfit2Equipped.visible = false
			%Outfit2Unequipped.visible = true
			$"../..".change_outfit()


func _on_outfit_3_button_pressed() -> void: # Samurai :
	if EventBus.samurai_brody_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.samurai_outfit_price :
			EventBus.total_acquired_goldpieces -= EventBus.samurai_outfit_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.samurai_brody_purchased = true
			# Update Look of Item Slot :
			EventBus.equipped_brodyoutfit = "samurai"
			%Outfit3Price.visible = false
			#%Outfit3BoughtTick.visible = true
			%Outfit3Equipped.visible = true
			
			# Show Other Outfit Slots as Unequipped :
			if EventBus.gladiator_brody_purchased == true :
				%Outfit1Equipped.visible = false
				%Outfit1Unequipped.visible = true
			if EventBus.liquified_brody_purchased == true :
				%Outfit2Equipped.visible = false
				%Outfit2Unequipped.visible = true
			$"../..".change_outfit()
			
	else :
		if EventBus.equipped_brodyoutfit != "samurai" :
			# Just Equip :
			EventBus.equipped_brodyoutfit = "samurai"
			%Outfit3Equipped.visible = true
			%Outfit3Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.gladiator_brody_purchased == true :
				%Outfit1Equipped.visible = false
				%Outfit1Unequipped.visible = true
			if EventBus.liquified_brody_purchased == true :
				%Outfit2Equipped.visible = false
				%Outfit2Unequipped.visible = true
			$"../..".change_outfit()
		else :
			# Unequip :
			EventBus.equipped_brodyoutfit = "none"
			%Outfit3Equipped.visible = false
			%Outfit3Unequipped.visible = true
			$"../..".change_outfit()


# Shield :
func _on_shield_1_button_pressed() -> void: # BlueVariant :
	if EventBus.bluevariant_shield_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.bluevariant_shield_price :
			EventBus.total_acquired_goldpieces -= EventBus.bluevariant_shield_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.bluevariant_shield_purchased = true
			# Update Look of Item Slot :
			EventBus.shield_acquired = "bluevariant"
			%Shield1Price.visible = false
			#%Shield1BoughtTick.visible = true
			%Shield1Equipped.visible = true
			
			# Show Other Shield Slots as Unequipped :
			if EventBus.holyeffigee_shield_purchased == true :
				%Shield3Equipped.visible = false
				%Shield3Unequipped.visible = true
			if EventBus.nurnincrest_shield_purchased == true :
				%Shield2Equipped.visible = false
				%Shield2Unequipped.visible = true
			$"../..".change_shield()
			
	else :
		if EventBus.shield_acquired != "bluevariant" :
			# Just Equip :
			EventBus.shield_acquired = "bluevariant"
			%Shield1Equipped.visible = true
			%Shield1Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.holyeffigee_shield_purchased == true :
				%Shield3Equipped.visible = false
				%Shield3Unequipped.visible = true
			if EventBus.nurnincrest_shield_purchased == true :
				%Shield2Equipped.visible = false
				%Shield2Unequipped.visible = true
			$"../..".change_shield()
		else :
			# Unequip :
			EventBus.shield_acquired = "default"
			%Shield1Equipped.visible = false
			%Shield1Unequipped.visible = true
			$"../..".change_shield()


func _on_shield_2_button_pressed() -> void: # NurnenCrest :
	if EventBus.nurnincrest_shield_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.nurnincrest_shield_price :
			EventBus.total_acquired_goldpieces -= EventBus.nurnincrest_shield_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.nurnincrest_shield_purchased = true
			# Update Look of Item Slot :
			EventBus.shield_acquired = "nurnincrest"
			%Shield2Price.visible = false
			#%Shield2BoughtTick.visible = true
			%Shield2Equipped.visible = true
			
			# Show Other Shield Slots as Unequipped :
			if EventBus.holyeffigee_shield_purchased == true :
				%Shield3Equipped.visible = false
				%Shield3Unequipped.visible = true
			if EventBus.bluevariant_shield_purchased == true :
				%Shield1Equipped.visible = false
				%Shield1Unequipped.visible = true
			$"../..".change_shield()
			
	else :
		if EventBus.shield_acquired != "nurnincrest" :
			# Just Equip :
			EventBus.shield_acquired = "nurnincrest"
			%Shield2Equipped.visible = true
			%Shield2Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.holyeffigee_shield_purchased == true :
				%Shield3Equipped.visible = false
				%Shield3Unequipped.visible = true
			if EventBus.bluevariant_shield_purchased == true :
				%Shield1Equipped.visible = false
				%Shield1Unequipped.visible = true
			$"../..".change_shield()
		else :
			# Unequip :
			EventBus.shield_acquired = "default"
			%Shield2Equipped.visible = false
			%Shield2Unequipped.visible = true
			$"../..".change_shield()


func _on_shield_3_button_pressed() -> void: # Holyeffigee
	if EventBus.holyeffigee_shield_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.holyeffigee_shield_price :
			EventBus.total_acquired_goldpieces -= EventBus.holyeffigee_shield_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.holyeffigee_shield_purchased = true
			# Update Look of Item Slot :
			EventBus.shield_acquired = "holyeffigee"
			%Shield3Price.visible = false
			#%Shield3BoughtTick.visible = true
			%Shield3Equipped.visible = true
			
			# Show Other Shield Slots as Unequipped :
			if EventBus.bluevariant_shield_purchased == true :
				%Shield1Equipped.visible = false
				%Shield1Unequipped.visible = true
			if EventBus.nurnincrest_shield_purchased == true :
				%Shield2Equipped.visible = false
				%Shield2Unequipped.visible = true
			$"../..".change_shield()
			
	else :
		if EventBus.shield_acquired != "holyeffigee" :
			# Just Equip :
			EventBus.shield_acquired = "holyeffigee"
			%Shield3Equipped.visible = true
			%Shield3Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			if EventBus.bluevariant_shield_purchased == true :
				%Shield1Equipped.visible = false
				%Shield1Unequipped.visible = true
			if EventBus.nurnincrest_shield_purchased == true :
				%Shield2Equipped.visible = false
				%Shield2Unequipped.visible = true
			$"../..".change_shield()
		else :
			# Unequip :
			EventBus.shield_acquired = "default"
			%Shield3Equipped.visible = false
			%Shield3Unequipped.visible = true
			$"../..".change_shield()


# Torches
func _on_torch_1_button_pressed() -> void: # Walltorch Skin
	if EventBus.walltorch_torch_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.walltorch_torch_price :
			EventBus.total_acquired_goldpieces -= EventBus.walltorch_torch_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.walltorch_torch_purchased = true
			# Update Look of Item Slot :
			EventBus.equipped_torch = "walltorch"
			%Torch1Price.visible = false
			#%Torch1BoughtTick.visible = true
			%Torch1Equipped.visible = true
			
			# Show Other Torch Slots as Unequipped :
			#%Torch3Equipped.visible = false
			#%Torch3Unequipped.visible = true
			if EventBus.wizardstaff_torch_purchased == true :
				%Torch2Equipped.visible = false
				%Torch2Unequipped.visible = true
			$"../..".change_torch()
			
	else :
		if EventBus.equipped_torch != "walltorch" :
			# Just Equip :
			EventBus.equipped_torch = "walltorch"
			%Torch1Equipped.visible = true
			%Torch1Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			#%Torch3Equipped.visible = false
			#%Torch3Unequipped.visible = true
			if EventBus.wizardstaff_torch_purchased == true :
				%Torch2Equipped.visible = false
				%Torch2Unequipped.visible = true
			$"../..".change_torch()
		else :
			# Unequip :
			EventBus.equipped_torch = "none"
			%Torch1Equipped.visible = false
			%Torch1Unequipped.visible = true
			$"../..".change_torch()


func _on_torch_2_button_pressed() -> void: # Wizards Staff
	if EventBus.wizardstaff_torch_purchased == false :
		# Purchase & Equip mystic_sword
		if EventBus.total_acquired_goldpieces >= EventBus.wizardstaff_torch_price :
			EventBus.total_acquired_goldpieces -= EventBus.wizardstaff_torch_price
			%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
			EventBus.wizardstaff_torch_purchased = true
			# Update Look of Item Slot :
			EventBus.equipped_torch = "wizardstaff"
			%Torch2Price.visible = false
			#%Torch2BoughtTick.visible = true
			%Torch2Equipped.visible = true
			
			# Show Other Torch Slots as Unequipped :
			#%Torch3Equipped.visible = false
			#%Torch3Unequipped.visible = true
			if EventBus.walltorch_torch_purchased == true :
				%Torch1Equipped.visible = false
				%Torch1Unequipped.visible = true
			$"../..".change_torch()
			
	else :
		if EventBus.equipped_torch != "wizardstaff" :
			# Just Equip :
			EventBus.equipped_torch = "wizardstaff"
			%Torch2Equipped.visible = true
			%Torch2Unequipped.visible = false
			
			# Show Other Sidekick Slots as Unequipped :
			#%Torch3Equipped.visible = false
			#%Torch3Unequipped.visible = true
			if EventBus.walltorch_torch_purchased == true :
				%Torch1Equipped.visible = false
				%Torch1Unequipped.visible = true
			$"../..".change_torch()
		else :
			# Unequip :
			EventBus.equipped_torch = "none"
			%Torch2Equipped.visible = false
			%Torch2Unequipped.visible = true
			$"../..".change_torch()


func _on_torch_3_button_pressed() -> void:
	pass # Replace with function body.
