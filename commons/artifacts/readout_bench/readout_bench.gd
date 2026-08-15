extends Node3D
class_name ReadoutBench

## readout_bench — how a value is SHOWN is a claim about how well it is KNOWN.
##
## THE FAMILY. Seven artifacts share the axis `readout` with the values none, numeral,
## gradation, lattice, in that order: health_display, hits_reset_display, line,
## line_interface, qfep_calibrator, xyz_coordinates and xyz_slider_plate. The vocabulary is
## owned by xyz_slider_plate.gd (READOUT_ALIASES and the static readout_name()) and the rest
## parse through it, so one word means one rung on all seven. Every member glosses the
## ladder the same way — "monotone in evidence: rung 0 says nothing, rung 1 says a number,
## rung 2 puts that number on a public scale, rung 3 draws the values the apparatus counts
## as clean" — and every member builds it ADDITIVELY: gradation keeps the numeral, lattice
## keeps both. entropy_jar is a cousin, not a member: its `readout` is
## figures | number | verdict | none, which asks whether the second law arrives as a
## computed figure with commentary, a bare number, words, or nothing. `number` and `none`
## map onto this ladder; `figures` and `verdict` do not; so it is named and left out.
##
## THE ARGUMENT. The family treats the four as four amounts of evidence. Read them instead
## as four CLAIMS about the value, and they order the other way round:
##
##   numeral    "0.62". A decimal place is a promise. This readout can be wrong to the
##              hundredth, and nothing about a fluid surface backs a hundredth.
##   gradation  a rule beside the thing. It claims only an INTERVAL — between this tooth
##              and the next — and the body itself is the pointer.
##   lattice    a grid over the thing. It claims a CELL in a space, and one of the space's
##              two directions has nothing to do with the value at all. It shows the most
##              ink and asserts the least.
##   none       the body alone. It claims nothing, so it is the only readout that cannot
##              be wrong.
##
## So evidence and commitment run in opposite directions, and the rung the family calls the
## top of its ladder is the one that promises least. To make that visible each rung is
## mounted ALONE here — the bench does not stack them the way the members do — because a
## lattice that still carries the numeral still carries the numeral's promise.
##
## THE BODY, NOT A GAUGE. The readout IS a gauge, so the trick is that the thing being read
## is a real object and the readouts are bolted to it. One number, 0.62, is held by three
## bodies: a fluid standing 0.62 of the way up a glass tank (`level`), a knob 0.62 of the
## way along a rail on a panel (`position`), and five pucks on a spindle that holds eight
## (`count`: 5/8 = 0.625, the nearest that body can get). The numeral is a nameplate on the
## plinth, the rule stands beside the measured span, the grid lies on the face the value is
## read against. Nothing floats and nothing billboards.
##
## THE CHECK THE SECOND AXIS EXISTS FOR. On `count` the nameplate says "5" and cannot be
## wrong: a puck is a whole thing. On `level` the same nameplate says "0.62" and promises a
## hundredth of a tank. The numeral over-claims on count not at all and on level by the
## width of the meniscus — the argument bites only where the quantity is continuous, which
## is what a reader is meant to notice standing in front of the ladder.

## AXIS — what the bench commits to about the value its body holds. The family's four
## words in the family's order; default `numeral`, which six of the seven members ship
## (xyz_coordinates alone ships `none`).
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral":
	set(v):
		readout = v
		if is_inside_tree():
			_rebuild()

## AXIS — WHAT is being read. Three bodies that each hold the one number in `value`.
##   level     a fluid standing `value` of the way up a glass tank. Continuous, vertical.
##   position  a knob `value` of the way along a rail on an upright panel. Continuous,
##             horizontal.
##   count     round(value * capacity) pucks on a spindle that holds `capacity`. Discrete,
##             vertical — the only body whose numeral is exactly right.
@export_enum("level", "position", "count") var quantity: String = "level":
	set(v):
		quantity = v
		if is_inside_tree():
			_rebuild()

