extends CharacterBody2D


func _on_jackie_tent_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.jackie_shop_interactable = true
		%JackieTent.play("highlighted")
		%JackieSprite.play("highlighted")
		%JackieBench.play("highlighted")


func _on_jackie_tent_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.jackie_shop_interactable = false
		%JackieTent.play("default")
		%JackieSprite.play("default")
		%JackieBench.play("default")
