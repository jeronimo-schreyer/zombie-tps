extends Spatial

export (float) var mouse_sensitivity
export (float) var max_camera_angle

onready var raycast = $SpringArm/Camera/RayCast
onready var spring = $SpringArm
onready var camera = $SpringArm/Camera


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring.rotate_x(deg2rad(event.relative.y * mouse_sensitivity * -1))
		rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))

		var camera_rot = spring.rotation
		camera_rot.x = clamp(camera_rot.x, deg2rad(-max_camera_angle), deg2rad(max_camera_angle))
		spring.rotation = camera_rot


func add_raycast_exception(object):
	raycast.add_exception(object)
	spring.add_excluded_object(object.get_rid())
