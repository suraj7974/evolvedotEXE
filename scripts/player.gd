extends CharacterBody2D

@export var state_machine: Node  # Expose StateMachine
@export var sprite: AnimatedSprite2D  # Expose Sprite for animations

var health = 100
const MAX_DISPLAY_HEALTH = 100  # This is used for health bar display scaling
const JUMP_VELOCITY = -400.0
const SPEED = 300.0
const GRAVITY = 980.0
var player_name = "YOU"  # Name to display on the UI

# Reference to the HUD
var game_hud: CanvasLayer

func _ready():
	# Setup the camera to follow the player smoothly
	setup_camera()
	
	# Create or access the shared HUD
	setup_game_hud()
	
	print("Player Y:", global_position.y)
	if state_machine:
		print("✅ State Machine Loaded Successfully!")

func setup_game_hud():
	# Look for existing HUD
	var existing_hud = get_node_or_null("/root/GameHUD")
	
	if existing_hud:
		game_hud = existing_hud
	else:
		# Create new HUD if it doesn't exist
		game_hud = CanvasLayer.new()
		game_hud.name = "GameHUD"
		game_hud.layer = 10  # Top layer
		get_tree().root.call_deferred("add_child", game_hud)
		
		# Create the fighting game style HUD
		create_fighting_game_hud()

