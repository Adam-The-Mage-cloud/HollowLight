extends Area2D

var used = false
var currently_climbing = false
var climb_tween: Tween = null

func _ready() :
	# Themify :
	if EventBus.current_theme == 2 :
		modulate = Color(0.067, 0.988, 0.988)
	elif EventBus.current_theme == 3 :
		modulate = Color(0.976, 0.192, 0.298, 1.0)
	elif EventBus.current_theme == 4 :
		modulate = Color(0.0, 0.306, 0.078, 1.0)
		
	flash_white()


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Brody":
		return
	
	if used == true :
		return
	
	currently_climbing = true
	body.currently_climbing = true
	
	# If a previous tween exists, kill it
	if climb_tween:
		climb_tween.kill()
	
	# Start fresh shrink tween
	climb_tween = create_tween()
	climb_tween.tween_property(body, "scale", Vector2(0.25, 0.25), 1.2)
	
	# When tween finishes, teleport to new room
	climb_tween.finished.connect(func():
		if currently_climbing:  # Only if still on ladder
			used = true
			body.scale = Vector2i(1.0, 1.0)
			$"..".new_stepladder_dungeon(body)
			await get_tree().create_timer(1).timeout
			used = false
	)

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Brody":
		return
	
	currently_climbing = false
	body.currently_climbing = false
	
	# Stop shrink tween
	if climb_tween:
		climb_tween.kill()
	
	# Tween back to full size
	var grow_tween = create_tween()
	grow_tween.tween_property(body, "scale", Vector2(1, 1), 0.3)

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
