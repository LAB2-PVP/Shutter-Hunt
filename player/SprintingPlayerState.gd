class_name SprintingPlayerState

extends State

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func enter() -> void:
	GlobalScene.player._speed = GlobalScene.player.speed_sprint
	audio_stream_player_3d.play()
	
func _input(event):
	if event.is_action_released("sprint") and GlobalScene.player.is_on_floor():
		audio_stream_player_3d.stop()
		transition.emit("WalkingPlayerState")
