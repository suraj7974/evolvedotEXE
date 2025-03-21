extends State

func enter():
	print("Entered Jump State")
	if player:
		player.velocity.y = player.JUMP_VELOCITY  # Apply jump force
		player.play_animation("jump")  # Play jump animation

func process(delta):
	if player.velocity.y >= 0:  # When falling down
		transitioned.emit("IdleState")  # Return to idle when landing

func exit():
	print("Exiting Jump State")
