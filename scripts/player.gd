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
