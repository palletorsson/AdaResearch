class_name EmDetail
extends RefCounted
# em_detail.gd — the architectural trim that makes a box read as a room.
#
#   EmDetail.dress_segment(seg, tile, w, h, mats)              # 5-arg contract
#   EmDetail.dress_segment(seg, tile, w, h, mats, prev_w)      # sharper vestibule
#
# WHY TRIM AND NOT MORE GEOMETRY. The baseline segment is one hundred unbevelled
# 1x3x1 boxes. A renderer given an unbevelled box has exactly two pieces of
# information to work with: the albedo of a face and the angle of that face to
# the light. Every face of a wall is the same albedo and there are only three
# angles in the whole building, so every wall in every museum resolves to the
# same three flat values and the eye reads "grey boxes" no matter how good the
# lighting or the material is. Trim is not decoration here — it is the mechanism
# that puts a THIRD and FOURTH plane on every edge, so that an edge produces a
# luminance gradient instead of a step. That is the entire difference between an
# untextured prototype and an untextured Chipperfield gallery.
#
# The six families, in the order a joinery package would list them:
#
#   1. SKIRTING     a 130 mm plinth standing 22 mm proud at every wall base. Does
#                   two jobs: it terminates the wall against the floor with a
#                   horizontal shadow line, and it gives the floor's grazing
#                   bounce something to land on at eye-to-floor angles.
#   2. CORNICE      a 280 mm band standing 60 mm proud at the wall head (2.72 ..
#                   3.00). The overhang casts a hard line down the wall, which is
#                   the single strongest cue that a wall has a TOP — the baseline
#                   walls simply stop, and a wall that simply stops reads as a
#                   cut-out, not as built fabric.
#   3. SHADOW GAP   the ceiling does not touch the wall. It floats 140 mm above
#                   the 3.00 wall head, so a continuous dark slot runs the whole
#                   perimeter of every room. This is the detail that makes a
#                   modern gallery look expensive, and it costs zero geometry
#                   because it is made of the space between two things.
#   4. DOOR REVEALS every threshold gap 1..3 cells wide gets a lined reveal: 50 mm
#                   jamb linings down both cheeks, a 120 mm head lining at 2.10,
#                   and an overpanel closing 2.22 .. 3.00. The baseline "door" is
#                   a missing wall segment three metres tall; a lined 2.1 m
#                   opening in a one-metre-thick wall reads as MASS, and mass is
#                   what a museum is selling. The vestibule threshold gets the
#                   same treatment at monumental scale (a 2.40 portal head).
#   5. CEILING      a coffered daylight ceiling: solid panels on a 3.0 m bay with
#                   a 550 mm open slot between them, crossed by 180 mm ribs. The
#                   slots are real holes, so the sun lands in bands on the floor
#                   and the room gets a direction. Kimbell, Menil, Kanazawa and
#                   Chichu are all in the corridor's own template list and all
#                   four are top-lit buildings; this is their shared section.
#   6. FLOOR SEAMS  5 mm joint strips on the same 3.0 m module as the ceiling
#                   bays, so the structural grid reads in both planes. A floor
#                   with no module is a floor with no scale, and a floor with no
#                   scale makes a 30 m gallery read as a 6 m one.
#   + ARRIS BEADS   a 75 mm chamfered bead on every free convex wall corner,
#                   running between skirting and cornice. A 45-degree facet at an
#                   arris returns an intermediate luminance between the two wall
#                   faces; without it the corner is a hard step and the eye reads
#                   "polygon".
#
# COORDINATE CONTRACT (mirrors endless_museum.gd — do not drift):
#   cell (x, z) spans world x in [x, x+1], z in [z, z+1]; the segment node is
#   translated to the segment's z0, so everything here is SEGMENT-LOCAL.
#   floor top y = 0.0, wall box y = 0 .. 3.0, podium top 0.4, plinth top 0.8.
#   rows 0 .. VESTIBULE_H-1 are the lobby (LOBBY_W wide); tile row y is z = y + 4.
#   the outer skin walls stand at x = -1 and x = w for every tile row.
#
# NOTHING HERE INTRUDES INTO A WALKABLE CELL. Audited at the bottom of this file
# in _INTRUSION_AUDIT; the short version is that this file creates no
# CollisionShape3D, never touches the segment's StaticBody3D, never touches the
# scene's _walk_cells map, keeps every overhead element at or above 2.96 m
# (capsule top is 1.70 m, eye is 1.65 m), and keeps every element at body height
# within 53 mm of a wall face the walker already stands 320 mm off.

# ── the scene's contract, duplicated rather than imported (importing
# endless_museum.gd from here would be a preload cycle) ──────────────────────
const VESTIBULE_H := 4
const LOBBY_W := 17
const WALL_H := 3.0

