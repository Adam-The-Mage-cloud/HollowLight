extends Area2D

func _ready() :
	# Flashing :
	flashing()
	



func flashing() :
	while visible == true :
		var tween = create_tween()
		tween.tween_property(material, "shader_parameter/tint_amount", 0.72, 0.2)
		tween.tween_property(material, "shader_parameter/tint_amount", 0.12, 0.1)
		await tween.finished
		await get_tree().create_timer(1.2).timeout


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.shield_acquired = "default"
		body.pickup_shield()
		queue_free()
