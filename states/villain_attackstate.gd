extends VillainState  

var attack_cooldown = 0
var attack_rate = 1.5  # Seconds between attacks

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot attack")
		transitioned.emit("DeadState")
		return
		
	print("🗡️ Villain entered Attack State")
	
	# Only process attack if villain is not dead
	if villain and villain.sprite and not villain.is_dead:
		# Stop movement and play attack animation
		villain.velocity = Vector2.ZERO
		villain.play_animation("attack")
		print("⚔️ Playing attack animation!")
		
		# Deal damage to player
		if villain.player and villain.global_position.distance_to(villain.player.global_position) < villain.ATTACK_RANGE:
			print("⚔️ Villain attacking player!")
			if villain.player.has_method("take_damage"):
				villain.player.take_damage(villain.DAMAGE)
		
		# Wait for animation and then return to chase state
		await get_tree().create_timer(0.8).timeout
		
		# Return to chase state with cooldown
		if villain and not villain.is_dead:
			if get_parent().has_node("villain_chasestate"):
				get_parent().get_node("villain_chasestate").attack_cooldown_timer = 1.0
			transitioned.emit("ChaseState")

func _process(delta):
	if villain:
		villain.velocity = Vector2.ZERO

func _physics_process(delta):
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()

func exit():
	print("✓ Exiting attack state")
