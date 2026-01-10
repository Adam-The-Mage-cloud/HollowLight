extends Node2D

# 1.) LET'S GENERATE THE ROOM FROM _ready() 

# 2.) LET'S CONNECT THE DOOR SIGNALS TO THE ROOM_MANAGER SO IT KNOWS WHEN TO DELETE AND LOAD A NEW ROOM

# 3.) Base Room Sizes:
# Room Type 1 > Basic Dungeon = 32 x 18 Tiles 
# Room Type 2 > Basic Corridor = a x b Tiles

var room_type = 0
var theme = 0
var source_theme_id = 0

var width = 32
var height = 18

func _ready() :
	randomize()
	# Choose Room Size :
	room_type = randi_range (1, 1)
	if room_type == 1 :
		width = 32
		height = 18
		
	# Choose Room Theme :
	theme = randi_range (1, 1)
	
	# Initiate Generation Functions :
	generate_floor() 

func generate_floor() :
	# Generate Regular Gray Dungeon
	if theme == 1 :
		source_theme_id = 0
		for x in range(width) :
			for y in range(height) :
				var atlas_x = randi_range(0, 3) # Chooses the base x tile to then have an alternative (or 0 / no alternative) chosen
				var atlas_y = randi_range(0, 0) # Chooses the base y tile to then have an alternative (or 0 / no alternative) chosen
				var alternative_chance = randi_range(0, 3) # (4 in total starting from 0 (this picks a random alternative orientiation))
				%TileMapFloor.set_cell(Vector2i(x,y), source_theme_id, Vector2i(atlas_x, atlas_y), alternative_chance)
