extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalArchBench

## @identity
## name: "Fractal architecture"
## tier: medium
## lineage: a Roman aqueduct's logic on a workbench — the great span carried by
##   arches, and each arch carried by smaller arches, all the way down.
## essence: One load-bearing arch built entirely out of smaller arches. The big
##   span never touches the ground directly; it stands on two half-arches, which
##   stand on quarter-arches. The same curve at every scale holds the same weight
##   with less stone each level — span the most with the least.
## truth: "span the most with the least — an arch of arches"
## applications: recursive vaulting — a single arch rule, repeated at shrinking
##   scale, fills a span with structure that is mostly air.

@export var depth: int = 4
@export var span: float = 0.74
@export var rise: float = 0.62
@export var stone_col: Color = Color(0.74, 0.69, 0.56)
@export var bench_col: Color = Color(0.16, 0.18, 0.22)
@export var label_col: Color = Color(0.95, 0.88, 0.62)

## AXIS — WHAT THE BENCH PUTS ON SHOW OF THE LADDER OF DEPTHS.
##
## A fractal is a rule with no last step, so anything a bench can physically hold is one rung
## cut out of an infinite climb. `depth` picks WHICH rung. This axis is the different question
## of whether the bench admits there were others — whether it presents a finished object or an
## interrupted procedure.
##
## Shared word for word with [[sierpinski_bench]], [[mandelbrot_bench]] and [[julia_bench]].
## Those four were built as one family — same base class, same 1.1 m bench body, same billboard
## caption, six placements each — and they duplicate one another's helper code verbatim. One
## vocabulary, so a fractals room reads as an argument and not as four unrelated props: a bench
## set to `seed` beside one set to `figure` is staging rule-against-result on purpose.
##
##   figure   one rung, the deepest — the finished form alone, no evidence of a process.
##            The legacy lineage, byte for byte.
##   series   every rung side by side across the bench, coarse at the left, the working depth
##            at the right. The object is replaced by its own history.
##   seed     the first rung only, blown up and thickened to hold the same span — one fat arch
##            where fifteen were. The rule with the result withheld.
##   relief   every rung at once, each a complete figure on its own plane stepping toward the
##            viewer, dark at the back and pale at the front. All scales present, none of them
##            the fractal.
##   section  ONE figure cut across the ladder: the master span stands, its left haunch carries
##            a single bare arch and its right haunch the full nest, with a lit plumb line
##            dropped at the seam. The cut made an exhibit.
##
## The arch is the only member of the four whose recursion is already spatial: at `figure` every
## sub-arch is drawn, all fifteen of them coplanar at z = 0. So `relief` here does not ADD levels
## the way it does on the escape-time pair — it un-flattens the ones already present, fanning
## four complete arcades through 0.34 m of bench depth. Which of the five reads strongest is for
## the sweep to say, not for this comment.
@export var ladder: String = "figure"  # figure | series | seed | relief | section
const LADDERS: PackedStringArray = ["figure", "series", "seed", "relief", "section"]

var _t: float = 0.0
var _sway_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("span"):
		span = float(config["span"])
	if config.has("rise"):
		rise = float(config["rise"])
	if config.has("stone_col"):
		stone_col = _parse_color(config["stone_col"], stone_col)
	if config.has("ladder"):
		var _l: String = str(config["ladder"]).strip_edges().to_lower()
		ladder = _l if LADDERS.has(_l) else ladder
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway_root = null
	_build()


