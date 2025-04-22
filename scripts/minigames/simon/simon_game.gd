extends Node

signal game_completed(success)

@export var num_rounds = 3  
@export var starting_sequence_length = 2  # Starting pattern length
@export var show_time = 1.2  # How long each button lights up - increased from 0.8 to 1.2
@export var pause_time = 0.3  # Pause between button highlights - increased from 0.2 to 0.3
@export_range(0.0, 30.0) var blur_target = 10.0  # Max blur amount

enum GameState { SHOWING_PATTERN, PLAYER_TURN, GAME_OVER }

var current_state = GameState.SHOWING_PATTERN
var current_sequence = []  # The pattern to follow
var player_sequence = []   # Player's input sequence
var current_round = 1
var showing_index = 0      # Index in the sequence being shown
var buttons = []           # Reference to the button nodes
var button_colors = [      # Colors for buttons (normal, highlighted) - reduced to 4 colors
	[Color(0.7, 0.2, 0.2, 0.8), Color(1.0, 0.3, 0.3, 1.0)],     # Red - much brighter highlight with full alpha
	[Color(0.2, 0.7, 0.2, 0.8), Color(0.2, 1.0, 0.2, 1.0)],     # Green - much brighter highlight with full alpha
	[Color(0.2, 0.2, 0.7, 0.8), Color(0.3, 0.3, 1.0, 1.0)],     # Blue - much brighter highlight with full alpha
	[Color(0.7, 0.7, 0.2, 0.8), Color(1.0, 1.0, 0.2, 1.0)],     # Yellow - much brighter highlight with full alpha
]
var button_pitches = [0.7, 0.8, 0.9, 1.0]  # Different pitch for each button - adjusted to 4
var success = false
var is_showing = false
var level_manager

# For blur effect transition
var blur_amount = 0.0

# Keeps track of button hover state
var is_hovering = false

func _ready():
	randomize()
	
	# Get references to buttons - only the first 4 buttons
	for i in range(4):  # Changed from 6 to 4
		buttons.append(get_node("GameLayer/PopupContainer/GamePanel/Buttons/Button" + str(i + 1)))
	
	# Hide unused buttons (Button5 and Button6)
	get_node("GameLayer/PopupContainer/GamePanel/Buttons/Button5").visible = false
	get_node("GameLayer/PopupContainer/GamePanel/Buttons/Button6").visible = false
	
	# Find level manager
	level_manager = get_node_or_null("/root/LevelManager")
	
	# Set up game
	setup_game()
	
	# Enhance UI elements to match the image
	enhance_ui()
	
	# Pause the main game while mini-game runs
	get_tree().paused = true
	
	# Apply blur effect to the background
	var tween = create_tween()
	tween.tween_property(self, "blur_amount", blur_target, 0.5)
	
	# Set this mini-game scene to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Show welcome message
	$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Remember the pattern!"
	await get_tree().create_timer(2.0).timeout
	
	# Start first round
	start_next_round()

