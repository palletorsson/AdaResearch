extends Node3D

# @identity
# essence: the soft mill's DNA head — a thin root over softmill.tscn's authored machine (a pinned soft sphere, a posed robot-arm stand, a forever-rotating pusher arm), deciding what the laboratory does with what the mill does
# desire: to let the one softbody artifact that never stops moving be met the way its settled siblings are — as a specimen on an apparatus that can be gauged, compared, recorded or cased — without pretending the mill ever rests
# critical_parameter: assay — what measurement furniture stands beside the machine; no branch touches the soft body, the arm, a physics value or a single authored transform
# triggers: _ready() reads assay, returns immediately on the default, and otherwise appends static instruments dimensioned around the authored machine; the mill_still fixture freezes the scene at its authored first instant so a sweep can measure furniture instead of clock phase
# emerges: the recognition that a machine which never settles can still be a result — the chart value's trace refuses to damp to the rest line, because this bench's record is a forcing, not a settling
# needs: the authored SphereSoftBody08 [read live for position and radius, never written]; the authored Rotatingarm/StaticBody3D2 [frozen by fixture only]; the softbody bench kit re-dimensioned to a four-metre machine [tenth longhand copy — the family's no-shared-module debt, recorded again, paid again by nobody]
# relationships: adopts `assay` character for character from the nine softbody benches and from [[jelly_cube]] and [[revolving_joy_ride]] — its own named siblings in SoftBodies_Soft_Body_Deformation; rotating_arm.gd's identity already pairs this machine with jelly_cube, so the bench vocabulary was half-owed
# truth: an apparatus is the decision that something counts as a result. The mill supplies deformation forever; only the furniture around it decides whether that is a number, a difference, a history or an exhibit.

## AXIS — WHAT THE APPARATUS DOES WITH WHAT THE MILL DOES. The machine never changes:
## same pinned sphere, same arm, same stand, same lights. The axis is ON THE APPARATUS,
## never on the starting conditions — a soft body relaxes and a spun arm is a clock, so
## a still of a physics parameter is a still of what time it was. The word and its five
## values are the soft-body bench family's, character for character: jelly_cube and
## revolving_joy_ride — both named siblings of this machine's own @identity — answer the
## same question already.
##
##   none     nothing added. The machine as shipped, trust the eye. THE SHIPPED
##            LINEAGE, and the default: this branch builds no node at all.
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

## Everything the axis builds hangs off this one pivot, so re-dressing the bench can
## never reach the machine.
var _assay_root: Node3D = null


func _ready() -> void:
	_read_dna_meta()
	var a: String = str(assay).strip_edges().to_lower()
	assay = a if ASSAYS.has(a) else "none"

	if _is_true(mill_still):
		_freeze_machine()

	# THE LEGACY PATH. "none" adds nothing at all — with the fixture off, this script
	# has then touched nothing whatsoever and the machine runs exactly as shipped.
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


