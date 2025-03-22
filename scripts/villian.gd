extends CharacterBody2D

@export var state_machine: Node  
@export var sprite: AnimatedSprite2D  
@export var player: CharacterBody2D  
@export var hp_bar: ProgressBar  
@export var detection_area: Area2D  
@export var detection_range: float = 5  # Detection range

const SPEED = 80.0
const ATTACK_RANGE = 80.0
const DAMAGE = 20
var health = 100
const GRAVITY = 980.0

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]  # Get the first player
		print("✅ Player assigned successfully!")
	else:
		print("❌ ERROR: No player found in group 'player'!")
	hp_bar.max_value = health
	hp_bar.value = health
	print("Villain Y:", global_position.y)

	# ✅ Ensure the State Machine is loaded
	state_machine = $StateMachine  
	if state_machine:
		print("✅ Villain State Machine Loaded Successfully!")

func is_player_near() -> bool:
	if player:
		var distance = global_position.distance_to(player.global_position)
		print("🔍 Player Distance:", distance, "| Detection Range:", detection_range)

		if distance < detection_range:
			print("✅ Player is within detection range!")
			return true
		else:
			print("🛑 Player is too far, villain should NOT follow!")
			return false

	return false


func play_animation(anim_name: String):
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _physics_process(delta):
	# ✅ Apply Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0  # Reset when on the floor

	# ✅ STOP MOVEMENT IF IN IDLE STATE
	if state_machine and state_machine.current_state.name == "villain_idlestate":
		print("🛑 Force Stopping Movement in IdleState")
		velocity = Vector2.ZERO
		move_and_slide()  # Apply zero velocity
		return  # ⬅️ Exit function to stop processing further movement

	# ✅ Ensure State Machine Updates
	if state_machine:
		state_machine.update(delta)

	# ✅ Debugging Output
	print("Velocity:", velocity, "| Is On Floor:", is_on_floor())

	move_and_slide()  # ✅ Ensure movement update

	
func take_damage(amount):
	health -= amount
	hp_bar.value = health
	if health <= 0:
		print("💀 Villain Died!")  
		if state_machine:
			state_machine.on_state_transition("DeadState")
