extends Node

# Level settings
var current_level = 1
var max_level = 3
var level_transitioning = false  # Flag to prevent multiple level transitions

# Player and villain stats per level
var level_data = {
	1: {
		"player": {
			"health": 100,
			"damage_attack1": 10,
			"damage_attack2": 15,
			"speed": 300.0,
		},
		"villain": {
			"health": 100,
			"damage": 5, 
			"speed": 80.0,
			"attack_range": 50.0,
			"name": "VILLAIN LVL 1"
		}
	},
	2: {
		"player": {
			"health": 150,
			"damage_attack1": 15,
			"damage_attack2": 20,
			"speed": 325.0,
		},
		"villain": {
			"health": 200,
			"damage": 5,
			"speed": 90.0,
			"attack_range": 55.0,
			"name": "VILLAIN LVL 2"
		}
	},
	3: {
		"player": {
			"health": 200,
			"damage_attack1": 20,
			"damage_attack2": 30,
			"speed": 350.0,
		},
		"villain": {
			"health": 400,
			"damage": 15,
			"speed": 100.0,
			"attack_range": 60.0,
			"name": "FINAL BOSS"
		}
	}
}

# Track if game is over
var game_over = false

# Reference to essential nodes
var player
var villain
var game_hud
var log_file

func _ready():
	# Reset level on new game
	current_level = 1
	game_over = false
	level_transitioning = false
	
	# Setup debug logging
	setup_logging()
	log_debug("LevelManager initialized - Starting at level 1")
	
	# Ensure singleton pattern works correctly
	if get_parent() == get_tree().root and get_tree().root.get_node_or_null("LevelManager") != self:
		log_debug("Duplicate LevelManager detected, removing this instance")
		queue_free()
		return
		
	# Make sure we're properly added to the tree for persistence
	if get_parent() != get_tree().root:
		log_debug("Moving LevelManager to root for persistence")
		get_tree().root.call_deferred("add_child", self)
		call_deferred("reparented_initialization")
	else:
		call_deferred("_initialize")

func setup_logging():
	# Create a log file with timestamp
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "level_manager_%d-%02d-%02d_%02d-%02d-%02d.log" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	log_file = FileAccess.open("res://logs/" + filename, FileAccess.WRITE)
	log_debug("Logging started")

func log_debug(message):
	print("📝 " + message)
	if log_file:
		log_file.store_line(Time.get_time_string_from_system() + ": " + message)

func reparented_initialization():
	log_debug("LevelManager reparented to root")
	_initialize()
	
func _initialize():
	# Wait a bit for the scene to be fully ready
	await get_tree().create_timer(0.2).timeout
	
	log_debug("LevelManager initializing for level " + str(current_level))
	
	# Find player and villain
	find_game_entities()
	
	# Apply level settings
	if current_level in level_data:
		apply_level_settings()
		log_debug("Applied level " + str(current_level) + " settings")
	else:
		log_debug("ERROR: Level data not found for level " + str(current_level))

func find_game_entities():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		log_debug("Found player at " + str(player.global_position))
	else:
		log_debug("ERROR: Player not found!")
		
	var villains = get_tree().get_nodes_in_group("villain")
	if villains.size() > 0:
		villain = villains[0]
		log_debug("Found villain at " + str(villain.global_position) + ", health: " + str(villain.health))
	else:
		log_debug("ERROR: Villain not found!")
		
	# Get HUD reference
	game_hud = get_node_or_null("/root/GameHUD")

func apply_level_settings():
	log_debug("Applying settings for level " + str(current_level))
	
	# Apply player settings
	if player:
		var player_settings = level_data[current_level]["player"]
		player.health = player_settings["health"]
		player.SPEED = player_settings["speed"]
		player.update_health_bar()
		
		log_debug("Player stats set - Health: " + str(player.health) + ", Speed: " + str(player.SPEED))
		
		# Find attack state to update damage values
		if player.state_machine and player.state_machine.has_method("get_state"):
			var attack_state = player.state_machine.get_state("AttackState")
			if attack_state:
				# Save the damage values to the attack state
				attack_state.damage_attack1 = player_settings["damage_attack1"]
				attack_state.damage_attack2 = player_settings["damage_attack2"]
				log_debug("Player attack damage set - Attack1: " + str(attack_state.damage_attack1) + ", Attack2: " + str(attack_state.damage_attack2))
		else:
			# Try direct access to states dictionary
			if player.state_machine and player.state_machine.get("states") != null:
				var attack_state = player.state_machine.states.get("AttackState")
				if attack_state:
					attack_state.damage_attack1 = player_settings["damage_attack1"]
					attack_state.damage_attack2 = player_settings["damage_attack2"]
					log_debug("Player attack damage set via states dictionary")
	
	# Apply villain settings
	if villain:
		var villain_settings = level_data[current_level]["villain"]
		villain.health = villain_settings["health"]
		villain.SPEED = villain_settings["speed"]
		villain.DAMAGE = villain_settings["damage"]
		villain.ATTACK_RANGE = villain_settings["attack_range"]
		villain.villain_name = villain_settings["name"]
		villain.is_dead = false  # Ensure villain is not dead
		villain.update_health_bar()
		
		log_debug("Villain stats set - Health: " + str(villain.health) + 
			", Speed: " + str(villain.SPEED) + 
			", Damage: " + str(villain.DAMAGE) + 
			", Name: " + villain.villain_name)

