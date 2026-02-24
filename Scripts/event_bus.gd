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
signal player_deaded()
signal last_room_complete()
signal open_travel_menu()

signal open_clives_shop()

# NEW GAME / GO TO SANCTUARY Signals :
signal new_crawl()

signal spawn_sanctuary()

signal last_room_loaded()

var touchscreen_enacted = false

var total_beacons_to_light = 0
var beacons_lit = 0

var death_played = false

# Item Prices :
# Uniques (one-time purchases) :
var mystic_sword_price = 775
var winged_torch_price = 1725

# Currency Variables :
var total_current_darkness = 0.0
var total_acquired_experience: int = 0
var total_acquired_goldpieces: int = 0

var total_new_acquired_experience: int = 0
var total_new_acquired_goldpieces: int = 0

# PLAYER STATS :
var player_level: int = 1

# Currently Equipped Player Inventory :
var equipped_sidekick

# PURCHASES :
var mystic_sword_purchased = false
var winged_torch_purchased = false

# Rooms Completed / ENDGAME DECIDER :
var intro = false
var current_room
var game_over_chance = 0.0
var last_room = false
var total_rooms = 0.0

# Sanctuary Buttons :
var dungeon_crawl_button_available = false
var clives_shop_interactable = false

# Theme Indicator
var current_theme = 1

func _ready():
	# Access Saved Data :
	load_game()
	EventBus.beacon_spawned.connect(_on_beacon_spawned)
	EventBus.beacon_lit.connect(_on_beacon_lit)
	
	EventBus.ember_acquired.connect(_on_ember_acquired)
	EventBus.experience_orb_acquired.connect(_on_experience_orb_acquired)
	EventBus.goldpiece_acquired.connect(_on_goldpiece_acquired)
	
	EventBus.new_room.connect(_on_new_room)

func player_died() :
	EventBus.beacons_lit = 0
	EventBus.total_beacons_to_light = 0
	EventBus.total_beacons = 0
	EventBus.total_current_darkness = 0
	EventBus.total_new_acquired_experience = 0
	EventBus.total_new_acquired_goldpieces = 0
	EventBus.player_deaded.emit()

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
		elif intro == true :
			last_room = true

func last_room_passed() :
	EventBus.beacons_lit = 0
	EventBus.total_beacons_to_light = 0
	EventBus.total_beacons = 0
	EventBus.total_current_darkness = 0
	EventBus.last_room_complete.emit()
	save_game()

func open_the_travel_menu() :
	EventBus.open_travel_menu.emit()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NEW DUNGEON CRAWL / HEAD TO SANCTUARY :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# DUNGEONS :
func new_dungeon_crawl() :
	if touchscreen_enacted == true :
		%TouchScreenPress1.visible = true
		%TorchJoystickBase.visible = true
		%TorchJoystickSprite.visible = true
	EventBus.current_theme = randi_range(1, 4)
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


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OPEN SHOPS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# > Clives Shop (Uniques for Gems & Gold) :
func clives_shop_available() :
	EventBus.open_clives_shop.emit()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SAVING AND LOADING :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Saved Data Inside a Dictionary :
func get_save_data() -> Dictionary:
	return {
		"player_level": player_level,
		"total_acquired_experience": total_acquired_experience,
		"total_acquired_goldpieces": total_acquired_goldpieces,
		"sidekick": equipped_sidekick,
		
		# Shop Purchases :
		"mystic_sword_purchased": mystic_sword_purchased,
		"winged_torch_purchased": winged_torch_purchased
	}

func apply_save_data(data: Dictionary):
	player_level = data.get("player_level", 1)
	total_acquired_experience = data.get("total_acquired_experience", 0)
	total_acquired_goldpieces = data.get("total_acquired_goldpieces", 0)
	equipped_sidekick = data.get("sidekick", "none")
	
	# Shop Purchases :
	mystic_sword_purchased = data.get("mystic_sword_purchased", false)
	winged_torch_purchased = data.get("winged_torch_purchased", false)
	
	print("Game loaded!")

func save_game():
	var save_path = "user://savegame.json"
	var data = get_save_data()
	var json_string = JSON.stringify(data)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Game saved!")

func load_game():
	var save_path = "user://savegame.json"
	
	if not FileAccess.file_exists(save_path):
		print("No save file found.")
		return
		
	var file = FileAccess.open(save_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	
	if typeof(data) == TYPE_DICTIONARY:
		apply_save_data(data)
		
	# Needed Functions :
	# > Spawn Sidekick :
	if equipped_sidekick == "mystic_sword" :
		get_tree().current_scene.spawn_mystic_sword()
	elif equipped_sidekick == "winged_torch" :
		get_tree().current_scene.spawn_winged_torch()
