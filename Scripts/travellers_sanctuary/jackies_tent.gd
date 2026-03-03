extends CharacterBody2D


func _on_jackie_tent_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.jackie_shop_interactable = true
		%JackieTent.play("highlighted")
		%JackieSprite.play("highlighted")
		%JackieBench.play("highlighted")
		%ExclamationMarkIndicator.visible = false


func _on_jackie_tent_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.jackie_shop_interactable = false
		%JackieTent.play("default")
		%JackieSprite.play("default")
		%JackieBench.play("default")


func exclamation_animation() :
	%ExclamationMarkIndicator.visible = true
	while $".".visible == true:
		var up_ex = create_tween().set_parallel(true)
		up_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		up_ex.tween_property(%UpgradesText, "scale", Vector2(0.2, 0.2), 1.6)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween().set_parallel(true)
		down_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		down_ex.tween_property(%UpgradesText, "scale", Vector2(0.12, 0.12), 1.6)
		
		
		await down_ex.finished
	%ExclamationMarkIndicator.visible = false