func advance_to_next_level():
	# Prevent multiple calls to this function while a transition is in progress
	if level_transitioning or game_over:
		log_debug("Ignoring advance_to_next_level call - already transitioning or game over")
		return
		
	level_transitioning = true
	
	if current_level < max_level:
		log_debug("Advancing from level " + str(current_level) + " to level " + str(current_level + 1))
		var old_level = current_level
		current_level += 1
		
		# Show level transition - Call this in a delayed manner to ensure it works
		call_deferred("show_level_transition", "LEVEL " + str(current_level))
		
		# Reset game state for next level after a delay
		await get_tree().create_timer(3.5).timeout
		
		# Verify we haven't been detached due to scene change
		if not is_instance_valid(self) or not is_inside_tree():
			log_debug("LevelManager was detached during level transition - aborting")
			return
			
		# Double check the level hasn't changed again (prevents race conditions)
		if current_level != old_level + 1:
			log_debug("Level changed during transition - aborting redundant transition")
			level_transitioning = false
			return
		
		# Refresh entity references
		find_game_entities()
		
		# Apply settings for new level
		apply_level_settings()
		
		# Position villain and player correctly and revive them
		reset_positions()
		
		game_over = false
		level_transitioning = false
	else:
		# Player has beaten the final level
		log_debug("Player completed all levels!")
		show_game_win()
		game_over = true
		level_transitioning = false

# New function for ensuring level transition is shown
func show_level_transition(level_text):
	# Use a direct approach to create the message overlay
	var root = get_tree().root
	
	# Remove any existing message overlay to ensure fresh state
	var existing = root.get_node_or_null("MessageOverlay")
	if existing:
		existing.queue_free()
		await get_tree().process_frame
	
	# Create a new CanvasLayer for the message
	var overlay = CanvasLayer.new()
	overlay.name = "MessageOverlay"
	overlay.layer = 128  # Extremely high layer to ensure visibility
	root.add_child(overlay)
	
	log_debug("Created new message overlay with layer " + str(overlay.layer))
	
	# Add background color panel
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.0, 0.1, 0.6, 0.9)  # Richer blue color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	# Add layout container
	var vbox = VBoxContainer.new()
	vbox.name = "MessageContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	background.add_child(vbox)
	
	# Add title (level number)
	var title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)  # Larger font
	title_label.text = level_text
	vbox.add_child(title_label)
	
	# Add message
	var msg_label = Label.new()
	msg_label.name = "Message"
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 32)  # Larger font
	
	# Show more descriptive message based on level number
	if level_text == "LEVEL 2":
		msg_label.text = "Be careful, this villain is stronger! Get ready!"
	elif level_text == "LEVEL 3":
		msg_label.text = "Final challenge! The boss awaits... Get ready!"
	else:
		msg_label.text = "Get ready!"
		
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(msg_label)
	
	log_debug("Level transition message displayed: " + level_text + " - " + msg_label.text)
	
	# Keep visible for a while then hide
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(overlay) and overlay.is_inside_tree():
		overlay.queue_free()
		log_debug("Removed level transition message overlay")

func player_died():
	if not game_over and not level_transitioning:
		game_over = true
		log_debug("Player died! Game over.")
		show_game_over()

func villain_died():
	if game_over or level_transitioning:
		log_debug("Ignoring villain_died call - already in game over or level transition")
		return
		
	log_debug("Villain defeated on level " + str(current_level))
	# Instead of respawning, advance to next level
	advance_to_next_level()

