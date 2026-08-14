## residue_hall — what remains of a walk, asked of three walks at once.
##
## THE FAMILY. Four artifacts run a walk and share one vocabulary for what survives it:
## head, tail, path, envelope, ensemble. The census read them as three vocabularies and was
## wrong — all four declare the identical five values and differ only in DECLARATION ORDER
## (PipeDream opens on `head`, random_walk_leash on `tail`), which doc/reports/
## VOCABULARY_SPLIT.md rules is a decision and not a disagreement. The word is honest.
##
## LAW 16, ANSWERED FROM THE MEMBERS' CODE: THE VALUES NEST, so `residue` is the AXIS and
## the members are the exhibit. The evidence is not the prose, it is the dispatch:
##
##   - All four hold RESIDUE_RUNGS as an INTEGER dictionary {head:0, tail:1, path:2,
##     envelope:3, ensemble:4} — PipeDream.gd:154-160, RandomWalk128Algorithm.gd:118-124,
##     random_walk_leash.gd:125-131, random_walk_collection.gd:95-101. No member ever
##     matches on the WORD once the reader has resolved it.
##   - Every gate is `>=`, not `==`. PipeDream draws the pipe at `rung >= 1`, adds rails at
##     `rung >= 3`, adds ghosts at `rung >= 4`. RandomWalk128 raises the field at `rung >= 2`,
##     refreshes the rail at `r >= 3`, builds ghosts at `r >= 4`.
##
## A rung therefore CONTAINS every rung below it. This hall reproduces that: each value adds
## to the last, and the sheet reads as accumulation rather than as five alternatives.
##
## WHAT `envelope` MEANS HERE — and it is the wave's question, because `aftermath` declares
## the same word. In THIS family an envelope is measured BACKWARDS off the walk's own record:
## an A-POSTERIORI HULL. pipe_dream seeds an AABB at _points[0] with zero size and grows it
## over every recorded turn; random_walk_128 runs four integer compares per landing against
## extents initialised to Vector2i(32,32)/Vector2i(-1,-1) and rebuilds its fence only when the
## rectangle grows. The bound is not a rule the walk was given. It is a fact discovered about
## the walk after the fact, and it can only shrink to fit by being rebuilt from scratch.
##
##   (In `aftermath`, the same word means the opposite: the region a growth's demand was
##   SAMPLED FROM, fixed before anything grew — branching_growth draws its cage at
##   FIELD_RADIUS := 3.0, the same literal as the attractor radius, and its own comment says
##   a cage at any other radius would be decoration rather than boundary. A-priori permission
##   against a-posteriori hull: same five letters, opposite direction in time.)
##
## THE SECOND AXIS IS `tenure`, AND THE FAMILY NEVER NAMED IT. Every member exposes step
## counts only as run parameters — max_segments 180, total_steps 10000, initial_steps
## randi_range(20,80) — and never as a reading. Three of the four source readers filed the
## same correction without coordinating: the shipped dna.fixture blocks pin `walk_seed` and
## omit any age control, so every published sweep of this family has photographed whatever
## length the clock happened to reach. tenure fixes that by taking a strict PREFIX of one
## seeded run: fresh 25%, worked 60%, spent 100%. It cannot borrow signal from residue —
## residue chooses which marks are drawn, tenure chooses how much walk exists to mark.
##
## LAW 1: NO BAR, NO SLAT, NO RACK, NO PAD. A walk here is a polyline in real lattice
## coordinates, a mound with real visit counts, and a tangle against a real hard clamp.
extends Node3D
class_name ResidueHall

## The family's list, character for character, in the order three of four members declare it.
@export_enum("head", "tail", "path", "envelope", "ensemble") var residue: String = "path"
const RESIDUES: PackedStringArray = ["head", "tail", "path", "envelope", "ensemble"]

## How much walk there is to remain of. Declared SECOND because build_dna_gallery trims from
## the end of the later axis and drops one trimmed below two values; 5 x 3 = 15 fits a cap of
## 16 whole.
@export_enum("worked", "spent", "fresh") var tenure: String = "worked"
const TENURES: PackedStringArray = ["worked", "spent", "fresh"]

