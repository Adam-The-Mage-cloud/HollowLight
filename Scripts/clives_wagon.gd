extends CharacterBody2D


func _on_wagon_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.clives_shop_interactable = true
		%WagonSprite.play("highlighted")


func _on_wagon_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.clives_shop_interactable = false
		%WagonSprite.play("default")
