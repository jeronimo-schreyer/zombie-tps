extends Spatial

export (float) var joy_rotate_speed
export (float) var mouse_sensitivity
export (float) var max_camera_angle

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
		clamp_camera()


func clamp_camera():
	var camera_rot = spring.rotation
	camera_rot.x = clamp(camera_rot.x, deg2rad(-max_camera_angle), deg2rad(max_camera_angle))
	spring.rotation = camera_rot


func _process(delta):
	var rotate_x = Input.get_axis("rotate_camera_up", "rotate_camera_down")
	if abs(rotate_x) > 0.0:
		spring.rotate_x(deg2rad(rotate_x * joy_rotate_speed * delta))
		clamp_camera()
	rotate_y(deg2rad(Input.get_axis("rotate_camera_right", "rotate_camera_left") * joy_rotate_speed * delta))


func add_raycast_exception(object):
	spring.add_excluded_object(object.get_rid())
