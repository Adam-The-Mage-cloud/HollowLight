extends Area2D

func _ready() :
	draw_back()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		body.ogre_slashed(self)
		body.massive_knockback(self)

func fly() :
	var direction = Vector2.RIGHT.rotated(global_rotation)
	var distance = 600
	
	var fly_straight_tween = create_tween()
	fly_straight_tween.tween_property(self, "global_position", global_position + direction * distance, 5.5)

func draw_back() :
	var draw_back_tween = create_tween()
	draw_back_tween.tween_property(self, "position", + position + Vector2(-4, 0), 2)

func apply_angle(target_angle) :
	rotation_degrees = target_angle


func _on_despawn_timer_timeout() -> void:
	queue_free()
