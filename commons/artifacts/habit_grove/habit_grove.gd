extends Node3D
class_name HabitGrove

## habit_grove — a plant's HABIT is one angle, and it is a roll, not a divergence.
##
## THE FAMILY. Three artifacts declare an axis called `habit` with one vocabulary,
## character for character: branching_vine (hazards.json), lsystem_tree (lsystems.json) and
## stochastic_tree_separated (procgen_extra.json) — planar · fanned · whorled · spiral, all
## three defaulting to planar. Read from their code, the four words are ONE TABLE OF FOUR
## NUMBERS, branching_vine.gd:73-78, which stochastic_tree preloads out of that file so the
## family cannot drift (example_8_7...gd:91):
##     planar 0.0 · fanned 30.0 · whorled 90.0 · spiral 137.5   degrees
## and ONE MECHANISM: at every descent of the branch rule — the L-system `[` push in the vine
## (gd:318-319) and the tree (gd:202-203), the recursive call in the stochastic tree
## (gd:281-285) — the plane the next fork will lie in is ROLLED about the parent's own axis
## by that many degrees. Every fork is the same fork: two children at +/- one angle in one
## plane (25.0 deg in the vine and the stochastic tree, 25.7 in lsystem_tree). Nothing else
## changes. Not the number of children per node, not the branch angle, not the rule.
##
## THE ARGUMENT, sharpened from the code and AGAINST the botanist's reading of the words.
## The brief for this artifact assumed the vocabulary meant what a botanist means: whorled =
## n branches per node spread 360/n around the stem, spiral = one branch per node stepping
## by the golden angle 137.5. THE CODE DOES NEITHER. In all three members:
##   (1) the fork ALWAYS has two children in ONE plane — nothing is ever arranged around the
##       stem; a fork is a plane, and the habit turns that plane;
##   (2) the roll is applied once per DESCENT, and in the two L-system members the parent's
##       plane is restored on `]`, so every fork that hangs off one axis lies in the SAME
##       plane whatever the habit (the vine's trunk carries fifteen forks at generation 4,
##       all coplanar, under `spiral` as under `planar`); the plane turns only when the rule
##       steps OUT onto a child, never as it climbs a stem. No stem in this family carries
##       a spiral;
##   (3) because a fork is a plane, and a plane is the same plane after 180 degrees, the
##       golden angle is not golden here: 137.5 = -42.5 (mod 180). Rolling the fork plane by
##       137.5 lands the two children on the same two lines as rolling it by -42.5 with the
##       +/- labels swapped, and with a symmetric fork the swap is invisible. So `spiral` is
##       `fanned` turned the other way and 12.5 degrees wider per generation — a fan, in a
##       mirror. And `whorled`, at 90, is DECUSSATE: two planes only, each generation a
##       quarter-turn from its parent's, the mint family's word and not the whorl's.
## So: a habit is an angle, yes — but the angle is a ROLL PER GENERATION, and two of the four
## names name arrangements the mechanism cannot produce. What it does produce is four plants
## a viewer would still file under four names, from one rule and one number. The
## disagreement available: that a name is a picture and not a mechanism, and if the picture
## reads as a whorl the word is earned. The plant reading shows both sides.
##
## THE BODY. One deterministic plant, built with the vine's own rule F -> F[+F][-F]F
## (branching_vine.gd:90 — both children at ONE node, the axis continues) to generation 4:
## 256 rods, 85 fork nodes, 171 tips. Fork half-angle 25.0, trunk segment 0.062 m shortened
## by 0.85 per push — NOT lsystem_tree's 0.72 (gd:199), which with this rule made a needle
## 0.33 m wide on a 0.93 m trunk whose planes could not be told apart in a raster; 0.85 gives
## 0.99 m tall by 0.46 m wide under planar. Rods are real six-sided prisms, coloured
## trunk-to-tip with lsystem_tree's brown and green (gd:23-24); tips are the vine's leaf
## greens darkening with depth (gd:341-342). No randf anywhere: four variants are one plant
## under four rolls, and a diff between two frames is a fact about the roll.
##
## THE STANDPOINT, said out loud. The reference fork plane is XY (normal +Z, the approach
## side), and the roll is right-handed about the local up (Godot's rotated()). From the
## canonical sweep camera (yaw 0.62, pitch -0.26) a plane at azimuth phi photographs at
## |cos(phi - 35.6 deg)| of its width, so the FIRST fork planes — the biggest limbs — show
## at 81% (planar, 0), 99% (fanned, 30), 58% (whorled, 90) and 22% (spiral, 137.5). Spiral's
## largest limbs point nearly at the camera; its deeper planes at 95 / 52.5 / 10 show at
## 50 / 96 / 91%, so it does not collapse — but a narrow spiral silhouette is a fact about
## the standpoint before it is a fact about the axis. probe_anamorphic exists for this.

