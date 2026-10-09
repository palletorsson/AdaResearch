extends Node3D

# @identity
# essence: the soft mill's DNA head — a thin root over softmill.tscn's authored machine (a pinned soft sphere, a posed robot-arm stand, a forever-rotating pusher arm), deciding what the laboratory does with what the mill does
# desire: to let the one softbody artifact that never stops moving be met the way its settled siblings are — as a specimen on an apparatus that can be gauged, compared, recorded or cased — without pretending the mill ever rests
# critical_parameter: assay — what measurement furniture stands beside the machine; no branch touches the soft body, the arm, a physics value or a single authored transform
# triggers: _ready() reads assay, re-finishes the machine's own surfaces (the same finish under every value, so the axis still measures furniture and nothing else), returns on the default, and otherwise appends static instruments dimensioned around the authored machine; the mill_still fixture freezes the scene at its authored first instant so a sweep can measure furniture instead of clock phase
# emerges: the recognition that a machine which never settles can still be a result — the chart value's trace refuses to damp to the rest line, because this bench's record is a forcing, not a settling
# needs: the authored SphereSoftBody08 [read live for position and radius, never written]; the authored Rotatingarm/StaticBody3D2 [frozen by fixture only]; commons/render/pbr_kit.gd and mesh_kit.gd for every surface and every chamfer [the bench kit's tenth longhand copy is now a call into a shared module — the family's no-shared-module debt is paid for the FINISH, still owed on the furniture's proportions]
# relationships: adopts `assay` character for character from the nine softbody benches and from [[jelly_cube]] and [[revolving_joy_ride]] — its own named siblings in SoftBodies_Soft_Body_Deformation; rotating_arm.gd's identity already pairs this machine with jelly_cube, so the bench vocabulary was half-owed
# truth: an apparatus is the decision that something counts as a result. The mill supplies deformation forever; only the furniture around it decides whether that is a number, a difference, a history or an exhibit.

## The two shared surface libraries. Preloaded rather than reached through their global
## class names: a class_name lookup has failed under headless tooling in this repo before,
## and a capture that cannot resolve PbrKit is a blank tile rather than a loud error.
const PBR = preload("res://commons/render/pbr_kit.gd")
const MK = preload("res://commons/render/mesh_kit.gd")

## AXIS — WHAT THE APPARATUS DOES WITH WHAT THE MILL DOES. The machine never changes:
## same pinned sphere, same arm, same stand, same lights. The axis is ON THE APPARATUS,
## never on the starting conditions — a soft body relaxes and a spun arm is a clock, so
## a still of a physics parameter is a still of what time it was. The word and its five
## values are the soft-body bench family's, character for character: jelly_cube and
## revolving_joy_ride — both named siblings of this machine's own @identity — answer the
## same question already.
##
##   none     nothing added. The machine as shipped, trust the eye. THE SHIPPED
##            LINEAGE, and the default: this branch builds no furniture at all.
##   gauge    a graduated column full machine height beside the specimen, cantilever
##            arm reaching in, stylus dropped onto the sphere's crown — the deformation
##            gets a NUMBER.
##   control  a wire reference sphere at the size the specimen had before the mill
##            ever touched it, on its own witness plate — the working shape gets a
##            COMPARISON.
##   chart    a plotted board standing behind the machine carrying the forcing trace —
##            a transient that dies into a steady oscillation which never reaches the
##            rest line. The mill gets a HISTORY, and the history admits it does not
##            end.
##   vitrine  glass on four posts around the whole working volume, capped and
##            captioned. The machine goes on milling inside and can no longer be
##            reached — the demonstration becomes an exhibit.
##
## The machine's own SURFACES (see _finish_machine) are re-finished under all five
## values identically, so they cancel out of every pairwise difference a sweep measures.
## The axis still reports furniture; the furniture now stands next to a machine that
## looks like a machine.
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## CAPTURE FIXTURE, not an axis, and OFF in every room. The arm turns 30 degrees a
## second forever and the soft sphere sways on its pin, so two captures of the same
## value differ by whatever the clock did between them — the false-confident-bite trap
## with rotation instead of randf. True freezes both at their AUTHORED first instant
## (process disabled before the first physics tick; no pose is invented), so variants
## differ only by the assay furniture. Untyped so a fixture string survives being
## assigned before _ready.
@export var mill_still = false

