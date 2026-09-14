extends Control

func _ready() :
	randomize()
	EventBus.last_room_loaded.connect(hide_loading)

func show_loading():
	visible = true
	continuously_set_progress()

func hide_loading():
	# Create a tween that fills the rest of the bar :
	var finish_loading_tween = create_tween()
	finish_loading_tween.tween_property(%LoadingProgressBar, "value", 100.0, 0.5)
	await get_tree().create_timer(2.0).timeout
	%LoadingProgressBar.value = 0.0
	visible = false

func continuously_set_progress():
	while visible == true :
		%LoadingProgressBar.value += randi_range(1, 7)
		await get_tree().create_timer(randf_range(0.1, 1.2)).timeout
