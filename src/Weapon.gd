extends Spatial

const smoke = preload("res://fx/bullet_smoke.tscn")

onready var rig = $"../../CameraRig"
onready var mesh = $MeshInstance
onready var muzzle = $MeshInstance/Muzzle


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_look_point():
	var look_point : Vector3
	if rig.raycast.is_colliding():
		look_point = rig.raycast.get_collision_point()
	else:
		look_point = rig.camera.get_global_transform().basis.z

	return look_point


func _input(_event):
	if Input.is_action_pressed("point"):
		mesh.look_at(get_look_point(), Vector3.UP)

	if Input.is_action_just_pressed("fire"):
		var s = smoke.instance()
		muzzle.get_parent().add_child(s)
		s.transform = muzzle.transform
