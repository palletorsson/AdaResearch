extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SierpinskiBench

## @identity
## name: "Sierpinski"
## tier: medium
## lineage: the Sierpinski gasket — Sierpinski's triangle, the canonical self-similar set,
##   recursed until the same hole appears at every scale on a bench.
## essence: A filled triangle has its middle quarter punched out, leaving three corner
##   triangles. Each of those loses ITS middle. Recurse five times and the surface is more
##   hole than triangle, yet at any zoom it looks the same — three copies of itself, half
##   size. The whole IS its parts.
## truth: "the same hole at every scale" — three half-size copies of the whole. D = log 3 / log 2 ≈ 1.585.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var depth: int = 5
@export var tri_size: float = 0.64           # base edge length of the gasket (m)
@export var fill_color: Color = Color(0.70, 0.55, 1.0)
@export var tip_color: Color = Color(1.0, 0.78, 0.50)
@export var label_color: Color = Color(0.88, 0.85, 1.0)

## AXIS — WHAT THE BENCH PUTS ON SHOW OF THE LADDER OF DEPTHS.
##
## A fractal is a rule with no last step, so anything a bench can physically hold is one rung
## cut out of an infinite climb. `depth` picks WHICH rung. This axis is the different question
## of whether the bench admits there were others — whether it presents a finished object or an
## interrupted procedure.
##
## Shared word for word with [[fractal_arch_bench]], [[mandelbrot_bench]] and [[julia_bench]].
## Those four were built as one family — same base class, same 1.1 m bench body, same billboard
## caption, six placements each — and they duplicate one another's helper code verbatim (this
## file's `_field` and mandelbrot_bench's are the same twenty lines). One vocabulary, so a
## fractals room reads as an argument rather than four unrelated props.
##
##   figure   one rung, the deepest — 243 leaf cells, the gasket as a finished thing. The
##            legacy lineage, byte for byte.
##   series   the whole climb tiled across the backboard, one small gasket per rung, coarse at
##            the top left and the working depth at the end. The object as its own history.
##   seed     the first rung only, at full board size — three fat triangles and one hole. The
##            rule stated once, the result withheld. Roughly three times the lit area of the
##            default, which is why it reads from across a room.
##   relief   every rung at once, each a complete gasket on its own plane stepping toward the
##            viewer, dark at the back. The fine speckle sits on the big plates it came from.
##   section  ONE gasket cut across the ladder: its lower-left third left solid, its upper third
##            cut once, its lower-right third cut all the way, with a lit bar at the seam. The
##            truncation made an exhibit.
##
## The gasket is by far the smallest subject of the four benches: at depth 5 its lit cells total
## about 0.062 m^2 on a 0.59 m^2 black backboard, roughly one part in a hundred of the capture
## frame. Every value here was therefore chosen to move the lit AREA and not just its pattern —
## `seed` 0.196 m^2, `section` 0.130, `relief` a 0.196 m^2 silhouette five layers thick. `series`
## is the exception: it keeps the total ink almost unchanged (0.065) and only redistributes it
## into five separated tiles, so it is the value most at risk of being diluted by the two
## billboard labels and the lit steel benchtop, which do not move.
@export var ladder: String = "figure"  # figure | series | seed | relief | section
const LADDERS: PackedStringArray = ["figure", "series", "seed", "relief", "section"]

var _t: float = 0.0
var _gasket_root: Node3D = null
var _leaves: Array = []     # each: {center:Vector3, size:float}


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 6)
	if config.has("tri_size"):
		tri_size = float(config["tri_size"])
	if config.has("ladder"):
		var _l: String = str(config["ladder"]).strip_edges().to_lower()
		ladder = _l if LADDERS.has(_l) else ladder
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_gasket_root = null
	_build()


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _collect(p_a: Vector2, p_b: Vector2, p_c: Vector2, d: int) -> void:
	# Recurse; at the leaf, record the small filled triangle as a center+size.
	if d <= 0:
		var center: Vector2 = (p_a + p_b + p_c) / 3.0
		var size: float = p_a.distance_to(p_b)
		_leaves.append({"c": center, "s": size})
		return
	var ab: Vector2 = (p_a + p_b) * 0.5
	var bc: Vector2 = (p_b + p_c) * 0.5
	var ca: Vector2 = (p_c + p_a) * 0.5
	_collect(p_a, ab, ca, d - 1)
	_collect(ab, p_b, bc, d - 1)
	_collect(ca, bc, p_c, d - 1)