# Enhance UI elements to better match the image
func enhance_ui():
	# Get panel and enhance styling
	var panel = $GameLayer/PopupContainer/GamePanel
	var panel_style = panel.get_theme_stylebox("panel").duplicate()
	panel_style.border_width_left = 6
	panel_style.border_width_top = 6
	panel_style.border_width_right = 6
	panel_style.border_width_bottom = 6
	panel_style.border_color = Color(0.294118, 0.521569, 0.831373, 0.85)
	panel_style.corner_radius_top_left = 25
	panel_style.corner_radius_top_right = 25
	panel_style.corner_radius_bottom_left = 25
	panel_style.corner_radius_bottom_right = 25
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Enhance buttons background panel
	var buttons_bg = $GameLayer/PopupContainer/GamePanel/ButtonsBackground
	var bg_style = buttons_bg.get_theme_stylebox("panel").duplicate()
	bg_style.border_width_left = 4
	bg_style.border_width_top = 4
	bg_style.border_width_right = 4
	bg_style.border_width_bottom = 4
	bg_style.border_color = Color(0.294118, 0.486275, 0.713726, 0.5)
	bg_style.corner_radius_top_left = 15
	bg_style.corner_radius_top_right = 15
	bg_style.corner_radius_bottom_left = 15
	bg_style.corner_radius_bottom_right = 15
	buttons_bg.add_theme_stylebox_override("panel", bg_style)
	
	# Enhance buttons with thicker borders
	for i in range(buttons.size()):
		var button = buttons[i]
		var style_normal = button.get_theme_stylebox("normal").duplicate()
		var style_hover = button.get_theme_stylebox("hover").duplicate()
		var style_pressed = button.get_theme_stylebox("pressed").duplicate()
		
		# Increase border width
		style_normal.border_width_left = 5
		style_normal.border_width_top = 5
		style_normal.border_width_right = 5
		style_normal.border_width_bottom = 5
		
		style_hover.border_width_left = 5
		style_hover.border_width_top = 5
		style_hover.border_width_right = 5
		style_hover.border_width_bottom = 5
		
		style_pressed.border_width_left = 5
		style_pressed.border_width_top = 5
		style_pressed.border_width_right = 5
		style_pressed.border_width_bottom = 5
		
		# Apply shadow
		style_normal.shadow_size = 6
		style_hover.shadow_size = 8
		style_pressed.shadow_size = 4
		
		# Apply enhanced styles
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)
		
	# Enhance title and other labels
	var title = $GameLayer/PopupContainer/GamePanel/Title
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)

func _process(_delta):
	# Update the shader blur amount
	if $GameLayer/BlurBackground.material:
		$GameLayer/BlurBackground.material.set_shader_parameter("blur_amount", blur_amount)

func setup_game():
	# Initialize the game
	current_round = 1
	current_sequence = []
	player_sequence = []
	success = false
	
	# Update UI
	$GameLayer/PopupContainer/GamePanel/RoundLabel.text = "Round: " + str(current_round) + "/" + str(num_rounds)
	$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Remember the pattern!"
	
	# Set up button signals - only for the 4 buttons we're using
	for i in range(buttons.size()):
		var button = buttons[i]
		button.pressed.connect(_on_button_pressed.bind(i))
		button.mouse_entered.connect(_on_button_hover.bind(i))
		button.mouse_exited.connect(_on_button_exit.bind(i))
		# Set the initial color
		button.self_modulate = button_colors[i][0]

func start_next_round():
	# Update round label
	$GameLayer/PopupContainer/GamePanel/RoundLabel.text = "Round: " + str(current_round) + "/" + str(num_rounds)
	
	# Generate new sequence for this round
	generate_sequence()
	
	# Show the sequence to the player
	$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Watch carefully..."
	current_state = GameState.SHOWING_PATTERN
	showing_index = 0
	is_showing = false
	
	# Start showing the pattern after a short delay
	await get_tree().create_timer(0.5).timeout
	show_next_in_sequence()

func generate_sequence():
	# Add more steps to the sequence for this round
	var new_steps_to_add = 2  # Add 2 new colors per round
	
	# Clear existing sequence if starting a new game
	if current_round == 1:
		current_sequence = []
	
	# Make sure the sequence is long enough for this round
	# Add exactly 2 new colors for each round
	for i in range(new_steps_to_add):
		current_sequence.append(randi() % 4)  # Changed to 4 buttons
	
	# Log the sequence for debugging
	var seq_str = ""
	for s in current_sequence:
		seq_str += str(s) + " "
	log_debug("Generated sequence: " + seq_str)

func show_next_in_sequence():
	if showing_index < current_sequence.size():
		if not is_showing:
			is_showing = true
			
			# Show one color at a time
			var button_index = current_sequence[showing_index]
			highlight_button(button_index)
			
			# Schedule unhighlight
			await get_tree().create_timer(show_time).timeout
			unhighlight_button(button_index)
			
			is_showing = false
			
			# Move to next button in sequence
			showing_index += 1
			
			# Add a pause between buttons
			await get_tree().create_timer(pause_time).timeout
			show_next_in_sequence()  # Recursively show next button
	else:
		# Done showing the sequence, player's turn
		$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Your turn! Repeat the pattern."
		current_state = GameState.PLAYER_TURN
		player_sequence = []  # Reset player input

