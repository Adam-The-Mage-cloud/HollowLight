extends Sprite2D

@onready var margin = 32.0

var target

func _process(_delta):
	get_nearest_brazier()
	if target == null :
		get_nearest_door()
	if target == null:
		visible = false
		return
	
	var viewport = get_viewport()
	var cam = viewport.get_camera_2d()
	if cam == null:
		return
	
	# WORLD → SCREEN
	var screen_pos: Vector2 = cam.get_canvas_transform() * target.global_position
	var screen_size = viewport.get_visible_rect().size
	
	# On-screen?
	if screen_pos.x > margin and screen_pos.x < screen_size.x - margin \
	and screen_pos.y > margin and screen_pos.y < screen_size.y - margin:
		visible = false
		return
	
	visible = true
	
	var center = screen_size * 0.5
	var dir = (screen_pos - center).normalized()
	
	var half = center - Vector2(margin, margin)
	var edge_pos = center + dir * min(
		abs(half.x / dir.x),
		abs(half.y / dir.y)
	)
	
	# Now this works because pointer is in CanvasLayer
	position = edge_pos
	rotation = dir.angle()
	rotation_degrees += 90
	print("screen_pos:", screen_pos, " pointer_pos:", position)


func get_nearest_brazier():
	var braziers = get_tree().get_nodes_in_group("braziers")
	var nearest = null
	var nearest_dist = INF
	
	for b in braziers:
		if b.lit:
			continue
	
		var dist = %Brody.global_position.distance_to(b.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = b
	
	# fallback to doors
	if nearest == null:
		nearest = get_nearest_door()
	
	target = nearest

func get_nearest_door():
	var doors = get_tree().get_nodes_in_group("doors")
	var nearest = null
	var nearest_dist = INF
	
	for d in doors:
		if d.unlocked == true:
			continue
	
		var dist = %Brody.global_position.distance_to(d.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = d
	
	return nearest


func flash_white():
	if visible == true :
		var mat = material
		if mat == null:
			return
			
		# Flash up to white
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_amount", 1.0, 0.3)
		
		# Fade back down
		tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)

func _on_flash_timer_timeout() -> void:
	flash_white()
