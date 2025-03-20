extends Control

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
	

func _on_resume_pressed() -> void:
	visible = false
	is_paused = false


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://GameUI_V1/pause_settings.tscn")
	

func _on_quit_game_pressed() -> void:
	get_tree().change_scene_to_file("res://GameUI_V1/MainMenu.tscn")
