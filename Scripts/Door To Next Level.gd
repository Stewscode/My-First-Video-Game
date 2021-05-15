extends Sprite

onready var target = get_node("/root/MainScene/Player")

func _on_Door_body_entered(body):
	if body == target:
		print(filename)
		print(get_tree().current_scene.filename)
		get_tree().change_scene("res://Scenes/Levels/Level " + str(int(get_tree().current_scene.filename) + 1) + ".tscn")
		#get_tree().change_scene("res://Scenes/Levels/Level 2.tscn")
