extends Node2D

signal win(state)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Mimic.die.connect(on_mimic_die)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $Mobs.get_child_count() == 0:
		win.emit(true)


func on_mimic_die():
	win.emit(false)



