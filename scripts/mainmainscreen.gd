extends Control


func _on_evolvedotexe_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	


func _on_python_quiz_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/pymainmenu.tscn")
