extends State

var attack_type = "attack1"  # Default attack type

func enter(new_attack_type = "attack1"):
	attack_type = new_attack_type
	print("Entered Attack State with:", attack_type)

	if player and player.sprite and player.sprite.sprite_frames:
		if player.sprite.sprite_frames.has_animation(attack_type):
			player.play_animation(attack_type)
		else:
			print("❌ ERROR: Animation not found for", attack_type)

	await get_tree().create_timer(0.5).timeout  # Wait for animation duration
	transitioned.emit("IdleState")  # Return to Idle State

func exit():
	print("Exiting Attack State")
