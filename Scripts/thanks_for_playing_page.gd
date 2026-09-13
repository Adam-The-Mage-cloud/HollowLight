extends Sprite2D

func fade_scroll():
	var tween := create_tween()
	tween.set_parallel(false)

	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hold visible for a moment
	tween.tween_interval(2.0)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
