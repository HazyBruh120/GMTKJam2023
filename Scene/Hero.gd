extends CharacterBody2D



@onready var scanner = $DetectionArea
@onready var nav_agent = $NavigationAgent2D
@onready var emote = $EmoteSprite
@onready var take_damage_timer = $TakingDamageTimer
@onready var anim_sprite = $AnimatedSprite2D

@export var speed: float = 100.0
@export var base_health: int = 5
@export var will_push: bool = false

@onready var health = base_health

var target_loot: Area2D = null
var has_move_target = false
var target_still_hidden = true

var random = null


var is_first_move = true


func _init():

	velocity = Vector2.UP
	random = RandomNumberGenerator.new()
	print(random)
	random.randomize()






func _physics_process(delta):
	if (is_first_move):
		is_first_move = false
		has_move_target = true
		nav_agent.target_position = global_transform.origin + Vector2.DOWN * 15

		if base_health == 5:
			$HealthBar.play("health5")

		elif base_health == 2:
			$HealthBar.play("health2")

		$HealthBar.pause()


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

				var rand_dist = randf_range(100, 600)
				var rand_rot = PI/3 * random.randfn()
				print(rand_dist)
				print(rand_rot)

				var target_random = velocity.normalized() * rand_dist
				target_random = target_random.rotated(rand_rot) + global_transform.origin

				print(target_random)

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

				nav_agent.target_position = target_random

				if nav_agent.is_target_reachable():
					has_move_target = true
					break

		else:
			# print(nav_agent.distance_to_target())
			calc_velocity()

	do_damage()

	move_and_slide()


func calc_velocity():

	if not $TakingDamageTimer.is_stopped():
		velocity = Vector2.ZERO
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	velocity = (next_pos - position).normalized() * speed

	var dir = velocity.normalized()
	anim_sprite.flip_h = false

	#if abs(dir.y) > abs(dir.x): #up/down
	#	if dir.y < 0: #up
	#		anim_sprite.play("up")
	#	else: #down
	#		anim_sprite.play("down")
	#else: #horz
	if (dir.x < 0): #left
		anim_sprite.play("horz")
		anim_sprite.flip_h = true
	else: #right
		anim_sprite.play("horz")


func bit():
	if $TakingDamageTimer.is_stopped():
		$TakingDamageTimer.start()

	health -= 1
	if health <= 0:
		queue_free()

		$HealthBar.frame = base_health - health


	if will_push:
		do_push()

func is_biteable():
	return target_still_hidden or not $TakingDamageTimer.is_stopped()



func do_damage():
	if $HitArea.has_overlapping_bodies():
		for body in $HitArea.get_overlapping_bodies():
			if body.is_in_group("mimic"):
				if $AttackTimer.is_stopped():
					target_still_hidden = false
					body.on_hit()
					$AttackTimer.start()

				break


func do_push():
	if $HitArea.has_overlapping_bodies():
		for body in $HitArea.get_overlapping_bodies():
			if body.is_in_group("mimic"):
				var dir = body.global_position - global_position
				dir = dir.normalized()
				body.push(dir)
				break


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


func _on_taking_damage_timer_timeout():
	do_damage()