## Whether the four readouts stand together on one quantity, or one at a time. THIS IS NOT
## PART OF THE AXES: with an all-rungs value inside an axis, capture_config_sweep unions
## the AABB across the spec and photographs every single rung as a speck against a row four
## times its width. The sweep pins this to `single` through dna.fixture; the artifact still
## stands as the whole comparison by default, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## The one number every body holds, as a fraction of full. 0.62 on purpose: it is not a
## station on any of the scales below (the majors fall on quarters, the minors on
## twentieths, the pucks on eighths), so every readout has to say something about a value
## that lies BETWEEN its own marks. Not an axis — it is the constant the argument needs.
@export var value: float = 0.62
## How many pucks the count body's spindle holds. round(value * capacity) are on it.
@export var capacity: int = 8
@export var spacing: float = 0.31

const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]
const QUANTITIES: PackedStringArray = ["level", "position", "count"]

const SPAN := 0.24                     # the measured span, the same on all three bodies
const PLINTH := Vector3(0.28, 0.05, 0.16)
const STEPS := 20                      # minor teeth on a continuous scale — one every 5%
const MAJOR_EVERY := 5                 # a numbered station every quarter
const GRID_ROWS := 10                  # lattice cells along the measured span
const WIRE := 0.003
const BLADE_W := 0.022
const BLADE_T := 0.005
const TOOTH_MINOR := 0.011
const TOOTH_MAJOR := 0.020
const TOOTH_W := 0.0035
const PLATE := Vector3(0.11, 0.04, 0.004)

const GRAPHITE := Color(0.16, 0.17, 0.19)
const PANEL := Color(0.30, 0.32, 0.35)
const STEEL := Color(0.72, 0.75, 0.80)
const BONE := Color(0.90, 0.88, 0.82)
const INK := Color(0.08, 0.08, 0.09)
const AMBER := Color(0.95, 0.60, 0.16)
const GLASS := Color(0.78, 0.88, 0.94, 0.26)
const KNOB := Color(0.55, 0.92, 1.00)
const PUCK_A := Color(0.86, 0.80, 0.66)
const PUCK_B := Color(0.78, 0.71, 0.56)
const WIRE_TINT := Color(0.62, 0.86, 0.96)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("readout"):
		# The family's one reader, so `#readout: ticks` means the same rung here as on the
		# plate, the line and the two gameplay panels; an unrecognised word builds as
		# numeral, not none — the members' rule, for the members' reason.
		var want: String = XYZSliderPlate.readout_name(str(config_data["readout"]))
		readout = want if READOUTS.has(want) else "numeral"
	if config_data.has("quantity"):
		var q: String = str(config_data["quantity"]).strip_edges().to_lower()
		if QUANTITIES.has(q):
			quantity = q
	if config_data.has("value"):
		value = clampf(float(config_data["value"]), 0.0, 1.0)
	if config_data.has("capacity"):
		capacity = maxi(int(config_data["capacity"]), 1)
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var rungs: Array = []
	if layout == "ladder":
		for r in READOUTS:
			rungs.append(String(r))
	else:
		rungs.append(readout)
	var n: int = rungs.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "Readout_%s" % String(rungs[i])
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		var desc: Dictionary = _build_body(holder)
		_mount(holder, desc, String(rungs[i]))


# ── the bodies ───────────────────────────────────────────────────────────────
#
# Each builder makes the plinth and the measured thing, and returns a Dictionary that says
# where a readout may be bolted on: where the rule starts and which way it runs, which way
# its teeth point, which face the grid lies on. The readouts never touch the body's
# geometry — they only stand where the body says a reading is taken.

func _build_body(holder: Node3D) -> Dictionary:
	match quantity:
		"position":
			return _build_position(holder)
		"count":
			return _build_count(holder)
		_:
			return _build_level(holder)


