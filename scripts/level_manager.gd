extends Node

# Level settings
var current_level = 1
var max_level = 3

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
			"health": 250,
			"damage": 10,
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

func _ready():
	# Make this a singleton so it doesn't get destroyed between scenes
	if get_parent() == get_tree().get_root():
		set_process(false)
		return
		
	# Add to root so it persists
	get_tree().root.call_deferred("add_child", self)
	call_deferred("_initialize")
	
func _initialize():
	# Wait a bit for the scene to be fully ready
	await get_tree().create_timer(0.2).timeout
	
	# Find player and villain
	find_game_entities()
	
	# Apply level settings
	if current_level in level_data:
		apply_level_settings()

func find_game_entities():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	var villains = get_tree().get_nodes_in_group("villain")
	if villains.size() > 0:
		villain = villains[0]
		
	# Get HUD reference
	game_hud = get_node_or_null("/root/GameHUD")

func apply_level_settings():
	print("🎮 Applying settings for level " + str(current_level))
	
	# Apply player settings
	if player:
		var player_settings = level_data[current_level]["player"]
		player.health = player_settings["health"]
		player.SPEED = player_settings["speed"]
		player.update_health_bar()
		
		# Find attack state to update damage values
		var attack_state = player.state_machine.states.get("AttackState")
		if attack_state:
			# Save the original damage values to the attack state
			attack_state.damage_attack1 = player_settings["damage_attack1"]
			attack_state.damage_attack2 = player_settings["damage_attack2"]
	
	# Apply villain settings
	if villain:
		var villain_settings = level_data[current_level]["villain"]
		villain.health = villain_settings["health"]
		villain.SPEED = villain_settings["speed"]
		villain.DAMAGE = villain_settings["damage"]
		villain.ATTACK_RANGE = villain_settings["attack_range"]
		villain.villain_name = villain_settings["name"]
		villain.update_health_bar()

func advance_to_next_level():
	if current_level < max_level:
		current_level += 1
		
		# Show level transition
		show_level_message("LEVEL " + str(current_level))
		
		# Reset game state for next level
		await get_tree().create_timer(2.0).timeout
		
		# Apply settings for new level
		apply_level_settings()
		
		# Position villain and player correctly
		reset_positions()
		
		game_over = false
	else:
		# Player has beaten the final level
		show_game_win()

func player_died():
	if not game_over:
		game_over = true
		show_game_over()

func villain_died():
	if not game_over:
		# Instead of respawning, advance to next level
		advance_to_next_level()

func reset_positions():
	if player:
		player.global_position = Vector2(100, 300)
		player.velocity = Vector2.ZERO
		
	if villain:
		villain.global_position = Vector2(400, 300)
		villain.velocity = Vector2.ZERO
		villain.is_dead = false
		villain.can_attack = true
		villain.attack_cooldown = 0
		
		# Reset collision state
		if villain.has_node("CollisionShape2D"):
			villain.get_node("CollisionShape2D").set_deferred("disabled", false)
		
		if villain.has_node("Area2D") and villain.get_node("Area2D").has_node("CollisionShape2D"):
			villain.get_node("Area2D").get_node("CollisionShape2D").set_deferred("disabled", false)
		
		# Return to idle state
		villain.state_machine.on_state_transition("IdleState")

func show_message(title, message, color = Color(0.2, 0.2, 0.2, 0.9)):
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
		# Fix the problematic line for title_label font size
		var title_font_size = 48
		title_label.add_theme_font_size_override("font_size", title_font_size)
		vbox.add_child(title_label)
		
		var msg_label = Label.new()
		msg_label.name = "Message"
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Fix the problematic line for msg_label font size
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
		overlay.get_node("Background").color = color
		
		if title_label:
			title_label.text = title
		if msg_label:
			msg_label.text = message
	
	# Make overlay visible
	overlay.visible = true
	
	# If it's a temporary message (like level transition)
	if title != "GAME OVER" and title != "VICTORY":
		await get_tree().create_timer(2.0).timeout
		overlay.visible = false

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func show_level_message(level_text):
	show_message(level_text, "Get ready!", Color(0.0, 0.0, 0.5, 0.8))

func show_game_over():
	show_message("GAME OVER", "You were defeated! Try again.", Color(0.5, 0.0, 0.0, 0.9))
	
func show_game_win():
	show_message("VICTORY", "Congratulations! You've defeated all enemies!", Color(0.0, 0.5, 0.0, 0.9))
