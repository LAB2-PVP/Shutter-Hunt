extends CanvasLayer

var quests = []

@onready var panel_list = [
	$Panel2,
	$Panel3,
	$Panel4
]

func _ready():
	self.hide()
	load_quests()

func load_quests():
	var file_path = "res://QuestBoard/quests.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		quests = JSON.parse_string(file.get_as_text())
	else:
		push_error("Could not load quest file at " + file_path)

func showQuests():
	super.show()
	assign_quests_to_panels()

func assign_quests_to_panels():
	var available = quests.duplicate()
	available.shuffle()
	
	for i in range(panel_list.size()):
		if i >= available.size():
			break

		var quest = available[i]
		var panel = panel_list[i]

		panel.get_node("TitleLabel").text = quest["title"]
