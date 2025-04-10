extends Node

var AIController
var walk: bool = true

# Roaming behavior variables
var roam_timer := 0.0
var roam_interval := 2.0 # seconds between direction changes

# Walk/Idle switch variables
var switch_timer := 0.0
var switch_interval := 4.0 # seconds to switch between walk and idle

func _ready() -> void:
	AIController = get_parent().get_parent()
	if AIController.Awakening:
		await AIController.get_node("AnimationTree").animation_finished
	else:
		walk = false
		AIController.get_node("AnimationTree").get("parameters/playback").travel("Awaken")
		AIController.Awakening = true
		await AIController.get_node("AnimationTree").animation_finished

	walk = true
	switch_timer = switch_interval
	AIController.Awakening = false
	AIController.get_node("AnimationTree").get("parameters/playback").travel("Walk")

func _physics_process(delta: float) -> void:
	if not AIController:
		return

	switch_timer -= delta
	if switch_timer <= 0:
		# Toggle walk/idle
		walk = !walk
		switch_timer = switch_interval

		if walk:
			AIController.get_node("AnimationTree").get("parameters/playback").travel("Walk")
		else:
			AIController.get_node("AnimationTree").get("parameters/playback").travel("Idle")
			AIController.velocity = Vector3.ZERO

	if walk:
		# Handle direction change every roam_interval
		roam_timer -= delta
		if roam_timer <= 0:
			roam_timer = roam_interval
			var angle = randf() * TAU
			AIController.direction = Vector3(cos(angle), 0, sin(angle)).normalized()

		# Apply movement
		AIController.velocity.x = AIController.direction.x * AIController.speed
		AIController.velocity.z = AIController.direction.z * AIController.speed
		AIController.look_at(AIController.global_transform.origin + AIController.direction, Vector3.UP)
