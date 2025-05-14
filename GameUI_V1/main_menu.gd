extends Control

@onready var settings: Control = $Settings
@onready var back_button: TextureButton = $BackButton

func _on_start_game_pressed() -> void:
	
	get_tree().change_scene_to_file("res://GameUI_V1/StartGame.tscn")


func _on_settings_pressed() -> void:
	
	settings.visible = true
	back_button.visible = true

func _on_quit_game_pressed() -> void:
	
	get_tree().quit()


func _on_back_button_pressed() -> void:
	settings.visible = false
	back_button.visible = false
	
