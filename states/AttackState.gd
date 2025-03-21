extends State

func enter():
	print("Entered Attack State")

	if player and player.sprite and player.sprite.sprite_frames:
		if player.sprite.sprite_frames.has_animation("attack"):
			player.play_animation("attack")
		else:
			print("❌ ERROR: Attack animation not found!")

	await get_tree().create_timer(0.5).timeout  # Wait for attack duration
	transitioned.emit("IdleState")  # Return to Idle State

func exit():
	print("Exiting Attack State")
