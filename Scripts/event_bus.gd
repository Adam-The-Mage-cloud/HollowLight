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

var total_beacons_to_light = 0
var beacons_lit = 0

# Currency Variables :
var total_acquired_embers = 0
var total_acquired_experience = 0

func _ready():
	EventBus.beacon_spawned.connect(_on_beacon_spawned)
	EventBus.beacon_lit.connect(_on_beacon_lit)
	
	EventBus.ember_acquired.connect(_on_ember_acquired)
	EventBus.ember_acquired.connect(_on_experience_orb_acquired)

func _on_beacon_spawned() :
	total_beacons_to_light += 1

func _on_beacon_lit() :
	beacons_lit += 1
	if beacons_lit == total_beacons_to_light :
		EventBus.all_beacons_lit.emit()

# Currency System Functions :
func _on_ember_acquired() :
	total_acquired_embers += 1

func _on_experience_orb_acquired() :
	total_acquired_experience += 1
