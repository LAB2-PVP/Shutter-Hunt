extends Control

@onready var blink = $TextureRect/AnimationPlayer/ColorRect
@onready var overlay = $TextureRect

var is_open = false

func _ready():
	blink.visible = false
	close()
	var dir = DirAccess.open("user://")
	dir.make_dir("screenshots")
	
func _process(delta):
	if Input.is_action_just_pressed("open_camera_window"):
		if is_open:
			close()
		else:
			open()
		
	if Input.is_action_just_pressed("Take_photo") and is_open:
		blink.visible = true
		$TextureRect/AnimationPlayer.play("take_photo")
		await $TextureRect/AnimationPlayer.animation_finished
		blink.visible = false
		take_photo()
		
func open():
	self.visible = true
	is_open = true

func close():
	visible = false
	is_open = false

func take_photo():
	overlay.visible = false
	await RenderingServer.frame_post_draw
	var timestamp = Time.get_datetime_string_from_system (false, true).replace(":", "-")
	var sshot = get_viewport().get_texture().get_image()
	sshot.save_png("user://screenshots/ss_" + timestamp + ".png")
	overlay.visible = true
