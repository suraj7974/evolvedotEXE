extends CanvasLayer

signal move_left_start
signal move_left_stop
signal move_right_start
signal move_right_stop
signal jump_start
signal jump_stop
signal attack_start
signal attack_stop
signal attack2_start
signal attack2_stop

func _ready():
	print("🎮 Mobile controls ready - connecting buttons...")
	
	# Make buttons circular
	_make_button_circular($Control/LeftButton)
	_make_button_circular($Control/RightButton)
	_make_button_circular($Control/JumpButton)
	_make_button_circular($Control/AttackButton)
	_make_button_circular($Control/Attack2Button)
	
	# Connect all buttons to down/up signals for simultaneous pressing
	$Control/LeftButton.connect("button_down", Callable(self, "_on_left_down"))
	$Control/LeftButton.connect("button_up", Callable(self, "_on_left_up"))
	$Control/RightButton.connect("button_down", Callable(self, "_on_right_down"))
	$Control/RightButton.connect("button_up", Callable(self, "_on_right_up"))
	$Control/JumpButton.connect("button_down", Callable(self, "_on_jump_down"))
	$Control/JumpButton.connect("button_up", Callable(self, "_on_jump_up"))
	$Control/AttackButton.connect("button_down", Callable(self, "_on_attack_down"))
	$Control/AttackButton.connect("button_up", Callable(self, "_on_attack_up"))
	$Control/Attack2Button.connect("button_down", Callable(self, "_on_attack2_down"))
	$Control/Attack2Button.connect("button_up", Callable(self, "_on_attack2_up"))
	
	print("🎮 All mobile control buttons connected!")

func _make_button_circular(button: Button):
	# Create a circular style for the button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.3, 0.8)  # Dark blue-gray
	style_normal.corner_radius_top_left = 50
	style_normal.corner_radius_top_right = 50
	style_normal.corner_radius_bottom_left = 50
	style_normal.corner_radius_bottom_right = 50
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_color = Color(0.6, 0.6, 0.7, 1.0)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.4, 0.4, 0.5, 0.9)  # Lighter when pressed
	style_pressed.corner_radius_top_left = 50
	style_pressed.corner_radius_top_right = 50
	style_pressed.corner_radius_bottom_left = 50
	style_pressed.corner_radius_bottom_right = 50
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_color = Color(0.8, 0.8, 0.9, 1.0)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("hover", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

func _on_left_down():
	print("🎮 Left button DOWN!")
	emit_signal("move_left_start")

func _on_left_up():
	print("🎮 Left button UP!")
	emit_signal("move_left_stop")

func _on_right_down():
	print("🎮 Right button DOWN!")
	emit_signal("move_right_start")

func _on_right_up():
	print("🎮 Right button UP!")
	emit_signal("move_right_stop")

func _on_jump_down():
	print("🎮 Jump button DOWN!")
	emit_signal("jump_start")

func _on_jump_up():
	print("🎮 Jump button UP!")
	emit_signal("jump_stop")

func _on_attack_down():
	print("🎮 Attack button DOWN!")
	emit_signal("attack_start")

func _on_attack_up():
	print("🎮 Attack button UP!")
	emit_signal("attack_stop")

func _on_attack2_down():
	print("🎮 Attack2 button DOWN!")
	emit_signal("attack2_start")

func _on_attack2_up():
	print("🎮 Attack2 button UP!")
	emit_signal("attack2_stop")
