extends CharacterBody2D

@export var state_machine: Node  
@export var sprite: AnimatedSprite2D  
@export var player: CharacterBody2D  
@export var hp_bar: ProgressBar  
@export var detection_area: Area2D  
@export var detection_range: float = 150 

const SPEED = 80.0
const ATTACK_RANGE = 50.0  # Reduced attack range so player has a chance
const DAMAGE = 5  # Reduced damage per hit to make it fairer
var health = 100
const GRAVITY = 980.0
var attack_cooldown = 0
var can_attack = true
var is_dead = false  # Add a flag to track death state

func _ready():
	add_to_group("villain")  # Add villain to a group for player attacks
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]  # Get the first player
		print("✅ Player assigned successfully!")
	else:
		print("❌ ERROR: No player found in group 'player'!")
	hp_bar.max_value = health
	hp_bar.value = health
	print("Villain Y:", global_position.y)

	# ✅ Ensure the State Machine is loaded
	state_machine = $StateMachine  
	if state_machine:
		print("✅ Villain State Machine Loaded Successfully!")

func is_player_near() -> bool:
	if player:
		var distance = global_position.distance_to(player.global_position)
		print("🔍 Player Distance:", distance, "| Detection Range:", detection_range)

		if distance < detection_range:
			print("✅ Player is within detection range!")
			return true
		else:
			print("🛑 Player is too far, villain should NOT follow!")
			return false

	return false

func _physics_process(delta):
	# Skip all processing if villain is dead
	if is_dead:
		return

	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	# ✅ Apply Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0  # Reset when on the floor

	# ✅ STOP MOVEMENT IF IN IDLE STATE
	if state_machine and state_machine.current_state.name == "villain_idlestate":
		print("🛑 Force Stopping Movement in IdleState")
		velocity = Vector2.ZERO
		move_and_slide()  # Apply zero velocity
		return  # ⬅️ Exit function to stop processing further movement

	# ✅ Ensure State Machine Updates
	if state_machine:
		state_machine.update(delta)

	# ✅ Debugging Output
	print("Velocity:", velocity, "| Is On Floor:", is_on_floor())

	move_and_slide()  # ✅ Ensure movement update

func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	
func take_damage(amount):
	# Don't take damage if already dead
	if is_dead:
		return

	print("💥 Villain taking damage:", amount)
	health -= amount
	hp_bar.value = health
	
	# Flash the sprite to indicate damage
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)  # Red tint
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)  # Reset to normal
	
	if health <= 0:
		print("💀 Villain Died!")
		is_dead = true  # Set the dead flag
		health = 0     # Ensure health doesn't go below 0
		hp_bar.value = 0
		
		# Disable ALL collisions to prevent further interactions
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
				print("✓ Disabled collision shape: ", child.name)
			
			if child is Area2D:
				for area_child in child.get_children():
					if area_child is CollisionShape2D:
						area_child.set_deferred("disabled", true)
						print("✓ Disabled area collision shape: ", area_child.name)
		
		# Explicitly stop all movement
		velocity = Vector2.ZERO
		move_and_slide()
		
		# Force stop processing attacks
		attack_cooldown = 999999  # Very high number to prevent attacks
		can_attack = false
		
		print("✓ Triggering dead state")
		# Transition to dead state - use EXACT state name from villain_statemachine.gd
		if state_machine and state_machine.has_method("on_state_transition"):
			state_machine.on_state_transition("DeadState")
		else:
			# Direct transition if method doesn't exist
			print("❌ on_state_transition method not found, trying direct state change")
			play_animation("dead")