func create_fighting_game_hud():
	# Create main container
	var hud_container = Control.new()
	hud_container.name = "FightingGameHUD"
	hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the screen
	game_hud.add_child(hud_container)
	
	# Add top bar background with a cleaner design
	var top_bar = ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color(0.05, 0.05, 0.07, 0.85)  # Darker, more transparent
	top_bar.custom_minimum_size = Vector2(1152, 70)  # Slightly taller
	top_bar.position = Vector2(0, 0)
	hud_container.add_child(top_bar)
	
	# Add a thin separator line
	var separator = ColorRect.new()
	separator.name = "Separator"
	separator.color = Color(0.7, 0.7, 0.8, 0.4)  # Subtle highlight
	separator.position = Vector2(0, 68)
	separator.custom_minimum_size = Vector2(1152, 2)
	top_bar.add_child(separator)
	
	# Create player health container - Using MarginContainer instead of HBoxContainer
	var player_health_container = MarginContainer.new()
	player_health_container.name = "PlayerHealthContainer"
	player_health_container.position = Vector2(20, 15)
	player_health_container.size = Vector2(400, 40)
	top_bar.add_child(player_health_container)
	
	# Player side layout (HBox)
	var player_layout = HBoxContainer.new()
	player_layout.name = "PlayerLayout"
	player_layout.size_flags_horizontal = Control.SIZE_FILL
	player_layout.size_flags_vertical = Control.SIZE_FILL
	player_health_container.add_child(player_layout)
	
	# Player name label
	var player_name_label = Label.new()
	player_name_label.name = "PlayerNameLabel"
	player_name_label.text = player_name
	player_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	player_layout.add_child(player_name_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(10, 0)
	player_layout.add_child(spacer)
	
	# Player health bar frame - using a single container
	var player_bar_container = Control.new()
	player_bar_container.name = "PlayerBarContainer"
	player_bar_container.custom_minimum_size = Vector2(260, 40)
	player_bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_layout.add_child(player_bar_container)
	
	# Frame (border)
	var player_bar_frame = ColorRect.new()
	player_bar_frame.name = "PlayerHealthBarFrame"
	player_bar_frame.color = Color(0.7, 0.7, 0.8, 0.4)  # Light border color
	player_bar_frame.size = Vector2(260, 40)
	player_bar_frame.position = Vector2(0, 0)
	player_bar_container.add_child(player_bar_frame)
	
	# Background
	var player_bar_bg = ColorRect.new()
	player_bar_bg.name = "PlayerHealthBarBG"
	player_bar_bg.color = Color(0.12, 0.12, 0.14, 1.0)  # Darker background
	player_bar_bg.position = Vector2(2, 2)
	player_bar_bg.size = Vector2(256, 36)
	player_bar_container.add_child(player_bar_bg)
	
	# Fill
	var player_bar_fill = ColorRect.new()
	player_bar_fill.name = "PlayerHealthBarFill"
	player_bar_fill.color = Color(0.1, 0.8, 0.3, 1.0)  # Brighter green
	player_bar_fill.position = Vector2(0, 0)
	player_bar_fill.size = Vector2(256, 36)
	player_bar_bg.add_child(player_bar_fill)
	
	# Add spacer
	var spacer2 = Control.new()
	spacer2.name = "Spacer2"
	spacer2.custom_minimum_size = Vector2(10, 0)
	player_layout.add_child(spacer2)
	
	# Player health text
	var player_health_text = Label.new()
	player_health_text.name = "PlayerHealthText"
	player_health_text.text = str(health)
	player_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_health_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	player_layout.add_child(player_health_text)
	
	# Create villain health container - Using MarginContainer
	var villain_health_container = MarginContainer.new()
	villain_health_container.name = "VillainHealthContainer"
	villain_health_container.position = Vector2(700, 15)
	villain_health_container.size = Vector2(400, 40)
	top_bar.add_child(villain_health_container)
	
	# Villain side layout (HBox)
	var villain_layout = HBoxContainer.new()
	villain_layout.name = "VillainLayout"
	villain_layout.size_flags_horizontal = Control.SIZE_FILL
	villain_layout.size_flags_vertical = Control.SIZE_FILL
	villain_health_container.add_child(villain_layout)
	
	# Villain health text
	var villain_health_text = Label.new()
	villain_health_text.name = "VillainHealthText"
	villain_health_text.text = get_villain_health() # Get actual villain health instead of hardcoding "100"
	villain_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	villain_health_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	villain_layout.add_child(villain_health_text)
	
	# Add spacer
	var spacer3 = Control.new()
	spacer3.name = "Spacer3"
	spacer3.custom_minimum_size = Vector2(10, 0)
	villain_layout.add_child(spacer3)
	
	# Villain health bar container
	var villain_bar_container = Control.new()
	villain_bar_container.name = "VillainBarContainer"
	villain_bar_container.custom_minimum_size = Vector2(260, 40)
	villain_bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	villain_layout.add_child(villain_bar_container)
	
	# Frame (border)
	var villain_bar_frame = ColorRect.new()
	villain_bar_frame.name = "VillainHealthBarFrame"
	villain_bar_frame.color = Color(0.7, 0.7, 0.8, 0.4)  # Light border color
	villain_bar_frame.size = Vector2(260, 40)
	villain_bar_frame.position = Vector2(0, 0)
	villain_bar_container.add_child(villain_bar_frame)
	
	# Background
	var villain_bar_bg = ColorRect.new()
	villain_bar_bg.name = "VillainHealthBarBG"
	villain_bar_bg.color = Color(0.12, 0.12, 0.14, 1.0)  # Darker background
	villain_bar_bg.position = Vector2(2, 2)
	villain_bar_bg.size = Vector2(256, 36)
	villain_bar_container.add_child(villain_bar_bg)
	
	# Fill
	var villain_bar_fill = ColorRect.new()
	villain_bar_fill.name = "VillainHealthBarFill"
	villain_bar_fill.color = Color(0.9, 0.2, 0.2, 1.0)  # Brighter red
	villain_bar_fill.position = Vector2(0, 0)
	villain_bar_fill.size = Vector2(256, 36)
	villain_bar_bg.add_child(villain_bar_fill)
	
	# Add spacer
	var spacer4 = Control.new()
	spacer4.name = "Spacer4"
	spacer4.custom_minimum_size = Vector2(10, 0)
	villain_layout.add_child(spacer4)
	
	# Villain name label
	var villain_name_label = Label.new()
	villain_name_label.name = "VillainNameLabel"
	villain_name_label.text = "VILLAIN"
	villain_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	villain_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	villain_layout.add_child(villain_name_label)

func update_health_bar():
	# Find the HUD
	var hud = get_node_or_null("/root/GameHUD")
	if not hud:
		# If HUD doesn't exist yet, create it
		setup_game_hud()
		hud = game_hud
	
	# Access player health components
	var health_container = hud.get_node_or_null("FightingGameHUD/TopBar/PlayerHealthContainer")
	if health_container:
		# Update health text - show actual health value
		var health_text = health_container.get_node_or_null("PlayerLayout/PlayerHealthText")
		if health_text:
			health_text.text = str(int(health))
		
		# Update health bar fill with the new structure
		var player_layout = health_container.get_node_or_null("PlayerLayout")
		if player_layout:
			var bar_container = player_layout.get_node_or_null("PlayerBarContainer")
			if bar_container:
				var health_bg = bar_container.get_node_or_null("PlayerHealthBarBG")
				if health_bg:
					var health_fill = health_bg.get_node_or_null("PlayerHealthBarFill")
					if health_fill:
						# Calculate percentage based on MAX_DISPLAY_HEALTH instead of actual health
						var percent = min(float(health) / MAX_DISPLAY_HEALTH, 1.0)
						health_fill.size.x = 256 * percent
						
						# Change color based on health value relative to MAX_DISPLAY_HEALTH
						var health_ratio = float(health) / MAX_DISPLAY_HEALTH
						if health_ratio < 0.3:
							health_fill.color = Color(0.9, 0.2, 0.2, 1.0)  # Red when low
						elif health_ratio < 0.6:
							health_fill.color = Color(0.9, 0.7, 0.1, 1.0)  # Yellow when medium
						else:
							health_fill.color = Color(0.1, 0.8, 0.3, 1.0)  # Green when high

func take_damage(amount):
	health -= amount
	update_health_bar()  # Update the health bar in the HUD
	
	# Visual feedback of damage
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)

	print("💔 Player took damage! HP:", health)

	if health <= 0:
		print("☠️ Player Died!")
		state_machine.transition_to("DeadState")

