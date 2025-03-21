extends State

func enter():
	print("Entered Jump State")
	if player:
		player.velocity.y = player.JUMP_VELOCITY  # Apply jump force
		player.play_animation("jump")  # Play jump animation

func process(delta):
	# Maintain left/right movement while in air
	if Input.is_action_pressed("move_left"):
		player.velocity.x = -player.SPEED
	elif Input.is_action_pressed("move_right"):
		player.velocity.x = player.SPEED
	else:
		player.velocity.x = 0  # Stop moving if no input

	# When player lands, transition back to Idle or Run state
	if player.is_on_floor():
		if abs(player.velocity.x) > 0:
			transitioned.emit("RunState")  # ✅ If moving, transition to RunState
		else:
			transitioned.emit("IdleState")  # Otherwise, transition to IdleState

func exit():
	print("Exiting Jump State")