## WHICH ROLL. The family's table, branching_vine.gd:73-78 verbatim.
##   planar   roll 0. Every fork plane is the reference plane; the whole plant is flat, one
##            plane, 256 rods thick as a rod. The three members' shipped drawing.
##   fanned   roll 30 per generation. First forks at 30, then 60, 90, 120: a plant whose
##            planes open like a hand of cards over 120 degrees.
##   whorled  roll 90 per generation. 90, 180 = 0, 270 = 90, 360 = 0: TWO planes, alternating
##            by generation, each perpendicular to its parent's — decussate, not whorled.
##   spiral   roll 137.5 per generation, the golden angle: 137.5, 275, 52.5, 190 — as planes
##            (mod 180) 137.5, 95, 52.5, 10 — a fan of 42.5 per generation turning the other
##            way from `fanned`. Never repeats, but never was a spiral along any stem.
@export_enum("planar", "fanned", "whorled", "spiral") var habit: String = "planar":
	set(v):
		habit = v
		if is_inside_tree():
			_rebuild()

## WHAT IS DRAWN OF THE PLANT.
##   plant   every rod of generation 4, coloured trunk to tip. The whole body; the reading in
##           which four rolls look like four species.
##   roll    the plant ghosted at 22% alpha and, at EVERY fork node (85 of them), the roll
##           itself drawn as geometry: a spoke along the parent's plane, a spoke along the
##           child's plane, and the arc between them about the parent's axis, radius 0.6x
##           the child segment (37 mm on the trunk, 19 mm at the last forks). Under planar
##           the two spokes coincide and there is no arc — a comb of single spokes on the
##           trunk, all pointing +X, is what a roll of zero looks like. The fifteen trunk
##           forks all draw the SAME arc, stacked: the roll is one number, fifteen times.
##   crown   no branches: only where the plant ends up — a bead at all 171 tips (170 leaves,
##           the vine's `]`, plus the trunk's top) in the vine's leaf greens, hung on the
##           bare trunk. The silhouette without the mechanism: planar's tips lie in one
##           sheet, whorled's in two crossed sheets, fanned's and spiral's in fans of four.
@export_enum("plant", "roll", "crown") var reading: String = "plant":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## One habit alone, or all four in a row (the grove). NOT PART OF THE AXES — wave 13 learned
## that an all-rungs value declared inside a ladder axis makes capture_config_sweep union the
## row's AABB with every single rung and photograph the singles as specks. The registry
## fixture pins `single`.
@export_enum("single", "grove") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## Bench knob, not an axis: how many times the rule is applied. 4 is lsystem_tree's
## `iterations` and the vine's `max_iterations`; 1..5 accepted.
@export var generations: int = 4:
	set(v):
		generations = clampi(v, 1, 5)
		if is_inside_tree():
			_rebuild()

const HABITS: PackedStringArray = ["planar", "fanned", "whorled", "spiral"]
const READINGS: PackedStringArray = ["plant", "roll", "crown"]
const LAYOUTS: PackedStringArray = ["single", "grove"]

## branching_vine.gd:73-78, the table all three members share. Degrees of roll of the fork
## plane about the parent axis, per descent.
const HABIT_ROLL: Dictionary = {
	"planar": 0.0,
	"fanned": 30.0,
	"whorled": 90.0,
	"spiral": 137.5,
}

## The rule: branching_vine.gd:89-90. Both children at one node; the axis continues.
const AXIOM: String = "F"
const RULE_LHS: String = "F"
const RULE_RHS: String = "F[+F][-F]F"
## Fork half-angle: branching_vine.gd:22 and example_8_7...gd:29 say 25.0; lsystem_tree 25.7.
const FORK_HALF_ANGLE_DEG: float = 25.0
## Trunk segment, metres, and the per-push shortening (lsystem_tree's is 0.72, gd:199; see
## THE BODY for why 0.85).
const SEGMENT_LEN: float = 0.062
const SHORTEN: float = 0.85
## Rod radius at depth 0 and its shrink per depth (10 mm trunk, 3.3 mm at depth 4).
const ROD_R0: float = 0.010
const ROD_SHRINK: float = 0.76
const ROD_SIDES: int = 6
## Roll reading: arc radius as a multiple of the child segment; arc tube radius bounds.
const ARC_RADIUS_K: float = 0.6
const ARC_TUBE_MIN: float = 0.0014
const ARC_TUBE_MAX: float = 0.0028
const ARC_TUBE_K: float = 0.08
const GHOST_ALPHA: float = 0.22
## Crown reading: bead radius (octahedron half-diagonal).
const BEAD_R: float = 0.011
const GROVE_PITCH: float = 0.85

