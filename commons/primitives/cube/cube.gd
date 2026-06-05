# Cube.gd - Regular cube/hexahedron (6 square faces)
extends Node3D
class_name Cube

# @identity
# essence: the unit cube — the project's geometric atom and the grid system's literal cell
# desire: a configurable hexahedron primitive that any map cell, artifact, or compound shape can drop in without subclassing
# critical_parameter: size — sets the cell-edge length; default 0.5 (= 1.0m cube, the grid cell size)
# triggers: _ready() builds 8 vertices and 12 triangle faces with a grid-shader material in base_color
# emerges: a hard-edged six-sided body with consistent grid lines on every face, color uniform across the surface
# needs: GridMaterialFactory [present]; PrimitiveMeshBuilder [present]; size + color knobs via apply_grid_config [present, 2026-05-19]
# relationships: parent vocabulary for boxbeam, dice, design_classics; sibling to cylinder, capsule, dodecahedron, icosahedron, octahedron, tetrahedron under primitives/; the grid system's GridSystem.gd places these directly into cells
# truth: the cube is what every other shape is measured against — the cell, the box, the void's complement. Making it configurable means the grid stops being the only thing that names size.

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


@export var base_color: Color = Color(0.0, 1.0, 1.0)
## Half-edge length. The cube extends ±size on each axis; default 0.5 = 1.0m edge,
## matching the grid cell. Set via apply_grid_config({"size": 0.3}) or directly in
## the inspector for compound primitives.
@export var size: float = 0.5

var _mesh_instance: MeshInstance3D

func _ready():
	_build_cube()

func _build_cube() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var geometry := _cube_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Cube",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _cube_geometry() -> Dictionary:
	var vertices: Array[Vector3] = [
		Vector3(-size, -size, size),
		Vector3(size, -size, size),
		Vector3(size, size, size),
		Vector3(-size, size, size),
		Vector3(-size, -size, -size),
		Vector3(size, -size, -size),
		Vector3(size, size, -size),
		Vector3(-size, size, -size)
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],
		[5, 4, 7], [5, 7, 6],
		[4, 0, 3], [4, 3, 7],
		[1, 5, 6], [1, 6, 2],
		[3, 2, 6], [3, 6, 7],
		[4, 5, 1], [4, 1, 0]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "size"  — half-edge length (Float)
##   "color" — base_color (Color or [r,g,b] array)
## Unknown keys are ignored. Rebuilds the mesh if it has already been constructed.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("size"):
		size = float(config_data["size"])
		dirty = true
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			base_color = c
		elif c is Array and c.size() >= 3:
			base_color = Color(float(c[0]), float(c[1]), float(c[2]))
		dirty = true
	if dirty and _mesh_instance:
		_build_cube()
