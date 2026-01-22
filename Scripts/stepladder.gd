extends Area2D

var used = false

func _ready() :
	flash_white()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		if used == false : # if body.dashing == false and... ?
			used = true
			# Teleport to a new room at an offset far enough along +x axis away from current system :
			# 1. Create new room :
			$"..".new_stepladder_dungeon(body)
			await get_tree().create_timer(1).timeout
			used = false

func flash_white():
	while(1) :
		var mat = %StepLadderSprite.material
		if mat == null:
			return
			
		# Flash up to white
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_amount", 1.0, 0.3)
		
		# Fade back down
		tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)
		await get_tree().create_timer(1.6).timeout
