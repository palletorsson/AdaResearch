extends Node3D
class_name Prism

# @identity
# essence: Godot's built-in PrismMesh wrapped as a project primitive — a triangular prism whose top edge slides along the X axis via left_to_right, producing wedges from right-triangular to symmetric to skewed
# desire: a configurable triangular-prism primitive distinct from the wedge-shaped prismblock — exports the one parameter that matters (left_to_right) and the project's grid aesthetic
# critical_parameter: left_to_right — at 0.0 the top edge sits centred (isoceles wedge), at -1.0 it slides fully left (right-triangle prism), at +1.0 fully right (mirror right-triangle)
# triggers: _ready() builds a PrismMesh with the chosen left_to_right + size, then applies the project's grid shader so the wedge reads as part of the lattice
# emerges: a slanted volume that already implies a roof, an awning, or a ramp — geometry that tells the player "the floor stops being flat here"
# needs: PrismMesh [Godot built-in]; grid shader [present]; left_to_right + size exports [present, 2026-05-19]; class_name + @identity [present, 2026-05-19]; apply_grid_config [present, 2026-05-19]
# relationships: NOT the same shape as prismblock — prismblock is the 5-face asymmetric ridged wedge, this is the 5-face symmetric triangular prism; sibling primitive to triangularprism (a different procedural builder); used as a roof / awning / ramp piece in compound primitive demos
# truth: a prism is a triangle dragged along an axis. When the top edge slides off-centre, the dragged triangle becomes a different triangle — and the same "prism" primitive becomes a different shape.

## Configurable triangular-prism primitive backed by Godot's built-in PrismMesh.
## Distinct from prismblock (which is a procedurally-built 5-face ridged wedge).
## Replaces a previously-hardcoded scene that had no script, no exports, and
## no @identity. UID preserved so existing map / registry references resolve.

@export var left_to_right: float = 0.0
@export var size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var fill_color: Color = Color(0.2, 0.3, 0.8, 0.7)
@export var wireframe_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var wireframe_width: float = 3.0
@export var wireframe_brightness: float = 2.0

const SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_build_prism()


func _build_prism() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "PrismMesh"
	var mesh := PrismMesh.new()
	mesh.left_to_right = left_to_right
	mesh.size = size
	_mesh_instance.mesh = mesh

	# Material: try the project's SimpleGrid shader; fall back to StandardMaterial3D
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var sh := ShaderMaterial.new()
		sh.shader = shader
		sh.set_shader_parameter("fill_color", fill_color)
		sh.set_shader_parameter("wireframe_color", wireframe_color)
		sh.set_shader_parameter("wireframe_width", wireframe_width)
		sh.set_shader_parameter("wireframe_brightness", wireframe_brightness)
		_mesh_instance.material_override = sh
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = fill_color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if fill_color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		_mesh_instance.material_override = m

	# Position so the prism sits on the ground (base at y=0, peak at y=size.y).
	_mesh_instance.position = Vector3(0, size.y * 0.5, 0)
	add_child(_mesh_instance)


func set_left_to_right(v: float) -> void:
	left_to_right = clamp(v, -1.0, 1.0)
	_build_prism()


## Called by the grid system. Keys honoured:
##   "left_to_right"       — float, top-edge slide [-1.0 .. 1.0]
##   "size"                — Vector3 or [x,y,z], full size of the prism's bounding box
##   "color" / "fill_color"
##   "wireframe_color"
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("left_to_right"):
		left_to_right = clamp(float(config_data["left_to_right"]), -1.0, 1.0); dirty = true
	if config_data.has("size"):
		var s = config_data["size"]
		if s is Vector3:
			size = s
		elif s is Array and s.size() >= 3:
			size = Vector3(float(s[0]), float(s[1]), float(s[2]))
		dirty = true
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			fill_color = c
		elif c is Array and c.size() >= 3:
			fill_color = Color(float(c[0]), float(c[1]), float(c[2]))
		dirty = true
	if config_data.has("fill_color"):
		var c2 = config_data["fill_color"]
		if c2 is Color:
			fill_color = c2
		dirty = true
	if config_data.has("wireframe_color"):
		var w = config_data["wireframe_color"]
		if w is Color:
			wireframe_color = w
		dirty = true
	if dirty and _mesh_instance:
		_build_prism()
