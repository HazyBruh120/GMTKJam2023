extends CharacterBody2D

const SPEED = 150.0

@onready var scanner = $DetectionArea
@onready var nav_agent = $NavigationAgent2D

var target_loot: Area2D = null
var has_move_target = false

func _init():
	pass

func _physics_process(delta):

	if target_loot != null:
		if target_loot.is_in_group("mimic"):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, target_loot.global_position, collision_mask, [self])
			var result = space_state.intersect_ray(query)

			if result and result["collider"].is_in_group("mimic"):
				nav_agent.target_position = target_loot.position

		if nav_agent.distance_to_target() < 3:
			target_loot = null

		calc_velocity()

	elif scanner.has_overlapping_areas():
		var nearby_loot = scanner.get_overlapping_areas()
		var space_state = get_world_2d().direct_space_state

		target_loot = null
		for loot in nearby_loot:

			var query = PhysicsRayQueryParameters2D.create(global_position, loot.global_position, collision_mask, [self])
			var result = space_state.intersect_ray(query)

			if not result or (result and result["collider"].is_in_group("loot")):
				if target_loot == null or position.distance_to(loot.position) < position.distance_to(target_loot.position):
					target_loot = loot

		if target_loot != null:
			has_move_target = false
			nav_agent.target_position = target_loot.global_position

	if target_loot == null:
		if not has_move_target or (has_move_target and (nav_agent.distance_to_target() < 10 or nav_agent.is_target_reached())):

			while(true):
				var target_random = Vector2(randi_range(-300, 300), randi_range(-300, 300))
				nav_agent.target_position = target_random

				if nav_agent.is_target_reachable():
					print("reachable")
					has_move_target = true
					break

		else:
			# print(nav_agent.distance_to_target())
			print("moving")
			calc_velocity()


	move_and_slide()

func calc_velocity():
	var next_pos: Vector2 = nav_agent.get_next_path_position()

	velocity = (next_pos - position).normalized() * SPEED



func _on_interact_area_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent.is_in_group("loot"):
		area_parent.queue_free()
		target_loot = null

