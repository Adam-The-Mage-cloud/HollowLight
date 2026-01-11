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
var theme = 0

var floor_source_id = 0
var obstacle_source_id = 0
var bitsandbobs_source_id = 0

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

func generate_floor() :
	# Generate Regular Gray Dungeon
	if theme == 1 :
		floor_source_id = 0
		for x in range(width) :
			for y in range(height) :
				var atlas_x = randi_range(0, 3) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
				var atlas_y = randi_range(0, 0) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
				var alternative_chance = randi_range(0, 3) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
				%TileMapFloor.set_cell(Vector2i(x,y), floor_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)

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
	# Generate Regular Gray Dungeon Obstacles
	if theme == 1 :
		bitsandbobs_source_id = 20
		for x in range ((width) * 2.4) :
			for y in range ((height / 0.315) * 0.7) :
				if randf() < 0.005: # 1% chance per tile
					var atlas_x = randi_range(0, 5) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
					var atlas_y = randi_range(0, 2) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
					var alternative_chance = randi_range(0, 3) # (4 in total starting from 0 [0 being the regular tile] (this picks a random alternative orientiation))
					%TileMapBitsandBobs.set_cell(Vector2i(x,y), bitsandbobs_source_id, Vector2i(atlas_x, atlas_y), alternative_chance)
