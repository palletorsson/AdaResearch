# Partial Derivative Terrain — ∂f/∂x and ∂f/∂y on a surface
#
# A bumpy terrain height-field z = f(x, y). Two arrows hover above the surface:
#   - red arrow points in +x direction, length = ∂f/∂x at that point
#   - green arrow points in +y direction, length = ∂f/∂y at that point
# The arrows ride the surface as the cursor moves over it, showing both partial slopes.
#
# Introduces partial differentiation: when you have a function of two variables, you can
# take its derivative with respect to either one. This is the substrate for forces' 3D
# vector calculus and for ML's gradient descent.
#
# @identity: First map where the player meets two-axis differentiation.
# @qfep_term: F over a 2D domain.

extends Node3D
class_name PartialDerivativeTerrain

@export_category("Terrain Settings")
@export var terrain_color: Color = Color(0.3, 0.5, 0.4, 1.0)
@export var dx_arrow_color: Color = Color(1.0, 0.4, 0.45, 1.0)  # red = ∂/∂x
@export var dy_arrow_color: Color = Color(0.5, 1.0, 0.55, 1.0)  # green = ∂/∂y
@export var grid_size: int = 24
@export var span: float = 2.0
@export var height_scale: float = 0.35
@export var sample_speed: float = 0.5

var _terrain_mesh: MeshInstance3D
var _dx_arrow: MeshInstance3D
var _dy_arrow: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_terrain()
	_dx_arrow = _build_arrow(dx_arrow_color)
	_dy_arrow = _build_arrow(dy_arrow_color)
	add_child(_dx_arrow)
	add_child(_dy_arrow)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_size"):
		grid_size = int(config_data["grid_size"])
	if config_data.has("span"):
		span = float(config_data["span"])


func _process(delta: float) -> void:
	_t += delta * sample_speed
	_update_arrows()


func _f(x: float, y: float) -> float:
	# A double-frequency wavy terrain.
	return sin(x * 1.5) * cos(y * 1.5) * height_scale + sin(x + y) * 0.12 * height_scale


func _df_dx(x: float, y: float) -> float:
	# ∂f/∂x analytically.
	return 1.5 * cos(x * 1.5) * cos(y * 1.5) * height_scale + cos(x + y) * 0.12 * height_scale


func _df_dy(x: float, y: float) -> float:
	# ∂f/∂y analytically.
	return -1.5 * sin(x * 1.5) * sin(y * 1.5) * height_scale + cos(x + y) * 0.12 * height_scale


func _build_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	_terrain_mesh.name = "Terrain"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = span / float(grid_size)
	for i in grid_size:
		for j in grid_size:
			var x0: float = -span * 0.5 + float(i) * step
			var z0: float = -span * 0.5 + float(j) * step
			var x1: float = x0 + step
			var z1: float = z0 + step
			var y00: float = _f(x0, z0)
			var y10: float = _f(x1, z0)
			var y01: float = _f(x0, z1)
			var y11: float = _f(x1, z1)
			# Two triangles per quad.
			st.add_vertex(Vector3(x0, y00, z0))
			st.add_vertex(Vector3(x1, y10, z0))
			st.add_vertex(Vector3(x1, y11, z1))
			st.add_vertex(Vector3(x0, y00, z0))
			st.add_vertex(Vector3(x1, y11, z1))
			st.add_vertex(Vector3(x0, y01, z1))
	st.generate_normals()
	_terrain_mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = terrain_color
	mat.roughness = 0.85
	_terrain_mesh.material_override = mat
	add_child(_terrain_mesh)


func _build_arrow(color: Color) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.4)
	arrow.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = mat
	return arrow


func _update_arrows() -> void:
	# Sample point moves in a small circle.
	var sx: float = sin(_t * 0.4) * 0.7
	var sz: float = cos(_t * 0.6) * 0.7
	var sy: float = _f(sx, sz)
	var dx: float = _df_dx(sx, sz)
	var dy: float = _df_dy(sx, sz)
	# Place the arrows just above the surface at (sx, sy, sz).
	var lift := Vector3(0, 0.05, 0)
	var origin := Vector3(sx, sy, sz) + lift
	# +x direction arrow with length = |dx|.
	_dx_arrow.position = origin + Vector3(0.25, 0, 0)
	_dx_arrow.transform.basis = Basis().looking_at(Vector3.RIGHT, Vector3.UP)
	_dx_arrow.scale.z = clamp(abs(dx) * 6.0, 0.3, 2.0)
	# +y direction arrow with length = |dy|.
	_dy_arrow.position = origin + Vector3(0, 0, 0.25)
	_dy_arrow.transform.basis = Basis().looking_at(Vector3.FORWARD, Vector3.UP)
	_dy_arrow.scale.z = clamp(abs(dy) * 6.0, 0.3, 2.0)
