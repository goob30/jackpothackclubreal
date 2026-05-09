extends Control


@onready var normal_button: Button = $ButtonContainer/NormalButton
@onready var baby_button: Button = $ButtonContainer/BabyButton


func _ready():
	normal_button.pressed.connect(_on_normal_pressed)
	baby_button.pressed.connect(_on_baby_pressed)
	
	InputManager.button_2_left_pressed.connect(_on_normal_pressed)
	InputManager.button_2_right_pressed.connect(_on_baby_pressed)


func _on_normal_pressed():
	GameManager.start_new_run(GameManager.MODE_NORMAL)
	GameManager.debug_print_state()


func _on_baby_pressed():
	GameManager.start_new_run(GameManager.MODE_BABY)
	GameManager.debug_print_state()
