extends SceneTree

## Can a body live inside the rhizome? (2026-09-03)
##
## probe_radial_inside.gd asked whether you can walk down a TUNNEL, and a tunnel
## has a spine and a section: one path, one direction, one answer. Palle's
## objection to it was exactly that. A rhizome has no spine — it is chambers and
## the passages between them, and the questions change shape with it:
##
##   a tunnel asks   "is the floor continuous from mouth to mouth?"
##   a rhizome asks  "is every chamber standable, is every passage passable, and
##                    is the whole cavity ONE space or several?"
##
## The last one is the one that can ship silently. dream_iso's shell_field gives
## a hollow body whose cavity is the solid's own interior, so the PLAN of the
## building is whatever the smooth-union happened to fuse. That is the whole
## point — nobody decided the plan — but it also means nobody checked it. A
## rhizome whose graph says twelve bulbs are connected, and whose FIELD closed
## one of those throats to 0.19 m because two limbs were 3 cm too far apart, is
## a building with a room nobody can reach, and it renders beautifully.
##
## So this probe does not look at the rhizome. It puts the player's own capsule
## — read from commons/scenes/desktop_player.tscn, never typed here — into every
## chamber, walks it down every declared passage, and then floods the graph it
## actually MEASURED rather than the one the builder declared. The difference
## between those two graphs is the entire finding.
##
## THREE LESSONS ARE CARRIED OVER FROM THE TUNNEL PROBE rather than rediscovered:
##
##   A SHAPE QUERY HAS A DEFAULT 0.04 m MARGIN. A capsule resting 2 cm above a
##   perfectly good floor overlaps it and the query reports "stuck" — which it
##   did, at 14 of 26 stations, on a building that was fine underfoot. So every
##   query here sets margin = 0.0 and lifts the capsule 6 cm clear.
##
##   ONE DOWNWARD RAY IS NOT A FLOOR. The first thing under a ray can be the top
##   of a wall bulge, and the probe will happily call its 72-degree flank a ramp
##   and stand the capsule on it inside the surrounding geometry. Falling means
##   continuing downward past anything steeper than the engine's own
##   floor_max_angle, so that is what _fall does.
##
##   A TEST THAT TESTED NOTHING REPORTS A PERFECT SCORE. probe_iso_chunks once
##   printed "worst distance 0.000000 m" from a comparison of zero vertices. So
##   every fraction here asserts its own DENOMINATOR before it reports a ratio.
##
## AND ONE THAT IS NEW HERE. The shell has TWO skins, so "how much of the surface
## faces me" is not a yes/no question any more — see _skins() for the arithmetic
## and for why the assertion is a window rather than a threshold.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_rhizome_inside.gd

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

const SCENE := "res://commons/artifacts/radial_inside/rhizome_inside.tscn"
const BUILDER := "res://commons/artifacts/radial_inside/rhizome_inside.gd"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/rhizome_inside_probe.txt"

## The agreed contract. A missing name here is named in the report, not guessed
## around: the builder and this probe were handed the same list, so a mismatch is
## a fact about one of the two files and the report should say which name.
const WANT_EXPORTS: Array[String] = ["seed", "surface", "cell", "wall", "blend", "bulbs"]
const WANT_METHODS: Array[String] = ["cavity_points", "graph_edges"]

