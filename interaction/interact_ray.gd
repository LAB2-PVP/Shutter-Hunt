extends RayCast3D

@onready var prompt = $Prompt
@onready var prompt2 = $Prompt2
@onready var hand = $"../Camera3D/hand"
@onready var photoCamera = preload("res://interaction/camera.tscn")
@onready var heldCamera = preload("res://interaction/camera_hd.tscn")

var cameraToDrop
var cameraToSpawn

signal camera_updated(new_camera)

func _physics_process(_delta):
	
	prompt.text = ""
	prompt2.text = ""
	
	if is_colliding():
		
		var collider = get_collider()
		
		if collider is Interactable:
			prompt.text = collider.title_message
			prompt2.text = collider.action_message
			
			cameraToSpawn = heldCamera.instantiate()
			
			if hand.get_child(0) != null:
				cameraToDrop = photoCamera.instantiate()
			
			if Input.is_action_just_pressed("interact"):
				if cameraToSpawn != null:
					if hand.get_child(0) != null:
						get_parent().add_child(cameraToDrop)
						cameraToDrop.global_transform = hand.global_transform
						cameraToDrop = true
						hand.get_child(0).queue_free()
					get_collider().queue_free()
					hand.add_child(cameraToSpawn)
					cameraToSpawn.rotation = hand.rotation
					emit_signal("camera_updated", cameraToSpawn)
					
