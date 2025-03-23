extends State

func enter():
	print("💀 Player Entered DeadState")
	if player:
		player.play_animation("dead")  # Use the play_animation method instead
		# Wait for animation to complete (approximately)
		await get_tree().create_timer(0.8).timeout
	
	await get_tree().create_timer(2).timeout  # Wait for 2 seconds before respawning
	respawn()

func exit():
	print("🚀 Exiting DeadState")

func respawn():
	print("🔄 Respawning Player")
	player.global_position = Vector2(100, 300)  # Set respawn position
	player.health = 100  # Restore HP
	player.hp_bar.value = player.health  # Update the health bar
	player.state_machine.transition_to("IdleState")  # Go back to idle