## How finely a passage is walked. 0.20 m is under the capsule's own diameter, so
## a throat cannot close and reopen between two stations without being sampled.
const STEP_M: float = 0.20
## An edge longer than 40 m gets a coarser step rather than an unbounded walk.
const MAX_STEPS: int = 200
## The engine's floor_max_angle is 45 degrees and there is no step height at all,
## so anything steeper between two floor samples is a wall the player stops at.
## 50 is 45 plus five degrees of sampling slack: a genuinely 44-degree ramp
## sampled every 20 cm can alias a degree or two, and a probe that fires on its
## own discretisation is worse than no probe. A LEDGE is tens of degrees over.
const LIP_DEG: float = 50.0
## How far a body falls before "there is no floor here" rather than "there is a
## drop here". Six metres is well past survivable-and-fine and into trapdoor.
const DROP_M: float = 6.0

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80
var _wall: float = 0.30


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _read_envelope()
	await _selftest()

	# ── 0. IS THERE ANYTHING TO PROBE? ───────────────────────────────────────
	#
	# This probe was written alongside the builder, not after it, so the scene is
	# expected to be absent on the first run. An absence must be reported as an
	# absence and NAMED — "the scene did not load" sends the next agent looking
	# for a load error that does not exist. Every missing piece of the contract is
	# listed by its own name, and the run still exits non-zero, because a probe
	# that goes quiet when its subject is missing is how a stage builds on
	# silence.
	if not ResourceLoader.exists(SCENE):
		_check(false, "", "NOT BUILT YET: %s does not exist (builder script %s %s)"
			% [SCENE, BUILDER, "is present" if ResourceLoader.exists(BUILDER) else "is also missing"])
		_lines.append("[probe] note  the contract this probe holds the builder to:")
		_lines.append("[probe] note    exports  %s" % ", ".join(WANT_EXPORTS))
		_lines.append("[probe] note    methods  %s" % ", ".join(WANT_METHODS))
		_lines.append("[probe] note    nodes    Chunk<N>, each with StaticBody3D + ConcavePolygonShape3D")
		_finish()
		return
	var packed: PackedScene = load(SCENE) as PackedScene
	if packed == null:
		_check(false, "", "%s exists but did not load as a PackedScene" % SCENE)
		_finish()
		return
	var n: Node3D = packed.instantiate() as Node3D
	if n == null:
		_check(false, "", "%s instantiated to something that is not a Node3D" % SCENE)
		_finish()
		return

	# the contract, name by name, BEFORE anything is built — a missing method
	# found after a two-minute march is two minutes spent to learn a fact that was
	# available at once
	var have: Dictionary = {}
	for pd in n.get_property_list():
		have[str(pd["name"])] = true
	var missing_x: Array[String] = []
	for e in WANT_EXPORTS:
		if not have.has(e):
			missing_x.append(e)
	var missing_m: Array[String] = []
	for m in WANT_METHODS:
		if not n.has_method(m):
			missing_m.append(m)
	_check(missing_x.is_empty(), "all %d contracted export(s) present: %s"
		% [WANT_EXPORTS.size(), ", ".join(WANT_EXPORTS)],
		"the scene root is missing export(s): %s" % ", ".join(missing_x))
	_check(missing_m.is_empty(), "both contracted method(s) present: %s" % ", ".join(WANT_METHODS),
		"the scene root is missing method(s): %s" % ", ".join(missing_m))
	if not missing_m.is_empty():
		# every remaining question is phrased in terms of cavity_points and
		# graph_edges, so there is nothing honest left to measure
		n.queue_free()
		_finish()
		return

	if have.has("seed"):
		n.set("seed", 3)
	root.add_child(n)
	await process_frame
	await physics_frame
	await physics_frame
	if have.has("wall"):
		_wall = maxf(0.05, float(n.get("wall")))
	var conf: Array[String] = []
	for e in WANT_EXPORTS:
		if have.has(e):
			conf.append("%s=%s" % [e, str(n.get(e))])
	_lines.append("[probe] built with %s" % ", ".join(conf))

	# ── 1. IT IS ARCHITECTURE, NOT A SCULPTURE ───────────────────────────────
	var chunks: Array[MeshInstance3D] = []
	var meshes: Array[MeshInstance3D] = _meshes(n)
	for m in meshes:
		if String(m.name).begins_with("Chunk"):
			chunks.append(m)
	var tris: int = 0
	var box := AABB()
	var first: bool = true
	for m in meshes:
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var a: Array = m.mesh.surface_get_arrays(s)
			if not a.is_empty():
				tris += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var wb: AABB = m.global_transform * m.mesh.get_aabb()
		box = wb if first else box.merge(wb)
		first = false
	# A BODY 20 m ACROSS CANNOT BE ONE CHUNK AT ANY SANE CHUNK SIZE, and chunking
	# is the entire affordability claim behind marching a building at body
	# resolution — one monolithic march over this span would come back coarsened
	# up to 9.3x by dream_iso's own cell budget. So the chunk count is not
	# cosmetic bookkeeping; it is the evidence the claim was used.
	_check(chunks.size() >= 4, "%d chunk mesh(es), %d mesh(es) in all, %d triangles, %.1f x %.1f x %.1f m"
		% [chunks.size(), meshes.size(), tris, box.size.x, box.size.y, box.size.z],
		"only %d node(s) named Chunk<N> out of %d mesh(es) — either the body was marched as one grid or the naming half of the contract is unmet"
			% [chunks.size(), meshes.size()])
	_check(tris > 10000, "%d triangles across the whole body" % tris,
		"%d triangles is a sculpture's worth of surface, not a building's" % tris)
	_check(box.size.length() > 20.0, "%.1f m across the merged diagonal" % box.size.length(),
		"this is a sculpture, not a structure — %.1f m diagonal" % box.size.length())

	# EVERY chunk, not "some collision exists". A single chunk without a collider
	# is a room you fall out of, and it is invisible in every render.
	var naked: Array[String] = []
	var tri_shapes: int = 0
	for m in chunks:
		var got: bool = false
		for cs in _shapes(m):
			if cs.shape is ConcavePolygonShape3D and cs.get_parent() is StaticBody3D:
				got = true
				tri_shapes += 1
		if not got:
			naked.append(String(m.name))
	_check(naked.is_empty() and tri_shapes >= chunks.size(),
		"all %d chunk(s) carry a StaticBody3D with a trimesh collider (%d shape(s))" % [chunks.size(), tri_shapes],
		"%d chunk(s) have no StaticBody3D+ConcavePolygonShape3D and the player falls through them: %s"
			% [naked.size(), ", ".join(naked)])
	# A trimesh with backface_collision off is only solid from the side its faces
	# point at. Standing INSIDE a hollow body that is the inner skin's front, so
	# this is normally correct and invisible — but when a chamber reports no floor
	# underfoot, the winding is the first suspect and the report should already
	# hold the number rather than sending the next run to find it.
	var backface_on: int = 0
	for cs2 in _shapes(n):
		if cs2.shape is ConcavePolygonShape3D and (cs2.shape as ConcavePolygonShape3D).backface_collision:
			backface_on += 1
	_lines.append("[probe] note  %d of %d trimesh shape(s) have backface_collision on (0 is normal; it matters only if a chamber reports no floor)"
		% [backface_on, tri_shapes])

	# ── 2. YOU CAN STAND IN EVERY CHAMBER ────────────────────────────────────
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h

	# THE RETURN OF A CONTRACTED METHOD IS STILL UNTRUSTED. A method that answers
	# with null or with an int satisfies has_method() and then takes the probe
	# down inside a for loop, which reads as "the probe is broken" rather than as
	# "the builder returned the wrong type".
	var raw_v: Variant = n.call("cavity_points")
	var raw: Array = (raw_v as Array) if raw_v is Array else []
	var cavity: Array[Vector3] = []
	for p_v in raw:
		if p_v is Vector3:
			cavity.append(n.global_transform * (p_v as Vector3))
	_check(cavity.size() >= 3, "%d cavity point(s) declared" % cavity.size(),
		"cavity_points() returned %d usable Vector3 out of %d entry/entries (%s) — there is no set of chambers to test"
			% [cavity.size(), raw.size(), type_string(typeof(raw_v))])
	if cavity.size() < 2:
		n.queue_free()
		_finish()
		return

	var stood: Array[bool] = []
	var floors: Array[Vector3] = []
	var free_r: Array[float] = []          # the inscribed radius of each chamber
	var no_floor: Array[String] = []
	var stuck: Array[String] = []
	var head_min: float = 1.0e9
	var head_at: int = -1
	for i in range(cavity.size()):
		var c: Vector3 = cavity[i]
		free_r.append(_inscribed(space, c, false))
		# FALL FROM THE CENTRE, NOT FROM ABOVE IT. Inside a hollow body a ray that
		# starts above the chamber starts outside the cavity, and the first thing
		# it meets is the ceiling — so the "floor" would be the roof and every
		# number after it a fiction.
		var hit: Dictionary = _fall(space, c, DROP_M)
		if hit.is_empty():
			no_floor.append("chamber %d at %s" % [i, _pt(c)])
			stood.append(false)
			floors.append(Vector3.INF)
			continue
		var fp: Vector3 = hit["position"]
		floors.append(fp)
		var names: Array[String] = []
		var ok: bool = _fits(space, cap, fp + Vector3(0.0, _cap_h * 0.5 + 0.06, 0.0), names)
		stood.append(ok)
		if not ok:
			stuck.append("chamber %d at %s in %s" % [i, _pt(c), ", ".join(names)])
		var uh: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			fp + Vector3(0.0, 0.05, 0.0), fp + Vector3(0.0, 12.0, 0.0)))
		var head: float = (float(uh["position"].y) - fp.y) if not uh.is_empty() else 12.0
		if head < head_min:
			head_min = head
			head_at = i
	var stood_n: int = 0
	for b in stood:
		if b:
			stood_n += 1
	_check(no_floor.is_empty(), "every chamber has a floor under it",
		"%d chamber(s) have no floor within %.0f m — the body falls out of the building: %s"
			% [no_floor.size(), DROP_M, "; ".join(no_floor)])
	_check(stood_n == cavity.size(),
		"the player's own capsule (r %.2f, h %.2f) stands in all %d chamber(s)" % [_cap_r, _cap_h, cavity.size()],
		"the capsule does not fit in %d of %d chamber(s): %s"
			% [cavity.size() - stood_n, cavity.size(), "; ".join(stuck) if not stuck.is_empty() else "no floor to try"])
	# NO MEASUREMENT IS NOT A GOOD MEASUREMENT. head_min starts at 1e9, so a run
	# where no chamber had a floor would otherwise print a billion metres of
	# headroom underneath the failure that caused it — a reassuring number in the
	# middle of a broken report is exactly the silence this project fears.
	if head_at < 0:
		_lines.append("[probe] note  headroom unmeasured: no chamber had a floor to stand on")
	else:
		_check(head_min >= 2.0, "tightest chamber headroom %.2f m (chamber %d), want >= 2.00" % [head_min, head_at],
			"you cannot stand up in chamber %d — %.2f m of headroom" % [head_at, head_min])

	# ── 3. EVERY GRAPH EDGE IS ACTUALLY PASSABLE ─────────────────────────────
	#
	# THIS IS THE ONE THAT MAKES IT A RHIZOME AND NOT A DIAGRAM. graph_edges is
	# what the builder INTENDED to connect; the field is what actually fused. Two
	# limbs whose smooth-union came 3 cm short leave a throat of 0.19 m in a
	# building that photographs perfectly, and the only instrument that can tell
	# the difference is a body walking the line.
	#
	# THE STRAIGHT CHORD IS THE WRONG LINE, AND IT COST THIS PROBE A RUN. Walking
	# the plain segment between two bulb centres, the first version of this section
	# reported 10 of 11 passages impassable and 8 of 9 chambers cut off — a
	# catastrophic-looking verdict, every number of it real, and every number of it
	# a fact about the PROBE LINE rather than about the building. A passage in this
	# body is bowed sideways and its axis is seated on a terraced floor, so the
	# chord between two centres leaves the cavity within a metre or two of the
	# mouth and spends the middle of its walk inside the wall. It duly measured a
	# throat of 0.01 m. That is the exact shape of the failure this project already
	# recorded about INERT verdicts: five of seven were facts about where the
	# camera stood, not about the artifact.
	#
	# So the body FOLLOWS the passage instead of assuming it is straight. At each
	# station the capsule may drift in the plane perpendicular to the chord, one
	# short step at a time, bounded so the walk stays a walk down THIS edge rather
	# than a search of the whole cavity. A drifting walk is what a person does; a
	# chord is what a diagram does, and the whole point of this artifact is that
	# those are different.
	#
	# The chord is still walked, cheaply, and reported as a NOTE with the bow that
	# the corridor needed. That divergence is worth more than either number alone:
	# it says how far from a wiring diagram the building actually is.
	#
	# Three measurements per edge, deliberately kept apart:
	#   FIT   the capsule at every station of the drifting walk. This drives
	#         connectivity in step 4 — "can a body get through here at all".
	#   WIDTH the horizontal free radius AND the floor-to-ceiling span at each
	#         station. Both, because the first version reported one passage as
	#         "narrowest 1.05 m" and BLOCKED in the same line: the tube was wide
	#         and short, and a horizontal-only width could not say so.
	#   FLOOR the rise between adjacent floors. A tube that leaves a chamber above
	#         its floor hands you a ledge that fits a capsule perfectly and cannot
	#         be climbed by an engine with no step height.
	var edges_v: Variant = n.call("graph_edges")
	var edges_raw: Array = (edges_v as Array) if edges_v is Array else []
	if not (edges_v is Array):
		_check(false, "", "graph_edges() returned %s, not an Array of index pairs" % type_string(typeof(edges_v)))
	var passable: Array = []               # [i, j] pairs the body actually got through
	var edge_fail: Array[String] = []
	var lip_fail: Array[String] = []
	var floorless: Array[String] = []
	var bad_index: Array[String] = []
	var narrow_worst: float = 1.0e9
	var narrow_where: String = "nothing"
	var tested: int = 0
	var chord_only: int = 0
	for e_v in edges_raw:
		var ei: int = -1
		var ej: int = -1
		if e_v is Array and (e_v as Array).size() >= 2:
			ei = int((e_v as Array)[0])
			ej = int((e_v as Array)[1])
		elif e_v is Vector2i:
			ei = (e_v as Vector2i).x
			ej = (e_v as Vector2i).y
		if ei < 0 or ej < 0 or ei >= cavity.size() or ej >= cavity.size() or ei == ej:
			bad_index.append(str(e_v))
			continue
		tested += 1
		var a: Vector3 = cavity[ei]
		var b: Vector3 = cavity[ej]
		var span: float = a.distance_to(b)
		var steps: int = clampi(int(span / STEP_M), 4, MAX_STEPS)
		# the plane the body may drift in: horizontal-across and straight up
		var fwd: Vector3 = (b - a).normalized()
		var u_ax: Vector3 = Vector3.UP.cross(fwd)
		if u_ax.length_squared() < 0.001:
			u_ax = Vector3.RIGHT
		u_ax = u_ax.normalized()
		var v_ax: Vector3 = Vector3.UP
		# HOW FAR THE WALK MAY WANDER. Enough that a bowed passage is followed;
		# little enough that the walk cannot leave this edge and find its way to
		# the far chamber down somebody else's corridor, which would turn the edge
		# test into a reachability test and quietly answer a different question.
		var lim: float = 0.22 * span + 1.20
		var off := Vector2.ZERO
		var fits_all: bool = true
		var blocked_at: String = ""
		var chord_blocked: bool = false
		var max_bow: float = 0.0
		var min_r: float = 1.0e9
		var min_at: Vector3 = a
		var min_v: float = 1.0e9
		var min_v_at: Vector3 = a
		var prev_f: Vector3 = Vector3.INF
		var gaps: int = 0
		var worst_lip: float = -1.0
		var lip_at: Vector3 = a
		for s in range(steps + 1):
			var t: float = float(s) / float(steps)
			var line_p: Vector3 = a.lerp(b, t)
			# the contracted chord, walked purely so the note can say what it saw
			var n_chord: Array[String] = []
			if not _fits(space, cap, line_p, n_chord):
				chord_blocked = true
			# THE FIT, following the passage
			var seek: Dictionary = _seek(space, cap, line_p, u_ax, v_ax, off, lim)
			if bool(seek["ok"]):
				off = seek["off"]
				max_bow = maxf(max_bow, off.length())
			elif fits_all:
				var p_fail: Vector3 = line_p + u_ax * off.x + v_ax * off.y
				# `seek["who"] as Array[String]` parses and then fails at the call —
				# GDScript builds a typed array by declaration, never by cast.
				var who_l: Array = seek["who"]
				blocked_at = "%s (%.2f along, in %s)" % [_pt(p_fail), span * t, ", ".join(who_l)]
				fits_all = false
			var p: Vector3 = line_p + u_ax * off.x + v_ax * off.y
			# THE WIDTH, horizontally. An inscribed radius over the whole sphere
			# would report the ceiling as the narrowest part of every passage,
			# which conflates headroom with width and buries the number.
			var r: float = _inscribed(space, p, true)
			if r >= 0.0 and r < min_r:
				min_r = r
				min_at = p
			# AND THE HEIGHT, separately. Without this the report can say
			# "narrowest 1.05 m" and "BLOCKED" on one line and leave the reader to
			# guess that the tube was wide and short — which is what it did.
			var vs: float = _headspan(space, p)
			if vs >= 0.0 and vs < min_v:
				min_v = vs
				min_v_at = p
			# THE FLOOR
			var h3: Dictionary = _fall(space, p, DROP_M)
			if h3.is_empty():
				gaps += 1
				prev_f = Vector3.INF
				continue
			var fp3: Vector3 = h3["position"]
			if prev_f != Vector3.INF:
				var rise: float = fp3.y - prev_f.y
				var run: float = Vector2(fp3.x - prev_f.x, fp3.z - prev_f.z).length()
				if rise > 0.0:
					var deg: float = rad_to_deg(atan2(rise, maxf(run, 0.001)))
					if deg > worst_lip:
						worst_lip = deg
						lip_at = fp3
			prev_f = fp3
		if min_r < narrow_worst:
			narrow_worst = min_r
			narrow_where = "edge [%d,%d] at %s" % [ei, ej, _pt(min_at)]
		# "CLEARANCE", NOT "WIDTH". This is the free radius at the point the body
		# actually stands, and the walk hugs the nearest fitting offset rather than
		# the passage's axis — so it is smaller than the passage's own radius and
		# must not be read as one. It is the number walkability cares about: how
		# much room the body has where it goes, not how big the tube is.
		_lines.append("[probe] edge  [%2d,%2d] %5.2f m  %s  clearance %s at %s  floor-to-ceiling %s at %s  bow %.2f m%s%s"
			% [ei, ej, span, "PASSABLE" if fits_all else "BLOCKED", _m(min_r), _pt(min_at),
				_m(min_v), _pt(min_v_at), max_bow,
				"" if worst_lip < 0.0 else "  steepest rise %.0f deg" % worst_lip,
				"  (the straight chord alone is blocked)" if chord_blocked else ""])
		if chord_blocked:
			chord_only += 1
		if fits_all:
			passable.append([ei, ej])
		else:
			edge_fail.append("[%d,%d] blocked at %s; width there %s, floor-to-ceiling %s (the body is %.2f wide and %.2f tall)"
				% [ei, ej, blocked_at, _m(min_r), _m(min_v), _cap_r * 2.0, _cap_h])
		if worst_lip > LIP_DEG:
			lip_fail.append("[%d,%d] a %.0f deg rise at %s" % [ei, ej, worst_lip, _pt(lip_at)])
		if gaps > steps / 10:
			floorless.append("[%d,%d] %d of %d station(s) with no floor within %.0f m"
				% [ei, ej, gaps, steps + 1, DROP_M])
	_check(bad_index.is_empty(), "every graph edge indexes a real chamber",
		"graph_edges returned %d entry/entries that do not index cavity_points: %s"
			% [bad_index.size(), ", ".join(bad_index)])
	_check(tested > 0, "%d edge(s) walked with the player's capsule" % tested,
		"graph_edges declared nothing testable — there is no rhizome to walk")
	# THE NUMBER THAT SAYS THIS IS NOT A WIRING DIAGRAM. A passage the body can
	# only follow by leaving the straight line is a passage that BENDS, and how
	# many of them do is the difference between a rhizome and a graph drawn in
	# tubes. It is reported, never asserted: a straight passage is not a fault.
	_lines.append("[probe] note  %d of %d passage(s) are impassable along the naive straight chord and passable only by following the bend"
		% [chord_only, tested])
	if tested > 0:
		_check(edge_fail.is_empty(),
			"all %d declared passage(s) admit the capsule; tightest clearance beside the walking body %s, %s (the body's own half-width is %.2f)"
				% [tested, _m(narrow_worst), narrow_where, _cap_r],
			"%d of %d declared passage(s) a body cannot get through: %s"
				% [edge_fail.size(), tested, "; ".join(edge_fail)])
		_check(lip_fail.is_empty(), "no passage hands the body a rise steeper than %.0f deg" % LIP_DEG,
			"%d passage(s) have an unclimbable lip (no step height in this engine): %s"
				% [lip_fail.size(), "; ".join(lip_fail)])
		_check(floorless.is_empty(), "every passage has a floor under it the whole way",
			"%d passage(s) run over a void: %s" % [floorless.size(), "; ".join(floorless)])

	# ── 4. THE WHOLE CAVITY IS ONE SPACE ─────────────────────────────────────
	#
	# Flooded over the edges the CAPSULE got through, never over the edges the
	# builder declared. If those two graphs agree the distinction costs nothing;
	# when they disagree it is the entire finding, and a flood over the declared
	# graph would report a connected building either way.
	var adj: Dictionary = {}
	for pe_v in passable:
		var pe: Array = pe_v
		var u: int = int(pe[0])
		var w: int = int(pe[1])
		if not adj.has(u):
			adj[u] = []
		if not adj.has(w):
			adj[w] = []
		(adj[u] as Array).append(w)
		(adj[w] as Array).append(u)
	var seen: Dictionary = {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var cur: int = queue.pop_back()
		for nb_v in (adj.get(cur, []) as Array):
			var nb: int = int(nb_v)
			if not seen.has(nb):
				seen[nb] = true
				queue.append(nb)
	var cut: Array[String] = []
	for i2 in range(cavity.size()):
		if not seen.has(i2):
			cut.append("chamber %d at %s" % [i2, _pt(cavity[i2])])
	_check(cut.is_empty(),
		"all %d chamber(s) are reachable from chamber 0 over the passages a body actually fits through"
			% cavity.size(),
		"%d of %d chamber(s) cannot be reached from chamber 0: %s%s"
			% [cut.size(), cavity.size(), "; ".join(cut),
				"" if edge_fail.is_empty() else " — the passage(s) that failed: " + "; ".join(edge_fail)])

	# ── 5. YOU ARE INSIDE ────────────────────────────────────────────────────
	_skins(chunks if not chunks.is_empty() else meshes, cavity, free_r)

	n.queue_free()
	_finish()


## THE INSTRUMENTS, BEFORE THE VERDICT.
##
## "A dead reading is the instrument" is a standing ruling in this project, and
## this probe has five instruments that could each fail SILENTLY into a pass:
## _fits could never report an overlap (every passage passable, every chamber
## standable), _fall could return the outer skin (every floor found, all of them
## the roof), _inscribed could return its sentinel (every throat unmeasured),
## _facing could sample nothing (a percentage of nothing).
##
## So before the building is judged, the same five instruments are pointed at a
## rig marched RIGHT HERE out of dream_iso, whose answers are known from the
## arithmetic rather than from the run: three bulbs of radius 1.70 with wall 0.30,
## so every cavity is 1.40 in radius; one FAT passage of radius 1.50, cavity 1.20,
## which a 0.30 x 1.80 capsule fits; one THIN passage of radius 0.42, cavity 0.12,
## which it cannot. If the instruments cannot tell those two apart, nothing they
## say about the real body means anything.
##
## The rig is torn down before the subject is built. A stray collider left in the
## world would make the building's own numbers wrong in a way nothing would catch.
func _selftest() -> void:
	var R: float = 1.70
	var wall: float = 0.30
	var a := Vector3(0.0, 0.0, 0.0)
	var b := Vector3(6.0, 0.0, 0.0)
	var c := Vector3(0.0, 0.0, 6.0)
	# SIX METRES APART ON PURPOSE. At four the two bulbs' own smooth union would
	# open the thin passage for them and the rig would prove nothing: the midpoint
	# has to be far enough from both bulb surfaces that only the tube is deciding.
	var parts: Array = [
		Iso.sphere(a, R), Iso.sphere(b, R), Iso.sphere(c, R),
		Iso.capsule(a, b, 1.50),                      # cavity 1.20 — passable
		Iso.capsule(a, c, 0.42),                      # cavity 0.12 — sealed
	]
	var rig := Node3D.new()
	rig.name = "SelfTestRig"
	root.add_child(rig)
	# 0.15 m cells, deliberately coarse: this rig is a ruler, not a building, and
	# the marching itself is already gated by probe_iso_chunks.
	var built: Array = Iso.mesh_rhizome(parts, 0.15, 0.55, wall, 4.0, 0.30)
	var rig_tris: int = 0
	for i in range(built.size()):
		var m: ArrayMesh = (built[i] as Dictionary)["mesh"]
		rig_tris += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var mi := MeshInstance3D.new()
		mi.name = "Chunk%d" % i
		mi.mesh = m
		rig.add_child(mi)
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = m.create_trimesh_shape()
		sb.add_child(cs)
		mi.add_child(sb)
	await process_frame
	await physics_frame
	await physics_frame
	_check(built.size() >= 2 and rig_tris > 2000,
		"instrument rig: %d chunk(s), %d triangles marched from dream_iso" % [built.size(), rig_tris],
		"instrument: the self-test rig did not mesh (%d chunk(s), %d triangles) — nothing below is calibrated"
			% [built.size(), rig_tris])
	if built.size() < 2:
		rig.queue_free()
		return

	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h

	# _fall must find the CAVITY floor, which is R - wall below the centre — not
	# the outer skin, and not the far side of the world.
	var hit: Dictionary = _fall(space, a, DROP_M)
	var fy: float = float(hit["position"].y) if not hit.is_empty() else 1.0e9
	var want_y: float = a.y - (R - wall)
	_check(not hit.is_empty() and absf(fy - want_y) < 0.30,
		"instrument _fall: floor at y %.2f where the cavity's own is %.2f" % [fy, want_y],
		"instrument: _fall %s — it is not finding the inner skin, so every floor this probe reports is suspect"
			% ("found nothing under a chamber centre" if hit.is_empty()
				else "found y %.2f, not the cavity floor at %.2f" % [fy, want_y]))

	# _fits must SAY YES where there is room...
	var n1: Array[String] = []
	var open_ok: bool = false
	if not hit.is_empty():
		open_ok = _fits(space, cap, (hit["position"] as Vector3) + Vector3(0.0, _cap_h * 0.5 + 0.06, 0.0), n1)
	# ...and NO where there is not. THIS IS THE ONE THAT MATTERS: a shape query
	# that never reports an overlap makes every passage in the report passable and
	# every chamber standable, and the run comes back green and empty.
	var n2: Array[String] = []
	var sealed_ok: bool = not _fits(space, cap, a.lerp(c, 0.5), n2)
	_check(open_ok and sealed_ok,
		"instrument _fits: yes in the 1.20 m cavity, no in the 0.12 m one",
		"instrument: _fits answered %s in the open chamber and %s in the sealed 0.12 m throat — the query does not discriminate and no passage verdict below is worth reading"
			% ["yes" if open_ok else "NO", "no" if sealed_ok else "YES"])

	# _inscribed must measure the cavity it is standing in.
	var ins: float = _inscribed(space, a, false)
	_check(absf(ins - (R - wall)) < 0.30,
		"instrument _inscribed: %.2f m in a cavity of %.2f m" % [ins, R - wall],
		"instrument: _inscribed read %s where the cavity is %.2f m — every width in this report is off by that much"
			% [_m(ins), R - wall])
	var thin: float = _inscribed(space, a.lerp(c, 0.5), true)
	_check(thin < 0.30, "instrument _inscribed: the sealed throat measures %s, under the capsule's 0.30 m" % _m(thin),
		"instrument: the sealed 0.12 m throat measured %s — a narrow passage will not be reported as narrow" % _m(thin))

	# _facing must see BOTH skins on a body that is known to have two.
	var rig_meshes: Array[MeshInstance3D] = _meshes(rig)
	# `[a, b, c] as Array[Vector3]` is not a conversion GDScript performs — a
	# typed array is built by DECLARATION, and the cast form parses and then fails
	# at the call.
	var rig_cav: Array[Vector3] = [a, b, c]
	var rig_free: Array[float] = [R - wall, R - wall, R - wall]
	# _facing reads _wall for the inner-band width and it is still the 0.30 default
	# here, which is the rig's own wall — deliberate, not a coincidence.
	var f: Dictionary = _facing(rig_meshes, rig_cav, rig_free)
	var ff: float = float(f["inward"]) / float(maxi(int(f["faces"]), 1))
	var bf: float = float(f["band_inward"]) / float(maxi(int(f["band_faces"]), 1))
	_check(int(f["faces"]) > 500 and ff > 0.20 and ff < 0.80 and int(f["band_faces"]) > 200 and bf > 0.85,
		"instrument _facing: %.1f%% of %d sampled face(s) point at a chamber, %.1f%% of the %d in a chamber's own band"
			% [ff * 100.0, int(f["faces"]), bf * 100.0, int(f["band_faces"])],
		"instrument: _facing read %.1f%% global over %d face(s) and %.1f%% in-band over %d on a rig KNOWN to be a two-skinned shell — the facing test is miscalibrated, not the building"
			% [ff * 100.0, int(f["faces"]), bf * 100.0, int(f["band_faces"])])

	# TEAR IT DOWN. A collider left standing here would be inside the building's
	# own measurements, and nothing downstream would notice.
	rig.queue_free()
	await process_frame
	await physics_frame


## Which way does the surface face, and what is the right number to expect.
##
## THE SHELL HAS TWO SKINS AND THAT CHANGES THE QUESTION. The tunnel probe could
## demand 92% of lumen faces pointing at the axis because a lofted lumen IS the
## inner surface. abs(f) - wall is not: it marches the band from f = -wall to
## f = +wall, so it yields an inner skin AND an outer skin in one mesh, and the
## outer one correctly faces away from every cavity there is.
##
## So what fraction should face inward? Not half — the two skins are offset
## surfaces of different size. Round a bulb of free radius R the inner skin is at
## R and the outer at R + 2*wall, and area goes as the square: for R = 2.2 and
## wall = 0.30 that is 4.84 against 7.84, i.e. 38%. Round a tube it goes as the
## first power, 2.2 against 2.8, i.e. 44%. Add the noise from "nearest cavity
## centre" being the wrong centre near a wall between two bulbs and the honest
## expectation is somewhere in the thirties or forties.
##
## THE WINDOW IS 20% TO 80% AND IT IS NOT A WEAK ASSERTION — it is aimed at the
## two failures that actually happen, both of which are catastrophic and neither
## of which is subtle:
##   near 0    every face points away: the mesh is inside out (the winding bug
##             dream_iso already shipped once, invisible in a render that draws
##             back faces), or the body is SOLID and there is no cavity at all.
##   near 1    only an inner skin exists, or the mesh is inside out the other way.
## A tighter threshold would be a guess about the ratio of two offset areas on a
## body whose shape this probe does not know.
##
## THE SHARP CLAIM IS MADE SEPARATELY AND IT IS THE ONE THAT MATTERS: the two
## skins are 2*wall apart, so a shell of radius R + 0.85*wall round a cavity
## centre contains the INNER skin and nothing else. Every triangle in that band
## must face the chamber, because that is precisely what "standing in a hollow
## body you are looking at the inner skin" means. There the threshold is 85%.
func _skins(from: Array, cavity: Array[Vector3], free_r: Array[float]) -> void:
	var f: Dictionary = _facing(from, cavity, free_r)
	var faces: int = int(f["faces"])
	var inward: int = int(f["inward"])
	var band_faces: int = int(f["band_faces"])
	var band_inward: int = int(f["band_inward"])
	# THE DENOMINATOR BEFORE THE RATIO. probe_iso_chunks reported a perfect score
	# from a comparison of zero vertices; a percentage of nothing reads exactly
	# like a pass.
	_check(faces > 500, "%d triangle(s) sampled from %d mesh(es) (stride %d of %d)"
		% [faces, from.size(), int(f["stride"]), int(f["total"])],
		"only %d triangle(s) could be sampled — the facing test is not testing" % faces)
	if faces <= 500:
		return
	var frac: float = float(inward) / float(faces)
	_check(frac > 0.20 and frac < 0.80,
		"%.1f%% of sampled faces point at their nearest chamber — both skins are present (a shell of wall %.2f m predicts the thirties to forties)"
			% [frac * 100.0, _wall],
		"%.1f%% of faces point at their nearest chamber: %s"
			% [frac * 100.0, "the mesh has no inner skin, or it is inside out and you are looking at the backfaces of an outside"
				if frac <= 0.20 else "there is no outer skin — this is a surface, not a wall with two sides"])
	_check(band_faces > 200, "%d triangle(s) lie in the inner band of a chamber" % band_faces,
		"only %d triangle(s) fell within a chamber's inner band — the sharp facing test has no denominator" % band_faces)
	if band_faces > 200:
		var bf: float = float(band_inward) / float(band_faces)
		_check(bf > 0.85,
			"%.1f%% of the surface within a chamber's own inner band faces the chamber — you are inside the body"
				% (bf * 100.0),
			"only %.1f%% of the surface closest to a chamber faces it: standing in that chamber you are looking at the back of a wall"
				% (bf * 100.0))


## The facing arithmetic on its own, so the self-test rig and the real body are
## measured by ONE implementation. Split out after the tunnel probe's own lesson
## that a gate must compare across implementations — here the requirement is the
## opposite and just as strict: the calibration and the verdict must not be able
## to drift apart.
func _facing(from: Array, cavity: Array[Vector3], free_r: Array[float]) -> Dictionary:
	var faces: int = 0
	var inward: int = 0
	var band_faces: int = 0
	var band_inward: int = 0
	# a bounded, deterministic sample — a 20 m body is hundreds of thousands of
	# triangles and the nearest-centre search is per triangle
	var total: int = 0
	for m_v in from:
		var m: MeshInstance3D = m_v
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var a: Array = m.mesh.surface_get_arrays(s)
			if not a.is_empty():
				total += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	# 20,000 AND NOT 4,000. The global fraction was comfortable at 4,000, but the
	# in-band fraction — the sharp claim, the one that says you are inside — draws
	# from the few percent of the surface that lies close to a chamber, and on a
	# two-million-triangle body that left it 130 samples and no denominator. The
	# cost is the nearest-centre search, not the traversal, which walks every
	# triangle either way.
	var stride: int = maxi(1, int(float(total) / 20000.0))
	for m_v2 in from:
		var mi: MeshInstance3D = m_v2
		if mi.mesh == null:
			continue
		var xf: Transform3D = mi.global_transform
		for s2 in range(mi.mesh.get_surface_count()):
			var arr: Array = mi.mesh.surface_get_arrays(s2)
			if arr.is_empty():
				continue
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var t: int = 0
			for vi in range(0, vs.size() - 2, 3):
				t += 1
				if t % stride != 0:
					continue
				var p0: Vector3 = xf * vs[vi]
				var p1: Vector3 = xf * vs[vi + 1]
				var p2: Vector3 = xf * vs[vi + 2]
				var mid: Vector3 = (p0 + p1 + p2) / 3.0
				var nrm: Vector3
				if ns.size() > vi:
					nrm = (xf.basis * ns[vi]).normalized()
				else:
					# GODOT WINDS FRONT FACES CLOCKWISE and generate_normals takes
					# Plane(a,b,c).normal = (a-c) x (a-b). Written the textbook way
					# this fallback would report a perfectly consistent, perfectly
					# inverted mesh.
					nrm = (p0 - p2).cross(p0 - p1).normalized()
				var best: int = -1
				var bd: float = 1.0e9
				for k in range(cavity.size()):
					var d: float = cavity[k].distance_squared_to(mid)
					if d < bd:
						bd = d
						best = k
				if best < 0:
					continue
				var toward: Vector3 = (cavity[best] - mid).normalized()
				var faces_in: bool = nrm.dot(toward) > 0.0
				faces += 1
				if faces_in:
					inward += 1
				var r: float = free_r[best] if best < free_r.size() else 0.0
				if r > 0.0 and sqrt(bd) <= r + _wall * 0.85:
					band_faces += 1
					if faces_in:
						band_inward += 1
	return {"faces": faces, "inward": inward, "band_faces": band_faces,
		"band_inward": band_inward, "stride": stride, "total": total}


# ── the instruments ────────────────────────────────────────────────────────

## FALL, do not raycast once.
##
## The first thing under a downward ray can be the top of a wall bulge — a
## marched body is full of them — and calling its flank a floor puts the capsule
## on a ledge inside the surrounding geometry and calls a 72-degree face a ramp.
## This keeps going down past anything the engine would not stand on, which is
## what landing actually is.
func _fall(space: PhysicsDirectSpaceState3D, from: Vector3, drop: float) -> Dictionary:
	var to: Vector3 = from - Vector3(0.0, drop, 0.0)
	var cursor: Vector3 = from
	for _hop in range(10):
		if cursor.y <= to.y:
			return {}
		var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(cursor, to))
		if h.is_empty():
			return {}
		var slope: float = rad_to_deg(acos(clampf((h["normal"] as Vector3).dot(Vector3.UP), -1.0, 1.0)))
		if slope <= 45.0:
			return h
		cursor = (h["position"] as Vector3) + Vector3(0.0, -0.05, 0.0)
	return {}


