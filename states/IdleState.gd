extends State

func enter():
	print("Entered Idle State")
	if player:
		player.play_animation("idle")

func process(delta):
	if Input.is_action_just_pressed("attack"):
		transitioned.emit("AttackState")  # Change to AttackState

func exit():
	print("Exiting Idle State")
