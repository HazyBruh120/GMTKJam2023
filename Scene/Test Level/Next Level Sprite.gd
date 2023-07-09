extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#	if area.is_in_group("Mimic"):
#		get_tree().change_Scene("Tesrt Level");


func _on_area_2d_body_entered(body):
	if body.is_in_group("Mimic"):
		#print("res://Scene/Test Level/Tesrt Level.tscn")
		get_tree().change_scene("res://Scene/Test Level/Tesrt Level.tscn")
		
