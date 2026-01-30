extends CharacterBody2D

var squashed = false

# Touchscreen :
var touch_move = Vector2.ZERO
var input_enabled = true

var direction = Vector2.ZERO
var momentum_tail = Vector2.ZERO
var last_direction = Vector2.ZERO
var steering_change_timer = 0.0
var speed = 4000.0
var accel = 900.0
var friction = 700.0
var max_speed = 80.0

var weapon_equipped = false
var torch_equipped = true

var bobbing = false
var currently_climbing = false
var bouncing = false
var bounce_lock = 0.0 
var bounce_cooldown_finished = true

var dash_available = true
var dashing = false

func _ready():
	breathing()


func _physics_process(_delta: float) -> void:
	if input_enabled == true:

		# ---------------------------------------------------------
		# Bounce lock timer
		# ---------------------------------------------------------
		if bounce_lock > 0.0:
			bounce_lock -= _delta

		# ---------------------------------------------------------
		# Tool switching
		# ---------------------------------------------------------
		if Input.is_action_just_pressed("tool_switch"):
			initialise_swap_tool()

		# ---------------------------------------------------------
		# Dash
		# ---------------------------------------------------------
		if Input.is_action_pressed("dash"):
			dash_ability()

		# ---------------------------------------------------------
		# Input direction
		# ---------------------------------------------------------
		direction = get_move_direction()

		# ---------------------------------------------------------
		# Steering‑intent tracking (prevents bounce during navigation)
		# ---------------------------------------------------------
		if direction != Vector2.ZERO and last_direction != Vector2.ZERO:
			if direction.dot(last_direction) < 0.7:
				steering_change_timer = 0.15  # 150ms grace period

		last_direction = direction

		if steering_change_timer > 0.0:
			steering_change_timer -= _delta

		# ---------------------------------------------------------
		# Animation switching
		# ---------------------------------------------------------
		if direction != Vector2.ZERO:
			if dashing == false and bouncing == false:
				moving()
				%BrodySprite.play("moving")
		else:
			%BrodySprite.play("stationary")
			%feet.play("stationary")

		# ---------------------------------------------------------
		# Antenna movement
		# ---------------------------------------------------------
		if direction != Vector2.ZERO :
			%antenna.rotation_degrees = lerp(%antenna.rotation_degrees, -40.0, 0.12)
		else:
			%antenna.rotation_degrees = lerp(%antenna.rotation_degrees, 0.0, 0.12)

		# ---------------------------------------------------------
		# Normalize direction
		# ---------------------------------------------------------
		if direction != Vector2.ZERO:
			direction = direction.normalized()

		# ---------------------------------------------------------
		# Direction change skid
		# ---------------------------------------------------------
		if direction != Vector2.ZERO and velocity.length() > 0.1:
			var dot = velocity.normalized().dot(direction)
			if dot < 0.0:
				velocity *= 0.96

		# ---------------------------------------------------------
		# Movement control (reduced during bounce)
		# ---------------------------------------------------------
		var control = 0.24
		if bounce_lock > 0.0:
			control = lerp(control, 0.0, 0.4)

		velocity = velocity.lerp(direction * max_speed, control)

		# ---------------------------------------------------------
		# Momentum tail (follow‑through)
		# ---------------------------------------------------------
		if momentum_tail.length() > 0.1:
			velocity += momentum_tail
			momentum_tail *= 0.94

		# ---------------------------------------------------------
		# Store pre‑collision velocity
		# ---------------------------------------------------------
		var pre_velocity = velocity

		# ---------------------------------------------------------
		# Move the body
		# ---------------------------------------------------------
		move_and_slide()

		# ---------------------------------------------------------
		# Collision + Intentional Bounce System
		# ---------------------------------------------------------
		var collision = get_last_slide_collision()
		if collision and bounce_cooldown_finished == true:
			
			var normal = collision.get_normal()
			var speed = pre_velocity.length()
			var speed_ratio = speed / max_speed
			
			# -----------------------------------------------------
			# INTENTIONAL BOUNCE CONDITIONS
			# -----------------------------------------------------

			# 1. Must be moving fast enough (not navigating)
			if speed_ratio < 0.85:
				return

			# 2. Must not be moving TOO fast (post-bounce or sliding)
			if speed_ratio > 1.25:
				return

			# 3. Must be pushing INTO the wall (player intent)
			var push_intent = direction.dot(normal) < -0.6
			if not push_intent:
				return

			# 4. Must hit at a meaningful angle (not a shallow brush)
			var angle = abs(pre_velocity.normalized().dot(normal))
			if angle < 0.55:
				return

			# 5. Must not have just changed steering direction
			if steering_change_timer > 0.0:
				return

			# -----------------------------------------------------
			# Bounce is allowed — perform bounce
			# -----------------------------------------------------
			# Play Animation :
			bouncing = true
			%BrodySprite.play("roll")
			
			bounce_cooldown_finished = false
			%BounceCooldown.start()

			# 1. Perfect reflection
			var reflected = pre_velocity.bounce(normal)

			# 2. Blend reflection with original direction
			var blend = 0.35
			var blended = reflected.lerp(pre_velocity, blend)

			# 3. Slide bias for shallow angles
			var slide_amount = clamp(1.0 - angle * 2.0, 0.0, 1.0)
			var slided = blended.lerp(pre_velocity.slide(normal), slide_amount)

			# 4. Add wavy rotation
			var wave_amount = randf_range(-0.35, 0.35)
			var wavy = slided.rotated(wave_amount)

			# 5. Speed‑scaled wiggle
			var freq = 0.01 + speed * 0.00004
			var wiggle = Vector2(
				sin(Time.get_ticks_msec() * freq),
				cos(Time.get_ticks_msec() * freq * 1.2)
			) * (speed * 0.015)

			# 6. Momentum‑preserving velocity
			velocity = (wavy * 1.15) + wiggle

			# 7. Momentum tail
			momentum_tail = wavy.normalized() * (speed * 0.12)

			# 8. Curved bounce push
			var curve_dir = normal.rotated(randf_range(-0.6, 0.6)).normalized()
			var bounce_strength = clamp(speed * 0.12, 6.0, 22.0)

			var push = create_tween()
			push.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			push.tween_property(self, "position", position + curve_dir * bounce_strength, 0.24)

			# 9. Speed‑scaled bounce lock
			bounce_lock = clamp(speed * 0.024, 0.08, 0.18)

			# 10. Tiny friction
			velocity *= 0.985

			# 11. Squash + rotation feedback
			var t = create_tween()
			t.tween_property(%BrodySprite, "scale", Vector2(1.15, 0.85), 0.08)
			t.tween_property(%BrodySprite, "rotation_degrees", randf_range(-8, 8), 0.08)
			t.tween_property(%BrodySprite, "scale", Vector2(1, 1), 0.12)
			t.tween_property(%BrodySprite, "rotation_degrees", 0, 0.12)
			await t.finished
			bouncing = false