func _build() -> void:
	# --- bench base + pillar ------------------------------------------------
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.20, 0.22, 0.26), 0.85)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.20, 0.7), base_mat))
	var top_mat: StandardMaterial3D = _steel_mat(Color(0.40, 0.44, 0.50))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.7), top_mat))
	add_child(_cylinder(Vector3(0.0, 0.50, -0.18), 0.05, 0.70, base_mat))

	# --- backboard the gasket forms on (facing +Z) --------------------------
	var board_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, 1.18, 0.13), Vector3(tri_size + 0.12, tri_size + 0.14, 0.02), board_mat))

	var root := Node3D.new()
	root.name = "GasketSway"
	add_child(root)
	_gasket_root = root

	# --- recurse to collect leaf triangles ---------------------------------
	_leaves.clear()
	var h: float = tri_size * sqrt(3.0) * 0.5
	# centred on the board: apex up
	var cx0: float = 0.0
	var cy0: float = 1.18
	var apex := Vector2(cx0, cy0 + h * 0.5)
	var bl := Vector2(cx0 - tri_size * 0.5, cy0 - h * 0.5)
	var br := Vector2(cx0 + tri_size * 0.5, cy0 - h * 0.5)
	_collect(apex, bl, br, depth)

	# --- fill one MultiMesh with the leaf triangles (as small boxes) -------
	var count: int = _leaves.size()
	var field: MultiMeshInstance3D = _field(count, true)
	field.name = "Gasket"
	var mm: MultiMesh = field.multimesh
	for i in range(count):
		var leaf: Dictionary = _leaves[i]
		var c: Vector2 = leaf["c"]
		var s: float = leaf["s"]
		# vertical position drives color (apex warm -> base cool)
		var frac: float = clampf((c.y - bl.y) / maxf(h, 0.001), 0.0, 1.0)
		var col: Color = fill_color.lerp(tip_color, frac)
		# a small box approximating the filled cell
		var basis := Basis().scaled(Vector3(s * 0.86, s * 0.74, 0.02))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(c.x, c.y, 0.145)))
		mm.set_instance_color(i, col)
		# cache for sway-independent (already in root space)
	root.add_child(field)

	# --- labels -------------------------------------------------------------
	add_child(_billboard_label("D = log 3 / log 2 ≈ 1.585", Vector3(0.0, cy0 - h * 0.5 - 0.06, 0.16), 16, tip_color))
	add_child(_billboard_label("THE SAME HOLE AT EVERY SCALE", Vector3(0.0, 1.6, 0.0), 22, label_color))

	# LADDER dressing, appended LAST so every child index and position above is untouched on the
	# legacy path. "figure" falls through and adds nothing at all.
	#
	# The legacy gasket is not deleted, it is MUTED: layers = 0 takes it off every camera while
	# leaving it in the tree. The capture rig fits its frame to the merged AABB of every
	# MeshInstance3D it can find, so all five values frame at exactly the same distance and the
	# critic measures the picture rather than the zoom.
	if ladder != "figure":
		for c in _gasket_root.get_children():
			_mute(c)
		match ladder:
			"series":
				_ladder_series(cx0, cy0)
			"seed":
				_ladder_seed(cx0, cy0)
			"relief":
				_ladder_relief(cx0, cy0)
			"section":
				_ladder_section(cx0, cy0)
			_:
				pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _gasket_root != null:
		_gasket_root.rotation.y = sin(_t * 0.4) * 0.05


# ── LADDER ───────────────────────────────────────────────────────────────────
# Every rung this bench can climb, coarse first. Nothing here draws at random: each arrangement
# is a pure function of `depth` and `tri_size`, so two captures of one value are one picture.

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


# One gasket as its own MultiMesh — apex up, centred on (cx, cy), base edge `size`, cut at rung
# `d`. Same leaf shape and same apex-warm colour ramp the legacy build uses, so a tile in
# `series` is recognisably the same figure as the one in `figure`, only smaller.
func _gasket(cx: float, cy: float, size: float, d: int, z: float, dim: float) -> MultiMeshInstance3D:
	var hh: float = size * sqrt(3.0) * 0.5
	var apex := Vector2(cx, cy + hh * 0.5)
	var bl := Vector2(cx - size * 0.5, cy - hh * 0.5)
	var br := Vector2(cx + size * 0.5, cy - hh * 0.5)
	_leaves.clear()
	_collect(apex, bl, br, maxi(d, 0))
	return _emit(_leaves, bl.y, hh, z, dim)