# The bench family's accents, character for character.
const ASSAY_READ := Color(0.98, 0.74, 0.26)    # the instrument accent: readings and ink
const ASSAY_WIRE := Color(0.55, 0.88, 0.98)    # the reference standard's cool wire

## The authored machine, by node path.
const SPECIMEN_NODE := "SphereSoftBody08"
const ARM_NODE := "RobotArmWithStand/Rotatingarm/StaticBody3D2"
const MACHINE_NODE := "RobotArmWithStand"

## Everything the axis builds hangs off this one pivot, so re-dressing the bench can
## never reach the machine.
var _assay_root: Node3D = null


func _ready() -> void:
	_read_dna_meta()
	var a: String = str(assay).strip_edges().to_lower()
	assay = a if ASSAYS.has(a) else "none"

	if _is_true(mill_still):
		_freeze_machine()

	# The machine's own surfaces, under every value including the default. Materials and
	# rim chamfers only — no authored transform moves, no dimension changes, and the
	# specimen's frosted glass is not touched.
	_finish_machine()

	# THE LEGACY PATH. "none" adds no furniture at all — with the fixture off, the
	# machine runs exactly as shipped, in the pose the file authored.
	if assay == "none":
		return

	_assay_dressing()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. An unknown word keeps the default; no metadata, no change — which is all six
## existing placements.
func _read_dna_meta() -> void:
	if has_meta("config_assay"):
		var a: String = str(get_meta("config_assay")).strip_edges().to_lower()
		assay = a if ASSAYS.has(a) else assay
	if has_meta("config_mill_still"):
		mill_still = get_meta("config_mill_still")


## Late config honours only the assay key and rebuilds only the assay pivot — a teardown
## that restarted the SoftBody3D would be a physics reset disguised as a config call.
## The fixture is not runtime-switchable: unfreezing a machine that was captured frozen
## is a different scene, not a different dressing.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("assay"):
		return
	var a: String = str(config_data["assay"]).strip_edges().to_lower()
	if not ASSAYS.has(a) or a == assay:
		return
	assay = a
	if is_node_ready():
		_assay_dressing()


## The freeze: processing disabled on the two moving parts before the first physics
## tick, so both hold their authored transforms. Nothing is repositioned — the still is
## the file's own first frame.
func _freeze_machine() -> void:
	var sb: Node = get_node_or_null(SPECIMEN_NODE)
	if sb != null:
		sb.process_mode = Node.PROCESS_MODE_DISABLED
	var arm: Node = get_node_or_null(ARM_NODE)
	if arm != null:
		arm.process_mode = Node.PROCESS_MODE_DISABLED


# ── THE MACHINE'S SURFACES ───────────────────────────────────────────────────
# The stand shipped as five cylinders and three spheres sharing three materials: one at
# metallic 0.9 / roughness 0.1 for every limb, one mirror-bright gold for every joint,
# and — on the pusher's hub — no material at all, which Godot draws as white plastic.
# The blade was magenta at metallic 1.0 and roughness 0.0: an albedo no metal has and a
# polish no working machine keeps. None of that is a shape problem, so none of it is
# fixed by moving anything. Each mesh is rebuilt FROM ITS OWN NUMBERS with the rim
# chamfer it was missing, and each surface is told what it is made of.
#
# Read the dispatch below as the machine's parts list: a wide cylinder is the cast base,
# a narrow one is a turned limb, a small sphere is a bearing joint, a large one is the
# pivot marker, a box is the pusher. That is the whole machine, and the specimen — the
# one thing this file must never touch — is not in this subtree at all.

func _finish_machine() -> void:
	var machine: Node = get_node_or_null(MACHINE_NODE)
	if machine == null:
		return
	_machine_walk(machine)
	# Rubric 4. The base is a two-metre disc standing on a floor and nothing said so.
	# One decal, conforming to whatever it lands on, and the machine stops hovering.
	var pool: Decal = _a_shadow(Vector3.ZERO, 1.35)
	pool.name = "MachineContact"
	machine.add_child(pool)


