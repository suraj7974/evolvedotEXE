extends Resource
class_name QuizQuestion

@export var question_info: String 
@export var type: Enum.QuestionType
@export var question_image: Texture2D
@export var question_audio: AudioStream
@export var question_video: VideoStream
@export var options: Array[String]
@export var correct: String
@export var difficulty: int = 1  # 1 = Easy, 2 = Medium, 3 = Hard , 4= hardest
 
