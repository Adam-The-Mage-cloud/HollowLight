extends Area2D

func _ready () :
	%Smallgrass.play("default")

func _on_body_entered(body) :
	if body.direction != Vector2.ZERO :
		%Smallgrass.play("open")
	else :
		%Smallgrass.play("default")

func _on_body_exited(_body) :
	%Smallgrass.play("default")
