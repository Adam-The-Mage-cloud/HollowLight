extends Node2D

var old_food_amount = EventBus.food_accumulated


func _ready() :
	reparent(get_tree().current_scene, true)
	reparent(get_parent().get_node("Brody").get_node("BrodyCam"), true)
	global_position = get_parent().global_position
	add_to_group("deletables_sanctuary")
	update_visual()
	position += Vector2(-120, -60)


func _process(_float) -> void :
	if EventBus.currently_interacting == true and EventBus.cheffing_station_interactable == false :
		%StewLayer.visible = false
	elif EventBus.intro == true :
		%StewLayer.visible = false
	elif EventBus.clives_shop_interactable == true :
		%StewLayer.visible = false
	elif EventBus.mission_board_interactable == true :
		%StewLayer.visible = false
	elif EventBus.catballoon_shop_interactable == true :
		%StewLayer.visible = false
	elif EventBus.jackie_shop_interactable == true :
		%StewLayer.visible = false
	else :
		%StewLayer.visible = true
	
	if EventBus.raid_entity_count > 0 :
		%GoblinHead.visible = true
		%FervourLevel.visible = false
		%FervourProduction.visible = false
		%GoblinRaidRisk.visible = false
		%RaidRiskLevel.visible = false
	
	else :
		%FervourLevel.visible = true
		%FervourProduction.visible = true
		%GoblinHead.visible = false
		%GoblinRaidRisk.visible = true
		%RaidRiskLevel.visible = true
	
	if EventBus.cheffing_station_interactable == true and EventBus.currently_interacting == true :
		update_visual()
		%StewIndicator.position = Vector2(208, 58)
		%OrbleHappinessIndicator.position = Vector2(240, 100)
		%OrbleHappinessIndicator.scale = Vector2(2.5, 2.5)
		%StewIndicator.scale = Vector2(2.5, 2.5)
	else :
		%StewIndicator.position = Vector2(25, 14)
		%OrbleHappinessIndicator.position = Vector2(57, 28)
		%OrbleHappinessIndicator.scale = Vector2(2.0, 2.0)
		%StewIndicator.scale = Vector2(2.0, 2.0)
		
	%FervourText.text = str(EventBus.total_fervour)


func update_visual() :
	if old_food_amount != EventBus.food_accumulated :
		flash_white()
	old_food_amount = EventBus.food_accumulated
	# If Full :
	if EventBus.food_accumulated > 75.0 :
		%BubbleParticles.emitting = true
		%StewIndicator.play("4_4full")
		%OrbleHappinessIndicator.play("happy")
		%FervourLevel.text = "HIGH"
		%FervourLevel.add_theme_color_override("default_color", Color(0.0, 0.933, 0.0, 1.0))
		%RaidRiskLevel.text = "LOW"
		%RaidRiskLevel.add_theme_color_override("default_color", Color(0.0, 0.933, 0.0, 1.0))
		
	elif EventBus.food_accumulated > 50.0 :
		%StewIndicator.play("3_4full")
		%OrbleHappinessIndicator.play("happy")
		%FervourLevel.text = "HIGH"
		%FervourLevel.add_theme_color_override("default_color", Color(0.0, 0.933, 0.0, 1.0))
		%RaidRiskLevel.text = "LOW"
		%RaidRiskLevel.add_theme_color_override("default_color", Color(0.0, 0.933, 0.0, 1.0))
		
	elif EventBus.food_accumulated > 25.0 :
		continuously_flash_red()
		%StewIndicator.play("2_4full")
		%OrbleHappinessIndicator.play("okay")
		%FervourLevel.text = "AVERAGE"
		%FervourLevel.add_theme_color_override("default_color", Color(0.824, 0.514, 0.0, 1.0))
		%RaidRiskLevel.text = "AVERAGE"
		%RaidRiskLevel.add_theme_color_override("default_color", Color(0.824, 0.514, 0.0, 1.0))
		
	elif EventBus.food_accumulated >= 0.0 :
		continuously_flash_red()
		%StewIndicator.play("1_4full")
		%OrbleHappinessIndicator.play("sad")
		%FervourLevel.text = "LOW"
		%FervourLevel.add_theme_color_override("default_color", Color(0.878, 0.012, 0.0, 1.0))
		%RaidRiskLevel.text = "HIGH"
		%RaidRiskLevel.add_theme_color_override("default_color", Color(0.878, 0.012, 0.0, 1.0))


func flash_white() :
	var tween = create_tween()
	tween.tween_property(%StewIndicator.material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(%StewIndicator.material, "shader_parameter/flash_amount", 0.0, 0.1)

func continuously_flash_red() :
	while EventBus.food_accumulated <= 50 and EventBus.cheffing_station_interactable == false :
		var tween = create_tween()
		tween.tween_property(%StewIndicator.material, "shader_parameter/tint_amount", 0.85, 0.05)
		tween.tween_property(%StewIndicator.material, "shader_parameter/tint_amount", 0.12, 0.1)
		await get_tree().create_timer(1.2).timeout
