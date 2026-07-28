extends Node3D
class_name SolLewittWallDrawing

# @identity
# essence: a white wall with a drawing on it and the sentence that made the drawing hung beside it, at the same height, in the same frame family — certificate and execution refusing to be separated
# desire: to stop conceptual art being a story told about an object, and put the generating sentence in the room where the marks are, so a viewer can read the rule and then check it against the wall
# critical_parameter: draft_seed — the instruction fixes what is drawn, the seed fixes this drawing of it; two placements of corner_lines converge on different points and neither is the definitive version, because there is no definitive version
# triggers: _ready() picks an instruction from INSTRUCTIONS, seeds a RandomNumberGenerator with draft_seed, executes the sentence as segment geometry on the plaster panel, and bakes the sentence itself onto the certificate screen at the right
# emerges: the gap between rule and result becomes visible rather than described — the text is short, the wall is dense, and the distance between them is the work
# needs: BoxMesh segments [Godot built-in, one shared near-black material for hundreds of strips]; Grid.gdshader [present] for frame and plinth; TextScreen SCREEN mode [present] for the certificate; RandomNumberGenerator seeded, never randomize()
# relationships: the instruction end of the artmathematics room — vera_molnar_des_ordres holds the same argument with a continuous knob instead of a sentence, and bridget_riley_op_art drops the rule entirely and keeps only the retinal event
# truth: LeWitt sold the sentence, not the wall. The drafter is not an interpreter of the work, the drafter is where the work happens — which means every faithful execution is a different picture and none of them is a copy.

## Sol LeWitt wall drawing. A plastered panel carrying line geometry generated
## from a written instruction, with that instruction displayed beside it. Three
## canonical instructions; a seed varies the execution without varying the rule.

@export_enum("corner_lines", "not_straight_band", "points_connected") var instruction: String = "corner_lines"
@export var draft_seed: int = 4601
@export var rays_per_corner: int = 9      # corner_lines: lines each corner emits
@export var band_lines: int = 16          # not_straight_band: lines inside the band
@export var point_count: int = 14         # points_connected: points placed at random

const INSTRUCTIONS: PackedStringArray = ["corner_lines", "not_straight_band", "points_connected"]

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# The certificate. Title, then the sentence exactly as it is executed below.
const CERTIFICATES := {
	"corner_lines": [
		"WALL DRAWING",
		"Lines from each corner\nof the wall drawn toward\na common point.",
	],
	"not_straight_band": [
		"WALL DRAWING",
		"Not-straight lines from\nthe left edge to the right\nedge, within a band.",
	],
	"points_connected": [
		"WALL DRAWING",
		"Points placed at random,\nevenly distributed. All of\nthe points connected by\nstraight lines.",
	],
}

const PANEL_W := 1.16          # the plastered field, metres
const PANEL_H := 1.44
const PANEL_Y := 1.02          # centre height of the field
const PANEL_X := -0.34         # the drawing sits left of centre; the text sits right
const LINE_W := 0.005          # drafted line width
const BASE_W := 1.94

var _built := false
var _created: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _ink: Material = null


func _ready() -> void:
	_build_all()
	_built = true


## Parent a node we made, and remember we made it — so a rebuild frees our own
## geometry and never the label plates or tag markers the grid adds after us.
func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	instruction = _pick(instruction, INSTRUCTIONS, "corner_lines")
	_rng.seed = draft_seed
	_ink = _flat_material(Color(0.09, 0.09, 0.11))

	_build_plinth()
	var field := _build_panel()
	match instruction:
		"corner_lines":
			_draw_corner_lines(field)
		"not_straight_band":
			_draw_not_straight_band(field)
		"points_connected":
			_draw_points_connected(field)
		_:
			_draw_corner_lines(field)
	_build_certificate()


# --- the wall ---------------------------------------------------------------

func _build_plinth() -> void:
	var base := MeshInstance3D.new()
	base.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(BASE_W, 0.07, 0.30)
	base.mesh = box
	base.position = Vector3(0.0, 0.035, 0.0)
	base.material_override = _grid_material(Color(0.28, 0.30, 0.35), Color(0.45, 0.50, 0.60), 0.5)
	_own(base)


