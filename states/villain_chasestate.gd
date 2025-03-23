extends VillainState  

var attack_cooldown_timer = 0
const ATTACK_COOLDOWN = 1.5  # Seconds before villain can attack again

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot chase")
		transitioned.emit("DeadState")
		return

	print("🚨 Villain Entered Chase State")
	if villain and villain.sprite:
		villain.sprite.play("run")

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return

	# Decrease cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)
		
		# Check if player is too far away
		if distance > villain.chase_persistence_range:
			print("🛑 Player is too far! Returning to IdleState.")
			transitioned.emit("IdleState")
			return
		
		# Only transition to attack if the cooldown is finished
		# And ensure we're in the right distance range
		if distance < villain.ATTACK_RANGE and attack_cooldown_timer <= 0:
			print("⚔️ Attack range reached: ", distance)
			# Don't damage here, only transition to attack state
			transitioned.emit("AttackState")
			return
		elif distance < villain.ATTACK_RANGE:
			# If in range but cooldown still active, don't approach further
			villain.velocity.x = 0
		else:
			# Continue chasing
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * villain.SPEED
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()

func exit():
	print("🏃‍♂️ Exiting Chase State")
