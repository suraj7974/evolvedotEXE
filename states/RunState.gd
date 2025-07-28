extends State

func enter():
	print("Entered Run State")
	if player:
		player.play_animation("run")  # Play run animation

func process(delta):
	# Check for both keyboard and mobile input
	var keyboard_moving = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	var mobile_moving = player.mobile_left_pressed or player.mobile_right_pressed
	var is_moving = keyboard_moving or mobile_moving

	# Handle movement while in run state
	var direction = Input.get_axis("move_left", "move_right")  # Get keyboard input direction
	
	# Add mobile input to direction
	if player.mobile_left_pressed and not player.mobile_right_pressed:
		direction = -1
	elif player.mobile_right_pressed and not player.mobile_left_pressed:
		direction = 1
	elif not player.mobile_left_pressed and not player.mobile_right_pressed:
		# Keep keyboard input if no mobile input
		pass
	
	if direction != 0:
		player.velocity.x = direction * player.SPEED
		# Flip the sprite to face movement direction
		player.sprite.flip_h = (direction == -1)  # Face left if moving left
	else:
		player.velocity.x = 0  # Stop moving

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		transitioned.emit("JumpState")  # ✅ Switch to JumpState while running
	elif not is_moving:
		transitioned.emit("IdleState")  # Go back to IdleState if no movement

func exit():
	print("Exiting Run State")
