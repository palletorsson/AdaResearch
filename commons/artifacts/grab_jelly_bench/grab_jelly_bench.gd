## @identity
## name: Grab Jelly Bench
## tier: medium
## truth: a real soft body, not a picture of one — grab a corner nub and the jelly stretches like
##        taffy, push your hand in and it dents, let go and it wobbles back. Native SoftBody3D, pinned
##        to grabbable handles: the soft body you can take hold of.
## axis: assay — what the apparatus does with a shape you just squashed (see ASSAY below).
extends Node3D
class_name GrabJellyBench

@export var emissive: bool = false
@export var jelly_size: float = 0.5
@export var jelly_color: Color = Color(0.85, 0.35, 0.55)

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]


func _ready() -> void:
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pins.clear()
	# Bench base.
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 0.2, 0.8)
	base.mesh = bm
	base.position = Vector3(0, 0.75, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.17, 0.2)
	bmat.roughness = 0.7
	base.material_override = bmat
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.25, 0.65, 0.25)
	pillar.mesh = pm
	pillar.position = Vector3(0, 0.42, 0)
	pillar.material_override = bmat
	add_child(pillar)

	# The soft jelly cube resting on the bench top (top at y=0.85).
	var s: float = jelly_size
	var cy: float = 0.85 + s * 0.5 + 0.02
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 2.0, "stiffness": 0.35, "pressure": 0.0, "damping": 0.25,
		"precision": 5, "color": jelly_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_box(s, 5)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Pin the bottom face to the world so it sits on the bench.
	_pins.append({"pos": Vector3(0, -s * 0.5, 0), "node": null})
	# Four grabbable nubs on the top corners — grab to stretch.
	var h: float = s * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var local := Vector3(sx * h, h, sz * h)
			var handle := GSB.add_handle(self, sb.to_global(local), 0.055,
				Color(0.95, 0.7, 0.25))
			_pins.append({"pos": local, "node": handle})

	add_child(_label("GRAB A CORNER — IT STRETCHES", Vector3(0, 1.7, 0)))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()

	# Pinning must happen after everything is in the tree.
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.13)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 28
	l.pixel_size = 0.0016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l


# ── ASSAY ────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with mass_spring_bench,
# energy_landscape_bench, membrane_bench, rigidity_dial_bench, abject_bench, octopus_bench
# and becoming_bench: one kit, one vocabulary, so a room of benches cannot disagree with
# itself about what a demonstration is for. The geometry below is written out longhand
# because this bench does not extend embodied_prop — it drives a native SoftBody3D and
# keeps its own primitives.
#
# THE AXIS IS ON THE APPARATUS, NEVER ON THE STARTING CONDITIONS. A soft body relaxes: five
# specimens started five different ways settle into the same shape and photograph as one
# object five times. The bench is the thing that holds still, so the bench is the thing that
# can carry a claim — and the claim is that a laboratory decides what counts as a result.
#
#   none     nothing. The specimen alone on the bench; trust the eye. The legacy lineage.
#   gauge    a graduated column and an indicator arm reaching in — the shape gets a number.
#   control  an empty reference cage on its own plinth — the shape gets a comparison.
#   chart    a plotted board standing behind it — the shape gets a history.
#   vitrine  a glass case on posts, capped and captioned — the shape gets a canon.

const ASSAY_TOP := 0.86                        # the bench working surface, family-wide
const ASSAY_READ := Color(0.98, 0.74, 0.26)    # the instrument accent: readings and ink
const ASSAY_WIRE := Color(0.55, 0.88, 0.98)    # the reference standard's cool wire


## Where this bench puts its apparatus. The bench top is the 1.1 x 0.8 slab at y = 0.85 and
## the jelly with its four corner handles owns the middle of it, so everything stands in the
## back-left and back-right margins.
func _assay_dressing() -> void:
	match assay:
		"gauge":
			_assay_gauge(Vector3(-0.47, 0.0, -0.31), 0.42, 0.85)
		"control":
			_assay_control(Vector3(0.44, ASSAY_TOP, -0.20), 0.85)
		"chart":
			_assay_chart(0.86, -0.385, 0.85)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.32, 0.0), Vector3(0.90, 0.64, 0.70))
		_:
			pass                                # "none" — the legacy lineage


