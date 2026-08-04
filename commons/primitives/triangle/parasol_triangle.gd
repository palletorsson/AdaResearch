# @identity
# essence: triangle(elevated) + cylinder(stick) — a triangle raised on a pole like a parasol
# desire: to make triangles visible from across the room — a flag, a marker, an invitation
# critical_parameter: sidedness — whether the two faces are painted differently at all, which is the only way a flat sheet can say which way it faces; under it convention (normal / winding), the notation the claim is written in. Then stick_height / triangle_scale — the parasol must read as "triangle on a stick" instantly
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

# ── STAGE-2 DNA — promoted 2026-08-03 ─────────────────────────────────
#
# The parasol was already making an argument and could only ever make it one
# way. A triangle is three points in an order, and that order is the ONLY thing
# that gives a flat sheet a front and a back. The shipped object states that
# fact by painting the two sides different colours — pink toward you, blue
# away — and hard-codes both the statement and the notation it is written in.
#
# `sidedness` — what the surface claims about its two faces.
#
#   two_tone  the shipped parasol. Pink front, blue back: the winding order
#             made legible as colour. Walk round it and the flag changes
#             identity, which is the whole lesson.
#   flat      one colour on both faces, and not the pink either — a plain
#             uncoloured sheet. The claim is withdrawn entirely: this is what a
#             triangle looks like when nobody has decided which way it faces,
#             and it is the honest opposite of the artifact's own thesis.
#   inverted  blue front, pink back. The same claim with the convention
#             reversed. Nothing about the geometry moved; only the naming did,
#             which is the point — front and back are a convention, not a
#             property of the plane.
#   split     the two colours meet on ONE face, along the median from apex to
#             base. Facing becomes readable without walking around: the flag
#             carries both of its terms at once and stops being a secret you
#             have to circle to learn.
@export_enum("two_tone", "flat", "inverted", "split") var sidedness: String = "two_tone"

# `convention` — which orientation notation the triangle draws on itself.
#
# Graphics states "which way does this face point" twice, in two incompatible
# languages: the surface NORMAL (a vector standing off the face) and the
# WINDING order (the direction you travel the rim, v0 -> v1 -> v2). They encode
# the same fact and neither is derivable by looking. The shipped parasol draws
# neither and asks you to take the colour on faith.
#
#   none      the shipped parasol. No annotation; the colour is the only tell.
#   normal    an arrow standing off the front face — the vector notation.
#   winding   three arrowheads riding the edges in vertex order — the rim
#             notation, which is what actually produced the two colours.
#   both      both drawn at once, so the two languages can be compared.
@export_enum("none", "normal", "winding", "both") var convention: String = "none"

## The same lists as the @export_enum lines above. The enums are what the editor
## and the declaration gate read; these are what an incoming map token is
## checked against, so a typo falls back instead of building nothing.
const SIDEDNESS_VALUES: Array[String] = ["two_tone", "flat", "inverted", "split"]
const CONVENTION_VALUES: Array[String] = ["none", "normal", "winding", "both"]

## The colour a face wears when the parasol declines to declare a side.
const FLAT_COLOR: Color = Color(0.86, 0.86, 0.88)

var _stick: MeshInstance3D = null
var _tri_mesh: MeshInstance3D = null
var _built: bool = false


func _ready() -> void:
	_build()


func _build() -> void:
	_build_stick()
	_build_triangle()
	_built = true


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

	if sidedness == "split":
		# The two claims meet on ONE face, along the median apex -> base midpoint.
		var m: Vector3 = (v0 + v1) * 0.5
		_face(st, v0, m, v2, _front_color(), Vector3(0, 0, 1))
		_face(st, m, v1, v2, _back_color(), Vector3(0, 0, 1))
		_face(st, m, v0, v2, _front_color(), Vector3(0, 0, -1))
		_face(st, v1, m, v2, _back_color(), Vector3(0, 0, -1))
	else:
		# Front face (pink by default)
		_face(st, v0, v1, v2, _front_color(), Vector3(0, 0, 1))
		# Back face (blue by default) — reversed winding
		_face(st, v1, v0, v2, _back_color(), Vector3(0, 0, -1))

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

	if convention != "none":
		_build_convention_marks(v0, v1, v2)


## One flat-shaded triangle, colour and normal set once for the three vertices —
## the exact call order the shipped build used.
func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, n: Vector3) -> void:
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _front_color() -> Color:
	match sidedness:
		"flat":
			return FLAT_COLOR
		"inverted":
			return triangle_color_back
	return triangle_color_front


