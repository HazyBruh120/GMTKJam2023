extends CharacterBody2D


const SPEED = 150.0

@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]
@onready var particles = $CPUParticles2D
@onready var stealthTimer:Timer = $StealthTimer
@onready var qteSlider = $qteSlider
@onready var valSlider = $valueSlider
@onready var qteTimer = $qteTimer
@onready var delayTimer = $delayTimer

var boostMeter:float = 1
var hungerMeter:float = 1
var is_hidden:bool = false
var qte = {
	"timer": Timer.new(),
	"delayTimer": Timer.new(),
	"window": 1.0,
	"delay": 2.0,
	"range": 0.2,
	"wantedTime": randf_range(0.1,0.9), ## Randomized every qte
	"success": false ## for use in the process
	} : set = _set_qte

func _ready():
	animationTree.active = true
	qte["timer"].wait_time = qte["window"]
	qte["timer"].wait_time = qte["delay"]
	add_child(qte["timer"])
	add_child(qte["delayTimer"])

func _process(delta):
	
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


func _set_qte(new_qte):
	qte["timer"].wait_time = new_qte["window"] + new_qte["delay"]
	qte["window"] = new_qte["window"]
	qte["delay"] = new_qte["delay"]


func set_quickTime_event(window:float,delay:float):
	qte["timer"].wait_time = window + delay
	qte["window"] = window
	qte["delay"] = delay
	
func process_qte():
	if (qte["wantedTime"] < qte["timer"].time_left-qte["range"] or qte["wantedTime"] > qte["timer"].time_left+qte["range"]) and \
		Input.is_action_pressed("qte") and \
		qte["timer"].time_left <= qte["window"]:
		is_hidden = false
		qte["success"] = false
	elif (qte["wantedTime"] > qte["timer"].time_left-qte["range"] and qte["wantedTime"] < qte["timer"].time_left+qte["range"]) and \
		Input.is_action_pressed("qte") and \
		qte["timer"].time_left <= qte["window"]:
		qte["success"] = true
	
	if is_hidden and qte["timer"].is_stopped() :
		qteSlider.visible = true
		valSlider.visible = true
		qte["timer"].start()
	elif !is_hidden :
		qteSlider.visible = false
		valSlider.visible = false
		qte["timer"].stop()
	elif qte["timer"].time_left <= 0.1 :
		qte["wantedTime"] = randf_range(0.1,qte["window"]-0.1)
		valSlider.value = qte["wantedTime"]*100
		is_hidden = qte["success"]
	
	qteSlider.value = qte["timer"].time_left*100


func _on_stealth_timer_timeout():
	is_hidden = true


func _on_delay_timer_timeout():
	qte["success"] = false


func _on_qte_timer_timeout():
	pass # Replace with function body.
