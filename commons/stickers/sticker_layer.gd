extends Node3D
## THE STICKERS OF ONE HOST, drawn under that host's node. The layer's own transform IS the host frame (stickers.ts:
## a board's face centre, x right, y up, z out; a bench primitive's centre; a Void work's exported GLB frame; a Void
## floor's Floor<i> frame), so every sticker is placed exactly as its record says: at, n, up and size in that frame.
##
## A sticker is a PROJECTOR, as three.js's decal is (sticker-decal.ts): a box extent(design, size) = [w, h] along right
## and up (right = up x n) and DEPTH_RATIO times the long side along n, centred on `at`. It prints the picture, by an
## orthographic projection along -n, on the host's surface inside that box that faces n by at least MIN_FACING. Where
## the layer knows the host's BODY it prints exactly that (body(): the host's `surface` - the bench's sphere {shape:
## sphere, r} and cylinder {shape: cylinder, r, h} - or, for a board or a bench primitive, the box of the body's own
## collider: the board's Face, the bench's box and slab):
##   CURVED, the sphere and the cylinder's side ("Curved_<design>", one ArrayMesh per design): a GRID over the layout,
##   each of its points carried along -n onto the body. Cells past the projector's depth, or facing n by less than
##   MIN_FACING, are cut away at that boundary (found on each cell's edges); the cylinder's side ends at its rims. Every
##   vertex is lifted out along the body's normal there, which also lights it. Seen along n, each point of the picture
##   is where three.js prints it, and neither prints what lies past the depth (the corners of a 0.4 m sticker on the
##   0.3 m sphere). Laid along the body's normals instead (until 2026-11-13), the same picture point landed up to 1.1 cm
##   from three.js's at 0.18 m and 5.4 cm at 0.4 m, and the corners were drawn where three.js prints none.
##   PLANAR, a box's six faces and a cylinder's two caps (a 96-gon, as three.js's bench cuts it): the face clipped by the
##   projector's box (DecalGeometry's six planes), so a sticker ends at the edge of its face, where three.js's decal ends
##   (a flat quad by the edge of the bench box's top or the cylinder's cap stood out in the air past the body, 11.8 and
##   10.5 cm in the re-check of 2026-11-13). A sticker that lies whole inside one face is the quad below; one cut at an
##   edge is a mesh ("Clipped_<design>").
## Anywhere else (a Void work or floor, whose bodies the layer does not know), and for a sticker its body takes no ink
## from (drawn where its record says, as three.js draws an unseated one), a sticker is FLAT: one MultiMeshInstance3D per
## design ("Stickers_<design>"), the shared 1 x 1 quad scaled per instance to extent(design, size) - the DRAWN box, the
## die-cut border included - its basis columns right * w, up * h, n, its origin at + n * its lift.
##
## THE STACK: a sticker stuck later (higher z) lies over every earlier one it overlaps. Its lift is LIFT, or a step over
## the highest of the earlier live stickers whose drawn footprint overlaps its own (footprint(): the box its print fills
## in its own right / up / n, tested against the others' by separating axes), at most STACK_HEIGHT over LIFT; a step is
## STACK (0.1 mm) between flat prints and CURVED_STACK (0.5 mm, more than any grid's sag) where either is a grid. So
## stickers that do not overlap all lie at LIFT, and the cap is met only by a pile of 60 overlapping flat stickers or 12
## curved ones. (Counted by its index on the host, as until 2026-11-13, the 61st sticker of a board and the 13th of the
## sphere met the cap whatever overlapped what, and two overlapping stickers there were drawn at one lift: on the sphere
## they pierced each other, on the board the earlier one could cover the later. three.js orders them by rank.)
##
## Peeled stickers are drawn as RESIDUE ("Residue_<design>", "CurvedResidue_<design>", "ClippedResidue_<design>"): the
## silhouette in one flat colour (StickerData.RESIDUE_COLOR) at RESIDUE_ALPHA, 1.2 mm off the surface, under the
## stickers that are on - a peel is an event that leaves residue, never a deletion. Materials and pictures come from
## StickerData (one per design).
##
## A board sticker is drawn on the board's FACE whatever an older record says (drawn_as: stickers.ts settle).
##
## The host sets `host` (and `surface`) before adding the layer; the layer redraws itself whenever the placements or
## designs change. It has no _process: a floor's residency pauses and hides it with its floor at no cost.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const LIFT := 0.002          # off the surface (stickers.ts / the contract)
const STACK := 0.0001        # a step in the stack between flat prints (0.1 mm)
const STACK_MOST := 60       # flat steps in STACK_HEIGHT
## On a curve two stickers are two different grids, each sagging between its points by up to 0.37 mm, so 0.1 mm of
## stack (the flat step) let an earlier sticker show through a later one where they overlap (seen on the sphere in the
## probe's curved.png): a curved step is 0.5 mm, more than any sag, at most 12 of them (6 mm).
const CURVED_STACK := 0.0005
const CURVED_STACK_MOST := 12
const STACK_HEIGHT := 0.006  # the most a pile climbs over LIFT: STACK * STACK_MOST = CURVED_STACK * CURVED_STACK_MOST
const RESIDUE_LIFT := 0.0012 # under the stickers on it
const STEP := 0.07           # a curved grid's cell spans at most about this angle (rad): its chords sag under 0.4 mm
const CELLS_LEAST := 8
const CELLS_MOST := 32
# --- sticker-decal.ts ---
const MIN_FACING := 0.2      # MIN_FACING: cos 78.5 degrees; past that a projection smears more than it prints
const DEPTH_RATIO := 0.5     # DEPTH_RATIO: the projector's depth along n, as a share of the sticker's long side
const MIN_DEPTH := 0.002     # MIN_DEPTH
const CAP_SIDES := 96        # a cylinder's cap, cut as three.js cuts the bench's (CylinderGeometry, 96 segments)
# --- the stack ---
const FOOT_SLACK := 0.001    # a footprint's box reaches this far each way along its n (more than a grid's sag)
const TOUCH := 0.00001       # footprints that only touch (overlapping by less than 0.01 mm) are not a pile

