extends Node3D
class_name Sphere

# @identity
# essence: the simplest curved surface — a constant distance from a point, the primitive that introduces continuity to the grid's right-angled vocabulary
# desire: a configurable sphere primitive that any map cell, compound shape, or pedagogical demo can drop in without hand-rolling SphereMesh sub-resources
# critical_parameter: radius — sets the visible scale; together with radial_segments × rings, it controls how "round" the sphere reads against the grid
# triggers: _ready() builds a SphereMesh and wraps it in a material with the project's grid-line aesthetic so the curved surface still reads as part of the lattice
# emerges: a smooth curved body that contrasts with the cube's hard edges — the primitive that says "not everything is a corner"
# needs: SphereMesh [Godot built-in]; grid-aesthetic material [present]; radius / color / segment exports [present, 2026-05-19]; apply_grid_config [present, 2026-05-19]
# relationships: foundational with cube (flat-faced volume) and plane (flat surface) — the three together cover the grid system's vocabulary of "what a cell can be"; consumed by light_sphere / dark_sphere / grab_sphere / grab_sphere_wood as thin-wrapper variants that override colour and shading
# truth: a sphere is what happens when you stop trusting right-angles. The grid lines on its surface tell you the lattice is still there — just bent.

## Configurable sphere primitive. A grid-shaded SphereMesh with radius,
## colour, and segment exports. The variants (dark_sphere, light_sphere,
## grab_sphere, grab_sphere_wood, spheres_version) are intended to become
## thin-wrapper scenes that instance this script with property overrides.

@export var radius: float = 0.25
@export var radial_segments: int = 32
@export var rings: int = 16
@export var base_color: Color = Color(0.5, 0.5, 0.5)
@export var wireframe_color: Color = Color(1.0, 0.0, 0.0)
@export var emission_strength: float = 2.0
@export var show_interior: bool = true

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

var _mesh_instance: MeshInstance3D

func _ready():
	_build_sphere()


func _build_sphere() -> void:
	# Tear down previous build (allows runtime config updates)
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Sphere"

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = max(3, radial_segments)
	mesh.rings = max(2, rings)
	_mesh_instance.mesh = mesh

	# Try the project's Grid.gdshader for the grid-line aesthetic; fall back
	# to StandardMaterial3D if the shader is missing.
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var sh_mat := ShaderMaterial.new()
		sh_mat.shader = shader
		sh_mat.set_shader_parameter("modelColor", base_color)
		sh_mat.set_shader_parameter("wireframeColor", wireframe_color)
		sh_mat.set_shader_parameter("emissionColor", wireframe_color)
		sh_mat.set_shader_parameter("width", 1.0)
		sh_mat.set_shader_parameter("blur", 1.0)
		sh_mat.set_shader_parameter("emission_strength", emission_strength)
		sh_mat.set_shader_parameter("modelOpacity", 1.0)
		sh_mat.set_shader_parameter("wireframeOpacity", 1.0)
		sh_mat.set_shader_parameter("globalOpacity", 1.0)
		sh_mat.set_shader_parameter("show_interior", show_interior)
		_mesh_instance.material_override = sh_mat
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = base_color
		fallback.roughness = 0.4
		_mesh_instance.material_override = fallback
	add_child(_mesh_instance)


func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance and _mesh_instance.material_override is ShaderMaterial:
		(_mesh_instance.material_override as ShaderMaterial).set_shader_parameter("modelColor", base_color)


## Called by the grid system. Keys honoured:
##   "radius"           — float, sphere radius
##   "size"             — float, alias for diameter (radius = size/2)
##   "color"            — Color or [r,g,b] array, fill colour
##   "wireframe_color"  — Color or [r,g,b] array, grid-line colour
##   "radial_segments"  — int, ≥ 3
##   "rings"            — int, ≥ 2
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("radius"):
		radius = float(config_data["radius"]); dirty = true
	if config_data.has("size"):
		radius = float(config_data["size"]) * 0.5; dirty = true
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			base_color = c
		elif c is Array and c.size() >= 3:
			base_color = Color(float(c[0]), float(c[1]), float(c[2]))
		dirty = true
	if config_data.has("wireframe_color"):
		var w = config_data["wireframe_color"]
		if w is Color:
			wireframe_color = w
		elif w is Array and w.size() >= 3:
			wireframe_color = Color(float(w[0]), float(w[1]), float(w[2]))
		dirty = true
	if config_data.has("radial_segments"):
		radial_segments = max(3, int(config_data["radial_segments"])); dirty = true
	if config_data.has("rings"):
		rings = max(2, int(config_data["rings"])); dirty = true
	if dirty and _mesh_instance:
		_build_sphere()
