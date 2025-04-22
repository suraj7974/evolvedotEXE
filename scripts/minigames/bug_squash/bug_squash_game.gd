extends Node2D

signal game_completed(success)

@export var game_duration = 30.0  # Game lasts 30 seconds
@export var target_score = 200   # Score needed to win
@export var bug_scene: PackedScene
@export var spawn_cooldown = 1.0  # Time between bug spawns

var score = 0
var lives = 3
var time_left = 0
var game_over = false
var spawn_timer = 0
var difficulty_level = 1
var popup_mode = true  # Controls whether game appears as popup

# Store reference to LevelManager for returning to main game
var level_manager

func _ready():
	randomize()
	time_left = game_duration
	
	# Configure UI elements
	$UI/ScoreLabel.text = "SCORE: 0"
	$UI/LivesLabel.text = "LIVES: " + str(lives)
	$UI/TimeLabel.text = "TIME: " + str(int(time_left))
	$UI/MessageLabel.text = "Squash bugs to continue your adventure!"
	$UI/MessageLabel.visible = true
	
	# If in popup mode, setup the correct display style
	if popup_mode:
		setup_popup_style()
	
	# Find level manager if exists
	level_manager = get_node_or_null("/root/LevelManager")
	
	# Pause the main game while mini-game runs
	get_tree().paused = true
	
	# Set this mini-game scene to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Show initial message
	await get_tree().create_timer(2.0).timeout
	$UI/MessageLabel.text = "Ready..."
	await get_tree().create_timer(1.0).timeout
	$UI/MessageLabel.text = "Set..."
	await get_tree().create_timer(1.0).timeout
	$UI/MessageLabel.text = "SQUASH!"
	await get_tree().create_timer(0.5).timeout
	$UI/MessageLabel.visible = false
	
	# Start game timers
	$GameTimer.start()
	spawn_timer = spawn_cooldown

# Make the game appear as a popup overlay
func setup_popup_style():
	# Make the popup container visible and position in center
	$PopupContainer.visible = true
	
	# Make sure our game area is contained within the popup area
	$Bugs.position = Vector2(125, 125)  # Offset bugs to center of popup
	
	# Limit bugs to spawning within popup area
	var popup_size = $PopupContainer/PopupPanel.size
	
	# Darken background behind popup
	var screen_size = get_viewport_rect().size
	$Background.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	$Background.size = screen_size
	
	# Add animation for popup appearing
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	$PopupContainer.scale = Vector2(0.5, 0.5)  # Start smaller
	$PopupContainer.modulate = Color(1, 1, 1, 0) # Start transparent
	tween.tween_property($PopupContainer, "scale", Vector2(1, 1), 0.5)
	tween.parallel().tween_property($PopupContainer, "modulate", Color(1, 1, 1, 1), 0.5)

func _process(delta):
	if game_over:
		return
		
	# Update time display
	$UI/TimeLabel.text = "TIME: " + str(int(time_left))
	
	# Handle bug spawning
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_bug()
		spawn_timer = spawn_cooldown * (1.0 - difficulty_level * 0.05)  # Spawn faster as difficulty increases
	
	# Update progressbar
	$UI/ScoreProgress.value = min(score / float(target_score) * 100, 100)
	
	# Increase difficulty over time
	if time_left < game_duration * 0.7 and difficulty_level == 1:
		difficulty_level = 2
	elif time_left < game_duration * 0.4 and difficulty_level == 2:
		difficulty_level = 3
	elif time_left < game_duration * 0.2 and difficulty_level == 3:
		difficulty_level = 4

func _on_bug_squashed(points):
	score += points
	$UI/ScoreLabel.text = "SCORE: " + str(score)
	$SoundEffects/SquashSound.play()
	
	# Check for victory condition
	if score >= target_score:
		end_game(true)

func _on_bug_escaped():
	lives -= 1
	$UI/LivesLabel.text = "LIVES: " + str(lives)
	$SoundEffects/EscapeSound.play()
	
	if lives <= 0:
		end_game(false)

func _on_game_timer_timeout():
	time_left -= 1
	if time_left <= 0:
		# Time's up!
		if score >= target_score:
			end_game(true)
		else:
			end_game(false)

func spawn_bug():
	if game_over:
		return
		
	var bug_instance = bug_scene.instantiate()
	
	# Configure bug based on difficulty
	var bug_type = "normal"
	var rand = randf()
	
	match difficulty_level:
		1:  # Easy - mostly normal bugs
			if rand < 0.8:
				bug_type = "normal"
			else:
				bug_type = "bonus"
		2:  # Medium - introduce fast bugs
			if rand < 0.6:
				bug_type = "normal"
			elif rand < 0.85:
				bug_type = "fast"
			else:
				bug_type = "bonus"
		3:  # Hard - more fast bugs, less bonus
			if rand < 0.4:
				bug_type = "normal"
			elif rand < 0.85:
				bug_type = "fast"
			else:
				bug_type = "bonus"
		4:  # Very hard - add boss bugs
			if rand < 0.3:
				bug_type = "normal"
			elif rand < 0.7:
				bug_type = "fast"
			elif rand < 0.9:
				bug_type = "bonus"
			else:
				bug_type = "boss"
	
	bug_instance.bug_type = bug_type
	bug_instance.connect("squashed", _on_bug_squashed)
	bug_instance.connect("escaped", _on_bug_escaped)
	if bug_type == "boss":
		bug_instance.connect("spawn_child", _on_boss_spawn_child)
	
	# If in popup mode, limit bug spawning area
	if popup_mode:
		var popup_width = $PopupContainer/PopupPanel.size.x - 100
		var popup_height = $PopupContainer/PopupPanel.size.y - 150
		bug_instance.position = Vector2(
			randf_range(50, popup_width),
			randf_range(50, popup_height)
		)
	
	$Bugs.add_child(bug_instance)
	
func _on_boss_spawn_child(pos):
	# Boss bugs can spawn smaller bugs
	var child_bug = bug_scene.instantiate()
	child_bug.bug_type = "fast"
	child_bug.position = pos
	child_bug.scale = Vector2(0.7, 0.7)
	child_bug.connect("squashed", _on_bug_squashed)
	child_bug.connect("escaped", _on_bug_escaped)
	$Bugs.add_child(child_bug)

func end_game(success):
	game_over = true
	$GameTimer.stop()
	
	# Clear any remaining bugs
	for bug in $Bugs.get_children():
		bug.queue_free()
	
	# Show result message
	$UI/MessageLabel.visible = true
	if success:
		$UI/MessageLabel.text = "VICTORY! You squashed enough bugs!\nReturning to main game..."
		$SoundEffects/WinSound.play()
		await get_tree().create_timer(2.0).timeout
		close_popup_and_return(success)
	else:
		$UI/MessageLabel.text = "FAILED! Too many bugs escaped!\nReturning to main game..."
		$SoundEffects/LoseSound.play()
		await get_tree().create_timer(2.0).timeout
		close_popup_and_return(success)

func close_popup_and_return(success):
	# Animate popup closing
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property($PopupContainer, "scale", Vector2(0.5, 0.5), 0.3)
	tween.parallel().tween_property($PopupContainer, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(emit_signal.bind("game_completed", success))
	tween.tween_callback(return_to_main_game.bind(success))

func return_to_main_game(revive):
	# Unpause the main game
	get_tree().paused = false
	
	if level_manager:
		if revive:
			# Player succeeded, give them another chance
			level_manager.revive_player()
		else:
			# Player failed, show game over
			level_manager.player_died()
	
	# Remove this scene
	queue_free()
