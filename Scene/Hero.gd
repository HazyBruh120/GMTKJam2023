extends CharacterBody2D

const SPEED = 150.0

@onready var scanner = $DetectionArea
@onready var nav_agent = $NavigationAgent2D

var target_loot: Area2D = null

func _init():
	pass

func _physics_process(delta):

	if target_loot != null:
		nav_agent.target_position = target_loot.global_position
		var next_pos: Vector2 = nav_agent.get_next_path_position()

		velocity = (next_pos - position).normalized() * SPEED

	elif scanner.has_overlapping_areas():
		var nearby_loot = scanner.get_overlapping_areas()

		target_loot = nearby_loot[0]
		for loot in nearby_loot:
			if position.distance_to(loot.position) < position.distance_to(target_loot.position):
				target_loot = loot

	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()



func _on_interact_area_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent.is_in_group("loot"):
		area_parent.queue_free()
		target_loot = null

