extends Control

@onready var inv: Inv = preload("res://Inventory/playerInv.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
var is_open = false

func _ready():
	close()

func _process(delta):
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			load_items()
			update_slots()
			open()

func open():
	self.visible = true
	is_open = true

func close():
	self.visible = false
	is_open = false

func update_slots():
	for i in range(slots.size()):
		if i < inv.items.size():
			slots[i].update(inv.items[i])

func load_items():
	var folder = "user://screenshots/"
	var dir = DirAccess.open(folder)
	if dir == null:
		pass
	
	inv.items.clear()

	dir.list_dir_begin()
	while true:
		var item = dir.get_next()
		if item == "": # our screenshot
			break
		if item.ends_with(".png") and not dir.current_is_dir():
			var path = folder + "/" + item
			var image = Image.new() # screenshot image
			if image.load(path) == OK:
				var tex = ImageTexture.create_from_image(image)
				var photo = InvItem.new() # ingame item
				photo.name = item.get_file()
				photo.icon = tex
				inv.items.append(photo)
	dir.list_dir_end()
