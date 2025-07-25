extends VillainState  # Extending VillainState

var check_interval = 0.5
var time_since_check = 0

func enter():
	print("🛑 Villain Entered Idle State")
	
	# Notify villain of state change for sound system
	if villain and villain.has_method("on_state_changed"):
		villain.on_state_changed("IdleState")
	
	if villain and villain.sprite:
		villain.sprite.play("idle")
		
		# Ensure villain is facing left when idle at the beginning
		if villain.player:
			# Face toward player's initial position
			villain.sprite.flip_h = (villain.global_position.x > villain.player.global_position.x)
	
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
			
			# Only transition if player is well within detection range
			if distance < villain.detection_range * 0.8:
				print("👀 Player detected at distance: ", distance)
				print("🔄 Transitioning from Idle to Chase state")
				# Notify villain of state change for sound trigger
				if villain.has_method("on_state_changed"):
					villain.on_state_changed("ChaseState")
				transitioned.emit("ChaseState")

func _physics_process(delta):
	# Keep villain in place during idle state
	if villain:
		villain.velocity = Vector2.ZERO
		villain.move_and_slide()
