extends Node

@export var quiz: QuizTheme
@export var color_right: Color
@export var color_wrong: Color

var buttons: Array[Button]
var index: int
var correct: int 

var current_quiz: QuizQuestion:
	get: return quiz.theme[index]

@onready var question_text: Label = $Content/QuestionInfo/QuestionText

func _ready() -> void:
	correct = 0
	for button in $Content/QuestionHolder.get_children():
		buttons.append(button)
		
	load_quiz()
	
func load_quiz() -> void:
	
	if index >= quiz.theme.size():
		_game_over()
		return 
	
	question_text.text = quiz.theme[index].question_info
	
	var options = quiz.theme[index].options
	for i in buttons.size():
		buttons[i].text = options[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		
func _buttons_answer(button) -> void:
	if quiz.theme[index].correct == button.text:
		button.modulate = color_right
		correct += 1
		$AudioCorrect.play()
	else:
		button.modulate = color_wrong
		$AudioIncorrect.play()

	_next_question()
	
func _next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
		
	await get_tree().create_timer(0.5).timeout
	
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	index += 1
	load_quiz()

func _game_over() -> void:
	$Content/GameOver.show()
	$Content/GameOver/Score.text = str(correct, "/" ,quiz.theme.size())
	print("All questions are over")

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
