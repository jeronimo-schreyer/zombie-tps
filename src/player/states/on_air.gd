extends "res://player/fsm/state.gd"


export (float) var acceleration = 5
export (float) var speed = 10
export (float) var turn_speed = 10

var gravity : Vector3

func init():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") \
				* ProjectSettings.get_setting("physics/3d/default_gravity_vector")


func enter():
	player.jump_edge_raycast.enabled = true


func exit():
	player.jump_edge_raycast.enabled = false


func check():
	return not player.is_on_floor()# and player.linear_velocity.y <= 0


func physics_process(delta):
	player.linear_velocity += gravity * delta

	var vv = player.linear_velocity.y # vertical velocity
	var hv = Vector3(player.linear_velocity.x, 0, player.linear_velocity.z) # horizontal velocity

	var hdir = hv.normalized() # horizontal direction
	var hspeed = hv.length() # horizontal speed

	var cam_basis = rig.camera.get_global_transform().basis
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	) if player.can_move else Vector2.ZERO

	var dir = cam_basis * Vector3(input_direction.x, 0, input_direction.y)
	dir.y = 0
	dir = dir.normalized()
	if dir.length() > 0.1:
		hv += dir * (acceleration * delta)
		if hv.length() > speed:
			hv = hv.normalized() * speed
	else:
		hspeed = max(hspeed - acceleration * delta, 0.0)
		hv = hdir * hspeed

	# align with horizontal direction
	var orientation = player.mesh.global_transform.basis
	if dir.length() > 0:
		orientation = Basis(orientation.get_rotation_quat().slerp( \
			Transform().looking_at(-dir, Vector3.UP).basis.get_rotation_quat(), \
			turn_speed * delta))

	# align Y up
	orientation.y = Vector3.UP
	orientation.x = -orientation.z.cross(Vector3.UP)
	player.mesh.global_transform.basis = orientation.orthonormalized()

	# don't detect edges if collided with the is_on_ceiling
	if player.is_on_ceiling():
		player.jump_edge_raycast.enabled = false

	# edge detection
	if vv < 0 and player.jump_edge_raycast.is_colliding():

		# align the mesh with the wall normal
		var space_state = player.get_world().direct_space_state
		var result : Dictionary = space_state.intersect_ray(player.global_transform.origin, player.mesh.global_transform.basis.z, [player])
		if not result.empty():
			player.mesh.look_at(player.global_transform.origin + result.normal, Vector3.UP)

		# ṕṕṕplace the player at the collision point and pause movement
		player.anim_tree.get("parameters/playback").travel("Braced Hang Over")
		player.can_move = false
		yield(player.get_tree().create_timer(0.1), "timeout")
		player.global_transform.origin = player.jump_edge_raycast.get_collision_point()

	player.floor_raycast.cast_to = Vector3(0, max(player.linear_velocity.y, gravity.y * .5), 0)
	player.linear_velocity = player.move_and_slide(hv + Vector3.UP * vv, \
		-gravity.normalized(), true)
	player.movement_line.target = player.linear_velocity

	# update animation tree parameters
	player.anim_tree.set("parameters/conditions/On_Ground", false)
	player.anim_tree.set("parameters/conditions/On_Air", true) #vv < 0)
	player.anim_tree.set("parameters/On_Air/conditions/Fall", vv < 0 and player.floor_raycast.is_colliding())
