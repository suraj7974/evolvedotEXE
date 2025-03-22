extends VillainState  # ✅ Extending VillainState

func enter():
	print("Villain is in Idle State")

func _process(_delta):
	if villain.is_player_near():  # ✅ Ensure `is_player_near()` exists in `villain.gd`
		transitioned.emit("villian_chasestate")  # ✅ Change to Chase State

# ✅ Add missing `_physics_process`
func _physics_process(_delta):
	pass  # No physics updates needed for Idle state
