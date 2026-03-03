extends Node2D

func _ready() :
	open_stewpot_menu()
	finger_tapping()


func open_stewpot_menu() :
	# Update Gold & XP Values :
	%TotalGoldText.text = str(EventBus.total_acquired_goldpieces)
	
	# Swoop-in Shop :
	var bgs = $"."
	
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




# >>>
# GENERAL CLOSE BUTTON :
# >>>
func _on_close_menu_button_pressed() -> void:
	# SHOPS :
	$"../..".shop_closed()
	# > For Clives Shop :
			# Fade and slide back up
	var bgs = $"."
	
	# Start slightly above and transparent
	bgs.modulate.a = 0.0
	bgs.position.y -= 20
	
	var tb2 = create_tween()
	tb2.set_parallel(true)
	
	tb2.tween_property(bgs, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb2.tween_property(bgs, "position:y", bgs.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb2.finished
	queue_free()


func _on_buy_stew_button_pressed() -> void:
	print("bought")
	if EventBus.total_acquired_goldpieces >= 50 and EventBus.food_accumulated < 100 :
		print("bought")
		EventBus.total_acquired_goldpieces -= 50
		EventBus.stews_prepared += 1
		EventBus.food_accumulated += 35
		EventBus.food_accumulated = clamp(EventBus.food_accumulated, 0.0, 100.0)
		%TotalGoldText.text = str(EventBus.total_acquired_goldpieces)


func finger_tapping() :
	while %BuyFinger.visible == true and EventBus.food_accumulated < 65 :
		var BuyFinger_up = create_tween().set_parallel(true)
		BuyFinger_up.tween_property(%BuyFinger, "rotation_degrees", %BuyFinger.rotation_degrees - 10, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		BuyFinger_up.tween_property(%BuyFinger, "position", %BuyFinger.position + Vector2(-1, -2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await BuyFinger_up.finished
		var BuyFinger_back = create_tween().set_parallel(true)
		BuyFinger_back.tween_property(%BuyFinger, "rotation_degrees", %BuyFinger.rotation_degrees + 10, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		BuyFinger_back.tween_property(%BuyFinger, "position", %BuyFinger.position - Vector2(-1, -2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(1.2).timeout
	%BuyFinger.visible = false
