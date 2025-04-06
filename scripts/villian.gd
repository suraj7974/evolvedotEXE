extends CharacterBody2D

@export var state_machine: Node  
@export var sprite: AnimatedSprite2D  
@export var player: CharacterBody2D  
@export var hp_bar: ProgressBar  # Will be replaced with ColorRect
@export var detection_area: Area2D  
@export var detection_range: float = 150 
@export var ground_y_position: float = 300  # Default ground position
@export var y_offset: float = -70  # Y offset to align villain with ground - adjust this value as needed

const SPEED = 80.0
const ATTACK_RANGE = 50.0  # Attack range
const DAMAGE = 5  # Damage per hit
var health = 100
const GRAVITY = 980.0
var attack_cooldown = 0
var can_attack = true
var is_dead = false
var chase_persistence_range = 200.0
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect

func _ready():
	add_to_group("villain")
	
	print("👹 Villain initial position before adjustment: Y=", global_position.y)
	
	# Immediately adjust position at startup
	adjust_villain_position()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		if sprite:
			sprite.flip_h = true
	else:
		print("❌ ERROR: No player found!")
	
	# Create custom health bar using ColorRect
	create_custom_health_bar()
	
	# Setup state machine and animations
	state_machine = $StateMachine
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("dead"):
			sprite.sprite_frames.set_animation_loop("dead", false)
		if sprite.sprite_frames.has_animation("attack"):
			sprite.sprite_frames.set_animation_loop("attack", false)

func adjust_villain_position():
	# Force villain to the ground
	velocity.y = 0
	
	# Find player for ground reference
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_ref = players[0]
		print("🎮 Found player at Y position:", player_ref.global_position.y)
		
		# Match player's Y and apply offset to align villain's feet with ground
		global_position.y = player_ref.global_position.y - y_offset
		print("👹 Villain position adjusted to Y=", global_position.y)
		
		# Ensure collision is instantly applied
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		print("❌ Could not find player to match ground position")
		global_position.y = ground_y_position - y_offset
	
	# Extra debugging
	print("👹 Villain final position - X:", global_position.x, " Y:", global_position.y)

func create_custom_health_bar():
	# Remove existing hp_bar if any
	if hp_bar and is_instance_valid(hp_bar):
		hp_bar.queue_free()
	
	# Background bar (black/dark)
	health_bar_bg = ColorRect.new()
	health_bar_bg.color = Color(0.1, 0.1, 0.1, 0.6)
	health_bar_bg.size = Vector2(32, 1) # 1 pixel height
	health_bar_bg.position = Vector2(-16, -50)
	add_child(health_bar_bg)
	
	# Health fill (red)
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(0.8, 0.1, 0.1, 0.8)
	health_bar_fill.size = Vector2(32, 1) # 1 pixel height
	health_bar_fill.position = Vector2(0, 0) # Relative to background
	health_bar_bg.add_child(health_bar_fill)
	
	# Set initial health display
	update_health_bar()

func update_health_bar():
	if health_bar_fill:
		# Calculate width based on health percentage
		var health_percent = float(health) / 100.0
		health_bar_fill.size.x = 32 * health_percent

func is_player_near() -> bool:
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range:
			return true
		else:
			return false
	return false

func is_player_too_far() -> bool:
	if player:
		var distance = global_position.distance_to(player.global_position)
		return distance > chase_persistence_range
	return true

func _physics_process(delta):
	# Skip all processing if villain is dead
	if is_dead:
		return
		
	# Ensure position is corrected in the first few frames
	if Engine.get_frames_drawn() < 5:
		adjust_villain_position()

	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	# Apply Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0  # Reset when on the floor

	# STOP MOVEMENT IF IN IDLE STATE
	if state_machine and state_machine.current_state and state_machine.current_state.name == "villain_idlestate":
		velocity = Vector2.ZERO
		move_and_slide()  # Apply zero velocity
		return  # Exit function to stop processing further movement

	# Ensure State Machine Updates
	if state_machine:
		state_machine.update(delta)

	move_and_slide()  # Ensure movement update

func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		print("▶️ Playing villain animation: " + anim_name)
		sprite.play(anim_name)
	else:
		print("❌ ERROR: Could not play animation '" + anim_name + "'!")
	
func take_damage(amount):
	# Don't take damage if already dead
	if is_dead:
		return

	print("💥 Villain taking damage:", amount)
	health -= amount
	update_health_bar()  # Update custom health bar
	
	# Flash the sprite to indicate damage
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)  # Red tint
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)  # Reset to normal
	
	if health <= 0:
		print("💀 Villain Died!")
		is_dead = true
		health = 0
		update_health_bar()  # Update health bar to empty
		
		# Disable ALL collisions to prevent further interactions
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
			if child is Area2D:
				for area_child in child.get_children():
					if area_child is CollisionShape2D:
						area_child.set_deferred("disabled", true)
		
		# Explicitly stop all movement
		velocity = Vector2.ZERO
		move_and_slide()
		
		# Force stop processing attacks
		attack_cooldown = 999999  # Very high number to prevent attacks
		can_attack = false
		
		print("✓ Triggering dead state")
		if state_machine:
			state_machine.on_state_transition("DeadState")
		else:
			# Direct transition if method doesn't exist
			print("❌ on_state_transition method not found, trying direct state change")
			play_animation("dead")
