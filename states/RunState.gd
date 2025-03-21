extends State

func enter():
	print("Entered Run State")
	if player:
		player.play_animation("run")  # Play run animation

func process(delta):
	# Check if player is moving left or right
	var moving = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		transitioned.emit("JumpState")  # ✅ Switch to JumpState while running
	elif not moving:
		transitioned.emit("IdleState")  # Go back to IdleState if no movement

func exit():
	print("Exiting Run State")