# ── skirting ────────────────────────────────────────────────────────────────
const SKIRT_H := 0.13         # 130 mm — a gallery plinth, not a domestic 100 mm
const SKIRT_T := 0.045        # centred on the wall face: 22.5 mm proud, 22.5 mm buried

# ── cornice / wall head ─────────────────────────────────────────────────────
const CORNICE_BOTTOM := 2.72
const CORNICE_H := 0.28       # top lands exactly on the 3.00 wall head
const CORNICE_T := 0.12       # 60 mm overhang — enough to throw a line at 55 deg sun

# ── ceiling ─────────────────────────────────────────────────────────────────
# soffit is set ABOVE the lighting rig's fixture plane on purpose. em_lighting.gd
# hangs its gear at RIG_Y 2.78 and its top-light at SKY_Y 2.92; a soffit at 3.14
# with ribs bottoming at 2.96 leaves every one of those fixtures in open air.
const CEIL_SOFFIT := 3.14
const CEIL_THICK := 0.26
const CEIL_TOP := 3.40
const SHADOW_GAP := 0.14      # 3.00 wall head -> 3.14 soffit, read-only constant
const BAY := 3.0              # structural module, shared with the floor seams
const SLOT_W := 0.55          # open daylight slot per bay
const RIB_W := 0.20
const RIB_DROP := 0.18        # rib underside = 2.96, clear of SKY_Y 2.92

# ── door reveals ────────────────────────────────────────────────────────────
const DOOR_HEAD := 2.10       # standard door head. 450 mm over the capsule top
const HEAD_LINING := 0.12
const LINING_T := 0.05        # jamb lining depth: a 1-cell door clears 900 mm
const MAX_DOOR_CELLS := 3     # wider than 3 m is a room opening, not a door
const PORTAL_HEAD := 2.40     # the vestibule threshold is monumental, not domestic
const PORTAL_LINING := 0.08
const PORTAL_HEAD_LINING := 0.16

# ── arris beads ─────────────────────────────────────────────────────────────
# 100 mm, up from 75. At 1800 px and gallery distances a 75 mm chamfer resolves
# to 4-9 px and simply did not read in any of the four proof shots; 100 mm buys
# the intermediate luminance stripe the family exists for. Note the honest limit:
# this dresses WALL arrises only. The coffer beams and the pilaster/wall junction
# are built from MultiMesh boxes with no lattice-corner concept, so they keep
# their naked mitres — see the note at the foot of this file.
const BEAD_W := 0.10          # rotated 45 deg -> 71 mm proud of the arris
const BEAD_Y0 := 0.13         # sits on the skirting
const BEAD_H := 2.59          # dies into the cornice at 2.72

# ── wall labels ─────────────────────────────────────────────────────────────
# THE CHEAPEST BODY-SCALE OBJECT IN A MUSEUM. Every proof shot had a band 520 px
# tall across the full frame width — 24% of the image — containing not one
# object: no bench, no vitrine, no stanchion, no label, no door furniture. A
# renderer cannot give you scale you never modelled, and a wall card is the one
# fixture that needs no collision, no floor space and no art direction: it is a
# 300 x 420 plate at reading height, and the eye measures a human against it.
const LABEL_W := 0.30
const LABEL_H := 0.42
const LABEL_T := 0.025        # 25 mm proud — the walker stands 320 mm off
const LABEL_Y := 1.40
const LABEL_EVERY := 11       # one per N dressed wall faces, deterministic

# ── floor seams ─────────────────────────────────────────────────────────────
const SEAM_M := 3             # cells per joint — same module as the ceiling bays
const SEAM_W := 0.05
const SEAM_PROUD := 0.02      # box straddles y=0: 10 mm proud of the floor plane