var host: Dictionary = {}
var surface: Dictionary = {} # {shape: "sphere", r} or {shape: "cylinder", r, h}: the host's analytic body; {} = body()
var data: Node = null
var drawn := 0               # stickers drawn (state on)
var residue := 0             # peeled stickers drawn as residue
var lifts: Dictionary = {}   # id -> the lift each live sticker is drawn at (its place in the stack), for probes
var _sig := ""

func _ready() -> void:
	data = StickerData.get_or_create(get_tree())
	data.placements_changed.connect(redraw)
	data.designs_changed.connect(_designs_changed)
	redraw()

func host_key() -> String:
	return StickerData.host_key(host)

func _designs_changed() -> void:
	_sig = ""
	redraw()

## The body this host's stickers print on (host frame): `surface` when the host set one; else, for a board or a bench
## primitive, the box of its body's own collider (the board's Face, the bench's box and slab); {} for a Void host.
func body() -> Dictionary:
	if not surface.is_empty():
		return surface
	if str(host.get("kind", "")) in ["board", "primitive"]:
		return box_of(get_parent())
	return {}

## Draw this host's stickers again, when they (or the designs, or the body) changed since the last time.
func redraw() -> void:
	if data == null:
		return
	var surf := body()
	var list: Array = data.stickers_on(host_key())
	var sig := "%d|%s|%s" % [int(data.revisions.get("designs", -1)), JSON.stringify(surf), JSON.stringify(list)]
	if sig == _sig:
		return
	_sig = sig
	var on: Array = []
	var off: Array = []
	for s0 in list:
		var s := drawn_as(s0, host)
		if str(s.get("state", "on")) == "on":
			on.append(s)
		else:
			off.append(s)
	on.sort_custom(_earlier)
	var groups: Dictionary = {}     # node name -> [design, peeled, [[sticker, lift, shape]]]
	var feet: Array = []            # [footprint, lift, a grid] of each live sticker so far, in the order of the stack
	lifts = {}
	for s in on:
		var d: Dictionary = data.design(str(s.get("design", "")))
		if d.is_empty():
			continue   # a design this game does not have (yet): its stickers wait for it
		var g := shape_of(s, d, surf)
		var foot := footprint(s, d, g)
		var curved := bool(g.get("curved", false))
		var lift := LIFT
		for f in feet:
			if boxes_overlap(foot, f[0]):
				lift = maxf(lift, float(f[1]) + (CURVED_STACK if curved or bool(f[2]) else STACK))
		lift = minf(lift, LIFT + STACK_HEIGHT)
		feet.append([foot, lift, curved])
		lifts[str(s.get("id", ""))] = lift
		_group(groups, s, g, lift, false)
	for s in off:
		var d: Dictionary = data.design(str(s.get("design", "")))
		if not d.is_empty():
			_group(groups, s, shape_of(s, d, surf), RESIDUE_LIFT, true)
	var keep: Dictionary = {}
	drawn = 0
	residue = 0
	for node_name in groups:
		var grp: Array = groups[node_name]
		var key: String = grp[0]
		var peeled: bool = grp[1]
		var mat: Material = data.residue_material(key) if peeled else data.material(key)
		var flat := str(node_name).begins_with("Stickers_") or str(node_name).begins_with("Residue_")
		var ok := _fill(node_name, mat, grp[2], key) if flat else _fill_laid(node_name, mat, grp[2])
		if ok:
			keep[node_name] = true
			if peeled:
				residue += (grp[2] as Array).size()
			else:
				drawn += (grp[2] as Array).size()
	for c in get_children():
		if (c is MultiMeshInstance3D or c is MeshInstance3D) and not keep.has(str(c.name)):
			remove_child(c)
			c.queue_free()

## The order of the stack: by z, and by id where two share a z (so every redraw stacks them alike).
static func _earlier(a: Dictionary, b: Dictionary) -> bool:
	var za := int(a.get("z", 0))
	var zb := int(b.get("z", 0))
	return za < zb or (za == zb and str(a.get("id", "")) < str(b.get("id", "")))

