extends Area2D

var out_of_range = true

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = false
		$"..".slash()
		while out_of_range == false :
			$"..".slash()
			await get_tree().create_timer(randf_range(0.6, 1.25)).timeout

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		out_of_range = true