func _back_color() -> Color:
	match sidedness:
		"flat":
			return FLAT_COLOR
		"inverted":
			return triangle_color_front
	return triangle_color_back


## The orientation notation, drawn as geometry on the triangle's own plane.
## Children of _tri_mesh so they inherit the tilt and the parasol's height.
func _build_convention_marks(v0: Vector3, v1: Vector3, v2: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.98)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.1
	mat.roughness = 0.4

	if convention == "normal" or convention == "both":
		_build_normal_arrow(v0, v1, v2, mat)
	if convention == "winding" or convention == "both":
		_build_winding_arrows(v0, v1, v2, mat)


## The vector notation: an arrow standing off the front face at the centroid.
## CylinderMesh points along +Y; +90 degrees about X sends that to +Z, which is
## the front normal the surface already declares.
func _build_normal_arrow(v0: Vector3, v1: Vector3, v2: Vector3, mat: StandardMaterial3D) -> void:
	var centroid: Vector3 = (v0 + v1 + v2) / 3.0
	var shaft_len: float = triangle_size * 0.55
	var head_len: float = triangle_size * 0.25
	var r: float = triangle_size * 0.028

	var shaft := MeshInstance3D.new()
	shaft.name = "NormalShaft"
	var sc := CylinderMesh.new()
	sc.top_radius = r
	sc.bottom_radius = r
	sc.height = shaft_len
	sc.radial_segments = 8
	shaft.mesh = sc
	shaft.material_override = mat
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.position = centroid + Vector3(0, 0, shaft_len * 0.5)
	_tri_mesh.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "NormalHead"
	var hc := CylinderMesh.new()
	hc.top_radius = 0.0
	hc.bottom_radius = r * 2.6
	hc.height = head_len
	hc.radial_segments = 8
	head.mesh = hc
	head.material_override = mat
	head.rotation_degrees = Vector3(90, 0, 0)
	head.position = centroid + Vector3(0, 0, shaft_len + head_len * 0.5)
	_tri_mesh.add_child(head)


## The rim notation: an arrowhead on each edge, riding v0 -> v1 -> v2, which is
## the traversal that decided which face is the front in the first place.
func _build_winding_arrows(v0: Vector3, v1: Vector3, v2: Vector3, mat: StandardMaterial3D) -> void:
	var pts: Array[Vector3] = [v0, v1, v2]
	for i in range(pts.size()):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var mid: Vector3 = (a + b) * 0.5
		var dir: Vector3 = (b - a).normalized()

		var head := MeshInstance3D.new()
		head.name = "WindingArrow%d" % i
		var hc := CylinderMesh.new()
		hc.top_radius = 0.0
		hc.bottom_radius = triangle_size * 0.055
		hc.height = triangle_size * 0.18
		hc.radial_segments = 8
		head.mesh = hc
		head.material_override = mat
		head.position = mid + Vector3(0, 0, triangle_size * 0.03)
		# Cone tip is +Y; a spin about Z sends +Y to (-sin, cos), so this aims it
		# along the edge without touching the plane it lies in.
		head.rotation = Vector3(0.0, 0.0, atan2(-dir.x, dir.y))
		_tri_mesh.add_child(head)


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Contract: this runs AFTER _ready(), deferred from GridInteractablesComponent.
##
## The pre-promotion body set four floats and rebuilt nothing, so a `height`,
## `size`, `tilt` or `color` key has never once changed a placed parasol. That
## stays exactly true: only a DNA axis that ACTUALLY MOVES triggers a rebuild,
## and none of the eight placements passes any config key at all.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("height"):
		stick_height = float(config_data["height"])
	if config_data.has("size"):
		triangle_size = float(config_data["size"])
	if config_data.has("tilt"):
		triangle_tilt = float(config_data["tilt"])
	if config_data.has("color"):
		var c := Color(config_data["color"])
		triangle_color_front = c

	if config_data.has("sidedness"):
		var s: String = _pick_axis(str(config_data["sidedness"]), SIDEDNESS_VALUES, sidedness)
		if s != sidedness:
			sidedness = s
			changed = true
	if config_data.has("convention"):
		var k: String = _pick_axis(str(config_data["convention"]), CONVENTION_VALUES, convention)
		if k != convention:
			convention = k
			changed = true

	if not changed:
		return
	if not _built:
		return   # _ready has not run yet; it will build with these values.

	for child in get_children():
		remove_child(child)
		child.queue_free()
	_stick = null
	_tri_mesh = null
	_built = false
	_build()
