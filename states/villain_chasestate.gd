extends VillainState  

func enter():
	print("🏃‍♂️ Villain is Chasing!")
	villain.play_animation("run")

func _physics_process(delta):
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)

		if distance < villain.ATTACK_RANGE:  
			transitioned.emit("villian_attackstate")
		else:
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * villain.SPEED
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()

func exit():
	print("🏃‍♂️ Exiting Chase State")
func _process(_delta):
	pass  # No physics updates needed for Idle state