# ── ASSAY ────────────────────────────────────────────────────────────────────
# The same running mill, five times over, is a curiosity, a measurement, a difference,
# a record and an exhibit. The kit is the bench family's, re-dimensioned: that kit is
# drawn around a half-metre specimen on a bench top, and this is a one-metre sphere
# hanging four metres up beside a three-metre arm — so every position below is derived
# from the authored specimen, and the proportions, accents and captions are the
# family's untouched.

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
func _assay_gauge(spec: Vector3, r: float) -> void:
	var steel: StandardMaterial3D = _a_mat(Color(0.42, 0.45, 0.50), 0.4, 0.6)
	var tick: StandardMaterial3D = _a_mat(Color(0.88, 0.88, 0.84), 0.5, 0.0)
	var read: StandardMaterial3D = _a_glow(ASSAY_READ, 0.95)
	var px: float = spec.x - 1.8
	var pz: float = spec.z
	var top_y: float = spec.y + r + 0.35
	_a_add(_a_box(Vector3(px, 0.03, pz), Vector3(0.5, 0.06, 0.5), steel))
	_a_add(_a_box(Vector3(px, top_y * 0.5, pz), Vector3(0.12, top_y, 0.12), steel))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = 0.25 + float(i) * ((top_y - 0.5) / 12.0)
		var tl: float = 0.22 if (i % 5) == 0 else 0.11
		_a_add(_a_box(Vector3(px + 0.06 + tl * 0.5, ty, pz),
			Vector3(tl, 0.020, 0.030), read if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the sphere, a
	# lit point, and a stylus dropped from it onto the crown.
	var ay: float = spec.y + r + 0.22
	var reach: float = absf(spec.x - px) + 0.06
	_a_add(_a_box(Vector3(px, ay, pz), Vector3(0.22, 0.15, 0.22),
		_a_mat(Color(0.20, 0.21, 0.25), 0.6, 0.0)))
	_a_add(_a_box(Vector3(px + reach * 0.5, ay, pz), Vector3(reach, 0.055, 0.055), read))
	_a_add(_a_sphere(Vector3(px + reach, ay, pz), 0.07, read))
	_a_add(_a_box(Vector3(px + reach, (ay + spec.y + r) * 0.5, pz),
		Vector3(0.03, maxf(ay - (spec.y + r), 0.05), 0.03), read))
	_a_add(_a_label("GAUGE", Vector3(px, top_y + 0.16, pz), ASSAY_READ))


## CONTROL — the reference the bench keeps beside the machine: a wire sphere at the
## size the specimen had before the mill ever touched it, on its own witness plate on
## the floor. The working shape stops being a thing and becomes a difference from
## something. Three orthogonal rings — the reference for a sphere is drawn as a sphere,
## exactly as the cube benches cage a cube.
func _assay_control(at: Vector3, r: float) -> void:
	var pale: StandardMaterial3D = _a_mat(Color(0.80, 0.80, 0.76), 0.6, 0.0)
	var wire: StandardMaterial3D = _a_glow(ASSAY_WIRE, 0.9)
	_a_add(_a_box(Vector3(at.x, 0.025, at.z), Vector3(r * 3.4, 0.05, r * 3.4), pale))
	var cy: float = 0.05 + 0.04 + r
	var rings: Array = [Vector3(0.0, 0.0, 0.0), Vector3(deg_to_rad(90.0), 0.0, 0.0),
		Vector3(0.0, 0.0, deg_to_rad(90.0))]
	for rot in rings:
		var t := TorusMesh.new()
		t.inner_radius = r - 0.015
		t.outer_radius = r + 0.015
		var mi := MeshInstance3D.new()
		mi.mesh = t
		mi.material_override = wire
		mi.position = Vector3(at.x, cy, at.z)
		mi.rotation = rot
		_a_add(mi)
	for sy in [-r, r]:
		_a_add(_a_sphere(Vector3(at.x, cy + sy, at.z), 0.035, wire))
	_a_add(_a_label("CONTROL", Vector3(at.x, cy + r + 0.20, at.z), ASSAY_WIRE))


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
	var frame: StandardMaterial3D = _a_mat(Color(0.26, 0.27, 0.31), 0.7, 0.0)
	var paper: StandardMaterial3D = _a_mat(Color(0.87, 0.86, 0.81), 0.85, 0.0)
	var rule: StandardMaterial3D = _a_mat(Color(0.58, 0.58, 0.54), 0.7, 0.0)
	var ink: StandardMaterial3D = _a_glow(ASSAY_READ, 1.0)
	for lx in [bx - board_w * 0.36, bx + board_w * 0.36]:
		_a_add(_a_box(Vector3(lx, foot * 0.5, bz), Vector3(0.07, foot, 0.07), frame))
	_a_add(_a_box(Vector3(bx, by, bz - 0.03), Vector3(board_w + 0.10, board_h + 0.10, 0.04), frame))
	_a_add(_a_box(Vector3(bx, by, bz), Vector3(board_w, board_h, 0.03), paper))
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


## VITRINE — a case around the whole working volume: glass on four posts, rails top and
## bottom, a capping plate, a caption on the front rail. The mill goes on milling
## inside and can no longer be reached. Rails, not floors — a solid pan would hide the
## stand the machine is bolted to.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = _a_mat(Color(0.30, 0.32, 0.36), 0.4, 0.6)
	var cap: StandardMaterial3D = _a_mat(Color(0.20, 0.21, 0.25), 0.7, 0.0)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	_a_add(_a_box(c, s, _a_glass(Color(0.72, 0.84, 0.95), 0.09)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.06, s.y, 0.06), post))
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.045, 0.045), post))
		for sx2 in [-hx, hx]:
			_a_add(_a_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.045, 0.045, s.z), post))
	_a_add(_a_box(Vector3(c.x, y1 + 0.045, c.z), Vector3(s.x + 0.10, 0.055, s.z + 0.10), cap))
	_a_add(_a_box(Vector3(c.x, y0 + 0.14, c.z + hz + 0.03),
		Vector3(minf(s.x * 0.4, 0.9), 0.14, 0.025), _a_mat(Color(0.13, 0.14, 0.17), 0.8, 0.0)))
	_a_add(_a_label("VITRINE", Vector3(c.x, y0 + 0.14, c.z + hz + 0.08),
		Color(0.90, 0.92, 0.97)))


# ── assay primitives ─────────────────────────────────────────────────────────
# Only the ASSAY block uses these; nothing above this line changes.

func _a_add(n: Node3D) -> void:
	_assay_root.add_child(n)


func _a_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _a_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _a_glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _a_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _a_sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


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
