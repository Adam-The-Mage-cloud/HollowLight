extends Node2D

# 1.) LET'S GENERATE THE ROOM FROM _ready() 

# 2.) LET'S CONNECT THE DOOR SIGNALS TO THE ROOM_MANAGER SO IT KNOWS WHEN TO DELETE AND LOAD A NEW ROOM

# 3.) Base Room Sizes:
# Room Type 1 > Basic Dungeon = 32 x 18 Tiles 
# Room Type 2 > Basic Corridor = 8 x 18 Tiles

# 4.) Source ID's :
# Floor Tiles = ID 0-9
# Obstacle Tiles = ID 10-19
# BitsandBobs Tiles = ID 20-29
# Wall Tiles = ID 30-39
# Wall Corner Tiles = ID 40-49
# Door Tiles = ID 50-59
# Floor Cover (mushrooms etc) = ID 60-69
# Room Outline (cobblestone etc) = ID 70-79
# Front Facing Wall (mineshaft etc) = ID 80-89

# All Generated Floor Tile grid coordinates (for spawning) :
var floor_positions: Array[Vector2i] = []

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

# Directionally Useful Variables :
var direction
var first_room = true
var previous_floor
var door_origin
var width = 32
var height = 18

func _ready() :
	randomize()
	# Signal Connections :
	EventBus.all_beacons_lit.connect(_on_all_beacons_lit)
	# Choose Room Size :
	if first_room == true:
		room_type = 2 # Corridor
		width = randi_range(8, 10)
		height = randf_range(8, 24)
	else :
		if room_type == 0 : # Check it hasn't already been assigned as some other room type :
			room_type = randi_range (1, 2)
			if room_type == 1 : # Regular Dungeon Room :
				width = randi_range(24, 36)
				height = randf_range(14, 22)
		
			elif room_type == 2 : # Corridor
				width = randi_range(8, 10)
				height = randf_range(8, 24)
	
	# Choose Direction of Room (up/down or left/right) and adjust so it fits the overall map
	if first_room == false :
		direction = randi_range(1, 1) # 1 = up/down , 2 = left/right
		if direction == 1 : # It's up so we need to send the room up on the y-axis, relative to its door
			$".".global_position.y = door_origin.y - (height * 10) + 10
			#%SpawnPoints.global_position.y = global_position.y - global_position.y
			print("Room root global:", global_position)
			print ("mobspawnroot:", %SpawnPoints.global_position)
			if room_type == 1 :
				pass
			if room_type == 2 :
				$".".global_position.x = door_origin.x - (width * 10) / 2
	
	# Choose Room Theme :
	theme = randi_range (1, 1)
	
	# Initiate Generation Functions :
	generate_underwall()
	generate_wall()
	generate_wall_corners()
	
	# Generate Floor Over The Top
	generate_floor() 
	generate_obstacles()
	generate_bitsandbobs()
	generate_floorcover()
	
	# Now generate exterior decorations :
	generate_outline()
	generate_fader_darker_outline()
	generate_frontfacing_wall()
	
	position_door()
	
	# Spawn Dungeon Interactables :
	place_spawn_points()
	monster_spawns()
	beacon_spawns()

func generate_floor() :
	# Generate Regular Gray Dungeon Floor Box and eventually we will do other shaped dungeon rooms :
	floor_positions.clear()
	if theme == 1 :
		floor_source_id = 0
		for x in range(width) :
			for y in range(height) :
				var atlas_x = randi_range(0, 3) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
				var atlas_y = randi_range(0, 0) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
				var alternative_chance = randi_range(0, 3) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
				# Now let's make note of all placed tiles so we know where we can spawn our monsters/beacons etc :
				%TileMapFloor.set_cell(Vector2i(x,y), floor_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)
				floor_positions.append(Vector2i(x, y))


func generate_wall():
	if theme == 1 :
		wall_source_id = 30
		var atlas_y = 0
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(1, 2):
			# Fade order: 0,1,2,3,3,3 etc
			var atlas_x = ring -1
			if atlas_x > 3:
				atlas_x = 3
			var left_x   = -ring
			var right_x  = max_x + ring
			var top_y    = -ring
			var bottom_y = max_y + ring
			# TOP EDGE (alt = 3)
			for x in range(left_x, right_x + 1):
				%TileMapWalls.set_cell(Vector2i(x, top_y), wall_source_id, Vector2i(atlas_x, atlas_y), 3)
			# BOTTOM EDGE (alt = 2)
			for x in range(left_x, right_x + 1):
				%TileMapWalls.set_cell(Vector2i(x, bottom_y), wall_source_id, Vector2i(atlas_x, atlas_y), 2)
			# LEFT EDGE (alt = 1) 
			for y in range(top_y, bottom_y + 1):
				%TileMapWalls.set_cell(Vector2i(left_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), 1)
			# RIGHT EDGE (alt = 0)
			for y in range(top_y, bottom_y + 1):
				%TileMapWalls.set_cell(Vector2i(right_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), 0)

