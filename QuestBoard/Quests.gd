extends CanvasLayer

var quests = []
var quests_assigned = false

@onready var panel_list = [
	$Panel2,
	$Panel3,
	$Panel4
]

func _ready():
	self.hide()
	load_quests()
	assign_quests_to_panels()
	connect_accept_buttons()

func load_quests():
	var file_path = "res://QuestBoard/quests.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		quests = JSON.parse_string(file.get_as_text())
	else:
		push_error("Could not load quest file at " + file_path)

func showQuests():
	self.visible = true

func hideQuests():
	self.visible = false

func assign_quests_to_panels():
	if quests_assigned:
		return

	var available = quests.duplicate()
	available.shuffle()
	
	for i in range(panel_list.size()):
		if i >= available.size():
			break

		var quest = available[i]
		var panel = panel_list[i]

		panel.get_node("TitleLabel").text = quest["title"]

	quests_assigned = true

func connect_accept_buttons():
	for panel in panel_list:
		var accept_btn = panel.get_node("AcceptButton")
		accept_btn.connect("pressed", Callable(self, "_on_accept_pressed").bind(panel))

func _on_accept_pressed(panel):
	var title = panel.get_node("TitleLabel").text
	for quest in quests:
		if quest["title"] == title:
			print("Accepted quest: %s" % title)
			panel.get_node("AcceptButton").disabled = true
			break
