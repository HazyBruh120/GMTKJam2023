extends CharacterBody2D


const SPEED = 150.0

@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]
@onready var particles = $CPUParticles2D
@onready var timer:Timer = $StealthTimer

var boostMeter:float = 1

func _ready():
	animationTree.active = true

func _process(delta):
	if animationState.get_current_node() == "Idle" :
	#	Stealth mechanic for

	#	$LureArea.monitorable = Input.is_action_pressed("lure")
		$LureArea.visible = Input.is_action_pressed("lure")

	var input_vector = velocity.normalized()
	if input_vector != Vector2.ZERO :
		animationTree.set("parameters/Idle/blend_position",input_vector)
		animationTree.set("parameters/Move/blend_position",input_vector)
		particles.gravity = particles.gravity.rotated(particles.gravity.angle_to(-input_vector))
		if animationState.get_current_node() != "Move" :
			animationState.travel("Move")
	elif animationState.get_current_node() != "Idle" :
		particles.emitting = false
		animationState.travel("Idle")

func _physics_process(delta):
	var input_vector = Input.get_vector("game_left", "game_right","game_up", "game_down")
	if Input.is_action_pressed("boost") :
		if boostMeter > 0.0 :
			input_vector *= 1.5
			boostMeter -= delta
			particles.emitting = true
	elif boostMeter < 1 :
			boostMeter += delta
	else:
		boostMeter = 1

	if input_vector != Vector2.ZERO:
		velocity = input_vector * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
