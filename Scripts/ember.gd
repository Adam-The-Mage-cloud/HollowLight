extends Area2D

var player_tracking = false
var target
var speed = 60


func _ready():
	randomize()
	rotation_degrees = randf_range(0, 360)
	# Pick Random Skin :
	if randi_range(1, 2) == 1 :
		%EmberSprite.play("ember")
	else :
		%EmberSprite.play("ember2")
	ember_animation()
	
	# Help ember accelerate :
	var ember_accelerate = create_tween()
	ember_accelerate.tween_property($".", "speed", 60, 0.75)
	

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		player_tracking = true
		target = body

func _physics_process(delta: float) -> void:
	if player_tracking:
		
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		player_tracking = false

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.emit_signal("ember_acquired")
		queue_free()

func ember_animation():
	var tw = get_tree().create_tween()

	tw.parallel().tween_property($".", "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property($".", "scale", Vector2(0.9, 0.9), 0.4)

	tw.finished.connect(ember_animation)
