extends CharacterBody2D

const SPEED = 100.0

@onready var scanner = $DetectionArea
@onready var nav_agent = $NavigationAgent2D
@onready var emote = $EmoteSprite

@export var health: int = 5

var target_loot: Area2D = null
var has_move_target = false
var target_still_hidden = true

func _init():
	pass

func _physics_process(delta):
	if not is_instance_valid(target_loot):
		target_loot = null
		if emote.animation != "missing":
			emote.play("default")

	if target_loot != null:
		if target_loot.is_in_group("mimic") and target_still_hidden and not target_loot.get_parent().is_hidden:
			target_still_hidden = false

		if target_loot.is_in_group("mimic") and not target_still_hidden:
			emote.play("attack")

			var space_state = get_world_2d().direct_space_state

			var diff = target_loot.global_position - global_position
			var query = PhysicsRayQueryParameters2D.create(global_position, target_loot.global_position + diff, collision_mask, [self])
			var result = space_state.intersect_ray(query)

			if result and result["collider"].is_in_group("mimic"):
				nav_agent.target_position = target_loot.global_position
			else:
				emote.play("missing")

		if nav_agent.distance_to_target() < 3:
			target_loot = null
			emote.play("missing")
			$QuestionTimer.start()
			pass

		calc_velocity()

	elif scanner.has_overlapping_areas():
		var nearby_loot = scanner.get_overlapping_areas()
		var space_state = get_world_2d().direct_space_state

		target_loot = null
		for loot in nearby_loot:

			var query = PhysicsRayQueryParameters2D.create(global_position, loot.global_position, collision_mask, [self])
			var result = space_state.intersect_ray(query)

			if not result or (result and result["collider"].is_in_group("mimic")):
				if target_loot == null or position.distance_to(loot.position) < position.distance_to(target_loot.position):

					target_loot = loot


		if target_loot != null:
			has_move_target = false
			nav_agent.target_position = target_loot.global_position
			emote.play("loot")

	if target_loot == null:
		if not has_move_target or (has_move_target and (nav_agent.distance_to_target() < 10 or nav_agent.is_target_reached())):

			while(true):

				var target_random = Vector2(randi_range(-300, 300), randi_range(-300, 300))
				if emote.animation == "missing":
					var dir = velocity.normalized()
					var scan_vec = dir * 30
					var vec1 = scan_vec.rotated(PI/4)
					var vec2 = scan_vec.rotated(-PI/4)
					var vec3 = position

					var r1 = randf()
					var r2 = randf()

					if (r1 + r2 > 1):
						r1 = 1 - r1
						r2 = 1 - r2

					var a = 1 - r1 - r2;
					var b = r1;
					var c = r2;

					target_random = a*vec1 + b*vec2 + c*vec3
					target_random += global_transform.origin
					print(target_random)

				nav_agent.target_position = target_random

				if nav_agent.is_target_reachable():
					has_move_target = true
					break

		else:
			# print(nav_agent.distance_to_target())
			calc_velocity()


	move_and_slide()


func calc_velocity():
	var next_pos: Vector2 = nav_agent.get_next_path_position()

	velocity = (next_pos - position).normalized() * SPEED


func bit():
	health -= 1
	if health <= 0:
		queue_free()


func _on_interact_area_area_entered(area):
	var area_parent = area.get_parent()
	if area_parent.is_in_group("loot"):
		area_parent.queue_free()
		target_loot = null
		emote.play("default")



func _on_question_timer_timeout():
	if emote.animation == "missing":
		emote.play("default")
	target_still_hidden = true
