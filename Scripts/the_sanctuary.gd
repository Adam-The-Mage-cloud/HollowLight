extends Node2D

func _ready() :
	EventBus.save_game()
	EventBus.sanctuary = true
	EventBus.total_current_darkness = 0
	%SanctuaryMainFloor.add_to_group("floors")
	arrows_pointing()
	wagon_signs_pointing()
	tutorial_replay_floating()
	
	if EventBus.intro == true :
		play_sanctuary_tutorial()


func play_sanctuary_tutorial() :
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
	camera_tween21.tween_property(%IntroCam, "offset", Vector2(-140.0, 200.0), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
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
	EventBus.intro = false


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
