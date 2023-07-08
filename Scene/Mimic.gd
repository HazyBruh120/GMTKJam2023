extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_vector = Vector2(Input.get_axis("ui_left", "ui_right"),Input.get_axis("ui_up", "ui_down"))
	if input_vector:
		velocity = input_vector * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()