## GAUGE — a graduated column standing beside the bench with a cantilever indicator arm
## reaching in over the specimen and a stylus dropping onto it. The bench stops merely
## holding a shape and starts reporting a height.
func _assay_gauge(post: Vector3, reach: float, stand_y: float) -> void:
	var steel: StandardMaterial3D = _a_mat(Color(0.42, 0.45, 0.50), 0.4, 0.6)
	var tick: StandardMaterial3D = _a_mat(Color(0.88, 0.88, 0.84), 0.5, 0.0)
	var read: StandardMaterial3D = _a_glow(ASSAY_READ, 0.95)
	var top_y: float = ASSAY_TOP + 0.58
	add_child(_a_box(Vector3(post.x, stand_y + 0.015, post.z), Vector3(0.17, 0.03, 0.17), steel))
	add_child(_a_box(Vector3(post.x, (stand_y + top_y) * 0.5, post.z),
		Vector3(0.05, maxf(top_y - stand_y, 0.05), 0.05), steel))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = ASSAY_TOP + 0.02 + float(i) * 0.045
		var tl: float = 0.085 if (i % 5) == 0 else 0.045
		add_child(_a_box(Vector3(post.x + 0.025 + tl * 0.5, ty, post.z), Vector3(tl, 0.008, 0.012),
			read if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the specimen, a
	# lit point and a stylus dropped from it.
	var ay: float = ASSAY_TOP + 0.30
	add_child(_a_box(Vector3(post.x, ay, post.z), Vector3(0.09, 0.06, 0.09),
		_a_mat(Color(0.20, 0.21, 0.25), 0.6, 0.0)))
	add_child(_a_box(Vector3(post.x + reach * 0.5 + 0.03, ay, post.z), Vector3(reach, 0.024, 0.024), read))
	add_child(_a_sphere(Vector3(post.x + reach + 0.03, ay, post.z), 0.028, read))
	add_child(_a_box(Vector3(post.x + reach + 0.03, (ay + ASSAY_TOP + 0.10) * 0.5, post.z),
		Vector3(0.012, maxf(ay - ASSAY_TOP - 0.10, 0.02), 0.012), read))
	add_child(_a_label("GAUGE", Vector3(post.x, top_y + 0.07, post.z), 11, ASSAY_READ))


## CONTROL — the reference the bench keeps beside the specimen: an empty cage at the size
## the body had before anything happened to it, on its own witness plinth. The settled
## shape stops being a thing and becomes a difference from something.
func _assay_control(at: Vector3, stand_y: float) -> void:
	var pale: StandardMaterial3D = _a_mat(Color(0.80, 0.80, 0.76), 0.6, 0.0)
	var wire: StandardMaterial3D = _a_glow(ASSAY_WIRE, 0.9)
	if at.y - stand_y > 0.05:
		add_child(_a_box(Vector3(at.x, (stand_y + at.y) * 0.5, at.z),
			Vector3(0.07, at.y - stand_y, 0.07), _a_mat(Color(0.38, 0.40, 0.45), 0.4, 0.6)))
	add_child(_a_box(Vector3(at.x, at.y + 0.02, at.z), Vector3(0.24, 0.04, 0.24), pale))
	# Twelve edges of an undeformed cube with nothing inside it.
	var s: float = 0.10
	var cy: float = at.y + 0.05 + s
	for sx in [-s, s]:
		for sz in [-s, s]:
			add_child(_a_box(Vector3(at.x + sx, cy, at.z + sz), Vector3(0.009, s * 2.0, 0.009), wire))
	for sy in [-s, s]:
		for sz in [-s, s]:
			add_child(_a_box(Vector3(at.x, cy + sy, at.z + sz), Vector3(s * 2.0, 0.009, 0.009), wire))
		for sx in [-s, s]:
			add_child(_a_box(Vector3(at.x + sx, cy + sy, at.z), Vector3(0.009, 0.009, s * 2.0), wire))
	for sx2 in [-s, s]:
		for sy2 in [-s, s]:
			for sz2 in [-s, s]:
				add_child(_a_sphere(Vector3(at.x + sx2, cy + sy2, at.z + sz2), 0.016, wire))
	add_child(_a_label("CONTROL", Vector3(at.x, cy + s + 0.09, at.z), 11, ASSAY_WIRE))


## CHART — a record board at the back of the bench carrying the settling trace: an
## oscillation that damps out onto the rest line. The bench stops showing a state and starts
## keeping a history, and what you are looking at is the END of a line that was drawn.
func _assay_chart(board_w: float, bz: float, stand_y: float) -> void:
	var board_h: float = 0.52
	var by: float = ASSAY_TOP + 0.06 + board_h * 0.5
	var frame: StandardMaterial3D = _a_mat(Color(0.26, 0.27, 0.31), 0.7, 0.0)
	var paper: StandardMaterial3D = _a_mat(Color(0.87, 0.86, 0.81), 0.85, 0.0)
	var rule: StandardMaterial3D = _a_mat(Color(0.58, 0.58, 0.54), 0.7, 0.0)
	var ink: StandardMaterial3D = _a_glow(ASSAY_READ, 1.0)
	var foot: float = by - board_h * 0.5
	for lx in [-board_w * 0.36, board_w * 0.36]:
		add_child(_a_box(Vector3(lx, (stand_y + foot) * 0.5, bz),
			Vector3(0.03, maxf(foot - stand_y, 0.02), 0.03), frame))
	add_child(_a_box(Vector3(0.0, by, bz - 0.012), Vector3(board_w + 0.04, board_h + 0.04, 0.016), frame))
	add_child(_a_box(Vector3(0.0, by, bz), Vector3(board_w, board_h, 0.012), paper))
	var x0: float = -board_w * 0.42
	var x1: float = board_w * 0.42
	var y0: float = by - board_h * 0.34
	var y1: float = by + board_h * 0.34
	add_child(_a_box(Vector3(0.0, y0, bz + 0.009), Vector3(board_w * 0.86, 0.008, 0.006), rule))
	add_child(_a_box(Vector3(x0, by, bz + 0.009), Vector3(0.008, board_h * 0.70, 0.006), rule))
	for i in range(4):
		add_child(_a_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), bz + 0.008),
			Vector3(board_w * 0.86, 0.003, 0.004), rule))
	# The trace is CLOSED FORM, not sampled from the running solver: a plot that came out
	# different on every launch would be noise wearing the costume of a record.
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(29):
		var f: float = float(i) / 28.0
		var v: float = exp(-3.4 * f) * cos(f * 13.0)
		pts.append(Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.44), bz + 0.015))
	for i in range(pts.size() - 1):
		add_child(_a_seg(pts[i], pts[i + 1], 0.011, ink))
	add_child(_a_sphere(pts[pts.size() - 1], 0.015, ink))
	add_child(_a_label("CHART", Vector3(0.0, by + board_h * 0.5 + 0.07, bz), 11, ASSAY_READ))


