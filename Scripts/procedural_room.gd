extends Node2D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Source ID's :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Floor Tiles = ID 0-9
# Obstacle Tiles = ID 10-19
# BitsandBobs Tiles = ID 20-29
# Wall Tiles = ID 30-39
# Wall Corner Tiles = ID 40-49
# Door Tiles = ID 50-59
# Floor Cover (mushrooms etc) = ID 60-69
# Room Outline (cobblestone etc) = ID 70-79
# Front Facing Wall (mineshaft etc) = ID 80-89
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# VARIABLES :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
var floor_positions: Array[Vector2i] = []
var wall_positions: Array[Vector2i] = []

var room_complete = false
var already_opened = false

var spawnpoints = 10

var room_type = 0
var wallrings = 20
var theme = 0

var floor_source_id = 0
var obstacle_source_id = 0
var bitsandbobs_source_id = 0
var floorcover_source_id = 0
var wall_source_id = 0
var corner_source_id = 0
var room_outline_source_id = 0
var room_frontfacing_wall_source_id = 0

var direction
var first_room = true
var previous_floor_world_positions: Array[Vector2] = []
var door_origin
var width = 32
var height = 18
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PLAY ALL INITIAL EXECUTABLES NEEDED FOR ROOM :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ready() -> void:
	randomize()
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)

	_choose_room_type_and_size()

	if first_room == false:
		_position_room_relative_to_door()

	theme = 1

	# FLOOR GENERATION
	generate_floor()
	_smooth_floor(2)
	_raggedize_edges()

	# WIDENS NARROW PASSAGES BEFORE THEY ARE CONNECTED
	_widen_narrow_passages()

	# ENSURES ALL FLOOR IS REACHABLE
	_ensure_reachable_floor()

	# WALLS / OUTLINES
	generate_walls_from_floor()
	generate_wall_corners_from_floor()
	generate_frontfacing_wall_from_floor()
	generate_outline_layers_from_floor()
	generate_underwall_ring()

	# INTERIOR
	generate_obstacles()
	generate_bitsandbobs()
	generate_floorcover()

	# DOOR + SPAWNS
	position_door()
	place_spawn_points()
	monster_spawns()
	beacon_spawns()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ROOM TYPE + SIZE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _choose_room_type_and_size() -> void:
	if first_room:
		room_type = 2
		width = randi_range(14, 18)
		height = randi_range(18, 30)
	else:
		if room_type == 0:
			room_type = randi_range(1, 9)

		match room_type:
			1:
				width = randi_range(32, 52)
				height = randi_range(22, 34)
			2:
				width = randi_range(14, 20)
				height = randi_range(24, 40)
			3,4,5,6,7,8,9:
				width = randi_range(32, 52)
				height = randi_range(22, 36)
			_:
				width = randi_range(32, 48)
				height = randi_range(22, 34)

func _position_room_relative_to_door() -> void:
	direction = 1
	if direction == 1:
		global_position.y = door_origin.y - (height * 10) + 10
		if room_type == 2:
			global_position.x = door_origin.x - (width * 10) / 2

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FLOOR GENERATION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _add_floor(p: Vector2i) -> void:
	if floor_positions.has(p):
		return
	floor_positions.append(p)
	if theme == 1:
		var atlas_x = randi_range(0, 3)
		var alt = randi_range(0, 3)
		%TileMapFloor.set_cell(p, 0, Vector2i(atlas_x, 0), alt)

func generate_floor() -> void:
	floor_positions.clear()
	%TileMapFloor.clear()

	match room_type:
		1: _generate_ragged_hall()
		2: _generate_corridor_room()
		3: _generate_circle_room()
		4: _generate_cave_room()
		5: _generate_cross_room()
		6: _generate_pillar_room()
		7: _generate_blob_room()
		8: _generate_lobed_room()
		9: _generate_ring_room()
		_: _generate_ragged_hall()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# WIDEN NARROW PASSAGES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _widen_narrow_passages() -> void:
	var floor_set = build_floor_set()
	var to_add = []
	
	for p in floor_positions:
		var neighbors = 0
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			if floor_set.has(p + d):
				neighbors += 1
				
		if neighbors == 1:
			for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var n = p + d
				if not floor_set.has(n):
					to_add.append(n)
					
	for p in to_add:
		_add_floor(p)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# VARIOUS CHECKS TO MAKE SURE THE DOOR IS ALWAYS REACHABLE AND ALL ROOM AREAS ARE REACHABLE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ensure_reachable_floor() -> void:
	if floor_positions.is_empty():
		return
		
	var floor_set = build_floor_set()
	var start = floor_positions[0]
	
	var queue: Array[Vector2i] = [start]
	var visited = {}
	visited[start] = true
	
	while queue.size() > 0:
		var p = queue.pop_front()
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n = p + d
			if floor_set.has(n) and not visited.has(n):
				visited[n] = true
				queue.append(n)
				
	for p in floor_positions.duplicate():
		if not visited.has(p):
			floor_positions.erase(p)
			%TileMapFloor.set_cell(p, -1)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# WALLS / CORNERS / OUTLINES / FRONT-FACING WALL