# Movement INPUT :
func get_move_direction() -> Vector2:
	if input_enabled == true:
		# Touch joystick first
		if touch_move.length() > 0.1:
			return touch_move.normalized()
			
		# Keyboard fallback
		var dir = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		)
		
		return dir.normalized()
	else:
		return Vector2.ZERO


func dash_ability():
	if input_enabled == true:
		if dash_available == true:
			bounce_cooldown_finished = true
			
			var original_mask = collision_mask
			collision_mask = 1
			
			var target_angle = velocity.angle() * 180 / PI
			
			# Lean Into Movement Direction :
			var lean = create_tween()
			lean.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			lean.tween_property(%BrodySprite, "rotation_degrees", target_angle - 20, 0.08)
			
			# Roll
			var roll_tween = create_tween()
			roll_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			var current = %BrodySprite.rotation_degrees
			var spins = 1
			var target = (floor(current / 360.0) + spins) * 0 # change to 360 when roll anim added
			var overshoot = target + 18
			
			roll_tween.tween_property(%BrodySprite, "rotation_degrees", overshoot, 0.22)
			roll_tween.tween_property(%BrodySprite, "rotation_degrees", target, 0.12)
			
			# Squash & Stretch Effect
			var squash = create_tween()
			squash.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			squash.tween_property(%BrodySprite, "scale", Vector2(1.3, 0.8), 0.1)
			squash.tween_property(%BrodySprite, "scale", Vector2(1, 1), 0.2)
			
			# Dash Logic
			dashing = true
			dash_available = false
			%DashCooldown.start()
			speed = 4000
			%feet.visible = false
			%BrodySprite.play("roll")
			
			# Acceleration phase
			for i in range(9):
				await get_tree().create_timer(0.002).timeout
				speed *= 1.112
				max_speed *= 1.112
				
			# Deceleration phase
			await get_tree().create_timer(0.18).timeout
			for i in range(4):
				await get_tree().create_timer(0.03).timeout
				speed /= 2
				max_speed /= 2
				
			await get_tree().create_timer(0.04).timeout
			speed = 4000
			max_speed = 80.0
			
			# Reset state
			collision_mask = original_mask
			dashing = false
			%feet.visible = true
			%BrodySprite.play("moving")


