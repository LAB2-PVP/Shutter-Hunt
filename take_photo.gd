extends Control

var is_open = false


func _ready():
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
		take_screenshot()
		

func open():
	self.visible = true
	is_open = true

func close():
	visible = false
	is_open = false

func take_screenshot():
	await RenderingServer.frame_post_draw
	var timestamp = Time.get_datetime_string_from_system (false, true).replace(":", "-")
	var sshot = get_viewport().get_texture().get_image()
	sshot.save_png("user://screenshots/ss_" + timestamp + ".png")