## A glass tank on the plinth with a fluid standing `value` of the way up its inside.
func _build_level(holder: Node3D) -> Dictionary:
	_plinth(holder)
	var wall: float = 0.01
	var y0: float = PLINTH.y + wall                # the inner floor — where the span starts
	var tank_h: float = SPAN + wall * 2.0
	var t: float = clampf(value, 0.0, 1.0)
	var fill_h: float = maxf(SPAN * t, 0.001)
	# The fluid first, the glass after — the opaque body renders before the transparent
	# skin regardless of order, but a reader of this file should meet the value before
	# the vessel.
	var fluid: MeshInstance3D = _box(holder, Vector3(0.12, fill_h, 0.09),
			Vector3(0.0, y0 + fill_h * 0.5, 0.0), _mat(AMBER, 0.35))
	fluid.name = "Fluid"
	var tank: MeshInstance3D = _box(holder, Vector3(0.13, tank_h, 0.10),
			Vector3(0.0, PLINTH.y + tank_h * 0.5, 0.0), _glass())
	tank.name = "Tank"
	return {
		"numeral": "%.2f" % t,
		"discrete": false,
		"steps": STEPS,
		"major_every": MAJOR_EVERY,
		# the rule stands beside the tank, teeth reaching in toward the glass and
		# stopping 4 mm short of it
		"scale_start": Vector3(0.10, y0, 0.0),
		"along": Vector3.UP,
		"teeth": Vector3.LEFT,
		"flat": Vector3.BACK,
		# the grid lies on the front glass, the face the fluid is read against —
		# 0.024 m cells both ways, so the columns say nothing the rows do not
		"grid_origin": Vector3(-0.06, y0, 0.05 + 0.002),
		"grid_across": Vector3.RIGHT,
		"grid_width": 0.12,
		"grid_cols": 5,
		"cage": false,
	}


## An upright panel on the plinth with a rail across it and a knob `value` of the way along.
func _build_position(holder: Node3D) -> Dictionary:
	_plinth(holder)
	var panel_h: float = 0.15
	var panel_z: float = -0.03
	var face_z: float = panel_z + 0.006 + 0.001    # just proud of the panel's front face
	var half: float = SPAN * 0.5
	var panel: MeshInstance3D = _box(holder, Vector3(SPAN + 0.02, panel_h, 0.012),
			Vector3(0.0, PLINTH.y + panel_h * 0.5, panel_z), _mat(PANEL, 0.0))
	panel.name = "Panel"
	var rod_y: float = PLINTH.y + 0.06
	var rod_z: float = 0.012
	var rod: MeshInstance3D = _cyl(holder, 0.005, SPAN, Vector3(0.0, rod_y, rod_z), _mat(STEEL, 0.0))
	rod.rotation.z = PI * 0.5
	rod.name = "Rail"
	for sx in [-1.0, 1.0]:
		_box(holder, Vector3(0.012, 0.03, 0.026),
				Vector3(float(sx) * (half + 0.006), rod_y, rod_z), _mat(STEEL.darkened(0.3), 0.0))
	var t: float = clampf(value, 0.0, 1.0)
	var knob: MeshInstance3D = _box(holder, Vector3(0.022, 0.032, 0.026),
			Vector3(-half + SPAN * t, rod_y, rod_z), _mat(KNOB, 1.2))
	knob.name = "Knob"
	return {
		"numeral": "%.2f" % t,
		"discrete": false,
		"steps": STEPS,
		"major_every": MAJOR_EVERY,
		# the rule runs along the panel above the rail, teeth pointing down at it
		"scale_start": Vector3(-half, rod_y + 0.040, face_z),
		"along": Vector3.RIGHT,
		"teeth": Vector3.DOWN,
		"flat": Vector3.BACK,
		# the grid covers the panel: columns along the travel, rows across a height the
		# knob never uses — the direction that has nothing to do with the value
		"grid_origin": Vector3(-half, PLINTH.y, face_z),
		"grid_across": Vector3.UP,
		"grid_width": panel_h,
		"grid_cols": 5,
		"cage": false,
	}


