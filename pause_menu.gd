extends Control

@onready var settings: Control = $Settings
@onready var back_button: TextureButton = $Settings/BackButton

var is_paused: = false

func _ready():
	close()

func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		if is_paused:
			close()
		else:
			open()
			
func open():
	self.visible = true
	is_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func close():
	visible = false
	is_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
	

func _on_resume_pressed() -> void:
	close()

func _on_settings_pressed() -> void:
	
	settings.visible = true
	back_button.visible = true
	
func _on_quit_game_pressed() -> void:
	get_tree().change_scene_to_file("res://GameUI_V1/MainMenu.tscn")

func _on_back_button_pressed() -> void:
	settings.visible = false
	back_button.visible = false
