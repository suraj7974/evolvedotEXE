extends VillainState  

var attack_cooldown_timer = 0
const ATTACK_COOLDOWN = 1.5  # Seconds before villain can attack again

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot chase")
		transitioned.emit("DeadState")  # Go to dead state
		return

	if owner.is_player_near():
		print("🚨 Villain Entered FollowState")
		if owner.sprite:
			owner.sprite.play("run")
	else:
		print("✅ Villain should NOT be following (Player is too far!)")

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return

	# Decrease cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)

		if distance > villain.detection_range:  # ⬅️ Player is too far!
			print("🛑 Player is too far! Returning to IdleState.")
			transitioned.emit("IdleState")  # ⬅️ Force transition to idle
			return  # Stop processing movement!

		# Only transition to attack if the cooldown is finished
		if distance < villain.ATTACK_RANGE and attack_cooldown_timer <= 0:
			transitioned.emit("AttackState")
			attack_cooldown_timer = ATTACK_COOLDOWN  # Reset cooldown
		else:
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * villain.SPEED
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()

func exit():
	print("🏃‍♂️ Exiting Chase State")
	
func _process(_delta):
	pass  # No additional processing needed
