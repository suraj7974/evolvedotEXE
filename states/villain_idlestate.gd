extends VillainState  # ✅ Extending VillainState

func enter():
	print("🛑 Villain Entered Idle State")
	owner.velocity = Vector2.ZERO  # ✅ Stop movement completely
	owner.move_and_slide()
	if owner.sprite:
		owner.sprite.play("idle")



func _process(_delta):
	if villain.is_player_near():
		print("🔄 Player detected! Transitioning to ChaseState.")
		transitioned.emit("ChaseState")


# ✅ Add missing `_physics_process`
func _physics_process(_delta):
	pass  # No physics updates needed for Idle state
