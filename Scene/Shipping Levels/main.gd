extends Node

const TUTLVL2 = preload("res://Scene/Shipping Levels/Tutorial Level 2.tscn")
const GLVL1 = preload("res://Scene/Shipping Levels/Game Level 1.tscn")

const LVL_ORDERING_DICT = {
	"Tutorial Level 1": {
		"pack": preload("res://Scene/Shipping Levels/Tutorial Level 1.tscn"),
		"next": "Tutorial Level 2"
	},
	"Tutorial Level 2": {
		"pack": preload("res://Scene/Shipping Levels/Tutorial Level 2.tscn"),
		"next": "Game Level 1"
	}

}

var curr_level: Node2D = null
var last_level_name = ""

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
	elif state == "lose":
		$Music/LoseMusic.play()


func handle_win(state):
	if state:
		$NextLevel.show()
		process_state_change("win")
	else:
		$RestartLevel.show()
		process_state_change("lose")

	unload_level()


func unload_level():
	last_level_name = curr_level.name
	remove_child(curr_level)
	curr_level.queue_free()

func next_level():
	var next_level_name = LVL_ORDERING_DICT[last_level_name]["next"]

	curr_level = LVL_ORDERING_DICT[next_level_name]["pack"].instantiate()
	add_child(curr_level)
	curr_level.win.connect(handle_win)


func restart_level():
	curr_level = LVL_ORDERING_DICT[last_level_name]["pack"].instantiate()
	add_child(curr_level)
	curr_level.win.connect(handle_win)



func _on_start_pressed():
	curr_level = LVL_ORDERING_DICT["Tutorial Level 1"]["pack"].instantiate()
	add_child(curr_level)
	process_state_change("game")
	curr_level.win.connect(handle_win)


func _on_quit_pressed():
	get_tree().quit()


func _on_next_pressed():
	$NextLevel.hide()
	process_state_change("game")
	next_level()


func _on_restart_pressed():
	$RestartLevel.hide()
	process_state_change("game")
	restart_level()
