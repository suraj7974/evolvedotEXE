extends VillainState

# Add this as a property to the class so LevelManager can reset it
var notified_death = false

func enter():
	print("☠️ Entering Dead State")  
	notified_death = false
	
	if villain:
		# Ensure villain is properly marked as dead
		villain.is_dead = true
		
		# Stop all movement
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
		
		# Disable collisions to prevent further interactions
		if villain.has_node("CollisionShape2D"):
			villain.get_node("CollisionShape2D").set_deferred("disabled", true)
		
		if villain.has_node("Area2D") and villain.get_node("Area2D").has_node("CollisionShape2D"):
			villain.get_node("Area2D").get_node("CollisionShape2D").set_deferred("disabled", true)
		
		# Play the death animation
		if villain.has_method("play_animation"):
			print("✓ Playing villain death animation")
			villain.play_animation("dead")
			
			# Make sure animation doesn't loop
			if villain.sprite and villain.sprite.sprite_frames:
				if villain.sprite.sprite_frames.has_animation("dead"):
					villain.sprite.sprite_frames.set_animation_loop("dead", false)
					print("✓ Set dead animation to not loop")
			
			 # Start a delayed notification to level manager
			notify_level_manager_delayed()
		else:
			print("❌ ERROR: play_animation() not found!")
			# Still notify even if animation failed, but with a delay
			notify_level_manager_delayed()

# Function to notify level manager with a delay to ensure animation plays first
func notify_level_manager_delayed():
	# Wait for animation to complete before advancing to next level
	await get_tree().create_timer(1.5).timeout
	
	# Prevent duplicate notifications
	if notified_death or !is_instance_valid(self):
		return
	
	print("⚡ Checking if villain can notify death")
	if villain and villain.is_dead:
		notified_death = true
		print("✓ Notifying LevelManager of villain death")
		
		# Use call_deferred to avoid crashes if called during physics processing
		if Engine.get_singleton("LevelManager") or get_node_or_null("/root/LevelManager"):
			LevelManager.call_deferred("villain_died")
		else:
			print("❌ ERROR: LevelManager not found!")
	else:
		print("❓ Villain is not dead or no longer exists, not notifying")

func respawn():
	print("🔄 Respawning Villain")
	
	# Reset villain state
	if villain:
		# Make villain visible again
		villain.visible = true
		
		# Reset health
		villain.health = 100
		
		# Update the health bar using the custom method instead of directly setting hp_bar.value
		villain.update_health_bar()
		
		# Reset death flag
		villain.is_dead = false
		
		# Reset attack ability
		villain.can_attack = true
		villain.attack_cooldown = 0
		
		 # Reset learning system - villain "forgets" previous attack patterns
		if villain.has_method("reset_learning"):
			villain.reset_learning()
		
		# Re-enable collisions
		if villain.has_node("CollisionShape2D"):
			villain.get_node("CollisionShape2D").set_deferred("disabled", false)
		
		if villain.has_node("Area2D") and villain.get_node("Area2D").has_node("CollisionShape2D"):
			villain.get_node("Area2D").get_node("CollisionShape2D").set_deferred("disabled", false)
		
		# Reposition the villain - adjust Y position to match ground level with proper offset
		var spawnX = 400  # X position is some distance away from player
		var spawnY = villain.ground_y_position  # Default ground position
		
		# If player exists, use player's Y position as reference and apply the y_offset
		if villain.player:
			spawnY = villain.player.global_position.y - villain.y_offset
			print("✓ Respawning villain at adjusted Y position:", spawnY)
		
		villain.global_position = Vector2(spawnX, spawnY)
		print("✓ Villain respawned at position:", villain.global_position)
		
		# Ensure proper positioning by explicitly applying it
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
		
		# Re-enable processing
		villain.set_physics_process(true)
		villain.set_process(true)
		
		# Return to idle state
		transitioned.emit("IdleState")

func exit():
	print("🏃‍♂️ Exiting villain dead state")
	# Don't reset notified_death here - it should be reset when re-entering the state

func _process(_delta):
	pass  # No movement in dead state

func _physics_process(_delta):
	# Ensure villain doesn't move when dead
	if villain:
		villain.velocity = Vector2.ZERO
