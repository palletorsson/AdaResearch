extends MeshInstance3D
## The neck: the catenoid of the hall FormFinding_Catenary, made from (u, v) by
## two loops. Its axis is y and its waist is at its own origin. This folder goes
## to your room whole, so the script names nothing outside it and writes its
## colour out.

const Surfaces := preload("res://guests/budget/surfaces.gd")
const BODY := Color("c6ff3d")   # the look's BODY colour, written out

@export var u_steps: int = 24     # steps around
@export var v_steps: int = 12     # steps along the axis, from ring to ring
@export var size: float = 0.4     # metres for the radius of the waist

var build_usec := 0               # how long the last build took, in microseconds
var _shape: CollisionShape3D      # what a walker and a marble meet

func _ready() -> void:
	var body := StaticBody3D.new()
	_shape = CollisionShape3D.new()
	body.add_child(_shape)
	add_child(body)
	var started := Time.get_ticks_usec()
	build()
	build_usec = Time.get_ticks_usec() - started
	print(u_steps, " x ", v_steps, " steps: ", triangles(), " triangles, built in ", build_usec, " microseconds")

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in u_steps:
		for j in v_steps:
			var u0 := float(i) / u_steps
			var u1 := float(i + 1) / u_steps
			var v0 := float(j) / v_steps
			var v1 := float(j + 1) / v_steps
			corner(surface, u0, v0)
			corner(surface, u1, v0)
			corner(surface, u1, v1)
			corner(surface, u0, v0)
			corner(surface, u1, v1)
			corner(surface, u0, v1)
	surface.generate_normals()
	mesh = surface.commit()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = paint
	_shape.shape = mesh.create_trimesh_shape()

func corner(surface: SurfaceTool, u: float, v: float) -> void:
	surface.set_uv(Vector2(u, v))
	surface.add_vertex(Surfaces.catenoid(u, v) * size)

func triangles() -> int:
	return mesh.get_faces().size() / 3