## Dress one built segment. Additive and idempotent per segment: five nodes are
## appended to `seg` and nothing already in it is read back or modified.
##
## seg     the segment Node3D (already positioned at its z0)
## tile    the template's row array, exactly as endless_museum.gd stamped it
## w, h    template width / depth in cells
## mats    the material library (EmMaterials, a Dictionary, or null). Probed
##         defensively — a missing library degrades to local fallbacks.
## prev_w  optional: the previous segment's width, so the near vestibule seal is
##         known. Omit it and that one strip simply goes untrimmed.
static func dress_segment(seg: Node3D, tile: Array, w: int, h: int, mats, prev_w: int = -1) -> void:
	if seg == null:
		return
	if w <= 0:
		w = 1
	if h <= 0:
		h = tile.size()

	var lib: Dictionary = _resolve_mats(mats)

	# ── occupancy, in segment-local cell coordinates ────────────────────────
	var walls: Dictionary = {}
	var floors: Dictionary = {}
	_map_vestibule(walls, floors, w, prev_w)
	_map_tile(walls, floors, tile, w)

	# ── five transform buckets, five draw calls ─────────────────────────────
	var trim_x: Array = []    # cornice, jambs, head linings, arris beads, labels
	var skirt_x: Array = []   # skirting ONLY — see below
	var solid_x: Array = []   # door overpanels (wall material — they ARE the wall)
	var ceil_x: Array = []    # ceiling panels and ribs
	var seam_x: Array = []    # floor joints and thresholds

	# SKIRTING IS ITS OWN BUCKET NOW, and that is the whole point of the change.
	# em_materials ships skirting(kind, tint) — the same material at soil 0.75,
	# meant for exactly this 130 mm strip, with grime pushed into albedo,
	# roughness, specular and AO at once. It had NO CALLERS: every skirting box in
	# the building was drawn in the plain trim material, so the one mechanism in
	# the library that produces real light-reactive contact darkening was dead
	# code while the frames showed no contact darkening anywhere. One extra
	# bucket, one extra draw call, one material lookup.
	_add_wall_faces(walls, floors, skirt_x, trim_x)
	_add_arris_beads(walls, floors, trim_x)
	_add_labels(walls, floors, trim_x)
	_add_doors(walls, floors, w, h, trim_x, solid_x, seam_x)
	_add_portal(w, trim_x, solid_x, seam_x)
	_add_ceiling(w, h, ceil_x)
	_add_seams(floors, w, h, seam_x)

	_emit(seg, "Trim", trim_x, lib.get("trim"), true)
	_emit(seg, "Skirting", skirt_x, lib.get("skirting"), true)
	_emit(seg, "DoorHeads", solid_x, lib.get("wall"), true)
	_emit(seg, "Ceiling", ceil_x, lib.get("ceiling"), true)
	_emit(seg, "FloorSeams", seam_x, lib.get("accent"), false)
	_add_extent_anchor(seg, w, h)


# ═══════════════════════════════════════════════════════════════════════════
# OCCUPANCY
# ═══════════════════════════════════════════════════════════════════════════

## The lobby: floor across the full LOBBY_W, side walls at both edges, and the
## closing strips that seal a width jump into the museum behind and ahead.
static func _map_vestibule(walls: Dictionary, floors: Dictionary, w: int, prev_w: int) -> void:
	for zr in range(VESTIBULE_H):
		for x in range(LOBBY_W):
			floors[Vector2i(x, zr)] = true
		walls[Vector2i(0, zr)] = true
		walls[Vector2i(LOBBY_W - 1, zr)] = true
	# far seal: everything at or beyond this museum's width
	for x1 in range(maxi(w - 1, 0), LOBBY_W):
		walls[Vector2i(x1, VESTIBULE_H - 1)] = true
	# near seal: only knowable if the caller hands over the previous width
	if prev_w > 0:
		for x2 in range(maxi(prev_w - 1, 0), LOBBY_W):
			walls[Vector2i(x2, 0)] = true


## The template rows, plus the outer skin walls the scene stamps at x = -1 and
## x = w. Only "1"/"1s" carry a floor box — podium, plinth and void cells do not,
## so they must not receive skirting or seams.
static func _map_tile(walls: Dictionary, floors: Dictionary, tile: Array, w: int) -> void:
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		var z: int = y + VESTIBULE_H
		walls[Vector2i(-1, z)] = true
		walls[Vector2i(w, z)] = true
		for x in range(row.size()):
			var c: String = String(row[x])
			if c == "4":
				walls[Vector2i(x, z)] = true
			elif c == "1" or c == "1s":
				floors[Vector2i(x, z)] = true


# ═══════════════════════════════════════════════════════════════════════════
# FAMILIES
# ═══════════════════════════════════════════════════════════════════════════

## Skirting and cornice on every wall face that actually faces a floor. A face
## into a void cell, a podium cell or another wall gets nothing — trim you cannot
## see is trim you should not pay for.
static func _add_wall_faces(walls: Dictionary, floors: Dictionary, skirt_out: Array, out: Array) -> void:
	for f in _dressed_faces(walls, floors):
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		var sk: Vector3 = Vector3(1.0, SKIRT_H, SKIRT_T)
		var co: Vector3 = Vector3(1.0, CORNICE_H, CORNICE_T)
		if not bool(fd["along_x"]):
			sk = Vector3(SKIRT_T, SKIRT_H, 1.0)
			co = Vector3(CORNICE_T, CORNICE_H, 1.0)
		skirt_out.append(_xf(Vector3(fx, SKIRT_H * 0.5, fz), sk))
		out.append(_xf(Vector3(fx, CORNICE_BOTTOM + CORNICE_H * 0.5, fz), co))


