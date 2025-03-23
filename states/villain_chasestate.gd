extends VillainState  

var attack_cooldown_timer = 0
const ATTACK_COOLDOWN = 1.5  # Seconds before villain can attack again
var check_interval = 0.5
var time_since_check = 0

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot chase")
		transitioned.emit("DeadState")  # Go to dead state
		return

	print("🚨 Villain Entered Chase State")
	if villain and villain.sprite:
		villain.sprite.play("run")
	
	time_since_check = 0  # Reset detection timer

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return

	# Decrease cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# Player detection timer
	time_since_check += delta
	
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)

		# Check range less often to prevent state thrashing
		if time_since_check >= check_interval:
			time_since_check = 0
			
			if distance > villain.detection_range:  # Player is too far!
				print("🛑 Player is too far! Returning to IdleState.")
				transitioned.emit("IdleState")  # Force transition to idle
				return  # Stop processing movement!
		
		# Only transition to attack if the cooldown is finished
		if distance < villain.ATTACK_RANGE and attack_cooldown_timer <= 0:
			print("⚔️ Attack range reached - transitioning to AttackState")
			print("  Distance: ", distance, " Attack Range: ", villain.ATTACK_RANGE)
			# Make sure we immediately stop before attacking
			villain.velocity = Vector2.ZERO
			villain.move_and_slide()
			attack_cooldown_timer = ATTACK_COOLDOWN  # Set cooldown
			transitioned.emit("AttackState")
			return  # Stop further processing
		else:
			# Continue chasing
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * villain.SPEED
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()

func exit():
	print("🏃‍♂️ Exiting Chase State")
	
func _process(_delta):
	pass  # No additional processing needed