func _group(groups: Dictionary, s: Dictionary, g: Dictionary, lift: float, peeled: bool) -> void:
	var key := str(s.get("design", ""))
	var node_name: String
	if not bool(g.get("laid", false)):
		node_name = ("Residue_" if peeled else "Stickers_") + key
	elif bool(g.get("curved", false)):
		node_name = ("CurvedResidue_" if peeled else "Curved_") + key
	else:
		node_name = ("ClippedResidue_" if peeled else "Clipped_") + key
	if not groups.has(node_name):
		groups[node_name] = [key, peeled, []]
	(groups[node_name][2] as Array).append([s, lift, g])

func _fill(node_name: String, mat: Material, entries: Array, design_id: String) -> bool:
	var d: Dictionary = data.design(design_id)
	if d.is_empty() or mat == null:
		return false   # a design this game does not have (yet), or its picture not drawn: its stickers wait for it
	var mmi := get_node_or_null(node_name) as MultiMeshInstance3D
	if mmi == null:
		mmi = MultiMeshInstance3D.new()
		mmi.name = node_name
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = data.quad_mesh()
		mmi.multimesh = mm
		add_child(mmi)
	mmi.material_override = mat
	var batch := mmi.multimesh
	batch.instance_count = entries.size()
	for i in entries.size():
		batch.set_instance_transform(i, pose(entries[i][0], d, float(entries[i][1])))
	return true

## The laid stickers of one design (or their residue) as one ArrayMesh in the host frame. The node carries metas for
## probes: ids (in order), ranges ([first vertex, count] per sticker), centres (each sticker's drawn centre) and lifts.
func _fill_laid(node_name: String, mat: Material, entries: Array) -> bool:
	if mat == null:
		return false
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var ids: Array = []
	var ranges: Array = []
	var centres := PackedVector3Array()
	var lift_list: Array = []
	for e in entries:
		var g: Dictionary = e[2]
		var lift := float(e[1])
		var gv: Array = g.verts
		var gn: Array = g.norms
		var base := verts.size()
		for i in gv.size():
			var m: Vector3 = gn[i]
			verts.append(Vector3(gv[i]) + m * lift)
			norms.append(m)
		for uv in g.uvs:
			uvs.append(uv)
		for k in g.idx:
			idx.append(base + int(k))
		ids.append(str((e[0] as Dictionary).get("id", "")))
		ranges.append([base, gv.size()])
		centres.append(Vector3(g.centre) + Vector3(g.centre_n) * lift)
		lift_list.append(lift)
	var mi := get_node_or_null(node_name) as MeshInstance3D
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = node_name
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var mesh := ArrayMesh.new()
	if not idx.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	mi.material_override = mat
	mi.set_meta("ids", ids)
	mi.set_meta("ranges", ranges)
	mi.set_meta("centres", centres)
	mi.set_meta("lifts", lift_list)
	return true

## The record as it is drawn: on a BOARD it lies on the face whatever an older record says (stickers.ts settle: n = +Z,
## at.z = 0, up laid on the face; the server settles every op since, so the truth holds no other). three.js does not do
## this: its board host is the face plane only, so an older record on the back gets no decal there and its 3D view
## lists it as unseated, a translucent quad at its own pose. Elsewhere the record itself.
static func drawn_as(s: Dictionary, h: Dictionary) -> Dictionary:
	if str(h.get("kind", "")) != "board":
		return s
	var c := s.duplicate()
	StickerData.settle(c, null)
	return c

## A flat sticker's quad in its host frame: basis columns right * w, up * h, n; origin at + n * lift.
static func pose(s: Dictionary, d: Dictionary, lift: float) -> Transform3D:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var e := StickerData.extent(d, float(s.get("size", 0.2)))
	return Transform3D(Basis(b.right * e.x, b.up * e.y, b.n), StickerData.v3(s.get("at")) + b.n * lift)

# ==== the body ====

## The analytic body a node's stickers print on (host frame), for the pad: its meta sticker_surface (the bench's sphere
## and cylinder), else for a board or a bench primitive the box of its own collider; {} when it is not known.
static func surface_of(node: Variant, h: Dictionary) -> Dictionary:
	if not node is Node:
		return {}
	var meta: Variant = (node as Node).get_meta("sticker_surface", {})
	if meta is Dictionary and not (meta as Dictionary).is_empty():
		return meta
	if str(h.get("kind", "")) in ["board", "primitive"]:
		return box_of(node)
	return {}

## The box of a body's one collider: {shape: "box", size: [x, y, z], at: [x, y, z]} in the body's frame, or {} when the
## body has not exactly one enabled CollisionShape3D, an unturned BoxShape3D.
static func box_of(node: Node) -> Dictionary:
	if node == null:
		return {}
	var found: Dictionary = {}
	for c in node.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.disabled or cs.shape == null:
			continue
		if not cs.shape is BoxShape3D or not cs.transform.basis.is_equal_approx(Basis.IDENTITY) or not found.is_empty():
			return {}
		var sz: Vector3 = (cs.shape as BoxShape3D).size
		found = {"shape": "box", "size": [sz.x, sz.y, sz.z], "at": [cs.position.x, cs.position.y, cs.position.z]}
	return found

