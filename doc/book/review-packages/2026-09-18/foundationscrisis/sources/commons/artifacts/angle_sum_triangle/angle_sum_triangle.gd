# angle_sum_triangle.gd
# Demonstrates that triangle angles sum to 180° (in Euclidean space)

extends Node3D
class_name AngleSumTriangle

# @identity
# essence: α + β + γ = 180° (Euclidean angle sum theorem)
# desire: see the number 180 emerge from three vertices — the axiom made spatial
# critical_parameter: curvature — at K=0 the sum is exactly 180°; any deviation breaks it
# triggers: static display; presence alone teaches
# emerges: the realization that this "obvious" fact depends on the parallel postulate
# needs: VR controls [missing] — could add draggable vertices to explore angle sum changes
# relationships: contrasts hyperbolic_surface (angle sum < 180°) and elliptic_surface (angle sum > 180°); depends on euclid_postulates_plaque
# truth: the angle sum of a triangle is not a fact about triangles but a fact about the space they inhabit

# --- DNA (stage 2, promoted 2026-08-05) --------------------------------------
# opening: WHICH SPACE the triangle is drawn in. This artifact's own truth line
#   says "the angle sum of a triangle is not a fact about triangles but a fact
#   about the space they inhabit", and its critical_parameter is named as
#   curvature — yet the only space it could ever draw was the flat one, three
#   straight segments and a hard-coded "= 180°". The theorem's failure was
#   described in the description field and nowhere in the geometry.
#     flat        — three straight chords, sum exactly 180° (what this always drew).
#     hyperbolic  — the edges bow INWARD, a saddle triangle; the angles close and
#                   the sum falls under 180°.
#     elliptic    — the edges bow OUTWARD, a sphere triangle; the angles open and
#                   the sum climbs over 180°.
#   The word and the three values are curvature_slider's, in its order. That is
#   the honest test of the shared vocabulary here: curvature_slider states the
#   sign of K on a dial, this states what the sign DOES to a triangle, and a room
#   holding both should not be able to set them to disagreeing spaces. (Note the
#   corpus carries a second, unrelated `opening` — agreement_gauge's
#   agreeing|strangers|opposing|parallel, the angle between two vectors. The
#   value lists tell them apart; this one is the curvature list.)
#
# NOT AN AXIS, and worth recording: the three labels read 60° each while the
#   triangle as drawn is isoceles — its measured angles are 53.1 / 63.4 / 63.4,
#   which do sum to 180. The shipped strings are nominal, not measured. They are
#   preserved to the byte at `flat` because three maps ship them; the curved
#   values print angles MEASURED off the polyline they actually draw.
const OPENING_VALUES: Array = ["flat", "hyperbolic", "elliptic"]
# Sagitta as a fraction of each chord. 0.06 puts the elliptic sum near 260° and
# the hyperbolic near 100° — both legal (a sphere triangle runs to 540°, a
# hyperbolic one down to 0°) and both far enough from straight to read in a still.
const SAGITTA_RATIO: float = 0.06
const ARC_SEGMENTS: int = 14

@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
@export var size: float = 0.4
var _triangle: MeshInstance3D
var _angle_labels: Array[Label3D] = []
var _sum_label: Label3D
var _built: bool = false

func _ready():
	_build()
	_built = true

func _build() -> void:
	var pts: Array[Vector3] = _polyline()
	_create_triangle(pts)
	_create_labels(pts)

## The three corners. Unchanged from the shipped literals — the curvature bows
## the EDGES between them, it does not move the vertices.
func _vertices() -> Array[Vector3]:
	var v: Array[Vector3] = []
	v.append(Vector3(0, size * 0.5, 0))
	v.append(Vector3(-size * 0.4, -size * 0.3, 0))
	v.append(Vector3(size * 0.4, -size * 0.3, 0))
	return v

func _bow_sign() -> float:
	match opening:
		"elliptic":
			return 1.0
		"hyperbolic":
			return -1.0
	return 0.0

