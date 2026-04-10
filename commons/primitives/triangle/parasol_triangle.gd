# @identity
# essence: triangle(elevated) + cylinder(stick) — a triangle raised on a pole like a parasol
# desire: to make triangles visible from across the room — a flag, a marker, an invitation
# critical_parameter: stick_height / triangle_scale — the parasol must read as "triangle on a stick" instantly
# triggers: placed in map, visible from spawn — draws the eye upward to the triangle surface
# emerges: the triangle becomes architectural — not just a shape but a structure, a shelter, a sign
# needs: triangle mesh [has]; stick cylinder [has]; double-sided material [has]
# relationships: child of triangle.gd concept; placed in Point_Triangle map; one per map as landmark
# truth: elevate a shape and it becomes a symbol.

# ParasolTriangle.gd
# A triangle mounted on a thin stick — like a parasol or flag.
# The triangle sits at the top, slightly tilted, with a thin cylinder pole below.
# Place multiples in a map for a forest of triangle parasols.

extends Node3D
class_name ParasolTriangle

@export var stick_height: float = 1.5
@export var stick_radius: float = 0.015
@export var triangle_size: float = 0.4
@export var triangle_tilt: float = 10.0  # degrees of tilt for visual interest
@export var stick_color: Color = Color(0.5, 0.5, 0.55)
@export var triangle_color_front: Color = Color(1.0, 0.2, 0.5)  # Deep pink like the triangle artifact
@export var triangle_color_back: Color = Color(0.2, 0.5, 1.0)   # Blue backside for orientation

var _stick: MeshInstance3D = null
var _tri_mesh: MeshInstance3D = null


func _ready() -> void:
	_build_stick()
	_build_triangle()


func _build_stick() -> void:
	_stick = MeshInstance3D.new()
	_stick.name = "Stick"
	var cyl := CylinderMesh.new()
	cyl.top_radius = stick_radius
	cyl.bottom_radius = stick_radius * 1.3  # Slightly thicker at base
	cyl.height = stick_height
	cyl.radial_segments = 8
	_stick.mesh = cyl
	_stick.position = Vector3(0, stick_height * 0.5, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = stick_color
	mat.metallic = 0.6
	mat.roughness = 0.3
	_stick.material_override = mat
	add_child(_stick)


func _build_triangle() -> void:
	# Build a double-sided triangle mesh at the top of the stick
	_tri_mesh = MeshInstance3D.new()
	_tri_mesh.name = "TriangleSurface"
	_tri_mesh.position = Vector3(0, stick_height, 0)
	_tri_mesh.rotation_degrees = Vector3(triangle_tilt, 0, 0)

	var half := triangle_size * 0.5
	# Matching the triangle artifact proportions
	var v0 := Vector3(-half, 0, 0)
	var v1 := Vector3(half, 0, 0)
	var v2 := Vector3(0, triangle_size * 0.866, 0)  # Equilateral height

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Front face (pink)
	st.set_color(triangle_color_front)
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)

	# Back face (blue) — reversed winding
	st.set_color(triangle_color_back)
	st.set_normal(Vector3(0, 0, -1))
	st.add_vertex(v1)
	st.add_vertex(v0)
	st.add_vertex(v2)

	_tri_mesh.mesh = st.commit()

	# Material — vertex colors enabled for front/back distinction
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.3, 0.5)
	mat.emission_energy_multiplier = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	mat.metallic = 0.1
	mat.roughness = 0.4
	_tri_mesh.material_override = mat

	add_child(_tri_mesh)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("height"):
		stick_height = float(config_data["height"])
	if config_data.has("size"):
		triangle_size = float(config_data["size"])
	if config_data.has("tilt"):
		triangle_tilt = float(config_data["tilt"])
	if config_data.has("color"):
		var c := Color(config_data["color"])
		triangle_color_front = c
