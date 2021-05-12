extends Area2D


onready var box = get_node("root/MainScene/Pushable Box")


func _on_Trigger_for_a_box_body_entered(body):
	if body.name == "Pushable Box":
		get_tree().queue_delete(self)
		print("Box collided with trigger")
