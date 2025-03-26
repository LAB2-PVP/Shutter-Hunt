class_name SprintingPlayerState

extends State


# Called when the node enters the scene tree for the first time.
func enter() -> void:
	GlobalScene.player._speed = GlobalScene.player.speed_sprint

func _input(event):
	if event.is_action_released("sprint") and GlobalScene.player.is_on_floor():
		transition.emit("WalkingPlayerState")
