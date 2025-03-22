extends VillainState  

func enter():
	print("🗡️ Villain entered Attack State")
	if villain.sprite:
		villain.sprite.play("attack")
	else:
		print("❌ ERROR: AnimatedSprite2D is missing!")
 

	# ✅ Wait for attack animation to finish before transitioning
	await villain.sprite.animation_finished
	transitioned.emit("IdleState")  

func _process(_delta):  
	pass  # Can add attack logic if needed

func _physics_process(_delta):
	pass  # No physics updates needed for Idle state
