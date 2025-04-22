extends State

var attack_type = "attack1"  # Default attack type
var damage = 10  # Default damage amount
var damage_attack1 = 10  # Damage for attack1
var damage_attack2 = 15  # Damage for attack2

func enter(new_attack_type = "attack1"):
	attack_type = new_attack_type
	print("Entered Attack State with:", attack_type)
	
	# Set the damage value based on the attack type
	if attack_type == "attack1":
		damage = damage_attack1
	elif attack_type == "attack2":
		damage = damage_attack2
		
	print("Using damage value:", damage)

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
				
				# Check if villain is still alive
				if villain.get("is_dead") and villain.is_dead:
					print("⚠️ Villain is already dead, skipping attack")
					continue
					
				# Improved hit detection with broader range and more reliable direction check
				var is_in_front = false
				if player.sprite.flip_h: # Player facing left
					is_in_front = villain.global_position.x <= player.global_position.x
				else: # Player facing right
					is_in_front = villain.global_position.x >= player.global_position.x
					
				# Increased attack range for better detection and give benefit of the doubt to player
				if distance < 70 and is_in_front:
					print("⚔️ Player hit villain with " + attack_type + " at distance: " + str(distance))
					if villain.has_method("take_damage"):
						# Explicitly print attack hit
						print("🎯 DIRECT HIT with " + attack_type + "! Dealing " + str(damage) + " damage")
						# Pass the attack type to the villain's take_damage method for learning
						villain.take_damage(damage, attack_type)
		else:
			print("❌ ERROR: Animation not found for", attack_type)

	await get_tree().create_timer(0.5).timeout  # Wait for animation duration
	transitioned.emit("IdleState")  # Return to Idle State

func exit():
	print("Exiting Attack State")
