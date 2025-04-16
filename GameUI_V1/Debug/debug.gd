extends PanelContainer

@onready var property_container = $MarginContainer/VBoxContainer

var frames_per_second : String

func _ready():
	visible = false
	GlobalScene.debug = self
	
	
	
func _input(event):
	if event.is_action_pressed("debug"):
		visible = !visible

func _process(delta):
	frames_per_second = "%.2f" % (1.0/delta)
	GlobalScene.debug.add_property("FPS", frames_per_second, 0)

func add_property(title: String, value, order):
	var target
	target = property_container.find_child(title, true, false) # Try to find Label node with same name
	if !target: # If there is no current Label node for property (i.e. initial load)
		target = Label.new() # Create new Label node
		property_container.add_child(target) # Add new node as child to VBox container
		target.name = title # Set name to title
		target.text = target.name + ": " + str(value) # Set text value
	elif visible:
		target.text = title + ": " + str(value) # Update text value
	property_container.move_child(target, order) # Reorder property based on given order value

#func add_debug_property(title: String, value):
#	property = Label.new()
#	property_container.add_child(property)
#	property.name = title
#	property.text = property.name + value
	
