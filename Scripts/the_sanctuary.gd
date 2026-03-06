extends Node2D

var raid_happened = false
var orble_spawned = false

func _ready() :
	randomize()
	EventBus.save_game()
	EventBus.sanctuary = true
	EventBus.total_current_darkness = 0
	# Resize Max Orble Potential and Calculate Any Room We Have For More :
	EventBus.orbles.resize(EventBus.max_orble_count)
	for i in range(EventBus.orbles.size()):
		if EventBus.orbles[i] == null:
			EventBus.orbles[i] = ""
	%StewPotSpit.alight_flame()
	%SanctuaryMainFloor.add_to_group("floors")
	arrows_pointing()
	wagon_signs_pointing()
	tutorial_replay_floating()
	turn_stewpot_spit()
	spawn_already_orbles()
	process_hourly_updates()
	spawn_stew_indicator()
	
	if EventBus.intro == true :
		play_sanctuary_tutorial()
	
	if EventBus.orbles_to_introduce > 0 :
		introduce_orbles()


func spawn_already_orbles() :
	for i in range(EventBus.max_orble_count) :
		if EventBus.orbles[i] != null and EventBus.orbles[i] != "" :
			EventBus.total_orbles += 1
			var new_orble = preload("res://Scenes/travellers_sanctuary/OrbleVillage/orble.tscn").instantiate()
			new_orble.name_visible(EventBus.orbles[i])
			new_orble.global_position = Vector2(0,42) + %sanctuary_ritual_site.position #+ Vector2(randi_range(-20, 10), randi_range(40, 50))
			print (global_position)
			print (new_orble.global_position)
			call_deferred("add_child", new_orble)
	while EventBus.total_orbles < 2 :
		EventBus.orbles_to_introduce += 1
		EventBus.total_orbles += 1
		orble_spawned = false
		introduce_orbles()


func introduce_orbles() :
	if orble_spawned == false and EventBus.intro == false :
		orble_spawned = true
		var new_orble = preload("res://Scenes/travellers_sanctuary/OrbleVillage/orble.tscn").instantiate()
		call_deferred("add_child", new_orble)
		# Start naming process
		get_tree().current_scene.introduce_orble(new_orble)
		EventBus.orbles_to_introduce -= 1
		# Wait until the popup emits "orble_named"
		await new_orble.orble_named
		orble_spawned = false
		if EventBus.orbles_to_introduce > 0 or EventBus.total_orbles < 2 :
			await get_tree().create_timer(1.0).timeout
			introduce_orbles()


func turn_stewpot_spit() :
	%StewPotSpit.type = 2
	%StewPotSpit.chosen_skin_number = 3
	%StewPotSpit._ready()

func spawn_stew_indicator() :
	var stew_indicator = preload("res://Scenes/travellers_sanctuary/OrbleVillage/hunger_indicator.tscn").instantiate()
	get_tree().current_scene.call_deferred("add_child", stew_indicator)

func process_hourly_updates():
	var now = Time.get_unix_time_from_system()
	
	if EventBus.last_hourly_food_update == 0:
		EventBus.last_hourly_food_update = now
		return
	
	var seconds_passed = now - EventBus.last_hourly_food_update
	var hours_passed = int(seconds_passed / 3600)
	
	if hours_passed <= 0:
		return
	
	var fervour_gained = 0
	var food = EventBus.food_accumulated
	
	for hour in range(1, hours_passed + 1):
		
		# Hourly food decay
		food -= 4.0
		food = clamp(food, 0.0, 100.0)
		
		# Fervour gain every 3 hours
		if hour % (EventBus.total_orbles / 2) == 0:
			if food > 40.0:
				fervour_gained += 1
		
		# -------------------------
		# Goblin raid chance
		# -------------------------
		var raid_chance = get_goblin_raid_chance(food)
		if raid_chance > 0.0 and randf() < raid_chance and raid_happened == false:
			raid_happened = true
			goblin_raid()
	
	# Commit final food
	EventBus.food_accumulated = food
	
	EventBus.last_hourly_food_update = now
	%sanctuary_ritual_site.fervour_to_be_gained(fervour_gained * 2)

