extends Area2D

func _ready () :
	%Tallgrass.play("default")

func _on_body_entered(body) :
	if body.direction != Vector2.ZERO :
		%Tallgrass.play("swaying")
	else :
		%Tallgrass.play("default")

func _on_body_exited(_body) :
	%Tallgrass.play("default")
