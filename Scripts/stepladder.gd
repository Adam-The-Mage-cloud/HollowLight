extends Area2D

var used = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		if body.dashing == false and used == false :
			used = true
			# Teleport to a new room at an offset far enough along +x axis away from current system :
			# 1. Create new room :
			$"..".new_stepladder_dungeon(body)
			await get_tree().create_timer(1).timeout
			used = false
