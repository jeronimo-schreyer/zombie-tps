extends "res://fsm/state.gd"


export (float) var acceleration = 20
export (float) var walk_speed = 10
export (float) var deacceleration_factor = 3.0
export (float) var turn_speed = 10
export (float) var crouch_speed = 5
export (float) var jump_force = 10


var gravity : Vector3
var standing = true
var on_combat = false


func init():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") \
				* ProjectSettings.get_setting("physics/3d/default_gravity_vector")


func enter():
	player.climb_raycast.enabled = true


func exit():
	player.climb_raycast.enabled = false


func check():
	return player.is_on_floor()


func process(_delta):
	if Input.is_action_just_pressed("toggle_sword"):
		on_combat = !on_combat
		player.anim_tree.set("parameters/On_Ground/Movement/Withdraw Sword/active", on_combat)
		player.anim_tree.set("parameters/On_Ground/Movement/Seathing Sword/active", !on_combat)

	if Input.is_action_just_pressed("attack") and on_combat:
		player.anim_tree.get("parameters/On_Ground/playback").travel("Sword Attack")
		var anim = player.anim_tree.get("parameters/On_Ground/Sword Attack/playback")
		var current_hit = anim.get_current_node().trim_prefix("Hit")
		if not current_hit.empty() and current_hit != "empty":
			player.anim_tree.set("parameters/On_Ground/Sword Attack/conditions/Attack%s" % current_hit, true)

	if Input.is_action_just_pressed("action"):
		if player.climb_raycast.is_colliding():
			player.anim_tree.get("parameters/On_Ground/playback").travel("Climb Up")
			player.can_move = false
			yield(player.get_tree().create_timer(0.1), "timeout")
			player.global_transform.origin = player.climb_raycast.get_collision_point()
		else:
			standing = !standing
			var initial = 0 if standing else 1
			var end = 1 if standing else 0
			player.tween.interpolate_property(player.anim_tree, \
				"parameters/On_Ground/Movement/Stance/blend_amount", \
				initial, end, \
				.12)
			player.tween.start()


func physics_process(delta):
	player.linear_velocity += gravity * delta

	var vv = player.linear_velocity.y # vertical velocity
	var hv = Vector3(player.linear_velocity.x, 0, player.linear_velocity.z) # horizontal velocity

	var hdir = hv.normalized() # horizontal direction
	var hspeed = hv.length() # horizontal speed
	var updir = player.get_floor_normal()

	var cam_basis = rig.camera.get_global_transform().basis
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	) if player.can_move else Vector2.ZERO

	var dir = cam_basis * Vector3(input_direction.x, 0, input_direction.y)
	dir.y = 0
	dir = dir.normalized()

	if dir.length() > 0.1:
		hdir = dir - updir
		hspeed = min(hspeed + acceleration * delta, walk_speed if standing else crouch_speed)
	else:
		hspeed = max(hspeed - acceleration * deacceleration_factor * delta, 0.0)

	hv = hdir * hspeed

	if Input.is_action_just_pressed("jump") and not player.jumping:
		player.jumping = true
		vv = jump_force

	# align with horizontal direction
	var orientation = player.mesh.global_transform.basis
	if dir.length() > 0:
		orientation = Basis(orientation.get_rotation_quat().slerp( \
			Transform().looking_at(-dir, Vector3.UP).basis.get_rotation_quat(), \
			turn_speed * delta))

	# align with floor surface normal
	orientation.y = updir
	orientation.x = -orientation.z.cross(updir)
	player.mesh.global_transform.basis = orientation.orthonormalized()

	player.floor_raycast.cast_to = Vector3(0,-0.2, 0)
	player.linear_velocity = player.move_and_slide(hv + Vector3.UP * vv, \
		-gravity.normalized(), true)
	player.movement_line.target = player.linear_velocity

	# release jump
	if player.jumping and vv < 0:
		player.jumping = false

	# update animation tree parameters
	var move_blend = hspeed
	player.anim_tree.set("parameters/On_Ground/Movement/Crouch/blend_position", move_blend)
	player.anim_tree.set("parameters/On_Ground/Movement/Walk/blend_position", move_blend)
	player.anim_tree.set("parameters/conditions/On_Ground", true)
	player.anim_tree.set("parameters/conditions/On_Air", false)
	player.anim_tree.set("parameters/On_Air/conditions/Fall", false)