## Every wall face that actually faces a floor cell, in a stable order, as
## {x, z, along_x, cell}. Gathered once so skirting, cornice and labels all agree
## about what a dressed face is instead of each re-deriving it.
static func _dressed_faces(walls: Dictionary, floors: Dictionary) -> Array:
	var out: Array = []
	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var cells: Array = walls.keys()
	cells.sort_custom(func(a, b):
		var av: Vector2i = a
		var bv: Vector2i = b
		if av.y != bv.y:
			return av.y < bv.y
		return av.x < bv.x)
	for key in cells:
		var cell: Vector2i = key
		for d in dirs:
			var dv: Vector2i = d
			var nb: Vector2i = Vector2i(cell.x + dv.x, cell.y + dv.y)
			if walls.has(nb):
				continue
			if not floors.has(nb):
				continue
			out.append({
				"x": float(cell.x) + 0.5 + float(dv.x) * 0.5,
				"z": float(cell.y) + 0.5 + float(dv.y) * 0.5,
				"along_x": dv.y != 0,
				"cell": cell,
			})
	return out


## Wall cards at reading height, one per LABEL_EVERY dressed face. Deterministic
## (the face list is sorted, the selection is a modulo) so two runs of the same
## seed produce the same building — a randf() here would make every proof shot a
## different room. Non-colliding by construction: 25 mm proud of a face the
## walker already stands 320 mm off.
static func _add_labels(walls: Dictionary, floors: Dictionary, out: Array) -> void:
	var faces: Array = _dressed_faces(walls, floors)
	var i: int = 0
	for f in faces:
		i += 1
		if i % LABEL_EVERY != 0:
			continue
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		var sz: Vector3 = Vector3(LABEL_W, LABEL_H, LABEL_T)
		if not bool(fd["along_x"]):
			sz = Vector3(LABEL_T, LABEL_H, LABEL_W)
		out.append(_xf(Vector3(fx, LABEL_Y, fz), sz))


## A 45-degree bead on every FREE convex arris — a lattice point with exactly one
## wall cell around it and at least one floor cell to be seen from. Inside
## corners and pier junctions are skipped: a bead there would read as a lump.
static func _add_arris_beads(walls: Dictionary, floors: Dictionary, out: Array) -> void:
	var seen: Dictionary = {}
	for key in walls:
		var cell: Vector2i = key
		for ox in range(2):
			for oz in range(2):
				var p: Vector2i = Vector2i(cell.x + ox, cell.y + oz)
				if seen.has(p):
					continue
				seen[p] = true
				var a: Vector2i = Vector2i(p.x - 1, p.y - 1)
				var b: Vector2i = Vector2i(p.x, p.y - 1)
				var c: Vector2i = Vector2i(p.x - 1, p.y)
				var e: Vector2i = Vector2i(p.x, p.y)
				var n_wall: int = int(walls.has(a)) + int(walls.has(b)) + int(walls.has(c)) + int(walls.has(e))
				if n_wall != 1:
					continue
				var n_floor: int = int(floors.has(a)) + int(floors.has(b)) + int(floors.has(c)) + int(floors.has(e))
				if n_floor == 0:
					continue
				out.append(_xf_yaw(
					Vector3(float(p.x), BEAD_Y0 + BEAD_H * 0.5, float(p.y)),
					Vector3(BEAD_W, BEAD_H, BEAD_W), PI * 0.25))


