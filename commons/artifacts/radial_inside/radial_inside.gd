extends Node3D
class_name RadialInside

## RADIAL INSIDE — a structure you are inside of.
##
## 2026-09-03, Palle: "Can you make like Zaha Hadid inside radical architecture
## that we can walk inside and are large and immersive using the same techniques
## you use to create the sculptures, to make large walkable structures with both
## hard modeling and soft modeling and different shader on each element."
##
## After his own 2020 work RADICAL INSIDE, in which he drove Sketchfab's camera
## INSIDE 3D models and filmed their interiors: a "cave-like labyrinth", a
## "surrealist colour and sculptural assemblage informed by distorted desires",
## reached by an angle that "displaces the normative placement of the model".
## The frames are the brief. What they show, and what this builds:
##
##   NESTED FACETED RINGS RECEDING DOWN A TUNNEL, with small metal tabs
##   straddling every joint. That greyscale frame is a construction drawing: the
##   lumen is a loft of polygon rings, and the tabs are the evidence that it was
##   assembled rather than grown.
##   AN OVOID APERTURE opening from a lit chamber into a cold one. You do not
##   walk down a corridor, you find the hole that reaches the floor.
##   HAIRLINE EMISSIVE FILAMENTS along every cut edge, on black. The seams are
##   the only light, and light is the only wayfinding.
##   FLAT GRAPHIC SHAPES floating inside a volumetric chamber — unshaded vector
##   cutouts that belong to no surface.
##   HARD SHARDS LYING ACROSS SOFT DOMES: the two registers touching.
##
## HARD IS LOFTED, SOFT IS MARCHED, AND THE ARITHMETIC CHOSE THAT, NOT TASTE.
## A SurfaceTool loft is scale-free — the same 40x14 grid describes a 1.6 m body
## or a 30 m tunnel. A march costs span CUBED: dream_iso caps at 220,000 cells
## and silently coarsens up to 9.3x, so a 4 cm request over 20 m comes back as
## 29.8 cm, and the honest version would take about four hours. So the shell is
## lofted and the SOFT appears only at the JUNCTIONS, in local ~2.4 m volumes,
## which is exactly inside the mesher's own budget.
##
## That constraint turns out to be the argument. The hard parts are the armature
## — plates, ruled surfaces, construction lines, the side that faces out. The
## soft parts are what the armature was carrying, and they exist only where two
## hard things meet, because a fillet is precisely the thing an assembly does not
## have. You walk through a building of panels whose every joint has turned to
## cartilage. Hard means room; soft means way through.
##
## YOU ARE ON THE WRONG SIDE OF EVERY SURFACE, and that is a shader fact, not a
## metaphor. Standing inside a closed shell you see BACK faces. Godot flips the
## built-in NORMAL for those (measured, under both cull_front and cull_disabled)
## but it cannot flip a normal a shader computed for itself — dream_gloss.gdshader
## carries that fix now. The lumen skin is cull_front: half the triangles, and
## the exterior correctly cannot be seen from within.
##
## THE ENVELOPE IS THE PLAYER, and it is measured from commons/scenes/desktop_player.tscn:
## a capsule 0.30 m in radius and 1.80 m tall, eye at 1.60, floor_max_angle 45
## degrees, and NO STEP HEIGHT AT ALL — Godot 4's CharacterBody3D has none and
## DesktopPlayer adds none, so every level change is a ramp or it is a wall. The
## museum's own walked verdict on doorways is recorded in endless_museum.gd:
## "the passages are too small", every 1 m door widened to 2 m. So: 2.2 m of
## clear headroom, 2.0 m apertures, and floors under 20 degrees.
##
## NOT A DNA FAMILY, DELIBERATELY. Every rule in the artifact-DNA section assumes
## the evidence is one photograph from one standpoint, and this project has
## already recorded that five of seven INERT verdicts were false because of it.
## For something you walk inside, EVERY axis is anamorphic by construction. Its
## evidence is a WALK: commons/testing/probe_radial_inside.gd puts the player's
## own capsule through it and measures headroom, aperture width, floor angle and
## reachability. A tile sheet would be a fact about a camera.

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Shaders := preload("res://commons/artifacts/dream_bodies/dream_shaders.gd")

