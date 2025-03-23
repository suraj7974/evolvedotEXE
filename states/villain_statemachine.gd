extends Node

var states = {}  
var current_state  
var villain  

func _ready():
	villain = get_parent()  

	states["IdleState"] = get_node("villain_idlestate")  
	states["ChaseState"] = get_node("villain_chasestate")  
	states["AttackState"] = get_node("villain_attackstate")  
	states["DeadState"] = get_node("villain_deadstate")  # Changed to match what we'll use

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

# ✅ Add this function if other scripts call `update(delta)`
func update(delta):  
	if current_state and current_state.has_method("update"):
		current_state.update(delta)

func on_state_transition(new_state_name):
	print("🔄 Villain transitioning to:", new_state_name)
	print("🔄 Available states:", states.keys())
	
	if new_state_name in states:
		print("✅ Found state:", new_state_name)
		if current_state:
			current_state.exit()
		current_state = states[new_state_name]
		current_state.enter()
	else:
		print("❌ ERROR: Invalid state transition:", new_state_name)
		print("❌ Available states:", states.keys())
		
		# Check if DeadState exists but with a different case
		for state_name in states.keys():
			if state_name.to_lower() == new_state_name.to_lower():
				print("✅ Found state with different case:", state_name)
				if current_state:
					current_state.exit()
				current_state = states[state_name]
				current_state.enter()
				return