## Does the body fit with its centre here? MARGIN ZERO, always.
##
## PhysicsShapeQueryParameters3D defaults to a 0.04 m margin, which the tunnel
## probe learned the expensive way: a capsule resting 2 cm above a good floor
## overlapped it and 14 of 26 stations reported "stuck" on a building that was
## fine underfoot. A gate that fires on its own tolerance is worse than no gate.
func _fits(space: PhysicsDirectSpaceState3D, cap: CapsuleShape3D, centre: Vector3,
		out_names: Array[String]) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), centre)
	q.margin = 0.0
	var blocked: Array = space.intersect_shape(q, 8)
	if blocked.is_empty():
		return true
	# NAME THE OFFENDER. "blocked at (3.2, 1.1, 8.4)" sends the next run looking;
	# "blocked in Chunk7" opens one node.
	for b in blocked:
		var bn: Node = b.get("collider")
		if bn == null:
			continue
		var who: String = String(bn.name)
		var par: Node = bn.get_parent()
		if par != null:
			who = String(par.name)
			var gp: Node = par.get_parent()
			if gp != null and String(gp.name).begins_with("Chunk"):
				who = String(gp.name)
		if not out_names.has(who):
			out_names.append(who)
	return false


## FOLLOW THE PASSAGE. Where can the body stand at this station?
##
## Returns {ok, off, who}: the offset in the (u, v) plane at which the capsule
## fits, searched outward from where the body was standing at the previous
## station, or ok = false and the colliders that stopped it.
##
## THE SEARCH IS DELIBERATELY SHORT-SIGHTED — one ring of 0.25 m and one of
## 0.50 m round the previous offset, nothing more. That is what makes it a WALK:
## the body can follow a bend, and it cannot teleport across a wall into the
## passage next door. A wider search would answer "is the far chamber reachable
## somehow", which is step 4's question and not this one, and it would answer it
## in a way that hides exactly the throat this section exists to find.
##
## The nearest fitting offset wins, so a passage that is genuinely straight is
## walked straight and its reported bow is 0 — which is the check that the drift
## is not just wandering: on this body two of ten edges report exactly 0.00 m.
##
## IT CANNOT TUNNEL THROUGH A WALL, and that is the property that makes the drift
## a correction rather than a loophole. Every intermediate offset must ITSELF fit
## the capsule, so the walk only ever moves through connected open cavity. A body
## 0.60 m wide cannot occupy a wall 2 x wall = 0.60 m thick, so no fitting station
## exists inside one. The one gap left is a FIN thinner than about 0.10 m standing
## between two fitting stations 0.50 m apart — this probe would step over it. On a
## marched shell of wall 0.30 there is no such fin; on a thinner-walled body there
## could be, and then this bound is the thing to revisit.
func _seek(space: PhysicsDirectSpaceState3D, cap: CapsuleShape3D, line_p: Vector3,
		u_ax: Vector3, v_ax: Vector3, from: Vector2, lim: float) -> Dictionary:
	var who: Array[String] = []
	var cands: Array[Vector2] = [from]
	for ring in [0.25, 0.50]:
		for k in range(8):
			var ang: float = TAU * float(k) / 8.0
			cands.append(from + Vector2(cos(ang), sin(ang)) * float(ring))
	var best := Vector2.ZERO
	var best_d: float = 1.0e9
	var found: bool = false
	for c in cands:
		if c.length() > lim:
			continue
		var names: Array[String] = []
		if not _fits(space, cap, line_p + u_ax * c.x + v_ax * c.y, names):
			for w in names:
				if not who.has(w):
					who.append(w)
			continue
		var d: float = (c - from).length()
		if d < best_d:
			best_d = d
			best = c
			found = true
	return {"ok": found, "off": best, "who": who}


