extends Node2D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~wqww~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Source ID's :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Floor Tiles = ID 0-9                ID 0 = REG GRAY FLOOR / ID 1 = DIRT FLOOR / ID 2 = CLAY FLOOR
# Obstacle Tiles = ID 10-19
# BitsandBobs Tiles = ID 20-29
# Wall Tiles = ID 30-39
# Wall Corner Tiles = ID 40-49
# Door Tiles = ID 50-59
# Floor Cover (mushrooms etc) = ID 60-69
# Room Outline (cobblestone etc) = ID 70-79
# Front Facing Wall (mineshaft etc) = ID 80-89
# Exterior Plants (Menacing / Kind etc) = ID 90-99
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# VARIABLES :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
var floor_positions: Array[Vector2i] = []
# Floor Cluster Arrays (for visually correct spreading) :
var dirt_cluster = {}
var clay_cluster = {}

var wall_positions: Array[Vector2i] = []

var room_complete = false
var already_opened = false

var spawnpoints = 10

var room_type = 0

# Room Spawn Modifiers :
var dungeon_outline_plant_spawn_chance = 2 # Where higher is rarer. and 1 is everytime
var room_complexity = -0.45 # -1 is super open, simple space (boss) / -0.05 is super complex, (tight)
var floorcover_cluster_rate = 0.065 # The lower, the less clusters spawn in relation to the amount of floor tiles in the room
var floorcover_frequency = 0.4 # Default is 0.4, where 1.0 is maximum frequency and 0.0 is minimum
var bits_and_bobs_spawn_rate = 0.01 # Like above, the lower, the less likely to spawn in relation to the amount of floor tiles in the room
var obstacles_spawn_rate = 0.004 # The lower, the less obstacles are likely to spawn
var floor_interactable_spawn_chance = 0.010  # (where 1.0 is 100% chance per floor tile)
var max_wall_interactable_amount = 6000 # The max possible amount of wall interactables / number of floor tiles
var stepladder_spawn_rate = 9 # Where 1 is every time and the greater from 1 it is, the less likely aka 1/2 or 1/3 or 1/8...
var raggedize_level = 1.0 # Default at 0.25 where 0.0 is highly uniform and 1 is VERY ragged
var walls_obstruction_frequency = 0.08 # Default at 0.05, where 1.0 is a much higher noise chance of spawning negative wall obstructions compared to 0 (next to none)
var chamber_amount = randi_range(1, 7) # Default between 3 and 6, where more means a bigger cave
var narrowness_widen_value = 1.5 # Default is 2, the higher, the wider each narrower part of a cave

var beacon_amount = randi_range(2, 5)

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
var last_room = false
var stepladder_chance = 1
var protected_cells : Array[Vector2i] = []
var previous_frontwall_world_positions : Array[Vector2] = []
var previous_floor_world_positions: Array[Vector2] = []
var door_origin = Vector2.ZERO
var new_door_y = 99999
var width = 32
var height = 18