## VITRINE — a case. The demonstration stops being something you can reach into and becomes
## an exhibit: glass on four posts, a capping plate, a caption on the front rail. The
## specimen goes on moving inside and can no longer be touched.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = _a_mat(Color(0.30, 0.32, 0.36), 0.4, 0.6)
	var cap: StandardMaterial3D = _a_mat(Color(0.20, 0.21, 0.25), 0.7, 0.0)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	add_child(_a_box(c, s, _a_glass(Color(0.72, 0.84, 0.95), 0.09)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			add_child(_a_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.034, s.y, 0.034), post))
	# Rails, not floors: a solid pan at the base would hide whatever the bench has down there.
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			add_child(_a_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.026, 0.026), post))
		for sx2 in [-hx, hx]:
			add_child(_a_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.026, 0.026, s.z), post))
	add_child(_a_box(Vector3(c.x, y1 + 0.026, c.z), Vector3(s.x + 0.05, 0.03, s.z + 0.05), cap))
	add_child(_a_box(Vector3(c.x, y0 + 0.06, c.z + hz + 0.014), Vector3(minf(s.x * 0.5, 0.34), 0.07, 0.012),
		_a_mat(Color(0.13, 0.14, 0.17), 0.8, 0.0)))
	add_child(_a_label("VITRINE", Vector3(c.x, y0 + 0.06, c.z + hz + 0.035), 11,
		Color(0.90, 0.92, 0.97)))


# ── assay primitives ───────────────────────────────────────────────────
# Only the ASSAY block uses these; nothing above this line changes.

func _a_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _a_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	# This bench ships with emissive off, so an unlit instrument would be a grey stick. The
	# floor keeps the reading readable either way.
	m.emission_energy_multiplier = energy if emissive else energy * 0.55
	return m


func _a_glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _a_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _a_sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## One segment of the plotted trace. The whole chart lies in a plane at constant z, so a box
## turned about Z is enough — no general basis needed.
func _a_seg(a: Vector3, b: Vector3, w: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var mi: MeshInstance3D = _a_box((a + b) * 0.5, Vector3(maxf(d.length(), 0.001), w, w), mat)
	mi.rotation.z = atan2(d.y, d.x)
	return mi


func _a_label(text: String, pos: Vector3, font: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = 0.005
	l.modulate = color
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	return l
