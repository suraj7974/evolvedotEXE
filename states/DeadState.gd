extends State

func enter():
	print("💀 Player Entered DeadState")
	if player:
		player.play_animation("dead")  # Use the play_animation method instead
		# Wait for animation to complete (approximately)
		await get_tree().create_timer(0.8).timeout
	
	# Notify the level manager instead of respawning
	LevelManager.player_died()

func exit():
	print("🚀 Exiting DeadState")
