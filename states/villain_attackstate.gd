extends VillainState  

func enter():
	print("🗡️ Villain entered Attack State")
	villain.play_animation("attack")  

	# ✅ Wait for attack animation to finish before transitioning
	await villain.animation_player.animation_finished
	transitioned.emit("villian_idlestate")  

func _process(_delta):  
	pass  # Can add attack logic if needed

func _physics_process(_delta):
	pass  # No physics updates needed for Idle state