func _build() -> void:
	# Bench base.
	var top_y: float = 0.85
	var bench_mat: StandardMaterial3D = _matte_mat(bench_col, 0.7, 0.2)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.7), bench_mat))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.12, top_y, _steel_mat(bench_col.lightened(0.1))))

	# Sway root holds the recursive arch, springing from the bench top.
	var root := Node3D.new()
	root.name = "ArchSway"
	root.position = Vector3(0.0, top_y + 0.1, 0.0)
	add_child(root)
	_sway_root = root

	var stone_mat: StandardMaterial3D = _matte_mat(stone_col, 0.85, 0.0)

	# Master semicircular arch standing on the bench.
	_arch(root, Vector3(-span * 0.5, 0.0, 0.0), Vector3(span * 0.5, 0.0, 0.0), rise, depth, stone_mat)

	# Keystone glow at the crown of the master arch.
	root.add_child(_sphere(Vector3(0.0, rise, 0.0), 0.02, _glow_mat(label_col, 1.8)))

	add_child(_billboard_label("SPAN THE MOST WITH THE LEAST", Vector3(0.0, top_y + rise + 0.35, 0.0), 22, label_col))

	# LADDER dressing, appended LAST so every child index and position above is untouched on
	# the legacy path. "figure" falls through and adds nothing at all.
	#
	# The legacy arch is not deleted, it is MUTED: layers = 0 takes it off every camera while
	# leaving its meshes in the tree. The capture rig fits its frame to the merged AABB of every
	# MeshInstance3D it can find, so muting rather than freeing keeps all five values framed at
	# exactly the same distance — the critic then measures the picture and not the zoom.
	if ladder != "figure":
		for c in _sway_root.get_children():
			_mute(c)
		match ladder:
			"series":
				_ladder_series(stone_mat)
			"seed":
				_ladder_seed(stone_mat)
			"relief":
				_ladder_relief()
			"section":
				_ladder_section(stone_mat)
			_:
				pass


# A semicircular arch from foot `a` to foot `b` rising to `h` at its crown.
# Recursion: the area under the arch is spanned by two smaller arches that
# spring from the same feet toward the centre, then those split again.
# `rscale` thickens or thins the voussoirs without touching the geometry; it defaults to 1.0 so
# every legacy call is unchanged, and only the LADDER values ever pass anything else.
func _arch(parent: Node3D, a: Vector3, b: Vector3, h: float, d: int, mat: Material, rscale: float = 1.0) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var half_w: float = (b - a).length() * 0.5
	var r: float = 0.012 * (1.0 + 0.5 * float(d)) * rscale

	# Trace the semicircle as a polyline of short cylinders.
	var segs: int = 9
	var prev: Vector3 = a
	for i in range(1, segs + 1):
		var u: float = float(i) / float(segs)
		var ang: float = PI * (1.0 - u)  # PI at a, 0 at b
		var x: float = mid.x + cos(ang) * half_w
		var y: float = mid.y + sin(ang) * h
		var cur: Vector3 = Vector3(x, y, mid.z)
		parent.add_child(_cylinder_between(prev, cur, r, mat))
		prev = cur

	# Short jamb stubs grounding the feet.
	parent.add_child(_cylinder_between(a, a + Vector3(0.0, -0.05 - 0.04 * float(d), 0.0), r, mat))
	parent.add_child(_cylinder_between(b, b + Vector3(0.0, -0.05 - 0.04 * float(d), 0.0), r, mat))

	if d <= 1:
		return

	# Two child arches springing from the feet toward the centre, each half-width.
	var child_h: float = h * 0.5
	_arch(parent, a, mid, child_h, d - 1, mat, rscale)
	_arch(parent, mid, b, child_h, d - 1, mat, rscale)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway_root != null:
		_sway_root.rotation.y = sin(_t * 0.4) * 0.06


# ── LADDER ───────────────────────────────────────────────────────────────────
# Every rung this bench can climb, coarse first. Nothing here draws at random: the arrangement
# is a pure function of `depth`, `span` and `rise`, so two captures of the same value are the
# same picture.

func _rungs() -> PackedInt32Array:
	var out := PackedInt32Array()
	for d in range(1, maxi(depth, 1) + 1):
		out.append(d)
	return out


