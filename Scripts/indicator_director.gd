extends Sprite2D

@onready var margin = 32.0

var target

var levelled_used_xp = 0.0
var xp_displayed = 0.0
var xp_target = 0.0
var xp_velocity = 0.0

var temporary_level = 0

func _ready() :
	%GameplayXPOutlineFlasher.material = %GameplayXPOutlineFlasher.material.duplicate()
	%GameplayXPProgressBar.material = %GameplayXPProgressBar.material.duplicate()
	%GameplayTotalXPText.material = %GameplayTotalXPText.material.duplicate()

func _process(delta):
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
	
	# Showcase Gold, XP and Fervour Counts :
	%DungeonGoldText.text = str(EventBus.total_new_acquired_goldpieces)
	
	# Displayed level = real level + temporary level-ups
	%GameplayTotalXPText.text = str(EventBus.player_level + temporary_level)
	
	# Target XP comes from the event bus
	xp_target = float(EventBus.total_new_acquired_experience - levelled_used_xp)
	
	# Smooth interpolation
	var speed = 6.0
	xp_displayed = lerp(xp_displayed, xp_target, 1.0 - pow(0.001, delta * speed))
	
	# Snap if extremely close
	if abs(xp_displayed - xp_target) < 0.1:
		xp_displayed = xp_target
	
	%GameplayXPProgressBar.value = xp_displayed
	
	var current_level = EventBus.player_level + temporary_level
	%GameplayXPProgressBar.max_value = float(xp_required_for(current_level))
	resolve_level_ups()
	
	# Fervour UI
	if EventBus.total_new_fervour > 0:
		%FervourCount.visible = true
		%DungeonFervourText.text = str(EventBus.total_new_fervour)
	else:
		%FervourCount.visible = false


func resolve_level_ups():
	if xp_displayed >= float(xp_required_for(EventBus.player_level + temporary_level)):
		var needed = xp_required_for(EventBus.player_level + temporary_level)
		
		# Consume XP only from displayed value
		xp_displayed -= needed
		levelled_used_xp += needed
		
		# Add a temporary level
		temporary_level += 1
		%GameplayTotalXPText.text = str(EventBus.player_level + temporary_level)
		
		level_up_flash_in_game()
		var current_level = EventBus.player_level + temporary_level
		%GameplayXPProgressBar.max_value = float(xp_required_for(current_level))



func level_up_flash_in_game():
	print("flashingg")
	%GameplayXPOutlineFlasher.visible = true
	await get_tree().create_timer(0.2).timeout
	%GameplayXPOutlineFlasher.visible = false

func xp_required_for(level: int) -> int:
	var base = 100
	var per_level = 0
	var max_level = 0
	
	var effective_level = min(level, max_level)
	return base + (per_level * (effective_level - 1))


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
