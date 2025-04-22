extends Control

signal game_complete(success)

# Game state
enum GameState { SHOWING_SEQUENCE, PLAYER_INPUT, GAME_OVER, SUCCESS }
var current_state = GameState.SHOWING_SEQUENCE

# Game parameters
var current_level = 1
var max_level = 5  # Number of successful rounds needed to win
var sequence = []
var player_sequence = []
var current_sequence_index = 0
var button_flash_active = false

# UI References
@onready var red_button = $PanelContainer/VBoxContainer/GameArea/RedButton
@onready var blue_button = $PanelContainer/VBoxContainer/GameArea/BlueButton
@onready var green_button = $PanelContainer/VBoxContainer/GameArea/GreenButton
@onready var yellow_button = $PanelContainer/VBoxContainer/GameArea/YellowButton
@onready var status_label = $PanelContainer/VBoxContainer/StatusLabel
@onready var level_label = $PanelContainer/VBoxContainer/LevelLabel
@onready var sequence_timer = $SequenceTimer
@onready var button_flash_timer = $ButtonFlashTimer
@onready var success_sound = $SuccessSound
@onready var error_sound = $ErrorSound

# Button sound references
@onready var tone_c = $ToneC
@onready var tone_d = $ToneD
@onready var tone_e = $ToneE
@onready var tone_g = $ToneG

# Original button styles
var original_styles = {}
var active_button = null

# Button color modifiers
const HIGHLIGHT_MOD = 1.3
const DIM_MOD = 0.7

func _ready():
	# Store original styles
	original_styles[red_button] = red_button.get_theme_stylebox("normal").duplicate()
	original_styles[blue_button] = blue_button.get_theme_stylebox("normal").duplicate()
	original_styles[green_button] = green_button.get_theme_stylebox("normal").duplicate()
	original_styles[yellow_button] = yellow_button.get_theme_stylebox("normal").duplicate()
	
	# Connect button signals
	red_button.pressed.connect(_on_button_pressed.bind(red_button, 0, tone_c))
	blue_button.pressed.connect(_on_button_pressed.bind(blue_button, 1, tone_d))
	green_button.pressed.connect(_on_button_pressed.bind(green_button, 2, tone_e))
	yellow_button.pressed.connect(_on_button_pressed.bind(yellow_button, 3, tone_g))
	
	# Initialize game
	start_game()

func start_game():
	current_level = 1
	sequence = []
	player_sequence = []
	update_level_ui()
	start_next_round()

func start_next_round():
	player_sequence = []
	current_sequence_index = 0
	
	# Update UI
	status_label.text = "Watch the sequence..."
	
	# Add a new random element to the sequence
	sequence.append(randi() % 4)
	
	# Start displaying sequence after a short delay
	sequence_timer.start()
	current_state = GameState.SHOWING_SEQUENCE
	
	# Disable buttons during sequence display
	set_buttons_enabled(false)

func update_level_ui():
	level_label.text = "Level: " + str(current_level) + " / " + str(max_level)

func set_buttons_enabled(enabled: bool):
	red_button.disabled = !enabled
	blue_button.disabled = !enabled
	green_button.disabled = !enabled
	yellow_button.disabled = !enabled

func flash_button(button, sound):
	if active_button:
		restore_button(active_button)
	
	active_button = button
	
	# Highlight the button
	var style = button.get_theme_stylebox("normal").duplicate()
	var original_color = style.bg_color
	style.bg_color = original_color * HIGHLIGHT_MOD
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	
	# Play sound
	if sound:
		sound.play()
	
	button_flash_timer.start()

func restore_button(button):
	if button:
		button.add_theme_stylebox_override("normal", original_styles[button].duplicate())
		button.add_theme_stylebox_override("hover", original_styles[button].duplicate())
		button.add_theme_stylebox_override("pressed", original_styles[button].duplicate())

func _on_button_flash_timer_timeout():
	if active_button:
		restore_button(active_button)
		active_button = null
	
	if current_state == GameState.SHOWING_SEQUENCE:
		display_next_sequence_item()
	
func _on_sequence_timer_timeout():
	if current_state == GameState.SHOWING_SEQUENCE:
		display_next_sequence_item()
		
func display_next_sequence_item():
	if current_sequence_index < sequence.size():
		# Show next button in sequence
		var button_index = sequence[current_sequence_index]
		var button
		var sound
		
		match button_index:
			0: 
				button = red_button
				sound = tone_c
			1: 
				button = blue_button
				sound = tone_d
			2: 
				button = green_button
				sound = tone_e
			3: 
				button = yellow_button
				sound = tone_g
		
		flash_button(button, sound)
		current_sequence_index += 1
	else:
		# Sequence display complete, switch to player input
		current_sequence_index = 0
		current_state = GameState.PLAYER_INPUT
		status_label.text = "Your turn! Repeat the sequence."
		set_buttons_enabled(true)

func _on_button_pressed(button, button_index, sound):
	if current_state == GameState.PLAYER_INPUT:
		flash_button(button, sound)
		
		player_sequence.append(button_index)
		
		# Check if the player's input is correct
		var current_index = player_sequence.size() - 1
		
		if player_sequence[current_index] != sequence[current_index]:
			# Player made a mistake
			game_over(false)
			return
			
		# Check if the player has completed the sequence for this round
		if player_sequence.size() == sequence.size():
			round_complete()

func round_complete():
	set_buttons_enabled(false)
	
	if current_level == max_level:
		# Player has won the game
		game_over(true)
	else:
		# Move to the next level
		current_level += 1
		update_level_ui()
		status_label.text = "Well done! Next level..."
		success_sound.play()
		sequence_timer.wait_time = 1.5
		sequence_timer.start()
		current_state = GameState.SHOWING_SEQUENCE
	
func game_over(success: bool):
	current_state = GameState.GAME_OVER
	set_buttons_enabled(false)
	
	if success:
		status_label.text = "SUCCESS! You've completed all levels!"
		success_sound.play()
	else:
		status_label.text = "Game Over! Sequence failed."
		error_sound.play()
	
	# Signal the game result after a short delay
	await get_tree().create_timer(2.0).timeout
	emit_signal("game_complete", success)