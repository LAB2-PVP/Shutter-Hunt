extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display

func update(item):
	if !item:
		item_visual.visible = false
	else:
		item_visual.visible = true
		var texture = null

		if item.has_method("get_texture"):
			texture = item.get_texture()
		elif "texture" in item:
			texture = item.texture
		elif "icon" in item:
			texture = item.icon

		item_visual.texture = texture
