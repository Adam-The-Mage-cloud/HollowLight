extends CharacterBody2D

func _ready() :
	%CatBalloonist.play("down")
	cat_shake() 


func cat_shake() :
	var cat = %CatBalloonist
	while ($".".visible == true) :
		var shake_tween = create_tween()
		shake_tween.tween_property(cat, "global_position", cat.global_position + Vector2(0.5, 0), 0.05) 
		await shake_tween.finished
		
		var shake_tween2 = create_tween()
		shake_tween2.tween_property(cat, "global_position", cat.global_position - Vector2(0.5, 0), 0.05) 
		await shake_tween2.finished
		
		var shake_tween3 = create_tween()
		shake_tween3.tween_property(cat, "global_position", cat.global_position - Vector2(0.5, 0), 0.05) 
		await shake_tween3.finished
		
		var shake_tween4 = create_tween()
		shake_tween4.tween_property(cat, "global_position", cat.global_position + Vector2(0.5, 0), 0.05) 
		await shake_tween4.finished
		
		await get_tree().create_timer(2.4).timeout


# Collisions :
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


func _on_cat_rise_up_area_body_entered(_body) -> void:
	# It can honestly be any entity lol :
	%CatBalloonist.play("up")


func _on_cat_rise_up_area_body_exited(_body) -> void:
	%CatBalloonist.play("down")
