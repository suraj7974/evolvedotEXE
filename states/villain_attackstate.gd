extends VillainState  

var attack_cooldown = 0
var attack_rate = 1.5  # Seconds between attacks
var animation_complete = false

func enter():
	# First check if villain is dead
	if villain and villain.is_dead:
		print("💀 Villain is dead, cannot attack")
		transitioned.emit("DeadState")  # Go to dead state
		return
		
	print("🗡️ Villain entered Attack State")
	animation_complete = false
	
	# Only process attack if villain is not dead
	if villain and villain.sprite and not villain.is_dead:
		# Ensure villain stops
		villain.velocity = Vector2.ZERO
		
		# Explicitly play attack animation
		if villain.sprite.sprite_frames.has_animation("attack"):
			villain.sprite.play("attack")
			print("⚔️ Playing villain attack animation!")
			
			# Connect animation finished signal if not already connected
			if not villain.sprite.animation_finished.is_connected(_on_animation_finished):
				villain.sprite.animation_finished.connect(_on_animation_finished)
		else:
			print("❌ ERROR: 'attack' animation not found!")
			animation_complete = true
		
		# Reset cooldown
		attack_cooldown = attack_rate
		
		# Check if player is in range and deal damage
		if villain.player and villain.global_position.distance_to(villain.player.global_position) < villain.ATTACK_RANGE:
			print("⚔️ Villain attacking player!")
			if villain.player.has_method("take_damage"):
				villain.player.take_damage(villain.DAMAGE)
		
		# Fallback if animation signal doesn't trigger
		await get_tree().create_timer(0.9).timeout
		if not animation_complete:
			print("⚠️ Using fallback transition from attack state")
			_finish_attack()

func _on_animation_finished():
	print("✓ Attack animation finished")
	if villain.sprite.animation == "attack":
		_finish_attack()

func _finish_attack():
	animation_complete = true
	# Reset any pending signals
	if villain and villain.sprite and villain.sprite.animation_finished.is_connected(_on_animation_finished):
		villain.sprite.animation_finished.disconnect(_on_animation_finished)
	
	# Wait a short moment to avoid spamming attacks
	await get_tree().create_timer(0.3).timeout
	
	# Only transition if still alive
	if villain and not villain.is_dead:
		transitioned.emit("ChaseState")
		# Set cooldown in chase state
		if get_parent().has_node("villain_chasestate"):
			get_parent().get_node("villain_chasestate").attack_cooldown_timer = attack_rate

func _process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return
		
	# Force villain to stay in place
	if villain:
		villain.velocity = Vector2.ZERO

func _physics_process(delta):
	# Skip processing if dead
	if villain and villain.is_dead:
		return
		
	# Keep villain in place during attack animation
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()

func exit():
	# Clean up any connected signals
	if villain and villain.sprite and villain.sprite.animation_finished.is_connected(_on_animation_finished):
		villain.sprite.animation_finished.disconnect(_on_animation_finished)
	print("✓ Exiting attack state")
