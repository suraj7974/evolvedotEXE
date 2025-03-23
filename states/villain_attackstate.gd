extends VillainState  

var attack_cooldown = 0
var attack_rate = 1.5  # Seconds between attacks, slower to make it fairer

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot attack")
		transitioned.emit("DeadState")  # Go to dead state
		return
		
	print("🗡️ Villain entered Attack State")
	
	# Only process attack if villain is not dead
	if villain and villain.sprite and not villain.is_dead:
		villain.sprite.play("attack")
		
		# Reset cooldown
		attack_cooldown = attack_rate
		
		# Check if player is in range and deal damage
		if villain.player and villain.global_position.distance_to(villain.player.global_position) < villain.ATTACK_RANGE:
			print("⚔️ Villain attacking player!")
			if villain.player.has_method("take_damage"):
				villain.player.take_damage(villain.DAMAGE)
		
		# Wait for animation to complete
		await get_tree().create_timer(0.5).timeout
		
		# Only transition if still alive
		if villain and not villain.is_dead:
			transitioned.emit("ChaseState")

func _process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return
		
	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return
		
	# Keep villain in place during attack animation
	villain.velocity = Vector2.ZERO
	villain.move_and_slide()
