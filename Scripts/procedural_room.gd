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
var room_complexity = -0.45 # -1 is super open, simple space (boss) / -0.05 is super complex, (tight)
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
var protected_cells : Array[Vector2i] = []
var previous_frontwall_world_positions : Array[Vector2] = []
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
	# Door :
	%DoorArea.material = %DoorArea.material.duplicate()
	%DoorArea.add_to_group("doors")
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	
	_choose_room_type_and_size()
	theme = 1
	
	# FLOOR GENERATION
	generate_floor()
	_smooth_floor(2)
	_raggedize_edges()
	_widen_narrow_passages()
	_ensure_reachable_floor()
	
	# NOW that floor exists, align room to previous door
	if first_room == false :
		_position_room_relative_to_door()
		_register_protected_door_area()
	
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
	environmental_lights_spawns()
	moonlight_spawns()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ROOM TYPE + SIZE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _choose_room_type_and_size() -> void:
	if first_room:
		room_type = 2
		width = randi_range(14, 18) * 1.25
		height = randi_range(18, 30) * 1.25
	else:
		if room_type == 0:
			room_type = randi_range(1, 9) * 1.25
			
		match room_type:
			1:
				width = randi_range(32, 52) * 1.25
				height = randi_range(22, 34) * 1.25
			2:
				width = randi_range(14, 20) * 1.25
				height = randi_range(24, 40) * 1.25
			3,4,5,6,7,8,9:
				width = randi_range(32, 52) * 1.25
				height = randi_range(22, 36) * 1.25
			_:
				width = randi_range(32, 48) * 1.25
				height = randi_range(22, 34) * 1.25

func _position_room_relative_to_door() -> void:
	if door_origin == null:
		return
		
	# 1. Find the lowest floor tile in the new room
	var lowest_tile: Vector2i = _get_lowest_floor_tile()
	
	# 2. Convert that tile to local/world space
	var lowest_local: Vector2 = %TileMapFloor.map_to_local(lowest_tile)
	
	# 3. Compute the offset needed to align it to the old door
	var offset = door_origin - lowest_local
	
	# 4. Move the entire room so the lowest tile sits exactly at the door
	global_position = offset

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
		1:
			_generate_cave_system()          # natural Stardew-like cave
		2:
			_generate_cave_with_human_room() # cave + carved room
		3:
			_generate_mixed_cave()           # multiple chambers + rooms
		_:
			_generate_cave_system()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# WIDEN NARROW PASSAGES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _widen_narrow_passages() -> void:
	var floor_set = build_floor_set()
	var to_add = []
	var widen_value = 2 # Default = 2 
	for p in floor_positions:
		var neighbors = 0
		for d in [Vector2i(widen_value,0), Vector2i(-widen_value,0), Vector2i(0,widen_value), Vector2i(0,-widen_value)]:
			if floor_set.has(p + d):
				neighbors += 1
				
		if neighbors == 1:
			for d in [Vector2i(widen_value,0), Vector2i(-widen_value,0), Vector2i(0,widen_value), Vector2i(0,-widen_value)]:
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

# ---------------------------------------------------------
# CAVE SYSTEM GENERATION (STARDEW-LIKE)
# ---------------------------------------------------------

func _generate_cave_system() -> void:
	var chambers: Array[Vector2i] = []
	var chamber_count = randi_range(3, 6)

	for i in range(chamber_count):
		chambers.append(Vector2i(
			randi_range(int(width * 0.2), int(width * 0.8)),
			randi_range(int(height * 0.2), int(height * 0.8))
		))

	for c in chambers:
		_carve_chamber(c, randi_range(6, 12))
		
	for i in range(chambers.size() - 1):
		_carve_tunnel(chambers[i], chambers[i + 1], 3)
		
	if chambers.size() > 2 and randf() < 0.6:
		_carve_tunnel(chambers[0], chambers[chambers.size() - 1], 3)
		
	for i in range(randi_range(3, 7)):
		var c = floor_positions.pick_random()
		_carve_chamber(c, randi_range(3, 6))
		
	_carve_negative_space()
	_force_central_chamber()

func _generate_cave_with_human_room() -> void:
	_generate_cave_system()
	
	var cx = width / 2
	var cy = randi_range(int(height * 0.3), int(height * 0.6))
	var room_w = randi_range(10, 18)
	var room_h = randi_range(8, 14)

	for x in range(cx - room_w / 2, cx + room_w / 2):
		for y in range(cy - room_h / 2, cy + room_h / 2):
			_add_floor(Vector2i(x, y))

	var attach_point = Vector2i(cx, cy + room_h / 2 + 2)
	var nearest = _find_nearest_floor(attach_point)
	if nearest != null:
		_carve_tunnel(attach_point, nearest, 3)

func _generate_mixed_cave() -> void:
	_generate_cave_system()
	
	var extra_rooms = randi_range(1, 3)
	for i in range(extra_rooms):
		var base = floor_positions.pick_random()
		var room_w = randi_range(8, 14)
		var room_h = randi_range(6, 10)
		var offset = Vector2i(
			randi_range(-room_w, room_w),
			randi_range(-room_h, room_h)
		)
		var cx = base.x + offset.x
		var cy = base.y + offset.y
		
		for x in range(cx - room_w / 2, cx + room_w / 2):
			for y in range(cy - room_h / 2, cy + room_h / 2):
				_add_floor(Vector2i(x, y))

