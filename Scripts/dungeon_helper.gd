extends Node2D

func _ready() :
	%ShowcaserCamera.enabled = true
	
	# Assign Wall Interactable as Wall Torch :
	%wall_interactables.type = 1
	%wall_interactables._on_area_entered(%brazier)
	
	# Swipe In Scroll Manual 1 :
	var bgt = %DungeonScroll1
	
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
	var camera_tween = create_tween()
	camera_tween.tween_property(%ShowcaserCamera, "zoom", Vector2(1.6, 1.6), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	await get_tree().create_timer(7.0).timeout
	
		# Fade and slide back up
	var t2 = create_tween().parallel()
	t2.set_parallel(true)
	
	t2.tween_property(bgt, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	t2.tween_property(bgt, "position:y", bgt.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await t2.finished

	# Swipe In Scroll Manual 1 :
	var bga = %DungeonScroll2
	
	# Start slightly above and transparent
	bga.modulate.a = 0.0
	bga.position.y -= 20
	
	var t1 = create_tween().parallel()
	t1.set_parallel(true)
	
	# Fade in
	t1.tween_property(bga, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	t1.tween_property(bga, "position:y", bga.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Camera :
	var camera_tween2 = create_tween()
	camera_tween2.tween_property(%ShowcaserCamera, "zoom", Vector2(1.5, 1.5), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t1.finished
	await get_tree().create_timer(7.0).timeout
	
		# Fade and slide back up
	var t21 = create_tween().parallel()
	t21.set_parallel(true)
	
	t21.tween_property(bga, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	t21.tween_property(bga, "position:y", bga.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await t21.finished
	
	var camera_tween21 = create_tween()
	camera_tween21.tween_property(%ShowcaserCamera, "offset", Vector2(0.0, 0.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await camera_tween21.finished
	# Sort Camera Out :
	%ShowcaserCamera.enabled = false
	EventBus.return_camera()
	
	# SELF DESTRUCT TIMER :
	await get_tree().create_timer(3.0).timeout
	queue_free()
