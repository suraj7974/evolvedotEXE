extends State

func enter():
	print("Entered Run State")
	if player:
		player.play_animation("run")

func process(delta):
	# Move player left or right
	var direction = 0
	if Input.is_action_pressed("move_left"):
		direction = -1
	elif Input.is_action_pressed("move_right"):
		direction = 1
	
	player.velocity.x = direction * player.SPEED  # Move the player

	# If no movement, go back to idle
	if direction == 0:
		transitioned.emit("IdleState")

func exit():
	print("Exiting Run State")