# --- the envelope, from the player. Change these and re-run the probe. --------
const HEADROOM: float = 2.2          # clear, standing
const APERTURE_W: float = 2.0        # the museum's own walked verdict
const CAPSULE_R: float = 0.30

@export var seed: int = 1
## How far the tunnel runs, in metres. The loft is scale-free, so this is nearly
## free — what it costs is collision triangles and the marched junctions.
@export_range(12.0, 60.0, 1.0) var length_m: float = 34.0
## Rings per metre. 0.7 gives a 1.4 m bay: coarse enough to read as PANELS, which
## is what a built Hadid actually is, and what stops a 30 m loft pretending to be
## smooth.
@export_range(0.4, 1.6, 0.05) var rings_per_m: float = 0.7
## Sides of the tunnel's polygon section. The frame that started this shows about
## eight, and the facets are the point — do not raise this to fake a circle.
@export_range(5, 14) var sides: int = 8
## Cell size for the marched junctions. Clamped in code to a range that has been
## MEASURED, because a coarser cell is a silent amputation: dream_iso warns only
## when it emits nothing at all.
@export_range(0.055, 0.13, 0.005) var junction_cell: float = 0.085
## What the shell is made of. Six surfaces written FOR architecture rather than
## borrowed from the bodies — see arch_surface.gdshader for why that distinction
## is not cosmetic.
@export_enum("panel", "film", "velvet", "wetstone", "nacre", "flesh") var surface: String = "panel"

const ARCH_SHADER: Shader = preload("res://commons/artifacts/radial_inside/arch_surface.gdshader")
## The architecture surfaces, in the shader's own uniform order — index IS the
## mode, so this array and the shader cannot drift apart.
const SURFACES: Array[String] = ["panel", "film", "velvet", "wetstone", "nacre", "flesh"]
var QK: Array = Gloss.QUEER.keys()

var _rng := RandomNumberGenerator.new()
var _built: bool = false
## Every band's rings, kept so the junctions know where the wall actually is.
var _spine: Array = []


## The tunnel's own centre line, for anything that has to travel it. A probe
## walking the AABB's middle would walk into the wall — the spine wanders.
func spine_points() -> Array:
	var out: Array = []
	for r_v in _spine:
		out.append((r_v as Dictionary)["c"])
	return out


func apply_grid_config(config: Dictionary) -> void:
	for k in ["seed", "length_m", "rings_per_m", "sides", "junction_cell", "surface"]:
		if config.has(k):
			set(k, config[k])
	if is_inside_tree():
		_built = false
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	for c in get_children():
		c.queue_free()
	_rng.seed = seed
	_spine.clear()

	var rings: Array = _make_spine()
	var outfit: Dictionary = _palette()
	_lumen(rings, outfit)
	_deck(rings, outfit)
	_tabs(rings, outfit)
	_apertures(rings, outfit)
	_junctions(rings, outfit)
	_graphics(rings, outfit)


# ── the spine ──────────────────────────────────────────────────────────────
#
# A curve that never straightens, so you are always turning without ever having
# chosen to. The radius breathes: 2.4 m at a pinch is a room you stoop through,
# 4.6 m at a bell is a chamber. Both are above the standing envelope, which is
# the one number that is not allowed to be interesting.
func _make_spine() -> Array:
	var n: int = maxi(6, int(length_m * rings_per_m))
	var out: Array = []
	var yaw_amp: float = _rng.randf_range(0.5, 1.1)
	var yaw_f: float = _rng.randf_range(0.7, 1.4)
	var rise: float = _rng.randf_range(-0.10, 0.16)     # under 20 deg at any t
	var roll_rate: float = _rng.randf_range(0.4, 1.2)
	var pinch_f: float = _rng.randf_range(1.4, 2.6)
	var pinch_ph: float = _rng.randf_range(0.0, TAU)
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var z: float = t * length_m
		var x: float = sin(t * TAU * yaw_f * 0.5) * yaw_amp * length_m * 0.10
		var y: float = t * length_m * rise * 0.30
		# the lumen radius, never below what a person needs
		var breathe: float = 0.5 + 0.5 * sin(t * TAU * pinch_f + pinch_ph)
		var r: float = lerpf(2.45, 4.60, breathe)
		out.append({
			"c": Vector3(x, y, z),
			"r": r,
			"roll": t * roll_rate * TAU * 0.25,
			"t": t,
		})
	_spine = out
	return out