## LAW 6. Every walk in this hall is drawn from this seed and nothing else. Two builds of one
## variant are pixel-identical; that is not a nicety here, because five variants of an
## unseeded walk are five different walks and every measured number would be a fact about
## five objects rather than five readings of one.
@export var walk_seed: int = 20260814

# ── the three bays ───────────────────────────────────────────────────────────
# A row along +X, no shared plinth: each bay carries its member's own ground. The camera's
# screen-x direction is (0.8139, 0, -0.5810), so a 2x2 court would project its middle bays
# only 0.233 * pitch apart and overlap heavily; a row along X keeps the union's z extent at
# one bay's depth. A vertical stack would read as a rack, which law 1 bans.
## PITCH SET FROM THE BODIES, NOT FROM TASTE, AND CORRECTED AFTER THE FIRST SWEEP. The first
## capture used +/-1.5626 and measured subject 1.3% of frame: the union box was 85% of frame
## WIDTH and only 7% FULL, because three bodies of 0.68-0.80 m were spread over 3.9 m and the
## camera had to retreat far enough to hold the gaps. The widest tenants are the field carpet
## (0.800 m) and the leash ring (2 * 0.34 = 0.680 m), so half-extents are 0.400 and 0.340; at
## pitch 0.95 the daylight between neighbours is 0.95 - 0.400 - 0.340 = 0.210 m, still clear
## at the widest variant of both axes, and the union narrows 3.925 -> 2.700 m.
const BAY_X: Array = [-0.95, 0.0, 0.95]
const BAY_NAME: PackedStringArray = ["random_walk_128", "pipe_dream", "random_walk_leash"]

# ── bay 1: the field (random_walk_128) ───────────────────────────────────────
# 32x32 lattice, one cube per DISTINCT visited cell, height = visit count. The source's own
# geometry: offset = -GRID_AREA_SIZE/2 + CUBE_SIZE/2 so the field spans exactly +/-0.400 m at
# this scale, and the start cell is Vector2i(16,16) — half a cube off centre, as shipped.
const GRID_N: int = 32
const FIELD_CUBE: float = 0.025
const FIELD_HALF: float = 0.400
const RAISE_AMOUNT: float = 0.02
const FIELD_STEPS: int = 900

# ── bay 2: the pipe (pipe_dream) ─────────────────────────────────────────────
# An axis-aligned pipe that turns on a lattice. Radius is the source's, scaled.
const PIPE_R: float = 0.018
const PIPE_STEP: float = 0.075
const PIPE_SEGMENTS: int = 96

# ── bay 3: the leash (random_walk_leash) ─────────────────────────────────────
# A walk with a HARD CLAMP: the step is taken, then the position is pulled back inside a
# sphere. That clamp is why this member's envelope inverts — see dna.note. The tether is
# drawn because it is the constraint, not decoration.
const LEASH_R: float = 0.34
const LEASH_STEP: float = 0.055
const LEASH_SEGMENTS: int = 150

const TAIL_FRACTION: float = 0.22      ## `tail` shows this much of the record, ramped
const GHOST_COUNT: int = 3             ## `ensemble` adds this many other seeds

# Palettes, taken from the members rather than invented.
const FIELD_TINT := Color(0.98, 0.76, 0.91)     ## Grid.gdshader emissionColor
const FIELD_BODY := Color(0.16, 0.15, 0.20)
const PIPE_TINT := Color(0.45, 0.85, 1.0)
const LEASH_TINT := Color(0.55, 1.0, 0.70)
const FENCE_TINT := Color(1.0, 0.55, 0.18)      ## the only warm thing in the hall
const GHOST_TINT := Color(0.42, 0.52, 0.72)
const HEAD_TINT := Color(1.0, 0.93, 0.45)

var _rng := RandomNumberGenerator.new()
var _owned: Array[Node] = []


func _ready() -> void:
	_check_hints()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("residue"):
		var r: String = str(config_data["residue"]).strip_edges().to_lower()
		if RESIDUES.has(r):
			residue = r
	if config_data.has("tenure"):
		var t: String = str(config_data["tenure"]).strip_edges().to_lower()
		if TENURES.has(t):
			tenure = t
	if config_data.has("walk_seed"):
		walk_seed = int(config_data["walk_seed"])
	_rebuild()


