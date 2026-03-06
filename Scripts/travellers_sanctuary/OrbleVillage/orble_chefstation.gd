extends CharacterBody2D

var manual = false

func _ready() :
	if EventBus.food_accumulated < 40 :
		stew_animation()

func stirring() :
	%OrbleStewSprite.visible = true


func stop_stirring() :
	%OrbleStewSprite.visible = false


func _on_cheffing_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.cheffing_station_interactable = true
		%ChefstationSprite.play("highlighted")
		%ExclamationMarkIndicator.visible = false
		if manual == true :
			EventBus.intro = false
			load_cheffing_manual()



func _on_cheffing_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.cheffing_station_interactable = false
		%ChefstationSprite.play("default")


func load_cheffing_manual() :
	var cheffing_manual = preload("res://Scenes/travellers_sanctuary/OrbleVillage/stew_manual.tscn").instantiate()
	call_deferred("add_child", cheffing_manual)
	manual = false


func exclamation_animation() :
	%ExclamationMarkIndicator.visible = true
	while $".".visible == true:
		var up_ex = create_tween().set_parallel(true)
		up_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		up_ex.tween_property(%CookingText, "scale", Vector2(0.2, 0.2), 1.6)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween().set_parallel(true)
		down_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		down_ex.tween_property(%CookingText, "scale", Vector2(0.12, 0.12), 1.6)
		
		
		await down_ex.finished
	%ExclamationMarkIndicator.visible = false


func stew_animation() :
	%StewIconSprite.visible = true
	while $".".visible == true:
		var up_ex = create_tween().set_parallel(true)
		up_ex.tween_property(%StewIconSprite, "global_position", %StewIconSprite.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween().set_parallel(true)
		down_ex.tween_property(%StewIconSprite, "global_position", %StewIconSprite.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		
		await down_ex.finished
	%StewIconSprite.visible = false