## The section: a polygon, rolled, in the plane normal to the spine's direction.
func _ring_points(rings: Array, i: int, radius_mul: float) -> Array:
	var r0: Dictionary = rings[i]
	var c: Vector3 = r0["c"]
	var fwd: Vector3 = Vector3.FORWARD
	if i < rings.size() - 1:
		fwd = ((rings[i + 1]["c"] as Vector3) - c).normalized()
	else:
		fwd = (c - (rings[i - 1]["c"] as Vector3)).normalized()
	var up: Vector3 = Vector3.UP
	var right: Vector3 = up.cross(fwd).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	up = fwd.cross(right).normalized()
	var pts: Array = []
	var roll: float = float(r0["roll"])
	var rad: float = float(r0["r"]) * radius_mul
	for k in range(sides):
		var a: float = TAU * float(k) / float(sides) + roll
		pts.append(c + right * (cos(a) * rad) + up * (sin(a) * rad))
	return pts


# ── the lumen: the hard shell you stand in ─────────────────────────────────
#
# Inner skin, outer skin and the floor, lofted as flat quads with no smoothing —
# a panel is a panel. Collision is a trimesh of the FLOOR ONLY, plus the walls,
# built per band so a 30 m tunnel is not one 400,000-triangle shape.
func _lumen(rings: Array, outfit: Dictionary) -> void:
	var wall: float = 0.42                               # a real architectural wall
	var mat_in: ShaderMaterial = outfit["skin_in"]
	var mat_out: StandardMaterial3D = outfit["skin_out"]

	var band: int = 6                                    # rings per collision body
	var st_in := SurfaceTool.new()
	var st_out := SurfaceTool.new()
	st_in.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_out.begin(Mesh.PRIMITIVE_TRIANGLES)
	var in_band: int = 0

	for i in range(rings.size() - 1):
		var a_in: Array = _ring_points(rings, i, 1.0)
		var b_in: Array = _ring_points(rings, i + 1, 1.0)
		var a_out: Array = _ring_points(rings, i, 1.0 + wall / float(rings[i]["r"]))
		var b_out: Array = _ring_points(rings, i + 1, 1.0 + wall / float(rings[i + 1]["r"]))
		for k in range(sides):
			var k2: int = (k + 1) % sides
			# THE FLOOR IS NOT A FACET OF THE TUBE, and finding that out cost a
			# probe run. The section ROLLS along the spine — that is what keeps you
			# turning without choosing to — so which facet faces down changes as
			# you walk, and at the halfway points a VERTEX faces down instead. The
			# probe measured the result: a 76.2 degree surface where a floor should
			# be, which in an engine with no step height is a wall. So the tube is
			# the enclosure and the deck below is the floor, laid inside it, which
			# is also what a building actually does.
			# the panel's own hue, dealt from its position in the loft so it is
			# stable across rebuilds, with the alpha carrying a phase the film
			# mode uses to keep two neighbours from shimmering in lockstep
			var pk: int = absi(hash("%d|%d|%d" % [seed, i, k]))
			var pc: Color = Gloss.QUEER[QK[pk % QK.size()]]
			pc = pc.lerp(Color(1, 1, 1), float((pk / 7) % 30) * 0.006)
			pc.a = float(pk % 997) / 997.0
			_quad(st_in, a_in[k], a_in[k2], b_in[k2], b_in[k], pc)
			_quad(st_out, a_out[k2], a_out[k], b_out[k], b_out[k2])
		in_band += 1
		if in_band >= band or i == rings.size() - 2:
			_commit(st_in, mat_in, true, "Lumen")
			_commit(st_out, mat_out, false, "Outer")
			st_in = SurfaceTool.new(); st_in.begin(Mesh.PRIMITIVE_TRIANGLES)
			st_out = SurfaceTool.new(); st_out.begin(Mesh.PRIMITIVE_TRIANGLES)
			in_band = 0