## A spindle on the plinth holding round(value * capacity) pucks out of `capacity`.
func _build_count(holder: Node3D) -> Dictionary:
	_plinth(holder)
	var cap: int = maxi(capacity, 1)
	var pitch: float = SPAN / float(cap)
	var puck_h: float = pitch * 0.8
	var puck_r: float = 0.06
	var y0: float = PLINTH.y
	var spindle: MeshInstance3D = _cyl(holder, 0.008, SPAN + 0.02,
			Vector3(0.0, y0 + (SPAN + 0.02) * 0.5, 0.0), _mat(STEEL, 0.0))
	spindle.name = "Spindle"
	var n: int = clampi(int(round(clampf(value, 0.0, 1.0) * float(cap))), 0, cap)
	for i in range(n):
		var c: Color = PUCK_A if (i % 2 == 0) else PUCK_B
		var puck: MeshInstance3D = _cyl(holder, puck_r, puck_h,
				Vector3(0.0, y0 + float(i) * pitch + puck_h * 0.5, 0.0), _mat(c, 0.0))
		puck.name = "Puck%d" % (i + 1)
	return {
		"numeral": "%d" % n,
		"discrete": true,
		"steps": cap,
		"major_every": 1,                # every station on a discrete scale is a whole number
		"scale_start": Vector3(0.10, y0, 0.0),
		"along": Vector3.UP,
		"teeth": Vector3.LEFT,
		"flat": Vector3.BACK,
		# the count body's lattice is a cage — rings at every puck height, bars around
		"grid_origin": Vector3.ZERO,
		"grid_across": Vector3.RIGHT,
		"grid_width": 0.0,
		"grid_cols": 0,
		"cage": true,
		"cage_base": Vector3(0.0, y0, 0.0),
		"cage_radius": puck_r + 0.012,
	}


func _plinth(holder: Node3D) -> void:
	var p: MeshInstance3D = _box(holder, PLINTH, Vector3(0.0, PLINTH.y * 0.5, 0.0), _mat(GRAPHITE, 0.0))
	p.name = "Plinth"


# ── the readouts ─────────────────────────────────────────────────────────────

func _mount(holder: Node3D, desc: Dictionary, rung: String) -> void:
	match rung:
		"numeral":
			_mount_numeral(holder, desc)
		"gradation":
			_mount_gradation(holder, desc)
		"lattice":
			_mount_lattice(holder, desc)
		_:
			pass                          # none — the body alone


## RUNG numeral — a nameplate on the plinth's front, the digits and nothing else. The same
## plate on all three bodies; only the digits differ, which is the point.
func _mount_numeral(holder: Node3D, desc: Dictionary) -> void:
	var z: float = PLINTH.z * 0.5 + PLATE.z * 0.5
	var plate: MeshInstance3D = _box(holder, PLATE, Vector3(0.0, PLINTH.y * 0.5, z), _mat(BONE, 0.15))
	plate.name = "Nameplate"
	var glyph := Label3D.new()
	glyph.name = "Numeral"
	glyph.text = String(desc["numeral"])
	glyph.font_size = 44
	glyph.pixel_size = 0.0006
	glyph.outline_size = 0
	glyph.modulate = INK
	# NOT billboarded — it lies on the plate, so LabelFramer leaves it alone.
	glyph.position = Vector3(0.0, PLINTH.y * 0.5, z + PLATE.z * 0.5 + 0.001)
	holder.add_child(glyph)


## RUNG gradation — a ruled blade beside the measured span with a tooth every 5% and a
## numbered station every quarter (every puck, on the discrete body). No index: the fluid
## surface, the knob and the top puck ARE the pointer.
func _mount_gradation(holder: Node3D, desc: Dictionary) -> void:
	var rule := Node3D.new()
	rule.name = "Rule"
	holder.add_child(rule)
	var start: Vector3 = desc["scale_start"]
	var along: Vector3 = desc["along"]
	var teeth: Vector3 = desc["teeth"]
	var flat: Vector3 = desc["flat"]
	var steps: int = maxi(int(desc["steps"]), 1)
	var major_every: int = maxi(int(desc["major_every"]), 1)
	var discrete: bool = bool(desc["discrete"])
	_box(rule, _section(along, SPAN, teeth, BLADE_W, flat, BLADE_T),
			start + along * (SPAN * 0.5), _mat(STEEL.darkened(0.45), 0.3))
	var mark: StandardMaterial3D = _mat(STEEL, 0.9)
	for k in range(steps + 1):
		var d: float = SPAN * float(k) / float(steps)
		var major: bool = (k % major_every) == 0
		var length: float = TOOTH_MAJOR if major else TOOTH_MINOR
		_box(rule, _section(teeth, length, along, TOOTH_W, flat, BLADE_T * 1.3),
				start + along * d + teeth * (BLADE_W * 0.5 + length * 0.5), mark)
		if not major:
			continue
		var glyph := Label3D.new()
		glyph.text = ("%d" % k) if discrete else _station_text(float(k) / float(steps))
		glyph.font_size = 40
		glyph.pixel_size = 0.00045
		glyph.outline_size = 0
		glyph.modulate = STEEL.lightened(0.3)
		glyph.position = start + along * d - teeth * (BLADE_W * 0.5 + 0.020)
		rule.add_child(glyph)


