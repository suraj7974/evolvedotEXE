extends VillainState  

var attack_cooldown = 0
var attack_rate = 0.6  # Reduced from 1.5/1.0 to 0.6 seconds between attacks
var has_dealt_damage = false  # Track if damage has been dealt in this attack
var is_attacking = false  # Flag to prevent multiple attack triggers

func enter():
	# Prevent multiple simultaneous attacks
	if is_attacking:
		print("⚠️ Already attacking! Ignoring duplicate attack trigger")
		return
		
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot attack")
		transitioned.emit("DeadState")
		return
		
	print("🗡️ Villain entered Attack State")
	has_dealt_damage = false  # Reset damage flag for new attack
	is_attacking = true  # Set attacking flag
	
	# Only process attack if villain is not dead
	if villain and villain.sprite and not villain.is_dead:
		# Stop movement and play attack animation
		villain.velocity = Vector2.ZERO
		villain.play_animation("attack")
		print("⚔️ Playing attack animation!")
		
		# Wait for animation to reach the "impact" frame before dealing damage
		# This synchronizes damage with the attack animation - reduced from 0.3 to 0.2
		await get_tree().create_timer(0.2).timeout
		
		# Deal damage to player ONCE at the right moment in the animation
		if not has_dealt_damage and villain and villain.player and not villain.is_dead:
			var distance = villain.global_position.distance_to(villain.player.global_position)
			if distance < villain.ATTACK_RANGE:
				print("⚔️ Villain attacking player!")
				if villain.player.has_method("take_damage"):
					villain.player.take_damage(villain.DAMAGE)
					has_dealt_damage = true  # Mark damage as dealt
		
		# Wait for full animation to complete - reduced from 0.5 to 0.3
		await get_tree().create_timer(0.3).timeout
		
		# Return to chase state with cooldown
		if villain and not villain.is_dead:
			# Ensure cooldown is set in both places
			if get_parent().has_node("villain_chasestate"):
				get_parent().get_node("villain_chasestate").attack_cooldown_timer = attack_rate
			
			# Also set cooldown on villain itself to ensure consistency
			if villain.has_method("set_attack_cooldown"):
				villain.set_attack_cooldown(attack_rate)
			else:
				villain.attack_cooldown = attack_rate
				villain.can_attack = false
				
			is_attacking = false  # Reset attacking flag before transition
			transitioned.emit("ChaseState")
	else:
		is_attacking = false  # Reset flag if attack couldn't be performed

func _process(delta):
	# Keep villain in place during attack
	if villain:
		villain.velocity = Vector2.ZERO

func _physics_process(delta):
	# Keep villain in place during attack animation
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()

func exit():
	is_attacking = false  # Ensure flag is reset when exiting state
	print("✓ Exiting attack state")
