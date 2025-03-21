extends State

func enter():
	print("Entered Idle State")
	if player:
		player.play_animation("idle")

func process(delta):
	# Movement
	var direction = Input.get_axis("move_left", "move_right")  # Get input direction
	if direction != 0:
		player.velocity.x = direction * player.SPEED
		player.play_animation("run")  # Add running animation
	else:
		player.velocity.x = 0  # Stop moving

	# Jumping
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		player.play_animation("jump")  # Add jump animation

	# Attack
	if Input.is_action_just_pressed("attack1"):
		transitioned.emit("AttackState", "attack1")  # Pass attack type
	elif Input.is_action_just_pressed("attack2"):
		transitioned.emit("AttackState", "attack2")  # Pass attack type


func exit():
	print("Exiting Idle State")
