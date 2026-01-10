extends Node

var total_beacons = 0

signal beacon_spawned(beacon)
signal beacon_lit(beacon)
signal beacon_extinguished(beacon)
signal all_beacons_lit(beacon)

signal monster_died(monster)

var total_beacons_to_light = 0
var beacons_lit = 0

func _ready():
	EventBus.beacon_spawned.connect(_on_beacon_spawned)
	EventBus.beacon_lit.connect(_on_beacon_lit)

func _on_beacon_spawned() :
	total_beacons_to_light += 1

func _on_beacon_lit() :
	beacons_lit += 1
	if beacons_lit == total_beacons_to_light :
		EventBus.all_beacons_lit.emit()