## Lined reveals at every genuine door: a gap 1..3 cells wide through a wall run,
## open on both sides. The vestibule threshold row is excluded — _add_portal
## treats it at monumental scale instead of stamping a 15 m "door".
static func _add_doors(walls: Dictionary, floors: Dictionary, w: int, h: int, trim_out: Array, solid_out: Array, seam_out: Array) -> void:
	var x_lo: int = -2
	var x_hi: int = maxi(LOBBY_W, w + 1)
	var z_lo: int = 0
	var z_hi: int = VESTIBULE_H + h - 1

	# openings through a wall running along x (the walker passes along z)
	for z in range(z_lo, z_hi + 1):
		if z == VESTIBULE_H - 1:
			continue
		var x: int = x_lo
		while x <= x_hi:
			if walls.has(Vector2i(x, z)) or not floors.has(Vector2i(x, z)):
				x += 1
				continue
			var s: int = x
			while x <= x_hi and not walls.has(Vector2i(x, z)) and floors.has(Vector2i(x, z)):
				x += 1
			var e: int = x - 1
			var cells: int = e - s + 1
			if cells > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(s - 1, z)) or not walls.has(Vector2i(e + 1, z)):
				continue
			# a 1-cell corridor also has walls at x-1 and x+1 for every cell along
			# it, and would otherwise collect a lintel per metre. A pier that runs
			# THROUGH the row perpendicular to this test is a corridor wall, not a
			# door jamb — reject it and let skirting and beads dress the corridor.
			if _pier_runs_through(walls, Vector2i(s - 1, z), true):
				continue
			if _pier_runs_through(walls, Vector2i(e + 1, z), true):
				continue
			var clear: bool = true
			for xx in range(s, e + 1):
				if walls.has(Vector2i(xx, z - 1)) or walls.has(Vector2i(xx, z + 1)):
					clear = false
					break
			if not clear:
				continue
			_stamp_door_x(float(s), float(e + 1), float(z), trim_out, solid_out, seam_out)

	# openings through a wall running along z (the walker passes along x)
	for x2 in range(x_lo, x_hi + 1):
		var z2: int = z_lo
		while z2 <= z_hi:
			if walls.has(Vector2i(x2, z2)) or not floors.has(Vector2i(x2, z2)):
				z2 += 1
				continue
			var s2: int = z2
			while z2 <= z_hi and not walls.has(Vector2i(x2, z2)) and floors.has(Vector2i(x2, z2)):
				z2 += 1
			var e2: int = z2 - 1
			var cells2: int = e2 - s2 + 1
			if cells2 > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(x2, s2 - 1)) or not walls.has(Vector2i(x2, e2 + 1)):
				continue
			if _pier_runs_through(walls, Vector2i(x2, s2 - 1), false):
				continue
			if _pier_runs_through(walls, Vector2i(x2, e2 + 1), false):
				continue
			var clear2: bool = true
			for zz in range(s2, e2 + 1):
				if walls.has(Vector2i(x2 - 1, zz)) or walls.has(Vector2i(x2 + 1, zz)):
					clear2 = false
					break
			if not clear2:
				continue
			_stamp_door_z(float(x2), float(s2), float(e2 + 1), trim_out, solid_out, seam_out)


## Is this pier a length of wall running PERPENDICULAR to the opening we think we
## found — that is, a corridor cheek rather than a door jamb? True when the wall
## continues on both sides in the perpendicular axis. A jamb at the end of a real
## wall run has open room on at least one of those two sides.
## wall_runs_x: the candidate opening pierces a wall running along x.
static func _pier_runs_through(walls: Dictionary, p: Vector2i, wall_runs_x: bool) -> bool:
	if wall_runs_x:
		return walls.has(Vector2i(p.x, p.y - 1)) and walls.has(Vector2i(p.x, p.y + 1))
	return walls.has(Vector2i(p.x - 1, p.y)) and walls.has(Vector2i(p.x + 1, p.y))


## One door through an x-running wall. x0..x1 is the clear opening in world x;
## zc is the wall's cell index, so the reveal is one cell (1 m) deep.
static func _stamp_door_x(x0: float, x1: float, zc: float, trim_out: Array, solid_out: Array, seam_out: Array) -> void:
	var span: float = x1 - x0
	var mid: float = (x0 + x1) * 0.5
	var cz: float = zc + 0.5
	trim_out.append(_xf(Vector3(x0 + LINING_T * 0.5, DOOR_HEAD * 0.5, cz),
		Vector3(LINING_T, DOOR_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(x1 - LINING_T * 0.5, DOOR_HEAD * 0.5, cz),
		Vector3(LINING_T, DOOR_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(mid, DOOR_HEAD + HEAD_LINING * 0.5, cz),
		Vector3(span, HEAD_LINING, 1.0)))
	var over_h: float = WALL_H - DOOR_HEAD - HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(mid, WALL_H - over_h * 0.5, cz),
			Vector3(span, over_h, 1.0)))
	seam_out.append(_xf(Vector3(mid, 0.0, cz), Vector3(span, SEAM_PROUD, 0.14)))


## One door through a z-running wall. Mirror of _stamp_door_x.
static func _stamp_door_z(xc: float, z0: float, z1: float, trim_out: Array, solid_out: Array, seam_out: Array) -> void:
	var span: float = z1 - z0
	var mid: float = (z0 + z1) * 0.5
	var cx: float = xc + 0.5
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD * 0.5, z0 + LINING_T * 0.5),
		Vector3(1.0, DOOR_HEAD, LINING_T)))
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD * 0.5, z1 - LINING_T * 0.5),
		Vector3(1.0, DOOR_HEAD, LINING_T)))
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD + HEAD_LINING * 0.5, mid),
		Vector3(1.0, HEAD_LINING, span)))
	var over_h: float = WALL_H - DOOR_HEAD - HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(cx, WALL_H - over_h * 0.5, mid),
			Vector3(1.0, over_h, span)))
	seam_out.append(_xf(Vector3(cx, 0.0, mid), Vector3(0.14, SEAM_PROUD, span)))


