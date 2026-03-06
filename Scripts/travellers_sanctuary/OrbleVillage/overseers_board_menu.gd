extends Node2D

var already_used_missions: Array = []
var already_used_weekly_missions: Array = []

var daily_gold_reward = 200
var daily_fervour_reward = 5

var weekly_gold_reward = 500
var weekly_fervour_reward = 15


func _ready() :
	randomize()
	# Create 4 daily missions and 2 weekly missions
	open_mission_board()
	check_daily_reset()
	check_weekly_reset()
	set_and_check_missions()

# >>>
# Mission Board :
# >>>
func open_mission_board() :
	# Update Gold & XP Values :
	%TotalGoldText.text = str(EventBus.total_acquired_goldpieces)
	%TotalXPText.text = str(EventBus.player_level)
	%FervourText.text = str(EventBus.total_fervour)
	
	# Swoop-in Shop :
	var bgs = $"."
	
	# Start slightly above and transparent
	bgs.modulate.a = 0.0
	bgs.position.y -= 20
	
	var tb = create_tween().parallel()
	tb.set_parallel(true)
	
	# Fade in
	tb.tween_property(bgs, "modulate:a", 1.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Slide down into place
	tb.tween_property(bgs, "position:y", bgs.position.y + 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# REAL WORLD TIME UPDATER :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Daily :
# Check If A Day Has Passed :
func check_daily_reset():
	# Get Current Time :
	var now = Time.get_datetime_dict_from_system()
	# Setup Current Time as a key to compare with EventBus last recorded time
	var today_key = "%d-%02d-%02d" % [now.year, now.month, now.day]

	if EventBus.last_daily_reset != today_key:
		reset_daily_missions()
		EventBus.last_daily_reset = today_key

# Reset Missions if new day :
func reset_daily_missions():
	# Daily Mission Trackers :
	EventBus.draugr_burnt = 0
	EventBus.mudcrabs_burnt = 0
	EventBus.ogres_burnt = 0
	EventBus.goblins_burnt  = 0
	EventBus.grindstonters_burnt = 0
	EventBus.witches_burnt = 0
	EventBus.torch_wraiths_burnt = 0
	EventBus.soul_eaters_burnt = 0
	EventBus.dire_wolves_burnt = 0
	EventBus.orbles_rescued = 0
	EventBus.stews_prepared = 0
	EventBus.dungeons_completed = 0
	EventBus.shield_changed = false
	EventBus.outfit_changed = false
	EventBus.hat_changed = false
	EventBus.torch_changed = false
	EventBus.dash_used = 0
	EventBus.npcs_spoken_to = 0

	# Pick new missions
	EventBus.daily_missions["1"] = "0"
	EventBus.daily_missions["2"] = "0"
	EventBus.daily_missions["3"] = "0"
	EventBus.daily_missions["4"] = "0"
	%Daily1.add_theme_color_override("default_color", Color(0.902, 0.075, 0.051))
	%Daily2.add_theme_color_override("default_color", Color(0.902, 0.075, 0.051))
	%Daily3.add_theme_color_override("default_color", Color(0.902, 0.075, 0.051))
	%Daily4.add_theme_color_override("default_color", Color(0.902, 0.075, 0.051))
	pick_from_daily_pool()

# Weekly :
func check_weekly_reset():
	var now = Time.get_datetime_dict_from_system()

	# Godot weekday: Monday = 1, Sunday = 7
	if now.weekday == 1: # Monday
		if EventBus.last_weekly_reset != "%d-%02d-%02d" % [now.year, now.month, now.day]:
			reset_weekly_missions()
			EventBus.last_weekly_reset = "%d-%02d-%02d" % [now.year, now.month, now.day]


func reset_weekly_missions() :
	EventBus.daily_missions_completed_during_current_week = 0
	EventBus.weekly_dungeons_completed = 0
	
	EventBus.weekly_missions["1"] = "0"
	EventBus.weekly_missions["2"] = "0"
	%Weekly1.add_theme_color_override("default_color", Color(0.992, 0.722, 0.11))
	%Weekly2.add_theme_color_override("default_color", Color(0.992, 0.722, 0.11))
	pick_from_weekly_pool()
	set_and_check_missions()



func set_missions() :
	# If daily timer has expired then new missions :
	pick_from_daily_pool()
	set_and_check_missions()
	

# >>>
# GENERAL CLOSE BUTTON :
# >>>
func _on_close_menu_button_pressed() -> void:
	# SHOPS :
	$"../..".shop_closed()
	# > For Clives Shop :
			# Fade and slide back up
	var bgs = $"."
	
	# Start slightly above and transparent
	bgs.modulate.a = 0.0
	bgs.position.y -= 20
	
	var tb2 = create_tween()
	tb2.set_parallel(true)
	
	tb2.tween_property(bgs, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	tb2.tween_property(bgs, "position:y", bgs.position.y - 20, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tb2.finished
	queue_free()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check Missions :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func set_and_check_missions():
	# Daily
	for i in range(1, 5):
		if EventBus.daily_missions.has(str(i)):
			apply_daily_mission(i)
	
	# Weekly
	for i in range(1, 3):
		if EventBus.weekly_missions.has(str(i)):
			apply_weekly_mission(i)

# THIS ALSO CHECKS TO SEE IF OBJECTIVES HAVE BEEN COMPLETED
func apply_daily_mission(i: int):
	var mission_type = EventBus.daily_missions[str(i)]

	match mission_type:
		"complete":
			%OverseersBoard.get_node("DailyClaimed" + str(i)).visible = true
			%OverseersBoard.get_node("DailyGold" + str(i)).visible = false
			%OverseersBoard.get_node("DailyGoldSprite" + str(i)).visible = false
		"1":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Draugr" % EventBus.draugr_burnt
			if EventBus.draugr_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"2":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Mudcrabs" % EventBus.mudcrabs_burnt
			if EventBus.mudcrabs_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"3":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Ogres" % EventBus.ogres_burnt
			if EventBus.ogres_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"4":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Goblins" % EventBus.goblins_burnt
			if EventBus.goblins_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"5":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Grindstonters" % EventBus.grindstonters_burnt
			if EventBus.grindstonters_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"6":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Witches" % EventBus.witches_burnt
			if EventBus.witches_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"7":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Torch Wraiths" % EventBus.torch_wraiths_burnt
			if EventBus.torch_wraiths_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"8":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Soul Eaters" % EventBus.soul_eaters_burnt
			if EventBus.soul_eaters_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"9":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Burnt %s / 12 Dire Wolves" % EventBus.dire_wolves_burnt
			if EventBus.dire_wolves_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"10":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Rescued %s / 2 Orbles" % EventBus.orbles_rescued
			if EventBus.orbles_rescued >= 2 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"11":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Prepared %s / 2 Stews" % EventBus.stews_prepared
			if EventBus.stews_prepared >= 2 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"12":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Completed %s / 3 Dungeons" % EventBus.dungeons_completed
			if EventBus.dungeons_completed >= 3 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"13":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Shield Changed: %s" % EventBus.shield_changed
			if EventBus.shield_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"14":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Outfit Changed: %s" % EventBus.outfit_changed
			if EventBus.outfit_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"15":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Hat Changed: %s" % EventBus.hat_changed
			if EventBus.hat_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"16":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Torch Changed %s / 1" % EventBus.torch_changed
			if EventBus.torch_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"17":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Dash Used %s / 40" % EventBus.dash_used
			if EventBus.dash_used >= 40 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))
		"18":
			%OverseersBoard.get_node("Daily" + str(i)).text = "Spoken To %s / 5 NPCs" % EventBus.npcs_spoken_to
			if EventBus.npcs_spoken_to >= 5 and EventBus.daily_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Daily" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("DailyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("DailyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("DailyClaimFinger" + str(i)))


func apply_weekly_mission(i: int):
	var mission_type = EventBus.weekly_missions[str(i)]

	match mission_type:
		"complete":
				%OverseersBoard.get_node("WeeklyClaimed" + str(i)).visible = true
				%OverseersBoard.get_node("WeeklyGold" + str(i)).visible = false
				%OverseersBoard.get_node("WeeklyGoldSprite" + str(i)).visible = false
		"1":
			%OverseersBoard.get_node("Weekly" + str(i)).text = "Completed %s / 7 Daily Missions" % EventBus.daily_missions_completed_during_current_week
			if EventBus.daily_missions_completed_during_current_week >= 7 and EventBus.weekly_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Weekly" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("WeeklyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("WeeklyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("WeeklyClaimFinger" + str(i)))
		"2":
			%OverseersBoard.get_node("Weekly" + str(i)).text = "%s / 12 Dungeons Crawled" % EventBus.weekly_dungeons_completed
			if EventBus.weekly_dungeons_completed >= 12 and EventBus.weekly_missions[str(i)] != "complete":
				%OverseersBoard.get_node("Weekly" + str(i)).add_theme_color_override("default_color", Color(0.086, 0.918, 0.122))
				%OverseersBoard.get_node("WeeklyClaimButton" + str(i)).visible = true
				%OverseersBoard.get_node("WeeklyClaimFinger" + str(i)).visible = true
				finger_tapping(%OverseersBoard.get_node("WeeklyClaimFinger" + str(i)))


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MISSION POOLS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func pick_from_daily_pool() :
	# THE DAILY MISSION POOL :
	var i = 0
	while i < 4 :
		i += 1
		var daily_picker = 0
		if EventBus.daily_missions[str(i)] == "0" :
			daily_picker = randi_range(1, 18)
			while already_used_missions.has(daily_picker) :
				daily_picker = randi_range(1, 18)
			already_used_missions.append(daily_picker)
		if daily_picker == 1 or EventBus.daily_missions[str(i)] == "1" : # Burn Draugr :
			# Burn 12 Draugr :
			var mission_type = 1
			var mission_description = "Burnt " + str(EventBus.draugr_burnt) + " / 12 Draugr"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)
			
		elif daily_picker == 2 or EventBus.daily_missions[str(i)] == "2" : # Burn Mudcrabs
			# Burn 12 Mudcrabs :
			var mission_type = 2
			var mission_description = "Burnt " + str(EventBus.mudcrabs_burnt) + " / 12 Mudcrabs"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)
			
		elif daily_picker == 3 or EventBus.daily_missions[str(i)] == "3" : # Burn Ogres
			# Burn 12 Ogres :
			var mission_type = 3
			var mission_description = "Burnt " + str(EventBus.ogres_burnt) + " / 12 Ogres"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)
			
		elif daily_picker == 4 or EventBus.daily_missions[str(i)] == "4" : # Burn Goblins
			# Burn 12 Goblins :
			var mission_type = 4
			var mission_description = "Burnt " + str(EventBus.goblins_burnt) + " / 12 Goblins"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)
			
		elif daily_picker == 5 or EventBus.daily_missions[str(i)] == "5" : # Burn Grindstonters
			# Burn 12 Grindstonters :
			var mission_type = 5
			var mission_description = "Burnt " + str(EventBus.grindstonters_burnt) + " / 12 Grindstonters"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)
			
		elif daily_picker == 6 or EventBus.daily_missions[str(i)] == "6" : # Burn Witches
			# Burn 12 Witches :
			var mission_type = 6
			var mission_description = "Burnt " + str(EventBus.witches_burnt) + " / 12 Witches"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 7 or EventBus.daily_missions[str(i)] == "7" : # Burn Torch Wraiths
			# Burn 12 Torch Wraiths :
			var mission_type = 7
			var mission_description = "Burnt " + str(EventBus.torch_wraiths_burnt) + " / 12 Torch Wraiths"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 8 or EventBus.daily_missions[str(i)] == "8" : # Burn Soul Eaters
			# Burn 12 Soul Eaters :
			var mission_type = 8
			var mission_description = "Burnt " + str(EventBus.soul_eaters_burnt) + " / 12 Soul Eaters"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 9 or EventBus.daily_missions[str(i)] == "9" : # Burn Dire Wolves
			# Burn 12 Dire Wolves :
			var mission_type = 9
			var mission_description = "Burnt " + str(EventBus.dire_wolves_burnt) + " / 12 Dire Wolves"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 10 or EventBus.daily_missions[str(i)] == "10" : # Rescue Orbles               # ADD IN FUNCTIONALITY
			# Rescue 6 Orbles :
			var mission_type = 10
			var mission_description = "Rescued " + str(EventBus.orbles_rescued) + " / 2 Orbles"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 11 or EventBus.daily_missions[str(i)] == "11" : # Prepare Stews               # ADD IN FUNCTIONALITY
			# Prepare 3 Stews :
			var mission_type = 11
			var mission_description = "Prepared " + str(EventBus.stews_prepared) + " / 2 Stews"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 12 or EventBus.daily_missions[str(i)] == "12" : # Complete Dungeons
			# Complete 2 Dungeons :
			var mission_type = 12
			var mission_description = "Completed " + str(EventBus.dungeons_completed) + " / 3 Dungeons"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 13 or EventBus.daily_missions[str(i)] == "13" : # Change Shield
			# Change Shield once :
			var mission_type = 13
			var mission_description = "Shield Changed: " + str(EventBus.shield_changed)
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 14 or EventBus.daily_missions[str(i)] == "14" : # Change Outfit
			# Change Outfit once :
			var mission_type = 14
			var mission_description = "Outfit changed: " + str(EventBus.outfit_changed)
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 15 or EventBus.daily_missions[str(i)] == "15" : # Change Hat               # ADD IN FUNCTIONALITY
			# Change Hat once :
			var mission_type = 15
			var mission_description = "Hat Changed: " + str(EventBus.hat_changed)
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = mission_type

		elif daily_picker == 16 or EventBus.daily_missions[str(i)] == "16" : # Change Torch
			# Change Torch once :
			var mission_type = 16
			var mission_description = "Torch Changed: " + str(EventBus.torch_changed)
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 17 or EventBus.daily_missions[str(i)] == "17" : # Use Dash
			# Use Dash 10 times :
			var mission_type = 17
			var mission_description = "Dash Used " + str(EventBus.dash_used) + " / 40"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)

		elif daily_picker == 18 or EventBus.daily_missions[str(i)] == "18" : # Speak to NPCs
			# Speak to 5 NPCs :
			var mission_type = 18
			var mission_description = "Spoken To " + str(EventBus.npcs_spoken_to) + " / 5 NPCs"
			%OverseersBoard.get_node("Daily" + str(i)).text = mission_description
			EventBus.daily_missions[str(i)] = str(mission_type)



