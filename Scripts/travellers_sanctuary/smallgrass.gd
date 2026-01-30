extends Area2D

func _ready () :
	%Smallgrass.play("default")

func _on_body_entered(body) :
	if body.name == "Brody" :
		if body.direction != Vector2.ZERO :
			%Smallgrass.play("open")
		else :
			%Smallgrass.play("default")

func _on_body_exited(body) :
	if body.name == "Brody" :
		%Smallgrass.play("default")