func generate_underwall():
	if theme == 1 :
		wall_source_id = 30
		var atlas_y = 0
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(2, wallrings):
			# Fade order: 0,1,2,3,3,3 etc
			var atlas_x = ring -1
			if atlas_x > 3:
				atlas_x = 3
			var left_x   = -ring
			var right_x  = max_x + ring
			var top_y    = -ring
			var bottom_y = max_y + ring
			# TOP EDGE (alt = 3)
			for x in range(left_x, right_x + 1):
				%TileMapUnderWalls.set_cell(Vector2i(x, top_y), wall_source_id, Vector2i(atlas_x, atlas_y), 3)
			# BOTTOM EDGE (alt = 2)
			for x in range(left_x, right_x + 1):
				%TileMapUnderWalls.set_cell(Vector2i(x, bottom_y), wall_source_id, Vector2i(atlas_x, atlas_y), 2)
			# LEFT EDGE (alt = 1) 
			for y in range(top_y, bottom_y + 1):
				%TileMapUnderWalls.set_cell(Vector2i(left_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), 1)
			# RIGHT EDGE (alt = 0)
			for y in range(top_y, bottom_y + 1):
				%TileMapUnderWalls.set_cell(Vector2i(right_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), 0)

func generate_wall_corners():
	if theme == 1 :
		corner_source_id = 40
		var atlas_y = 0
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(1, 2):
			# Fade order: 0,1,2,3,3,3 etc
			var atlas_x = ring - 1
			if atlas_x > 3:
				atlas_x = 3
			# Corner coordinates
			var top_left = Vector2i(-ring, -ring)
			var top_right = Vector2i(max_x + ring, -ring)
			var bottom_left = Vector2i(-ring, max_y + ring)
			var bottom_right = Vector2i(max_x + ring, max_y + ring)
			# alternative tile IDs:
			# 0 = top-right
			# 1 = top-left
			# 2 = bottom-right
			# 3 = bottom-left
			%TileMapWallCorners.set_cell(top_left, corner_source_id, Vector2i(atlas_x, atlas_y), 1) # top-left
			%TileMapWallCorners.set_cell(top_right, corner_source_id, Vector2i(atlas_x, atlas_y), 0) # top-right
			%TileMapWallCorners.set_cell(bottom_left, corner_source_id, Vector2i(atlas_x, atlas_y), 3) # bottom-left
			%TileMapWallCorners.set_cell(bottom_right, corner_source_id, Vector2i(atlas_x, atlas_y), 2) # bottom-right

