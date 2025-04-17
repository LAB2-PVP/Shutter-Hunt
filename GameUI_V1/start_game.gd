extends Control



func _on_empty_game_1_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Map/new_map.tscn")


func _on_empty_game_2_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Map/new_map.tscn")


func _on_empty_game_3_pressed() -> void:
	
	get_tree().change_scene_to_file("res://level.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://GameUI_V1/MainMenu.tscn")
