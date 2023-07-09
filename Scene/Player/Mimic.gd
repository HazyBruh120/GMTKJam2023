extends CharacterBody2D


const SPEED = 150.0
@export var qte_range:float = 0.2
@export var depletion_speed:float = 0.5
@export var regen:float = 0.1

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree["parameters/playback"]
@onready var particles = $CPUParticles2D
@onready var stealthTimer:Timer = $StealthTimer
@onready var qteSlider = $CanvasLayer/UI/qteSlider
@onready var valSlider = $CanvasLayer/UI/valueSlider
@onready var HungerBar = $CanvasLayer/UI/HungerBar
@onready var prompt = $CanvasLayer/UI/prompt
@onready var qteTimer = $qteTimer
@onready var delayTimer = $delayTimer
@onready var PlayerSFX = $SFXPlayer

var boostMeter:float = 1
var hungerMeter:float = 1
var is_hidden:bool = false
var to_bite = null
var biting = false

var qte = {
	"wantedTime": randf_range(0.1,0.9), ## Randomized every qte
	"done": false, ## for use in the process
	"success": false ## for use in the process
	}

func _ready():
	animationTree.active = true
	qte["wantedTime"] = randf_range(0.1,0.9)

func _process(delta):
	$Sprite2D.modulate = Color.DIM_GRAY if is_hidden else Color.WHITE
	process_hunger(depletion_speed/10*delta)
	if animationState.get_current_node() != "Hit" :
		if !biting_check() :
			process_qte()
		else :
			abort_qte()
			bite()
		var input_vector = velocity.normalized()
		
		if input_vector != Vector2.ZERO :
			animationTree.set("parameters/Idle/blend_position",input_vector)
			animationTree.set("parameters/Move/blend_position",input_vector)
			animationTree.set("parameters/Bite/blend_position",input_vector)
			animationTree.set("parameters/FailQTE/blend_position",input_vector)
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


func _physics_process(delta):
	var input_vector = Input.get_vector("game_left", "game_right","game_up", "game_down")
	if Input.is_action_pressed("boost") and input_vector != Vector2.ZERO:
		if boostMeter > 0.0 :
			process_hunger(depletion_speed/10*delta)
			input_vector *= 1.5
			boostMeter -= delta
			particles.emitting = true
		else :
			particles.emitting = false
	elif boostMeter < 1 :
		boostMeter += delta
		particles.emitting = false
	else:
		boostMeter = 1
		particles.emitting = false

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * SPEED,SPEED)
		$Sprite2D.flip_h = input_vector.x < 0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()


func on_hit(dmg:float=0.2):
	hungerMeter = clamp(hungerMeter-dmg,0,1) if !biting else clamp(hungerMeter-dmg,0,1)
	animationState.travel("Hit")


func biting_check()->bool:
	if to_bite == null or !$EatArea.get_overlapping_bodies().has(to_bite) :
		to_bite = null
	else:
		return true
	
	for node in $EatArea.get_overlapping_bodies():
		if node.is_in_group("hero") and node.is_biteable() and to_bite == null and is_hidden:
			to_bite = node
			return true
	
	return false


func push(vector:Vector2):
	velocity = vector


func bite():
	prompt.visible = true
	#animationState.get_current_node() != "Bite" and \
	if  \
		Input.is_action_pressed("qte") and \
		to_bite != null:
		if animationState.get_current_node() != "Bite" :
			animationState.travel("Bite")
		to_bite.bit()
		hungerMeter = clamp(hungerMeter+regen,0,1)
		biting = true


func process_hunger(delta:float=0.2):
	hungerMeter = clamp(hungerMeter-delta,0,1)
	HungerBar.value = remap(hungerMeter,0,1,30,100)


func process_qte():
	if !qte["done"]:
		if (qte["wantedTime"] > qteTimer.time_left-qte_range and qte["wantedTime"] < qteTimer.time_left+qte_range) and \
			Input.is_action_just_pressed("qte") and \
			qteTimer.time_left <= qteTimer.wait_time:
			qteSlider.visible = false
			valSlider.visible = false
			prompt.visible = false
			qte["success"] = true
			qte["done"] = true
			PlayerSFX.seek(0)
			$SuccessSound.play()
			#play_sound("res://Scene/Player/Assets/SuccessSound.tres")
		elif  Input.is_action_just_pressed("qte") and \
			qteTimer.time_left <= qteTimer.wait_time:
			is_hidden = false
			qte["success"] = false
			qte["done"] = true
			PlayerSFX.seek(0)
			$FailSound.play()
			animationState.travel("FailQTE")
			#play_sound("res://Scene/Player/Assets/FailSound.tres")
	
	if is_hidden and delayTimer.is_stopped() and qteTimer.is_stopped():
		delayTimer.start()
	elif !is_hidden :
		abort_qte()

	qteSlider.value = qteTimer.time_left/qteTimer.wait_time*100


#func play_sound(file):
#	PlayerSFX.stream = null
#	PlayerSFX.stream = load(file)
#	PlayerSFX.seek(0)
#	PlayerSFX.play()

func abort_qte():
	is_hidden = false
	qteSlider.visible = false
	valSlider.visible = false
	prompt.visible = false
	qteTimer.stop()
	delayTimer.stop()

func _on_stealth_timer_timeout():
	is_hidden = true


func _on_delay_timer_timeout():
	qteSlider.visible = true
	valSlider.visible = true
	prompt.visible = true
	qte["wantedTime"] = randf_range(0.1,qteTimer.wait_time-0.40)
	valSlider.value = qte["wantedTime"]*100
	qteTimer.start()

func _on_qte_timer_timeout():
	qteSlider.visible = false
	valSlider.visible = false
	if !qte["success"] :
		$FailSound.play()
		animationState.travel("FailQTE")
		#play_sound("res://Scene/Player/Assets/FailSound.tres")
	is_hidden = qte["success"]
	qte["success"] = false
	qte["done"] = false
	delayTimer.start()


func _on_animation_player_animation_finished(anim_name):
	if anim_name.contains("Bite") :
		biting = false
	pass # Replace with function body.


func _on_push_timer_timeout():
	pass # Replace with function body.
