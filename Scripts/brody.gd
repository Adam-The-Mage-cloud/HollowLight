extends CharacterBody2D

var squashed = false
var brody_hittable = true
var shaking = false
var camera_shaking = false

# Touchscreen :
var touch_move = Vector2.ZERO
var input_enabled = true

var direction = Vector2.ZERO
var momentum_tail = Vector2.ZERO
var last_direction = Vector2.ZERO
var steering_change_timer = 0.0
var speed = 4000.0
var shield_slowdown_speed = 1.0
var accel = 900.0
var friction = 700.0
var max_speed = 72.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay = 64.0
var knockback_control_reduction = 0.64

var brody_saved = false
var last_safe_location = Vector2.ZERO
var last_location = Vector2.ZERO
var safe_frames = 0
const SAFE_FRAMES_REQUIRED = 4 

var weapon_equipped = false
var shield_equipped = false
var torch_equipped = true

var bobbing = false
var currently_climbing = false
var bouncing = false
var bounce_lock = 0.0 
var bounce_cooldown_finished = true

var dash_available = true
var dashing = false

# Cosmetics :
var outfit

func _ready():
	#_on_check_brody_location_okay()
	outfit = EventBus.equipped_brodyoutfit
	breathing()


func _physics_process(delta: float) -> void:
	if input_enabled == true:

		# ---------------------------------------------------------
		# Bounce lock timer
		# ---------------------------------------------------------
		if bounce_lock > 0.0:
			bounce_lock -= delta

		# ---------------------------------------------------------
		# Tool switching
		# ---------------------------------------------------------
		if Input.is_action_just_pressed("tool_switch"):
			initialise_shield_equip()

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
			steering_change_timer -= delta

		# ---------------------------------------------------------
		# Animation switching
		# ---------------------------------------------------------
		if direction != Vector2.ZERO:
			if dashing == false and bouncing == false:
				moving()
				%BrodySprite.play(str(outfit) + "_moving")
		else:
			%BrodySprite.play(str(outfit) + "_stationary")
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
		# Movement control (reduced during bounce or knockback)
		# ---------------------------------------------------------
		var control = 0.24

		# Reduce control during bounce
		if bounce_lock > 0.0:
			control = lerp(control, 0.0, 0.4)

		# Reduce control during knockback
		if knockback_velocity.length() > 1.0:
			control *= knockback_control_reduction

		# Apply steering
		velocity = velocity.lerp(direction * max_speed * shield_slowdown_speed, control)

		# ---------------------------------------------------------
		# Apply knockback
		# ---------------------------------------------------------
		velocity += knockback_velocity

		# Decay knockback
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		
		# ---------------------------------------------------------
		# Momentum tail
		# ---------------------------------------------------------
		if momentum_tail.length() > 0.1:
			velocity += momentum_tail
			momentum_tail *= 0.94
			
		var pre_velocity = velocity 

		# ---------------------------------------------------------
		# Move the body
		# ---------------------------------------------------------
		move_and_slide()

		# ---------------------------------------------------------
		# Collision + Intentional Bounce System
		# ---------------------------------------------------------
		var collision = get_last_slide_collision()
		if collision and bounce_cooldown_finished == true and dashing == true :
			
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
			%BrodySprite.play(str(outfit) + "_roll")
			
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
	# --- safety block at the end ---
	var overlapping = %BrodyMapStuckCollision.get_overlapping_areas().size() > 0
	var on_floor = is_on_floor_tile()

	# If Brody is safe, increment counter
	if not overlapping and on_floor:
		safe_frames += 1
		if safe_frames >= SAFE_FRAMES_REQUIRED:
			last_safe_location = global_position
			brody_saved = false

	# If Brody is unsafe, restore and reset counter
	elif (overlapping or not on_floor) and not dashing:
		global_position = last_safe_location
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		brody_saved = true
		safe_frames = 0


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


func pickup_shield() :
	EventBus.shield_acquired = "default"
	%brody_shield.check_shield()
	%ShieldButton.visible = true
	EventBus.save_game()
	
	# Display How To Use Shield Manual :
	var manual = preload("res://Scenes/shield_manual.tscn").instantiate()
	manual.global_position = %BrodyCam.position
	%BrodyCam.call_deferred("add_child", manual)


func dash_ability():
	
	if input_enabled == true:
		if dash_available == true:
			# Decrease size of collision body :
			%BrodyHitbox.scale = Vector2(0.15, 0.15)
			
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
			var upgraded = 0.75 / pow(1.0 / 0.88, EventBus.amount_dash_timing_upgraded)
			%DashCooldown.wait_time = clamp(upgraded, 0.4, 1.0)
			%DashCooldown.start()
			speed = 4000
			%feet.visible = false
			%BrodySprite.play(str(outfit) + "_roll")
			
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
			max_speed = 72.0
			
			# Reset state
			%BrodyHitbox.scale = Vector2(0.475, 0.475)
			collision_mask = original_mask
			dashing = false
			%feet.visible = true
			%BrodySprite.play(str(outfit) + "_moving")