# (your existing implementations stay exactly the same)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _generate_ragged_hall() -> void:
	# Start with a rectangle, then carve out edges with noise texture
	for x in range(width):
		for y in range(height):
			_add_floor(Vector2i(x, y))
			
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.12
	
	for p in floor_positions.duplicate():
		var n = noise.get_noise_2d(float(p.x), float(p.y))
		if n < -0.15:
			floor_positions.erase(p)
			%TileMapFloor.set_cell(p, -1)

func _generate_corridor_room() -> void:
	# Wider, more generous corridor, with some curveballs
	var mid_x = width / 2
	var corridor_half_width = randi_range(2, 3) 
	
	for x in range(width):
		for y in range(height):
			if abs(x - mid_x) <= corridor_half_width:
				_add_floor(Vector2i(x, y))
				
	# Add some side pockets / splits
	for i in range(randi_range(2, 4)):
		var pocket_y = randi_range(int(height * 0.2), int(height * 0.8))
		var pocket_dir = randi_range(-1, 1)
		var pocket_length = randi_range(4, 8)
		for j in range(pocket_length):
			var px = mid_x + pocket_dir * (corridor_half_width + j)
			if px >= 0 and px < width:
				for oy in range(-1, 2):
					var py = pocket_y + oy
					if py >= 0 and py < height:
						_add_floor(Vector2i(px, py))

func _generate_circle_room() -> void:
	var cx = width / 2.0
	var cy = height / 2.0
	var radius = min(width, height) * 0.45
	for x in range(width):
		for y in range(height):
			if Vector2(x - cx, y - cy).length() <= radius:
				_add_floor(Vector2i(x, y))

func _generate_cave_room() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.10
	
	for x in range(width):
		for y in range(height):
			var n = noise.get_noise_2d(float(x), float(y))
			if n > -0.1:
				_add_floor(Vector2i(x, y))

func _generate_cross_room() -> void:
	var mid_x = width / 2
	var mid_y = height / 2
	for x in range(width):
		for y in range(height):
			if abs(x - mid_x) < int(width * 0.18) or abs(y - mid_y) < int(height * 0.18):
				_add_floor(Vector2i(x, y))

func _generate_pillar_room() -> void:
	_generate_ragged_hall()
	
	var pillars = [
		Vector2i(width / 4, height / 4),
		Vector2i(3 * width / 4, height / 4),
		Vector2i(width / 4, 3 * height / 4),
		Vector2i(3 * width / 4, 3 * height / 4)
	]
	
	for p in pillars:
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				var pos = p + Vector2i(ox, oy)
				if floor_positions.has(pos):
					floor_positions.erase(pos)
					%TileMapFloor.set_cell(pos, -1)

func _generate_blob_room() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	
	var threshold = -0.05
	
	for x in range(width):
		for y in range(height):
			var n = noise.get_noise_2d(float(x), float(y))
			if n > threshold:
				_add_floor(Vector2i(x, y))

func _generate_lobed_room() -> void:
	var centers = [
		Vector2(width * 0.3, height * 0.3),
		Vector2(width * 0.7, height * 0.3),
		Vector2(width * 0.5, height * 0.7)
	]
	
	var radius = min(width, height) * 0.25
	
	for x in range(width):
		for y in range(height):
			for c in centers:
				if Vector2(x, y).distance_to(c) <= radius:
					_add_floor(Vector2i(x, y))
					break