## One quad, wound so its face points at the FIRST-named side.
##
## Godot winds front faces CLOCKWISE and generate_normals() takes Plane(a,b,c),
## which is (a-c) x (a-b) — the negative of the textbook cross. Getting this
## backwards produces a mesh that is consistently inside out and looks fine,
## which is exactly how it survives to ship.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		col: Color = Color(0, 0, 0, 0)) -> void:
	# A PANEL IS A DECISION, so it carries its own colour and its own unwrap. The
	# colour goes in vertex COLOR (every corner the same, so it is flat by
	# construction), and the 0..1 UV is what lets the shader know how far a
	# fragment is from the panel's EDGE — which is where the seam lives, and the
	# seams are the only light in a windowless interior.
	var tag: bool = col.a > 0.0
	var uv: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var vs: Array = [a, b, c, d]
	for tri in [[0, 1, 2], [0, 2, 3]]:
		for j in tri:
			if tag:
				st.set_color(col)
				st.set_uv(uv[int(j)])
			st.add_vertex(vs[int(j)])


func _commit(st: SurfaceTool, mat: Material, collide: bool, nm: String) -> void:
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	if not collide:
		return
	# THE FAMILY THIS BORROWS FROM HAS NO COLLIDERS BY WRITTEN CONTRACT — a dream
	# body "is looked at". A building is not, so this is new obligation, not a
	# tuning pass. Trimesh per band: one 30 m shape would be a single 400k-triangle
	# collider that the broadphase can never cull.
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	mi.add_child(body)


# ── the deck: the one thing you are allowed to trust ───────────────────────
#
# A flat ribbon following the spine at a CONSTANT drop below its centre line, so
# its only slope is the spine's own gentle rise and never the section's roll. Its
# width is set by the tube it has to fit inside — at a pinch the tube is 2.45 m
# in radius and the chord at deck height is narrower than the deck wants to be,
# so the deck yields rather than pushing through the wall, and never below the
# 2.2 m that the museum's own walked verdict says a passage needs.
const DECK_DROP: float = 1.90
const DECK_W_MAX: float = 3.40
const DECK_W_MIN: float = 2.20