## The declaration cannot drift from the code: read each hint_string back out of the live
## property list and compare to the const list in BOTH directions and IN ORDER. A registry
## that disagrees with this is caught at _ready rather than three gates later.
func _check_hints() -> void:
	for pair in [["residue", RESIDUES], ["tenure", TENURES]]:
		var key: String = pair[0]
		var want: PackedStringArray = pair[1]
		for p in get_property_list():
			if String(p.get("name", "")) != key:
				continue
			var got := PackedStringArray()
			for part in String(p.get("hint_string", "")).split(",", false):
				got.append(part.split(":")[0].strip_edges())
			if got != want:
				push_error("residue_hall: '%s' hint %s does not match const %s" % [key, got, want])
			break


func _rebuild() -> void:
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_build()


func _own(n: Node3D) -> void:
	add_child(n)
	_owned.append(n)


## Rung arithmetic. Every gate below is `>=`, mirroring all four members: a rung contains
## every rung beneath it, so the sheet accumulates rather than substituting.
func _rung() -> int:
	return maxi(RESIDUES.find(residue), 0)


## `tenure` as a strict prefix of one seeded run.
func _tenure_fraction() -> float:
	match tenure:
		"fresh":
			return 0.25
		"spent":
			return 1.0
		_:
			return 0.60


func _build() -> void:
	_build_field(BAY_X[0])
	_build_pipe(BAY_X[1])
	_build_leash(BAY_X[2])