## Whether a sticker on a host with this surface is laid on the curve (a grid) rather than drawn flat: every sticker
## on a sphere; on a cylinder, one on its side (|n.y| <= POLE), not one on a cap.
static func is_curved(s: Dictionary, surf: Dictionary) -> bool:
	if float(surf.get("r", 0.0)) <= 0.0:
		return false
	match str(surf.get("shape", "")):
		"sphere":
			return true
		"cylinder":
			return absf(float(StickerData.norm3(StickerData.a3(s.get("n")))[1])) <= StickerData.POLE
	return false

## Whether a sticker is drawn as a mesh laid on its body (a grid, or a face cut at its edge) rather than as its quad.
static func laid(s: Dictionary, d: Dictionary, surf: Dictionary) -> bool:
	match str(surf.get("shape", "")):
		"":
			return false
		"sphere":
			return float(surf.get("r", 0.0)) > 0.0
		"cylinder":
			if is_curved(s, surf):
				return true
	return bool(shape_of(s, d, surf).get("laid", false))

## The sticker's projector (sticker-decal.ts projector()): its at, right / up / n, extent [w, h] and depth along n.
static func projector(s: Dictionary, d: Dictionary) -> Dictionary:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var e := StickerData.extent(d, float(s.get("size", 0.2)))
	return {"at": StickerData.v3(s.get("at")), "right": b.right, "up": b.up, "n": b.n, "w": e.x, "h": e.y,
		"depth": maxf(MIN_DEPTH, DEPTH_RATIO * maxf(e.x, e.y))}

## Whether the point p of the body (host frame; `normal` the surface's normal there, when known) is under the
## sticker's print: inside its projector's box, on a surface facing n by at least MIN_FACING. The pad picks with this.
static func holds(s: Dictionary, d: Dictionary, p: Vector3, surf: Dictionary, normal := Vector3.ZERO) -> bool:
	var pr := projector(s, d)
	var rel: Vector3 = p - Vector3(pr.at)
	if absf(rel.dot(pr.right)) > float(pr.w) / 2.0 or absf(rel.dot(pr.up)) > float(pr.h) / 2.0 or absf(rel.dot(pr.n)) > float(pr.depth) / 2.0:
		return false
	var m := normal if normal.length_squared() > 1e-12 else _normal_at(p, surf)
	return m == Vector3.ZERO or m.normalized().dot(pr.n) >= MIN_FACING

## The point of a sticker's layout that a point p of the surface (host frame) is printed from: (u, v) along its right
## and up from `at` - the projection is orthographic, so this is p's own offset; Vector2(INF, INF) where the surface
## there faces n by less than MIN_FACING (its far side). The inverse of the print, for picking a sticker under the aim.
static func layout_of(s: Dictionary, p: Vector3, surf: Dictionary) -> Vector2:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var m := _normal_at(p, surf)
	if m != Vector3.ZERO and m.dot(b.n) < MIN_FACING:
		return Vector2(INF, INF)
	var rel := p - StickerData.v3(s.get("at"))
	return Vector2(rel.dot(b.right), rel.dot(b.up))

## The outward normal of an analytic body at its surface point p (host frame), Vector3.ZERO when it has none.
static func _normal_at(p: Vector3, surf: Dictionary) -> Vector3:
	match str(surf.get("shape", "")):
		"sphere":
			return p.normalized() if p.length() > 1e-9 else Vector3.ZERO
		"cylinder":
			var r := float(surf.get("r", 0.0))
			var hh := float(surf.get("h", 0.0)) / 2.0
			if hh > 0.0 and absf(p.y) >= hh - 0.001 and Vector2(p.x, p.z).length() < r - 0.001:
				return Vector3(0, signf(p.y), 0)
			var side := Vector3(p.x, 0.0, p.z)
			return side.normalized() if side.length() > 1e-9 else Vector3.ZERO
		"box":
			var e := StickerData.v3(surf.get("size")) / 2.0
			var q := p - StickerData.v3(surf.get("at", [0.0, 0.0, 0.0]))
			var best := -1
			var most := -INF
			for axis in 3:
				if e[axis] > 0.0 and absf(q[axis]) / e[axis] > most:
					most = absf(q[axis]) / e[axis]
					best = axis
			var m := Vector3.ZERO
			if best >= 0:
				m[best] = signf(q[best])
			return m
	return Vector3.ZERO

