extends Button


export var reference_path = ""
export(bool) var start_focused = false


# Called when the node enters the scene tree for the first time.
func _ready():
	if(start_focused):
		grab_focus()



func _on_Menu_Button_pressed():
	if(reference_path != ""):
		get_tree().change_scene(reference_path)
	else:
		get_tree().quit()


func _on_Menu_Button_mouse_entered():
	grab_focus()
