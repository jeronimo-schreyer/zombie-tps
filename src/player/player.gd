extends KinematicBody


var linear_velocity : Vector3
var jumping = false
var can_move = true setget set_can_move

onready var anim_tree = $AnimationTree
onready var mesh = $Mesh
onready var floor_raycast = $FloorRayCast
onready var climb_raycast = $Mesh/ClimbRayCast
onready var jump_edge_raycast = $Mesh/JumpEdgeRayCast
onready var movement_line = $ImmediateGeometry
onready var tween = $Tween

onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") \
				* ProjectSettings.get_setting("physics/3d/default_gravity_vector")


# Called when the node enters the scene tree for the first time.
func _ready():
	anim_tree.set_active(true)


func set_can_move(_can_move: bool):
	can_move = _can_move
