extends Control

func _ready():
	# Automatically load the main game without showing selection screen
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

# The original button handlers are kept for reference or future use
func _on_evolvedotexe_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	

func _on_python_quiz_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/pymainmenu.tscn")
