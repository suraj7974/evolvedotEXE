extends State

var attack_type = "attack1"  # Default attack type
var damage = 10  # Amount of damage player deals when attacking

func enter(new_attack_type = "attack1"):
	attack_type = new_attack_type
	print("Entered Attack State with:", attack_type)

	if player and player.sprite and player.sprite.sprite_frames:
		if player.sprite.sprite_frames.has_animation(attack_type):
			player.play_animation(attack_type)
			
			# Check for enemies nearby to damage
			var space_state = player.get_world_2d().direct_space_state
			var direction_vector = Vector2(-50, 0) if player.sprite.flip_h else Vector2(50, 0)
			var query = PhysicsRayQueryParameters2D.create(player.global_position, 
				player.global_position + direction_vector)
			
			# Wait a small fraction of time for the attack to "visually connect"
			await get_tree().create_timer(0.2).timeout
			
			# Find villains in attack range
			var villains = get_tree().get_nodes_in_group("villain")
			for villain in villains:
				var distance = player.global_position.distance_to(villain.global_position)
				# Check if villain is within attack range and in front of player
				var is_in_front = (villain.global_position.x > player.global_position.x and not player.sprite.flip_h) or \
								  (villain.global_position.x < player.global_position.x and player.sprite.flip_h)
				if distance < 50 and is_in_front:
					print("⚔️ Player hit villain with " + attack_type + "!")
					if villain.has_method("take_damage"):
						# Pass the attack type to the villain's take_damage method for learning
						villain.take_damage(damage, attack_type)
		else:
			print("❌ ERROR: Animation not found for", attack_type)

	await get_tree().create_timer(0.5).timeout  # Wait for animation duration
	transitioned.emit("IdleState")  # Return to Idle State

func exit():
	print("Exiting Attack State")