func pick_from_weekly_pool() :
	# THE WEEKLY MISSION POOL :
	var i = 0
	while i < 4 :
		i += 1
		var weekly_picker = 0
		if EventBus.weekly_missions[str(i)] == "0" :
			weekly_picker = randi_range(1, 18)
			while already_used_weekly_missions.has(weekly_picker) :
				weekly_picker = randi_range(1, 18)
			already_used_weekly_missions.append(weekly_picker)
		if EventBus.weekly_missions[str(i)] == "0" :
			weekly_picker = randi_range(1, 2)
		if weekly_picker == 1 or EventBus.weekly_missions[str(i)] == "1"  : # Weekly Missions Completed :
			# Complete 7 Daily Missions :
			var mission_type = 1
			var mission_description = "Completed " + str(EventBus.daily_missions_completed_during_current_week) + " / 7 Daily Missions"               # ADD IN FUNCTIONALITY
			%OverseersBoard.get_node("Weekly" + str(i)).text = mission_description
			EventBus.weekly_missions[str(i)] = str(mission_type)
			
		if weekly_picker == 2 or EventBus.weekly_missions[str(i)] == "2" : # Weekly Dungeons Crawled :
			# Complete 12 Dungeon Crawls :
			var mission_type = 2
			var mission_description = str(EventBus.weekly_dungeons_completed) + " / 12 Dungeons Crawled"
			%OverseersBoard.get_node("Weekly" + str(i)).text = mission_description
			EventBus.weekly_missions[str(i)] = str(mission_type)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# BUTTON PRESSES TO CLAIM :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_daily_claim_button_1_pressed() -> void:
	EventBus.daily_missions[str(1)] = "complete"
	%DailyClaimFinger1.visible = false
	%DailyClaimButton1.visible = false
	%DailyClaimed1.visible = true
	%DailyGold1.visible = false
	%DailyGoldSprite1.visible = false
	
	gold_addon(1)


