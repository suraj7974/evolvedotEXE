extends VillainState  

func enter():
	if owner.is_player_near():
		print("🚨 Villain Entered FollowState")
		if owner.sprite:
			owner.sprite.play("run")
 # Ensure the villain plays the running animation
	else:
		print("✅ Villain should NOT be following (Player is too far!)")

func _physics_process(delta):
	if villain and villain.player:
		var distance = villain.global_position.distance_to(villain.player.global_position)

		if distance > villain.detection_range:  # ⬅️ Player is too far!
			print("🛑 Player is too far! Returning to IdleState.")
			transitioned.emit("IdleState")  # ⬅️ Force transition to idle
			return  # Stop processing movement!

		if distance < villain.ATTACK_RANGE:
			transitioned.emit("AttackState")
		else:
			var direction = (villain.player.global_position - villain.global_position).normalized()
			villain.velocity.x = direction.x * villain.SPEED
			villain.sprite.flip_h = (direction.x < 0)

		villain.move_and_slide()



func exit():
	print("🏃‍♂️ Exiting Chase State")
func _process(_delta):
	pass  # No physics updates needed for Idle state