func _generate_ring_room() -> void:
	var cx = width / 2.0
	var cy = height / 2.0
	var outer = min(width, height) * 0.45
	var inner = outer * 0.55
	
	for x in range(width):
		for y in range(height):
			var d = Vector2(x - cx, y - cy).length()
			if d <= outer and d >= inner:
				_add_floor(Vector2i(x, y))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# POST-PROCESSING: SMOOTH + RAGGED EDGES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _smooth_floor(iterations = 2) -> void:
	if floor_positions.is_empty():
		return
		
	for i in range(iterations):
		var floor_set = build_floor_set()
		var to_remove: Array[Vector2i] = []
		for p in floor_positions:
			var neighbors = 0
			for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				if floor_set.has(p + d):
					neighbors += 1
			if neighbors <= 1:
				to_remove.append(p)
				
		for p in to_remove:
			floor_positions.erase(p)
			%TileMapFloor.set_cell(p, -1)

func _raggedize_edges() -> void:
	# Slightly take away from outer edges for rustic feel
	var floor_set = build_floor_set()
	var to_remove: Array[Vector2i] = []
	
	for p in floor_positions:
		var neighbors = 0
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			if floor_set.has(p + d):
				neighbors += 1
		# Edge tiles with few neighbors have a chance to be removed
		if neighbors <= 2 and randf() < 0.25:
			to_remove.append(p)
			
	for p in to_remove:
		floor_positions.erase(p)
		%TileMapFloor.set_cell(p, -1)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# WALLS / CORNERS / UNDERWALL / OUTLINES / FRONT-FACING WALL
# (your existing implementations can stay as-is, using floor_positions)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ... keep your existing:
# generate_walls_from_floor()
# generate_wall_corners_from_floor()
# generate_underwall_ring()
# _generate_outline_layer()
# generate_outline_layers_from_floor()
# generate_frontfacing_wall_from_floor()
# generate_obstacles()
# generate_bitsandbobs()
# generate_floorcover()
# position_door()
# place_spawn_points()
# monster_spawns()
# beacon_spawns()
# _on_all_beacons_lit()
# _on_door_open_area_body_entered()

# -------------------------------------------------------------------
# FLOOR-DRIVEN WALLS / CORNERS / OUTLINES / FRONT-FACING WALL
# -------------------------------------------------------------------
# Build Previous Room Lookup Sets to Prevent Overlap: 
# Previous Floor :
func build_previous_floor_set() -> Dictionary:
	var s = {}
	for world_pos in previous_floor_world_positions:
		var local_pos = %TileMapFloor.to_local(world_pos)
		var cell = %TileMapFloor.local_to_map(local_pos)
		s[cell] = true
	return s