# Take a subtree off every camera without freeing it — see the note in _build().
func _mute(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 0
	for c in n.get_children():
		_mute(c)


## SERIES — the working figure is replaced by the whole climb, four arcades in a row across the
## bench top: one bare arch on the left, then the same arch carrying two, then four, then the
## full fifteen on the right. The bench stops holding an object and starts holding a sequence.
func _ladder_series(mat: Material) -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var pitch: float = 1.02 / float(n)
	var w: float = pitch * 0.80
	for i in range(n):
		var cx: float = -0.51 + pitch * (float(i) + 0.5)
		var h: float = rise * (w / maxf(span, 0.001))
		_arch(_sway_root, Vector3(cx - w * 0.5, 0.0, 0.0), Vector3(cx + w * 0.5, 0.0, 0.0),
			h, rungs[i], mat, 0.75)
	# The crown of the last, deepest arcade still gets the keystone — the sequence has an end.
	var last_cx: float = -0.51 + pitch * (float(n) - 0.5)
	var last_h: float = rise * (w / maxf(span, 0.001))
	_sway_root.add_child(_sphere(Vector3(last_cx, last_h, 0.0), 0.018, _glow_mat(label_col, 1.8)))


## SEED — the first rung alone, at the same span and crown height as the full figure but with
## voussoirs three times as fat. Where the legacy build reads as stone lace, this reads as one
## heavy vault: the rule stated, the result withheld.
func _ladder_seed(mat: Material) -> void:
	var w: float = span * 1.26
	_arch(_sway_root, Vector3(-w * 0.5, 0.0, 0.0), Vector3(w * 0.5, 0.0, 0.0), rise, 1, mat, 3.0)
	_sway_root.add_child(_sphere(Vector3(0.0, rise, 0.0), 0.028, _glow_mat(label_col, 1.9)))


## RELIEF — each rung drawn as a COMPLETE figure on its own plane, stacked through the bench's
## depth: the bare arch furthest back and darkest, the full nest at the front and palest. Four
## arcades seen through one another. From the capture camera's 32 degrees off axis they fan.
func _ladder_relief() -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var last: float = maxf(float(n - 1), 1.0)
	for i in range(n):
		var layer := Node3D.new()
		layer.name = "Rung%d" % rungs[i]
		layer.position = Vector3(0.0, 0.0, -0.17 + 0.115 * float(i))
		_sway_root.add_child(layer)
		var f: float = float(i) / last
		var tint: Color = stone_col.darkened(0.52 * (1.0 - f))
		_arch(layer, Vector3(-span * 0.5, 0.0, 0.0), Vector3(span * 0.5, 0.0, 0.0),
			rise, rungs[i], _matte_mat(tint, 0.85, 0.0), 0.85)


## SECTION — one figure cut across the ladder. The master span stands as it always did; its left
## haunch is spanned by a single bare arch in darker stone, its right by the full recursion, and
## a lit plumb line hangs at the seam between them. Same silhouette, two different claims about
## what a fractal is, meeting at a visible join.
func _ladder_section(mat: Material) -> void:
	var a := Vector3(-span * 0.5, 0.0, 0.0)
	var b := Vector3(span * 0.5, 0.0, 0.0)
	var mid: Vector3 = (a + b) * 0.5
	var coarse: StandardMaterial3D = _matte_mat(stone_col.darkened(0.38), 0.92, 0.0)
	_arch(_sway_root, a, b, rise, 1, mat, 1.4)
	_arch(_sway_root, a, mid, rise * 0.5, 1, coarse, 1.4)
	_arch(_sway_root, mid, b, rise * 0.5, maxi(depth - 1, 1), mat)
	_sway_root.add_child(_cylinder_between(Vector3(mid.x, rise * 0.66, 0.0),
		Vector3(mid.x, -0.07, 0.0), 0.009, _glow_mat(label_col, 1.5)))
	_sway_root.add_child(_sphere(Vector3(0.0, rise, 0.0), 0.02, _glow_mat(label_col, 1.8)))