## One sticker as it is drawn, at `lift`: {verts, norms, uvs, idx, centre} in the host frame - laid on the body as
## shape_of() prints it, or its quad as a mesh where it is drawn flat. `fixed_cells` > 0 sets a grid's cells a side.
static func curved_mesh(s: Dictionary, d: Dictionary, lift: float, surf: Dictionary, fixed_cells := 0) -> Dictionary:
	var g := shape_of(s, d, surf, fixed_cells)
	if not bool(g.get("laid", false)):
		var xf := pose(s, d, lift)
		var nn: Vector3 = xf.basis.z.normalized()
		return {"verts": PackedVector3Array([xf * Vector3(-0.5, 0.5, 0), xf * Vector3(0.5, 0.5, 0), xf * Vector3(0.5, -0.5, 0), xf * Vector3(-0.5, -0.5, 0)]),
			"norms": PackedVector3Array([nn, nn, nn, nn]), "uvs": PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]),
			"idx": PackedInt32Array([0, 1, 2, 0, 2, 3]), "centre": xf.origin}
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var gv: Array = g.verts
	var gn: Array = g.norms
	for i in gv.size():
		var m: Vector3 = gn[i]
		verts.append(Vector3(gv[i]) + m * lift)
		norms.append(m)
	return {"verts": verts, "norms": norms, "uvs": PackedVector2Array(g.uvs), "idx": PackedInt32Array(g.idx), "centre": Vector3(g.centre) + Vector3(g.centre_n) * lift}

# ==== the print ====

## How one sticker is printed on a body (sticker-decal.ts: the projector's box, MIN_FACING, the orthographic
## projection along -n): {laid: false} for its plain quad - no body known, a sticker whole inside one face, or one the
## body takes no ink from - else {laid: true, curved (a grid among its pieces), verts, norms, uvs, idx (Arrays), centre,
## centre_n} in the host frame at lift 0: verts[i] + norms[i] * lift is the print at a lift.
static func shape_of(s: Dictionary, d: Dictionary, surf: Dictionary, fixed_cells := 0) -> Dictionary:
	var kind := str(surf.get("shape", ""))
	if kind == "" or d.is_empty():
		return {"laid": false, "curved": false}
	var pr := projector(s, d)
	var out := {"verts": [], "norms": [], "uvs": [], "idx": [], "curved": false, "pieces": 0, "whole": false}
	match kind:
		"sphere":
			if float(surf.get("r", 0.0)) > 0.0:
				_grid(out, pr, surf, fixed_cells)
		"cylinder":
			var r := float(surf.get("r", 0.0))
			var hh := float(surf.get("h", 0.0)) / 2.0
			if r > 0.0:
				_grid(out, pr, surf, fixed_cells)
				if hh > 0.0:
					for sgn in [1.0, -1.0]:
						var cap: Array = []
						for k in CAP_SIDES:
							var a := TAU * k / CAP_SIDES
							cap.append(Vector3(r * sin(a), sgn * hh, r * cos(a)))
						_planar(out, pr, cap, Vector3(0.0, sgn, 0.0))
		"box":
			var size := StickerData.v3(surf.get("size"))
			if size.x > 0.0 and size.y > 0.0 and size.z > 0.0:
				for f in _box_faces(StickerData.v3(surf.get("at", [0.0, 0.0, 0.0])), size / 2.0):
					_planar(out, pr, f[0], f[1])
	if (out.idx as Array).is_empty():
		return {"laid": false, "curved": false}
	if not bool(out.curved) and int(out.pieces) == 1 and bool(out.whole):
		return {"laid": false, "curved": false}
	var c0: Dictionary = _cast(pr, surf, Vector2.ZERO) if bool(out.curved) else {}
	var hit := bool(c0.get("hit", false))
	out["laid"] = true
	out["centre"] = c0.p if hit else pr.at
	out["centre_n"] = c0.m if hit else pr.n
	return out

## The six faces of a box (centre c, half extents e): [[polygon, outward normal]].
static func _box_faces(c: Vector3, e: Vector3) -> Array:
	var faces: Array = []
	for axis in 3:
		for sgn in [1.0, -1.0]:
			var m := Vector3.ZERO
			m[axis] = sgn
			var a1 := (axis + 1) % 3
			var a2 := (axis + 2) % 3
			var poly: Array = []
			for corner in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				var p := c
				p[axis] += sgn * e[axis]
				p[a1] += float(corner[0]) * e[a1]
				p[a2] += float(corner[1]) * e[a2]
				poly.append(p)
			faces.append([poly, m])
	return faces

