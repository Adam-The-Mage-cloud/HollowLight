extends Node

# TIMING (REAL WORLD) :
var last_daily_reset : String = ""   
var last_weekly_reset : String = ""  

var last_hourly_food_update = 0


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
signal new_dungeon_touchscreen

signal spawn_sanctuary()

signal last_room_loaded()

signal camera_reset()

var touchscreen_enacted = false

var total_beacons_to_light = 0
var beacons_lit = 0

var death_played = false

var sanctuary_under_attack = false 

# Item Prices :
# Uniques (one-time purchases) :
var mystic_sword_price = 775
var winged_torch_price = 1725
# Outfits (one-time purchases) :
var gladiator_outfit_price = 400
var liquified_outfit_price = 750
var samurai_outfit_price = 1200
# Torches (one-time purchases) :
var walltorch_torch_price = 160
var wizardstaff_torch_price = 2375
# Shields (one-time purchases) :
var bluevariant_shield_price = 300
var nurnincrest_shield_price = 625
var holyeffigee_shield_price = 1575

# Upgrade Prices :
var dash_timing_upgrade_price = 100
var torch_max_stamina_upgrade_price = 100
var torch_recovery_upgrade_price = 100
var fortify_darkness_upgrade_price = 250
var shield_stamina_upgrade_price = 100
var shield_speed_upgrade_price = 200
var loot_chance_upgrade_price = 500


# Currency Variables :
var total_current_darkness = 0.0
var total_acquired_experience: int = 0
var total_acquired_goldpieces: int = 0

var total_new_acquired_experience: int = 0
var total_new_acquired_goldpieces: int = 0

# PLAYER STATS :
var player_level: int = 1
var player_skill_points: int = 0

# Currently Equipped Player Inventory :
var equipped_sidekick
var shield_acquired
var equipped_torch
var equipped_brodyoutfit

# PURCHASES :
# > Clives Shop :
var mystic_sword_purchased = false
var winged_torch_purchased = false

# > Cat Balloonist :
# >> Outfits :
var gladiator_brody_purchased = false
var liquified_brody_purchased = false
var samurai_brody_purchased = false
# >> Torches :
var walltorch_torch_purchased = false
var wizardstaff_torch_purchased = false
# >> Shields :
var bluevariant_shield_purchased = false
var nurnincrest_shield_purchased = false
var holyeffigee_shield_purchased = false

# > Jackies Shop :
var amount_dash_timing_upgraded = 0 
var amount_max_stamina_upgraded = 0
var amount_torch_recovery_upgraded = 0
var amount_fortify_darkness_upgraded = 0 
var amount_shield_stamina_upgraded = 0 ### DO THIS NEXT
var amount_shield_speed_upgraded = 0 ### DO THIS NEXT 
var amount_lootchance_upgraded = 0

# Rooms Completed / ENDGAME DECIDER :
var sanctuary = false
var intro = false
var current_room
var game_over_chance = 0.0
var last_room = false
var total_rooms = 0.0

# Sanctuary Buttons :
var currently_interacting = false
var dungeon_crawl_button_available = false
var tutorial_replay_available = false
var clives_shop_interactable = false
var catballoon_shop_interactable = false
var jackie_shop_interactable = false
var mission_board_interactable = false
var cheffing_station_interactable = false

# Sanctuary Definables :
var food_accumulated = 100.0

var jackies_first_load = true

# Current Missions Activated :
# Dailies :
var daily_missions = {
	1: "0",
	2: "0",
	3: "0",
	4: "0",
}

# Weeklies :
var weekly_missions = {
	1: "0",
	2: "0",
}



# Daily Mission Trackers :
var draugr_burnt = 0
var mudcrabs_burnt = 0
var ogres_burnt = 0
var goblins_burnt  = 0
var grindstonters_burnt = 0
var witches_burnt = 0
var torch_wraiths_burnt = 0
var soul_eaters_burnt = 0
var dire_wolves_burnt = 0
var orbles_rescued = 0
var stews_prepared = 0
var dungeons_completed = 0
var shield_changed = false
var outfit_changed = false
var hat_changed = false
var torch_changed = false
var dash_used = 0
var npcs_spoken_to = 0

# Weekly Mission Trackers :
var daily_missions_completed_during_current_week = 0
var weekly_dungeons_completed = 0
# var weekly_bosses_beaten = 0


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

func return_camera() :
	EventBus.camera_reset.emit()

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
	game_over_chance = 0.2 
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
		EventBus.new_dungeon_touchscreen.emit()
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
# > Clives Shop (Uniques for Gold) :
func clives_shop_available() :
	EventBus.open_clives_shop.emit()



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# REAL WORLD TIME RESETS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~





# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SAVING AND LOADING :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Saved Data Inside a Dictionary :
func get_save_data() -> Dictionary:
	return {
		"player_level": player_level,
		"player_skill_points": player_skill_points,
		"total_acquired_experience": total_acquired_experience,
		"total_acquired_goldpieces": total_acquired_goldpieces,
		"sidekick": equipped_sidekick,
		"equipped_shield": shield_acquired,
		"equipped_torch": equipped_torch,
		"equipped_brodyoutfit": equipped_brodyoutfit,
		
		# Sanctuary Values :
		"food_accumulated": food_accumulated,
		
		# Time :
		"last_daily_reset": last_daily_reset,
		"last_weekly_reset": last_weekly_reset,
		"last_hourly_food_update": last_hourly_food_update,
		
		# Currently Active Missions :
		"daily_missions": daily_missions,
		"weekly_missions": weekly_missions,
		
		# Weekly Missions :
		"daily_missions_completed_during_current_week": daily_missions_completed_during_current_week,
		"weekly_dungeons_completed": weekly_dungeons_completed,
		
		# ----------------------------------------------------------------------
		# Shop Purchases :
		# ----------------------------------------------------------------------
		# > Clive :
		# > > Sidekicks
		"mystic_sword_purchased": mystic_sword_purchased,
		"winged_torch_purchased": winged_torch_purchased,
		
		# > Balloonist :
		# > > Outfits 
		"gladiator_brody_purchased": gladiator_brody_purchased,
		"liquified_brody_purchased": liquified_brody_purchased,
		"samurai_brody_purchased": samurai_brody_purchased,
		
		# > > Shields
		"bluevariant_shield_purchased": bluevariant_shield_purchased,
		"nurnincrest_shield_purchased": nurnincrest_shield_purchased,
		"holyeffigee_shield_purchased": holyeffigee_shield_purchased,
		
		# > > Torches 
		"walltorch_torch_purchased": walltorch_torch_purchased,
		"wizardstaff_torch_purchased": wizardstaff_torch_purchased,
		
		# > Jackie :
		# > > Upgrades
		"amount_dash_timing_upgraded": amount_dash_timing_upgraded,
		"amount_max_stamina_upgraded": amount_max_stamina_upgraded,
		"amount_torch_recovery_upgraded": amount_torch_recovery_upgraded,
		"amount_fortify_darkness_upgraded": amount_fortify_darkness_upgraded,
		"amount_shield_stamina_upgraded": amount_shield_stamina_upgraded,
		"amount_shield_speed_upgraded": amount_shield_speed_upgraded,
		"amount_lootchance_upgraded": amount_lootchance_upgraded,
	}

func apply_save_data(data: Dictionary):
	player_level = data.get("player_level", 1)
	player_skill_points = data.get("player_skill_points", 1)
	total_acquired_experience = data.get("total_acquired_experience", 0)
	total_acquired_goldpieces = data.get("total_acquired_goldpieces", 0)
	equipped_sidekick = data.get("sidekick", "none")
	shield_acquired = data.get("equipped_shield", "none")
	equipped_torch = data.get("equipped_torch", "none")
	equipped_brodyoutfit = data.get("equipped_brodyoutfit", "none")
	
	# Sanctuary Values :
	food_accumulated = data.get("food_accumulated", 100.0)
	
	# Time :
	last_daily_reset = data.get("last_daily_reset", "none")
	last_weekly_reset = data.get("last_weekly_reset", "none")
	last_hourly_food_update = data.get("last_hourly_food_update", 0)
	
	# Currently Active Missions :
	daily_missions = data.get("daily_missions", {
		1: "0",
		2: "0",
		3: "0",
		4: "0",
	})
	
	weekly_missions = data.get("weekly_missions", {
		1: "0",
		2: "0",
	})
	print (daily_missions)
	# ----------------------------------------------------------------------
	# Shop Purchases :
	# ----------------------------------------------------------------------
	# > Clive :
	# > > Sidekicks
	mystic_sword_purchased = data.get("mystic_sword_purchased", false)
	winged_torch_purchased = data.get("winged_torch_purchased", false)
	
	# > Balloonist :
	# > > Outfits 
	gladiator_brody_purchased = data.get("gladiator_brody_purchased", false)
	liquified_brody_purchased = data.get("liquified_brody_purchased", false)
	samurai_brody_purchased = data.get("samurai_brody_purchased", false)
	
	# > > Shields
	bluevariant_shield_purchased = data.get("bluevariant_shield_purchased", false)
	nurnincrest_shield_purchased = data.get("nurnincrest_shield_purchased", false)
	holyeffigee_shield_purchased = data.get("holyeffigee_shield_purchased", false)
	
	# > > Torches 
	walltorch_torch_purchased = data.get("walltorch_torch_purchased", false)
	wizardstaff_torch_purchased = data.get("wizardstaff_torch_purchased", false)
	
	# > Jackie :
	# > > Upgrades
	amount_dash_timing_upgraded = data.get("amount_dash_timing_upgraded", 0)
	amount_max_stamina_upgraded = data.get("amount_max_stamina_upgraded", 0)
	amount_torch_recovery_upgraded = data.get("amount_torch_recovery_upgraded", 0)
	amount_fortify_darkness_upgraded = data.get("amount_fortify_darkness_upgraded", 0)
	amount_shield_stamina_upgraded = data.get("amount_shield_stamina_upgraded", 0)
	amount_shield_speed_upgraded = data.get("amount_shield_speed_upgraded", 0)
	amount_lootchance_upgraded = data.get("amount_lootchance_upgraded", 0)
	
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
