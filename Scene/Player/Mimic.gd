extends CharacterBody2D


const SPEED = 150.0
@export var qte_range:float = 0.2

@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]
@onready var particles = $CPUParticles2D
@onready var stealthTimer:Timer = $StealthTimer
@onready var qteSlider = $CanvasLayer/Interface/qteSlider
@onready var valSlider = $CanvasLayer/Interface/valueSlider
@onready var qteTimer = $qteTimer
@onready var delayTimer = $delayTimer

var boostMeter:float = 1
var hungerMeter:float = 1
var is_hidden:bool = false
var qte = {
	"wantedTime": randf_range(0.1,0.9), ## Randomized every qte
	"success": false ## for use in the process
	}

func _ready():
	animationTree.active = true
	qte["wantedTime"] = randf_range(0.1,0.9)

func _process(delta):
	modulate = Color.CRIMSON if is_hidden else Color.WHITE
	
	process_qte()
	
	var input_vector = velocity.normalized()
	
	if input_vector != Vector2.ZERO :
		animationTree.set("parameters/Idle/blend_position",input_vector)
		animationTree.set("parameters/Move/blend_position",input_vector)
		particles.gravity = particles.gravity.rotated(particles.gravity.angle_to(-input_vector))
		is_hidden = false
		if animationState.get_current_node() != "Move" :
			animationState.travel("Move")
	elif animationState.get_current_node() != "Idle" :
		particles.emitting = false
		animationState.travel("Idle")
	else :
		if !is_hidden and stealthTimer.is_stopped():
			stealthTimer.start()
	#	$LureArea.monitorable = Input.is_action_pressed("lure")
		$LureArea.visible = Input.is_action_pressed("lure")


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


func process_hunger():
	
	pass


func process_qte():
	if (qte["wantedTime"] < qteTimer.time_left-qte_range or qte["wantedTime"] > qteTimer.time_left+qte_range) and \
		Input.is_action_just_pressed("qte") and \
		qteTimer.time_left <= qteTimer.wait_time:
		is_hidden = false
		qte["success"] = false
	elif (qte["wantedTime"] > qteTimer.time_left-qte_range and qte["wantedTime"] < qteTimer.time_left+qte_range) and \
		Input.is_action_just_pressed("qte") and \
		qteTimer.time_left <= qteTimer.wait_time:
		qteSlider.visible = false
		valSlider.visible = false
		qte["success"] = true
	
	if is_hidden and delayTimer.is_stopped() and qteTimer.is_stopped():
		delayTimer.start()
	elif !is_hidden :
		qteSlider.visible = false
		valSlider.visible = false
		qteTimer.stop()
		delayTimer.stop()
	
	qteSlider.value = qteTimer.time_left/qteTimer.wait_time*100


func damage():
	pass



func _on_stealth_timer_timeout():
	is_hidden = true


func _on_delay_timer_timeout():
	qteSlider.visible = true
	valSlider.visible = true
	qte["wantedTime"] = randf_range(0.1,qteTimer.wait_time-0.25)
	valSlider.value = qte["wantedTime"]*100
	qteTimer.start()

func _on_qte_timer_timeout():
	qteSlider.visible = false
	valSlider.visible = false
	is_hidden = qte["success"]
	delayTimer.start()
	qte["success"] = false
