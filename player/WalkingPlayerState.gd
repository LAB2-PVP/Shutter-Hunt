class_name WalkingPlayerState

extends State

@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func enter() -> void:
	GlobalScene.player._speed = GlobalScene.player.speed_default
	audio_stream_player.play()

func update(delta):
	if GlobalScene.player.velocity.length() == 0.0:
		audio_stream_player.stop()
		transition.emit("IdlePlayerState")

func _input(event):
	if event.is_action_pressed("sprint") and GlobalScene.player.is_on_floor():
		transition.emit("SprintingPlayerState")
