extends CharacterBody2D

func _ready() :
	set_and_check_missions()


func _on_mission_board_access_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" :
		%MissionBoardSprite.play("highlighted")
		%orble_overseer.player_interested()
		EventBus.mission_board_interactable = true
		%ExclamationMarkIndicator.visible = false


func _on_mission_board_access_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		%MissionBoardSprite.play("default")
		%orble_overseer.player_uninterested()
		EventBus.mission_board_interactable = false
		set_and_check_missions()


func set_and_check_missions():
	# Daily
	for i in range(1, 5):
		if EventBus.daily_missions.has(str(i)):
			apply_daily_mission(i)
	
	# Weekly
	for i in range(1, 3):
		if EventBus.weekly_missions.has(str(i)):
			apply_weekly_mission(i)




# THIS ALSO CHECKS TO SEE IF OBJECTIVES HAVE BEEN COMPLETED SO WE CAN SHOW THE EXCLAMATION MARK INDICATOR!
func apply_daily_mission(i: int):
	var mission_type = EventBus.daily_missions[str(i)]
	print (EventBus.daily_missions[str(i)])

	match mission_type:
		"1":
			if EventBus.draugr_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
				
		"2":
			if EventBus.mudcrabs_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"3":
			if EventBus.ogres_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"4":
			if EventBus.goblins_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"5":
			if EventBus.grindstonters_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"6":
			if EventBus.witches_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"7":
			if EventBus.torch_wraiths_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"8":
			if EventBus.soul_eaters_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"9":
			if EventBus.dire_wolves_burnt >= 12 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"10":
			if EventBus.orbles_rescued >= 2 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"11":
			if EventBus.stews_prepared >= 2 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"12":
			if EventBus.dungeons_completed >= 3 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"13":
			if EventBus.shield_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"14":
			if EventBus.outfit_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"15":
			if EventBus.hat_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"16":
			if EventBus.torch_changed == true and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"17":
			if EventBus.dash_used >= 40 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
		"18":
			if EventBus.npcs_spoken_to >= 5 and EventBus.daily_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()


func apply_weekly_mission(i: int):
	var mission_type = EventBus.weekly_missions[str(i)]

	match mission_type:
		"1":
			if EventBus.daily_missions_completed_during_current_week >= 7 and EventBus.weekly_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()
				
		"2":
			if EventBus.weekly_dungeons_completed >= 12 and EventBus.weekly_missions[str(i)] != "complete":
				%ExclamationMarkIndicator.visible = true
				exclamation_animation()


func exclamation_animation() :
	while $".".visible == true:
		var up_ex = create_tween()
		up_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween()
		down_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		
		await down_ex.finished
