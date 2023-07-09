extends Node

const TUTLVL1 = preload("res://Scene/Shipping Levels/Tutorial Level 1.tscn")
const TUTLVL2 = preload("res://Scene/Shipping Levels/Tutorial Level 2.tscn")

var curr_level: Node2D = null

var state = "menu"


func _ready():
	process_state_change("menu")


func _process(delta):
	pass


func process_state_change(new_state):
	state = new_state
	for music in $Music.get_children():
		if music.playing:
			music.stop()

	$Menu.hide()

	if state == "menu":
		$Music/IntroMusic.play()
		$Menu.show()
	elif state == "game":
		$Music/GameplayMusic.play()
	elif state == "win":
		$Music/WinMusic.play()


func handle_win():
	if curr_level.name == "Tutorial Level 1":
		swap_level(TUTLVL2)
		print(curr_level.name)
	if curr_level.name == "pass":
		pass


func swap_level(new_level):
	remove_child(curr_level)
	curr_level.queue_free()
	curr_level = new_level.instantiate()
	add_child(curr_level)
	curr_level.win.connect(handle_win)



func _on_start_pressed():
	curr_level = TUTLVL1.instantiate()
	add_child(curr_level)
	process_state_change("game")
	curr_level.win.connect(handle_win)


func _on_quit_pressed():
	get_tree().quit()
