extends CharacterBody2D


const SPEED = 150.0

@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]

var boostMeter:float = 1

func _ready():
	animationTree.active = true

func _process(delta):
	$LureArea.monitorable = Input.is_action_pressed("lure")
	$LureArea.visible = Input.is_action_pressed("lure")
	
	var input_vector = velocity.normalized()
	if input_vector != Vector2.ZERO :
		animationTree.set("parameters/Idle/blend_position",input_vector)
		animationTree.set("parameters/Move/blend_position",input_vector)
		if animationState.get_current_node() != "Move" :
			animationState.travel("Move")
	elif animationState.get_current_node() != "Idle" :
		animationState.travel("Idle")

func _physics_process(delta):
	var input_vector = Input.get_vector("game_left", "game_right","game_up", "game_down")
	
	if Input.is_action_pressed("boost") :
		if boostMeter > 0.0 :
			input_vector *= 1.5
			boostMeter -= delta
	elif boostMeter < 1 :
			boostMeter += delta  
	else:
		boostMeter = 1

	if input_vector != Vector2.ZERO:
		velocity = input_vector * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()