func generate_outline():
	if first_room == false :
		if theme == 1 : # Cobblestone
			wall_source_id = 70
			var max_x = width - 1
			var max_y = height - 1
			for ring in range(1, 2):
				# Fade order: 0,1,2,3,3,3 etc
				var left_x   = -ring
				var right_x  = max_x + ring
				var top_y    = -ring
				var bottom_y = max_y + ring
				# TOP EDGE 
				#for x in range(left_x, right_x + 1):
					#var atlas_y = randi_range(0,6)
					#var atlas_x = randi_range(0, 3)
					#%TileMapRoomOutline.set_cell(Vector2i(x, top_y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))
					# BOTTOM EDGE (alt = 2)
				for x in range(left_x, right_x + 1):
					var floor_map = previous_floor
					# The floor cell directly below the outline
					var outline_cell = Vector2i(x, bottom_y + 1 )
					
					# Convert outline cell → local pixel → floor cell
					var outline_pixel = %TileMapRoomOutline.map_to_local(outline_cell)
					var floor_local   = previous_floor.to_local(%TileMapRoomOutline.to_global(outline_pixel))
					var floor_cell    = previous_floor.local_to_map(floor_local)
					# If a floor tile already exists here, skip placing outline
					if previous_floor.get_cell_source_id(floor_cell) == 0:
						continue
						print("x:", x, " bottom_y:", bottom_y, " floor_cell:", floor_cell, " floor source:", floor_map.get_cell_source_id(floor_cell))
					# Otherwise place the rocky outline tile
					var atlas_y = randi_range(0, 6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomOutline.set_cell(
					Vector2i(x, bottom_y),
					wall_source_id,
					Vector2i(atlas_x, atlas_y),
					randi_range(0, 7)
				)
				# LEFT EDGE 
				for y in range(top_y, bottom_y + 1):
					var atlas_y = randi_range(0,6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomOutline.set_cell(Vector2i(left_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))
				# RIGHT EDGE 
				for y in range(top_y, bottom_y + 1):
					var atlas_y = randi_range(0,6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomOutline.set_cell(Vector2i(right_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))

func generate_fader_darker_outline():
	if first_room == false :
		if theme == 1 : # Cobblestone
			wall_source_id = 70
			var max_x = width - 1
			var max_y = height - 1
			for ring in range(2, 3):
				# Fade order: 0,1,2,3,3,3 etc
				var left_x   = -ring
				var right_x  = max_x + ring
				var top_y    = -ring
				var bottom_y = max_y + ring
				# TOP EDGE (alt = 3)
				#for x in range(left_x, right_x + 1):
					#var atlas_y = randi_range(0,6)
					#var atlas_x = randi_range(0, 3)
					#%TileMapRoomDarkerOutline.set_cell(Vector2i(x, top_y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))
				# BOTTOM EDGE (alt = 2)
				for x in range(left_x, right_x + 1):
					var floor_map = previous_floor
					# The floor cell directly below the outline
					var outline_cell = Vector2i(x, bottom_y )
					
					# Convert outline cell → local pixel → floor cell
					var outline_pixel = %TileMapRoomDarkerOutline.map_to_local(outline_cell)
					var floor_local   = previous_floor.to_local(%TileMapRoomDarkerOutline.to_global(outline_pixel))
					var floor_cell    = previous_floor.local_to_map(floor_local)
					# If a floor tile already exists here, skip placing outline
					if previous_floor.get_cell_source_id(floor_cell) == 0:
						continue
						print("x:", x, " bottom_y:", bottom_y, " floor_cell:", floor_cell, " floor source:", floor_map.get_cell_source_id(floor_cell))
					# Otherwise place the rocky outline tile
					var atlas_y = randi_range(0, 6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomDarkerOutline.set_cell(
					Vector2i(x, bottom_y),
					wall_source_id,
					Vector2i(atlas_x, atlas_y),
					randi_range(0, 7)
				)
				# LEFT EDGE (alt = 1) 
				for y in range(top_y, bottom_y + 1):
					var atlas_y = randi_range(0,6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomDarkerOutline.set_cell(Vector2i(left_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))
				# RIGHT EDGE (alt = 0)
				for y in range(top_y, bottom_y + 1):
					var atlas_y = randi_range(0,6)
					var atlas_x = randi_range(0, 3)
					%TileMapRoomDarkerOutline.set_cell(Vector2i(right_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))

func generate_frontfacing_wall():
	if theme == 1 : # Cobblestone
		wall_source_id = 80
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(2, 3):
			# Fade order: 0,1,2,3,3,3 etc
			var left_x   = -ring
			var right_x  = max_x + ring
			var top_y    = -ring
			var bottom_y = max_y + ring
			# TOP EDGE 
			for x in range(left_x, right_x + 1):
				var atlas_y = randi_range(0,0)
				var atlas_x = randi_range(0, 4)
				var flipped_wall_chance = randi_range(1, 2)
				if flipped_wall_chance == 1 : # then flip (alt becomes 2)
					flipped_wall_chance = 2
				%TileMapFrontFaceWall.set_cell(Vector2i(x, top_y), wall_source_id, Vector2i(atlas_x, atlas_y), flipped_wall_chance)
			# BOTTOM EDGE 
			#for x in range(left_x, right_x + 1):
				#var atlas_y = randi_range(0, 0)
				#var atlas_x = randi_range(0, 5)
				#%TileMapFrontFaceWall.set_cell(Vector2i(x, bottom_y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 1))
			# LEFT EDGE 
			#for y in range(top_y, bottom_y + 1):
				#var atlas_y = randi_range(0,6)
				#var atlas_x = randi_range(0, 3)
				#%TileMapFrontFaceWall.set_cell(Vector2i(left_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))
			# RIGHT EDGE 
			#for y in range(top_y, bottom_y + 1):
				#var atlas_y = randi_range(0,6)
				#var atlas_x = randi_range(0, 3)
				#%TileMapFrontFaceWall.set_cell(Vector2i(right_x, y), wall_source_id, Vector2i(atlas_x, atlas_y), randi_range(0, 7))

func generate_obstacles() :
	# Generate Regular Gray Dungeon Obstacles
	if theme == 1 :
		obstacle_source_id = 10
		for x in range ((width / 1.8) * 3.4) :
			for y in range ((height / 1.815) * 3.65) :
				if randf() < 0.001: # 1% chance per tile
					var atlas_x = randi_range(0, 1) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
					var atlas_y = randi_range(0, 1) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
					var alternative_chance = randi_range(0, 1) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
					%TileMapObstacles.set_cell(Vector2i(x,y), obstacle_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)

func generate_bitsandbobs() :
	# Generate Regular Gray Dungeon BitsandBobs
	if theme == 1 :
		bitsandbobs_source_id = 20
		for x in range ((width) * 2.4) :
			for y in range ((height / 0.315) * 0.7) :
				if randf() < 0.005: # 1% chance per tile
					var atlas_x = randi_range(0, 5) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
					var atlas_y = randi_range(0, 1) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
					var alternative_chance = randi_range(0, 1) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
					%TileMapBitsandBobs.set_cell(Vector2i(x,y), bitsandbobs_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)

func generate_floorcover():
	# Generate Regular Gray Dungeon FloorCover
	if theme == 1:
		floorcover_source_id = 60
		var density = 0.025
		var categories = {"cobwebs": 0, "hay": 1, "gold": 2, "mushrooms": 3}
		var cluster_count = int(width * height * density) # scale with room size
		for i in range(cluster_count):
			# Pick a random cluster center
			var cx = randi_range(0, int(width * 2.4))
			var cy = randi_range(0, int((height / 0.315) * 0.7))
			# Pick a category for this entire cluster
			var category_keys = categories.keys()
			var chosen_category = category_keys[randi() % category_keys.size()]
			var atlas_y = categories[chosen_category]
			# Cluster size
			var tiles_in_cluster = randi_range(1, 5)
			for j in range(tiles_in_cluster):
				var ox = randi_range(-6, 6)
				var oy = randi_range(-6, 6)
				var x = cx + ox
				var y = cy + oy
				if x < 0 or y < 0:
					continue
				var atlas_x = randi_range(0, 3)
				var alt = randi_range(0, 3)
				%TileMapFloorCover.set_cell(Vector2i(x, y), floorcover_source_id, Vector2i(atlas_x, atlas_y), alt)

func position_door() -> void:
	if direction == 1:
		# 1. Position the door somewhere along the room width
		%DoorArea.global_position.x = $".".global_position.x + randi_range(width * 2, width * 8)

		# 2. Convert door global position to FrontFaceWall cell coordinates
		var wall_map := %TileMapFrontFaceWall
		var global_pos: Vector2 = %DoorArea.global_position
		var local_pos: Vector2 = wall_map.to_local(global_pos)
		var door_cell: Vector2i = wall_map.local_to_map(local_pos)

		# 3. Erase a 3×3 area of FrontFaceWall tiles around the door
		for ox in range(-1, 2) :   # -1, 0, 1
			for oy in range(-1, 2) :
				var c = door_cell + Vector2i(ox, oy)
				wall_map.set_cell(c, -1)
	elif direction == 2 :
		pass


# SPAWNING INTERACTABLES :

# Choose Random Floor Tile Positions :
func pick_spawn_positions() -> Array[Vector2i]:
	var shuffled = floor_positions.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, spawnpoints)

# Move SpawnPoint Nodes to Shuffled Floor Tile Positions
func place_spawn_points():
	var positions = pick_spawn_positions()
	for i in range(spawnpoints):
		var spawn_node = %SpawnPoints.get_child(i)
		var tile_pos = positions[i]
		var local_pixel = %TileMapFloor.map_to_local(tile_pos)
		var world_pos = get_tree().current_scene.to_global(local_pixel)
		spawn_node.global_position = world_pos


# Spawn Monsters :
func monster_spawns() :
	if theme == 1 : # Gray Dungeon
		# Spawn Ogres :
		var ogre_amount = randi_range(1, 3)
		for i in range(ogre_amount) :
			var new_ogre = preload("res://Scenes/ogre.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_ogre.global_position = spawn_node.global_position
			add_child(new_ogre)

# Spawn Beacons :
func beacon_spawns() :
	if theme == 1 : # Gray Dungeon :
		var beacon_amount = randi_range(1, 4)
		for i in range (beacon_amount) :
			var new_beacon = preload("res://Scenes/brazier.tscn").instantiate()
			var rand = randi_range(1, spawnpoints)
			var spawn_node = %SpawnPoints.get_child(rand - 1)
			new_beacon.global_position = spawn_node.global_position
			add_child(new_beacon)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Gameplay :

func _on_all_beacons_lit() :
	%DoorStopperCollision.set_deferred("disabled", true)
	room_complete = true
	# door sprite flashes white


func _on_door_open_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and already_opened == false and room_complete == true :
		already_opened = true
		# Animate door :
		%DoorSprite.play("DarkSteelSmashed")
		# Spawn new random room :
		var new_room = preload("res://Scenes/procedural_room.tscn").instantiate()
		new_room.previous_floor = %TileMapFloor
		new_room.door_origin = %DoorArea.global_position
		new_room.z_index = 2
		new_room.first_room = false
		get_tree().current_scene.call_deferred("add_child", new_room)
