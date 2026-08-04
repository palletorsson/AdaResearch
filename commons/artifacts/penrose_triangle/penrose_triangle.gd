# @identity
# essence: 3 bars, 3 right angles, each corner coherent, the whole impossible -- visual Goedel in 3D
# desire: a triangle that looks correct from one viewpoint but is geometrically impossible in 3-space
# critical_parameter: disclosure -- how much the object confesses; _is_at_sweet_spot -- whether the viewer stands where illusion coheres
# triggers: player position relative to sweet spot; indicator shows when the impossible view aligns
# emerges: local validity does not guarantee global consistency -- the triangle knows what formal systems learned
# needs: bar meshes [has]; sweet spot detection [has]; info label [has]; VR viewpoint tracking [missing]
# relationships: paired with escher_staircase (impossible objects family); feeds Dark_Room_Paradox
# truth: each corner is valid, the object is not -- incompleteness you can hold in your hands.

# penrose_triangle.gd
# The impossible triangle - locally coherent, globally impossible
# A 3D construction that only "works" from specific viewpoints

extends Node3D

class_name PenroseTriangle

signal viewpoint_locked
signal illusion_revealed

@export var size: float = 0.5
@export var bar_thickness: float = 0.08
@export var auto_rotate: bool = false
@export var rotation_speed: float = 0.2
@export var show_sweet_spot: bool = true

## DNA axis — how much the object gives away about its own contradiction.
## Not a styling knob: it is the ladder a formal system can climb when it meets
## a sentence it cannot settle. Conceal it, point at it, mark it, take the
## machine apart, or close the joint by fiat and call the problem solved.
##   marker   — the joint is broken and a bead floats at the one viewpoint from
##              which it looks whole. The trick is hidden AND advertised.
##   bare     — same broken joint, no bead, no caption. Find it yourself.
##   seam     — the failing joint is capped in hot emissive: the break is legible
##              from every angle, so no viewpoint can launder it.
##   exploded — the three beams slide apart. Each is still locally valid; there
##              is no longer any whole for them to be inconsistent about.
##   sealed   — z_gap = 0, the beams actually meet. A possible triangle. The
##              contradiction removed by adding the axiom that says it isn't one.
@export_enum("marker", "bare", "seam", "exploded", "sealed") var disclosure: String = "marker"

## The same list as the @export_enum above, written twice on purpose: the enum is
## what the editor and the declaration gate read, this is what a map token's
## string is checked against before it can reach the build.
const DISCLOSURES: Array[String] = ["marker", "bare", "seam", "exploded", "sealed"]

var _bars: Array[MeshInstance3D] = []
var _sweet_spot_indicator: MeshInstance3D
var _info_label: Label3D
var _is_at_sweet_spot: bool = false
var _built: bool = false

func _ready():
	_build()

func _build() -> void:
	_create_impossible_triangle()
	# `bare` is the value that says nothing, so it gets no caption either.
	if disclosure != "bare":
		_create_info_label()
	if show_sweet_spot:
		_create_sweet_spot_indicator()
	_built = true

func _create_impossible_triangle():
	# Penrose triangle: three beams along the edges of an equilateral triangle.
	# One joint has a Z-offset so the triangle can't close in 3D,
	# but from the sweet-spot viewpoint it appears to form a closed shape.

	var h = size * 0.866  # sqrt(3)/2
	var half = size * 0.5

	# Three vertices of an equilateral triangle in XY plane
	var v_bl = Vector3(-half, -h / 3.0, 0)       # bottom-left
	var v_br = Vector3( half, -h / 3.0, 0)       # bottom-right
	var v_top = Vector3(0, h * 2.0 / 3.0, 0)     # top-center

	# Z-offset at top-center to create the impossible gap.
	# `sealed` sets it to zero: the beams meet, the object becomes possible, and
	# the whole argument quietly evaporates. Every other value keeps the gap.
	var z_gap: float = 0.0 if disclosure == "sealed" else size * 0.25
	var v_top_back = Vector3(v_top.x, v_top.y, -z_gap)

	var mat_a = StandardMaterial3D.new()
	mat_a.albedo_color = Color(0.85, 0.78, 0.65)
	mat_a.metallic = 0.35
	mat_a.roughness = 0.5

	var mat_b = mat_a.duplicate()
	mat_b.albedo_color = Color(0.72, 0.65, 0.55)

	var mat_c = mat_a.duplicate()
	mat_c.albedo_color = Color(0.6, 0.55, 0.48)

	# `exploded` slides each beam straight out from the centroid along its own
	# outward normal. Nothing about any single beam changes — that is the point.
	var spread: float = size * 0.28 if disclosure == "exploded" else 0.0

	# Bar 1 — bottom edge: bottom-left → bottom-right
	_add_beam(v_bl, v_br, mat_a, spread)

	# Bar 2 — right edge: bottom-right → top-back
	_add_beam(v_br, v_top_back, mat_b, spread)

	# Bar 3 — left edge: top-front → bottom-left
	_add_beam(v_top, v_bl, mat_c, spread)

	# `seam` caps both ends of the joint that cannot close, so the break reads
	# from any angle instead of only from the ones the bead does not name.
	if disclosure == "seam":
		_add_joint_cap(v_top)
		_add_joint_cap(v_top_back)

