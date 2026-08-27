extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FirstShadow

## @identity
## lineage: the primitives taxonomy's Triangle rung — one triangle built by hand from
##   three vertices (ArrayMesh, the smallest surface the engine accepts), hanging over
##   a pale floor under its own spotlight, casting the room's FIRST SHADOW. Beside it,
##   a line of the same size hangs under the same light and casts nothing.
## essence: three points get an inside. A point has no extension; a line has no area;
##   the triangle is where geometry first acquires a face, a normal, and therefore a
##   shadow. The line next to it is the control experiment — dimension by dimension,
##   the shadow is the proof of surface.
## truth: three lines make the minimum enclosure — the first closed thing. The shadow
##   arrives with the face.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md).

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 52
@export var spin: float = 0.25          # rad/s — the triangle turns so its shadow breathes

var _tri: MeshInstance3D

func _ready() -> void:
	_rng.seed = seed
	_build_floor()
	_build_triangle()
	_build_line()
	_build_light()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "spin"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_tri.rotation.y += spin * delta

func _build_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(2.8, 0.06, 1.8)
	floor_mesh.mesh = fm
	floor_mesh.position = Vector3(0.0, 0.03, 0.0)
	floor_mesh.material_override = _matte_mat(Color(0.82, 0.8, 0.76), 0.9)
	add_child(floor_mesh)

func _build_triangle() -> void:
	# the smallest surface the engine accepts: three vertices, one face, by hand
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-0.3, -0.26, 0.0)
	var b := Vector3(0.3, -0.26, 0.0)
	var c := Vector3(0.0, 0.3, 0.0)
	var n := (b - a).cross(c - a).normalized()
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)
	# and the same face turned around, so the surface exists from both sides — the
	# one-sidedness lesson belongs to backface_curtain, not here
	for v in [a, c, b]:
		st.set_normal(-n)
		st.add_vertex(v)
	_tri = MeshInstance3D.new()
	_tri.mesh = st.commit()
	_tri.position = Vector3(-0.6, 1.05, 0.0)
	var mat := _glow_mat(Color(0.95, 0.6, 0.2), 0.5)
	_tri.material_override = mat
	_tri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_tri)

func _build_line() -> void:
	# the control: same span, one dimension less — a hair of a cylinder, shadowless
	var line := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.004
	lm.bottom_radius = 0.004
	lm.height = 0.62
	line.mesh = lm
	line.position = Vector3(0.7, 1.05, 0.0)
	line.rotation.z = deg_to_rad(32.0)
	line.material_override = _glow_mat(Color(0.4, 0.7, 0.95), 0.8)
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)

func _build_light() -> void:
	var light := SpotLight3D.new()
	light.light_color = Color(1.0, 0.96, 0.88)
	light.light_energy = 3.2
	light.spot_range = 4.0
	light.spot_angle = 38.0
	light.shadow_enabled = true
	light.position = Vector3(0.0, 2.5, 0.6)
	light.rotation.x = deg_to_rad(-105.0)
	add_child(light)
	var housing := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.06
	hm.bottom_radius = 0.1
	hm.height = 0.18
	housing.mesh = hm
	housing.position = light.position
	housing.rotation.x = deg_to_rad(-15.0)
	housing.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(housing)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ShadowPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.2, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("FIRST SHADOW",
			"Three points get an inside - a face, a normal, and therefore a shadow.\nThe line beside it hangs under the same light and casts nothing:\nthe shadow arrives with the surface, dimension by dimension.")
