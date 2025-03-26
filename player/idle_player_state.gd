class_name IdlePlayerState

extends State

func update(delta):
	if GlobalScene.player.velocity.length() > 0.0:
		transition.emit("WalkingPlayerState")
