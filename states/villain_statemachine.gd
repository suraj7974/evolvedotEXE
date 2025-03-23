extends Node

var states = {}  
var current_state  
var villain  

func _ready():
	villain = get_parent()  

	states["IdleState"] = get_node("villain_idlestate")  
	states["ChaseState"] = get_node("villain_chasestate")  
	states["AttackState"] = get_node("villain_attackstate")  
	states["DeadState"] = get_node("villain_deadstate")  

	for state in states.values():
		state.transitioned.connect(on_state_transition)  
		state.villain = villain  

	current_state = states["IdleState"]  
	if current_state:
		current_state.enter()

func _process(delta):
	if current_state:
		current_state._process(delta)

func _physics_process(delta):  
	if current_state:
		current_state._physics_process(delta)

func update(delta):  
	if current_state and current_state.has_method("update"):
		current_state.update(delta)

func on_state_transition(new_state_name):
	print("🔄 Villain transitioning to:", new_state_name)
	
	# Prevent transitioning to the same state
	if current_state and states[new_state_name] == current_state:
		print("⚠️ Already in state:", new_state_name)
		return
		
	if new_state_name in states:
		print("✅ Found state:", new_state_name)
		if current_state:
			current_state.exit()
		current_state = states[new_state_name]
		current_state.enter()
	else:
		print("❌ ERROR: Invalid state transition:", new_state_name)
		print("❌ Available states:", states.keys())