## lsystem_tree.gd:23-24.
const TRUNK_COLOR: Color = Color(0.45, 0.28, 0.12)
const TIP_COLOR: Color = Color(0.20, 0.65, 0.15)
## The roll, in the family's amber (an accent none of the three members uses for wood).
const ARC_COLOR: Color = Color(1.00, 0.72, 0.30)
const SPOKE_COLOR: Color = Color(0.85, 0.86, 0.90)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("habit"):
		habit = _pick(str(config_data["habit"]), HABITS, habit)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
	if config_data.has("generations"):
		generations = int(config_data["generations"])
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: Array = []
	if layout == "grove":
		for h in HABITS:
			names.append(h)
	else:
		names.append(_pick(habit, HABITS, "planar"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = str(names[i])
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * GROVE_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[i]))


# ── the rule and the turtle ─────────────────────────────────────────────────────────────

## F -> F[+F][-F]F applied `generations` times. lsystem_tree.gd:125-141 shape.
func _derive() -> String:
	var current: String = AXIOM
	for _g in range(generations):
		var next: String = ""
		for ch in current:
			var c: String = ch
			if c == RULE_LHS:
				next += RULE_RHS
			else:
				next += c
		current = next
	return current


## Walk the string. Returns {"segments": [{a, b, depth}], "forks": [{pos, dir, before, after,
## depth, child_len}], "tips": [{pos, depth}]}. Frame is orthonormal (lsystem_tree gd:172-185):
## `+`/`-` tilt dir toward +/- right in the plane spanned by dir and right; `[` pushes, deepens,
## shortens, and ROLLS right about dir by the habit's angle (skipped at exactly 0.0, as the
## members skip it); `]` restores the parent's pre-roll frame, so siblings share one plane.
func _walk(source: String, h: String) -> Dictionary:
	var segments: Array = []
	var forks: Array = []
	var tips: Array = []
	var pos: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3.UP
	var right: Vector3 = Vector3.RIGHT
	var depth: int = 0
	var seg_len: float = SEGMENT_LEN
	var stack: Array = []
	var angle_rad: float = deg_to_rad(FORK_HALF_ANGLE_DEG)
	var roll_rad: float = deg_to_rad(float(HABIT_ROLL.get(h, 0.0)))
	var prev: String = ""
	for ch in source:
		var c: String = ch
		match c:
			"F":
				var b: Vector3 = pos + dir * seg_len
				segments.append({"a": pos, "b": b, "depth": depth})
				pos = b
			"+", "-":
				var axis: Vector3 = dir.cross(right)
				if axis.length_squared() < 1e-6:
					axis = Vector3.FORWARD
				axis = axis.normalized()
				var sgn: float = 1.0 if c == "+" else -1.0
				dir = dir.rotated(axis, sgn * angle_rad).normalized()
				right = right.rotated(axis, sgn * angle_rad).normalized()
			"[":
				stack.append({"pos": pos, "dir": dir, "right": right, "depth": depth, "len": seg_len})
				var before: Vector3 = right
				if roll_rad != 0.0:
					right = right.rotated(dir, roll_rad).normalized()
				# One fork per NODE: a `[` straight after a `]` is the sibling at the same node
				# and gets the same roll from the same restored frame.
				if prev != "]":
					forks.append({"pos": pos, "dir": dir, "before": before, "after": right,
							"depth": depth, "child_len": seg_len * SHORTEN})
				depth += 1
				seg_len *= SHORTEN
			"]":
				tips.append({"pos": pos, "depth": depth})
				if not stack.is_empty():
					var saved: Dictionary = stack.pop_back()
					pos = saved["pos"]
					dir = saved["dir"]
					right = saved["right"]
					depth = saved["depth"]
					seg_len = saved["len"]
		prev = c
	# The trunk's own top is a tip too.
	tips.append({"pos": pos, "depth": 0})
	return {"segments": segments, "forks": forks, "tips": tips}


# ── one variant ─────────────────────────────────────────────────────────────────────────

