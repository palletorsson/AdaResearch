# zeno_staircase.gd — THE RATE IS A SECANT OVER ONE FROZEN FRAME.
#
# The change (calculus) seam. Motion is continuous; the machine reads it at
# frame ticks and holds the value between them — Zeno's arrow, frozen then
# jumped. The amber curve is the true continuous change; the blue staircase is
# what the machine actually has: a held value at each tick and a jump to the
# next. The "instantaneous" rate it reports is not the tangent — it is a secant,
# rise over run across one frozen frame, a slope the true curve only touches for
# an instant the machine never samples. Shrink the frame and the staircase gets
# finer; it never becomes the curve.
extends Node3D
class_name ZenoStaircase

# ── the tick axis ──────────────────────────────────────────────────────
# The sentence this artifact has always ended on — "shrink the frame and the
# staircase gets finer; it never becomes the curve" — was, until now, a claim
# no placement could test. `samples` was an @export, but the only route to it
# was an apply_grid_config that assigned the variable AFTER _ready had already
# built with 9 and never rebuilt: the knob turned and nothing moved. Every one
# of this artifact's homes stood under a caption about subdivision showing the
# single frame rate its author happened to type.
#
# The five values are the halving argument laid out as one ladder, x3 either
# side of the shipped 9:
#   once     one hold and one jump — the whole motion as a single frozen frame
#   coarse   three, where the staircase is obviously not the curve
#   fine     nine, the shipped reading
#   dense    twenty-seven, close enough to flatter the machine
#   limit    eighty-one, where the eye stops being able to tell and the record
#            is STILL a staircase — the paradox stated rather than described
const TICKS: PackedStringArray = ["once", "coarse", "fine", "dense", "limit"]

## tick name -> sample count. One table so the word and the int cannot drift;
## every route (sweep @export, map token, inspector) goes through it.
const TICK_SAMPLES: Dictionary = {
	"once": 1,
	"coarse": 3,
	"fine": 9,
	"dense": 27,
	"limit": 81,
}

# ── the evidence axis ──────────────────────────────────────────────────
# What the machine offers you to check its own record against. The shipped
# artifact hands you everything at once: the true curve, the staircase, and the
# secant it wrongly calls a tangent. That is generous, and generosity is a
# position — it is not the position a machine is normally in.
#   result    the staircase alone. The machine's record, with nothing in the
#             frame it could be wrong about. It looks fine. That is the point.
#   trace     the true continuous curve laid behind it — the comparison, no
#             commentary
#   longhand  + the secant drawn extended past both ends and named, so the
#             slope the machine reports as instantaneous is visibly a chord
# The word and the ladder are the `evidence` family's (example_1_7 through
# example_2_9, koch_curve, box_counting_dimension, sine_wave_controller — which
# is likewise a three-value member, there being no fourth thing to withhold).
# The family asks: what does this thing put in the frame as PROOF that a law is
# at work? Same question here, aimed at the machine's account of its own error.
const EVIDENCE: PackedStringArray = ["result", "trace", "longhand"]

## Stage-2 DNA axis — how finely the machine chops the interval. Read at the top
## of _ready(), so the sweep reaches it by setting the @export alone.
@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "fine"
## Stage-2 DNA axis — what is in the frame besides the machine's own record.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"
## The int the build actually loops on. Kept in sync with `tick` by
## _sync_axes_from_exports(); an inspector that sets this and leaves `tick` at
## its default still wins, so nothing already standing changes shape.
@export var samples: int = 9
@export var span: float = 0.44
@export var amp: float = 0.13
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_step: Color = Color(0.3, 0.7, 1.0)
@export var color_secant: Color = Color(0.95, 0.5, 0.5)

## True once _ready() has finished a full build. apply_grid_config arrives
## deferred, AFTER _ready(), and must never rebuild before there is something
## to rebuild.
var _built: bool = false
## Every node THIS SCRIPT parented in. The rebuild frees exactly these — never
## get_children(), which would take the grid's own plates with it.
var _created: Array[Node] = []


func _ready() -> void:
	_sync_axes_from_exports()
	_build_all()
	_built = true


## Reconcile the words and the int before anything is drawn.
##
## `tick` wins when it names something other than the shipped reading, which is
## the sweep's route and the map's route. Left at "fine" the legacy `samples`
## wins, so a scene or inspector that already asked for a different count keeps
## it instead of being quietly reset to nine.
func _sync_axes_from_exports() -> void:
	tick = _pick(tick, TICKS, "fine")
	evidence = _pick(evidence, EVIDENCE, "longhand")
	if tick != "fine":
		samples = int(TICK_SAMPLES.get(tick, 9))
	else:
		samples = maxi(1, samples)


