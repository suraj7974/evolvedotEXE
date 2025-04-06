extends Node

class_name AttackPatternLearner

# Constants for learning parameters
const LEARNING_RATE = 0.6  # How quickly the villain learns
const PATTERN_MEMORY = 2   # Number of recent attacks to remember
const ADAPTATION_THRESHOLD = 0.7  # Threshold for attack pattern recognition
const MAX_RESISTANCE = 0.9  # Maximum resistance to repetitive attacks

# Track player attack patterns
var recent_attacks = []
var attack_counters = {}
var attack_resistances = {}

func _init():
	# Initialize attack resistances to zero (no resistance)
	attack_resistances["attack1"] = 0.0
	attack_resistances["attack2"] = 0.0
	
	# Initialize counters for tracking attack frequency
	attack_counters["attack1"] = 0
	attack_counters["attack2"] = 0

# Register a new attack from the player
func register_attack(attack_type: String) -> void:
	print("🧠 Learning: Registering attack type: " + attack_type)
	
	# Add this attack to recent attacks
	recent_attacks.append(attack_type)
	
	# Keep only the most recent attacks
	if recent_attacks.size() > PATTERN_MEMORY:
		recent_attacks.pop_front()
	
	# Update attack counter
	if attack_type in attack_counters:
		attack_counters[attack_type] += 1
	else:
		attack_counters[attack_type] = 1
	
	# Calculate how repetitive this attack is in the recent attacks
	var repetition_factor = calculate_repetition_factor(attack_type)
	
	# Update resistance for this attack type based on repetition
	update_resistance(attack_type, repetition_factor)
	
	# Decay resistances for attacks not used recently
	decay_other_resistances(attack_type)
	
	# Debug output
	print("🧠 Recent attacks: ", recent_attacks)
	print("🧠 Attack resistances: ", attack_resistances)

# Calculate how repetitive an attack is in recent memory
func calculate_repetition_factor(attack_type: String) -> float:
	if recent_attacks.size() == 0:
		return 0.0
	
	var count = 0
	for attack in recent_attacks:
		if attack == attack_type:
			count += 1
	
	return float(count) / recent_attacks.size()

# Update the resistance value for an attack type
func update_resistance(attack_type: String, repetition_factor: float) -> void:
	if not attack_type in attack_resistances:
		attack_resistances[attack_type] = 0.0
	
	# If the attack is being repeated frequently, increase resistance
	if repetition_factor > ADAPTATION_THRESHOLD:
		attack_resistances[attack_type] += LEARNING_RATE * repetition_factor
		
		# Cap resistance at maximum value
		attack_resistances[attack_type] = min(attack_resistances[attack_type], MAX_RESISTANCE)
		
		print("⚠️ Villain developing resistance to " + attack_type + 
			": " + str(int(attack_resistances[attack_type] * 100)) + "%")

# Decay resistances for attacks not used recently
func decay_other_resistances(current_attack: String) -> void:
	for attack_type in attack_resistances.keys():
		if attack_type != current_attack:
			attack_resistances[attack_type] = max(0.0, attack_resistances[attack_type] - LEARNING_RATE * 0.5)

# Get the damage reduction factor for an attack
func get_resistance(attack_type: String) -> float:
	if attack_type in attack_resistances:
		return attack_resistances[attack_type]
	return 0.0

# Reset all learning - used when villain respawns
func reset_learning() -> void:
	recent_attacks.clear()
	
	for attack_type in attack_resistances.keys():
		attack_resistances[attack_type] = 0.0
	
	print("🧠 Villain's attack pattern memory reset")