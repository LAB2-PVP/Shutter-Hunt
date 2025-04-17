class_name WalkingPlayerState

extends State

func enter() -> void:
	GlobalScene.player._speed = GlobalScene.player.speed_default

func update(delta):
	if GlobalScene.player.velocity.length() == 0.0:
		transition.emit("IdlePlayerState")

func _input(event):
	if event.is_action_pressed("sprint") and GlobalScene.player.is_on_floor():
		transition.emit("SprintingPlayerState")
