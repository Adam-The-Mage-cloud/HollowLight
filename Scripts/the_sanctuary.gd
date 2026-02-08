extends Node2D

func _ready() :
	EventBus.save_game()
	EventBus.total_current_darkness = 0
	%SanctuaryMainFloor.add_to_group("floors")
	arrows_pointing()
	wagon_signs_pointing()

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