func reset_positions():
	log_debug("Resetting positions for level " + str(current_level))
	
	if player:
		player.global_position = Vector2(100, 300)
		player.velocity = Vector2.ZERO
		log_debug("Player position reset to " + str(player.global_position))
		
	if villain:
		# Store reference to confirm this is the same villain later
		var villain_instance_id = villain.get_instance_id()
		
		# Completely revive the villain - Explicitly set is_dead to false FIRST
		villain.is_dead = false
		
		# Force reset collision state
		if villain.has_node("CollisionShape2D"):
			villain.get_node("CollisionShape2D").disabled = false
		
		if villain.has_node("Area2D") and villain.get_node("Area2D").has_node("CollisionShape2D"):
			villain.get_node("Area2D").get_node("CollisionShape2D").disabled = false
		
		# Make sure the villain's physics processing is enabled
		villain.set_physics_process(true)
		villain.set_process(true)
		
		# Reset other properties
		villain.global_position = Vector2(400, 300)
		villain.velocity = Vector2.ZERO
		villain.can_attack = true
		villain.attack_cooldown = 0
		villain.visible = true
		
		# Return to idle state - try different methods to ensure it works
		if villain.state_machine:
			if villain.state_machine.has_method("on_state_transition"):
				villain.state_machine.on_state_transition("IdleState")
				log_debug("Villain state reset to IdleState via on_state_transition")
			elif villain.state_machine.has_method("transition_to"):
				villain.state_machine.transition_to("IdleState")
				log_debug("Villain state reset to IdleState via transition_to")
			
		log_debug("Villain " + str(villain_instance_id) + " reset at " + str(villain.global_position))
		
		# Force a health update to ensure the UI reflects the correct values
		villain.update_health_bar()
		
		# Verify villain state
		log_debug("Villain state after reset - Health: " + str(villain.health) + 
			", Dead: " + str(villain.is_dead) +
			", Visible: " + str(villain.visible))

func show_message(title, message, color = Color(0.2, 0.2, 0.2, 0.9)):
	log_debug("Showing message: " + title + " - " + message)
	
	# Create message overlay if it doesn't exist yet
	var overlay = get_node_or_null("/root/MessageOverlay")
	if not overlay:
		overlay = CanvasLayer.new()
		overlay.name = "MessageOverlay"
		overlay.layer = 100  # Ensure it's on top
		get_tree().root.add_child(overlay)
		
		var background = ColorRect.new()
		background.name = "Background"
		background.color = color
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(background)
		
		var vbox = VBoxContainer.new()
		vbox.name = "MessageContainer"
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		background.add_child(vbox)
		
		var title_label = Label.new()
		title_label.name = "Title"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var title_font_size = 48
		title_label.add_theme_font_size_override("font_size", title_font_size)
		vbox.add_child(title_label)
		
		var msg_label = Label.new()
		msg_label.name = "Message"
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var msg_font_size = 24
		msg_label.add_theme_font_size_override("font_size", msg_font_size)
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(msg_label)
		
		if title == "GAME OVER" or title == "VICTORY":
			var button = Button.new()
			button.name = "RestartButton"
			button.text = "Restart Game"
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.custom_minimum_size = Vector2(200, 50)
			button.pressed.connect(_on_restart_button_pressed)
			vbox.add_child(button)
	else:
		# Update existing overlay
		var title_label = overlay.get_node("Background/MessageContainer/Title")
		var msg_label = overlay.get_node("Background/MessageContainer/Message")
		
		# Make sure overlay is set visible before setting text
		overlay.visible = true
		
		overlay.get_node("Background").color = color
		
		if title_label:
			title_label.text = title
		if msg_label:
			msg_label.text = message
	
	# Make overlay visible and ensure it's above other UI
	overlay.visible = true
	overlay.layer = 100
	
	# If it's a temporary message (like level transition)
	if title != "GAME OVER" and title != "VICTORY":
		# Wait longer for level transitions to be more noticeable
		await get_tree().create_timer(3.0).timeout
		
		# Make sure we're still in the tree before trying to hide
		if is_instance_valid(overlay) and overlay.is_inside_tree():
			overlay.visible = false

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func show_level_message(level_text):
	# Use brighter blue color for better visibility
	var level_color = Color(0.0, 0.1, 0.6, 0.9)  # Richer blue color
	
	# Show more descriptive message based on level number
	var message = ""
	if level_text == "LEVEL 2":
		message = "Be careful, this villain is stronger! Get ready!"
	elif level_text == "LEVEL 3":
		message = "Final challenge! The boss awaits... Get ready!"
	else:
		message = "Get ready!"
		
	show_message(level_text, message, level_color)
	log_debug("Level transition message displayed: " + level_text + " - " + message)

func show_game_over():
	show_message("GAME OVER", "You were defeated! Try again.", Color(0.5, 0.0, 0.0, 0.9))
	
func show_game_win():
	show_message("VICTORY", "Congratulations! You've defeated all enemies!", Color(0.0, 0.5, 0.0, 0.9))
