extends KinematicBody


export (float) var walk_speed = 6
export (float) var run_speed = 10
export (float) var jump_force = 10
export (float) var acceleration = 20
export (float) var deacceleration_factor = 3.0
export (float) var air_acceleration_factor = 0.5
export (float) var turn_speed = 10
export (float) var crouch_speed = .12
export (NodePath) var rig

var linear_velocity : Vector3
var jumping = false
var is_hanging = false
var can_move = true setget set_can_move
var standing = true

onready var anim_tree = $AnimationTree
onready var mesh = $Mesh
onready var floor_raycast = $FloorRayCast
onready var climb_raycast = $Mesh/ClimbRayCast
onready var movement_line = $ImmediateGeometry
onready var tween = $Tween

onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") \
				* ProjectSettings.get_setting("physics/3d/default_gravity_vector")


# Called when the node enters the scene tree for the first time.
func _ready():
	NodePathReflection.LinkNodePaths(self)
	anim_tree.set_active(true)


func _physics_process(delta):
	linear_velocity += gravity * delta

	var vv = linear_velocity.y # vertical velocity
	var hv = Vector3(linear_velocity.x, 0, linear_velocity.z) # horizontal velocity

	if is_hanging:
		pass
	else:
		var hdir = hv.normalized() # horizontal direction
		var hspeed = hv.length() # horizontal speed
		var updir = Vector3.UP # up direction
		var is_running = Input.is_action_pressed("run")

		# player input (camera oriented)
		var cam_basis = rig.camera.get_global_transform().basis
		var input_direction = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		) if can_move else Vector2.ZERO

		var dir = cam_basis * Vector3(input_direction.x, 0, input_direction.y)
		dir.y = 0
		dir = dir.normalized()

		# calculate speed
		var on_floor = is_on_floor()
		if on_floor:
			updir = get_floor_normal()
			if dir.length() > 0.1:
				hdir = dir - updir
				hspeed = min(hspeed + acceleration * delta, run_speed if is_running else walk_speed)
			else:
				hspeed = max(hspeed - acceleration * deacceleration_factor * delta, 0.0)

			hv = hdir * hspeed

			if Input.is_action_just_pressed("jump") and not jumping:
				jumping = true
				anim_tree.get("parameters/On_Ground/playback").travel("Run Jump")

			if Input.is_action_just_pressed("action"):
				if climb_raycast.is_colliding():
					global_transform.origin = climb_raycast.get_collision_point()
					anim_tree.get("parameters/On_Ground/playback").travel("Climb Up")
					can_move = false
				else:
					standing = !standing
					var initial = 0 if standing else 1
					var end = 1 if standing else 0
					tween.interpolate_property(anim_tree, \
						"parameters/On_Ground/Movement/Stance/blend_amount", \
						initial, end, \
						crouch_speed)
					tween.start()

		else:
			if dir.length() > 0.1:
				hv += dir * (acceleration * air_acceleration_factor * delta)
				if hv.length() > run_speed:
					hv = hv.normalized() * run_speed
			else:
				#hspeed = max(hspeed - acceleration * air_acceleration_factor * delta, 0.0)
				# dont use air_acceleration_factor to stop the player on air if not pressing keys
				hspeed = max(hspeed - acceleration * delta, 0.0)
				hv = hdir * hspeed

		# align with horizontal direction
		var orientation = mesh.global_transform.basis
		if dir.length() > 0:
			orientation = Basis(orientation.get_rotation_quat().slerp(
				Transform().looking_at(-dir, Vector3.UP).basis.get_rotation_quat(), turn_speed * delta))

		# align with floor surface normal
		orientation.y = updir
		orientation.x = -orientation.z.cross(updir)
		mesh.global_transform.basis = orientation.orthonormalized()

		# release jump
		if jumping and vv < 0:
			jumping = false

		# update animation values
		var is_on_air = not on_floor and vv < 0
		var move_blend = hspeed
		anim_tree.set("parameters/On_Ground/Movement/Crouch/blend_position", move_blend)
		anim_tree.set("parameters/On_Ground/Movement/Walk/blend_position", move_blend)
		anim_tree.set("parameters/conditions/On_Ground", on_floor)
		anim_tree.set("parameters/conditions/On_Air", is_on_air)
		anim_tree.set("parameters/On_Air/conditions/Fall", is_on_air and floor_raycast.is_colliding())

		# edge detection
		if is_on_air and climb_raycast.is_colliding():

			# align the mesh with the wall normal
			var space_state := get_world().direct_space_state
			var result : Dictionary = space_state.intersect_ray(global_transform.origin, mesh.global_transform.basis.z, [self])
			if not result.empty():
				mesh.look_at(global_transform.origin + result.normal, Vector3.UP)

			# ṕṕṕplace the player at the collision point and pause movement
			anim_tree.get("parameters/playback").travel("Braced Hang Over")
			can_move = false
			global_transform.origin = climb_raycast.get_collision_point()

		# update floor raycast length acording to velocity
		if is_on_air:
			floor_raycast.cast_to = Vector3(0, max(linear_velocity.y, gravity.y * .5), 0)
		else:
			floor_raycast.cast_to = Vector3(0,-0.2, 0)


	linear_velocity = move_and_slide(hv + Vector3.UP * vv, -gravity.normalized(), true)
	movement_line.target = linear_velocity


func jump():
	linear_velocity.y = jump_force


func set_can_move(_can_move: bool):
	can_move = _can_move
