extends ImmediateGeometry

var target := Vector3.ZERO

func _process(_delta):
	clear()

	begin(Mesh.PRIMITIVE_LINES)
	add_vertex(Vector3.ZERO)
	add_vertex(target)
	end()