func _machine_walk(n: Node) -> void:
	var mi: MeshInstance3D = n as MeshInstance3D
	if mi != null and mi.mesh != null:
		_machine_surface(mi)
	for c in n.get_children():
		_machine_walk(c)


## One authored mesh, re-finished in place. Every branch reads its dimensions off the
## mesh it replaces, so a part re-sized in the .tscn tomorrow still gets a proportionate
## chamfer and nothing here has to be kept in sync by hand.
func _machine_surface(mi: MeshInstance3D) -> void:
	var cyl: CylinderMesh = mi.mesh as CylinderMesh
	if cyl != null:
		var rb: float = cyl.bottom_radius
		var rt: float = cyl.top_radius
		var h: float = cyl.height
		var wide: float = maxf(rb, rt)
		# 48 facets on the metre-wide base, 24 on a limb you can close a hand around.
		var segs: int = 48 if wide > 0.5 else 24
		var ch: float = clampf(minf(wide, h) * 0.07, 0.003, 0.020)
		mi.mesh = MK.cone(rb, rt, h, segs, ch)
		if wide > 0.5:
			mi.material_override = _mat_base()
		else:
			mi.material_override = _mat_limb(maxf(h, wide * 2.0))
		return
	var sph: SphereMesh = mi.mesh as SphereMesh
	if sph != null:
		var sr: float = maxf(sph.radius, 0.001)
		# 64 x 32 to draw a 15 cm bearing is four thousand triangles for a ball. The
		# replacement is smooth at arm's length and costs a tenth of that.
		mi.mesh = MK.capsule(sr, maxf(sph.height, sr * 2.0), 24, 5)
		if sr > 0.2:
			mi.material_override = _mat_pivot()
		else:
			mi.material_override = _mat_joint(sr * 2.0)
		return
	var bx: BoxMesh = mi.mesh as BoxMesh
	if bx != null:
		var s: Vector3 = bx.size
		var thin: float = minf(minf(s.x, s.y), s.z)
		mi.mesh = MK.bevel_box(s, clampf(thin * 0.06, 0.004, 0.018))
		mi.material_override = _mat_pusher()


## The base: a heavy sand-cast disc, pitted, dirtier where it meets the floor.
func _mat_base() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.cast_metal(Color(0.235, 0.240, 0.265), 0.34)
	PBR.weather(m, 0.30)
	PBR.crevice_ao(m, 0.55)
	return m


## A turned limb. The authored albedo was 0.80, 0.85, 0.90 — brighter than any real
## metal reflects — so the cool cast stays and the impossible value goes.
func _mat_limb(size: float) -> StandardMaterial3D:
	return _a_fit(PBR.machined_metal(Color(0.615, 0.640, 0.660), 0.24, 0.10), size)


## A bearing joint: brass, turned, lightly polished. The authored gold stays gold.
func _mat_joint(size: float) -> StandardMaterial3D:
	return _a_fit(PBR.machined_metal(PBR.BRASS, 0.18, 0.12), size)


## The pivot marker keeps its authored glow — it is the one part of the machine whose
## job is to say where the axis is — at a third of the old energy, over a gold that has
## something left to shade.
func _mat_pivot() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.machined_metal(PBR.GOLD, 0.16, 0.06)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.62, 0.10)
	m.emission_energy_multiplier = 0.35
	return m


## The pusher: anodised magenta aluminium, brushed along its length, weathered where it
## spends every second of its life pressing into something soft. Same hue the file
## chose, at an albedo a metal can actually have.
func _mat_pusher() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.brushed_metal(Color(0.60, 0.145, 0.575), 0.30, 0.16, "x")
	m.metallic = 0.88
	m.metallic_specular = 0.50
	m.clearcoat_enabled = true
	m.clearcoat = 0.30
	m.clearcoat_roughness = 0.20
	return PBR.weather(m, 0.30)