func _build_variant(holder: Node3D, h: String) -> void:
	var walk: Dictionary = _walk(_derive(), h)
	var segments: Array = walk["segments"]
	var forks: Array = walk["forks"]
	var tips: Array = walk["tips"]
	var max_depth: int = maxi(generations, 1)
	match reading:
		"roll":
			_add_rods(holder, segments, max_depth, GHOST_ALPHA, "Ghost")
			_add_roll_arcs(holder, forks, h)
		"crown":
			var trunk: Array = []
			for s in segments:
				if int(s["depth"]) == 0:
					trunk.append(s)
			_add_rods(holder, trunk, max_depth, 1.0, "Trunk")
			_add_crown(holder, tips)
		_:
			_add_rods(holder, segments, max_depth, 1.0, "Rods")


## All rods of one depth into one mesh; one MeshInstance3D per depth so each carries its
## own colour. Alpha below 1 makes the ghost of the roll reading.
func _add_rods(holder: Node3D, segments: Array, max_depth: int, alpha: float, label: String) -> void:
	for d in range(max_depth + 1):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var has_any: bool = false
		var r: float = ROD_R0 * pow(ROD_SHRINK, float(d))
		for s in segments:
			if int(s["depth"]) != d:
				continue
			_append_prism(st, s["a"], s["b"], r)
			has_any = true
		if not has_any:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "%s_%d" % [label, d]
		mi.mesh = st.commit()
		var c: Color = TRUNK_COLOR.lerp(TIP_COLOR, float(d) / float(maxi(max_depth, 1)))
		c.a = alpha
		mi.material_override = _mat(c, 0.0, alpha < 0.999)
		holder.add_child(mi)


## The roll at every fork: spoke along the parent's plane (before), spoke along the child's
## plane (after), and the arc from one to the other about the parent's axis. At roll 0 the
## spokes coincide and only one is drawn.
func _add_roll_arcs(holder: Node3D, forks: Array, h: String) -> void:
	var roll_rad: float = deg_to_rad(float(HABIT_ROLL.get(h, 0.0)))
	var st_arc := SurfaceTool.new()
	st_arc.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_spoke := SurfaceTool.new()
	st_spoke.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any_arc: bool = false
	for f in forks:
		var p: Vector3 = f["pos"]
		var axis: Vector3 = f["dir"]
		var before: Vector3 = f["before"]
		var after: Vector3 = f["after"]
		var radius: float = ARC_RADIUS_K * float(f["child_len"])
		var tube: float = clampf(ARC_TUBE_K * radius, ARC_TUBE_MIN, ARC_TUBE_MAX)
		_append_prism(st_spoke, p, p + before * radius, tube)
		if roll_rad == 0.0:
			continue
		_append_prism(st_spoke, p, p + after * radius, tube)
		var steps: int = maxi(3, int(ceil(absf(rad_to_deg(roll_rad)) / 9.0)))
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			pts.append(p + before.rotated(axis, roll_rad * t) * radius)
		_append_tube(st_arc, pts, tube)
		any_arc = true
	var mi_s := MeshInstance3D.new()
	mi_s.name = "Spokes"
	mi_s.mesh = st_spoke.commit()
	mi_s.material_override = _mat(SPOKE_COLOR, 0.15, false)
	holder.add_child(mi_s)
	if any_arc:
		var mi_a := MeshInstance3D.new()
		mi_a.name = "Arcs"
		mi_a.mesh = st_arc.commit()
		mi_a.material_override = _mat(ARC_COLOR, 0.45, false)
		holder.add_child(mi_a)


## A bead at every tip, in the vine's leaf colour for its depth (branching_vine.gd:341-342).
func _add_crown(holder: Node3D, tips: Array) -> void:
	var by_depth: Dictionary = {}
	for t in tips:
		var d: int = int(t["depth"])
		if not by_depth.has(d):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			by_depth[d] = st
		_append_octahedron(by_depth[d] as SurfaceTool, t["pos"], BEAD_R)
	var depths: Array = by_depth.keys()
	depths.sort()
	for d in depths:
		var mi := MeshInstance3D.new()
		mi.name = "Tips_%d" % int(d)
		mi.mesh = (by_depth[d] as SurfaceTool).commit()
		var green_val: float = maxf(0.3, 0.9 - float(d) * 0.15)
		mi.material_override = _mat(Color(0.2, green_val, 0.1), 0.12, false)
		holder.add_child(mi)