## A planar face of the body under the projector (sticker-decal.ts: a triangle whose face normal . n >= MIN_FACING is
## clipped by the six planes of the projector's box): the face polygon (convex, host frame), clipped in projector space
## (x along right, y along up, z along n, from `at`), appended as a fan. The UV of a point is its (x, y) in the box.
static func _planar(out: Dictionary, pr: Dictionary, poly: Array, m: Vector3) -> void:
	var n: Vector3 = pr.n
	var facing := m.dot(n)
	if facing < MIN_FACING:
		return
	var at: Vector3 = pr.at
	var right: Vector3 = pr.right
	var up: Vector3 = pr.up
	var w: float = pr.w
	var h: float = pr.h
	var hd: float = float(pr.depth) / 2.0
	var pts: Array = []
	for p in poly:
		var rel: Vector3 = Vector3(p) - at
		pts.append(Vector3(rel.dot(right), rel.dot(up), rel.dot(n)))
	for plane in [[0, 1.0, w / 2.0], [0, -1.0, w / 2.0], [1, 1.0, h / 2.0], [1, -1.0, h / 2.0], [2, 1.0, hd], [2, -1.0, hd]]:
		pts = _clip_axis(pts, int(plane[0]), float(plane[1]), float(plane[2]))
		if pts.size() < 3:
			return
	var area := 0.0
	for k in pts.size():
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[(k + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	area = absf(area) / 2.0
	if area < 1e-10:
		return
	var verts: Array = out.verts
	var base := verts.size()
	for q in pts:
		verts.append(at + right * q.x + up * q.y + n * q.z)
		(out.norms as Array).append(m)
		(out.uvs as Array).append(Vector2(q.x / w + 0.5, 0.5 - q.y / h))
	for k in range(1, pts.size() - 1):
		_tri(out, base, base + k, base + k + 1)
	out.pieces = int(out.pieces) + 1
	# the sticker's own plane is this face's, and the face holds all of it: the plain quad draws exactly this
	out.whole = facing >= 1.0 - 1e-5 and absf((Vector3(poly[0]) - at).dot(m)) <= 0.0005 and area >= w * h * (1.0 - 1e-4)

## Sutherland-Hodgman in projector space: the polygon kept where sign * p[axis] <= bound.
static func _clip_axis(poly: Array, axis: int, sign: float, bound: float) -> Array:
	var kept: Array = []
	for k in poly.size():
		var a: Vector3 = poly[k]
		var c: Vector3 = poly[(k + 1) % poly.size()]
		var fa := sign * a[axis] - bound
		var fc := sign * c[axis] - bound
		if fa <= 0.0:
			kept.append(a)
		if (fa < 0.0 and fc > 0.0) or (fa > 0.0 and fc < 0.0):
			kept.append(a.lerp(c, fa / (fa - fc)))
	return kept

## The sphere's surface or the cylinder's side, printed through the projector: the layout's cells x cells grid (enough
## that no cell spans more than STEP radians where the print is steepest, or `fixed_cells`), each point carried along
## -n onto the body (_cast). A cell inside every bound is two triangles on shared points; one cut by a bound (the
## projector's depth, MIN_FACING, a rim) is clipped in the layout at that bound and fanned.
static func _grid(out: Dictionary, pr: Dictionary, surf: Dictionary, fixed_cells: int) -> void:
	var r := float(surf.get("r", 0.0))
	var n: Vector3 = pr.n
	if str(surf.get("shape", "")) == "cylinder" and Vector2(n.x, n.z).length() < MIN_FACING:
		return   # the side faces n nowhere by MIN_FACING (a sticker on a cap): it takes no ink
	var w: float = pr.w
	var h: float = pr.h
	var steep := clampf(1.0 - float(pr.depth) / (2.0 * r), MIN_FACING, 1.0)   # the least facing inside the depth
	var cells := fixed_cells if fixed_cells > 0 else clampi(ceili(maxf(w, h) / (r * steep * STEP)), CELLS_LEAST, CELLS_MOST)
	var row := cells + 1
	var lattice: Array = []          # per point: [vertex index or -1, layout (u, v), uv, bounds, cast]
	for j in row:
		for i in row:
			var uv := Vector2(float(i) / cells, float(j) / cells)
			var lv := Vector2((uv.x - 0.5) * w, (0.5 - uv.y) * h)
			var e := _bounds(pr, surf, lv)
			lattice.append([-1, lv, uv, e[0], e[1]])
	var nb := (lattice[0][3] as Array).size()
	var before := (out.idx as Array).size()
	for j in cells:
		for i in cells:
			var corners := [lattice[j * row + i], lattice[j * row + i + 1], lattice[(j + 1) * row + i + 1], lattice[(j + 1) * row + i]]
			var whole := true
			var outside := false
			for k in nb:
				var fails := 0
				for c in corners:
					if float(c[3][k]) < 0.0:
						fails += 1
				whole = whole and fails == 0
				outside = outside or fails == 4
			if outside:
				continue
			if whole:
				var ids: Array = []
				for c in corners:
					if int(c[0]) < 0:
						c[0] = _add(out, c[4], c[2])
					ids.append(int(c[0]))
				_tri(out, ids[0], ids[1], ids[2])
				_tri(out, ids[0], ids[2], ids[3])
				continue
			var poly: Array = []
			for c in corners:
				poly.append(c[1])
			for k in nb:
				poly = _clip_layout(poly, pr, surf, k)
				if poly.size() < 3:
					break
			if poly.size() < 3:
				continue
			var casts: Array = []
			for lv in poly:
				var cast := _cast(pr, surf, lv)
				if not bool(cast.hit):
					casts.clear()
					break
				casts.append(cast)
			if casts.size() < 3:
				continue
			var ids: Array = []
			for k in poly.size():
				var lv: Vector2 = poly[k]
				ids.append(_add(out, casts[k], Vector2(lv.x / w + 0.5, 0.5 - lv.y / h)))
			for k in range(1, ids.size() - 1):
				_tri(out, ids[0], ids[k], ids[k + 1])
	if (out.idx as Array).size() > before:
		out.curved = true

## The layout point (u, v) carried along -n onto the sphere or the cylinder's side: the front-most crossing of the
## line at + right u + up v + t n with the body. {hit, t, p, m (the outward normal there), facing (= m . n)}; a miss
## has hit false and a facing below 0 that grows to 0 at the body's silhouette (so a bound can be found across it).
static func _cast(pr: Dictionary, surf: Dictionary, lv: Vector2) -> Dictionary:
	var n: Vector3 = pr.n
	var q: Vector3 = Vector3(pr.at) + Vector3(pr.get("right", Vector3.RIGHT)) * lv.x + Vector3(pr.get("up", Vector3.UP)) * lv.y
	var r := float(surf.get("r", 0.0))
	if r <= 0.0:
		return {"hit": false, "facing": -1.0}
	if str(surf.get("shape", "")) == "cylinder":
		var a := n.x * n.x + n.z * n.z
		var b := q.x * n.x + q.z * n.z
		var c := q.x * q.x + q.z * q.z - r * r
		var disc := b * b - a * c
		if a < 1e-9:
			return {"hit": false, "facing": -1.0}
		if disc < 0.0:
			return {"hit": false, "facing": -sqrt(-disc) / r}
		var root := sqrt(disc)
		var t := (-b + root) / a
		var p := q + n * t
		return {"hit": true, "t": t, "p": p, "m": Vector3(p.x, 0.0, p.z).normalized(), "facing": root / r}
	var b2 := q.dot(n)
	var disc2 := b2 * b2 - (q.dot(q) - r * r)
	if disc2 < 0.0:
		return {"hit": false, "facing": -sqrt(-disc2) / r}
	var root2 := sqrt(disc2)
	var t2 := -b2 + root2
	var p2 := q + n * t2
	return {"hit": true, "t": t2, "p": p2, "m": p2.normalized(), "facing": root2 / r}

## The bounds a layout point must keep to be printed, each >= 0 inside: [facing - MIN_FACING, the projector's back
## (t + depth / 2), its front (depth / 2 - t), and on the cylinder its top and bottom rims], with the point's cast.
static func _bounds(pr: Dictionary, surf: Dictionary, lv: Vector2) -> Array:
	var c := _cast(pr, surf, lv)
	var hd := float(pr.depth) / 2.0
	var cyl := str(surf.get("shape", "")) == "cylinder"
	var hh := float(surf.get("h", 0.0)) / 2.0
	var g: Array = [float(c.facing) - MIN_FACING]
	if bool(c.hit):
		var t := float(c.t)
		g.append(t + hd)
		g.append(hd - t)
		if cyl:
			var y: float = (c.p as Vector3).y
			g.append(hh - y if hh > 0.0 else 1.0)
			g.append(y + hh if hh > 0.0 else 1.0)
	else:
		g.append_array([-1.0, -1.0] + ([-1.0, -1.0] if cyl else []))
	return [g, c]

## Sutherland-Hodgman in the layout against bound k (>= 0 inside): each crossing found on its edge (_crossing).
static func _clip_layout(poly: Array, pr: Dictionary, surf: Dictionary, k: int) -> Array:
	var values: Array = []
	for p in poly:
		values.append(float(_bounds(pr, surf, p)[0][k]))
	var kept: Array = []
	for i in poly.size():
		var a: Vector2 = poly[i]
		var c: Vector2 = poly[(i + 1) % poly.size()]
		var ga: float = values[i]
		var gc: float = values[(i + 1) % poly.size()]
		if ga >= 0.0:
			kept.append(a)
		if (ga >= 0.0) != (gc >= 0.0):
			kept.append(_crossing(pr, surf, k, a, c, ga, gc))
	return kept

## Where bound k crosses 0 between layout points a and c (one inside, one out), on its inside: false position and
## halving in turn, to a hundred-thousandth of the edge.
static func _crossing(pr: Dictionary, surf: Dictionary, k: int, a: Vector2, c: Vector2, ga: float, gc: float) -> Vector2:
	var s_in := 0.0 if ga >= 0.0 else 1.0
	var s_out := 1.0 - s_in
	var g_in := ga if ga >= 0.0 else gc
	var g_out := gc if ga >= 0.0 else ga
	for it in 24:
		if absf(s_out - s_in) < 1e-5:
			break
		var s := (s_in + s_out) / 2.0 if it % 2 == 1 else s_in + (s_out - s_in) * g_in / (g_in - g_out)
		var gs := float(_bounds(pr, surf, a.lerp(c, s))[0][k])
		if gs >= 0.0:
			s_in = s
			g_in = gs
		else:
			s_out = s
			g_out = gs
	return a.lerp(c, s_in)

static func _add(out: Dictionary, cast: Dictionary, uv: Vector2) -> int:
	(out.verts as Array).append(cast.p)
	(out.norms as Array).append(cast.m)
	(out.uvs as Array).append(uv)
	return (out.verts as Array).size() - 1

## One triangle, wound as Godot's front face (clockwise seen from outside: (b - a) x (c - a) points into the body).
static func _tri(out: Dictionary, a: int, b: int, c: int) -> void:
	var v: Array = out.verts
	var nm: Array = out.norms
	var va: Vector3 = v[a]
	var f := (Vector3(v[b]) - va).cross(Vector3(v[c]) - va)
	if f.length_squared() < 1e-24:
		return
	var o: Vector3 = Vector3(nm[a]) + Vector3(nm[b]) + Vector3(nm[c])
	if f.dot(o) > 0.0:
		(out.idx as Array).append_array([a, c, b])
	else:
		(out.idx as Array).append_array([a, b, c])

# ==== the stack ====

## The box a sticker's print fills (host frame), in its own right / up / n: its quad, or its laid mesh's extent, and
## FOOT_SLACK each way along n. {c, ax: [right, up, n], h (half extents), r (its bounding radius)}.
static func footprint(s: Dictionary, d: Dictionary, g: Dictionary) -> Dictionary:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var right: Vector3 = b.right
	var up: Vector3 = b.up
	var n: Vector3 = b.n
	var at := StickerData.v3(s.get("at"))
	var c := at
	var h: Vector3
	if not bool(g.get("laid", false)):
		var e := StickerData.extent(d, float(s.get("size", 0.2)))
		h = Vector3(e.x / 2.0, e.y / 2.0, FOOT_SLACK)
	else:
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for p in g.verts:
			var rel: Vector3 = Vector3(p) - at
			var q := Vector3(rel.dot(right), rel.dot(up), rel.dot(n))
			lo = Vector3(minf(lo.x, q.x), minf(lo.y, q.y), minf(lo.z, q.z))
			hi = Vector3(maxf(hi.x, q.x), maxf(hi.y, q.y), maxf(hi.z, q.z))
		var mid := (lo + hi) / 2.0
		h = (hi - lo) / 2.0 + Vector3(0.0, 0.0, FOOT_SLACK)
		c = at + right * mid.x + up * mid.y + n * mid.z
	return {"c": c, "ax": [right, up, n], "h": h, "r": h.length()}

## Whether two footprints overlap (separating axes of two boxes: their six faces' normals, then the nine products of
## their edges). Boxes that only touch, by less than TOUCH, do not.
static func boxes_overlap(a: Dictionary, b: Dictionary) -> bool:
	var t: Vector3 = Vector3(b.c) - Vector3(a.c)
	if t.length() > float(a.r) + float(b.r):
		return false
	var ax: Array = a.ax
	var bx: Array = b.ax
	var ea: Vector3 = a.h
	var eb: Vector3 = b.h
	var rot: Array = []
	var arot: Array = []
	for i in 3:
		var row: Array = []
		var arow: Array = []
		for j in 3:
			var v := Vector3(ax[i]).dot(Vector3(bx[j]))
			row.append(v)
			arow.append(absf(v) + 1e-6)
		rot.append(row)
		arot.append(arow)
	var ta: Array = [t.dot(ax[0]), t.dot(ax[1]), t.dot(ax[2])]
	for i in 3:
		if absf(ta[i]) > ea[i] + eb[0] * arot[i][0] + eb[1] * arot[i][1] + eb[2] * arot[i][2] - TOUCH:
			return false
	for j in 3:
		var tb: float = ta[0] * rot[0][j] + ta[1] * rot[1][j] + ta[2] * rot[2][j]
		if absf(tb) > ea[0] * arot[0][j] + ea[1] * arot[1][j] + ea[2] * arot[2][j] + eb[j] - TOUCH:
			return false
	for i in 3:
		var i1 := (i + 1) % 3
		var i2 := (i + 2) % 3
		for j in 3:
			var j1 := (j + 1) % 3
			var j2 := (j + 2) % 3
			var ra: float = ea[i1] * arot[i2][j] + ea[i2] * arot[i1][j]
			var rb: float = eb[j1] * arot[i][j2] + eb[j2] * arot[i][j1]
			if absf(ta[i2] * rot[i1][j] - ta[i1] * rot[i2][j]) > ra + rb:
				return false
	return true

# ==== where ====

## Where a sticker's middle is drawn (host frame) at `lift`: its `at` carried onto a curved body along -n, else at.
static func centre_of(s: Dictionary, surf: Dictionary, lift: float) -> Vector3:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var at := StickerData.v3(s.get("at"))
	if str(surf.get("shape", "")) in ["sphere", "cylinder"]:
		var c := _cast({"at": at, "right": b.right, "up": b.up, "n": b.n}, surf, Vector2.ZERO)
		if bool(c.hit):
			return Vector3(c.p) + Vector3(c.m) * lift
	return at + Vector3(b.n) * lift

## Where each drawn sticker stands in the world, by id (for probes and tools): {id: Vector3}.
func world_positions() -> Dictionary:
	var out: Dictionary = {}
	var surf := body()
	for s0 in data.stickers_on(host_key()):
		var s := drawn_as(s0, host)
		out[str(s.get("id", ""))] = global_transform * centre_of(s, surf, LIFT)
	return out
