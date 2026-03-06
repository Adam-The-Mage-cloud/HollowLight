extends CharacterBody2D

var manual = false
var fervour_to_collect = false
var fervour_gained = 0

func _ready() :
	floating_rock()


func floating_rock():
	var rock_count = 6
	var radius = 20.24
	var duration = 24.0
	var vertical_offset = -5.0
	var counter = 0

	for i in rock_count:
		counter += 1
		var rock = %RitualSprite.get_node("FloatingRock" + str(counter))
		var angle_offset = TAU * (float(i) / rock_count)

		var t = create_tween().set_loops().set_parallel(true)

		# Spin
		t.tween_property(rock, "rotation_degrees", 360.0, duration)

		# Orbit
		t.tween_method(
			func(angle):
				rock.position = Vector2(
					cos(angle + angle_offset),
					sin(angle + angle_offset)
		) * radius + Vector2(0, vertical_offset)
		,
			0.0, TAU, duration
		)

func fervour_to_be_gained(calculated_fervour) :
	fervour_to_collect = true
	fervour_gained = calculated_fervour
	%EarntFervour.text = str(calculated_fervour)
	fervour_point_animation()

func fervour_fly_out() :
	var FervourScene = preload("res://Scenes/travellers_sanctuary/OrbleVillage/fervour_collection.tscn")
	fervour_to_collect = false
	%FervourSprite.visible = false
	for i in range(fervour_gained):
		print ("spawned")
		var fervour = FervourScene.instantiate()
		fervour.global_position = Vector2(randi_range(-35, 35), randi_range(-5, 42)) + $".".position
		get_parent().call_deferred("add_child", fervour)

func _on_ritual_area_body_entered(body: Node2D) -> void:
	if body.name == "Brody" and fervour_to_collect == true :
		%ExclamationMarkIndicator.visible = false
		EventBus.ritual_statue_interactable = true
		%RitualSprite.play("highlighted")
		fervour_fly_out()
	if EventBus.intro == true and manual == false and body.name == "Brody" :
		load_ritual_manual()

func load_ritual_manual() :
	var ritual_manual = preload("res://Scenes/travellers_sanctuary/OrbleVillage/ritual_manual.tscn").instantiate()
	call_deferred("add_child", ritual_manual)
	manual = true

func _on_ritual_area_body_exited(body: Node2D) -> void:
	if body.name == "Brody" :
		EventBus.ritual_statue_interactable = false
		%RitualSprite.play("default")


func fervour_point_animation() :
	%FervourSprite.visible = true
	while fervour_to_collect == true:
		var up_ex = create_tween().set_parallel(true)
		up_ex.tween_property(%FervourSprite, "global_position", %FervourSprite.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween().set_parallel(true)
		down_ex.tween_property(%FervourSprite, "global_position", %FervourSprite.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		
		
		await down_ex.finished
	%FervourSprite.visible = false


func exclamation_animation() :
	%ExclamationMarkIndicator.visible = true
	while $".".visible == true:
		var up_ex = create_tween().set_parallel(true)
		up_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position + Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		up_ex.tween_property(%FervourText, "scale", Vector2(0.2, 0.2), 1.6)
		
		# Wait for le both tweens du finieash :
		await up_ex.finished
		
		var down_ex = create_tween().set_parallel(true)
		down_ex.tween_property(%ExclamationMarkIndicator, "global_position", %ExclamationMarkIndicator.global_position - Vector2(2, -11), 1.6).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
		down_ex.tween_property(%FervourText, "scale", Vector2(0.12, 0.12), 1.6)
		
		
		await down_ex.finished
	%ExclamationMarkIndicator.visible = false
