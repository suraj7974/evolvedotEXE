extends VillainState  

func enter():
	print("💀 Villain is Dead.")
	villain.queue_free()  # Remove villain from the game
