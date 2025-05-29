extends RayCast3D

@onready var prompt = $Prompt
@onready var prompt2 = $Prompt2
@onready var hand = $"../Camera3D/hand"
@onready var photoCamera = preload("res://interaction/camera.tscn")
@onready var heldCamera = preload("res://interaction/camera_hd.tscn")

@onready var development: Control = $"../../UI/Ryskinimas"

var is_quest_open = false
var is_development_open = false

var cameraToDrop
var cameraToSpawn

signal camera_updated(new_camera)

func _ready():
	development.visible = false

func _physics_process(_delta):
	
	
	prompt.text = ""
	prompt2.text = ""
	
	if is_colliding():
		
		var collider = get_collider()
		
		
		if collider is Interactable and collider.name == "Camera":
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
					GlobalScene.player.hasCamera = true
		
		elif collider is Interactable and collider.name == "Ryskinimas":
			prompt.text = collider.title_message
			prompt2.text = collider.action_message
			
			if Input.is_action_just_pressed("interact") and not is_development_open:
				
				development.visible = true
				GlobalScene.development_open = true
				is_development_open = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
			elif Input.is_action_just_pressed("interact") and is_development_open:
				
				development.visible = false
				GlobalScene.development_open = false
				is_development_open = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		elif collider is Interactable and collider.name == "QuestBoard":
			var quest_board_ui = get_tree().get_current_scene().get_node("QuestMenu")
			prompt.text = collider.title_message
			prompt2.text = collider.action_message
				
			if Input.is_action_just_pressed("interact") and not is_quest_open:
				GlobalScene.quest_open = true
				quest_board_ui.visible = true
				quest_board_ui.call("showQuests")
				is_quest_open = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

			elif Input.is_action_just_pressed("interact") and is_quest_open:
				GlobalScene.quest_open = false
				quest_board_ui.visible = false
				quest_board_ui.call("hideQuests")
				is_quest_open = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