# ── ASSAY ────────────────────────────────────────────────────────────────────
# The same running mill, five times over, is a curiosity, a measurement, a difference,
# a record and an exhibit. The kit is the bench family's, re-dimensioned: that kit is
# drawn around a half-metre specimen on a bench top, and this is a one-metre sphere
# hanging four metres up beside a three-metre arm — so every position below is derived
# from the authored specimen, and the proportions, accents and captions are the
# family's untouched. What is NOT the family's any more is the finish: every surface
# here now names a material out of commons/render rather than inventing an albedo and
# one flat roughness on the spot.

func _assay_dressing() -> void:
	if _assay_root != null and is_instance_valid(_assay_root):
		remove_child(_assay_root)
		_assay_root.queue_free()
	_assay_root = null
	if assay == "none":
		return                                    # the legacy lineage: nothing at all
	_assay_root = Node3D.new()
	_assay_root.name = "Assay"
	add_child(_assay_root)

	# The specimen, read live: where the author pinned it and how big its mesh is.
	var spec: Vector3 = Vector3(-0.809108, 3.99691, -1.97789)
	var r: float = 0.5
	var sb: MeshInstance3D = get_node_or_null(SPECIMEN_NODE) as MeshInstance3D
	if sb != null:
		spec = sb.position
		var sm: SphereMesh = sb.mesh as SphereMesh
		if sm != null:
			r = sm.radius

	match assay:
		"gauge":
			_assay_gauge(spec, r)
		"control":
			_assay_control(Vector3(2.5, 0.0, spec.z + 0.08), r)
		"chart":
			_assay_chart(2.7, spec.z - 1.1)
		"vitrine":
			_assay_vitrine(Vector3(0.0, (spec.y + r + 0.35) * 0.5, -0.7),
				Vector3(5.6, spec.y + r + 0.35, 3.9))
		_:
			pass