## The plastered field, plus a slim frame behind it. Returns the node that
## drawing segments are parented to: local x/y are panel coordinates in metres,
## origin at the centre of the field.
func _build_panel() -> Node3D:
	var holder := Node3D.new()
	holder.name = "Field"
	holder.position = Vector3(PANEL_X, PANEL_Y, 0.0)
	_own(holder)

	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(PANEL_W + 0.06, PANEL_H + 0.06, 0.05)
	frame.mesh = fbox
	frame.position = Vector3(0.0, 0.0, -0.03)
	frame.material_override = _grid_material(Color(0.26, 0.28, 0.33), Color(0.45, 0.50, 0.60), 0.4)
	holder.add_child(frame)

	var plaster := MeshInstance3D.new()
	plaster.name = "Plaster"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(PANEL_W, PANEL_H, 0.02)
	plaster.mesh = pbox
	plaster.material_override = _flat_material(Color(0.93, 0.92, 0.89))
	holder.add_child(plaster)

	var marks := Node3D.new()
	marks.name = "Marks"
	marks.position = Vector3(0.0, 0.0, 0.012)
	holder.add_child(marks)
	return marks


# --- the three instructions -------------------------------------------------

## Lines from each corner of the wall toward a common point. The point is not
## the centre — the seed puts it somewhere in the middle third, and each corner
## fans onto a small circle around it, so the bundles cross rather than meet.
func _draw_corner_lines(field: Node3D) -> void:
	var hw: float = PANEL_W * 0.5 - 0.03
	var hh: float = PANEL_H * 0.5 - 0.03
	var cx: float = _rng.randf_range(-hw * 0.34, hw * 0.34)
	var cy: float = _rng.randf_range(-hh * 0.30, hh * 0.38)
	var lens: float = _rng.randf_range(0.05, 0.17)
	var corners: Array[Vector2] = [
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	]
	var n: int = maxi(1, rays_per_corner)
	for c in corners:
		for i in range(n):
			var a: float = TAU * float(i) / float(n) + _rng.randf_range(-0.08, 0.08)
			var target := Vector2(cx + cos(a) * lens, cy + sin(a) * lens)
			_segment(field, c, target, LINE_W)
	# The common point itself, marked — the instruction names it, so the wall shows it.
	_segment(field, Vector2(cx - 0.02, cy), Vector2(cx + 0.02, cy), LINE_W * 2.2)
	_segment(field, Vector2(cx, cy - 0.02), Vector2(cx, cy + 0.02), LINE_W * 2.2)


## Not-straight lines from the left edge to the right edge, within a band. Each
## line is a random walk in y, clamped to the band, so it wanders without ever
## leaving the region the instruction allows it.
func _draw_not_straight_band(field: Node3D) -> void:
	var hw: float = PANEL_W * 0.5 - 0.04
	var band_h: float = PANEL_H * 0.52
	var band_y: float = _rng.randf_range(-PANEL_H * 0.10, PANEL_H * 0.10)
	var rows: int = maxi(2, band_lines)
	var steps: int = 16
	var wander: float = band_h / float(rows) * 0.55
	for r in range(rows):
		var base_y: float = band_y - band_h * 0.5 + band_h * (float(r) + 0.5) / float(rows)
		var y: float = base_y
		var prev := Vector2(-hw, y)
		for s in range(1, steps + 1):
			var x: float = -hw + 2.0 * hw * float(s) / float(steps)
			y += _rng.randf_range(-wander, wander)
			y = clampf(y, base_y - wander * 1.6, base_y + wander * 1.6)
			var p := Vector2(x, y)
			_segment(field, prev, p, LINE_W * 0.85)
			prev = p