func _build_all() -> void:
	_backing()
	# the true continuous curve (amber, dense) — the thing the machine does not
	# have. Withheld at `result`, where the record stands unchallenged.
	if evidence != "result":
		var steps: int = 180
		var prev: Vector3 = _tp(-span)
		for i in range(1, steps + 1):
			var x: float = -span + 2.0 * span * float(i) / float(steps)
			var p: Vector3 = _tp(x)
			_seg(prev, p, color_true, 0.004)
			prev = p
	# the staircase (zero-order hold): flat, then jump, at each frame tick
	var xs: Array[float] = []
	for i in range(samples + 1):
		xs.append(-span + 2.0 * span * float(i) / float(samples))
	# A tick dot must never be wider than the tick it marks, or the ladder's top
	# rungs fuse into one fat bar and the argument is lost to overlap. At the
	# shipped nine the cap is 0.044, so the 0.008 constant is untouched.
	var dot_r: float = minf(0.008, (2.0 * span / float(samples)) * 0.45)
	for i in range(samples):
		var y0: float = _tp(xs[i]).y
		var y1: float = _tp(xs[i + 1]).y
		_seg(Vector3(xs[i], y0, 0.0), Vector3(xs[i + 1], y0, 0.0), color_step, 0.008)  # hold
		_seg(Vector3(xs[i + 1], y0, 0.0), Vector3(xs[i + 1], y1, 0.0), color_step, 0.008)  # jump
		_dot(Vector3(xs[i], y0, 0.0), Color(0.95, 0.96, 1.0), dot_r)
	# the secant the machine calls the "tangent" — rise over run, one frame,
	# drawn extended so its wrong slope is obvious against the true curve. It has
	# nothing to be obvious against without the curve, so it belongs to longhand.
	if evidence == "longhand":
		var mi: int = clampi(int(samples / 2), 0, samples - 1)
		var a: Vector3 = _tp(xs[mi])
		var b: Vector3 = _tp(xs[mi + 1])
		var sl: float = (b.y - a.y) / (b.x - a.x)
		var ext: float = 0.14
		_seg(Vector3(a.x - ext, a.y - sl * ext, 0.0), Vector3(b.x + ext, b.y + sl * ext, 0.0),
			color_secant, 0.005)
		_tag("the 'tangent' = a secant over one frame", Vector3(0.0, -0.2, 0.0), color_secant)
	# The plate is the wall caption, not evidence: it names the piece and states
	# the seam in words. It stands at every value of both axes, so a bite
	# measured here is a bite in the drawing and never in the label.
	_plate("THE FRAME",
		"motion is continuous · the machine reads at ticks\nand holds between (frozen, then jump — Zeno)\nthe rate it reports is a secant, not the tangent",
		Vector3(0.0, 0.31, 0.0), color_step)


## Free only what this script made, then build again.
func _rebuild_now() -> void:
	for c in _created:
		if not is_instance_valid(c):
			continue
		var p: Node = c.get_parent()
		if p != null:
			p.remove_child(c)
		c.queue_free()
	_created.clear()
	_build_all()


## Parent a node and remember it belongs to us.
func _own(n: Node) -> Node:
	add_child(n)
	_created.append(n)
	return n


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

	var before_tick: String = tick
	var before_evidence: String = evidence
	var before_samples: int = samples

	# ── Stage-2 DNA axes — `#tick:limit`, `#evidence:result` ───────────────
	if config_data.has("tick"):
		tick = _pick(str(config_data["tick"]), TICKS, tick)
		samples = int(TICK_SAMPLES.get(tick, samples))
	if config_data.has("evidence"):
		evidence = _pick(str(config_data["evidence"]), EVIDENCE, evidence)
	# The legacy raw route, still working and now actually reaching the geometry.
	# It is read last, so a token that says both gets the number it asked for.
	if has_meta("config_samples"):
		samples = maxi(1, int(str(get_meta("config_samples"))))

	if not _built:
		return
	if tick == before_tick and evidence == before_evidence and samples == before_samples:
		return
	_rebuild_now()


## Accept an axis value only if it names something this artifact actually builds.
## A typo has to fall back to the shipped look; a half-recognised value would
## strand a placement showing a reading nobody asked for.
func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _tp(x: float) -> Vector3:
	var u: float = (x + span) / (2.0 * span)   # 0..1
	var y: float = amp * (pow(u, 1.7) * 2.0 - 1.0)
	return Vector3(x, y, 0.0)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.44, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.014)
	_own(mi)


func _seg(a: Vector3, b: Vector3, color: Color, thick: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	_own(mi)


func _dot(p: Vector3, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mi.material_override = mat
	mi.position = p + Vector3(0.0, 0.0, 0.012)
	_own(mi)


func _tag(text: String, pos: Vector3, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00042
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos
	_own(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.82, 0.13, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	_own(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.82, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.072, 0.006)
	_own(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	_own(t)
