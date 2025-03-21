extends Node

var states = {}  
var current_state  
var player  

func _ready():
	player = get_parent()  # ✅ Fix: Get reference to Player

	states["IdleState"] = $IdleState
	states["AttackState"] = $AttackState

	for state in states.values():
		state.transitioned.connect(on_state_transition)  
		state.player = player  # ✅ Fix: Pass the player reference

	current_state = states["IdleState"]  
	if current_state:
		current_state.enter()

func _process(delta):
	if current_state:
		current_state.process(delta)

func update(delta):  # ✅ Fix: Add missing function
	if current_state:
		current_state.process(delta)

func on_state_transition(new_state_name):
	if new_state_name in states:
		current_state.exit()
		current_state = states[new_state_name]
		current_state.enter()