## GAUGE — a graduated column standing machine height beside the hanging specimen, a
## cantilever arm reaching in over it and a stylus dropped onto the crown. The mill
## stops merely deforming a shape and starts reporting a height.
##
## The finish makes one distinction the old flat grey could not: STRUCTURE is metal
## (rolled steel column, scuffed footplate, anodised cantilever) and the READING is
## self-lit. The stylus, its tip and every fifth graduation glow; nothing else does.
func _assay_gauge(spec: Vector3, r: float) -> void:
	var px: float = spec.x - 1.8
	var pz: float = spec.z
	var top_y: float = spec.y + r + 0.35
	# Rolled steel brushed UP the column, so one highlight runs its whole height; the
	# footplate is a different piece of the same stock laid flat, brushed across and
	# dirtier, because the floor is what reaches it.
	var steel: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.30, 0.14, "y")
	PBR.crevice_ao(steel, 0.45)
	var plate: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.34, 0.30, "x")
	PBR.weather(plate, 0.40)
	# A graduation is paint in an engraved line — a dielectric, not a little metal bar.
	var tick: StandardMaterial3D = _a_fit(PBR.rams_body(Color(0.88, 0.88, 0.85), 0.06), 0.03)
	var amber: StandardMaterial3D = _a_fit(PBR.anodized(ASSAY_READ.darkened(0.30), 0.30, 0.12), 0.12)
	var read: StandardMaterial3D = PBR.emissive(ASSAY_READ, 0.95)
	var lit: StandardMaterial3D = PBR.led(ASSAY_READ, 1.8)
	var collar: StandardMaterial3D = _a_fit(PBR.worn_metal(PBR.GUNMETAL, 0.40), 0.22)
	_a_add(_a_box(Vector3(px, 0.03, pz), Vector3(0.5, 0.06, 0.5), plate, 0.35))
	_a_add(_a_box(Vector3(px, top_y * 0.5, pz), Vector3(0.12, top_y, 0.12), steel, 0.20))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = 0.25 + float(i) * ((top_y - 0.5) / 12.0)
		var tl: float = 0.22 if (i % 5) == 0 else 0.11
		_a_add(_a_box(Vector3(px + 0.06 + tl * 0.5, ty, pz),
			Vector3(tl, 0.020, 0.030), lit if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the sphere, a
	# lit point, and a stylus dropped from it onto the crown.
	var ay: float = spec.y + r + 0.22
	var reach: float = absf(spec.x - px) + 0.06
	_a_add(_a_box(Vector3(px, ay, pz), Vector3(0.22, 0.15, 0.22), collar))
	_a_add(_a_box(Vector3(px + reach * 0.5, ay, pz), Vector3(reach, 0.055, 0.055), amber))
	_a_add(_a_sphere(Vector3(px + reach, ay, pz), 0.07, read))
	_a_add(_a_box(Vector3(px + reach, (ay + spec.y + r) * 0.5, pz),
		Vector3(0.03, maxf(ay - (spec.y + r), 0.05), 0.03), read))
	_a_add(_a_label("GAUGE", Vector3(px, top_y + 0.16, pz), ASSAY_READ))
	_a_ground(Vector3(px, 0.0, pz), 0.42)


## CONTROL — the reference the bench keeps beside the machine: a wire sphere at the
## size the specimen had before the mill ever touched it, on its own witness plate on
## the floor. The working shape stops being a thing and becomes a difference from
## something. Three orthogonal rings — the reference for a sphere is drawn as a sphere,
## exactly as the cube benches cage a cube.
func _assay_control(at: Vector3, r: float) -> void:
	# Painted plate, scuffed where a reference gets lifted on and off it. The wire is
	# self-lit and rim-brightened so it reads as a DIAGRAM standing in the room rather
	# than a second object competing with the specimen.
	var pale: StandardMaterial3D = PBR.rams_body(Color(0.82, 0.82, 0.79), 0.14)
	PBR.weather(pale, 0.30)
	PBR.crevice_ao(pale, 0.50)
	var wire: StandardMaterial3D = PBR.emissive(ASSAY_WIRE, 0.9)
	PBR.edge_light(wire, 0.35, 0.50)
	_a_add(_a_box(Vector3(at.x, 0.025, at.z), Vector3(r * 3.4, 0.05, r * 3.4), pale, 0.40))
	var cy: float = 0.05 + 0.04 + r
	var rings: Array = [Vector3(0.0, 0.0, 0.0), Vector3(deg_to_rad(90.0), 0.0, 0.0),
		Vector3(0.0, 0.0, deg_to_rad(90.0))]
	for rot in rings:
		var mi: MeshInstance3D = _a_ring(Vector3(at.x, cy, at.z), r, 0.015, wire)
		mi.rotation = rot
		_a_add(mi)
	for sy in [-r, r]:
		_a_add(_a_sphere(Vector3(at.x, cy + sy, at.z), 0.035, wire))
	_a_add(_a_label("CONTROL", Vector3(at.x, cy + r + 0.20, at.z), ASSAY_WIRE))
	_a_ground(Vector3(at.x, 0.0, at.z), r * 1.9)


## CHART — a record board standing behind the machine carrying the forcing trace: a
## transient that dies into a steady oscillation which never reaches the rest line,
## because this machine never lets its specimen rest. The bench stops showing a state
## and starts keeping a history — and the history is honest about not ending. The trace
## is CLOSED FORM, not sampled from the running solver: a plot that came out different
## on every launch would be noise wearing the costume of a record.
func _assay_chart(board_w: float, bz: float) -> void:
	var board_h: float = 1.35
	var foot: float = 0.55
	var by: float = foot + board_h * 0.5
	var bx: float = -0.4
	var frame: StandardMaterial3D = PBR.brushed_metal(PBR.GUNMETAL, 0.34, 0.28, "y")
	# The backing is a painted steel plate and the sheet on it is paper: a hard coated
	# gloss against a soft matte one, which is the whole reason the sheet reads as paper.
	var back: StandardMaterial3D = PBR.painted_metal(Color(0.26, 0.27, 0.31), 0.22, 0.35, 0.55)
	var paper: StandardMaterial3D = PBR.rams_body(Color(0.88, 0.87, 0.82), 0.10)
	var rule: StandardMaterial3D = _a_fit(PBR.rams_body(Color(0.56, 0.56, 0.53), 0.10), 0.03)
	var ink: StandardMaterial3D = PBR.emissive(ASSAY_READ, 1.0)
	for lx in [bx - board_w * 0.36, bx + board_w * 0.36]:
		_a_add(_a_box(Vector3(lx, foot * 0.5, bz), Vector3(0.07, foot, 0.07), frame, 0.30))
	_a_add(_a_panel(Vector3(bx, by, bz - 0.03),
		Vector3(board_w + 0.10, board_h + 0.10, 0.04), back, 0.030, 0.006))
	_a_add(_a_panel(Vector3(bx, by, bz), Vector3(board_w, board_h, 0.03), paper, 0.014, 0.004))
	var x0: float = bx - board_w * 0.42
	var x1: float = bx + board_w * 0.42
	var y0: float = by - board_h * 0.34
	var y1: float = by + board_h * 0.34
	_a_add(_a_box(Vector3(bx, by, bz + 0.022), Vector3(board_w * 0.86, 0.020, 0.015), rule))
	_a_add(_a_box(Vector3(x0, by, bz + 0.022), Vector3(0.020, board_h * 0.70, 0.015), rule))
	for i in range(4):
		_a_add(_a_box(Vector3(bx, lerpf(y0, y1, float(i + 1) / 5.0), bz + 0.020),
			Vector3(board_w * 0.86, 0.008, 0.010), rule))
	# Transient into steady forcing: the settled benches damp to the rest line; the mill
	# does not, and its record says so. The rest line above is drawn at MID-height so
	# the steady band visibly straddles it forever.
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(33):
		var f: float = float(i) / 32.0
		var v: float = exp(-3.0 * f) * cos(f * 11.0) * 0.5
		v += 0.26 * sin(f * 24.0) * clampf(f * 1.8, 0.0, 1.0)
		pts.append(Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.42), bz + 0.035))
	for i in range(pts.size() - 1):
		_a_add(_a_seg(pts[i], pts[i + 1], 0.026, ink))
	_a_add(_a_sphere(pts[pts.size() - 1], 0.036, ink))
	_a_add(_a_label("CHART", Vector3(bx, by + board_h * 0.5 + 0.16, bz), ASSAY_READ))
	_a_ground(Vector3(bx, 0.0, bz), board_w * 0.45)


