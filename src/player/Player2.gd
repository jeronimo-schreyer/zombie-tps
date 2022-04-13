extends KinematicBody


export (float) var walk_speed = 6
export (float) var run_speed = 10
export (float) var jump_force = 10
export (float) var acceleration = 20
export (float) var deacceleration_factor = 3.0
export (float) var air_acceleration_factor = 0.5

var linear_velocity : Vector3
var jumping = false

onready var anim_tree = $AnimationTree
onready var rig = $CameraRig
onready var mesh = $Mesh
onready var floor_raycast = $FloorRayCast
onready var movement_line = $ImmediateGeometry

onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") \
				* ProjectSettings.get_setting("physics/3d/default_gravity_vector")


# Called when the node enters the scene tree for the first time.
func _ready():
	anim_tree.set_active(true)


func _physics_process(delta):
	linear_velocity += gravity * delta

	var vv = linear_velocity.y # vertical velocity
	var hv = Vector3(linear_velocity.x, 0, linear_velocity.z) # horizontal velocity
	var hdir = hv.normalized() # horizontal direction
	var hspeed = hv.length() # horizontal speed
	var updir = Vector3.UP # up direction
	var is_running = Input.is_action_pressed("run")

	# player input (camera oriented)
	var cam_basis = rig.camera.get_global_transform().basis
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
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

		if Input.is_action_just_pressed("ui_select") and not jumping:
			#vv = jump_force
			jumping = true
			anim_tree.get("parameters/On_Ground/playback").travel("Run Jump")
	else:
		if dir.length() > 0.1:
			hv += dir * (acceleration * air_acceleration_factor * delta)
			if hv.length() > run_speed:
				hv = hv.normalized() * run_speed
		else:
			#hspeed = max(hspeed - acceleration * air_acceleration_factor * delta, 0.0)
			# use this version to stop the player on air if not press ing keys
			hspeed = max(hspeed - acceleration * delta, 0.0)
			hv = hdir * hspeed
#			if hv.length() > max_speed:
#				hv = hv.normalized() * max_speed

	if hdir.length() > 0:
		# align with horizontal direction
		mesh.look_at(mesh.global_transform.origin - hdir, Vector3.UP)

	# align with floor surface
	mesh.global_transform.basis.y = updir
	mesh.global_transform.basis.x = -mesh.global_transform.basis.z.cross(updir)
	mesh.global_transform.basis = mesh.global_transform.basis.orthonormalized()

	# release jump
	if jumping and vv < 0:
		jumping = false

	# update animation values
	var is_on_air = not on_floor and vv < 0
	var move_blend = Vector3.UP * input_direction.length()
	anim_tree.set("parameters/On_Ground/Movement/blend_position", move_blend if is_running else move_blend / 2.0)
	anim_tree.set("parameters/conditions/On_Ground", on_floor)
	anim_tree.set("parameters/conditions/On_Air", is_on_air)
	anim_tree.set("parameters/On_Air/conditions/Fall", is_on_air and floor_raycast.is_colliding())

	# Update floor raycast length acording to velocity
	if is_on_air:
		floor_raycast.cast_to = Vector3(0, max(linear_velocity.y, gravity.y * .5), 0)
	else:
		floor_raycast.cast_to = Vector3(0,-0.2, 0)

	linear_velocity = move_and_slide(hv + Vector3.UP * vv, -gravity.normalized(), true)
	movement_line.target = linear_velocity


func jump():
	linear_velocity.y = jump_force
