extends CollisionObject3D
class_name Interactable

@export var title_message = "Interact"
@export var action_message = "Interact"

func interact(body):
	print(body.name, "interacted with ", name)