## VITRINE — a case around the whole working volume: glass on four posts, rails top and
## bottom, a capping plate, a caption on the front rail. The mill goes on milling
## inside and can no longer be reached. Rails, not floors — a solid pan would hide the
## stand the machine is bolted to.
##
## The glass is one layer and one layer only (transparency is overdraw, and overdraw is
## the Quest's tightest budget); its Fresnel rim is what draws the case's edges, so the
## exhibit reads as a case rather than as a faint tint over the machine.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.28, 0.14, "y")
	var rail_x: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.30, 0.18, "x")
	var rail_z: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.30, 0.18, "z")
	var cap: StandardMaterial3D = PBR.painted_metal(Color(0.21, 0.22, 0.26), 0.22, 0.35, 0.55)
	var plaque: StandardMaterial3D = _a_fit(PBR.terminal_body(Color(0.15, 0.16, 0.19), 0.28), 0.16)
	# ONE pane's worth of tint. The old glass drew both faces of the box at 0.09 each,
	# so the case read at about 0.17 through; back-face culling halves the overdraw and
	# the opacity is raised to land the same density on the machine behind it.
	var pane: StandardMaterial3D = PBR.glass(Color(0.74, 0.85, 0.95), 0.03, 0.16)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	_a_add(_a_box(c, s, pane))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.06, s.y, 0.06), post, 0.18))
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.045, 0.045), rail_x, 0.18))
		for sx2 in [-hx, hx]:
			_a_add(_a_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.045, 0.045, s.z), rail_z, 0.18))
	_a_add(_a_box(Vector3(c.x, y1 + 0.045, c.z), Vector3(s.x + 0.10, 0.055, s.z + 0.10), cap, 0.25))
	_a_add(_a_panel(Vector3(c.x, y0 + 0.14, c.z + hz + 0.03),
		Vector3(minf(s.x * 0.4, 0.9), 0.14, 0.025), plaque, 0.020, 0.004))
	_a_add(_a_label("VITRINE", Vector3(c.x, y0 + 0.14, c.z + hz + 0.08),
		Color(0.90, 0.92, 0.97)))


# ── assay primitives ─────────────────────────────────────────────────────────
# Only the ASSAY block and the machine finish use these; the axis above does not know
# what a material is. Every one of them is now a thin adapter onto commons/render —
# same call shapes the bench family has always used, chamfers and tangents underneath.

