# Plane.gd - Generates a plane mesh
extends Node3D
class_name PlanePrimitive

# @identity
# essence: the simplest 2D surface — a flat infinite-by-convention rectangle that the grid stands on, subdivided into a triangle mesh
# desire: a configurable ground/wall/ceiling primitive that any map cell or compound shape can drop in without manual mesh-tool work
# critical_parameter: width × height (size) and x_segments × y_segments (resolution); together they decide both footprint and triangle count
# triggers: _ready() builds vertices in row-major order, then emits two triangles per quad with CCW winding for +Y normals
# emerges: a flat surface whose tessellation density is visible — high segments make the wireframe legible, low segments make it sparse
# needs: GridMaterialFactory [present]; PrimitiveMeshBuilder [present]; width/height/segments exports [present]; class_name + @identity + apply_grid_config [present, 2026-05-19]
# relationships: foundational with cube (3D body) and sphere (curved surface) — together they cover the grid system's vocabulary of "what a cell can be"; consumed by floor/wall/ceiling primitives across maps; sibling to triangle (single face) and quad (two-triangle rectangle without subdivision)
# truth: a plane is the limit of a cube as one of its dimensions goes to zero — flatness is just a degenerate volume. Subdivisions make the flatness visible by drawing the lattice on top of it.

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

@export var width: float = 10.0
@export var height: float = 10.0
@export var x_segments: int = 10
@export var y_segments: int = 10
@export var base_color: Color = Color(0.8, 0.8, 0.8)

var _mesh_instance: MeshInstance3D

signal mesh_built(mesh_instance)

func _ready():
	_build_plane()

func _build_plane() -> void:
	_teardown()
	var geometry := _plane_geometry()
	var material = GridMaterialFactory.make(base_color, {
		"edge_color": Color.BLACK,
		"edge_width": 0.2,
		"emission_strength": 0.5
	})
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Plane",
			"material": material
		}
	)
	add_child(_mesh_instance)
	mesh_built.emit(_mesh_instance)

func _teardown() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

func _plane_geometry() -> Dictionary:
	var vertices: Array[Vector3] = []
	var faces: Array = []

	var half_width = width / 2.0
	var half_height = height / 2.0
	var x_step = width / float(x_segments)
	var y_step = height / float(y_segments)

	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			var x = -half_width + i * x_step
			var z = half_height - j * y_step
			vertices.append(Vector3(x, 0, z))

	for j in range(y_segments):
		for i in range(x_segments):
			var a = j * (x_segments + 1) + i
			var b = a + 1
			var c = (j + 1) * (x_segments + 1) + i
			var d = c + 1
			# Use CCW winding as seen from +Y to ensure upward-facing normals
			# Triangle 1
			faces.append([a, c, b])
			# Triangle 2
			faces.append([b, c, d])

	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
			"edge_color": Color.BLACK,
			"edge_width": 0.2,
			"emission_strength": 0.5
		})

## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "size" / "width" / "height" — float, edge length(s); "size" sets both
##   "x_segments" / "y_segments" — int, mesh resolution; ≥ 1
##   "color"                    — Color or [r,g,b] array
## Unknown keys are ignored. Rebuilds the mesh if it has already been built.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("size"):
		var s := float(config_data["size"])
		width = s
		height = s
		dirty = true
	if config_data.has("width"):
		width = float(config_data["width"]); dirty = true
	if config_data.has("height"):
		height = float(config_data["height"]); dirty = true
	if config_data.has("x_segments"):
		x_segments = max(1, int(config_data["x_segments"])); dirty = true
	if config_data.has("y_segments"):
		y_segments = max(1, int(config_data["y_segments"])); dirty = true
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			base_color = c
		elif c is Array and c.size() >= 3:
			base_color = Color(float(c[0]), float(c[1]), float(c[2]))
		dirty = true
	if dirty and _mesh_instance:
		_build_plane()