## Points placed at random, evenly distributed, all connected by straight lines.
## "Evenly distributed" is honoured by jittering inside a coarse lattice rather
## than by uniform sampling — uniform sampling clumps, and LeWitt's drafters did
## not clump. Point count stays modest so the connections stay legible as lines.
func _draw_points_connected(field: Node3D) -> void:
	var hw: float = PANEL_W * 0.5 - 0.07
	var hh: float = PANEL_H * 0.5 - 0.07
	var n: int = clampi(point_count, 3, 22)
	var cols: int = maxi(1, int(ceil(sqrt(float(n)))))
	var rows: int = maxi(1, int(ceil(float(n) / float(cols))))
	var pts: Array[Vector2] = []
	var idx: int = 0
	for r in range(rows):
		for c in range(cols):
			if idx >= n:
				break
			var fx: float = (float(c) + 0.5) / float(cols)
			var fy: float = (float(r) + 0.5) / float(rows)
			var px: float = -hw + 2.0 * hw * fx + _rng.randf_range(-hw / float(cols), hw / float(cols)) * 0.7
			var py: float = -hh + 2.0 * hh * fy + _rng.randf_range(-hh / float(rows), hh / float(rows)) * 0.7
			pts.append(Vector2(clampf(px, -hw, hw), clampf(py, -hh, hh)))
			idx += 1
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			_segment(field, pts[i], pts[j], LINE_W * 0.7)
	for p in pts:
		_segment(field, p + Vector2(-0.012, 0.0), p + Vector2(0.012, 0.0), LINE_W * 2.4)


# --- drafting ---------------------------------------------------------------

## One drawn segment: a thin box lying in the panel plane, rotated to the line.
func _segment(field: Node3D, a: Vector2, b: Vector2, w: float) -> void:
	var d: Vector2 = b - a
	var l: float = d.length()
	if l < 0.0005:
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(l, w, 0.003)
	mi.mesh = box
	var mid: Vector2 = (a + b) * 0.5
	mi.position = Vector3(mid.x, mid.y, 0.0)
	mi.rotation.z = atan2(d.y, d.x)
	mi.material_override = _ink
	field.add_child(mi)


# --- the certificate --------------------------------------------------------

## The sentence, hung beside the drawing at the same height. Configure BEFORE
## add_child — TextScreen's setters rebuild only when already in-tree.
func _build_certificate() -> void:
	var entry: Array = CERTIFICATES.get(instruction, CERTIFICATES["corner_lines"])
	var ts := TextScreenScript.new()
	ts.name = "Certificate"
	ts.mode = 0                       # Mode.SCREEN — a framed panel, no post
	ts.width_m = 0.56
	ts.position = Vector3(0.60, PANEL_Y + 0.16, 0.0)
	if ts.has_method("set_text"):
		ts.set_text(str(entry[0]), str(entry[1]))
	_own(ts)

	var tag := TextScreenScript.new()
	tag.name = "Attribution"
	tag.mode = 0
	tag.width_m = 0.42
	tag.position = Vector3(0.60, PANEL_Y - 0.32, 0.0)
	if tag.has_method("set_text"):
		tag.set_text("SEED %d" % draft_seed, "this drafting of it;\nnot the drawing.")
	_own(tag)


# --- materials --------------------------------------------------------------

func _flat_material(c: Color) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.metallic = 0.0
	return m


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Accept a value only if it names something we actually draw. A typo in a map
## token lands on the shipped instruction whole rather than on a blank wall.
func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


## Grid config. Keys: "instruction", "seed", "rays", "band_lines", "points".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_instruction: String = instruction
	var before_seed: int = draft_seed
	var before_rays: int = rays_per_corner
	var before_band: int = band_lines
	var before_points: int = point_count

	if config_data.has("instruction"):
		instruction = _pick(str(config_data["instruction"]), INSTRUCTIONS, instruction)
	if config_data.has("seed"):
		draft_seed = int(config_data["seed"])
	if config_data.has("rays"):
		rays_per_corner = clampi(int(config_data["rays"]), 1, 40)
	if config_data.has("band_lines"):
		band_lines = clampi(int(config_data["band_lines"]), 2, 60)
	if config_data.has("points"):
		point_count = clampi(int(config_data["points"]), 3, 22)

	if not _built:
		return
	if (instruction == before_instruction and draft_seed == before_seed
			and rays_per_corner == before_rays and band_lines == before_band
			and point_count == before_points):
		# Nothing drawn changed. Curation passes hand every artifact unrelated
		# keys one line after framing it; rebuilding here would throw that away.
		return

	_rebuild_now()
	print("[SolLewittWallDrawing] instruction=%s seed=%d" % [instruction, draft_seed])
