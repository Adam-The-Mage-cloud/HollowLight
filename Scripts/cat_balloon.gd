extends CharacterBody2D


func _on_cat_balloon_shop_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.catballoon_shop_interactable = true
		%CatBalloonBasket.play("highlighted")
		%CatBalloon.play("highlighted")


func _on_cat_balloon_shop_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.catballoon_shop_interactable = false
		%CatBalloonBasket.play("default")
		%CatBalloon.play("default")