## The vestibule threshold — the one gap the corridor guarantees, and the one the
## walker meets head-on every time a museum opens. The scene's own seal runs from
## x = w-1, and the lobby's west wall ends at x = 1, so the clear opening is
## exactly [1, w-1] in the row z = VESTIBULE_H - 1. Given a portal frame rather
## than a door: 2.40 head, 80 mm linings, 160 mm head lining.
static func _add_portal(w: int, trim_out: Array, solid_out: Array, seam_out: Array) -> void:
	var x0: float = 1.0
	var x1: float = float(w - 1)
	if x1 - x0 < 0.5:
		return
	var span: float = x1 - x0
	var mid: float = (x0 + x1) * 0.5
	var cz: float = float(VESTIBULE_H - 1) + 0.5
	trim_out.append(_xf(Vector3(x0 + PORTAL_LINING * 0.5, PORTAL_HEAD * 0.5, cz),
		Vector3(PORTAL_LINING, PORTAL_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(x1 - PORTAL_LINING * 0.5, PORTAL_HEAD * 0.5, cz),
		Vector3(PORTAL_LINING, PORTAL_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(mid, PORTAL_HEAD + PORTAL_HEAD_LINING * 0.5, cz),
		Vector3(span, PORTAL_HEAD_LINING, 1.0)))
	var over_h: float = WALL_H - PORTAL_HEAD - PORTAL_HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(mid, WALL_H - over_h * 0.5, cz),
			Vector3(span, over_h, 1.0)))
	# a wider threshold plate than an interior door gets — you walk over this one
	seam_out.append(_xf(Vector3(mid, 0.0, cz), Vector3(span, SEAM_PROUD, 0.22)))


## The coffered daylight ceiling. Solid panels on a 3.0 m bay, a 550 mm open slot
## between them, ribs crossing both ways to give the soffit a grain. The slots are
## real holes: the directional sun lands in bands, which is the whole point — a
## sealed ceiling would flatten every room the lighting rig just modelled.
static func _add_ceiling(w: int, h: int, out: Array) -> void:
	var x0: float = -1.0
	var x1: float = float(maxi(LOBBY_W, w + 1))
	var z0: float = 0.0
	var z1: float = float(VESTIBULE_H + h)
	var span_x: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	var panel_len: float = BAY - SLOT_W

	var zc: float = z0
	while zc < z1 - 0.01:
		var plen: float = minf(panel_len, z1 - zc)
		if plen > 0.05:
			out.append(_xf(Vector3(cx, CEIL_SOFFIT + CEIL_THICK * 0.5, zc + plen * 0.5),
				Vector3(span_x, CEIL_THICK, plen)))
			# ribs frame the slot: one at the panel's near edge, one at its far edge
			out.append(_xf(Vector3(cx, CEIL_SOFFIT - RIB_DROP * 0.5, zc),
				Vector3(span_x, RIB_DROP, RIB_W)))
			out.append(_xf(Vector3(cx, CEIL_SOFFIT - RIB_DROP * 0.5, zc + plen),
				Vector3(span_x, RIB_DROP, RIB_W)))
		zc += BAY

	# longitudinal ribs on the same module, so the coffer is a square grid
	var span_z: float = z1 - z0
	var cz: float = (z0 + z1) * 0.5
	var xc: float = 0.0
	while xc <= x1 + 0.01:
		out.append(_xf(Vector3(xc, CEIL_SOFFIT - RIB_DROP * 0.5, cz),
			Vector3(RIB_W, RIB_DROP, span_z)))
		xc += BAY


## Expansion joints on the ceiling's own module, emitted only over cells that
## actually carry a floor box — a strip hanging over a void cell would read as a
## floating line.
static func _add_seams(floors: Dictionary, w: int, h: int, out: Array) -> void:
	var z_max: int = VESTIBULE_H + h
	var x_max: int = maxi(LOBBY_W, w + 1)

	# joints running in z, on lattice lines x = 0, 3, 6 ...
	for sx in range(0, x_max + 1, SEAM_M):
		var start: int = -1
		for z in range(0, z_max + 2):
			var present: bool = z <= z_max and (floors.has(Vector2i(sx, z)) or floors.has(Vector2i(sx - 1, z)))
			if present and start < 0:
				start = z
			elif not present and start >= 0:
				var length: float = float(z - start)
				out.append(_xf(Vector3(float(sx), 0.0, float(start) + length * 0.5),
					Vector3(SEAM_W, SEAM_PROUD, length)))
				start = -1

	# joints running in x, on lattice lines z = 0, 3, 6 ...
	for sz in range(0, z_max + 1, SEAM_M):
		var start2: int = -1
		for x in range(-1, x_max + 2):
			var present2: bool = x <= x_max and (floors.has(Vector2i(x, sz)) or floors.has(Vector2i(x, sz - 1)))
			if present2 and start2 < 0:
				start2 = x
			elif not present2 and start2 >= 0:
				var length2: float = float(x - start2)
				out.append(_xf(Vector3(float(start2) + length2 * 0.5, 0.0, float(sz)),
					Vector3(length2, SEAM_PROUD, SEAM_W)))
				start2 = -1