## RUNG lattice — a grid on the face the value is read against: GRID_ROWS cells along the
## span, and columns across a direction the value does not use. On the count body it is a
## cage: a ring at every puck height and bars around, the pucks sitting inside.
func _mount_lattice(holder: Node3D, desc: Dictionary) -> void:
	var grid := Node3D.new()
	grid.name = "Lattice"
	holder.add_child(grid)
	var wire_mat: StandardMaterial3D = _mat(WIRE_TINT, 0.9)
	if bool(desc["cage"]):
		_build_cage(grid, desc["cage_base"], float(desc["cage_radius"]), int(desc["steps"]), wire_mat)
		return
	var origin: Vector3 = desc["grid_origin"]
	var along: Vector3 = desc["along"]
	var across: Vector3 = desc["grid_across"]
	var flat: Vector3 = desc["flat"]
	var width: float = float(desc["grid_width"])
	var cols: int = maxi(int(desc["grid_cols"]), 1)
	for i in range(GRID_ROWS + 1):
		var d: float = SPAN * float(i) / float(GRID_ROWS)
		_box(grid, _section(across, width, along, WIRE, flat, WIRE),
				origin + along * d + across * (width * 0.5), wire_mat)
	for j in range(cols + 1):
		var w: float = width * float(j) / float(cols)
		_box(grid, _section(along, SPAN, across, WIRE, flat, WIRE),
				origin + across * w + along * (SPAN * 0.5), wire_mat)


func _build_cage(host: Node3D, base: Vector3, r: float, rings: int, mat: StandardMaterial3D) -> void:
	var n: int = maxi(rings, 1)
	for k in range(n + 1):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - WIRE * 0.5
		tm.outer_radius = r + WIRE * 0.5
		tm.rings = 40
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position = base + Vector3(0.0, SPAN * float(k) / float(n), 0.0)
		host.add_child(ring)
	var bars: int = 8
	for b in range(bars):
		var ang: float = TAU * float(b) / float(bars)
		_box(host, Vector3(WIRE, SPAN, WIRE),
				base + Vector3(cos(ang) * r, SPAN * 0.5, sin(ang) * r), mat)


## Station text on a continuous rule: 0  .25  .5  .75  1 — the fraction with the leading
## zero and any trailing zero dropped, so a quarter reads as a quarter and not as "0.25".
func _station_text(f: float) -> String:
	if absf(f) < 0.001:
		return "0"
	if absf(f - 1.0) < 0.001:
		return "1"
	var s: String = "%.2f" % f
	s = s.trim_prefix("0")
	if s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	return s


# ── geometry helpers ─────────────────────────────────────────────────────────

## A box size that runs `la` along unit vector `a`, `lb` along `b`, `lc` along `c`. Only
## meaningful for axis-aligned unit vectors, which is all this file ever passes.
func _section(a: Vector3, la: float, b: Vector3, lb: float, c: Vector3, lc: float) -> Vector3:
	return a.abs() * la + b.abs() * lb + c.abs() * lc


func _box(host: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(maxf(size.x, 0.0005), maxf(size.y, 0.0005), maxf(size.z, 0.0005))
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(mi)
	return mi


func _cyl(host: Node3D, r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(h, 0.0005)
	cm.radial_segments = 24
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	host.add_child(mi)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m


func _glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = GLASS
	m.roughness = 0.12
	m.metallic = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
