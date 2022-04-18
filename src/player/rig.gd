extends Spatial

export (float) var min_zoom = 1.0
export (float) var max_zoom = 6.0
export (float) var zoom_factor = 0.3
export (float) var zoom_duration = 0.12
export (float) var joy_rotate_speed = 72.0
export (float) var mouse_sensitivity = 0.1
export (float) var max_camera_angle = 30
export (float) var movement_speed = 5
export (NodePath) var player

onready var spring = $SpringArm
onready var camera = $SpringArm/Camera
onready var tween = $Tween

var offset : Vector3
var zoom_level := 6.0 setget set_zoom_level


# Called when the node enters the scene tree for the first time.
func _ready():
	NodePathReflection.LinkNodePaths(self)
	offset = global_transform.origin - player.global_transform.origin


func _process(delta):
	var rotate_x = Input.get_axis("rotate_camera_down", "rotate_camera_up")
	if abs(rotate_x) > 0.0:
		spring.rotate_x(deg2rad(rotate_x * joy_rotate_speed * delta))
		clamp_camera()
	rotate_y(deg2rad(Input.get_axis("rotate_camera_right", "rotate_camera_left") * joy_rotate_speed * delta))

	global_transform.origin = global_transform.origin.linear_interpolate( \
		player.global_transform.origin - offset, \
		movement_speed * delta)

	if Input.is_action_pressed("zoom_camera_in"):
		set_zoom_level(zoom_level - zoom_factor)

	if Input.is_action_pressed("zoom_camera_out"):
		set_zoom_level(zoom_level + zoom_factor)


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

	if event.is_action_pressed("zoom_camera_in"):
		set_zoom_level(zoom_level - zoom_factor)

	if event.is_action_pressed("zoom_camera_out"):
		set_zoom_level(zoom_level + zoom_factor)


func clamp_camera():
	var camera_rot = spring.rotation
	camera_rot.x = clamp(camera_rot.x, deg2rad(-max_camera_angle), deg2rad(max_camera_angle))
	spring.rotation = camera_rot


func set_zoom_level(value: float):
	if value < max_zoom and value > min_zoom:
		tween.interpolate_property(spring, "spring_length", zoom_level, value, zoom_duration, tween.TRANS_SINE, tween.EASE_OUT)
		zoom_level = clamp(value, min_zoom, max_zoom)
		tween.start()


func add_raycast_exception(object):
	spring.add_excluded_object(object.get_rid())