# ═══════════════════════════════════════════════════════════════════════════
# EMISSION
# ═══════════════════════════════════════════════════════════════════════════

## One MultiMeshInstance3D per material role. Every box in the family is the same
## unit BoxMesh with its size carried in the per-instance basis, so a family of
## 900 boxes is one mesh, one material and one draw call.
static func _emit(parent: Node3D, node_name: String, xforms: Array, mat: Variant, shadows: bool) -> void:
	if xforms.is_empty():
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		var t: Transform3D = xforms[i]
		mm.set_instance_transform(i, t)
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	if mat is Material:
		mmi.material_override = mat as Material
	if shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## The corpus law: an artifact built from MultiMeshInstance3D measures as a 1 m
## AABB, because the capture rig counts MeshInstance3D only. This anchor is a real
## MeshInstance3D sized to the segment's true extent, on layers = 0 so it renders
## to nothing, casts nothing and costs nothing — it exists to be MEASURED.
static func _add_extent_anchor(seg: Node3D, w: int, h: int) -> void:
	var x0: float = -1.0
	var x1: float = float(maxi(LOBBY_W, w + 1))
	var z1: float = float(VESTIBULE_H + h)
	var anchor: MeshInstance3D = MeshInstance3D.new()
	anchor.name = "DetailExtentAnchor"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(x1 - x0, CEIL_TOP, z1)
	anchor.mesh = box
	anchor.position = Vector3((x0 + x1) * 0.5, CEIL_TOP * 0.5, z1 * 0.5)
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seg.add_child(anchor)


static func _xf(pos: Vector3, size: Vector3) -> Transform3D:
	return Transform3D(Basis().scaled(size), pos)


## Yaw is applied to a box whose x and z scales are equal, so pre- and
## post-multiplied scale are identical and Basis.scaled() is unambiguous here.
static func _xf_yaw(pos: Vector3, size: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(size), pos)


# ═══════════════════════════════════════════════════════════════════════════
# MATERIAL PROBE
# ═══════════════════════════════════════════════════════════════════════════

## Ask the library for four roles without assuming its shape. Accepts an Object
## with getter methods or plain properties, a Dictionary, or null. Anything the
## library does not answer for falls back to a local material chosen so the trim
## still does its job: trim lighter and smoother than wall (so an edge lifts),
## ceiling matte (so it does not become the brightest thing in frame), joints
## semi-metallic (so the floor grid glints at grazing angles and vanishes head-on).
static func _resolve_mats(mats) -> Dictionary:
	var names: Dictionary = _member_names(mats)
	var wall_mat: Variant = _role(mats, names,
		["wall", "get_wall", "wall_material", "get_wall_material"],
		_fallback(Color(0.34, 0.34, 0.37), 0.86, 0.0))
	var lib: Dictionary = {
		"wall": wall_mat,
		"trim": _role(mats, names,
			["trim", "get_trim", "trim_material", "get_trim_material"],
			_fallback(Color(0.44, 0.435, 0.415), 0.52, 0.0)),
		"accent": _role(mats, names,
			["accent", "get_accent", "accent_material", "get_accent_material"],
			_fallback(Color(0.20, 0.185, 0.155), 0.34, 0.65)),
	}
	lib["ceiling"] = _role(mats, names,
		["ceiling", "get_ceiling", "ceiling_material", "get_ceiling_material"],
		wall_mat if wall_mat is Material else _fallback(Color(0.40, 0.40, 0.42), 0.92, 0.0))
	# the contact-grime strip. Falls back to a darker, rougher wall rather than to
	# the wall itself, so the skirting still terminates the wall against the floor
	# with a value step even when the library never answers for this role.
	lib["skirting"] = _role(mats, names,
		["skirting", "get_skirting", "skirting_material", "get_skirting_material"],
		_fallback(Color(0.21, 0.20, 0.19), 0.90, 0.0))
	return lib


