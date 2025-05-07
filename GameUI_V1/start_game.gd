extends Control

func _ready() -> void:
	# Delete all files inside the screenshots directory
	var screenshots_dir := DirAccess.open("user://screenshots")
	if screenshots_dir:
		screenshots_dir.list_dir_begin()
		var file_name := screenshots_dir.get_next()
		while file_name != "":
			if not screenshots_dir.current_is_dir():
				screenshots_dir.remove(file_name)
			file_name = screenshots_dir.get_next()
		screenshots_dir.list_dir_end()

func _on_empty_game_1_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Map/new_map.tscn")


func _on_empty_game_2_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Map/new_map.tscn")


func _on_empty_game_3_pressed() -> void:
	
	get_tree().change_scene_to_file("res://level.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://GameUI_V1/MainMenu.tscn")