# Monster Spawning Dictionary :
var SPAWN_GROUPS = {
	1: { # Goblin / Ogre / Wolf room
		"weights": {
			"goblin": 2,
			"ogre": 1,
			"dire_wolf": 1
		},
		"min_multiplier": 1,
		"max_multiplier": 3
	},
	2: { # Draugr / Machines
		"weights": {
			"draugr": 2,
			"grindstonter": 1
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	3: { # Witches only
		"weights": {
			"witch": 3
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	4: { # Goblins / Mudcrabs
		"weights": {
			"goblin": 3,
			"mud_crab": 1,
		},
		"min_multiplier": 2,
		"max_multiplier": 3
	},
	5: { # Wolves
		"weights": {
			"dire_wolf": 2,
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	6: { # Draugr / Mudcrab
		"weights": {
			"draugr": 2,
			"mud_crab": 1
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	7: { # Draugr / Witch
		"weights": {
			"draugr": 2,
			"witch": 1
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	8: { # Wolf / Mudcrab
		"weights": {
			"dire_wolf": 1,
			"mud_crab": 1
		},
		"min_multiplier": 1,
		"max_multiplier": 2
	},
	9: { # Machines / Mudcrab
		"weights": {
			"grindstonter": 2,
			"mud_crab": 1
		},
		"min_multiplier": 2,
		"max_multiplier": 3
	}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PLAY ALL INITIAL EXECUTABLES NEEDED FOR ROOM :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ready() -> void:
	randomize()
	
	$".".add_to_group("rooms")
	EventBus.total_rooms += 1
	# Door :
	%DoorArea.material = %DoorArea.material.duplicate()
	%DoorArea.add_to_group("doors")
	%TileMapFloor.add_to_group("floors")
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	
	# If last room then prepare Door to have light :
	if EventBus.last_room == true :
		last_room = true
		%FinishLight1.enabled = true
		%FinishLight2.enabled = true
		%FinishLight3.enabled = true
		# Emit a signal to tell the loading screen it's pretty much ready :
		EventBus.last_room_loaded.emit()
		var theme = EventBus.current_theme
		if theme == 1 : # Then DarkSteel Door! :
			%DoorSprite.play("DarkSteelFinishDoor")
		elif theme == 2 : # Ice :
			%DoorSprite.play("DarkSteelFinishDoorIce")
		elif theme == 3 : # Hell :
			%DoorSprite.play("DarkSteelFinishDoorHell")
		elif theme == 4 : # Overgrown :
			%DoorSprite.play("DarkSteelFinishDoorOvergrown")
	
	_choose_room_type_and_size()
	
	# Adjust Room For Theme:
	themify()
	
	
	
	# FLOOR GENERATION
	generate_floor()
	diversify_room_with_scalers()
	_raggedize_edges()
	_smooth_floor(5)
	_ensure_reachable_floor()
	_widen_narrow_passages()
	generate_floor_variant_clusters()
	
	# NOW that floor exists, align room to previous door
	if first_room == false :
		await get_tree().process_frame
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
	generate_exterior_plants_outline()
	place_spawn_points()
	monster_spawns()
	beacon_spawns()
	generate_wall_interactables()
	generate_floor_interactables()
	moonlight_spawns()
	fog_cluster_spawns()
	
	_ensure_door_corridor_clear()
	_ensure_room_opening_clear()
	# Stepladder Chance :
	if stepladder_chance != 0 :
		if randi_range(1, stepladder_spawn_rate) == 1 :
			spawn_stepladder()
		
	# Pre-Generate Next Room :
	spawn_next_room()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ROOM TYPE + SIZE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func diversify_room_with_scalers() :
	dungeon_outline_plant_spawn_chance = randf_range(1.5, 2.5) # Where higher is rarer. and 1 is everytime
	room_complexity = randf_range(-0.75, -0.25) # -1 is super open, simple space (boss) / -0.05 is super complex, (tight)
	floorcover_cluster_rate = randf_range(0.05, 0.1) # The lower, the less clusters spawn in relation to the amount of floor tiles in the room
	floorcover_frequency = randf_range(0.25, 0.55) # Default is 0.4, where 1.0 is maximum frequency and 0.0 is minimum
	bits_and_bobs_spawn_rate = randf_range(0.005, 0.015) # Like above, the lower, the less likely to spawn in relation to the amount of floor tiles in the room
	obstacles_spawn_rate = randf_range(0.002, 0.006) # The lower, the less obstacles are likely to spawn
	floor_interactable_spawn_chance = randf_range(0.05, 0.015) # (where 1.0 is 100% chance per floor tile)
	max_wall_interactable_amount = randi_range(4000, 8000) # The max possible amount of wall interactables / number of floor tiles
	stepladder_spawn_rate = 9 # Where 1 is every time and the greater from 1 it is, the less likely aka 1/2 or 1/3 or 1/8...
	raggedize_level = randf_range(0.5, 0.8) # Default at 0.25 where 0.0 is highly uniform and 1 is VERY ragged
	walls_obstruction_frequency = randf_range(0.03, 0.055) # Default at 0.05, where 1.0 is a much higher noise chance of spawning negative wall obstructions compared to 0 (next to none)
	chamber_amount = randi_range(1, 7) # Default between 3 and 6, where more means a bigger cave
	narrowness_widen_value = randf_range(1.5, 3.5) # Default is 2, the higher, the wider each narrower part of a cave

func _choose_room_type_and_size() -> void:
	if first_room:
		room_type = 2
		width = randi_range(14, 18) * 1.25
		height = randi_range(18, 30) * 1.25
	else:
		if room_type == 0:
			room_type = randi_range(1, 9)
			
		match room_type:
			1:
				width = randi_range(32, 52) * 1.25
				height = randi_range(22, 34) * 1.25
			2:
				width = randi_range(14, 20) * 1.25
				height = randi_range(24, 40) * 1.25
			3, 4, 5: # Corridor
				width = randi_range(7, 9) * 1.25
				height = randi_range(9, 15) * 1.25
			6,7,8,9:
				width = randi_range(32, 52) * 1.25
				height = randi_range(22, 36) * 1.25
			_:
				width = randi_range(32, 48) * 1.25
				height = randi_range(22, 34) * 1.25

func _position_room_relative_to_door() -> void:
	if door_origin == Vector2.ZERO:
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
	#if EventBus.current_theme == 1:
	var atlas_x = randi_range(0, 3)
	var alt = randi_range(0, 3)
	%TileMapFloor.set_cell(p, 0, Vector2i(atlas_x, 0), alt)

func generate_floor() -> void:
	floor_positions.clear()
	%TileMapFloor.clear()

	match room_type:
		1:
			_generate_cave_system()          # natural 
		2:
			_generate_cave_with_human_room() # cave + carved room
		3:
			_generate_mixed_cave()           # multiple chambers + rooms
		_:
			_generate_cave_system()     # heavily randomised cave look

# This Function Generates Variants Within The Floor Using A Secondary Set Such As Dirt etc, then a 3rd Set Such as Clay, 
# These have their own unique terrain ID's within %TileMapFloor e.g. regular stone = 0, dirt = 1, clay = 2
func generate_floor_variant_clusters():
	# Generate Noise to help with natural irregularity :
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.12
	
	#if EventBus.current_theme == 1 : # DIRT CLUSTER AND THEN CLAY WITHIN THE DIRT
	# DIRT :
	var cluster_count = randi_range(5, 10)
	var clay_cluster_count = randi_range(3, 6)
		
	for i in range(cluster_count):
		var center = floor_positions.pick_random()
		
		# 1. Build cluster set using random walk and our globally declared dirt cluster array
		var walker = center
		dirt_cluster[walker] = true
		
		var steps = randi_range(4, 24)  # how big/small the clusters are!
		
		for s in range(steps):
			var dir = [
				Vector2i.LEFT,
				Vector2i.RIGHT,
				Vector2i.UP,
				Vector2i.DOWN
			].pick_random()
			
			walker += dir
			
			var radius = randi_range(2, 3)
			
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var np = walker + Vector2i(dx, dy)
					if floor_positions.has(np):
						var n = noise.get_noise_2d(np.x, np.y)
						if n > randf() * 0.35: # irregular threshold
							dirt_cluster[np] = true
	# CLAY (Generating Within Dirt) :
	for i in range(clay_cluster_count):
		var center = dirt_cluster.keys().pick_random()
		
		var walker = center
		clay_cluster[walker] = true
		
		var steps = randi_range(100, 120)
		
		for s in range(steps):
			var dir = [
				Vector2i.LEFT,
				Vector2i.RIGHT,
				Vector2i.UP,
				Vector2i.DOWN
			].pick_random()
			
			walker += dir
			
			# Only allow clay to grow inside dirt
			if not dirt_cluster.has(walker):
				continue
			
			var radius = randi_range(1, 1)
			
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var np = walker + Vector2i(dx, dy)
					# Only place clay if all 4 neighbours are dirt too
					if dirt_cluster.has(np) and dirt_cluster.has(np + Vector2i.LEFT) and dirt_cluster.has(np + Vector2i.RIGHT) and dirt_cluster.has(np + Vector2i.UP) and dirt_cluster.has(np + Vector2i.DOWN):
						var n = noise.get_noise_2d(np.x, np.y)
						if n > randf() * 0.05:
							clay_cluster[np] = true
		
	# Autotile The Dirt Cluster :
	for p in dirt_cluster.keys():
		var atlas = get_tile_for_cluster(p, dirt_cluster)
		%TileMapFloor.set_cell(p, 1, atlas)
		
	# Autotile The Clay Clusters Within Dirt :
	for p in clay_cluster.keys():
		var atlas = get_tile_for_cluster(p, clay_cluster)
		%TileMapFloor.set_cell(p, 2, atlas)

# THIS IS ALWAYS DELETABLE IF IT DOESN'T WORK BUT THIS BASICALLY ALLOWS US TO SORT WHAT TILE SHOULD BE PLACED WHERE BY HAND RATHER THAN RELYING ON THE GODOT AUTOTILER :
func get_tile_for_cluster(p: Vector2i, cluster: Dictionary) -> Vector2i:
	# Define Tiles :
	var FULL = [Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)]
	var EDGE_LEFT = [Vector2i(0,1)]
	var EDGE_RIGHT = [Vector2i(1,1)]
	var EDGE_TOP = [Vector2i(3,1)]
	var EDGE_BOTTOM = [Vector2i(2,1)]
	var CORNER_TL = [Vector2i(0,0)]
	var CORNER_TR = [Vector2i(1,0)]
	var CORNER_BL = [Vector2i(2,0)]
	var CORNER_BR = [Vector2i(3,0)]
	
	# Check neighbours inside the cluster :
	var up = cluster.has(p + Vector2i(0, -1))
	var down = cluster.has(p + Vector2i(0, 1))
	var left = cluster.has(p + Vector2i(-1, 0))
	var right = cluster.has(p + Vector2i(1, 0))
	
	# If the tile is fully surrounded :
	if up and down and left and right:
		return FULL.pick_random()
	
	# Corners :
	if not up and not left: return CORNER_TL.pick_random()
	if not up and not right: return CORNER_TR.pick_random()
	if not down and not left: return CORNER_BL.pick_random()
	if not down and not right: return CORNER_BR.pick_random()
	
	# Edges :
	if not left: return EDGE_LEFT.pick_random()
	if not right: return EDGE_RIGHT.pick_random()
	if not up: return EDGE_TOP.pick_random()
	if not down: return EDGE_BOTTOM.pick_random()
	
	return Vector2.ZERO

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# WIDEN NARROW PASSAGES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _widen_narrow_passages() -> void:
	var floor_set = build_floor_set()
	var to_add = []
	var widen_value = narrowness_widen_value
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
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
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
	var chamber_count = chamber_amount

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
	noise.frequency = walls_obstruction_frequency

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

func _smooth_floor(iterations = 5) -> void:
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
		if neighbors <= 2 and randf() < raggedize_level:
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
	
	#if EventBus.current_theme != 1:
		#return
		
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
	
	#if EventBus.current_theme != 1:
		#return
		
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
			%TileMapUnderWalls.set_cell(pos, 30, Vector2i(atlas_x, atlas_y), alt)

func themify() :
	if EventBus.current_theme == 2 : # Ice
		%TileMapFrontFaceWall.modulate = Color(0.004, 0.929, 0.855, 1.0)
		%TileMapRoomOutline.modulate = Color(0.004, 0.582, 0.582, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.002, 0.431, 0.431, 1.0)
		%TileMapFloor.modulate = Color(0.067, 0.988, 0.988)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapFloorCover.modulate = Color(0.067, 0.988, 0.988) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.517, 0.999, 0.996, 1.0)
		%EnvironmentalLights.modulate = Color(0.067, 0.988, 0.988)
		#%WallInteractables.modulate = Color(0.067, 0.988, 0.988)
		#%FloorInteractables.modulate = Color(0.067, 0.988, 0.988)
		%Mist.modulate = Color(0.067, 0.988, 0.988)
		%DoorArea.modulate = Color(0.067, 0.988, 0.988)
	
	if EventBus.current_theme == 3 : # Hell
		%TileMapFrontFaceWall.modulate = Color(0.995, 0.552, 0.554, 1.0)
		%TileMapRoomOutline.modulate = Color(0.779, 0.078, 0.207, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.506, 0.03, 0.12, 1.0)
		%TileMapFloor.modulate = Color(0.976, 0.192, 0.298, 1.0)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapFloorCover.modulate = Color(0.976, 0.192, 0.298, 1.0) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.992, 0.435, 0.454, 1.0)
		%EnvironmentalLights.modulate = Color(0.976, 0.192, 0.298, 1.0)
		#%WallInteractables.modulate = Color(0.976, 0.192, 0.298, 1.0)
		#%FloorInteractables.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%Mist.modulate = Color(0.976, 0.192, 0.298, 1.0)
		%DoorArea.modulate = Color(0.976, 0.192, 0.298, 1.0)
	
	
	if EventBus.current_theme == 4 : # Overgrown
		%TileMapFrontFaceWall.modulate = Color(0.0, 0.373, 0.103, 1.0)
		%TileMapRoomOutline.modulate = Color(0.0, 0.26, 0.061, 1.0)
		%TileMapRoomDarkerOutline.modulate = Color(0.0, 0.154, 0.024, 1.0)
		%TileMapFloor.modulate = Color(0.0, 0.306, 0.078, 1.0)
		# Maybes :
		%TileMapObstacles.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapBitsandBobs.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapFloorCover.modulate = Color(0.0, 0.306, 0.078, 1.0) # maybe not
		%TileMapExteriorPlants.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%EnvironmentalLights.modulate = Color(0.0, 0.306, 0.078, 1.0)
		#%WallInteractables.modulate = Color(0.0, 0.306, 0.078, 1.0)
		#%FloorInteractables.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%Mist.modulate = Color(0.0, 0.306, 0.078, 1.0)
		%DoorArea.modulate = Color(0.0, 0.306, 0.078, 1.0)

func themify_particular(entity) :
	if EventBus.current_theme == 2 :
		entity.modulate = Color(0.067, 0.988, 0.988)
	elif EventBus.current_theme == 3 :
		entity.modulate = Color(0.976, 0.192, 0.298, 1.0)
	elif EventBus.current_theme == 4 :
		entity.modulate = Color(0.0, 0.306, 0.078, 1.0)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OUTLINE LAYER AND FRONTFACING WALL FUNCTIONS ARE FOR CREATING THE PERIMETER OF THE ROOM, THEY ARE DEPENDENT ON THE "BUILD_FLOOR_SET()" FUNCTION TO TELL THEM WHERE THEY SHOULD BE,
# THE OUTLINE LAYER IN PARTICULAR ALSO USES THE "BUILD_PREVIOUS_SETS" SO THAT NEW ROOM OUTLINE TILES DO NOT OVERLAP THE OLD ROOMS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _generate_outline_layer(tilemap: TileMapLayer, source_id: int, offset: int) -> void:
	tilemap.clear()
	#if EventBus.current_theme != 1:
		#return
		
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
			if protected_cells.has(npos + Vector2i(1, -2)):
				continue
			if protected_cells.has(npos + Vector2i(-1, -2)):
				continue
			
			# Place outline tile
			var atlas_x = randi_range(0, 3)
			var atlas_y = randi_range(0, 6)
			var alt = randi_range(0, 7)
			tilemap.set_cell(npos, source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_outline_layers_from_floor() -> void:
	#if first_room or EventBus.current_theme != 1:
		#return
	room_outline_source_id = 70
	_generate_outline_layer(%TileMapRoomOutline, room_outline_source_id, 1)
	_generate_outline_layer(%TileMapRoomDarkerOutline, room_outline_source_id, 3)


func generate_exterior_plants_outline() -> void:
	%TileMapExteriorPlants.clear()
	
	#if EventBus.current_theme != 1 or first_room:
		#return
	
	var placed_plants = {}
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	
	var old_floor_set = build_previous_floor_set()
	var old_frontwall_set = build_previous_frontfacingwalls_set()
	var floor_set = build_floor_set()
	
	var source_id = 90 # Menacing Plants
	
	for p in floor_positions:
		var offset = 3  # x beyond your darker outline (which uses 3)
		var x = p.x
		var y = p.y
		
		var neighbors = [
			Vector2i(x, y - offset - 1),
			Vector2i(x, y - offset - 2),
			Vector2i(x, y + offset + 1),
			Vector2i(x - offset + 1 - randi_range(2, 3), y),
			Vector2i(x + offset - 1 + randi_range(2, 3), y),
		]
		
		for npos in neighbors:
			
			# Reject if too close to another plant
			if too_close_to_other_plants(placed_plants, npos, 2):
				continue
			
			# Skip if it's floor
			if floor_set.has(npos):
				continue
			
			# Skip entire x‑axis above the door
			if npos.y < new_door_y:
				continue
			
			# Skip if overlapping previous room floor (with vertical padding like outlines)
			if old_floor_set.has(npos):
				continue
			if old_floor_set.has(npos + Vector2i(0, -1)):
				continue
			if old_floor_set.has(npos + Vector2i(0, -2)):
				continue
			if old_floor_set.has(npos + Vector2i(0, 1)):
				continue
			
			# Skip if outline already placed here
			if %TileMapRoomOutline.get_cell_source_id(npos) != -1:
				continue
			#if %TileMapRoomDarkerOutline.get_cell_source_id(npos) != -1:
				#continue
			
			# Skip if overlapping previous frontwalls (with vertical padding)
			if old_frontwall_set.has(npos):
				continue
			if old_frontwall_set.has(npos + Vector2i(0, -1)):
				continue
			if old_frontwall_set.has(npos + Vector2i(0, -2)):
				continue
			if old_frontwall_set.has(npos + Vector2i(0, 1)):
				continue
			
			# Skip if front‑facing wall occupies this tile or its vertical neighbors
			if %TileMapFrontFaceWall.get_cell_source_id(npos) != -1:
				continue
			if %TileMapFrontFaceWall.get_cell_source_id(npos + Vector2i(0, -1)) != -1:
				continue
			if %TileMapFrontFaceWall.get_cell_source_id(npos + Vector2i(0, 1)) != -1:
				continue
			
			# Respect protected door area
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
			
			# Spread out with noise :
			if noise.get_noise_2d(npos.x, npos.y) > 0.25: # NOISE SCALER (Scales the chance that a plant can spawn!)
				continue
			
			if abs(npos.x - x) > abs(npos.y - y) :
				if randf() < 0.7: 
					continue
				
			# Finally, place plant tile
			if randi_range(1, dungeon_outline_plant_spawn_chance) == 1 : # (Chance of plants spawning)
				var atlas_x = randi_range(0, 3)   # Plant ATLAS
				var atlas_y = randi_range(0, 15)                 
				var alt = randi_range(0, 1)
				%TileMapExteriorPlants.set_cell(npos, source_id, Vector2i(atlas_x, atlas_y), alt)
				placed_plants[npos] = true

# Helper to stop plants spawning ontop of each other :
func too_close_to_other_plants(placed_plants: Dictionary, pos: Vector2i, radius = 2) -> bool:
	for p in placed_plants:
		if p.distance_to(pos) <= radius:
			return true
	return false

func generate_frontfacing_wall_from_floor() -> void:
	%TileMapFrontFaceWall.clear()
	previous_frontwall_world_positions.clear()
		
	#if EventBus.current_theme != 1:
		#return
	# Random wall texture picker :
	var random_wall_picker = randi_range(1, 4)
	if random_wall_picker == 1 : # Mineshaft
		wall_source_id = 80
	elif random_wall_picker == 2 : # Cobblestone Ragged
		wall_source_id = 81
	elif random_wall_picker == 3 : # Wood Planked Room
		wall_source_id = 82
	elif random_wall_picker == 4 : # Clean Stone Wall
		wall_source_id = 83
	var floor_set = build_floor_set()
	
	for w in wall_positions:
		var below = w + Vector2i(0, 1)
		var above = w + Vector2i(0, 0)
		
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
	#if EventBus.current_theme != 1:
		#return
	obstacle_source_id = 10
	for p in floor_positions:
		if randf() < obstacles_spawn_rate:
			if is_near_obstacle(p, 2): # If it's too near to furniture then stop:
				continue
			
			var atlas_x = randi_range(0, 5)
			var atlas_y = randi_range(0, 2)
			var alt = randi_range(0, 1)
			%TileMapObstacles.set_cell(p, obstacle_source_id, Vector2i(atlas_x, atlas_y), alt)

# Helps Figure out if something is neaar obstacles and so whether to avoid it etc :
func is_near_obstacle(pos: Vector2i, radius = 2) -> bool:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var check = pos + Vector2i(dx, dy)
			if %TileMapObstacles.get_cell_source_id(check) != -1:
				return true
	return false


func generate_bitsandbobs() -> void:
	#if EventBus.current_theme != 1:
		#return
	bitsandbobs_source_id = 20
	var attempts = int(floor_positions.size() * bits_and_bobs_spawn_rate)
	for i in range(attempts):
		var pos: Vector2i = floor_positions.pick_random()
		if is_near_door(pos.x, pos.y):
			continue
		if %TileMapBitsandBobs.get_cell_source_id(pos) != -1:
			continue
		var atlas_x = randi_range(0, 5)
		var atlas_y = randi_range(0, 3)
		var alt = randi_range(0, 1)
		%TileMapBitsandBobs.set_cell(pos, bitsandbobs_source_id, Vector2i(atlas_x, atlas_y), alt)

func generate_floorcover() -> void:
	#if EventBus.current_theme != 1:
		#return
	var floorcover_source_id = 60
	var categories = {
		"cobwebs": 0,
		"hay": 1,
		"corn": 2,
		"mushrooms": 3,
		"pebbles": 4,
		"moss": 5,
		"bones": 6,
		"wood_chippings": 7,
		"gold": 8,
		"blood": 9
	}
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = floorcover_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	var cluster_count = int(floor_positions.size() * floorcover_cluster_rate)
	
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
	if roll < 0.15:
		return "corn"
	elif roll < 0.3:
		return "mushrooms"
	elif roll < 0.45 :
		return "cobwebs"
	elif roll < 0.5 :
		return "blood"
	elif roll < 0.55:
		return "hay"
	elif roll < 0.65:
		return "pebbles"
	elif roll < 0.75:
		return "moss"
	elif roll < 0.85:
		return "bones"
	elif roll < 0.95:
		return "wood_chippings"
	else :
		return "gold"

func weighted_atlas_x(category: String) -> int:
	match category:
		"mushrooms":
			return randi_range(0, 3)
		"corn":
			return randi_range(0, 3)
		"hay":
			return randi_range(0, 3)
		"cobwebs":
			return randi_range(0, 3)
		"pebbles":
			return randi_range(0, 3)
		"moss":
			return randi_range(0, 3)
		"bones":
			return randi_range(0, 3)
		"wood_chippings":
			return randi_range(0, 3)
		"gold" :
			return randi_range(0, 3)
		"blood" :
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DOOR CLEARING SNAKE (Ensures Doors Are ALWAYS Clear of Blockades (unless blocked on purpose) 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ensure_door_corridor_clear() -> void:
	if floor_positions.is_empty():
		return

	var door_cell = _door_start_cell()

	# How deep into the room we guarantee clearance
	var depth = 12   # 6 tiles downward is plenty

	for i in range(depth):
		var row = door_cell + Vector2i(0, i)

		# Check a 2‑tile‑wide footprint (player width)
		for ox in range(0, 1):   # -1, 0, 1 → 3‑tile wide safety band
			var c = row + Vector2i(ox, 0)

			# Only clear if something is blocking AND it's inside the protected corridor
			if _is_blocking_for_player(c):
				_clear_blocking_in_door_corridor(c)


func _ensure_room_opening_clear() -> void:
	if floor_positions.is_empty():
		return
	
	# The “bottom” of the room (closest to previous door)
	var entry_cell: Vector2i = %TileMapFloor.local_to_map(to_local(door_origin))
	
	var depth = 7       # how many tiles far upward to clear
	
	for i in range(depth):
		# Move UPWARD from the lowest tile
		var row = entry_cell + Vector2i(0, -i)
		
		for ox in range(0, 2):
			var c = row + Vector2i(ox, 0)
			
			# Respect protected door area
			if protected_cells.has(c):
				continue
				
			if _is_blocking_for_player(c):
				_clear_blocking_in_room_opening(c)

func _door_start_cell() -> Vector2i:
	# DoorArea is already positioned in world space
	var local = %TileMapFloor.to_local(%DoorArea.global_position)
	return %TileMapFloor.local_to_map(local)

func _is_blocking_for_player(cell: Vector2i) -> bool:
	# Anything solid that would block a 2‑tile‑wide player
	if %TileMapWalls.get_cell_source_id(cell) != -1:
		return true
	if %TileMapFrontFaceWall.get_cell_source_id(cell) != -1:
		return true
	if %TileMapRoomOutline.get_cell_source_id(cell) != -1:
		return true
	if %TileMapRoomDarkerOutline.get_cell_source_id(cell) != -1:
		return true
	if %TileMapObstacles.get_cell_source_id(cell) != -1:
		return true
	# can add more here if needed (exterior plants, etc.)
	return false
#AND here
func _clear_blocking_in_door_corridor(cell: Vector2i) -> void:
	# Only clear tiles that are allowed to be removed in the doorway corridor
	%TileMapFrontFaceWall.set_cell(cell, -1)
	%TileMapObstacles.set_cell(cell, -1)
	%TileMapRoomOutline.set_cell(cell, -1)
	%TileMapRoomDarkerOutline.set_cell(cell, -1)
	%TileMapWalls.set_cell(cell, -1)

	# Ensure floor exists
	if not floor_positions.has(cell):
		_add_floor(cell)

func is_near_door(x: int, y: int) -> bool:
	var cell = Vector2i(x, y)
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			if protected_cells.has(cell + Vector2i(ox, oy)):
				return true
	return false

#all round here
func _clear_blocking_in_room_opening(cell: Vector2i) -> void:
	# Remove front walls + obstacles
	%TileMapFrontFaceWall.set_cell(cell, -1)
	%TileMapObstacles.set_cell(cell, -1)
	
	# Remove outlines ONLY if they are literally blocking the entry
	%TileMapRoomOutline.set_cell(cell, -1)
	%TileMapRoomDarkerOutline.set_cell(cell, -1)
	
	# Remove walls ONLY if they are directly blocking the entry
	%TileMapWalls.set_cell(cell, -1)
	
	# Ensure floor exists
	if not floor_positions.has(cell):
		_add_floor(cell)

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
			# and set as floor instead :
			%TileMapFloor.set_cell(door_cell + Vector2i(ox, oy), 0, Vector2i(randi_range(0, 3), 0), randi_range(0, 1))
	
	new_door_y = door_tile.y

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

# ~~~~~~~~~~~~~
# Monster Spawning

func monster_spawns() -> void:
	var group = SPAWN_GROUPS.get(room_type)
	
	if group == null:
		return
	
	var amount = randi_range((group["min_multiplier"] + width + height) / 25, (group["max_multiplier"] + width + height) / 20 + 2) 
	
	for i in range(amount):
		var monster_name = weighted_pick(group["weights"])
		spawn_monster(monster_name)

func spawn_monster(monster_name: String) -> void:
	var scene_path = "res://Scenes/Monsters/%s.tscn" % monster_name
	var monster = load(scene_path).instantiate()
	
	var rand = randi_range(0, %SpawnPoints.get_child_count() - 1)
	var spawn_node = %SpawnPoints.get_child(rand)
	
	monster.global_position = spawn_node.global_position
	call_deferred("add_child", monster)

func weighted_pick(weights: Dictionary) -> String:
	var total = 0
	for w in weights.values():
		total += w
	
	var roll = randi_range(1, total)
	var cumulative = 0
	
	for monster_name in weights.keys():
		cumulative += weights[monster_name]
		if roll <= cumulative:
			return monster_name
	
	return weights.keys()[0] # fallback
# ~~~~~~~~~~~~~

func beacon_spawns() -> void:
	#if EventBus.current_theme == 1:
		for i in range(beacon_amount):
			var new_beacon = preload("res://Scenes/brazier.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_beacon.global_position = spawn_node.global_position
			new_beacon.visible = false
			get_node("Beacons").add_child(new_beacon)

# Stepladder :
func spawn_stepladder() :
	#if EventBus.current_theme == 1:
		var new_stepladder = preload("res://Scenes/stepladder.tscn").instantiate()
		var rand = randi_range(1, spawnpoints)
		var spawn_node = %SpawnPoints.get_child(rand - 1)
		new_stepladder.global_position = spawn_node.global_position
		themify_particular(new_stepladder)
		add_child(new_stepladder)

func generate_wall_interactables():
	if previous_frontwall_world_positions.is_empty():
		return
	
	var wall_interactable_amount = randi_range((max_wall_interactable_amount * 0.6) / floor_positions.size(), max_wall_interactable_amount / floor_positions.size())
	
	var placed_positions: Array[Vector2] = []
	var min_distance = 48.0  # adjust to taste (pixels)
	
	for i in range(wall_interactable_amount):
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
			var new_walltorch = preload("res://Scenes/wall_interactables.tscn").instantiate()
			new_walltorch.global_position = pos
			%WallInteractables.add_child(new_walltorch)
			
			placed_positions.append(pos)
			break

func generate_floor_interactables() -> void:
	var used = {}
		
	for p in floor_positions:
		# Skip protected tiles (door area)
		if protected_cells.has(p):
			continue
		
		# Skip if Bits & Bobs already placed something here
		if %TileMapBitsandBobs.get_cell_source_id(p) != -1:
			continue
		
		# Skip if obstacles occupy this tile
		if %TileMapObstacles.get_cell_source_id(p) != -1:
			continue
		
		# Skip if already used by another interactable
		if used.has(p):
			continue
		
		# Random chance
		if randf() > floor_interactable_spawn_chance:
			continue
		
		# Convert tile → world
		var local_pixel = %TileMapFloor.map_to_local(p)
		var world_pos = get_tree().current_scene.to_global(local_pixel)
		
		# Spawn interactable
		var scene = preload("res://Scenes/floor_interactables.tscn")
		var inst = scene.instantiate()
		inst.global_position = world_pos
		%FloorInteractables.add_child(inst)
	
		# Mark tile as used
		used[p] = true

func moonlight_spawns():
	#if EventBus.current_theme != 1:
		#return
	
	if floor_positions.is_empty():
		return
	
	if randi_range(1, 3) == 2 : # Then natural light room!
		var cluster_count = randi_range(1, 3)  # how many clumps
		var beams_per_cluster = randi_range(2, 4)
		var cluster_radius = 2               # tiles around the center
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

func fog_cluster_spawns():
	if floor_positions.is_empty():
		return
	
	var cluster_count = randi_range(2, 4)     # number of fog clumps
	var fogs_per_cluster = randi_range(3, 7)  # how many fog sprites per clump
	var cluster_radius = 4                    # tiles around center
	var min_distance = 20.0                   # pixel spacing between fog sprites
	
	var placed_positions: Array[Vector2] = []
	
	for c in range(cluster_count):
		# Pick a random floor tile as the cluster center
		var center_tile: Vector2i = floor_positions.pick_random()
		
		for i in range(fogs_per_cluster):
			var attempts = 17
			
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
				
				# Spawn fog cluster sprite
				var fog = preload("res://Scenes/fog_cluster.tscn").instantiate()
				fog.global_position = world_pos
				%Mist.add_child(fog)
				
				placed_positions.append(world_pos)
				break
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SIGNALS FOR GAMEPLAY USAGE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_all_beacons_lit() -> void:
	if EventBus.current_room == self :
		%DoorStopperCollision.set_deferred("disabled", true)
		room_complete = true
		EventBus.beacon_count_reset()
		# Door Flashes and Continues Flashing :
		flash_white()
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

func new_stepladder_dungeon(body) :
		var new_room = preload("res://Scenes/custom_rooms/trapdoor_room.tscn").instantiate()
		new_room.z_index = 0
		new_room.global_position.x += global_position.x + 750
		body.global_position = new_room.global_position + Vector2(160, 21)
		# Delete all previous rooms :
		for node in get_tree().current_scene.get_tree().get_nodes_in_group("rooms"):
			node.queue_free()
		
		get_tree().current_scene.get_node("RoomsToBeDeleted").call_deferred("add_child", new_room)
		# new_room.first_room = false

func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name != "Brody" or already_opened == true or room_complete == false :
		return
	
	else :
		already_opened = true
		%DoorBreakParticles.emitting = true
		%DoorFlashingTimer.stop()
		%DoorArea.remove_from_group("doors")
		%DoorArea.unlocked = true
		var theme = EventBus.current_theme
		if theme == 1 : # Then DarkSteel Door! :
			%DoorSprite.play("DarkSteelSmashed")
		elif theme == 2 : # Ice :
			%DoorSprite.play("DarkSteelSmashedIce")
		elif theme == 3 : # Hell :
			%DoorSprite.play("DarkSteelSmashedHell")
		elif theme == 4 : # Overgrown :
			%DoorSprite.play("DarkSteelSmashedOvergrown")
		
		if last_room == true :
			EventBus.last_room_passed()
			return
		
		# SWITCH TO NEXT ROOM :
		# Reset Beacons :
		EventBus.beacon_count_reset()
		
		var rooms = get_tree().current_scene.get_node("RoomsToBeDeleted").get_children()
		var index = rooms.find($".")
		
		if index != -1 and index + 1 < rooms.size():
			var next_room = rooms[index + 1]
			
			# Show next room :
			EventBus.current_room = next_room
			next_room.visible = true
			
			# Special Event Spawns :
			#Money Goblin :
			if randi_range(1, 24) == 12 :
				print ("yayay")
				var new_money_goblin = preload("res://Scenes/Monsters/money_goblin.tscn").instantiate()
				var rand = randi_range(1, spawnpoints)
				var spawn_node = %SpawnPoints.get_child(rand - 1)
				new_money_goblin.global_position = spawn_node.global_position + Vector2(0, -200)
				print (new_money_goblin.global_position)
				%SpawnPoints.call_deferred("add_child", new_money_goblin)
			
			# Tell EventBus How many beacons are in the next room, by getting beacons to activate :
			var new_rooms_beacons = next_room.get_node("Beacons").get_children()
			for i in new_rooms_beacons :
				i.now_visible()
		
func spawn_next_room() :
	if EventBus.last_room == false :
		var new_room = preload("res://Scenes/procedural_room.tscn").instantiate()
		new_room.door_origin = %DoorArea.global_position
		new_room.z_index = 0
		new_room.first_room = false
		EventBus.beacon_count_reset()
		EventBus._on_new_room()
		
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
		
		# Make Invisible  :
		new_room.visible = false
		
		get_tree().current_scene.get_node("RoomsToBeDeleted").call_deferred("add_child", new_room)
