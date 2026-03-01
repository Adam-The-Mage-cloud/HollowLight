extends CharacterBody2D

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