## Floor to ceiling through this point — the other half of "how big is it here".
##
## A horizontal width alone let the first version of this probe print
## "narrowest 1.05 m" and "BLOCKED" on the same line, because the tube was wide
## and short and nothing was looking up. -1 when either ray escapes, which is not
## a height and must not be printed as one.
func _headspan(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var up: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3(0.0, 30.0, 0.0)))
	var dn: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p - Vector3(0.0, 30.0, 0.0)))
	if up.is_empty() or dn.is_empty():
		return -1.0
	return float(up["position"].y) - float(dn["position"].y)


## The largest sphere centred here that touches nothing — the honest width of a
## place. `horiz` restricts the directions to a band round the horizon, because
## over the whole sphere the ceiling is the nearest thing at every standing point
## and the number stops meaning "how wide is this passage".
func _inscribed(space: PhysicsDirectSpaceState3D, p: Vector3, horiz: bool) -> float:
	var best: float = 1.0e9
	for d_v in _dirs(32):
		var d: Vector3 = d_v
		if horiz and absf(d.y) > 0.5:
			continue
		var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + d * 40.0))
		if h.is_empty():
			# NO HIT IS NOT INFINITE ROOM. Inside a closed body every ray should
			# land, so a miss means either the body is open here or the trimesh is
			# one-sided in this direction. Either way it is not evidence of width,
			# so it contributes nothing rather than a reassuring 40 m.
			continue
		best = minf(best, p.distance_to(h["position"]))
	# -1 IS "NOBODY LOOKED", NOT "ZERO ROOM". Returning 0.0 for a point where every
	# ray escaped would print "narrowest 0.00 m" — which reads as a sealed throat,
	# the exact opposite of what a total miss means.
	if best > 1.0e8:
		return -1.0
	return best