# NOW CURRENT ROOM SETS :
func build_floor_set() -> Dictionary:
	var s = {}
	for p in floor_positions:
		s[p] = true
	return s
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# THIS FUNCTION HELPS (THROUGH WALL_POSITIONS ARRAY WITH LOCATIONING) TELL THE ROOM ITS DIMENISONS AND WHERE OUTLINES ETC SHOULD GO:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func generate_walls_from_floor() -> void:
	%TileMapWalls.clear()
	%TileMapUnderWalls.clear()
	wall_positions.clear()
	
	if theme != 1:
		return
		
	wall_source_id = 30
	var floor_set = build_floor_set()
	
	var directions = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]
	
	for p in floor_positions:
		for d in directions:
			var npos = p + d
			if not floor_set.has(npos):
				if not wall_positions.has(npos):
					wall_positions.append(npos)
					var atlas_x = randi_range(2, 3)
					var atlas_y = 0
					var alt = randi_range(0, 3)
					%TileMapWalls.set_cell(npos, wall_source_id, Vector2i(atlas_x, atlas_y), alt)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# THESE FUNCTIONS ARE PURELY FOR THE BACKGROUND DARKNESS TEXTURE AESTHETIC : (TILEMAP MODULATES CAN BE CHANGED FOR EACH BIOME/THEME)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func generate_wall_corners_from_floor() -> void:
	%TileMapWallCorners.clear()
	
	if theme != 1:
		return
		
	corner_source_id = 40
	var floor_set = build_floor_set()
	
	var diagonals = [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1)
	]
	
	for p in floor_positions:
		for d in diagonals:
			var diag = p + d
			if floor_set.has(diag):
				continue
				
			var side1 = Vector2i(d.x, 0)
			var side2 = Vector2i(0, d.y)
			var has_side1 = floor_set.has(p + side1)
			var has_side2 = floor_set.has(p + side2)
			
			if has_side1 and has_side2:
				var atlas_x = randi_range(0, 3)
				var atlas_y = 0
				var alt = 0
				
				if d.x == -1 and d.y == -1:
					alt = 1 # top-left
				elif d.x == 1 and d.y == -1:
					alt = 0 # top-right
				elif d.x == -1 and d.y == 1:
					alt = 3 # bottom-left
				elif d.x == 1 and d.y == 1:
					alt = 2 # bottom-right
				%TileMapWallCorners.set_cell(diag, corner_source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_underwall_ring() -> void:
	%TileMapUnderWalls.clear()
	
	var floor_set = build_floor_set()
	if floor_positions.is_empty():
		return
		
	# How thick the dark ring should be
	var ring_thickness = 30
	
	# Compute bounding box of the floor
	var min_x = floor_positions[0].x
	var max_x = floor_positions[0].x
	var min_y = floor_positions[0].y
	var max_y = floor_positions[0].y
	
	for p in floor_positions:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
		
	# Expand the bounding box outward
	min_x -= ring_thickness
	max_x += ring_thickness
	min_y -= ring_thickness
	max_y += ring_thickness
	
	# Fill everything outside the floor with dark tiles
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)
			
			# Skip floor
			if floor_set.has(pos):
				continue
				
			# Skip walls
			if wall_positions.has(pos):
				continue
				
			# Skip if already placed
			if %TileMapUnderWalls.get_cell_source_id(pos) != -1:
				continue
				
			# Choose your dark underwall tile here
			var atlas_x = randi_range(2, 3)
			var atlas_y = 0
			var alt = randi_range(0, 3)
			print("Placing underwall at: ", pos)
			%TileMapUnderWalls.set_cell(pos, 30, Vector2i(atlas_x, atlas_y), alt)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OUTLINE LAYER AND FRONTFACING WALL FUNCTIONS ARE FOR CREATING THE PERIMETER OF THE ROOM, THEY ARE DEPENDENT ON THE "BUILD_FLOOR_SET()" FUNCTION TO TELL THEM WHERE THEY SHOULD BE,