func _deck(rings: Array, outfit: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev_l: Vector3 = Vector3.INF
	var prev_r: Vector3 = Vector3.INF
	for i in range(rings.size()):
		var c: Vector3 = rings[i]["c"]
		var rad: float = rings[i]["r"]
		var fwd: Vector3 = Vector3.FORWARD
		if i < rings.size() - 1:
			fwd = ((rings[i + 1]["c"] as Vector3) - c)
		else:
			fwd = (c - (rings[i - 1]["c"] as Vector3))
		fwd.y = 0.0
		fwd = fwd.normalized()
		var side: Vector3 = Vector3.UP.cross(fwd).normalized()
		# the chord the tube leaves at deck height, so the deck cannot poke out
		var chord: float = 2.0 * sqrt(maxf(rad * rad - DECK_DROP * DECK_DROP, 0.36))
		var w: float = clampf(minf(DECK_W_MAX, chord * 0.94), DECK_W_MIN, DECK_W_MAX) * 0.5
		var y: float = c.y - DECK_DROP
		var l: Vector3 = Vector3(c.x, y, c.z) - side * w
		var r: Vector3 = Vector3(c.x, y, c.z) + side * w
		if prev_l != Vector3.INF:
			# wound so the walking surface faces UP
			_quad(st, prev_l, prev_r, r, l)
		prev_l = l
		prev_r = r
	_commit(st, outfit["floor"], true, "Deck")


# ── the tabs: the evidence of manufacture ──────────────────────────────────
#
# Small plates straddling the ring joints, exactly as the reference frame shows
# them. They are the whole reason the lumen reads as ASSEMBLED, which is what
# makes the marched junctions later read as a fault in the assembly rather than
# as more of the same.
func _tabs(rings: Array, outfit: Dictionary) -> void:
	var mat: StandardMaterial3D = outfit["tab"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 0
	for i in range(2, rings.size() - 2, 2):
		var pts: Array = _ring_points(rings, i, 1.0)
		var nxt: Array = _ring_points(rings, i + 1, 1.0)
		for k in range(sides):
			if _rng.randf() > 0.42:
				continue
			var p: Vector3 = pts[k]
			var q: Vector3 = nxt[k]
			var c: Vector3 = rings[i]["c"]
			var inward: Vector3 = (c - p).normalized()
			var along: Vector3 = (q - p)
			var side: Vector3 = along.cross(inward).normalized() * 0.16
			var lift: Vector3 = -inward * 0.07
			var a0: Vector3 = p - along * 0.35 - side + lift
			var a1: Vector3 = p - along * 0.35 + side + lift
			var b0: Vector3 = p + along * 1.35 - side + lift
			var b1: Vector3 = p + along * 1.35 + side + lift
			_quad(st, a0, a1, b1, b0)
			n += 1
	if n == 0:
		return
	_commit(st, mat, false, "Tabs")


# ── the apertures: how you get on ──────────────────────────────────────────
#
# Not doors. Holes in the wall that happen to reach the floor, which is the
# reference's own grammar — you look through an opening in one shell into
# another chamber, and most of the openings are useless to you.
#
# Each aperture is a rolled ring standing proud of the lumen wall, with an
# emissive lip. The hole itself is cut by the marched junction that follows.
func _apertures(rings: Array, outfit: Dictionary) -> void:
	var mat: StandardMaterial3D = outfit["lip"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var made: int = 0
	var i: int = 4
	while i < rings.size() - 5:
		var pts: Array = _ring_points(rings, i, 1.0)
		# pick a facet that is NOT the floor
		var k: int = _rng.randi_range(0, sides - 1)
		var p: Vector3 = pts[k]
		var c: Vector3 = rings[i]["c"]
		if p.y < c.y - float(rings[i]["r"]) * 0.5:
			i += 3
			continue
		var outward: Vector3 = (p - c).normalized()
		var w: float = maxf(APERTURE_W, 2.0) * 0.5 + 0.25
		var u: Vector3 = outward.cross(Vector3.UP).normalized() * w
		if u.length_squared() < 0.001:
			u = Vector3.RIGHT * w
		var v: Vector3 = outward.cross(u).normalized() * w
		var ring_n: int = 12
		for s in range(ring_n):
			var a0: float = TAU * float(s) / float(ring_n)
			var a1: float = TAU * float(s + 1) / float(ring_n)
			var q0: Vector3 = p + u * cos(a0) + v * sin(a0)
			var q1: Vector3 = p + u * cos(a1) + v * sin(a1)
			var o0: Vector3 = q0 + outward * 0.34
			var o1: Vector3 = q1 + outward * 0.34
			_quad(st, q0, q1, o1, o0)
		_spine[i]["breach"] = {"at": p, "out": outward, "w": w, "deck_y": c.y - DECK_DROP}
		made += 1
		i += _rng.randi_range(4, 7)
	if made > 0:
		_commit(st, mat, false, "Lips")


# ── the junctions: the only soft thing in the building ─────────────────────
#
# Where a breach meets the wall, the panelling stops and the two surfaces have
# FUSED — no edge, no join, a marched throat you stoop through. This is the
# whole hard/soft argument in one object, and it is local by necessity: a 2.4 m
# field at 8.5 cm is about 25,000 cells, well inside dream_iso's 220,000 budget,
# where the same march over the whole tunnel would silently return 30 cm cells.
func _junctions(rings: Array, outfit: Dictionary) -> void:
	var cell: float = clampf(junction_cell, 0.055, 0.13)
	var mat: ShaderMaterial = outfit["cartilage"]
	var built: int = 0
	for r_v in _spine:
		var r: Dictionary = r_v
		if not r.has("breach"):
			continue
		var b: Dictionary = r["breach"]
		var at: Vector3 = b["at"]
		var outward: Vector3 = b["out"]
		var parts: Array = []
		# the throat: a fat capsule through the wall, swelling on both sides
		parts.append(Iso.capsule(at - outward * 0.55, at + outward * 0.85, 1.18, 0.86))
		# two lobes that make it read as flesh rather than as pipe
		var side: Vector3 = outward.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		parts.append(Iso.sphere(at + side * 0.62 + outward * 0.10, 0.72))
		parts.append(Iso.sphere(at - side * 0.58 - Vector3.UP * 0.22, 0.66))
		# and the hole through it, which is what you look through
		parts.append(Iso.cut(Iso.capsule(at - outward * 1.4, at + outward * 1.4,
			APERTURE_W * 0.5, APERTURE_W * 0.5)))
		# THE WALKING ENVELOPE IS SUBTRACTED FROM THE FLESH.
		#
		# The probe caught this and both of its failures were one object: a lobe of
		# Cartilage1 hung down over the deck at z 16.3, and it was simultaneously
		# the thing the capsule was stuck in and the 72-degree "floor" the ray
		# found. A marched blob does not know where the deck is.
		#
		# It is cut in the FIELD rather than trimmed after, so the clearance has a
		# rolled lip like every other opening here and still reads as grown. And it
		# settles what an aperture IS in this building: its sill is at head height,
		# so you look through it and cannot climb it. That is the reference's own
		# grammar — most of the openings are useless to you, and finding the one
		# that is not is the whole of moving through.
		var deck_y: float = float(b.get("deck_y", at.y - 3.0))
		var clear_h: float = 4.0
		parts.append(Iso.cut(Iso.box(Vector3(at.x, deck_y + HEADROOM - clear_h, at.z),
			Vector3(7.0, clear_h, 7.0), 0.0)))
		var mesh: ArrayMesh = Iso.mesh_of(parts, cell, 0.26, 0.10)
		if mesh == null:
			push_warning("[radial_inside] a junction at %s yielded no surface" % str(at))
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Cartilage%d" % built
		mi.mesh = mesh
		mi.material_override = mat
		add_child(mi)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		body.add_child(cs)
		mi.add_child(body)
		built += 1
	if built > 0:
		print("[radial_inside] %d marched junction(s) at cell %.3f m" % [built, cell])


# ── the flat graphics ──────────────────────────────────────────────────────
#
# Unshaded vector cutouts hanging in the volume, belonging to no surface — the
# reference has them, flat purple and red shapes floating inside a modelled
# chamber, and they are the strangest thing in it. They read as a rendering
# error that turned out to be on purpose, which is the work's whole subject.
func _graphics(rings: Array, outfit: Dictionary) -> void:
	var mat: StandardMaterial3D = outfit["flat"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 0
	for _i in range(_rng.randi_range(5, 9)):
		var ri: int = _rng.randi_range(2, rings.size() - 3)
		var c: Vector3 = rings[ri]["c"]
		var rad: float = float(rings[ri]["r"])
		# OUT NEAR THE WALL, AND ABOVE THE WALK. The first render had one of these
		# parked on the lens — an unshaded plane a metre from the eye fills the
		# frame with flat colour and the whole building disappears behind it. They
		# are marks on the room, not obstacles in it: 0.72 to 0.94 of the radius
		# puts them against the shell, and the upward bias keeps them out of the
		# corridor you actually walk.
		var dir: Vector3 = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.15, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized()
		var p: Vector3 = c + dir * rad * _rng.randf_range(0.72, 0.94)
		var yaw: float = _rng.randf_range(0.0, TAU)
		var bx: Basis = Basis(Vector3.UP, yaw)
		var w: float = _rng.randf_range(0.35, 0.95)
		var h: float = _rng.randf_range(0.25, 0.70)
		var pts: Array = []
		var lobes: int = _rng.randi_range(3, 6)
		for k in range(lobes):
			var a: float = TAU * float(k) / float(lobes) + _rng.randf_range(-0.3, 0.3)
			pts.append(p + bx * Vector3(cos(a) * w * _rng.randf_range(0.5, 1.0), 0.0,
				sin(a) * h * _rng.randf_range(0.5, 1.0)))
		for k in range(1, lobes - 1):
			st.add_vertex(pts[0]); st.add_vertex(pts[k]); st.add_vertex(pts[k + 1])
			st.add_vertex(pts[0]); st.add_vertex(pts[k + 1]); st.add_vertex(pts[k])
		n += 1
	if n > 0:
		_commit(st, mat, false, "Flats")


# ── the palette ────────────────────────────────────────────────────────────
#
# A DIFFERENT SHADER ON EACH ELEMENT, as asked — but as FAMILIES with a mode
# uniform rather than forty files. This project's own shader cache holds four
# versions across 426 compiled pipeline blobs, so one new Shader resource is
# 50-166 pipeline compilations, not one; a shader per element would be a stutter
# you cannot get back. The lumen and the cartilage take dream_gloss (two modes),
# everything else takes a StandardMaterial3D finish out of dream_skin.
func _palette() -> Dictionary:
	var main: Color = Gloss.queer_colour(_rng)
	var accent: Color = Gloss.queer_colour(_rng)
	var tries: int = 0
	while accent.is_equal_approx(main) and tries < 6:
		accent = Gloss.queer_colour(_rng)
		tries += 1

	# THE INNER SKIN IS SEEN FROM INSIDE, SO IT IS cull_front: half the triangles,
	# and the exterior correctly cannot be seen from within.
	# A ShaderMaterial HAS NO cull_mode — culling is a render_mode on the SHADER,
	# not a property of the material, and assigning it throws at runtime. That is
	# fine, because the geometry already solves it better: the lumen quads are
	# wound so their faces point INWARD (verified by the arithmetic Godot itself
	# uses, Plane(v0,v1,v2).normal = (v0-v2) x (v0-v1)), so plain cull_back keeps
	# exactly the faces you can see from inside and discards the rest. Same saving
	# as cull_front, no second shader, and — unlike a render_mode — it is a fact
	# about the mesh that a probe can measure.
	# LATEX ON THE WALLS, NOT OIL SLICK. The first render came back as psychedelic
	# candy floss: interference is a function of viewing angle, and across a 36 m
	# wall every angle is present at once, so the whole surface bands. Palle's own
	# frames are the argument — their big shells are fairly plain chrome and flesh,
	# and the loud iridescence is LOCAL, on small things close to the camera. So
	# the lumen is a deep glossy rubber and the cartilage keeps the wet shine.
	var skin_in: ShaderMaterial = _arch(surface, main, accent)
	skin_in.set_shader_parameter("seam_energy", 3.2)

	# the cartilage: wet, warm, and the only smooth thing in the building
	# the cartilage is always FLESH whatever the shell is: the soft register has to
	# stay legible as the thing the building is not
	var cart: ShaderMaterial = _arch("flesh", accent, main)
	cart.set_shader_parameter("panel_mix", 0.0)
	cart.set_shader_parameter("seam_energy", 0.0)
	cart.set_shader_parameter("glow", 0.55)

	# THE ONE DRY PASSAGE. The floor is chalk, because a wet room only reads wet
	# if the thing under your feet is not. It is also the only surface whose job
	# is to be believed rather than looked at.
	var floor_m: StandardMaterial3D = Gloss.skin("matte", Color(0.74, 0.72, 0.76), _rng)
	floor_m.roughness = 0.94

	var outer: StandardMaterial3D = Gloss.skin("patent", Color(0.10, 0.09, 0.13), _rng)
	var tab: StandardMaterial3D = Gloss.skin("chrome", Color(0.86, 0.87, 0.92), _rng)

	# the lip: the hairline filament along every cut edge, which in the reference
	# is the only light in the frame
	var lip: StandardMaterial3D = Gloss.skin("neon", accent, _rng)
	lip.emission_energy_multiplier = 2.4

	# the flat graphics: UNSHADED on purpose — they belong to no surface, they do
	# not receive the room's light, and that is what makes them read as cutouts
	# rather than as objects
	var flat: StandardMaterial3D = StandardMaterial3D.new()
	flat.albedo_color = main
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.cull_mode = BaseMaterial3D.CULL_DISABLED

	return {"skin_in": skin_in, "skin_out": outer, "floor": floor_m, "tab": tab,
		"lip": lip, "cartilage": cart, "flat": flat}


## One architecture surface. `name` is from SURFACES; anything else falls back to
## index 0, so a typo gets a wall rather than a null.
func _arch(name: String, base: Color, accent: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ARCH_SHADER
	m.set_shader_parameter("mode", maxi(0, SURFACES.find(name)))
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("accent_color", accent)
	m.set_shader_parameter("seam_color", accent.lerp(Color(1, 1, 1), 0.35))
	m.set_shader_parameter("panel_mix", 0.85)
	m.set_shader_parameter("seam_w", 0.035)
	m.set_shader_parameter("seam_energy", 3.0)
	m.set_shader_parameter("gloss", 0.7)
	m.set_shader_parameter("glow", 0.30)
	m.set_shader_parameter("seed_offset", float(seed % 997) * 0.31)
	return m
