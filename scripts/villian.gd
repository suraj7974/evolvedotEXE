extends CharacterBody2D

@export var state_machine: Node  
@export var sprite: AnimatedSprite2D  
@export var player: CharacterBody2D  
@export var hp_bar: ProgressBar  
@export var detection_area: Area2D  
@export var detection_range: float = 200.0  # Detection range

const SPEED = 80.0
const ATTACK_RANGE = 80.0
const DAMAGE = 20
var health = 100
const GRAVITY = 980.0

func _ready():
	hp_bar.max_value = health
	hp_bar.value = health
	print("Villain Y:", global_position.y)

	# ✅ Ensure the State Machine is loaded
	state_machine = $StateMachine  
	if state_machine:
		print("✅ Villain State Machine Loaded Successfully!")

# ✅ Check if player is within range
func is_player_near() -> bool:
	if player:
		return global_position.distance_to(player.global_position) < detection_range
	return false

func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _physics_process(delta):
	# ✅ Apply Gravity (Fixes the infinite fall issue)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0  # Reset when on the floor

	# ✅ Ensure State Machine Updates
	if state_machine:
		state_machine.update(delta)

	# ✅ Keep HP Bar Updated
	hp_bar.value = health  
	
func take_damage(amount):
	health -= amount
	hp_bar.value = health
	if health <= 0:
		print("💀 Villain Died!")  
		if state_machine:
			state_machine.on_state_transition("DeadState")
