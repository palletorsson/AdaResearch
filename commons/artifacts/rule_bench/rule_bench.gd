extends Node3D
class_name RuleBench

## rule_bench — a RULE is a local law; the form is nobody's decision. Stand at three
## distances from the same law and the difference between two laws changes by twenty times.
##
## THE FAMILY. Five artifacts declare an axis called `rule` and they carry FOUR disjoint
## value lists, because each names the law at a different distance from the mechanism:
##
##   ca_bridge          30 · 90 · 110 · 250        the NUMBER. Wolfram's integer encoding of
##                                                 the lookup table itself. gd:207 — the whole
##                                                 update is `(rule >> ((a<<2)|(b<<1)|c)) & 1`.
##                                                 Maximally close to the mechanism, and it
##                                                 tells a reader nothing.
##   lifeform_walker    life · highlife · seeds ·  the NICKNAME. RULES = {"life": [[3],[2,3]],
##                      replicator · maze · coral  "coral": [[3],[4,5,6,7,8]], ...} (gd:72-79):
##                                                 birth/survival bands under the culture's
##                                                 name for the GLOBAL FORM they make. Named
##                                                 by what you end up looking at.
##   mold_network       reinforce · explore ·      the TENDENCY. RULE_BANDS (Flexible gd:111-116)
##   structure_growth   compact · strand           = "4-6/5-7" · "3-6/4-7" · "5-7/6-8" · "2-4/5-6",
##                                                 named for what the front DOES: "commits on
##                                                 little evidence", "dies wherever crowded".
##   pheromone_terrain  trail · sniff · avoid ·    the AGENT'S ACT. Each value changes one clause
##                      grid                       of _choose_next_position — which neighbours
##                                                 are candidates, or the SIGN of the comparison.
##                                                 Named from inside the walker.
##
## Four vocabularies, one question, and they are a LADDER OF DISTANCE from the code to the
## phenomenon: number → tendency → act → nickname. Where a family sits on that ladder says
## who the artifact was written for. And the family knows it cannot compare across the rungs
## — ca_bridge's registry says the Life values "would name a mechanism this object does not
## have", mold_network says "a different alphabet", pheromone_terrain says "the word carries;
## the numbers must not". They are right, and being right leaves the interesting thing
## unmeasured: HOW FAR APART ARE THE RUNGS?
##
## THIS BENCH TURNS THE LADDER INTO AN AXIS. One automaton — ca_bridge's own elementary CA,
## its update copied byte for byte including the periodic wrap — built as a wall, and drawn
## at three distances:
##
##   lookup     the mechanism as an object. Eight three-cell neighbourhoods, in the order
##              111 · 110 · 101 · 100 · 011 · 010 · 001 · 000, each over the cell it produces.
##              Read the eight output blocks in reading order and you have literally spelled
##              the rule number in base two. This is what "rule 30" IS.
##   front      the present tense. Generation 39 alone, standing where it stands in the wall,
##              with all its history gone. This is mold_network's `wake: none` ("the object is
##              only what is alive right now", Flexible gd:120) and lifeform_walker's 6x6 torso.
##   spacetime  the global form. All forty generations stacked, grown downward. The Sierpinski
##              gasket, the chaotic deck, the checkerboard — the thing that has a NICKNAME.
##
## THE ARGUMENT, and it is falsifiable. Take rules 90 and 218. They differ in exactly one bit
## of eight — neighbourhood 111, three live cells in a row. From a single seed rule 90 NEVER
## PRODUCES three live cells in a row (checked, all 40 generations), so that bit is never
## read, and 90 and 218 build THE SAME WALL, cell for cell. Now take 250 and 218: also one bit
## apart (neighbourhood 101), and that bit is read constantly — 15% of the wall differs. Equal
## distance in the mechanism, and the distance in the form is 0% against 15%. That is the
## whole claim about local laws and global forms, and it is two numbers you can check.
##
## Somebody can disagree, and the disagreement is the point: all the information is in the
## eight bits, so (the objection runs) the wall adds nothing and the three readings are three
## renderings of one fact. The 90/218 pair is where that objection is strongest — two
## different numbers, one wall — and it is exactly where it costs something to hold, because
## the reverse case sits next to it on the same shelf.
##
## Nothing animates, nothing is printed, nothing is random. Every generation is integer
## arithmetic on the seed row, so two builds of one value are the same mesh.

