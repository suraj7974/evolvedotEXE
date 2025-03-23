extends CharacterBody2D

@export var state_machine: Node  # Expose StateMachine
@export var sprite: AnimatedSprite2D  # Expose Sprite for animations
@export var hp_bar: ProgressBar  # Player HP bar

var health = 100
const JUMP_VELOCITY = -400.0
const SPEED = 300.0
const GRAVITY = 980.0

func _ready():
	hp_bar.max_value = health
	hp_bar.value = health
	print("Player Y:", global_position.y)
	if state_machine:
		print("✅ State Machine Loaded Successfully!")
	
	
func take_damage(amount):
	health -= amount
	hp_bar.value = health  # Update UI
	print("💔 Player took damage! HP:", health)

	if health <= 0:
		print("☠️ Player Died!")
		state_machine.transition_to("DeadState")  # State transition happens but animation issue remains

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
