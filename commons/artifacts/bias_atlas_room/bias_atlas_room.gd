extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BiasAtlasRoom

## @identity
## name: Bias Atlas Room
## truth: Bias is the shape of what it cannot see.
##
## Bias as structural incompleteness — LARGE, room-scale (~7x7 floor y=-0.05).
## A floor atlas of a model's input space: lit cells (territory the system
## sees and classifies) and dark EXCLUDED territories (whole classes it misses).
## The excluded regions are labelled out loud. Slate pillars frame the map;
## a purple wireframe grid floats over it. Overhead constructive title.

@export var grid_n: int = 14               # atlas grid resolution (n x n)
@export var floor_extent: float = 6.4      # atlas covers most of the 7x7 room
@export var reveal_speed: float = 0.25     # how fast the seen/unseen boundary breathes

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.34, 0.38, 0.48)
const PURPLE := Color(0.58, 0.42, 0.92)
const SEE_TEAL := Color(0.28, 0.80, 0.76)
const SEE_BLUE := Color(0.40, 0.56, 0.95)
const EXCLUDED := Color(0.05, 0.05, 0.09)
const AMBER := Color(0.98, 0.72, 0.28)

var _cell_mm: MultiMeshInstance3D = null
var _cell_seen: Array[bool] = []
var _cell_pos: Array[Vector3] = []
var _grid_floats: Array[MeshInstance3D] = []
var _scan_marker: MeshInstance3D = null
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_cell_seen.clear()
	_cell_pos.clear()
	_grid_floats.clear()

	# --- Room floor (cool/formal slate slab) -------------------------------
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.9)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7.0, 0.08, 7.0), floor_mat))

	# Define the excluded territories (the classes the model misses) as
	# axis regions of the atlas. These are the "shape it cannot see".
	var blind_regions: Array = [
		Rect2(0.62, 0.0, 0.38, 0.34),   # NE corner class — unrepresented
		Rect2(0.0, 0.70, 0.30, 0.30),   # SW corner class — unrepresented
		Rect2(0.40, 0.42, 0.22, 0.22),  # central pocket — under-sampled
	]

	# --- Atlas cells via MultiMesh ----------------------------------------
	_cell_mm = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cell_box := BoxMesh.new()
	var cell_w: float = floor_extent / float(grid_n)
	cell_box.size = Vector3(cell_w * 0.9, 0.04, cell_w * 0.9)
	mm.mesh = cell_box
	mm.instance_count = grid_n * grid_n
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.emission_enabled = true
	cm.emission_energy_multiplier = 1.4 if emissive else 0.0
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_cell_mm.material_override = cm
	_cell_mm.multimesh = mm

	var idx: int = 0
	for gz in range(grid_n):
		for gx in range(grid_n):
			var u: float = float(gx) / float(grid_n - 1)
			var v: float = float(gz) / float(grid_n - 1)
			var seen: bool = true
			for region in blind_regions:
				var rr: Rect2 = region
				if rr.has_point(Vector2(u, v)):
					seen = false
					break
			var x: float = (u - 0.5) * floor_extent
			var z: float = (v - 0.5) * floor_extent
			var p := Vector3(x, -0.02, z)
			_cell_pos.append(p)
			_cell_seen.append(seen)
			mm.set_instance_transform(idx, Transform3D(Basis(), p))
			if seen:
				var base: Color = SEE_TEAL if (gx + gz) % 2 == 0 else SEE_BLUE
				mm.set_instance_color(idx, base)
			else:
				mm.set_instance_color(idx, EXCLUDED)
			idx += 1
	add_child(_cell_mm)

	# Set the excluded cells slightly recessed (dark holes in the map).
	for i in range(_cell_pos.size()):
		if not _cell_seen[i]:
			var t: Transform3D = mm.get_instance_transform(i)
			t.origin.y = -0.05
			mm.set_instance_transform(i, t)

	# --- Floating purple wireframe grid (formal coordinate frame) ----------
	var wire_mat: StandardMaterial3D = _glow_mat(PURPLE, 1.2)
	var lines: int = 8
	for i in range(lines + 1):
		var f: float = float(i) / float(lines)
		var off: float = (f - 0.5) * floor_extent
		add_child(_box(Vector3(off, 1.4, 0), Vector3(0.018, 0.018, floor_extent), wire_mat))
		add_child(_box(Vector3(0, 1.4, off), Vector3(floor_extent, 0.018, 0.018), wire_mat))

	# --- Slate frame pillars at corners ------------------------------------
	var pillar_mat: StandardMaterial3D = _steel_mat(SLATE)
	var hx: float = floor_extent * 0.5 + 0.2
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_cylinder(Vector3(hx * sx, 1.25, hx * sz), 0.08, 2.5, pillar_mat))
			add_child(_sphere(Vector3(hx * sx, 2.55, hx * sz), 0.10, _glow_mat(COOL_WHITE, 1.0)))

	# --- Label the excluded territories out loud ---------------------------
	var labels: Array = [
		["UNSEEN CLASS A", blind_regions[0]],
		["UNSEEN CLASS B", blind_regions[1]],
		["UNDER-SAMPLED", blind_regions[2]],
	]
	for entry in labels:
		var label_text: String = entry[0]
		var rr: Rect2 = entry[1]
		var cu: float = rr.position.x + rr.size.x * 0.5
		var cv: float = rr.position.y + rr.size.y * 0.5
		var lx: float = (cu - 0.5) * floor_extent
		var lz: float = (cv - 0.5) * floor_extent
		add_child(_billboard_label(label_text, Vector3(lx, 0.9, lz), 20, AMBER))
		# Amber stake marking the named exclusion — constructive: built-around.
		add_child(_cylinder(Vector3(lx, 0.45, lz), 0.02, 0.9, _glow_mat(AMBER, 1.6)))

	# --- A roving scan marker tracing the seen/unseen boundary -------------
	_scan_marker = _sphere(Vector3(0, 0.3, 0), 0.12, _glow_mat(SEE_TEAL, 2.0))
	add_child(_scan_marker)

	# --- Overhead title ----------------------------------------------------
	add_child(_billboard_label("BIAS IS THE SHAPE OF WHAT IT CANNOT SEE", Vector3(0, 3.6, 0), 44, COOL_WHITE))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Seen cells breathe (active classification); excluded cells stay dark/recessed.
	if _cell_mm != null and _cell_mm.multimesh != null:
		var mm: MultiMesh = _cell_mm.multimesh
		for i in range(_cell_pos.size()):
			if _cell_seen[i]:
				var phase: float = _cell_pos[i].x * 0.5 + _cell_pos[i].z * 0.5 + _t * 1.4
				var lift: float = 0.02 + 0.02 * (0.5 + 0.5 * sin(phase))
				var t: Transform3D = mm.get_instance_transform(i)
				t.origin.y = -0.02 + lift
				mm.set_instance_transform(i, t)

	# Scan marker orbits the floor on the edge of an excluded zone.
	if _scan_marker != null:
		var a: float = _t * 0.6
		var rad: float = floor_extent * 0.34
		_scan_marker.position = Vector3(cos(a) * rad, 0.32 + 0.08 * sin(_t * 2.0), sin(a) * rad)