func get_goblin_raid_chance(food: float) -> float:
	if food >= 70.0 and EventBus.intro == false and EventBus.orbles_to_introduce <= 0 :
		return 0.05
	elif food >= 50.0 and EventBus.intro == false and EventBus.orbles_to_introduce <= 0 :
		return 1.0 / 7.0
	elif food >= 20.0 and EventBus.intro == false and EventBus.orbles_to_introduce <= 0 :
		return 1.0 / 4.0
	elif EventBus.intro == false and EventBus.orbles_to_introduce <= 0 :
		return 0.5
	else :
		return 0.0

func goblin_raid() :
	await get_tree().create_timer(7.0).timeout
	get_tree().current_scene.sanctuary_raid_started()
	for i in range(randi_range(5, 6)) :
		EventBus.raid_entity_count += 1
		var halfdarkgoblin = preload("res://Scenes/Monsters/halfdarkgoblin.tscn").instantiate()
		halfdarkgoblin.global_position = %sanctuary_ritual_site.position + Vector2(randi_range(-300, 300), randi_range(90, 150))
		call_deferred("add_child", halfdarkgoblin)
		
		for tm in get_tree().get_nodes_in_group("orbles"):
			tm.raided = true
			tm.run_upwards()

func spawn_default_shield() :
	var shield_pickup = preload("res://Scenes/brody_shield_pickup.tscn").instantiate() 
	shield_pickup.global_position = Vector2(90, 16)
	call_deferred("add_child", shield_pickup)

