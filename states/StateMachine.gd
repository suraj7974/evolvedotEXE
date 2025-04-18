extends Node

var states = {}  
var current_state  
var player  

func _ready():
	player = get_parent()  # ✅ Fix: Get reference to Player

	states["IdleState"] = $IdleState
	states["RunState"] = $RunState
	states["JumpState"] = $JumpState
	states["AttackState"] = $AttackState
	states["DeadState"] = $DeadState

	for state in states.values():
		state.transitioned.connect(on_state_transition)  
		state.player = player  # ✅ Fix: Pass the player reference

	current_state = states["IdleState"]  
	if current_state:
		current_state.enter()

func transition_to(new_state_name, attack_type = null):
	if new_state_name in states:
		if current_state:
			current_state.exit()
		current_state = states[new_state_name]
		if attack_type:
			current_state.enter(attack_type)  # Pass attack type to AttackState
		else:
			current_state.enter()
	else:
		print("❌ ERROR: Invalid state transition:", new_state_name)


func _process(delta):
	if current_state:
		current_state.process(delta)

func update(delta):  # ✅ Fix: Add missing function
	if current_state:
		current_state.process(delta)

func on_state_transition(new_state_name, attack_type = null):
	if new_state_name in states:
		current_state.exit()
		current_state = states[new_state_name]
		if attack_type:
			current_state.enter(attack_type)  # Pass attack type to AttackState
		else:
			current_state.enter()
