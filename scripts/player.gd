extends CharacterBody2D

@export var state_machine: Node  # Expose StateMachine
@export var sprite: AnimatedSprite2D  # Expose Sprite for animations
@export var hp_bar: ProgressBar  # Player HP bar

var health = 100
const JUMP_VELOCITY = -400.0
const SPEED = 300.0
const GRAVITY = 980.0
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect

func _ready():
	# Create custom health bar using ColorRect
	create_custom_health_bar()
	
	# Setup the camera to follow the player smoothly
	setup_camera()
	
	print("Player Y:", global_position.y)
	if state_machine:
		print("✅ State Machine Loaded Successfully!")

func create_custom_health_bar():
	# Remove existing hp_bar if any
	if hp_bar and is_instance_valid(hp_bar):
		hp_bar.queue_free()
	
	# Background bar (black/dark)
	health_bar_bg = ColorRect.new()
	health_bar_bg.color = Color(0.1, 0.1, 0.1, 0.6)
	health_bar_bg.size = Vector2(32, 1) # 1 pixel height
	health_bar_bg.position = Vector2(-16, -50)
	add_child(health_bar_bg)
	
	# Health fill (green)
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(0.0, 0.8, 0.3, 0.8)
	health_bar_fill.size = Vector2(32, 1) # 1 pixel height
	health_bar_fill.position = Vector2(0, 0) # Relative to background
	health_bar_bg.add_child(health_bar_fill)
	
	# Set initial health display
	update_health_bar()

func update_health_bar():
	if health_bar_fill:
		# Calculate width based on health percentage
		var health_percent = float(health) / 100.0
		health_bar_fill.size.x = 32 * health_percent

func take_damage(amount):
	health -= amount
	update_health_bar()  # Update custom health bar
	
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
	camera.position_smoothing_speed = 7.0  # Higher value = more responsive, lower = smoother
	
	# Set rotation smoothing properties
	camera.rotation_smoothing_enabled = true
	camera.rotation_smoothing_speed = 7.0
	
	# Set zoom and limits if needed
	camera.zoom = Vector2(1.0, 1.0)  # Default zoom level
	
	# Optional drag margin (makes camera move only when player approaches screen edge)
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

	# ✅ Flip the sprite to face movement direction
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