# ═══════════════════════════════════════════════════════════════════════════
# BAY 1 — THE FIELD. A lattice walk that RAISES the ground it lands on, so the
# residue is a mound. This is the only bay whose record is an accumulation
# rather than a trace, which is why its `path` and its `envelope` differ in kind.
# ═══════════════════════════════════════════════════════════════════════════
func _build_field(x: float) -> void:
	var root := Node3D.new()
	root.name = "bay_field"
	root.position = Vector3(x, 0.0, 0.0)
	_own(root)

	_rng.seed = walk_seed
	var steps: int = int(FIELD_STEPS * _tenure_fraction())
	var visits := {}
	var cell := Vector2i(16, 16)
	var trail: Array[Vector2i] = [cell]
	var lo := cell
	var hi := cell
	# The source's own step: four unit directions, CLAMPED to [0,31]. Never reflected,
	# never stopped — a clamped walk spends real time pinned against its wall, and that
	# is visible in the corners of the mound.
	for i in steps:
		var d: int = _rng.randi() % 4
		if d == 0:
			cell.x += 1
		elif d == 1:
			cell.x -= 1
		elif d == 2:
			cell.y += 1
		else:
			cell.y -= 1
		cell.x = clampi(cell.x, 0, GRID_N - 1)
		cell.y = clampi(cell.y, 0, GRID_N - 1)
		visits[cell] = int(visits.get(cell, 0)) + 1
		trail.append(cell)
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))

	var rung: int = _rung()
	# rung >= 2 (`path`) is where the accumulated ground appears at all — below it the
	# record is only the walker and its recent window, exactly as _cube_y returns 0.0
	# below rung 2 in the source.
	if rung >= 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		var box := BoxMesh.new()
		box.size = Vector3(FIELD_CUBE, FIELD_CUBE, FIELD_CUBE)
		mm.mesh = box
		mm.instance_count = visits.size()
		var idx: int = 0
		for c in visits:
			var n: int = visits[c]
			var h: float = RAISE_AMOUNT * float(n)
			var p := _cell_to_local(c)
			var t := Transform3D()
			t = t.scaled(Vector3(1.0, maxf(h / FIELD_CUBE, 1.0), 1.0))
			t.origin = Vector3(p.x, h * 0.5, p.y)
			mm.set_instance_transform(idx, t)
			mm.set_instance_color(idx, FIELD_BODY.lerp(FIELD_TINT, clampf(float(n) / 6.0, 0.0, 1.0)))
			idx += 1
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.emission_enabled = true
		mat.emission = FIELD_TINT
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.55
		mmi.material_override = mat
		root.add_child(mmi)
		# LAW 11: the capture AABB counts MeshInstance3D only, so a MultiMesh body measures
		# as a 1 m box unless an anchor states the real extent. layers = 0 keeps it out of
		# the render while leaving it in the merge.
		_anchor(root, Vector3(FIELD_HALF * 2.0, 0.30, FIELD_HALF * 2.0), Vector3(0, 0.15, 0))

	# rung 1 (`tail`) — the recent window, ramped, drawn as standing pins so the direction
	# of travel is legible. Present at every rung above it too.
	if rung >= 1:
		var window: int = maxi(int(trail.size() * TAIL_FRACTION), 2)
		var start: int = maxi(trail.size() - window, 0)
		for i in range(start, trail.size()):
			var f: float = float(i - start + 1) / float(trail.size() - start)
			var p := _cell_to_local(trail[i])
			var h: float = 0.012 + 0.10 * f
			_pin(root, Vector3(p.x, h * 0.5, p.y), h, 0.006, PIPE_TINT.lerp(FIELD_TINT, f), 1.1)

	# rung 0 (`head`) — where it ended. Always drawn: every rung contains it.
	var head := _cell_to_local(trail[trail.size() - 1])
	_ball(root, Vector3(head.x, 0.055, head.y), 0.024, HEAD_TINT, 2.4)

	# rung >= 3 (`envelope`) — the A-POSTERIORI hull. Built from lo/hi, which were grown by
	# comparison at every landing and never given in advance. A wire fence, never a shell,
	# because the source draws one unshaded cylinder per box edge.
	if rung >= 3:
		var a := _cell_to_local(lo) - Vector2(FIELD_CUBE * 0.5, FIELD_CUBE * 0.5)
		var b := _cell_to_local(hi) + Vector2(FIELD_CUBE * 0.5, FIELD_CUBE * 0.5)
		_fence(root, a, b, 0.16)

	# rung 4 (`ensemble`) — the same law at other seeds, so the reader can see which parts
	# of the record are the law and which are this particular walk.
	if rung >= 4:
		for g in GHOST_COUNT:
			_rng.seed = walk_seed + 1000 * (g + 1)
			var gc := Vector2i(16, 16)
			var pts := PackedVector3Array()
			for i in int(steps * 0.7):
				var d2: int = _rng.randi() % 4
				if d2 == 0:
					gc.x += 1
				elif d2 == 1:
					gc.x -= 1
				elif d2 == 2:
					gc.y += 1
				else:
					gc.y -= 1
				gc.x = clampi(gc.x, 0, GRID_N - 1)
				gc.y = clampi(gc.y, 0, GRID_N - 1)
				if i % 6 == 0:
					var q := _cell_to_local(gc)
					pts.append(Vector3(q.x, 0.02 + 0.004 * float(g), q.y))
			_polyline(root, pts, 0.004, GHOST_TINT, 0.5)


func _cell_to_local(c: Vector2i) -> Vector2:
	var off: float = -FIELD_HALF + FIELD_CUBE * 0.5
	return Vector2(off + float(c.x) * FIELD_CUBE, off + float(c.y) * FIELD_CUBE)