# ── mesh helpers ────────────────────────────────────────────────────────────────────────

## Perpendicular frame for a direction.
func _frame(t: Vector3) -> Array:
	var seed_axis: Vector3 = Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var n1: Vector3 = t.cross(seed_axis).normalized()
	var n2: Vector3 = t.cross(n1).normalized()
	return [n1, n2]


## A closed six-sided prism from a to b, radius r, appended to st. Normals outward per
## vertex; culling is off in every material anyway.
func _append_prism(st: SurfaceTool, a: Vector3, b: Vector3, r: float) -> void:
	var t: Vector3 = b - a
	if t.length_squared() < 1e-10:
		return
	t = t.normalized()
	var fr: Array = _frame(t)
	var n1: Vector3 = fr[0]
	var n2: Vector3 = fr[1]
	var ring_a: Array = []
	var ring_b: Array = []
	var normals: Array = []
	for k in range(ROD_SIDES):
		var ang: float = TAU * float(k) / float(ROD_SIDES)
		var nrm: Vector3 = n1 * cos(ang) + n2 * sin(ang)
		normals.append(nrm)
		ring_a.append(a + nrm * r)
		ring_b.append(b + nrm * r)
	for k in range(ROD_SIDES):
		var k2: int = (k + 1) % ROD_SIDES
		var na: Vector3 = normals[k]
		var nb: Vector3 = normals[k2]
		_tri(st, ring_a[k], ring_b[k], ring_a[k2], na, na, nb)
		_tri(st, ring_a[k2], ring_b[k], ring_b[k2], nb, na, nb)
		# Caps.
		_tri(st, a, ring_a[k2], ring_a[k], -t, -t, -t)
		_tri(st, b, ring_b[k], ring_b[k2], t, t, t)


## A round tube along a polyline with rotation-minimising frames (regime_threshold's),
## appended to st.
func _append_tube(st: SurfaceTool, pts: PackedVector3Array, r: float) -> void:
	var count: int = pts.size()
	if count < 2:
		return
	var rings: Array = []
	var n1: Vector3 = Vector3.ZERO
	for i in range(count):
		var prev: Vector3 = pts[maxi(i - 1, 0)]
		var next: Vector3 = pts[mini(i + 1, count - 1)]
		var tangent: Vector3 = (next - prev).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3.RIGHT
		if i == 0:
			var fr: Array = _frame(tangent)
			n1 = fr[0]
		else:
			n1 = n1 - tangent * n1.dot(tangent)
			if n1.length_squared() < 1e-8:
				var fr2: Array = _frame(tangent)
				n1 = fr2[0]
			n1 = n1.normalized()
		var n2: Vector3 = tangent.cross(n1).normalized()
		var ring: Array = []
		for k in range(ROD_SIDES):
			var a: float = TAU * float(k) / float(ROD_SIDES)
			var normal: Vector3 = n1 * cos(a) + n2 * sin(a)
			ring.append([pts[i] + normal * r, normal])
		rings.append(ring)
	for i in range(count - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for k in range(ROD_SIDES):
			var k2: int = (k + 1) % ROD_SIDES
			var a0: Array = ra[k]
			var a1: Array = ra[k2]
			var b0: Array = rb[k]
			var b1: Array = rb[k2]
			_tri(st, a0[0], b0[0], a1[0], a0[1], b0[1], a1[1])
			_tri(st, a1[0], b0[0], b1[0], a1[1], b0[1], b1[1])


## An octahedron of half-diagonal r at p: six vertices, eight faces, face normals.
func _append_octahedron(st: SurfaceTool, p: Vector3, r: float) -> void:
	var px: Vector3 = p + Vector3(r, 0.0, 0.0)
	var nx: Vector3 = p - Vector3(r, 0.0, 0.0)
	var py: Vector3 = p + Vector3(0.0, r, 0.0)
	var ny: Vector3 = p - Vector3(0.0, r, 0.0)
	var pz: Vector3 = p + Vector3(0.0, 0.0, r)
	var nz: Vector3 = p - Vector3(0.0, 0.0, r)
	var faces: Array = [
		[py, px, pz], [py, pz, nx], [py, nx, nz], [py, nz, px],
		[ny, pz, px], [ny, nx, pz], [ny, nz, nx], [ny, px, nz],
	]
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var c: Vector3 = f[2]
		var n: Vector3 = ((a + b + c) / 3.0 - p).normalized()
		_tri(st, a, b, c, n, n, n)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


func _mat(c: Color, emit: float, translucent: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if translucent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
