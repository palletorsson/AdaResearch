extends MeshInstance3D
## The neck: the catenoid of FormFinding_Catenary as a mesh, made from (u, v)
## by two loops. It stands with its axis along y; the scene lays it on its side.

const Surfaces := preload("res://borrowed/surfaces.gd")
const Look := preload("res://supplied/look.gd")

@export var u_steps: int = 24     # cuts along the axis, from ring to ring
@export var v_steps: int = 48     # cuts around
@export var size: float = 1.1     # metres for one waist radius

var build_usec := 0               # how long the last build took, in microseconds

func _ready() -> void:
	var started := Time.get_ticks_usec()
	build()
	build_usec = Time.get_ticks_usec() - started
	give_body()
	print(u_steps, " x ", v_steps, " steps: ", triangles(), " triangles, built in ", build_usec, " microseconds")

func build() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in u_steps:
		for j in v_steps:
			var u0 := float(i) / u_steps
			var u1 := float(i + 1) / u_steps
			var v0 := float(j) / v_steps
			var v1 := float(j + 1) / v_steps
			corner(tool, u0, v0)
			corner(tool, u0, v1)
			corner(tool, u1, v1)
			corner(tool, u0, v0)
			corner(tool, u1, v1)
			corner(tool, u1, v0)
	tool.generate_normals()
	mesh = tool.commit()
	material_override = Look.paint(Look.BODY)
	material_override.cull_mode = BaseMaterial3D.CULL_DISABLED

func corner(tool: SurfaceTool, u: float, v: float) -> void:
	tool.set_uv(Vector2(v, u))
	tool.add_vertex(Surfaces.catenoid(u, v) * size)

func give_body() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)

func triangles() -> int:
	return mesh.get_faces().size() / 3