func _on_daily_claim_button_2_pressed() -> void:
	EventBus.daily_missions[str(2)] = "complete"
	%DailyClaimFinger2.visible = false
	%DailyClaimButton2.visible = false
	%DailyClaimed2.visible = true
	%DailyGold2.visible = false
	%DailyGoldSprite2.visible = false
	
	gold_addon(1)


func _on_daily_claim_button_3_pressed() -> void:
	EventBus.daily_missions[str(3)] = "complete"
	%DailyClaimFinger3.visible = false
	%DailyClaimButton3.visible = false
	%DailyClaimed3.visible = true
	%DailyGold3.visible = false
	%DailyGoldSprite3.visible = false
	
	gold_addon(1)


func _on_daily_claim_button_4_pressed() -> void:
	EventBus.daily_missions[str(4)] = "complete"
	%DailyClaimFinger4.visible = false
	%DailyClaimButton4.visible = false
	%DailyClaimed4.visible = true
	%DailyGold4.visible = false
	%DailyGoldSprite4.visible = false
	
	gold_addon(1)


func _on_weekly_claim_button_1_pressed() -> void:
	EventBus.weekly_missions[str(1)] = "complete"
	%WeeklyClaimFinger1.visible = false
	%WeeklyClaimButton1.visible = false
	%WeeklyClaimed1.visible = true
	%WeeklyGold1.visible = false
	%WeeklyGoldSprite1.visible = false
	
	gold_addon(2)