# Fill a MultiMesh from whatever `_collect` last gathered. Split out because `section` needs to
# collect three sub-triangles at three different rungs into ONE field.
func _emit(leaves: Array, base_y: float, hh: float, z: float, dim: float) -> MultiMeshInstance3D:
	var count: int = leaves.size()
	var mi: MultiMeshInstance3D = _field(count, true)
	var mm: MultiMesh = mi.multimesh
	for i in range(count):
		var leaf: Dictionary = leaves[i]
		var c: Vector2 = leaf["c"]
		var s: float = leaf["s"]
		var frac: float = clampf((c.y - base_y) / maxf(hh, 0.001), 0.0, 1.0)
		var col: Color = fill_color.lerp(tip_color, frac)
		if dim < 1.0:
			col = col.darkened(1.0 - dim)
		var basis := Basis().scaled(Vector3(s * 0.86, s * 0.74, 0.02))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(c.x, c.y, z)))
		mm.set_instance_color(i, col)
	return mi


## SERIES — the backboard stops holding one gasket and holds the whole climb: a small gasket per
## rung, row-major from the top left, the last row centred. Rung 1 is three plain triangles;
## rung 5 is the familiar lace. Five stages of one rule, all at once, all the same size.
func _ladder_series(cx0: float, cy0: float) -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var cols: int = 3
	var rows: int = int(ceil(float(n) / float(cols)))
	# Derived from the backboard, not hardcoded: the board is (tri_size + 0.12) wide by
	# (tri_size + 0.14) tall, so a map that shrinks tri_size still gets tiles that fit on it.
	var pitch_x: float = (tri_size + 0.12) / float(cols)
	var pitch_y: float = (tri_size + 0.14) / float(maxi(rows, 1))
	var tile: float = minf(pitch_x * 0.86, pitch_y * 0.92)
	for i in range(n):
		var row: int = i / cols
		var col: int = i % cols
		var in_row: int = mini(cols, n - row * cols)
		var tx: float = cx0 + (float(col) - (float(in_row) - 1.0) * 0.5) * pitch_x
		var ty: float = cy0 + ((float(rows) - 1.0) * 0.5 - float(row)) * pitch_y
		_gasket_root.add_child(_gasket(tx, ty, tile, rungs[i], 0.145, 1.0))


## SEED — the first rung at full board size: three fat triangles around one central hole, each
## leaf roughly 0.28 m across where the legacy leaf is 0.02 m. The rule stated once. This is the
## value that changes the lit area most, and the one that reads at distance.
func _ladder_seed(cx0: float, cy0: float) -> void:
	_gasket_root.add_child(_gasket(cx0, cy0, tri_size, 1, 0.145, 1.0))


## RELIEF — every rung as a complete gasket on its own plane, stepping out of the board toward
## the viewer: rung 1's three big plates furthest back and darkest, the working rung's speckle at
## the front and full brightness. Each rung's cells fall inside the plates of the rung below, so
## the stack reads as one figure thickened into depth rather than five figures overlapping.
func _ladder_relief(cx0: float, cy0: float) -> void:
	var rungs: PackedInt32Array = _rungs()
	var n: int = rungs.size()
	var last: float = maxf(float(n - 1), 1.0)
	for i in range(n):
		var f: float = float(i) / last
		_gasket_root.add_child(_gasket(cx0, cy0, tri_size, rungs[i],
			0.145 + 0.026 * float(i), 0.34 + 0.66 * f))


## SECTION — one gasket cut across the ladder. Its lower-left third is left SOLID (rung 0, a
## single filled triangle), its upper third is cut once, its lower-right third is cut all the way
## to the working depth, and a lit bar stands on the seam between solid and lace. The same
## outline, three different answers to "how far down does this go", meeting at a visible join.
func _ladder_section(cx0: float, cy0: float) -> void:
	var hh: float = tri_size * sqrt(3.0) * 0.5
	var apex := Vector2(cx0, cy0 + hh * 0.5)
	var bl := Vector2(cx0 - tri_size * 0.5, cy0 - hh * 0.5)
	var br := Vector2(cx0 + tri_size * 0.5, cy0 - hh * 0.5)
	var ab: Vector2 = (apex + bl) * 0.5
	var bc: Vector2 = (bl + br) * 0.5
	var ca: Vector2 = (br + apex) * 0.5
	_leaves.clear()
	_collect(apex, ab, ca, 1)                        # upper third — cut once
	_collect(ab, bl, bc, 0)                          # lower left — never cut, one solid plate
	_collect(ca, bc, br, maxi(depth, 1))             # lower right — cut all the way
	_gasket_root.add_child(_emit(_leaves, bl.y, hh, 0.145, 1.0))
	# The cut itself: a lit bar standing on the seam where solid meets lace.
	_gasket_root.add_child(_box(Vector3(cx0, cy0 - hh * 0.25, 0.162),
		Vector3(0.008, hh * 0.5, 0.006), _glow_mat(tip_color, 1.7)))
