extends VillainState

func enter():
	print("☠️ Entering Dead State")  
	if villain:
		# Ensure villain is marked as dead
		villain.is_dead = true
		
		# Stop all movement
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
		
		# Disable collisions
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
			
			# Wait for animation to complete before respawning
			await get_tree().create_timer(1.5).timeout
			respawn()
		else:
			print("❌ ERROR: play_animation() not found!")
			await get_tree().create_timer(1.5).timeout
			respawn()

func respawn():
	print("🔄 Respawning Villain")
	
	# Reset villain state
	if villain:
		# Make villain visible again
		villain.visible = true
		
		# Reset health
		villain.health = 100
		villain.hp_bar.value = villain.health
		
		# Reset death flag
		villain.is_dead = false
		
		# Re-enable collisions
		if villain.has_node("CollisionShape2D"):
			villain.get_node("CollisionShape2D").set_deferred("disabled", false)
		
		if villain.has_node("Area2D") and villain.get_node("Area2D").has_node("CollisionShape2D"):
			villain.get_node("Area2D").get_node("CollisionShape2D").set_deferred("disabled", false)
		
		# Reposition the villain - adjust this position as needed
		villain.global_position = Vector2(400, 65)  # Set respawn position to a different area
		
		# Re-enable processing
		villain.set_physics_process(true)
		villain.set_process(true)
		
		# Return to idle state
		transitioned.emit("IdleState")

func exit():
	print("🏃‍♂️ Exiting Dead State")

func _process(_delta):
	pass  # No movement in dead state

func _physics_process(_delta):
	# Ensure villain doesn't move when dead
	if villain:
		villain.velocity = Vector2.ZERO
