extends Node2D

func _ready() :
	open_jackies_shop()
	set_upgrades_status_and_price()

# >>>
# Balloonist SHOP (Uniques [Gems & Gold]) :
# >>>
func open_jackies_shop() :
	# Update Gold & XP Values :
	%TotalGoldTextCat.text = str(EventBus.total_acquired_goldpieces)
	%TotalXPTextCat.text = str(EventBus.player_level)
	
	# Swoop-in Shop :
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


func set_upgrades_status_and_price() :
	# Work out what the prices and green highlights should be for each upgrade :
	var upgraded_counter = 0
	for i in range(EventBus.amount_dash_timing_upgraded) :
		upgraded_counter += 1
		get_node("DashTimingSkillup"+ str(upgraded_counter))
		EventBus.dash_timing_upgrade_price *= 2
		if upgraded_counter == 6 :
			%DashTimingPrice.visible = false
			%DashTimingButton.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_max_stamina_upgraded) :
		upgraded_counter += 1
		get_node("TorchMaxStaminaSkillup"+ str(upgraded_counter))
		EventBus.torch_max_stamina_upgrade_price *= 2
		if upgraded_counter == 6 :
			%TorchMaxStaminaPrice.visible = false
			%TorchStaminaButton.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_torch_recovery_upgraded) :
		upgraded_counter += 1
		get_node("TorchRecoverySkillup"+ str(upgraded_counter))
		EventBus.torch_recovery_upgrade_price *= 2
		if upgraded_counter == 6 :
			%SwipeRecoveryButton.visible = false
			%TorchStaminaRecoveryPrice.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_fortify_darkness_upgraded) :
		upgraded_counter += 1
		get_node("FortifyDarknessSkillup"+ str(upgraded_counter))
		EventBus.amount_fortify_darkness_upgraded *= 2
		if upgraded_counter == 6 :
			%FortifyDarknessPrice.visible = false
			%FortitudeButton.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_shield_stamina_upgraded) :
		upgraded_counter += 1
		get_node("ShieldStaminaSkillup"+ str(upgraded_counter))
		EventBus.shield_stamina_upgrade_price *= 2
		if upgraded_counter == 6 :
			%ShieldStaminaPrice.visible = false
			%ShieldStaminaButton.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_shield_speed_upgraded) :
		upgraded_counter += 1
		get_node("ShieldSpeedSkillup"+ str(upgraded_counter))
		EventBus.shield_speed_upgrade_price *= 2
		if upgraded_counter == 6 :
			%ShieldSpeedPrice.visible = false
			%ShieldSpeedButton.visible = false
	upgraded_counter = 0
	for i in range(EventBus.amount_lootchance_upgraded) :
		upgraded_counter += 1
		get_node("LootChanceSkillup"+ str(upgraded_counter))
		EventBus.loot_chance_upgrade_price *= 2
		if upgraded_counter == 6 :
			%IncreaseLootPrice.visible = false
			%LootChanceButton.visible = false
	
	# And then lets now set those prices :
	%DashTimingPrice.value = EventBus.amount_dash_timing_upgraded
	%TorchMaxStaminaPrice.value = EventBus.amount_max_stamina_upgraded
	%TorchRecovery.value = EventBus.amount_torch_recovery_upgraded
	%FortifyDarknessPrice.value = EventBus.amount_fortify_darkness_upgraded
	%ShieldStaminaPrice.value = EventBus.amount_shield_stamina_upgraded
	%ShieldSpeedPrice.value = EventBus.amount_shield_speed_upgraded
	%IncreaseLootPrice.value = EventBus.amount_lootchance_upgraded


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


func _on_dash_timing_button_pressed() -> void:
	if EventBus.amount_dash_timing_upgraded < 6 :
		EventBus.amount_dash_timing_upgraded += 1
		set_upgrades_status_and_price()


func _on_torch_stamina_button_pressed() -> void:
	if EventBus.amount_max_stamina_upgraded < 6 :
		EventBus.amount_max_stamina_upgraded += 1
		set_upgrades_status_and_price()


func _on_swipe_recovery_button_pressed() -> void:
	if EventBus.amount_torch_recovery_upgraded < 6 :
		EventBus.amount_torch_recovery_upgraded += 1
		set_upgrades_status_and_price()


func _on_fortitude_button_pressed() -> void:
	if EventBus.amount_fortify_darkness_upgraded < 6 :
		EventBus.amount_fortify_darkness_upgraded += 1
		set_upgrades_status_and_price()


func _on_shield_stamina_button_pressed() -> void:
	if EventBus.amount_shield_stamina_upgraded < 6 :
		EventBus.amount_shield_stamina_upgraded += 1
		set_upgrades_status_and_price()


func _on_shield_speed_button_pressed() -> void:
	if EventBus.amount_shield_speed_upgraded < 6 :
		EventBus.amount_shield_speed_upgraded += 1
		set_upgrades_status_and_price()


func _on_loot_chance_button_pressed() -> void:
	if EventBus.amount_lootchance_upgraded < 6 :
		EventBus.amount_lootchance_upgraded += 1
		set_upgrades_status_and_price()
