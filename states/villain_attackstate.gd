extends VillainState  

var attack_cooldown = 0
var attack_rate = 1.5  # Seconds between attacks
var has_dealt_damage = false  # Track if damage has been dealt in this attack

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot attack")
		transitioned.emit("DeadState")
		return
		
	print("🗡️ Villain entered Attack State")
	has_dealt_damage = false  # Reset damage flag for new attack
	
	# Only process attack if villain is not dead
	if villain and villain.sprite and not villain.is_dead:
		# Stop movement and play attack animation
		villain.velocity = Vector2.ZERO
		villain.play_animation("attack")
		print("⚔️ Playing attack animation!")
		
		# Wait for animation to reach the "impact" frame before dealing damage
		# This synchronizes damage with the attack animation
		await get_tree().create_timer(0.3).timeout  # Adjust timing as needed
		
		# Deal damage to player ONCE at the right moment in the animation
		if not has_dealt_damage and villain and villain.player and not villain.is_dead:
			var distance = villain.global_position.distance_to(villain.player.global_position)
			if distance < villain.ATTACK_RANGE:
				print("⚔️ Villain attacking player!")
				if villain.player.has_method("take_damage"):
					villain.player.take_damage(villain.DAMAGE)
					has_dealt_damage = true  # Mark damage as dealt
		
		# Wait for full animation to complete
		await get_tree().create_timer(0.5).timeout
		
		# Return to chase state with cooldown
		if villain and not villain.is_dead:
			if get_parent().has_node("villain_chasestate"):
				get_parent().get_node("villain_chasestate").attack_cooldown_timer = attack_rate
			transitioned.emit("ChaseState")

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
	print("✓ Exiting attack state")