func moving():
	if input_enabled == true:
		while direction != Vector2.ZERO:
			%feet.play("moving")
			%FootStepParticlesLeft.emitting = true
			await get_tree().create_timer(0.2).timeout
			%FootStepParticlesRight.emitting = true
			await get_tree().create_timer(0.2).timeout


func initialise_swap_tool():
	if weapon_equipped == false:
		torch_equipped = false
		weapon_equipped = true
		%Torch.now_unequipped()
		%weapon.now_equipped()
	else:
		weapon_equipped = false
		torch_equipped = true
		%weapon.now_unequipped()
		%Torch.now_equipped()


func _on_dash_cooldown_timeout() -> void:
	dash_available = true


# Appearance :
func breathing():
	if bobbing == false:
		bobbing = true
		for i in range(6):
			%BrodySprite.position.y += 0.1
			%antenna.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4):
			%BrodySprite.position.y += 0.05
			%antenna.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6):
			%BrodySprite.position.y -= 0.1
			%antenna.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4):
			%BrodySprite.position.y -= 0.05
			%antenna.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()


# UI Tracking :
func get_nearest_unlit_brazier(player_pos: Vector2) -> Node2D:
	var braziers = get_tree().get_nodes_in_group("braziers")
	var nearest: Node2D = null
	var nearest_dist = INF
	
	for b in braziers:
		if b.lit == true:
			continue
	
		var dist = player_pos.distance_to(b.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = b
	
	return nearest


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# EXTERNAL GAMEPLAY REACTIONS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func crushed():
	if squashed == false:
		squashed = true
		input_enabled = false
		%BrodySprite.play("puddle")
		%antenna.position.y += 4
		%feet.position.y -= 2
		await get_tree().create_timer(0.55).timeout
		%antenna.position.y -= 4
		%feet.position.y += 2
		input_enabled = true
		await get_tree().create_timer(0.9).timeout
		squashed = false


func blood_splatter():
	%BloodSplatterParticles.emitting = true


func flash_white():
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)


func darkness_consuming():
	EventBus.total_current_darkness -= 4


func caught_by_wormbat(wormbat):
	EventBus.total_current_darkness -= 1
	flash_white()
	blood_splatter()
	basic_knockback(wormbat)


func got_torch_wraithed(torch_wraith):
	EventBus.total_current_darkness -= 1
	flash_white()
	blood_splatter()
	basic_knockback(torch_wraith)


func ogre_slashed(ogre):
	EventBus.total_current_darkness -= 2
	flash_white()
	blood_splatter()
	if currently_climbing == false :
		global_position.y += randf_range(-3, 3)
		global_position.x += randf_range(-3, 3)
		var knockback_direction = (global_position - ogre.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 4, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		crushed()


func basic_knockback(entity):
	if currently_climbing == false :
		global_position.y += randf_range(-2, 2)
		global_position.x += randf_range(-2, 2)
		var knockback_direction = (global_position - entity.global_position).normalized()
		var knockback_movement = create_tween()
		knockback_movement.tween_property(self, "position", position + knockback_direction * 2, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Beacon Reactions :
func resting():
	%DarknessClearingParticles.emitting = true

func nolonger_resting():
	%DarknessClearingParticles.emitting = false


# TOUCHSCREEN REACTIONS :
func _on_touch_screen_press_2_move_stick_changed(vec: Variant) -> void:
	touch_move = vec

func _on_dash_button_pressed() -> void:
	dash_ability()
	if EventBus.dungeon_crawl_button_available == true:
		EventBus.new_dungeon_crawl()


func _on_bounce_cooldown_timeout() -> void:
	bounce_cooldown_finished = true