# THE OUTLINE LAYER IN PARTICULAR ALSO USES THE "BUILD_PREVIOUS_SETS" SO THAT NEW ROOM OUTLINE TILES DO NOT OVERLAP THE OLD ROOMS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _generate_outline_layer(tilemap: TileMapLayer, source_id: int, offset: int) -> void:
	tilemap.clear()
	if theme != 1:
		return
		
	var old_floor_set = build_previous_floor_set()
	
	var floor_set = build_floor_set()
	
	for p in floor_positions:
		var x = p.x
		var y = p.y
		# If its the darker outline then it needs to register the front facing walls one y value down from itself :
		var neighbors = [
			Vector2i(x, y - offset),
			Vector2i(x, y + offset),
			Vector2i(x - offset, y),
			Vector2i(x + offset, y),
		]
		if tilemap == %TileMapRoomDarkerOutline :
			neighbors = [
				Vector2i(x, y - offset + 1),
				Vector2i(x, y + offset - 1),
				Vector2i(x - offset, y),
				Vector2i(x + offset, y),
			]
		for npos in neighbors:
			# Skip if it's floor
			if floor_set.has(npos):
				continue
			
			if old_floor_set.has(npos) :
				continue
			# Skip if this outline layer already placed something here
			#if tilemap.get_cell_source_id(npos) != -1:
				#continue
			# Skip ONLY if a frontwall occupies this tile
			if %TileMapFrontFaceWall.get_cell_source_id(npos) != -1:
				continue
			if %TileMapFrontFaceWall.get_cell_source_id(npos + Vector2i(0, -1)) != -1:
				continue
			if %TileMapFrontFaceWall.get_cell_source_id(npos + Vector2i(0, -2)) != -1:
				continue
			if %TileMapFrontFaceWall.get_cell_source_id(npos + Vector2i(0, +1)) != -1:
				continue
			
			# Place outline tile
			var atlas_x = randi_range(0, 3)
			var atlas_y = randi_range(0, 6)
			var alt = randi_range(0, 7)
			tilemap.set_cell(npos, source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_outline_layers_from_floor() -> void:
	if first_room or theme != 1:
		return
	room_outline_source_id = 70
	_generate_outline_layer(%TileMapRoomOutline, room_outline_source_id, 1)
	_generate_outline_layer(%TileMapRoomDarkerOutline, room_outline_source_id, 3)

func generate_frontfacing_wall_from_floor() -> void:
	%TileMapFrontFaceWall.clear()
	if theme != 1:
		return
	wall_source_id = 80
	var floor_set = build_floor_set()
	for w in wall_positions:
		var below = w + Vector2i(0, 1)
		var above = w + Vector2i(0, -1)
		# Only place a front-facing wall where:
		# - There is floor below (so it's a real wall edge)
		# - There is NOT floor above (so it's exposed)
		if not floor_set.has(below):
			continue
		if floor_set.has(above):
			continue
		var front_pos = w + Vector2i(0, -1)
		var atlas_x = randi_range(0, 4)
		var atlas_y = 0
		var alt = randi_range(0, 1)

		%TileMapFrontFaceWall.set_cell(front_pos, wall_source_id, Vector2i(atlas_x, atlas_y), alt)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OBSTACLES / BITS / FLOOR COVER { THESE USE FLOOR POSITIONS, WALL POSITIONS, AND THEIR OWN ALGORITHMS (INCLUDING NOISE) TO GENERATE AS NEEDED
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func generate_obstacles() -> void:
	if theme != 1:
		return
	var obstacle_spawn_chance = 0.01
	obstacle_source_id = 10
	for p in floor_positions:
		if randf() < obstacle_spawn_chance:
			var atlas_x = randi_range(0, 1)
			var atlas_y = randi_range(0, 1)
			var alt = randi_range(0, 1)
			%TileMapObstacles.set_cell(p, obstacle_source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_bitsandbobs() -> void:
	if theme != 1:
		return
	bitsandbobs_source_id = 20
	var attempts = int(floor_positions.size() * 0.02)
	for i in range(attempts):
		var pos: Vector2i = floor_positions.pick_random()
		if is_near_door(pos.x, pos.y):
			continue
		if %TileMapBitsandBobs.get_cell_source_id(pos) != -1:
			continue
		var atlas_x = randi_range(0, 5)
		var atlas_y = randi_range(0, 1)
		var alt = randi_range(0, 1)
		%TileMapBitsandBobs.set_cell(pos, bitsandbobs_source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_floorcover() -> void:
	if theme != 1:
		return
	var floorcover_source_id = 60
	var categories = {
		"cobwebs": 0,
		"hay": 1,
		"gold": 2,
		"mushrooms": 3
	}
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.4
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	var cluster_count = int(floor_positions.size() * 0.025)
	
	for i in range(cluster_count):
		var center: Vector2i = floor_positions.pick_random()
		var cx = center.x
		var cy = center.y
		var d = noise.get_noise_2d(float(cx), float(cy))
		if d < -0.1:
			continue
			
		var chosen_category = weighted_category_choice()
		var atlas_y = categories[chosen_category]
		var cluster_radius = randi_range(2, 5)
		var tile_count = randi_range(2, 7)
		
		for j in range(tile_count):
			var angle = randf() * TAU
			var dist = randf() * float(cluster_radius)
			var ox = int(round(cos(angle) * dist))
			var oy = int(round(sin(angle) * dist))
			var x = cx + ox
			var y = cy + oy
			var pos = Vector2i(x, y)
			
			if not floor_positions.has(pos):
				continue
				
			if chosen_category == "cobwebs" and not is_near_wall(x, y):
				continue
				
			if chosen_category == "mushrooms" and is_near_door(x, y):
				continue
				
			if %TileMapFloorCover.get_cell_source_id(pos) != -1:
				continue
				
			var atlas_x = weighted_atlas_x(chosen_category)
			var alt = randi_range(0, 7)
			
			%TileMapFloorCover.set_cell(pos, floorcover_source_id, Vector2i(atlas_x, atlas_y), alt)

func weighted_category_choice() -> String:
	var roll = randf()
	if roll < 0.10:
		return "gold"
	elif roll < 0.35:
		return "hay"
	elif roll < 0.75:
		return "mushrooms"
	else:
		return "cobwebs"

func weighted_atlas_x(category: String) -> int:
	match category:
		"mushrooms":
			return randi_range(0, 3)
		"gold":
			return randi_range(0, 3)
		"hay":
			return randi_range(0, 3)
		"cobwebs":
			return randi_range(0, 3)
		_:
			return randi_range(0, 3)

func is_near_wall(x: int, y: int) -> bool:
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			var pos = Vector2i(x + ox, y + oy)
			if %TileMapWalls.get_cell_source_id(pos) != -1:
				return true
	return false

func is_near_door(x: int, y: int) -> bool:
	# Stub – wire into your actual door logic if needed
	return false
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DOOR POSITIONING { CRUCIAL TO THE SUCCESSFUL CONNECTION OF EACH ROOM AND EACH DOOR COMMUNICATES TO THE NEXT ROOM WHERE TO BUILD FROM IN THE GLOBAL WORLDSPACE }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func position_door() -> void:
	if floor_positions.is_empty():
		return
		
	# 1. Find the topmost floor row (smallest y)
	var min_y = floor_positions[0].y
	for p in floor_positions:
		if p.y < min_y:
			min_y = p.y
		
	# 2. Collect all floor tiles on that row
	var top_row: Array[Vector2i] = []
	for p in floor_positions:
		if p.y == min_y:
			top_row.append(p)
		
	if top_row.is_empty():
		return
		
	# 3. Sort by x and pick the center tile
	top_row.sort_custom(func(a, b): return a.x < b.x)
	var door_tile: Vector2i = top_row[top_row.size() / 2]
	
	# 4. Convert tile → world position using the tilemap's transform
	var local_pixel = %TileMapFloor.map_to_local(door_tile)
	var world_pos = %TileMapFloor.to_global(local_pixel)
	
	# 5. Move the door there
	%DoorArea.global_position = world_pos
	
	# 6. Clear front-facing walls around the door
	var wall_map = %TileMapFrontFaceWall
	var local_pos = wall_map.to_local(world_pos)
	var door_cell = wall_map.local_to_map(local_pos)
	
	for ox in range(-1, 2):
		for oy in range(-3, 2):
			wall_map.set_cell(door_cell + Vector2i(ox, oy), -1)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SPAWNING INTERACTABLES { THIS IS WHERE ALL IN-GAME ASSETS THAT CAN BE INTERACTED WITH ARE SPAWNED, LIKE CLUTTER ETC, THEY ARE DEPENDENT ON FLOOR POSITIONS AND WALL POSITIONS }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func pick_spawn_positions() -> Array[Vector2i]:
	var shuffled = floor_positions.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, spawnpoints)

func place_spawn_points() -> void:
	var positions = pick_spawn_positions()
	for i in range(spawnpoints):
		var spawn_node = %SpawnPoints.get_child(i)
		var tile_pos: Vector2i = positions[i]
		var local_pixel = %TileMapFloor.map_to_local(tile_pos)
		var world_pos = get_tree().current_scene.to_global(local_pixel)
		spawn_node.global_position = world_pos

func monster_spawns() -> void:
	if theme == 1:
		var ogre_amount = randi_range(1, 3)
		for i in range(ogre_amount):
			var new_ogre = preload("res://Scenes/ogre.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_ogre.global_position = spawn_node.global_position
			add_child(new_ogre)

func beacon_spawns() -> void:
	if theme == 1:
		var beacon_amount = randi_range(1, 4)
		for i in range(beacon_amount):
			var new_beacon = preload("res://Scenes/brazier.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_beacon.global_position = spawn_node.global_position
			add_child(new_beacon)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SIGNALS FOR GAMEPLAY USAGE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_all_beacons_lit() -> void:
	%DoorStopperCollision.set_deferred("disabled", true)
	room_complete = true

func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and not already_opened and room_complete:
		already_opened = true
		%DoorSprite.play("DarkSteelSmashed")
		var new_room = preload("res://Scenes/procedural_room.tscn").instantiate()
		new_room.door_origin = %DoorArea.global_position
		new_room.z_index = 2
		new_room.first_room = false
		
		var world_floor_positions: Array[Vector2] = []
		for p in floor_positions:
			var local_pixel = %TileMapFloor.map_to_local(p)
			var world_pos = %TileMapFloor.to_global(local_pixel)
			world_floor_positions.append(world_pos)
		new_room.previous_floor_world_positions = world_floor_positions
		
		get_tree().current_scene.call_deferred("add_child", new_room)