func _add_beam(from: Vector3, to: Vector3, mat: StandardMaterial3D, spread: float = 0.0) -> void:
	var diff = to - from
	var length = diff.length()
	if length < 0.001:
		return

	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bar_thickness, bar_thickness, length)
	mesh_instance.mesh = box
	mesh_instance.material_override = mat

	# Position at midpoint, rotate to align Z-axis with from→to direction
	var mid: Vector3 = (from + to) * 0.5
	mesh_instance.position = mid
	mesh_instance.look_at_from_position(mid, to, Vector3.UP)

	# Offset AFTER the look_at, so the beam keeps its original bearing and only
	# its station moves — a dismantled triangle, not a differently-bent one.
	if spread > 0.0:
		var out_dir: Vector3 = Vector3(mid.x, mid.y, 0.0)
		if out_dir.length() > 0.0001:
			mesh_instance.position = mid + out_dir.normalized() * spread

	add_child(mesh_instance)
	_bars.append(mesh_instance)

func _add_joint_cap(at: Vector3) -> void:
	var cap := MeshInstance3D.new()
	var box := BoxMesh.new()
	var s: float = bar_thickness * 1.7
	box.size = Vector3(s, s, s)
	cap.mesh = box
	cap.position = at

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.32, 0.18)
	mat.metallic = 0.1
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.38, 0.16)
	mat.emission_energy_multiplier = 1.4
	cap.material_override = mat

	add_child(cap)
	_bars.append(cap)

func _create_info_label():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.001
	_info_label.font_size = 14
	_info_label.text = "PENROSE TRIANGLE\nLocally coherent\nGlobally impossible"
	_info_label.position = Vector3(0, -size * 0.8, 0)
	_info_label.modulate = Color(0.8, 0.8, 0.8)
	add_child(_info_label)

func _create_sweet_spot_indicator():
	_sweet_spot_indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	_sweet_spot_indicator.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.3, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.3)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sweet_spot_indicator.material_override = mat
	
	# Position where the illusion works best
	_sweet_spot_indicator.position = Vector3(0, 0, size * 2.5)

	# Only `marker` actually shows the bead. The others keep the mesh and hide
	# the instance with layers = 0 rather than dropping it: this node sits 2.5
	# sizes out on +Z and is what the capture AABB is measured from, so removing
	# it for four values out of five would reframe those four and the critic
	# would be scoring a zoom change. layers = 0 is per-instance, does not
	# propagate, and leaves mesh and material untouched.
	if disclosure != "marker":
		_sweet_spot_indicator.layers = 0
	add_child(_sweet_spot_indicator)

func _process(delta):
	if auto_rotate:
		rotation.y += delta * rotation_speed

func check_viewer_position(viewer_pos: Vector3) -> bool:
	# Check if viewer is near the sweet spot where illusion works
	var local_pos = to_local(viewer_pos)
	var sweet_spot = Vector3(0, 0, size * 2.5)
	var distance = local_pos.distance_to(sweet_spot)
	
	var was_at_sweet_spot = _is_at_sweet_spot
	_is_at_sweet_spot = distance < size * 0.5
	
	if _is_at_sweet_spot and not was_at_sweet_spot:
		viewpoint_locked.emit()
		# `bare` builds no label. The signal still fires; there is just nothing
		# on the object willing to say so.
		if is_instance_valid(_info_label):
			_info_label.text = "ILLUSION ACTIVE\nFrom here, it looks possible"
	elif not _is_at_sweet_spot and was_at_sweet_spot:
		illusion_revealed.emit()
		if is_instance_valid(_info_label):
			_info_label.text = "PENROSE TRIANGLE\nLocally coherent\nGlobally impossible"

	return _is_at_sweet_spot

func normalise_disclosure(raw: String, fallback: String) -> String:
	# An unknown string keeps what we had. A map that mistypes a value gets the
	# object it already had rather than a silent fallback to the default, which
	# would look like the axis working while reporting nothing.
	return raw if raw in DISCLOSURES else fallback

func apply_grid_config(config_data: Dictionary):
	var before: String = disclosure
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	disclosure = normalise_disclosure(disclosure, before)
	# Rebuild ONLY when the axis actually moved, and never before _ready has
	# built once: an unguarded rebuild here would tear down every shipped
	# placement's geometry on a config call that changed nothing.
	if disclosure == before or not _built:
		return
	_rebuild()

func _rebuild() -> void:
	for n in _bars:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_bars.clear()
	for extra in [_sweet_spot_indicator, _info_label]:
		if is_instance_valid(extra):
			if extra.get_parent() != null:
				extra.get_parent().remove_child(extra)
			extra.queue_free()
	_sweet_spot_indicator = null
	_info_label = null
	_is_at_sweet_spot = false
	_build()
	print("PenroseTriangle: disclosure=%s" % disclosure)