## WHICH LOCAL LAW. ca_bridge's four numbers, character for character and in its order, plus
## one. The values are NUMBERS because for an elementary CA the rules ARE their numbers —
## ca_bridge's registry refuses the Life-family words for that reason and its own @identity
## says `critical_parameter: rule (0-255)`.
##
##   30   class 3, chaotic. Left XOR (centre OR right). A broken deck.
##   90   class 2. Left XOR right — the Sierpinski gasket, nested self-similar gaps.
##   110  class 4, the universal one. Structure, and gliders crossing it.
##   250  class 1/2. Isolated cells die (010 -> 0), so from one seed it is a pure alternating
##        lattice that computes nothing — ca_bridge's control.
##   218  NOT ca_bridge's. 90 with neighbourhood 111 switched on: a different lookup table,
##        a different number, and — from this seed — the same wall as 90 to the byte. Built
##        for the experiment above, and for no other reason.
@export_enum("30", "90", "110", "250", "218") var rule: String = "30":
	set(v):
		var picked: String = _num_str(v).strip_edges().to_lower()
		if not RULES.has(picked):
			return                      ## an unreachable value keeps the current wall
		rule = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW FAR YOU STAND FROM IT. spacetime is the members' shipped behaviour — ca_bridge builds
## every generation and leaves them all standing — so it is the default and the one
## solve_framing measures.
@export_enum("spacetime", "front", "lookup") var reading: String = "spacetime":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One wall, or all five rules in a row. NOT PART OF EITHER AXIS — wave 13 learned that an
## all-rungs value declared inside an axis makes capture_config_sweep union the row's AABB
## with every single and photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const RULES: PackedStringArray = ["30", "90", "110", "250", "218"]
const READINGS: PackedStringArray = ["spacetime", "front", "lookup"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the automaton ──────────────────────────────────────────────────────────────────────
## ca_bridge's own geometry class: a fixed width, a periodic wrap, a single live cell in the
## middle of row 0 (`current_row[width / 2] = 1`, gd:158) and no randomness anywhere.
## 48 x 40 was chosen so the light cone reaches the edges at generation 24 and the last
## sixteen rows are the wrap folding the pattern into itself — which is ca_bridge's own
## behaviour at its shipped width 31, not an artefact introduced here.
const COLS: int = 48
const GENS: int = 40

# ── the wall, metres ───────────────────────────────────────────────────────────────────
const PITCH: float = 0.024        ## one cell of the lattice, both ways
const CELL: float = 0.020         ## the cube in it; the 4 mm gap is what makes the lattice read
const CELL_D: float = 0.018       ## how far a live cell stands proud of the backplate
const MARGIN: float = 0.020       ## backplate overhang around the field
const BACK_D: float = 0.020
const BASE_Y: float = 0.050       ## bottom of the backplate above the floor
const FIELD_TOP: float = BASE_Y + MARGIN + GENS * PITCH   ## 1.030
const FIELD_BOT: float = BASE_Y + MARGIN                  ## 0.070
const BACK_W: float = COLS * PITCH + MARGIN * 2.0         ## 1.192
const BACK_H: float = GENS * PITCH + MARGIN * 2.0         ## 1.000
const FRAME_T: float = 0.008      ## the field's rebate; CONSTANT in every variant
const FRAME_D: float = 0.010

## Every artifact has a front, and this one's front is where the sweep stands: the wall is
## turned to face capture_config_sweep's standpoint bearing (YAW 0.62) so the spacetime
## diagram is seen as a diagram rather than edge-on. Same argument postulate_bench makes.
const FRONT_YAW: float = 0.62
const LADDER_PITCH: float = 1.35

# ── the lookup table as an object ──────────────────────────────────────────────────────
## Four tiles across, two down, index 7 first: reading order spells the number in base two.
const TILE_X: PackedFloat32Array = [-0.432, -0.144, 0.144, 0.432]
const IN_Y: PackedFloat32Array = [0.996, 0.346]     ## the three-cell neighbourhood
const OUT_Y: PackedFloat32Array = [0.816, 0.166]    ## the cell it produces
const IN_CELL: float = 0.067
const IN_PITCH: float = 0.0787
const OUT_W: float = 0.224
const OUT_H: float = 0.192
const SOCK_D: float = 0.006       ## the empty socket: a table has rows whether or not they are true
const IN_LIVE: float = 0.055
const OUT_LIVE_W: float = 0.208
const OUT_LIVE_H: float = 0.176
const LIVE_D: float = 0.018

const BACK_COLOR: Color = Color(0.10, 0.10, 0.12)     ## lifeform_walker dead_color, gd:83
const FRAME_COLOR: Color = Color(0.17, 0.18, 0.21)
const LIVE_COLOR: Color = Color(0.20, 1.00, 0.30)     ## lifeform_walker alive_color, gd:82
const LIVE_EMISSION: Color = Color(0.10, 0.80, 0.20)  ## lifeform_walker emission_alive, gd:85
## The seed cell, the one thing all five rules share. Off-white so it is visibly not the law.
const SEED_COLOR: Color = Color(0.96, 0.94, 0.86)

var _built: Array[Node3D] = []
## Set while a whole config dictionary is landing, so three keys cost one rebuild rather
## than three. Each rebuild frees and respawns up to about 1,700 boxes.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("rule"):
		rule = _num_str(config_data["rule"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


## The rule axis's values LOOK LIKE NUMBERS, which is the tier_terrarium trap: cabinet_sweep
## numericises anything that parses, and Object.set() on a typed String property of the wrong
## type is refused in silence. capture_config_sweep now converts back through the property's
## own enum hint (gd:1387-1412), so the sweep is safe — but a map token, apply_grid_config or
## a float round-trip is not, and "30.0" is not "30". Normalise before comparing.
func _num_str(v: Variant) -> String:
	if typeof(v) == TYPE_INT:
		return str(int(v))
	if typeof(v) == TYPE_FLOAT:
		return str(int(round(float(v))))
	return str(v)


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = RULES.duplicate()
	else:
		names.append(_pick(rule, RULES, "30"))
	var n: int = names.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "Rule" + names[i]
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		holder.rotation.y = FRONT_YAW
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, names[i])


# ── the automaton, ca_bridge's update verbatim ─────────────────────────────────────────

## `next[i] = (rule >> ((left << 2) | (centre << 1) | right)) & 1`, periodic wrap, single
## centre seed. ca_bridge gd:195-212 and gd:147-158. Re-implemented in Python at ca_bridge's
## OWN geometry (width 31, 120 rows) as a check on this transcription: fills came out 48.0 /
## 23.5 / 49.7 / 87.5 percent for 30 / 90 / 110 / 250, which is its registry's measured
## ladder_note to the decimal. The transcription is verified, not assumed.
func _grid(num: int) -> Array:
	var row: PackedByteArray = PackedByteArray()
	row.resize(COLS)          ## resize zero-initialises: the quiescent row
	row[COLS / 2] = 1         ## ca_bridge gd:158, `current_row[width / 2] = 1`
	var rows: Array = [row.duplicate()]
	for g in range(GENS - 1):
		var nxt: PackedByteArray = PackedByteArray()
		nxt.resize(COLS)
		for i in range(COLS):
			var left: int = int(row[(i - 1 + COLS) % COLS])
			var centre: int = int(row[i])
			var right: int = int(row[(i + 1) % COLS])
			var idx: int = (left << 2) | (centre << 1) | right
			nxt[i] = (num >> idx) & 1
		row = nxt
		rows.append(row.duplicate())
	return rows


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_variant(holder: Node3D, rule_name: String) -> void:
	# The backplate and the field's rebate are IDENTICAL in every one of the fifteen cells.
	# That is deliberate: capture_config_sweep unions the AABB across a spec's variants, and
	# a rule that fills the wall against one that draws a thread would otherwise reframe the
	# whole sheet. Rule 250 lights 35.6% of the field and rule 90 lights 12.7%; the body they
	# are drawn on does not move by a millimetre.
	var back := SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(back, Vector3(0.0, BASE_Y + BACK_H * 0.5, -BACK_D * 0.5),
		Vector3(BACK_W, BACK_H, BACK_D))
	_commit(holder, "Backplate", back, BACK_COLOR, false)

	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw: float = float(COLS) * PITCH + FRAME_T * 2.0
	var fh: float = float(GENS) * PITCH + FRAME_T * 2.0
	var mid_y: float = (FIELD_TOP + FIELD_BOT) * 0.5
	var half_w: float = (float(COLS) * PITCH + FRAME_T) * 0.5
	_add_box(frame, Vector3(0.0, FIELD_TOP + FRAME_T * 0.5, FRAME_D * 0.5),
		Vector3(fw, FRAME_T, FRAME_D))
	_add_box(frame, Vector3(0.0, FIELD_BOT - FRAME_T * 0.5, FRAME_D * 0.5),
		Vector3(fw, FRAME_T, FRAME_D))
	_add_box(frame, Vector3(-half_w, mid_y, FRAME_D * 0.5), Vector3(FRAME_T, fh, FRAME_D))
	_add_box(frame, Vector3(half_w, mid_y, FRAME_D * 0.5), Vector3(FRAME_T, fh, FRAME_D))

	var live := SurfaceTool.new()
	live.begin(Mesh.PRIMITIVE_TRIANGLES)
	var num: int = int(rule_name)

	if reading == "lookup":
		_build_lookup(frame, live, num)
	else:
		_build_wall(holder, live, num, reading == "front")

	_commit(holder, "Rebate", frame, FRAME_COLOR, false)
	_commit(holder, "Live", live, LIVE_COLOR, true)


## All forty generations, or only the last one. A cube where the cell is alive and NOTHING
## where it is not — ca_bridge spawns a cube only for `row[i] == 1` (gd:172-186) and this
## keeps that, because an absence is what a dead cell is. `front` is therefore an almost
## empty wall with a bright line standing on the rebate, which is the reading: for a 1-D
## automaton the present tense is one row in forty, and everything else you can see of it
## is memory. Two and a half percent of the picture, and that number IS the finding.
func _build_wall(holder: Node3D, live: SurfaceTool, num: int, front_only: bool) -> void:
	var rows: Array = _grid(num)
	var first: int = GENS - 1 if front_only else 0
	var seed_st := SurfaceTool.new()
	seed_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seeded: bool = false
	for g in range(first, GENS):
		var row: PackedByteArray = rows[g]
		var cy: float = FIELD_TOP - (float(g) + 0.5) * PITCH
		for c in range(COLS):
			if int(row[c]) == 0:
				continue
			var cx: float = (float(c) + 0.5 - float(COLS) * 0.5) * PITCH
			var at := Vector3(cx, cy, CELL_D * 0.5)
			var size := Vector3(CELL, CELL, CELL_D)
			if g == 0:
				_add_box(seed_st, at, size)
				seeded = true
			else:
				_add_box(live, at, size)
	if seeded:
		_commit(holder, "Seed", seed_st, SEED_COLOR, false)


## The mechanism as a body. Eight tiles, index 7 first, each a three-cell neighbourhood over
## the single cell it produces. Every socket is drawn whether or not it is filled — a lookup
## table has all eight rows under every rule, and only the outputs are the rule's opinion.
## So between any two rules the picture differs in exactly (popcount of a XOR b) output
## blocks out of eight, which is the tightest arithmetic in this artifact.
func _build_lookup(sockets: SurfaceTool, live: SurfaceTool, num: int) -> void:
	for k in range(8):
		var idx: int = 7 - k
		var tx: float = TILE_X[k % 4]
		var iy: float = IN_Y[k / 4]
		var oy: float = OUT_Y[k / 4]
		for j in range(3):
			var bit: int = (idx >> (2 - j)) & 1
			var cx: float = tx + (float(j) - 1.0) * IN_PITCH
			_add_box(sockets, Vector3(cx, iy, SOCK_D * 0.5),
				Vector3(IN_CELL, IN_CELL, SOCK_D))
			if bit == 1:
				_add_box(live, Vector3(cx, iy, LIVE_D * 0.5),
					Vector3(IN_LIVE, IN_LIVE, LIVE_D))
		_add_box(sockets, Vector3(tx, oy, SOCK_D * 0.5), Vector3(OUT_W, OUT_H, SOCK_D))
		if ((num >> idx) & 1) == 1:
			_add_box(live, Vector3(tx, oy, LIVE_D * 0.5),
				Vector3(OUT_LIVE_W, OUT_LIVE_H, LIVE_D))


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals. The
## materials are CULL_DISABLED as well: wave 13's lesson is that a wall photographed from
## behind is indistinguishable from a wall that was never built.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], Vector3(0.0, 0.0, 1.0))
	_quad(st, p[5], p[4], p[7], p[6], Vector3(0.0, 0.0, -1.0))
	_quad(st, p[3], p[2], p[6], p[7], Vector3(0.0, 1.0, 0.0))
	_quad(st, p[4], p[5], p[1], p[0], Vector3(0.0, -1.0, 0.0))
	_quad(st, p[1], p[5], p[6], p[2], Vector3(1.0, 0.0, 0.0))
	_quad(st, p[4], p[0], p[3], p[7], Vector3(-1.0, 0.0, 0.0))


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emissive: bool) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emissive)
	holder.add_child(mi)


func _mat(c: Color, emissive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.65
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		m.emission_enabled = true
		m.emission = LIVE_EMISSION
		m.emission_energy_multiplier = 0.6
	return m