func play_sanctuary_tutorial() :
	# Spawn Exclamation Marks for Mission Board, Cat Balloon, Clives Shop, Jackie
	%overseer_mission_board.exclamation_animation()
	%cat_balloon.exclamation_animation()
	%jackies_tent.exclamation_animation()
	%orble_chefstation.exclamation_animation()
	%sanctuary_ritual_site.exclamation_animation()
	%IntroCam.enabled = true
	
	var bgt = %TradersBackground
	
	# Start slightly above and transparent
	bgt.modulate.a = 0.0
	bgt.position.y -= 20
	
	var t = create_tween().parallel()
	t.set_parallel(true)
	
	# Fade in
	t.tween_property(bgt, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	t.tween_property(bgt, "position:y", bgt.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Camera :
	var camera_tween = create_tween().parallel()
	camera_tween.tween_property(%IntroCam, "zoom", Vector2(1.0, 1.0), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(%IntroCam, "offset", Vector2(0.0, 0.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	await get_tree().create_timer(9.0).timeout
	
		# Fade and slide back up
	var t2 = create_tween().parallel()
	t2.set_parallel(true)
	
	t2.tween_property(bgt, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	t2.tween_property(bgt, "position:y", bgt.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await t2.finished
	
	# ----------------------------------------------------------------------------------------------
	# SHOPS TIME :
	# ----------------------------------------------------------------------------------------------
	var bgs = %ShopsBackground
	
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
	
	var camera_tween2 = create_tween().parallel()
	camera_tween2.tween_property(%IntroCam, "zoom", Vector2(1.75, 1.75), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween2.tween_property(%IntroCam, "offset", Vector2(-70.0, -80.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await camera_tween2.finished
	var camera_tween3 = create_tween().parallel()
	camera_tween3.tween_property(%IntroCam, "zoom", Vector2(1.75, 1.75), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween3.tween_property(%IntroCam, "offset", Vector2(120.0, -70.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await camera_tween3.finished
	
	var camera_tween4 = create_tween().set_parallel(true)
	camera_tween4.tween_property(%IntroCam, "zoom", Vector2(1.00, 1.00), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween4.tween_property(%IntroCam, "offset", Vector2(0.0, 0.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2.4).timeout
	
		# Fade and slide back up
	var tb2 = create_tween()
	tb2.set_parallel(true)
	
	tb2.tween_property(bgs, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb2.tween_property(bgs, "position:y", bgs.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb2.finished
	
	# ----------------------------------------------------------------------------------------------
	# ORBLES TIME :
	# ----------------------------------------------------------------------------------------------
	var bgo = %OrbleBackground
	
	# Start slightly above and transparent
	bgo.modulate.a = 0.0
	bgo.position.y -= 20
	
	var tb1 = create_tween().parallel()
	tb1.set_parallel(true)
	
	# Fade in
	tb1.tween_property(bgo, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	tb1.tween_property(bgo, "position:y", bgo.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await tb1.finished
	
	var camera_tween21 = create_tween().set_parallel(true)
	camera_tween21.tween_property(%IntroCam, "zoom", Vector2(1.1, 1.1), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween21.tween_property(%IntroCam, "offset", Vector2(-180.0, 165.0), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await camera_tween21.finished
	
	var camera_tween41 = create_tween().set_parallel(true)
	camera_tween41.tween_property(%IntroCam, "zoom", Vector2(1.00, 1.00), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween41.tween_property(%IntroCam, "offset", Vector2(0.0, 0.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2.4).timeout
	
		# Fade and slide back up
	var tb21 = create_tween()
	tb21.set_parallel(true)
	
	tb21.tween_property(bgo, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb21.tween_property(bgo, "position:y", bgo.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb21.finished
	
	get_tree().current_scene.get_node("Brody/BrodyCam").enabled = true
	%IntroCam.enabled = false
	EventBus.currently_interacting = false
	#EventBus.intro = false
	spawn_default_shield() 
	%orble_chefstation.manual = true


func _on_torch_and_shield_body_entered(body: Node2D) -> void:
	if body.name == "Brody" : 
		# Highlight and then if player clicks interact button within the space, begin dungeon crawl:
		%TorchAndShieldSprite.play("highlighted")
		EventBus.dungeon_crawl_button_available = true


func _on_torch_and_shield_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.dungeon_crawl_button_available = false
		# Unhighlight and take away ability to click interact to dungeon crawl :
		if get_node_or_null("%TorchAndShieldSprite") :
			%TorchAndShieldSprite.play("default")


func arrows_pointing() :
	# Torch & Shield Arrow Tween:
	while %TorchAndShieldArrow.visible == true :
		var torch_and_shield_arrow_up_tween = create_tween()
		torch_and_shield_arrow_up_tween.tween_property(%TorchAndShieldArrow, "position", Vector2(177.0, -19.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# When Moved Up, Move Down :
		await torch_and_shield_arrow_up_tween.finished
		var torch_and_shield_down_tween = create_tween()
		torch_and_shield_down_tween.tween_property(%TorchAndShieldArrow, "position", Vector2(177.0, -9.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await torch_and_shield_down_tween.finished


func wagon_signs_pointing():
	while %clives_wagon.visible:
		var up_ex = create_tween()
		up_ex.tween_property(%MoneySign, "position", Vector2(8, -65), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		var up_dollar = create_tween()
		up_dollar.tween_property(%ExclamationMark, "position", Vector2(20, -65), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		await up_dollar.finished
		
		var down_ex = create_tween()
		down_ex.tween_property(%MoneySign, "position", Vector2(5, -41), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		var down_dollar = create_tween()
		down_dollar.tween_property(%ExclamationMark, "position", Vector2(16, -41), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		await down_ex.finished
		await down_dollar.finished


func tutorial_replay_floating() :
	while %TutorialReplay.visible:
		var up_ex = create_tween()
		up_ex.tween_property(%TutorialReplay, "position", %TutorialReplay.position + Vector2(2, -4), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween()
		down_ex.tween_property(%TutorialReplay, "position", %TutorialReplay.position - Vector2(2, -4), 2.4).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		await down_ex.finished


func _on_tutorial_replay_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		%TutorialReplaySprite.play("highlighted")
		EventBus.tutorial_replay_available = true


func _on_tutorial_replay_body_exited(body: Node2D) -> void:
	if body.name == "Brody" and is_instance_valid(%TutorialReplaySprite) :
		%TutorialReplaySprite.play("default")
		EventBus.tutorial_replay_available = false
