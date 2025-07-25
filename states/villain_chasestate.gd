extends VillainState  

var attack_cooldown_timer = 0
const ATTACK_COOLDOWN = 0.6  # Reduced from 1.5 to 0.6 seconds for faster attacks
var transitioning_to_attack = false  # Flag to prevent multiple transitions

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot chase")
		transitioned.emit("DeadState")
		return

	print("🚨 Villain Entered Chase State")
	
	# Notify villain of state change for sound trigger
	if villain and villain.has_method("on_state_changed"):
		villain.on_state_changed("ChaseState")
		
	transitioning_to_attack = false  # Reset transition flag
	if villain and villain.sprite:
		villain.sprite.play("run")
		
	# Reset cooldown timer to a small value to enable quick first attack
	attack_cooldown_timer = 0.2

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return
		
	# Skip if already transitioning to attack
	if transitioning_to_attack:
		return

	# Decrease cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta * 1.2  # Speed up cooldown reduction by 20%
	
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)
		
		# Check if player is too far away
		if distance > villain.chase_persistence_range:
			print("🛑 Player is too far! Returning to IdleState.")
			# Notify villain of state change
			if villain.has_method("on_state_changed"):
				villain.on_state_changed("IdleState")
			transitioned.emit("IdleState")
			return
		
		# Only transition to attack if the cooldown is finished
		# And ensure we're in the right distance range
		if distance < villain.ATTACK_RANGE and attack_cooldown_timer <= 0 and villain.can_attack:
			print("⚔️ Attack range reached: ", distance)
			# Set flag to prevent multiple transitions in single frame
			transitioning_to_attack = true
			# Ensure villain's internal cooldown is also synchronized
			villain.can_attack = false
			# Notify villain of state change
			if villain.has_method("on_state_changed"):
				villain.on_state_changed("AttackState")
			# Don't damage here, only transition to attack state
			transitioned.emit("AttackState")
			return
		elif distance < villain.ATTACK_RANGE:
			# If in range but cooldown still active, don't approach further
			villain.velocity.x = 0
			
			# Approach player slightly during cooldown to maintain attack position
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.sprite.flip_h = (direction.x < 0)
		else:
			# Continue chasing - increased chase speed by 20%
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * (villain.SPEED * 1.2)
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()

func exit():
	transitioning_to_attack = false  # Reset flag when exiting
	print("🏃‍♂️ Exiting Chase State")