func moving():
	if input_enabled == true:
		while direction != Vector2.ZERO:
			%feet.play("moving")
			%FootStepParticlesLeft.emitting = true
			await get_tree().create_timer(0.2).timeout
			%FootStepParticlesRight.emitting = true
			await get_tree().create_timer(0.2).timeout


func initialise_shield_equip():
	if %brody_shield.equipped == false : # Equip :
		shield_equipped = true
		%brody_shield.equipped = true
		%brody_shield.unequipped = false
		%brody_shield.z_index = 1
		%ShieldStrap.visible = false
		%brody_shield.shield_collision()
	else : # Unequip :
		shield_equipped = false
		%brody_shield.equipped = false
		%ShieldStrap.visible = true
		%brody_shield.z_index = -1


func _on_dash_cooldown_timeout() -> void:
	dash_available = true
	var tween = create_tween()
	tween.tween_property(%DashButton.material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(%DashButton.material, "shader_parameter/flash_amount", 0.0, 0.1)


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

# COSMETICS :
func change_outfit() :
	EventBus.outfit_changed = true
	outfit = EventBus.equipped_brodyoutfit


func change_shield() :
	EventBus.shield_changed = true
	%brody_shield._ready()
	# Make Shield Equip Button Appear :
	%ShieldButton.visible = true


func change_torch() :
	EventBus.torch_changed = true
	%Torch.change_skin()
	# Make Appear for a bit :
	%Torch.visible = true

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
		%BrodySprite.play(str(outfit) + "_moving")
		%antenna.position.y -= 4
		%feet.position.y += 2
		input_enabled = true
		await get_tree().create_timer(0.9).timeout
		squashed = false


func pickup_shake() :
	if shaking == false :
		shaking = true
		var original = %BrodySprite.position
		for i in 1:
			%BrodySprite.position.x = original.x + randf_range(-0.5, 0.5)
			await get_tree().create_timer(0.03).timeout
		%BrodySprite.position = original
		shaking = false


func camera_shake():
	if camera_shaking:
		return
	
	camera_shaking = true
	var original = %BrodyCam.offset
	
	var tween = create_tween()
	
	tween.tween_method(
		func(v):
			%BrodyCam.offset = original + Vector2(randf_range(-v, v), randf_range(-v, v))
			, 4.0, 0.0, 0.25
	)
	
	tween.tween_property(%BrodyCam, "offset", original, 0.1)
	
	await tween.finished
	camera_shaking = false

func camera_shake_small(intensity = 1.0):
	if camera_shaking:
		return
	
	camera_shaking = true
	var original = %BrodyCam.offset
	intensity = randf_range(0.2, 1.0)
	
	# Clamp intensity so enemies can't break the camera
	intensity = clamp(intensity, 0.2, 1.0)
	
	# Max shake amount (scaled by intensity)
	var max_shake = 1.5 * intensity   # very subtle
	
	var tween = create_tween()
	
	tween.tween_method(
		func(v):
			# v goes from max_shake → 0
			var shake = Vector2(
				randf_range(-v, v),
				randf_range(-v, v)
			)
			%BrodyCam.offset = original + shake
			,
			max_shake, 0.0, 0.18 + (0.05 * intensity)  # duration scales slightly
	)
	
	tween.tween_property(%BrodyCam, "offset", original, 0.08)
	
	await tween.finished
	camera_shaking = false


func blood_splatter():
	%BloodSplatterParticles.emitting = true


func flash_white():
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)

func make_darkness_invisible() :
	%Shadow.visible = false

func make_darkness_visible() :
	%Shadow.visible = true

func lose_torch() :
	%TouchScreenLayer.visible = false
	%Torch.get_lost()

func darkness_consuming():
	%Shadow.apply_darkness_damage()
	EventBus.total_current_darkness += 4


func caught_by_wormbat(wormbat):
	if brody_hittable == true :
		brody_hittable = false
		%AttackedCooldown.start()
		EventBus.total_current_darkness += 1
		%Shadow.apply_darkness_damage()
		flash_white()
		blood_splatter()
		camera_shake_small()
		basic_knockback(wormbat)


func got_torch_wraithed(torch_wraith):
	if brody_hittable == true :
		brody_hittable = false
		%AttackedCooldown.start()
		EventBus.total_current_darkness += 1
		%Shadow.apply_darkness_damage()
		flash_white()
		blood_splatter()
		camera_shake_small()
		basic_knockback(torch_wraith)


func ogre_slashed(ogre):
	if brody_hittable == true :
		brody_hittable = false
		%AttackedCooldown.start()
		EventBus.total_current_darkness += 2
		flash_white()
		blood_splatter()
		camera_shake()
		if currently_climbing == false :
			basic_knockback(ogre)
			crushed()


func slowed() :
	if brody_hittable == true :
		brody_hittable = false
		%AttackedCooldown.start()
		EventBus.total_current_darkness += 2
		flash_white()
		blood_splatter()
		camera_shake_small()
		var initial_speed = speed
		speed = speed * 0.33
		await get_tree().create_timer(0.8).timeout
		speed = initial_speed