## Method and property names the library exposes, gathered once. Probing by name
## list rather than by has_method() alone means a library that publishes plain
## `var trim: Material` works as well as one that publishes `func trim()`.
static func _member_names(mats) -> Dictionary:
	var out: Dictionary = {}
	if mats == null or not (mats is Object):
		return out
	var obj: Object = mats as Object
	for m in obj.get_method_list():
		var md: Dictionary = m
		var args: Array = md.get("args", [])
		var defaults: Variant = md.get("default_args", [])
		var required: int = args.size()
		if defaults is Array:
			required -= (defaults as Array).size()
		elif defaults is int:
			required -= int(defaults)
		if required <= 0:
			out[String(md.get("name", ""))] = "method"
	for p in obj.get_property_list():
		var pd: Dictionary = p
		var pname: String = String(pd.get("name", ""))
		if not out.has(pname):
			out[pname] = "property"
	return out


static func _role(mats, names: Dictionary, keys: Array, fallback: Variant) -> Variant:
	if mats == null:
		return fallback
	if mats is Dictionary:
		var d: Dictionary = mats as Dictionary
		for k in keys:
			var key: String = String(k)
			if d.has(key) and d[key] is Material:
				return d[key]
		return fallback
	if mats is Object:
		var obj: Object = mats as Object
		for k2 in keys:
			var key2: String = String(k2)
			var got: Variant = null
			if names.has(key2) and String(names[key2]) == "method":
				got = obj.call(key2)
			elif names.has(key2):
				got = obj.get(key2)
			elif obj.has_method(key2):
				# a GDScript class object handed over instead of an instance:
				# get_method_list() does not surface its static functions, but
				# has_method()/call() still reach them
				got = obj.call(key2)
			if got is Material:
				return got
	return fallback


static func _fallback(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	# trim is the geometry that is SUPPOSED to catch light; a little specular
	# tightening is the difference between a bevel and a painted stripe
	m.metallic_specular = 0.5 + metallic * 0.2
	return m


# ═══════════════════════════════════════════════════════════════════════════
# _INTRUSION_AUDIT — the walkable footprint is unchanged. Every claim measured
# against the scene's own numbers: capsule radius 0.32, capsule top y = 1.70,
# eye y = 1.65, wall face standoff at rest 0.32.
#
#   element          y range        max horizontal reach past a wall face
#   skirting         0.00 .. 0.13   0.0225 m   (7% of the 0.32 standoff)
#   arris bead       0.13 .. 2.72   0.053 m    (17% of the standoff, convex corners only)
#   cornice          2.72 .. 3.00   0.060 m    (1.02 m above the capsule top)
#   door jamb lining 0.00 .. 2.10   0.05 m into the opening; a 1-cell door still
#                                   clears 0.90 m against a 0.64 m capsule
#   door head lining 2.10 .. 2.22   overhead
#   door overpanel   2.22 .. 3.00   overhead
#   portal lining    0.00 .. 2.40   0.08 m into a >= 11 m wide threshold
#   ceiling ribs     2.96 .. 3.14   overhead, 1.26 m of clearance over the capsule
#   ceiling panels   3.14 .. 3.40   overhead
#   floor seams      -0.01 .. 0.01  0.01 m proud of a floor the walker's y is clamped to
#
# And structurally, not just dimensionally:
#   - this file constructs no CollisionShape3D and no PhysicsBody of any kind;
#   - it never looks up, adds to or removes from the segment's "Collision"
#     StaticBody3D, so the physics walker meets exactly the surfaces it met before;
#   - it never touches endless_museum.gd's _walk_cells dictionary, so the
#     autopilot's BFS plan over the stamped cells is bit-identical with and
#     without this pass, and --em-autopilot cannot regress because of it;
#   - the only elements below 1.70 m are flush-to-a-wall bands, an in-opening
#     jamb lining and a 25 mm wall card, all of them non-colliding decoration
#     standing off surfaces the capsule already cannot reach.
#
# WHAT IS STILL AN UNBROKEN 90-DEGREE ARRIS, honestly. The bead family dresses
# WALL corners — lattice points with exactly one wall cell around them. It does
# not and cannot dress:
#   - the coffer beam mitres (ceiling boxes on a MultiMesh; there is no lattice)
#   - the pilaster / wall butt joint (a template cell, not a free convex corner)
#   - any edge of a podium, plinth or the ember strip (owned by endless_museum)
# Those need either PbrKit.box() with baked vertex-colour wear (em_materials is
# already wired for it: vertex_color_use_as_albedo is on and a BoxMesh simply
# carries no COLOR array) or real chamfered ArrayMesh geometry. Neither is in
# this file yet, and neither should be claimed by it.
# ═══════════════════════════════════════════════════════════════════════════