# ═══════════════════════════════════════════════════════════════════════════
# BAY 2 — THE PIPE. A walk whose record IS its body: an axis-aligned pipe that
# turns on a lattice and cannot cross itself. Its residue is the pipe run.
# ═══════════════════════════════════════════════════════════════════════════
func _build_pipe(x: float) -> void:
	var root := Node3D.new()
	root.name = "bay_pipe"
	root.position = Vector3(x, 0.34, 0.0)
	_own(root)

	_rng.seed = walk_seed + 7
	var n: int = int(PIPE_SEGMENTS * _tenure_fraction())
	var dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
	var p := Vector3.ZERO
	var d: Vector3 = dirs[0]
	var pts := PackedVector3Array([p])
	var turns := PackedVector3Array()
	var lo := p
	var hi := p
	for i in n:
		# Turn on a lattice: keep going, or pick a perpendicular. The turn points are the
		# record pipe_dream itself keeps, and they are what its AABB is grown over.
		if _rng.randf() < 0.34:
			var nd: Vector3 = dirs[_rng.randi() % 6]
			if absf(nd.dot(d)) < 0.5:
				d = nd
				turns.append(p)
		p += d * PIPE_STEP
		p.x = clampf(p.x, -0.42, 0.42)
		p.y = clampf(p.y, -0.30, 0.30)
		p.z = clampf(p.z, -0.30, 0.30)
		pts.append(p)
		lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))

	var rung: int = _rung()
	if rung >= 2:
		_polyline(root, pts, PIPE_R, PIPE_TINT, 1.3)
	if rung >= 1:
		var window: int = maxi(int(pts.size() * TAIL_FRACTION), 2)
		var start: int = maxi(pts.size() - window, 0)
		var tail := PackedVector3Array()
		for i in range(start, pts.size()):
			tail.append(pts[i])
		_polyline(root, tail, PIPE_R * 1.35, HEAD_TINT, 2.0)
	_ball(root, pts[pts.size() - 1], PIPE_R * 1.9, HEAD_TINT, 2.6)
	if rung >= 3:
		_wire_box(root, lo, hi, 0.005, FENCE_TINT, 1.6)
	if rung >= 4:
		for g in GHOST_COUNT:
			_rng.seed = walk_seed + 7 + 1000 * (g + 1)
			var gp := Vector3.ZERO
			var gd: Vector3 = dirs[0]
			var gpts := PackedVector3Array([gp])
			for i in int(n * 0.7):
				if _rng.randf() < 0.34:
					var nd2: Vector3 = dirs[_rng.randi() % 6]
					if absf(nd2.dot(gd)) < 0.5:
						gd = nd2
				gp += gd * PIPE_STEP
				gp.x = clampf(gp.x, -0.42, 0.42)
				gp.y = clampf(gp.y, -0.30, 0.30)
				gp.z = clampf(gp.z, -0.30, 0.30)
				gpts.append(gp)
			_polyline(root, gpts, PIPE_R * 0.32, GHOST_TINT, 0.5)


# ═══════════════════════════════════════════════════════════════════════════
# BAY 3 — THE LEASH. A walk taken, then PULLED BACK inside a sphere. The clamp
# is given in advance, so this member's envelope is the one place in the family
# where the bound is a-priori — the inversion the readers found, drawn rather
# than argued.
# ═══════════════════════════════════════════════════════════════════════════
func _build_leash(x: float) -> void:
	var root := Node3D.new()
	root.name = "bay_leash"
	root.position = Vector3(x, 0.34, 0.0)
	_own(root)

	_rng.seed = walk_seed + 31
	var n: int = int(LEASH_SEGMENTS * _tenure_fraction())
	var p := Vector3.ZERO
	var pts := PackedVector3Array([p])
	var pinned: int = 0
	for i in n:
		var step := Vector3(_rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0))
		if step.length() > 0.0001:
			step = step.normalized() * LEASH_STEP
		p += step
		if p.length() > LEASH_R:
			p = p.normalized() * LEASH_R
			pinned += 1
		pts.append(p)

	var rung: int = _rung()
	if rung >= 2:
		_polyline(root, pts, 0.009, LEASH_TINT, 1.2)
	if rung >= 1:
		var window: int = maxi(int(pts.size() * TAIL_FRACTION), 2)
		var start: int = maxi(pts.size() - window, 0)
		var tail := PackedVector3Array()
		for i in range(start, pts.size()):
			tail.append(pts[i])
		_polyline(root, tail, 0.013, HEAD_TINT, 2.0)
	_ball(root, pts[pts.size() - 1], 0.022, HEAD_TINT, 2.6)
	# THE INVERSION, drawn: this envelope is the leash itself — a bound the walk was GIVEN,
	# identical at every seed and every tenure, and the walk is pinned against it `pinned`
	# times rather than discovering it. The tether from origin to head says so.
	if rung >= 3:
		_ring(root, LEASH_R, 0.004, FENCE_TINT, 1.7)
		_polyline(root, PackedVector3Array([Vector3.ZERO, pts[pts.size() - 1]]), 0.003,
				FENCE_TINT, 1.0)
	if rung >= 4:
		for g in GHOST_COUNT:
			_rng.seed = walk_seed + 31 + 1000 * (g + 1)
			var gp := Vector3.ZERO
			var gpts := PackedVector3Array([gp])
			for i in int(n * 0.7):
				var s2 := Vector3(_rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0))
				if s2.length() > 0.0001:
					s2 = s2.normalized() * LEASH_STEP
				gp += s2
				if gp.length() > LEASH_R:
					gp = gp.normalized() * LEASH_R
				gpts.append(gp)
			_polyline(root, gpts, 0.003, GHOST_TINT, 0.5)


