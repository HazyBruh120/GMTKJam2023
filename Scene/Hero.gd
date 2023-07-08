extends CharacterBody2D


const SPEED = 300.0



@onready var scanner = $DetectionArea
@onready var nav_agent = $NavigationAgent2D

func _init():
	pass

func _physics_process(delta):
	if scanner.has_overlapping_bodies():
		var nearby_loot = scanner.get_overlapping_areas()

		var target_loot: Area2D = nearby_loot[0]
		for loot in nearby_loot:
			if position.distance_to(loot.position) < position.distance_to(target_loot.position):
				target_loot = loot

		nav_agent.target_position = target_loot.global_position
		var next_pos = nav_agent.get_next_path_position()



	pass



#	velocity.x = direction * SPEED
#	velocity.x = move_toward(velocity.x, 0, SPEED)
#
#	move_and_slide()