## The closed polyline actually drawn: the three corners, plus arc points along
## each edge when the space is curved. At `flat` the bow is zero and this
## SHORT-CIRCUITS to exactly the three shipped vertices, so the mesh handed to
## ImmediateMesh is the one that shipped, vertex for vertex.
func _polyline() -> Array[Vector3]:
	var verts: Array[Vector3] = _vertices()
	var pts: Array[Vector3] = []
	var s: float = _bow_sign() * SAGITTA_RATIO
	var centroid: Vector3 = (verts[0] + verts[1] + verts[2]) / 3.0
	for i in range(3):
		var a: Vector3 = verts[i]
		var b: Vector3 = verts[(i + 1) % 3]
		pts.append(a)
		if is_zero_approx(s):
			continue
		var mid: Vector3 = (a + b) * 0.5
		var outward: Vector3 = mid - centroid
		if outward.length() < 0.0001:
			outward = Vector3.UP
		outward = outward.normalized()
		var chord: float = a.distance_to(b)
		for j in range(1, ARC_SEGMENTS):
			var t: float = float(j) / float(ARC_SEGMENTS)
			var bulge: float = 4.0 * t * (1.0 - t) * s * chord
			pts.append(a.lerp(b, t) + outward * bulge)
	return pts

## MEASURE the three corner angles off the drawn polyline rather than asserting
## them: at each vertex, the angle between the first segment leaving it and the
## last segment arriving — which is what a protractor laid on the picture reads.
## At `flat` this returns 53.1 / 63.4 / 63.4, and they sum to 180.
func _angles(pts: Array[Vector3]) -> Array:
	var out: Array = []
	var n: int = pts.size()
	if n < 3:
		return [0.0, 0.0, 0.0]
	var stride: int = n / 3
	for i in range(3):
		var idx: int = i * stride
		var prev: Vector3 = pts[(idx - 1 + n) % n]
		var next: Vector3 = pts[(idx + 1) % n]
		var d1: Vector3 = prev - pts[idx]
		var d2: Vector3 = next - pts[idx]
		var deg: float = 0.0
		if d1.length() > 0.00001 and d2.length() > 0.00001:
			deg = rad_to_deg(d1.normalized().angle_to(d2.normalized()))
		out.append(deg)
	return out

func _create_triangle(pts: Array[Vector3]):
	_triangle = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(pts.size()):
		im.surface_add_vertex(pts[i])
	im.surface_add_vertex(pts[0])
	im.surface_end()

	_triangle.mesh = im
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.8, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_triangle.material_override = mat
	add_child(_triangle)

func _create_labels(pts: Array[Vector3]):
	# The shipped strings, nominal rather than measured — see the DNA note above.
	# Kept to the byte at `flat` because three maps ship them.
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
	if opening != "flat":
		var meas: Array = _angles(pts)
		var a: int = int(round(meas[0]))
		var b: int = int(round(meas[1]))
		var c: int = int(round(meas[2]))
		angles = ["%d°" % a, "%d°" % b, "%d°" % c]
		# Sum the ROUNDED parts, so the equation on the label is true as printed.
		sum_text = "%d° + %d° + %d° = %d°" % [a, b, c, a + b + c]
	var positions = [Vector3(0, size * 0.55, 0.01), Vector3(-size * 0.45, -size * 0.35, 0.01), Vector3(size * 0.45, -size * 0.35, 0.01)]

	for i in range(3):
		var lbl = Label3D.new()
		lbl.text = angles[i]
		lbl.pixel_size = 0.001
		lbl.font_size = 14
		lbl.position = positions[i]
		lbl.modulate = Color(1, 0.9, 0.5)
		add_child(lbl)
		_angle_labels.append(lbl)
	
	_sum_label = Label3D.new()
	_sum_label.text = sum_text
	_sum_label.pixel_size = 0.001
	_sum_label.font_size = 12
	_sum_label.position = Vector3(0, -size * 0.6, 0)
	add_child(_sum_label)

func _rebuild() -> void:
	if _triangle != null and is_instance_valid(_triangle):
		_triangle.queue_free()
	_triangle = null
	for lbl in _angle_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_angle_labels.clear()
	if _sum_label != null and is_instance_valid(_sum_label):
		_sum_label.queue_free()
	_sum_label = null
	_build()

## Map tokens reach the DNA through here. Nothing is torn down unless a value
## this artifact owns ACTUALLY changed and _ready has already built once — the
## bare `angle_sum_triangle` tokens in every existing placement never get past
## the first line.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
			opening = want
			changed = true

	if config_data.has("size"):
		var s: float = float(config_data["size"])
		if s > 0.0 and not is_equal_approx(s, size):
			size = s
			changed = true

	if changed and _built:
		_rebuild()
