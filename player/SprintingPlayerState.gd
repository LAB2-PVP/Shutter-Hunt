class_name SprintingPlayerState

extends State

func enter() -> void:
	GlobalScene.player._speed = GlobalScene.player.speed_sprint

func _input(event):
	if event.is_action_released("sprint") and GlobalScene.player.is_on_floor():
		transition.emit("WalkingPlayerState")
