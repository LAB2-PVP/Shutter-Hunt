extends PanelContainer

@onready var property_container = $MarginContainer/VBoxContainer

var property
var frames_per_second : String

func _ready():
	visible = false
	
	add_debug_property("test", "test")
	
func _input(event):
	if event.is_action_pressed("debug"):
		visible = !visible

func add_debug_property(title: String, value):
	property = Label.new()
	property_container.add_child(property)
	property.name = title
	property.text = property.name + value
	
func _process(delta):
	frames_per_second = "%.2f" % (1.0/delta)
	property.text = property.name + ": " + frames_per_second