func basic_knockback(entity):
	if brody_hittable:
		brody_hittable = false
		flash_white()
		%AttackedCooldown.start()
		
		var dir = (global_position - entity.global_position).normalized()
		if %brody_shield.equipped == false :
			knockback_velocity += dir * 24   # small push
			camera_shake_small()
		else :
			knockback_velocity += dir * 8


func massive_knockback(entity):
	if brody_hittable:
		brody_hittable = false
		flash_white()
		camera_shake()
		%AttackedCooldown.start()
		
		var dir = (global_position - entity.global_position).normalized()
		if %brody_shield.equipped == false :
			knockback_velocity += dir * 49  # medium push
		else :
			knockback_velocity += dir * 14


func crab_punch(entity):
	if brody_hittable:
		brody_hittable = false
		flash_white()
		%AttackedCooldown.start()
		
		var dir = (global_position - entity.global_position).normalized()
		if %brody_shield.equipped == false :
			knockback_velocity += dir * 36  # strong push
			camera_shake_small()
		else :
			knockback_velocity += dir * 12  # strong push


func grindstone_bounce(entity):
	if brody_hittable:
		brody_hittable = false
		flash_white()
		%AttackedCooldown.start()
		
		var dir = (global_position - entity.global_position).normalized()
		if %brody_shield.equipped == false :
			knockback_velocity += dir * 64  # huge push
			camera_shake()
		else :
			knockback_velocity += dir * 16  # huge push


# Beacon Reactions :
func resting():
	%DarknessClearingParticles.emitting = true


func nolonger_resting():
	%DarknessClearingParticles.emitting = false


# TOUCHSCREEN REACTIONS :
func _on_touch_screen_press_2_move_stick_changed(vec: Variant) -> void:
	touch_move = vec


func _on_dash_button_pressed() -> void:
	EventBus.dash_used += 1
	dash_ability()
	if EventBus.sanctuary == true :
		if EventBus.currently_interacting == false :
			if EventBus.dungeon_crawl_button_available == true and EventBus.raid_entity_count <= 0 :
				EventBus.new_dungeon_crawl()
				make_darkness_visible()
				EventBus.npcs_spoken_to += 1
				
			elif EventBus.clives_shop_interactable == true:
				EventBus.currently_interacting = true
				EventBus.clives_shop_available()
				EventBus.npcs_spoken_to += 1
				
			elif EventBus.tutorial_replay_available == true :
				EventBus.intro = true
				EventBus.currently_interacting = true
				$"..".delete_current_memory()
				$".."._ready()
				
			elif EventBus.catballoon_shop_interactable == true :
				EventBus.currently_interacting = true
				%DashButton.visible = false
				%TouchScreenPress2.visible = false
				EventBus.npcs_spoken_to += 1
				var balloon_shop = preload("res://Scenes/travellers_sanctuary/ShopMenus/catballoon_shop.tscn").instantiate()
				balloon_shop.global_position = %BrodyCam.position
				%BrodyCam.call_deferred("add_child", balloon_shop)
				
			elif EventBus.jackie_shop_interactable == true :
				EventBus.currently_interacting = true
				%DashButton.visible = false
				%TouchScreenPress2.visible = false
				EventBus.npcs_spoken_to += 1
				var jackies_shop = preload("res://Scenes/travellers_sanctuary/ShopMenus/jackies_shop.tscn").instantiate()
				jackies_shop.global_position = %BrodyCam.position
				%BrodyCam.call_deferred("add_child", jackies_shop)
				
			elif EventBus.mission_board_interactable == true :
				EventBus.currently_interacting = true
				%DashButton.visible = false
				%TouchScreenPress2.visible = false
				EventBus.npcs_spoken_to += 1
				var mission_board = preload("res://Scenes/travellers_sanctuary/ShopMenus/overseers_board_menu.tscn").instantiate()
				mission_board.global_position = %BrodyCam.position
				%BrodyCam.call_deferred("add_child", mission_board)
				
			elif EventBus.cheffing_station_interactable == true :
				EventBus.currently_interacting = true
				%DashButton.visible = false
				%TouchScreenPress2.visible = false
				EventBus.npcs_spoken_to += 1
				var cheffing_station = preload("res://Scenes/travellers_sanctuary/OrbleVillage/stewpot_menu.tscn").instantiate()
				cheffing_station.global_position = %BrodyCam.position
				%BrodyCam.call_deferred("add_child", cheffing_station)


func _on_shield_button_pressed() -> void:
	initialise_shield_equip()
	if %brody_shield.equipped == true :
		%ShieldHighlighted.visible = false
	else :
		%ShieldHighlighted.visible = true

func _on_bounce_cooldown_timeout() -> void:
	bounce_cooldown_finished = true


func is_on_floor_tile() -> bool:
	var check_pos = global_position + Vector2(0, 0)
	
	for tm in get_tree().get_nodes_in_group("floors"):
		if tm.get_parent().visible == true :
			var local = tm.to_local(check_pos)
			var cell = tm.local_to_map(local)
			
			var data = tm.get_cell_tile_data(cell)
			if data != null:
				return true
	
	return false


func _on_attacked_cooldown_timeout() -> void:
	brody_hittable = true

func shop_closed() :
	$"..".shop_closed()
