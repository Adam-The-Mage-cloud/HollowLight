extends Node2D

# 1.) LET'S GENERATE THE ROOM FROM _ready() 

# 2.) LET'S CONNECT THE DOOR SIGNALS TO THE ROOM_MANAGER SO IT KNOWS WHEN TO DELETE AND LOAD A NEW ROOM

# 3.) Base Room Sizes:
# Room Type 1 > Basic Dungeon = 32 x 18 Tiles 
# Room Type 2 > Basic Corridor = a x b Tiles

# 4.) Source ID's :
# Floor Tiles = ID 0-9
# Obstacle Tiles = ID 10-19
# BitsandBobs Tiles = ID 20-29
# Wall Tiles = ID 30-39
# Wall Corner Tiles = ID 40-49
# Door Tiles = ID 50-59
# Floor Cover (mushrooms etc) = ID 60-69

var room_type = 0
var wallrings = 8
var theme = 0

var floor_source_id = 0
var obstacle_source_id = 0
var bitsandbobs_source_id = 0
var floorcover_source_id = 0
var wall_source_id = 0
var corner_source_id = 0

var width = 32
var height = 18

func _ready() :
	# Choose Room Size :
	room_type = randi_range (1, 1)
	if room_type == 1 :
		width = 32
		height = 18
		
	# Choose Room Theme :
	theme = randi_range (1, 1)
	
	# Initiate Generation Functions :
	generate_floor() 
	generate_obstacles()
	generate_bitsandbobs()
	generate_floorcover()
	generate_wall()
	generate_wall_corners()

func generate_floor() :
	# Generate Regular Gray Dungeon Floor
	if theme == 1 :
		floor_source_id = 0
		for x in range(width) :
			for y in range(height) :
				var atlas_x = randi_range(0, 3) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
				var atlas_y = randi_range(0, 0) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
				var alternative_chance = randi_range(0, 3) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
				%TileMapFloor.set_cell(Vector2i(x,y), floor_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)

func generate_wall():
	if theme == 1 :
		wall_source_id = 30
		var atlas_y = 0
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(1, wallrings + 4):
			# Fade order: 0,1,2,3,3,3 etc
			var atlas_x = ring - 1
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

func generate_wall_corners():
	if theme == 1 :
		corner_source_id = 40
		var atlas_y = 0
		var max_x = width - 1
		var max_y = height - 1
		for ring in range(1, wallrings):
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