func _on_weekly_claim_button_2_pressed() -> void:
	EventBus.weekly_missions[str(2)] = "complete"
	%WeeklyClaimFinger2.visible = false
	%WeeklyClaimButton2.visible = false
	%WeeklyClaimed2.visible = true
	%WeeklyGold2.visible = false
	%WeeklyGoldSprite2.visible = false
	
	gold_addon(2)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ANIMATIONS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func finger_tapping(finger) :
	while finger.visible == true :
		var finger_up = create_tween().set_parallel(true)
		finger_up.tween_property(finger, "rotation_degrees", finger.rotation_degrees - 10, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		finger_up.tween_property(finger, "position", finger.position + Vector2(-1, -2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await finger_up.finished
		var finger_back = create_tween().set_parallel(true)
		finger_back.tween_property(finger, "rotation_degrees", finger.rotation_degrees + 10, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		finger_back.tween_property(finger, "position", finger.position - Vector2(-1, -2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(1.2).timeout


func gold_addon(daily) :
	# Gold Addon Animation :
	if daily == 1 :
		var start_value = EventBus.total_acquired_goldpieces
		var end_value = start_value + daily_gold_reward
		var gold_addon_duration = 2.0  # Seconds
		var gold_addon_tween = create_tween()
		gold_addon_tween.tween_method(
			func(value):
				%TotalGoldText.text = str(value),
			start_value,
			end_value,
			gold_addon_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(gold_addon_duration).timeout
		var descale_tween = create_tween()
		descale_tween.tween_property(%TotalGoldText, "scale", Vector2(0.12, 0.12), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var white_tween = create_tween()
		white_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# ADDUP END GOLDPIECES
		EventBus.total_acquired_goldpieces = end_value
		
		# ADDUP END FERVOUR 
		EventBus.total_fervour += 1
		%FervourText.text = str(EventBus.total_fervour)
		await get_tree().create_timer(1.0).timeout
		
		
	if daily == 2 :
		var start_value = EventBus.total_acquired_goldpieces
		var end_value = start_value + weekly_gold_reward
		var gold_addon_duration = 2.0  # Seconds
		var gold_addon_tween = create_tween()
		gold_addon_tween.tween_method(
			func(value):
				%TotalGoldText.text = str(value),
			start_value,
			end_value,
			gold_addon_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(gold_addon_duration).timeout
		var descale_tween = create_tween()
		descale_tween.tween_property(%TotalGoldText, "scale", Vector2(0.12, 0.12), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var white_tween = create_tween()
		white_tween.tween_property(%TotalGoldText, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# ADDUP END GOLDPIECES
		EventBus.total_acquired_goldpieces = end_value
		
		# ADDUP END FERVOUR 
		EventBus.total_fervour += 3
		%FervourText.text = str(EventBus.total_fervour)
		await get_tree().create_timer(1.0).timeout
