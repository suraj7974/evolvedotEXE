extends CharacterBody2D

@export var state_machine: Node  # Expose StateMachine
@export var sprite: AnimatedSprite2D  # Expose Sprite for animations

const JUMP_VELOCITY = -400.0
const SPEED = 300.0
const GRAVITY = 980.0

func _ready():
	if state_machine:
		print("✅ State Machine Loaded Successfully!")

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += GRAVITY * delta  # Apply gravity

	if state_machine:
		state_machine.update(delta)  # Update state machine

	move_and_slide()  # Apply movement


func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
			print("✅ Playing animation:", anim_name)
	else:
		print("❌ ERROR: sprite or sprite_frames is missing!")