# ---------------------------------------------------------
# CAVE HELPERS
# ---------------------------------------------------------

func _carve_chamber(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue
			if Vector2(x - center.x, y - center.y).length() <= radius:
				_add_floor(Vector2i(x, y))

func _carve_tunnel(a: Vector2i, b: Vector2i, width_radius = 3) -> void:
	var x = a.x
	var y = a.y
	
	while x != b.x or y != b.y:
		for ox in range(-width_radius, width_radius + 1):
			for oy in range(-width_radius, width_radius + 1):
				if Vector2(ox, oy).length() <= width_radius:
					var px = x + ox
					var py = y + oy
					if px >= 0 and px < width and py >= 0 and py < height:
						_add_floor(Vector2i(px, py))
						
		if x < b.x: x += 1
		elif x > b.x: x -= 1
		
		if y < b.y: y += 1
		elif y > b.y: y -= 1

func _carve_negative_space() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05

	for p in floor_positions.duplicate():
		if noise.get_noise_2d(p.x, p.y) < room_complexity :
			floor_positions.erase(p)
			%TileMapFloor.set_cell(p, -1)

func _force_central_chamber() -> void:
	var cx = width / 2
	var cy = height / 2
	var radius = int(min(width, height) * 0.15)

	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue
			if Vector2(x - cx, y - cy).length() <= radius:
				_add_floor(Vector2i(x, y))

func _find_nearest_floor(target: Vector2i) -> Vector2i:
	var best: Vector2i = Vector2i.ZERO
	var best_dist = INF
	for p in floor_positions:
		var d = target.distance_to(p)
		if d < best_dist:
			best_dist = d
			best = p
	return best

func _get_lowest_floor_tile() -> Vector2i:
	var lowest = floor_positions[0]
	for p in floor_positions:
		if p.y > lowest.y:
			lowest = p
	return lowest

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

# Previous Front-Facing Walls :
func build_previous_frontfacingwalls_set() -> Dictionary:
	var s = {}
	for world_pos in previous_frontwall_world_positions:
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
func _get_entry_floor_tile() -> Vector2i:
	if floor_positions.is_empty():
		return Vector2i.ZERO
	var floor_set = build_floor_set()
	# 1. Find the vertical center of the room
	var avg_x = 0
	for p in floor_positions:
		avg_x += p.x
	avg_x /= floor_positions.size()
	# 2. Find all tiles within a horizontal band around the center
	var band: Array[Vector2i] = []
	for p in floor_positions:
		if abs(p.x - avg_x) <= 4: # 8‑tile wide band
			band.append(p)
	# If the band is empty, fall back to all floor tiles
	if band.is_empty():
		band = floor_positions.duplicate()
	# 3. Find the highest reachable tile in that band
	var best = band[0]
	for p in band:
		if p.y < best.y:
			best = p
	return best

func _register_protected_door_area() -> void:
	if door_origin == null:
		return

	var local = %TileMapFloor.to_local(door_origin)
	var cell = %TileMapFloor.local_to_map(local)

	# Protect a small 3×3 area around the door
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			protected_cells.append(cell + Vector2i(ox, oy))

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
	var old_frontwall_set = build_previous_frontfacingwalls_set()
	
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
			if old_floor_set.has(npos + Vector2i(0, -1)) :
				continue
			if old_floor_set.has(npos + Vector2i(0, -2)) :
				continue
			if old_floor_set.has(npos + Vector2i(0, +1)) :
				continue
			
			if old_frontwall_set.has(npos) :
				continue
			if old_frontwall_set.has(npos + Vector2i(0, -1)) :
				continue
			if old_frontwall_set.has(npos + Vector2i(0, -2)) :
				continue
			if old_frontwall_set.has(npos + Vector2i(0, +1)) :
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
			
			if protected_cells.has(npos):
				continue
			if protected_cells.has(npos + Vector2i(0, -2)):
				continue
			if protected_cells.has(npos + Vector2i(0, -1)):
				continue
			if protected_cells.has(npos + Vector2i(-1, 0)):
				continue
			if protected_cells.has(npos + Vector2i(1, 0)):
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
	previous_frontwall_world_positions.clear()
	
	if theme != 1:
		return
	
	wall_source_id = 80
	var floor_set = build_floor_set()
	
	for w in wall_positions:
		var below = w + Vector2i(0, 1)
		var above = w + Vector2i(0, -1)
		
		if not floor_set.has(below):
			continue
		if floor_set.has(above):
			continue
		if protected_cells.has(above):
			continue
		
		var front_pos = w + Vector2i(0, -1)
		
		var atlas_x = randi_range(0, 4)
		var atlas_y = 0
		var alt = randi_range(0, 1)
		
		%TileMapFrontFaceWall.set_cell(front_pos, wall_source_id, Vector2i(atlas_x, atlas_y), alt)
		
		# Correct global position (same fix as spawnpoints)
		var local_pixel = %TileMapFrontFaceWall.map_to_local(front_pos)
		var world_pos = get_tree().current_scene.to_global(local_pixel)
		previous_frontwall_world_positions.append(world_pos)
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
	var count = min(spawnpoints, positions.size())
	for i in range(count):
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
			call_deferred("add_child", new_ogre)

func beacon_spawns() -> void:
	if theme == 1:
		var beacon_amount = randi_range(1, 4)
		for i in range(beacon_amount):
			var new_beacon = preload("res://Scenes/brazier.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_beacon.global_position = spawn_node.global_position
			add_child(new_beacon)

func environmental_lights_spawns():
	if theme != 1:
		return
		
	if previous_frontwall_world_positions.is_empty():
		return
	
	var walltorch_amount = randi_range(1, 4)
	var lights_node = %EnvironmentalLights
	
	var placed_positions: Array[Vector2] = []
	var min_distance = 48.0  # adjust to taste (pixels)
	
	for i in range(walltorch_amount):
		var attempts = 10  # avoid infinite loops
			
		while attempts > 0:
			attempts -= 1
			
			var pos = previous_frontwall_world_positions.pick_random()
			
			var too_close = false
			for existing in placed_positions:
				if existing.distance_to(pos) < min_distance:
					too_close = true
					break
			
			if too_close:
				continue  # try another position
			
			# Valid position → spawn torch
			var new_walltorch = preload("res://Scenes/wall_torch.tscn").instantiate()
			new_walltorch.global_position = pos
			lights_node.add_child(new_walltorch)
			
			placed_positions.append(pos)
			break

func moonlight_spawns():
	if theme != 1:
		return
	
	if floor_positions.is_empty():
		return
	
	var cluster_count = randi_range(0, 2)  # how many clumps
	var beams_per_cluster = randi_range(2, 5)
	var cluster_radius = 3                # tiles around the center
	var min_distance = 30.0                # pixel spacing
	var placed_positions: Array[Vector2] = []
	
	for c in range(cluster_count):
		# Pick a random floor tile as the cluster center
		var center_tile: Vector2i = floor_positions.pick_random()
		
		for i in range(beams_per_cluster):
			var attempts = 10
			
			while attempts > 0:
				attempts -= 1
				
				# Random offset around the cluster center
				var ox = randi_range(-cluster_radius, cluster_radius)
				var oy = randi_range(-cluster_radius, cluster_radius)
				var tile_pos = center_tile + Vector2i(ox, oy)
				
				# Must be valid floor
				if not floor_positions.has(tile_pos):
					continue
				
				# Avoid door area
				if is_near_door(tile_pos.x, tile_pos.y):
					continue
				
				# Convert tile → world
				var local_pixel = %TileMapFloor.map_to_local(tile_pos)
				var world_pos = get_tree().current_scene.to_global(local_pixel)
				
				# Spacing check
				var too_close = false
				for existing in placed_positions:
					if existing.distance_to(world_pos) < min_distance:
						too_close = true
						break
				
				if too_close:
					continue
				
				# Spawn moonlight beam
				var moonlight = preload("res://Scenes/outside_light.tscn").instantiate()
				moonlight.global_position = world_pos
				%EnvironmentalLights.add_child(moonlight)
				
				placed_positions.append(world_pos)
				break
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SIGNALS FOR GAMEPLAY USAGE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_all_beacons_lit() -> void:
	%DoorStopperCollision.set_deferred("disabled", true)
	room_complete = true
	# Door Flashes :
	%DoorFlashingTimer.start()

func _on_door_flashing_timer_timeout() -> void:
	flash_white()

func flash_white():
	if already_opened == false :
		var mat = %DoorArea.material
		if mat == null:
			return
			
		# Flash up to white
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_amount", 1.0, 0.3)
		
		# Fade back down
		tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)

func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and not already_opened and room_complete:
		%DoorFlashingTimer.stop()
		already_opened = true
		%DoorArea.remove_from_group("doors")
		%DoorArea.unlocked = true
		%DoorSprite.play("DarkSteelSmashed")
		var new_room = preload("res://Scenes/procedural_room.tscn").instantiate()
		new_room.door_origin = %DoorArea.global_position
		new_room.z_index = 0
		new_room.first_room = false
		
		# Send Old Floor Positions :
		var world_floor_positions: Array[Vector2] = []
		for p in floor_positions:
			var local_pixel = %TileMapFloor.map_to_local(p)
			var world_pos = %TileMapFloor.to_global(local_pixel)
			world_floor_positions.append(world_pos)
		new_room.previous_floor_world_positions = world_floor_positions
		
		# Send Old FrontWall Positions :
		var world_frontwall_positions: Array[Vector2] = []
		for p in world_frontwall_positions:
			var local_pixel = %TileMapFloor.map_to_local(p)
			var world_pos = %TileMapFloor.to_global(local_pixel)
			world_frontwall_positions.append(world_pos)
		new_room.previous_frontwall_world_positions = world_frontwall_positions
		
		get_tree().current_scene.call_deferred("add_child", new_room)
