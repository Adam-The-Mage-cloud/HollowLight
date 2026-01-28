extends Node

var total_beacons = 0

signal beacon_spawned(beacon)
signal beacon_lit(beacon)
signal beacon_extinguished(beacon)
signal all_beacons_lit(beacon)

signal monster_died(monster)

# Currency System Signals :
signal ember_acquired(ember)
signal experience_orb_acquired(experience_orb)
signal goldpiece_acquired(gold_piece)

signal new_room

# MENU Signals :
signal last_room_complete()
signal open_travel_menu()

# NEW GAME / GO TO SANCTUARY Signals :
signal new_crawl()

signal spawn_sanctuary()


var total_beacons_to_light = 0
var beacons_lit = 0

# Currency Variables :
var total_current_darkness = 0.0
var total_acquired_experience = 0
var total_acquired_goldpieces = 0

var total_new_acquired_experience = 0
var total_new_acquired_goldpieces = 0

# PLAYER STATS :
var player_level = 1

# Rooms Completed / ENDGAME DECIDER :
var current_room
var game_over_chance = 0.0
var last_room = false
var total_rooms = 0.0

# Sanctuary Buttons :
var dungeon_crawl_button_available = false

# Theme Indicator
var current_theme = 1

func _ready():
	EventBus.beacon_spawned.connect(_on_beacon_spawned)
	EventBus.beacon_lit.connect(_on_beacon_lit)
	
	EventBus.ember_acquired.connect(_on_ember_acquired)
	EventBus.experience_orb_acquired.connect(_on_experience_orb_acquired)
	EventBus.goldpiece_acquired.connect(_on_goldpiece_acquired)
	
	EventBus.new_room.connect(_on_new_room)

func _on_beacon_spawned() :
	total_beacons_to_light += 1

func _on_beacon_lit() :
	beacons_lit += 1
	total_current_darkness -= 15
	if beacons_lit == total_beacons_to_light :
		EventBus.all_beacons_lit.emit()

# Currency System Functions :
func _on_ember_acquired() :
	total_current_darkness -= 5

func _on_experience_orb_acquired() :
	total_new_acquired_experience += 1

func _on_goldpiece_acquired() :
	total_new_acquired_goldpieces += 1

# New Room / Game Finisher Decider :
func _on_new_room() :
	game_over_chance = 0.25 
	if randf_range(0, 1) < game_over_chance :
		if total_rooms >= 5 : # 7
			last_room = true

func last_room_passed() :
	EventBus.beacons_lit = 0
	EventBus.total_beacons_to_light = 0
	EventBus.total_beacons = 0
	EventBus.last_room_complete.emit()

func open_the_travel_menu() :
	EventBus.open_travel_menu.emit()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NEW DUNGEON CRAWL / HEAD TO SANCTUARY :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# DUNGEONS :
func new_dungeon_crawl() :
	total_current_darkness = 0.0
	total_new_acquired_experience = 0
	total_new_acquired_goldpieces = 0
	beacons_lit = 0
	total_beacons_to_light = 0
	total_beacons = 0
	EventBus.new_crawl.emit()

# Done after every room :
func beacon_count_reset() :
	EventBus.beacons_lit = 0
	EventBus.total_beacons_to_light = 0
	EventBus.total_beacons = 0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Sanctuary :
func spawn_the_sanctuary() :
	EventBus.spawn_sanctuary.emit()
