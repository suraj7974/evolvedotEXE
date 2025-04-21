extends CharacterBody2D

@export var state_machine: Node  
@export var sprite: AnimatedSprite2D  
@export var player: CharacterBody2D  
@export var detection_area: Area2D  
@export var detection_range: float = 150 
@export var ground_y_position: float = 300  # Default ground position
@export var y_offset: float = -70  # Y offset to align villain with ground
@export var enable_learning: bool = true  # Enable/disable reinforcement learning

var SPEED = 80.0  # Changed from const to var so it can be modified
var ATTACK_RANGE = 50.0  # Changed from const to var so it can be modified
var DAMAGE = 5  # Changed from const to var so it can be modified
var health = 100
var MAX_DISPLAY_HEALTH = 100  # This will be updated based on current level
const GRAVITY = 980.0
var attack_cooldown = 0
var can_attack = true
var is_dead = false
var chase_persistence_range = 200.0
var villain_name = "VILLAIN"  # Name to display on the UI

# For AttackPatternLearner
var attack_learner: AttackPatternLearner  # Reference to our reinforcement learning system

# Helper method to set attack cooldown
func set_attack_cooldown(duration: float) -> void:
	attack_cooldown = duration
	can_attack = false
	print("🕒 Villain attack on cooldown for " + str(duration) + " seconds")

func _ready():
	add_to_group("villain")
	
	print("👹 Villain initial position before adjustment: Y=", global_position.y)
	
	# Initialize attack pattern learning system
	if enable_learning:
		attack_learner = AttackPatternLearner.new()
		print("🧠 Attack pattern learning system initialized")
	
	# Set MAX_DISPLAY_HEALTH based on current level
	# First, try to find the LevelManager to determine which level we're on
	if Engine.get_singleton("LevelManager") or get_node_or_null("/root/LevelManager"):
		var level_data = LevelManager.level_data
		var current_level = LevelManager.current_level
		
		if current_level in level_data and "villain" in level_data[current_level]:
			# Set the max health display to match the current level's villain health
			MAX_DISPLAY_HEALTH = level_data[current_level]["villain"]["health"]
			print("✅ Adjusted MAX_DISPLAY_HEALTH to: " + str(MAX_DISPLAY_HEALTH))
	
	# Immediately adjust position at startup
	adjust_villain_position()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		if sprite:
			sprite.flip_h = true
	else:
		print("❌ ERROR: No player found!")
	
	# Update health in the fighting game HUD
	update_health_bar()
	
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

func update_health_bar():
	# Find the HUD created by the player
	var hud = get_node_or_null("/root/GameHUD")
	if not hud:
		# If HUD doesn't exist yet, the player will create it
		return
	
	# Print debug info for health bar update
	print("🔄 Updating villain health bar - Current health: " + str(health) + 
		", Max display health: " + str(MAX_DISPLAY_HEALTH))
	
	# Access villain health components
	var health_container = hud.get_node_or_null("FightingGameHUD/TopBar/VillainHealthContainer")
	if health_container:
		# Update health text - show actual health value
		var health_text = health_container.get_node_or_null("VillainLayout/VillainHealthText")
		if health_text:
			health_text.text = str(int(health))
		
		# Update health bar fill with new path structure
		var villain_layout = health_container.get_node_or_null("VillainLayout")
		if villain_layout:
			var bar_container = villain_layout.get_node_or_null("VillainBarContainer")
			if bar_container:
				var health_bg = bar_container.get_node_or_null("VillainHealthBarBG")
				if health_bg:
					var health_fill = health_bg.get_node_or_null("VillainHealthBarFill")
					if health_fill:
						# Calculate percentage based on MAX_DISPLAY_HEALTH instead of actual health
						var percent = clamp(float(health) / float(MAX_DISPLAY_HEALTH), 0.0, 1.0)
						var new_width = int(256 * percent)
						
						# Force immediate size update to ensure bar decreases properly
						health_fill.size.x = new_width
						
						print("📊 Health bar updated: " + str(health) + "/" + str(MAX_DISPLAY_HEALTH) + 
							" = " + str(percent) + " → Width: " + str(new_width))
						
						# Change color based on health ratio relative to MAX_DISPLAY_HEALTH
						var health_ratio = float(health) / float(MAX_DISPLAY_HEALTH)
						if health_ratio < 0.3:
							health_fill.color = Color(0.9, 0.1, 0.1, 1.0)  # Intense red when low
						elif health_ratio < 0.6:
							health_fill.color = Color(0.9, 0.4, 0.2, 1.0)  # Orange when medium
						else:
							health_fill.color = Color(0.9, 0.2, 0.2, 1.0)  # Standard red when high
		
		# Update villain name
		var name_label = health_container.get_node_or_null("VillainLayout/VillainNameLabel")
		if name_label:
			name_label.text = villain_name

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
	
func take_damage(amount, attack_type: String = "attack1"):
	# Don't take damage if already dead
	if is_dead:
		return

	# Calculate actual damage after applying learning-based resistance
	var actual_damage = amount
	if enable_learning and attack_learner:
		# Register this attack for learning
		attack_learner.register_attack(attack_type)
		
		# Apply resistance to reduce damage from repetitive attacks
		var resistance = attack_learner.get_resistance(attack_type)
		actual_damage = amount * (1.0 - resistance)
		
		# Show feedback when resistance is in effect
		if resistance > 0.2:  # Only show if resistance is significant
			print("🛡️ Villain resisted " + str(int(resistance * 100)) + "% of " + attack_type + " damage!")
			
			# Visual feedback for resistance
			if sprite:
				sprite.modulate = Color(0.7, 0.7, 1.0)  # Blue tint for resistance
				await get_tree().create_timer(0.1).timeout
				sprite.modulate = Color(1, 1, 1)  # Reset to normal
	
	# Apply the (potentially reduced) damage
	print("💥 Villain taking damage:", actual_damage, " (original: ", amount, ")")
	health -= actual_damage
	update_health_bar()  # Update the health bar in the HUD
	
	# Flash the sprite to indicate damage
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)  # Red tint
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)  # Reset to normal
	
	# Check for death
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

# Reset the villain's learning when respawning
func reset_learning():
	if enable_learning and attack_learner:
		attack_learner.reset_learning()
		print("🧠 Villain's attack pattern memory has been reset")
