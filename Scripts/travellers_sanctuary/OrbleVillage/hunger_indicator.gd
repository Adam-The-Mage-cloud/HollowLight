extends Node2D

var old_food_amount = EventBus.food_accumulated


func _ready() :
	reparent(get_tree().current_scene, true)
	reparent(get_parent().get_node("Brody").get_node("BrodyCam"), true)
	global_position = get_parent().global_position
	add_to_group("deletables_sanctuary")
	check_hourly_food_update()
	update_visual()
	position += Vector2(-120, -60)


func _process(_float) -> void :
	if EventBus.currently_interacting == true and EventBus.cheffing_station_interactable == false :
		%StewLayer.visible = false
	else :
		%StewLayer.visible = true
	
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

# If it's been an hour, reduce amount of food by 4 :
func check_hourly_food_update():
	var now = Time.get_unix_time_from_system()
	if EventBus.last_hourly_food_update == 0:
		EventBus.last_hourly_food_update = now
		return
	
	var hours_passed = int((now - EventBus.last_hourly_food_update) / 3600)
	
	if hours_passed > 0:
		EventBus.food_accumulated -= 4 * hours_passed
		EventBus.food_accumulated = clamp(EventBus.food_accumulated, 0.0, 100.0)
		update_visual()
		EventBus.last_hourly_food_update = now


func update_visual() :
	print("updated")
	if old_food_amount != EventBus.food_accumulated :
		print("flash_white")
		flash_white()
	old_food_amount = EventBus.food_accumulated
	# If Full :
	if EventBus.food_accumulated > 75.0 :
		%BubbleParticles.emitting = true
		%StewIndicator.play("4_4full")
		%OrbleHappinessIndicator.play("happy")
		
	elif EventBus.food_accumulated > 50.0 :
		%StewIndicator.play("3_4full")
		%OrbleHappinessIndicator.play("happy")
		
	elif EventBus.food_accumulated > 25.0 :
		continuously_flash_red()
		%StewIndicator.play("2_4full")
		%OrbleHappinessIndicator.play("okay")
		
	elif EventBus.food_accumulated >= 0.0 :
		continuously_flash_red()
		%StewIndicator.play("1_4full")
		%OrbleHappinessIndicator.play("sad")


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
