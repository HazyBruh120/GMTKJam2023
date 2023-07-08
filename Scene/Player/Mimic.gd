extends CharacterBody2D


const SPEED = 300.0

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]
var boostMeter:float = 1

func _ready():
	animationTree.active = true
	pass

func _process(delta):
	$LureArea.monitorable = Input.is_action_pressed("lure")
	$LureArea.visible = Input.is_action_pressed("lure")
	var input_vector = velocity.normalized()
	animationTree.set("parameters/Idle/blend_position",input_vector)
	animationTree.set("parameters/Move/blend_position",input_vector)
	if input_vector != Vector2.ZERO:
		animationState.travel("Move")
	else:
		animationState.travel("Idle")

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_vector = Vector2(Input.get_axis("game_left", "game_right"),Input.get_axis("game_up", "game_down")).normalized()
	if Input.is_action_pressed("boost") and boostMeter > 0.0 :
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