func highlight_button(index):
	if index >= 0 and index < buttons.size():
		buttons[index].self_modulate = button_colors[index][1]  # Highlighted color
		# Play sound for feedback
		$SoundEffects/ButtonSound.pitch_scale = button_pitches[index]  # Different pitch for each button
		$SoundEffects/ButtonSound.play()

func unhighlight_button(index):
	if index >= 0 and index < buttons.size():
		buttons[index].self_modulate = button_colors[index][0]  # Normal color

func _on_button_pressed(index):
	if current_state == GameState.PLAYER_TURN:
		# Highlight the button briefly for feedback
		highlight_button(index)
		await get_tree().create_timer(0.2).timeout
		unhighlight_button(index)
		
		# Record player's input
		player_sequence.append(index)
		
		# Check if the input matches the sequence so far
		if player_sequence.size() <= current_sequence.size():
			var check_index = player_sequence.size() - 1
			if player_sequence[check_index] != current_sequence[check_index]:
				# Wrong input!
				_on_wrong_input()
				return
		
		# Check if player completed the sequence for this round
		if player_sequence.size() == current_sequence.size():
			_on_sequence_completed()

func _on_button_hover(index):
	# Subtle highlight when hovering
	if current_state == GameState.PLAYER_TURN:
		var hover_color = button_colors[index][0].lightened(0.2)
		buttons[index].self_modulate = hover_color

func _on_button_exit(index):
	# Restore normal color when not hovering
	if current_state == GameState.PLAYER_TURN:
		buttons[index].self_modulate = button_colors[index][0]

func _on_sequence_completed():
	# Player correctly repeated the sequence
	$SoundEffects/SuccessSound.play()
	
	if current_round >= num_rounds:
		# Player won the game!
		success = true
		end_game()
	else:
		# Move to the next round
		current_round += 1
		$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Good job! Next pattern..."
		await get_tree().create_timer(1.0).timeout
		start_next_round()

func _on_wrong_input():
	# Player made a mistake
	$SoundEffects/FailSound.play()
	
	$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Oops! Wrong pattern."
	current_state = GameState.GAME_OVER
	
	# Flash the correct sequence once more
	await get_tree().create_timer(1.0).timeout
	
	# Show correct pattern one more time
	$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "The correct pattern was..."
	showing_index = 0
	is_showing = false
	await get_tree().create_timer(0.5).timeout
	show_next_in_sequence()
	
	# Wait for the sequence to finish showing
	var wait_time = (show_time + pause_time) * current_sequence.size() + 1.0
	await get_tree().create_timer(wait_time).timeout
	
	# End game with failure
	success = false
	end_game()

func end_game():
	current_state = GameState.GAME_OVER
	
	# Show appropriate message
	if success:
		$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "SUCCESS! You remembered all patterns!\nYou've earned another chance!"
		$SoundEffects/WinSound.play()
	else:
		$GameLayer/PopupContainer/GamePanel/MessageLabel.text = "Game over! You didn't complete all patterns."
		$SoundEffects/LoseSound.play()
	
	# Wait a moment and close
	await get_tree().create_timer(2.0).timeout
	close_popup_and_return()

func close_popup_and_return():
	# Animate blur removal and popup closing
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "blur_amount", 0.0, 0.5)
	tween.parallel().tween_property($GameLayer/PopupContainer, "scale", Vector2(0.5, 0.5), 0.3)
	tween.parallel().tween_property($GameLayer/PopupContainer, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(emit_signal.bind("game_completed", success))
	tween.tween_callback(return_to_main_game)

func return_to_main_game():
	# Unpause the main game
	get_tree().paused = false
	
	if level_manager:
		if success:
			# Player succeeded, give them another chance with 50% HP
			# Make sure game_over is set to false BEFORE restoring health
			level_manager.game_over = false
			
			 # Now call the level manager to restore health
			level_manager.revive_player(0.5)
			
			# Add debug message
			log_debug("Player successfully revived with 50% health")
		else:
			# Player failed, show game over
			level_manager.player_died()
	
	# Remove this scene
	queue_free()

func log_debug(message):
	# Optional debug function - add if not already present 
	print("🎮 Simon: " + message)