## A deterministic spread of directions — the golden spiral, so the same run
## twice gives the same numbers and a regression is a regression.
func _dirs(count: int) -> Array:
	var out: Array = []
	var ga: float = PI * (3.0 - sqrt(5.0))
	for i in range(count):
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(count)
		var r: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = ga * float(i)
		out.append(Vector3(cos(th) * r, y, sin(th) * r))
	return out


## The player's real capsule, read rather than assumed. A probe that hardcodes
## the body it is testing against is testing its own opinion.
func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		_lines.append("[probe] note  %s not found — falling back to the documented 0.30 / 1.80" % PLAYER)
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m" % [_cap_r, _cap_h])
	p.free()


func _pt(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]


## A width, or the honest admission that there is not one. The two sentinels this
## probe carries — -1 from _inscribed for "every ray escaped" and 1e9 for "no
## station was measured" — must never be printed as metres, because "0.00 m" and
## "1000000000.00 m" both read as findings.
func _m(v: float) -> String:
	if v < 0.0:
		return "unmeasured (every ray escaped the body)"
	if v > 1.0e8:
		return "unmeasured (no station yielded a width)"
	return "%.2f m" % v


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func _shapes(n: Node) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if n is CollisionShape3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_shapes(c))
	return out


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	if line.is_empty():
		_lines.append("[probe] *** %s ***" % why)
	else:
		_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
