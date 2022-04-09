extends KinematicBody


export (float) var walk_force
export (float) var jump_force

onready var gravity = ProjectSettings.get("physics/3d/default_gravity") * \
	ProjectSettings.get("physics/3d/default_gravity_vector")

onready var rig = $CameraRig
onready var mesh = $Base
onready var anim_tree = $Base/Mesh/AnimationTree
onready var floor_raycast = $Base/FloorRayCast
onready var movement_line = $ImmediateGeometry

var velocity = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Get Input Axis
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_down", "ui_up")
	).normalized()
	var animation_movement = Vector2.ZERO
	var collision_normal = floor_raycast.get_collision_normal()

	if input_direction != Vector2.ZERO:
		# Get direction acording to camera
		var xform = rig.camera.get_global_transform()
		var direction = xform.basis.x * input_direction.x \
			- xform.basis.z * input_direction.y \
			- collision_normal

		# Apply in velocity vector
		velocity.x = direction.x * walk_force
		velocity.z = direction.z * walk_force

		if is_pointing():
			mesh.rotation = rig.rotation
			animation_movement = input_direction
		else:
			# Rotate mesh in the movement direction
			var look_point : Vector3
			look_point = transform.origin + direction
			mesh.look_at(look_point, Vector3.UP)
			mesh.rotation_degrees.x = 0
			animation_movement = Vector2.DOWN

	# If no input, then deaccelerate
	elif velocity != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0, walk_force)
		velocity.z = move_toward(velocity.z, 0, walk_force)

	# Apply gravity
	var is_on_floor = is_on_floor()
	if !is_on_floor:
		velocity.y = max(velocity.y + gravity.y * delta, gravity.y)

	movement_line.target = move_and_slide(velocity, Vector3.UP, true)

	if is_on_floor:
		# Align with floor surface
		mesh.global_transform.basis.y = collision_normal
		mesh.global_transform.basis.x = -mesh.global_transform.basis.z.cross(collision_normal)
		mesh.global_transform.basis = mesh.global_transform.basis.orthonormalized()

		# Jump if actioned
		if Input.is_action_just_pressed("ui_select"):
			anim_tree.set("parameters/On Floor/conditions/Jump", true)

	# Update Animation Tree parameters
	var is_on_air = !is_on_floor and velocity.y < 0.0
	anim_tree.set("parameters/On Floor/Movement/Movement/blend_position", animation_movement)
	anim_tree.set("parameters/conditions/On Floor", is_on_floor)
	anim_tree.set("parameters/conditions/On Air", is_on_air)
	anim_tree.set("parameters/On Air/conditions/Landing", is_on_air and floor_raycast.is_colliding())

	# Update floor raycast length acording to velocity
	if is_on_air:
		floor_raycast.cast_to = Vector3(0, velocity.y, 0)
	else:
		floor_raycast.cast_to = Vector3(0,-0.2, 0)


func jump():
	# Apply jump force
	velocity.y = jump_force
	anim_tree.set("parameters/On Floor/conditions/Jump", false)


func is_pointing():
	return Input.is_action_pressed("point")


func _input(_event):
	# Aim
	anim_tree.set("parameters/On Floor/Movement/Aim/blend_amount", 1.0 if is_pointing() else 0.0)
