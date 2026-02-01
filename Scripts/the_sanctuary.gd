extends Node2D

func _ready() :
	EventBus.save_game()
	%SanctuaryMainFloor.add_to_group("floors")
	arrows_pointing()

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