func _a_add(n: Node3D) -> void:
	_assay_root.add_child(n)


## Detail frequency for a part of a given size. The kit authors its noise at three to
## six tiles a metre, which is right for a half-metre panel and reads as flat colour on
## a two-centimetre graduation. Refine on small parts; never coarsen, because the
## machine's own parts are metres long and the kit's rate already suits them.
func _a_fit(m: StandardMaterial3D, size: float) -> StandardMaterial3D:
	return PBR.scale_detail(m, clampf(0.35 / maxf(size, 0.004), 1.0, 20.0))


## A chamfered box, positioned. Same three arguments the bench family has always used;
## the fourth bakes vertex wear — edges rubbed clean, undersides darkened where dirt
## collects — into anything that meets a floor.
func _a_box(center: Vector3, size: Vector3, mat: Material, wear: float = 0.0) -> MeshInstance3D:
	return PBR.box(center, size, mat, -1.0, wear)


## A milled plate: rounded corners, a bevel round both faces, tangents for the normal
## map. Faces +Z, which is the plane every board on this bench stands in.
func _a_panel(center: Vector3, size: Vector3, mat: Material,
		corner: float, bevel: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MK.rounded_panel(size, corner, 3, bevel)
	mi.material_override = mat
	mi.position = center
	return mi


## One ring of the wire reference, lathed rather than left to TorusMesh's 64 x 32
## default: the same circle — major radius `major`, tube radius `tube`, hole up the Y
## axis, exactly what inner/outer_radius described — for a quarter of the triangles,
## with the tangents a normal map needs and a section count I can actually see.
func _a_ring(center: Vector3, major: float, tube: float, mat: Material,
		around: int = 48, section: int = 10) -> MeshInstance3D:
	var prof: Array = []
	for k in range(section + 1):
		var a: float = TAU * float(k) / float(section)
		prof.append(Vector4(major + tube * cos(a), tube * sin(a), cos(a), sin(a)))
	var mi := MeshInstance3D.new()
	mi.mesh = MK.lathe(prof, around)
	mi.material_override = mat
	mi.position = center
	return mi


func _a_sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MK.capsule(radius, radius * 2.0, 20, 5)
	mi.material_override = mat
	mi.position = center
	return mi


## One contact shadow, laid on a contact plane. A decal, so it conforms to a floor, a
## plinth top or a step instead of z-fighting a flat quad against one — rubric 4, and
## the cheapest honest grounding there is.
##
## The kit's projector box is half a metre tall so it can find a step below the object.
## Here the only thing under this bench IS the floor, and a tall box would also spray
## the pool up the side of whatever stands in it — the machine's own base disc, in the
## machine's case. Squashed to a ten-centimetre slab it can reach nothing but the
## contact plane and the last centimetre of skirt above it, which is the shadow anyway.
func _a_shadow(at: Vector3, radius: float) -> Decal:
	var d: Decal = PBR.ground_shadow(radius, 0.50, 0.10)
	d.size = Vector3(d.size.x, 0.10, d.size.z)
	d.position = at + Vector3(0.0, 0.02, 0.0)
	return d


## The assay's own contact pool. One per branch: the machine already carries its own,
## and two overlapping pools read as a stain rather than as two objects standing.
func _a_ground(at: Vector3, radius: float) -> void:
	_a_add(_a_shadow(at, radius))


## One segment of the plotted trace. The whole chart lies in a plane at constant z, so
## a box turned about Z is enough — no general basis needed.
func _a_seg(a: Vector3, b: Vector3, w: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var mi: MeshInstance3D = _a_box((a + b) * 0.5, Vector3(maxf(d.length(), w), w, w), mat)
	mi.rotation.z = atan2(d.y, d.x)
	return mi


## Machine-scale caption: the family's billboard label, sized for a frame that is six
## metres wide rather than sixty centimetres.
func _a_label(text: String, pos: Vector3, tint: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 13
	l.pixel_size = 0.0035
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = tint
	l.outline_size = 5
	return l


func _is_true(v) -> bool:
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]
