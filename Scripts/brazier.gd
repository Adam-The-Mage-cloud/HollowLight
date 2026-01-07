extends Area2D


func brazier_lit() :
	%BrazierSprite.play("lit")
	

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Torch" :
		brazier_lit()