# ── drawing helpers ──────────────────────────────────────────────────────────

func _mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.metallic = 0.1
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _polyline(parent: Node3D, pts: PackedVector3Array, r: float, c: Color, e: float) -> void:
	if pts.size() < 2:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	mm.mesh = cyl
	mm.instance_count = pts.size() - 1
	for i in range(pts.size() - 1):
		mm.set_instance_transform(i, _between(pts[i], pts[i + 1]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat(c, e)
	parent.add_child(mmi)


## A cylinder transform spanning a to b. The basis is built explicitly rather than with
## look_at, which is undefined when the segment is parallel to UP — a lattice walk produces
## exactly that on every vertical step.
func _between(a: Vector3, b: Vector3) -> Transform3D:
	var d := b - a
	var len_m: float = d.length()
	if len_m < 0.00001:
		return Transform3D(Basis().scaled(Vector3(1, 0.00001, 1)), a)
	var up := d / len_m
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var side := ref.cross(up).normalized()
	var fwd := up.cross(side).normalized()
	var basis := Basis(side, up * len_m, fwd)
	return Transform3D(basis, (a + b) * 0.5)


func _pin(parent: Node3D, at: Vector3, h: float, r: float, c: Color, e: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = h
	cyl.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position = at
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


func _ball(parent: Node3D, at: Vector3, r: float, c: Color, e: float) -> void:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.position = at
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


## The measured fence: one cylinder per edge of the rectangle the walk turned out to occupy.
func _fence(parent: Node3D, a: Vector2, b: Vector2, h: float) -> void:
	var corners := [Vector3(a.x, 0, a.y), Vector3(b.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(a.x, 0, b.y)]
	for i in 4:
		var p0: Vector3 = corners[i]
		var p1: Vector3 = corners[(i + 1) % 4]
		_polyline(parent, PackedVector3Array([p0, p1]), 0.004, FENCE_TINT, 1.6)
		_polyline(parent, PackedVector3Array([p0, p0 + Vector3.UP * h]), 0.004, FENCE_TINT, 1.6)
		_polyline(parent, PackedVector3Array([p0 + Vector3.UP * h, p1 + Vector3.UP * h]),
				0.004, FENCE_TINT, 1.6)


func _wire_box(parent: Node3D, lo: Vector3, hi: Vector3, r: float, c: Color, e: float) -> void:
	var v := []
	for ix in 2:
		for iy in 2:
			for iz in 2:
				v.append(Vector3(lo.x if ix == 0 else hi.x, lo.y if iy == 0 else hi.y,
						lo.z if iz == 0 else hi.z))
	var edges := [[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6],
			[3, 7], [4, 5], [4, 6], [5, 7], [6, 7]]
	for ed in edges:
		_polyline(parent, PackedVector3Array([v[ed[0]], v[ed[1]]]), r, c, e)


func _ring(parent: Node3D, radius: float, r: float, c: Color, e: float) -> void:
	var segs: int = 40
	var pts := PackedVector3Array()
	for i in segs + 1:
		var a: float = TAU * float(i) / float(segs)
		pts.append(Vector3(cos(a) * radius, 0.0, sin(a) * radius))
	_polyline(parent, pts, r, c, e)


## An invisible mesh that states a MultiMesh body's real extent to the capture AABB.
func _anchor(parent: Node3D, size: Vector3, at: Vector3) -> void:
	var b := BoxMesh.new()
	b.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = at
	mi.layers = 0
	parent.add_child(mi)