func setup_camera():
	# Check if camera exists, if not create one
	var camera = $Camera2D if has_node("Camera2D") else null
	
	if not camera:
		camera = Camera2D.new()
		add_child(camera)
		camera.name = "Camera2D"
	
	# Configure camera for smooth movement
	camera.make_current()  # Make this the active camera
	
	# Set smoothing properties
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	
	# Set rotation smoothing properties
	camera.rotation_smoothing_enabled = true
	camera.rotation_smoothing_speed = 7.0
	
	# Set zoom and limits if needed
	camera.zoom = Vector2(1.0, 1.0)  # Default zoom level
	
	# Optional drag margin
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.1
	camera.drag_right_margin = 0.1
	camera.drag_top_margin = 0.1
	camera.drag_bottom_margin = 0.1
	
	print("✅ Camera setup complete")

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle movement
	var direction = 0
	if Input.is_action_pressed("move_left"):
		direction = -1
	elif Input.is_action_pressed("move_right"):
		direction = 1

	# Move the player
	velocity.x = direction * SPEED

	# Flip the sprite to face movement direction
	if direction != 0:
		sprite.flip_h = (direction == -1)  # Face left if moving left
		
		# Optional: Slight camera offset in movement direction
		var camera = get_node_or_null("Camera2D")
		if camera:
			camera.offset.x = lerp(camera.offset.x, direction * 50.0, delta * 2.0)

	if state_machine:
		state_machine.update(delta)

	move_and_slide()

func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
			print("✅ Playing animation:", anim_name)
		else:
			print("❌ ERROR: Animation '" + anim_name + "' not found!")
	else:
		print("❌ ERROR: sprite or sprite_frames is missing!")

func get_villain_health() -> String:
	# Find villain in the scene
	var villains = get_tree().get_nodes_in_group("villain")
	if villains.size() > 0:
		return str(int(villains[0].health))
	else:
		# If villain isn't found yet, use a timer to try again in the next frame
		call_deferred("_try_update_villain_health_later")
		return "..." # Show placeholder until we get the actual value
		
func _try_update_villain_health_later():
	# This will try to update the villain health text shortly after startup
	await get_tree().create_timer(0.1).timeout
	
	# Try to find the HUD and update villain health text
	var hud = get_node_or_null("/root/GameHUD")
	if hud:
		var health_container = hud.get_node_or_null("FightingGameHUD/TopBar/VillainHealthContainer")
		if health_container:
			var health_text = health_container.get_node_or_null("VillainLayout/VillainHealthText")
			if health_text:
				var villains = get_tree().get_nodes_in_group("villain")
				if villains.size() > 0:
					health_text.text = str(int(villains[0].health))
				else:
					# Try again if villain still not found
					call_deferred("_try_update_villain_health_later")
