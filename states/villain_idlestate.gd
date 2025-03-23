extends VillainState  # Extending VillainState

var check_interval = 0.5
var time_since_check = 0

func enter():
	print("🛑 Villain Entered Idle State")
	if villain and villain.sprite:
		villain.sprite.play("idle")
	
	# Reset velocity when entering idle
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
	
	time_since_check = 0  # Reset detection timer

func _process(delta):
	# Only check periodically to avoid state thrashing
	time_since_check += delta
	if time_since_check >= check_interval:
		time_since_check = 0
		
		# Check if player is nearby and transition to chase if needed
		if villain and villain.player:
			var distance = villain.global_position.distance_to(villain.player.global_position)
			
			if distance < villain.detection_range:
				print("👀 Player detected at distance: ", distance)
				print("🔄 Transitioning from Idle to Chase state")
				transitioned.emit("ChaseState")

func _physics_process(_delta):
	# Keep villain in place during idle state
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
