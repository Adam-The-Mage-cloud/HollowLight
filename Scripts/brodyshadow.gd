extends Sprite2D

var corruption = 0.0
var jitter_timer = 0.0
var default_position = Vector2.ZERO

# Full transformation
var _do_full_transform = false
var _brody_original_pos = Vector2.ZERO
var _shadow_original_pos = Vector2.ZERO
var _corruption_level = 0.0

# Death control
var _death_locked := false
var _death_tween: Tween = null


func _ready() -> void:
	default_position = position
	set_process(true)


func apply_darkness_damage() -> void:
	jitter_timer = 0.1


func _process(delta: float) -> void:
	# Update corruption
	corruption = EventBus.total_current_darkness / 100.0
	%Shadow.modulate.a = corruption

	# --- JITTER WHEN TAKING DAMAGE ---
	if jitter_timer > 0.0:
		jitter_timer -= delta
		%Shadow.position = Vector2(
			randf_range(-0.25, 0.25) * corruption,
			randf_range(-0.25, 0.25) * corruption
		)
	else:
		%Shadow.position = default_position

	# --- RECOVERY WHILE GLITCHING ---
	if _do_full_transform and not _death_locked and EventBus.total_current_darkness < 99.5:
		_recover_from_shadow_glitch()
		return

	# --- FULL TRANSFORMATION MOTION ---
	if _do_full_transform:
		var brody = %BrodySprite
		var shadow = %Shadow

		# Brody shaking
		var shake_strength = 1.5
		brody.position = _brody_original_pos + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		# Shadow drifting
		var t = Time.get_ticks_msec() * 0.002
		var drift_strength = _corruption_level * 6.0

		shadow.position = _shadow_original_pos + Vector2(
			sin(t * 1.3) * drift_strength,
			cos(t * 0.9) * drift_strength
		)


func _on_full_shadow_checker_timeout() -> void:
	# If we've already died once, clamp darkness and bail
	if EventBus.death_played == true:
		EventBus.total_current_darkness = 0
		return

	# Only start if fully dark
	if EventBus.total_current_darkness < 99.5:
		return

	var brody = %BrodySprite
	var shadow = %Shadow

	# Store original positions
	_brody_original_pos = brody.position
	_shadow_original_pos = shadow.position

	# Store corruption level for drifting motion
	_corruption_level = EventBus.total_current_darkness / 100.0

	# Enable shaking + drifting
	_do_full_transform = true
	_death_locked = false

	# Fade Brody out
	_death_tween = create_tween()
	_death_tween.tween_property(brody, "modulate:a", 0.0, 2.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	# After fade, lock death and start animation
	_death_tween.tween_interval(1.0)
	_death_tween.tween_callback(func():
		_death_locked = true
		play_death_animation()
	)

	# When finished, stop everything (only if not recovered)
	_death_tween.finished.connect(func():
		_do_full_transform = false
		set_process(false)
		brody.position = _brody_original_pos
		shadow.position = _shadow_original_pos
	)


func _recover_from_shadow_glitch() -> void:
	_do_full_transform = false

	# Kill fade-out tween
	if _death_tween and is_instance_valid(_death_tween):
		_death_tween.kill()
		_death_tween = null

	# Restore Brody
	var brody = %BrodySprite
	var shadow = %Shadow

	brody.modulate.a = 1.0
	brody.self_modulate = Color.WHITE

	# Reset positions
	brody.position = _brody_original_pos
	shadow.position = _shadow_original_pos


func play_death_animation() -> void:
	# Once we're here, no more recovery
	if EventBus.death_played == false:
		EventBus.death_played = true
		$"../..".input_enabled = false

		# Burn Up Animation :
		%antenna.position.y += 4
		%feet.position.y -= 2
		%BrodySprite.play("shadow")
		%BrodyShadow.visible = false
		$"../..".lose_torch()

		var first_flash = create_tween()
		first_flash.tween_property(%BrodySprite, "self_modulate", Color(0.0, 0.0, 0.0, 1.0), 0.24)
		first_flash.tween_property(%antenna, "self_modulate", Color(0.0, 0.0, 0.0, 1.0), 0.24)
		first_flash.tween_property(%feet, "self_modulate", Color(0.0, 0.0, 0.0, 1.0), 0.24)
		first_flash.tween_property(%FadedText, "modulate", Color(1.0, 1.0, 1.0, 0.878), 0.24)
		await first_flash.finished

		%BrodySprite.play("puddle")
		hover_away()
		await get_tree().create_timer(3.0).timeout
		EventBus.player_died()
		brody_reset()


func hover_away() -> void:
	var brody = self

	var angle = randf_range(-1.2, -1.0)  # gentle upward drift
	var direction = Vector2(cos(angle), sin(angle)).normalized()
	var distance = randf_range(24.0, 36.0)
	var target = brody.position + direction * distance

	var t = create_tween()

	t.tween_property(brody, "position", target, 4.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	t.parallel().tween_method(
		func(v):
			brody.position += Vector2(
				randf_range(-0.4, 0.4),
				randf_range(-0.4, 0.4)
			)
	, 0.0, 1.0, 1.2)

	t.parallel().tween_property(
		brody,
		"rotation_degrees",
		brody.rotation_degrees + randf_range(5, 15),
		1.2
	)


func brody_reset() -> void:
	$"../..".input_enabled = true
	%antenna.position.y -= 4
	%feet.position.y += 2
	%BrodySprite.play("stationary")
	%BrodySprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	%antenna.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	%feet.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	%BrodySprite.modulate.a = 1.0
	%Shadow.modulate.a = 0.0
	%BrodyShadow.visible = true
	await get_tree().create_timer(1.0).timeout
	%FadedText.modulate.a = 0.0
	$".".position = default_position
	set_process(true)
