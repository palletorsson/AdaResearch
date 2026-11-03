class_name TheUnit
extends Node3D
## THE UNIT (Palle, 2026-11-03): a small robot with only three controllable actions - drive forward or back, turn its
## chassis, turn an independent hub that carries attachments - and the question whether two identical units joined by
## a rod become a third thing, a drawing mechanism made by their relationship. The model and the rule are unit_sim.gd;
## this node draws them on a sheet of paper on the floor. What is shown is MECHANICAL coupling (Palle's level 2):
## compliant drives and a rod pulling the units into shared rates - not yet units that adapt (level 3). The pen is the
## instrument that reads the relation between the bodies.
##
##   setup  one     one unit, a pen on its hub's rim pin: a closed four-loop rosette - all one unit can make
##          apart   two identical units with the pair's starts and NO rod, a pen on each: two copies of the rosette
##                  (the control - the same units, the same rule, only the rod is missing)
##          triangle  three units, a rod between every two hubs, a plate between the rods with a pen at its centre
##                  and a pen at each rod's middle; with a tighter own circle (w0 0.8) every start tried settles into
##                  one relation, the four pens weaving a spirograph ring (unit_sim.gd, TRIANGLES)
##          pair    the same two units joined hub pin to hub pin by a 1 m rod, the pen at the rod's middle: within a
##                  few minutes the rod pulls them into a relation neither programme contains (most starts settle in
##                  about ten minutes; a second relation exists); the pen spirals inwards, then keeps to a ring
##   arrangement  c | parallel | crossed | facing - how the pair starts (facing, mirror-symmetric, is the second mode,
##          point-symmetric: the pen stays put until rounding error breaks the symmetry, then the fence or the button
##          starts the next drawing);
##          the button on the stem steps to the next one and starts the drawing again
##   scale_factor  the whole machine and its drawing, model metres to metres; 0 = by setup (0.7 - a unit 28 cm long,
##          the pair's ring about 3 m - and 1.0 for the triangle, whose drawing is about 1.2 m)
##
## Each unit: an open frame on two wheels and a front caster, its rails wide enough that the hub pin's circle never
## crosses them, a mast and boom holding a turntable hub 12 cm ahead of the axle from above, a pin on its rim; a pen
## drops from the pin through the open middle to the paper, a rod joins two pins under the boom. Wheels turn with
## the drive. The ink is one MultiMesh per pen (append-only, a ring that overwrites its oldest marks after `capacity`),
## one draw call each, no texture uploads. A readout over the button names the relation as it forms: the units' own
## turn and hub rates against the programmed 0.25 and 1.0 rad/s, the distance between them, the rod's stretch.
## get_state() reports the same. Bench: commons/testing/probe_the_unit.tscn.

const Sim := preload("res://commons/artifacts/the_unit/unit_sim.gd")
const INKS := [Color("1d2846"), Color("c8402e"), Color("2f5fa8"), Color("1f8f6a")]

@export_enum("pair", "triangle", "apart", "one") var setup := "pair"
@export var arrangement := "c"      ## pair/apart: c, parallel, crossed, facing; triangle: c, scattered, drifted, tangent
@export var scale_factor := 0.0     ## model metres to metres; 0 = by setup
@export var paper := 0.0            ## side of the square sheet, metres; 0 = by setup (pair 3.6, triangle 2.8, apart 2.6, one 1.6)
@export var pen_frac := 0.5         ## where the pen sits on the rod, from unit 1's pin
@export var capacity := 6000        ## ink segments per pen before the oldest are overwritten
@export var show_button := true
@export var show_readout := true
@export var lamp := true
@export var running := true

var sim: RefCounted
var field: Node3D                   ## everything in model metres, scaled by scale_used()
var _plate: MeshInstance3D          ## the triangle's plate between its rods
var button: Node3D
var readout: Label3D
var _units: Array = []              ## per unit {root, hub, wheels: [l, r], spin: [l, r]}
var _rods: Array = []               ## per rod {mesh}
var _pens: Array = []               ## per pen {holder, mm: MultiMesh, last: Vector2, has_last, count, next}
var _built_key := ""
var _readout_clock := 0.0
var _avg := {}                      ## 10 s running means for the readout: w, h per unit, distance, heading (cos, sin)
const AVG_SECONDS := 10.0

const SPACING := 0.008              ## model metres between ink marks
const WIDTH := 0.012                ## model metres, ink line width
const PIN_TOP := 0.25               ## model height of the pin tops, where rods attach (under the boom at 0.33)
const HUB_Y := 0.19                 ## model height of the turntable's middle
const WHEEL_R := 0.06
const TRACK := 0.47                 ## wheel to wheel, outside the rails at +-0.20
## How far a unit may wander from the station's centre, in MODEL metres, before the drawing starts again: past every
## start's measured excursion, and fixed, so a different paper or scale cannot move the fence onto a drawing.
const FENCE := {"pair": 3.2, "apart": 2.6, "one": 1.5, "triangle": 1.9}

const KEYS := ["setup", "arrangement", "scale_factor", "paper", "pen_frac", "capacity", "show_button", "show_readout", "lamp", "running"]

## Config from a map or a hall sidecar: each value coerced to its property's type (a JSON number is a float, and a
## typed property refuses a wrong type in silence), unknown setups and arrangements refused aloud.
func apply_grid_config(config: Dictionary) -> void:
	for key in KEYS:
		if not config.has(key):continue
		var val = config[key]
		match typeof(get(key)):
			TYPE_INT:val = int(val)
			TYPE_FLOAT:val = float(val)
			TYPE_BOOL:val = bool(val)
			TYPE_STRING:val = str(val)
		if key == "setup" and not val in ["pair", "triangle", "apart", "one"]:
			push_warning("TheUnit: unknown setup '%s'" % val);continue
		set(key, val)
	capacity = maxi(capacity, 64)
	if not Sim.has_arrangement(setup, arrangement):
		push_warning("TheUnit: no arrangement '%s' for %s - using c" % [arrangement, setup]);arrangement = "c"
	_rebuild_if_changed()

func _ready() -> void:
	var config := {}
	for key in KEYS:
		if has_meta("config_" + key):config[key] = get_meta("config_" + key)
	apply_grid_config(config)
	_rebuild_if_changed()

func _key() -> String:
	return "%s|%s|%.3f|%.3f|%.3f|%d|%s|%s|%s" % [setup, arrangement, scale_factor, paper, pen_frac, capacity, show_button, show_readout, lamp]

func _rebuild_if_changed() -> void:
	if not is_inside_tree() or _key() == _built_key:return
	_built_key = _key()
	for c in get_children():
		remove_child(c);c.free()
	_units.clear();_rods.clear();_pens.clear();_plate = null
	_avg.clear();_readout_clock = 0.0
	_build()

func paper_side() -> float:
	if paper > 0.0:return paper
	return {"pair": 3.6, "triangle": 2.8, "apart": 2.6, "one": 1.6}.get(setup, 3.6)

func scale_used() -> float:
	if scale_factor > 0.0:return scale_factor
	return 1.0 if setup == "triangle" else 0.7

## Start the drawing again from `arrangement` (or the next one when `step` is true): a fresh model, clean paper.
func restart(step := false) -> void:
	if step and setup != "one":
		var order: Array = Sim.order(setup)
		arrangement = order[(order.find(arrangement) + 1) % order.size()]
		_built_key = _key()
	sim = Sim.make(setup, arrangement, {}, pen_frac)
	_avg.clear()
	for pen in _pens:
		pen.count = 0;pen.next = 0;pen.has_last = false
		(pen.mm as MultiMesh).visible_instance_count = 0
	_sync()

func _build() -> void:
	var side := paper_side()
	var sf := scale_used()
	field = Node3D.new();field.name = "Field";field.scale = Vector3.ONE * sf;add_child(field)
	# the paper, a few millimetres over the floor
	var sheet := MeshInstance3D.new();sheet.name = "Paper";var pm := PlaneMesh.new();pm.size = Vector2(side, side);sheet.mesh = pm
	sheet.material_override = _mat(Color("f3efe6"), .0, .9);sheet.position.y = .006;add_child(sheet)
	var edge := MeshInstance3D.new();edge.name = "PaperEdge";var em := BoxMesh.new();em.size = Vector3(side + .06, .004, side + .06);edge.mesh = em
	edge.material_override = _mat(Color("2b2f33"), .0, .8);edge.position.y = .002;add_child(edge)   # 0..4 mm, under the sheet at 6 mm
	sim = Sim.make(setup, arrangement, {}, pen_frac)
	var frame_mat := _mat(Color("3a3f45"), .6, .4)
	var hub_mat := _mat(Color("c9a46a"), .5, .45)   # brass: the turntable reads against the paper
	var stripe_mat := _mat(Color("d8432e"), .0, .5)
	var rubber := _mat(Color("1b1b1b"), .0, .9)
	for i in sim.units.size():
		var root := Node3D.new();root.name = "Unit%d" % i;field.add_child(root)
		# the open frame: the pin circles r_pin round the hub (x -0.03..0.27, z +-0.15), so the rails stand at z +-0.20,
		# the bars at x -0.09 and 0.33, stub axles reach out to the wheels, and a mast at the back carries the hub on a
		# boom from above (0.33 m up, over the rods at 0.25) - nothing crosses the pen's path
		var hx: float = float(sim.P.a_hub)
		_box(root, "RailL", Vector3(.44, .025, .02), Vector3(.12, .075, .20), frame_mat)
		_box(root, "RailR", Vector3(.44, .025, .02), Vector3(.12, .075, -.20), frame_mat)
		_box(root, "FrontBar", Vector3(.02, .025, .42), Vector3(.33, .075, 0), frame_mat)
		_box(root, "BackBar", Vector3(.02, .025, .42), Vector3(-.09, .075, 0), frame_mat)
		_box(root, "AxleL", Vector3(.02, .02, .05), Vector3(0, WHEEL_R, .22), frame_mat)
		_box(root, "AxleR", Vector3(.02, .02, .05), Vector3(0, WHEEL_R, -.22), frame_mat)
		_cyl(root, "Mast", .012, .27, Vector3(-.09, .075 + .135, 0), frame_mat)
		_box(root, "Boom", Vector3(hx + .11, .02, .025), Vector3((hx - .09) / 2.0, .335, 0), frame_mat)
		_cyl(root, "Spindle", .01, .135, Vector3(hx, HUB_Y + .01 + .0675, 0), frame_mat)
		_cyl(root, "CasterPost", .008, .05, Vector3(.33, .05, 0), frame_mat)
		_sphere(root, "Caster", .02, Vector3(.33, .02, 0), rubber)
		var wheels := []
		for s in [-1.0, 1.0]:
			# local -z is the model's right side, local +z its left (root.rotation.y = -heading)
			var w := Node3D.new();w.name = "Wheel%s" % ("R" if s < 0 else "L");w.position = Vector3(0, WHEEL_R, s * TRACK / 2.0);root.add_child(w)
			var tyre := _cyl(w, "Tyre", WHEEL_R, .03, Vector3.ZERO, rubber);tyre.rotation.x = PI / 2
			_box(w, "Spoke", Vector3(WHEEL_R * 1.6, .012, .032), Vector3.ZERO, frame_mat)
			wheels.append(w)
		# the hub: a turntable, a red stripe from the centre to the pin, the pin on its rim
		var hub := Node3D.new();hub.name = "Hub";hub.position = Vector3(hx, HUB_Y, 0);root.add_child(hub)
		_cyl(hub, "Disc", .17, .02, Vector3.ZERO, hub_mat)
		_box(hub, "Stripe", Vector3(float(sim.P.r_pin), .004, .025), Vector3(float(sim.P.r_pin) / 2.0, .012, 0), stripe_mat)
		_cyl(hub, "Pin", .014, PIN_TOP - HUB_Y, Vector3(float(sim.P.r_pin), (PIN_TOP - HUB_Y) / 2.0, 0), frame_mat)
		_units.append({"root": root, "hub": hub, "wheels": wheels, "spin": [0.0, 0.0]})
	for j in sim.rods.size():
		var bar := _cyl(field, "Rod%d" % j, .012, 1.0, Vector3.ZERO, _mat(Color("6f7880"), .7, .35))
		_rods.append({"mesh": bar})
	if setup == "triangle":
		_plate = MeshInstance3D.new();_plate.name = "Plate";_plate.mesh = ImmediateMesh.new()
		var pmat := StandardMaterial3D.new();pmat.albedo_color = Color(.85, .82, .74, .55);pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pmat.cull_mode = BaseMaterial3D.CULL_DISABLED;_plate.material_override = pmat;field.add_child(_plate)
	for j in sim.pens.size():
		var ink: Color = INKS[j] if setup == "triangle" else (INKS[0] if setup == "pair" else (INKS[1] if j == 0 else INKS[2]))
		var holder := Node3D.new();holder.name = "Pen%d" % j;field.add_child(holder)
		var on_rod: bool = sim.pens[j].has("rod") or sim.pens[j].has("plate")
		var top := PIN_TOP if on_rod else HUB_Y - .01   # a hub pen hangs from the pin, under the turntable
		_cyl(holder, "Barrel", .011, top - .02, Vector3(0, (top - .02) / 2.0 + .02, 0), _mat(Color("dcd6c8"), .0, .6))
		_cyl(holder, "Tip", .006, .03, Vector3(0, .015, 0), _mat(ink, .0, .5))
		var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D
		var seg := PlaneMesh.new();seg.size = Vector2(1.0, WIDTH);mm.mesh = seg   # two triangles a mark, flat on the paper
		mm.instance_count = capacity;mm.visible_instance_count = 0
		var half := side / sf / 2.0 + .5
		mm.custom_aabb = AABB(Vector3(-half, 0, -half), Vector3(half * 2.0, .02, half * 2.0))
		var mi := MultiMeshInstance3D.new();mi.name = "Ink%d" % j;mi.multimesh = mm
		var im := StandardMaterial3D.new();im.albedo_color = ink;im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = im;mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;mi.position.y = .008 / sf   # 8 mm: over the sheet
		field.add_child(mi)
		_pens.append({"holder": holder, "mm": mm, "last": Vector2.ZERO, "has_last": false, "count": 0, "next": 0})
	if lamp:
		var light := OmniLight3D.new();light.name = "Lamp";light.position = Vector3(0, 2.3, 0);light.omni_range = side * 1.1 + 1.0
		light.light_energy = 1.2;light.shadow_enabled = false;add_child(light)
	if show_button or show_readout:_build_furniture(side)
	_sync()

func _build_furniture(side: float) -> void:
	var front := Vector3(0, 0, side / 2.0 + .45)
	if show_button:
		var stem := _cyl(self, "Stem", .022, .9, front + Vector3(0, .45, 0), _mat(Color("8d9e9a"), .0, .6))
		stem.name = "Stem"
		_box(self, "Plate", Vector3(.3, .02, .2), front + Vector3(0, .9, 0), _mat(Color("263638"), .0, .6))
		var scene: PackedScene = load("res://commons/interactables/push_button.tscn")
		button = scene.instantiate();button.name = "NextButton";add_child(button)
		button.rotation = Vector3.ZERO;button.position = front + Vector3(0, .91, 0)   # cap up, on the plate
		if button.has_signal("pressed"):button.pressed.connect(func(): restart(true))
	if show_readout:
		readout = Label3D.new();readout.name = "Readout";readout.font_size = 26;readout.pixel_size = .0035;readout.modulate = Color("e5efe9")
		readout.outline_size = 6;readout.outline_modulate = Color(0, 0, 0, .7)
		readout.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y;readout.position = front + Vector3(0, 1.4, 0);add_child(readout)

func _physics_process(delta: float) -> void:
	if sim == null or not running:return
	var before: float = sim.time
	sim.advance(delta)
	var dt: float = sim.time - before
	if dt <= 0.0:return
	_sync(dt)
	_ink()
	_average(dt)
	_fence()
	_readout_clock += delta
	if _readout_clock >= .5 and readout != null:
		_readout_clock = 0.0
		readout.text = _readout_text()

## Draw `seconds` of the model at once, inking every tick (a probe's fast-forward; also a pre-warmed sheet).
func run_for(seconds: float) -> void:
	for i in int(round(seconds / Sim.DT)):
		sim.tick()
		_ink()
		_average(Sim.DT)
		_fence()
	_sync(Sim.DT)
	if readout != null:readout.text = _readout_text()

## Pose the units, the hubs, the wheels, the rods and the pens from the model.
func _sync(dt := 0.0) -> void:
	for i in _units.size():
		var u: Dictionary = sim.units[i]
		var view: Dictionary = _units[i]
		var root: Node3D = view.root
		root.position = Vector3(float(u.x), 0, float(u.z))
		root.rotation = Vector3(0, -float(u.th), 0)
		(view.hub as Node3D).rotation = Vector3(0, -float(u.ph), 0)
		var cmd: Vector3 = u.cmd
		for s in 2:
			var side := 1.0 if s == 0 else -1.0   # wheel 0 is on the right: turning left, it is the outer wheel
			var rim := cmd.x + cmd.y * side * TRACK / 2.0   # each wheel's ground speed
			view.spin[s] = float(view.spin[s]) + rim * dt / WHEEL_R
			(view.wheels[s] as Node3D).rotation = Vector3(0, 0, -float(view.spin[s]))
	for j in _rods.size():
		var rod: Dictionary = sim.rods[j]
		var a: Vector2 = sim.pin(int(rod.a))
		var b: Vector2 = sim.pin(int(rod.b))
		_stretch_between((_rods[j].mesh as MeshInstance3D), Vector3(a.x, PIN_TOP, a.y), Vector3(b.x, PIN_TOP, b.y))
	for j in _pens.size():
		var p: Vector2 = sim.pen_point(j)
		(_pens[j].holder as Node3D).position = Vector3(p.x, 0, p.y)
	if _plate != null:
		var im: ImmediateMesh = _plate.mesh
		im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 3:
			var q: Vector2 = sim.pin(i)
			im.surface_set_normal(Vector3.UP);im.surface_add_vertex(Vector3(q.x, PIN_TOP - .006, q.y))
		im.surface_end()

## Lay ink where each pen has moved at least SPACING since its last mark.
func _ink() -> void:
	for j in _pens.size():
		var pen: Dictionary = _pens[j]
		var p: Vector2 = sim.pen_point(j)
		if not pen.has_last:
			pen.last = p;pen.has_last = true
			continue
		var a: Vector2 = pen.last
		var d := p.distance_to(a)
		if d < SPACING:continue
		var dir := (p - a) / d
		var basis := Basis(Vector3(dir.x, 0, dir.y) * d, Vector3.UP, Vector3(-dir.y, 0, dir.x))
		var mm: MultiMesh = pen.mm
		mm.set_instance_transform(int(pen.next), Transform3D(basis, Vector3((a.x + p.x) * .5, 0, (a.y + p.y) * .5)))
		pen.next = (int(pen.next) + 1) % capacity
		pen.count = mini(int(pen.count) + 1, capacity)
		mm.visible_instance_count = int(pen.count)
		pen.last = p

## Running means over about AVG_SECONDS: the relation breathes, the means show where it settles.
func _average(dt: float) -> void:
	var a := 1.0 - exp(-dt / AVG_SECONDS)
	var sample := {}
	for i in sim.units.size():
		var c: Vector3 = sim.units[i].cmd
		sample["w%d" % i] = c.y;sample["h%d" % i] = c.z
	if sim.units.size() == 2:
		var u0: Dictionary = sim.units[0];var u1: Dictionary = sim.units[1]
		sample["d"] = Vector2(float(u0.x), float(u0.z)).distance_to(Vector2(float(u1.x), float(u1.z)))
		var dh := float(u0.th) - float(u1.th)
		sample["hc"] = cos(dh);sample["hs"] = sin(dh)
	for k in sample:
		_avg[k] = float(sample[k]) if not _avg.has(k) else lerpf(float(_avg[k]), float(sample[k]), a)

## If a unit wanders off its paper (a start that never settles), begin again from the next arrangement.
func _fence() -> void:
	var limit: float = FENCE.get(setup, 3.2)
	for u in sim.units:
		if absf(float(u.x)) > limit or absf(float(u.z)) > limit:
			restart(true)
			return

func _stretch_between(mesh: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	if l < 1e-6:return
	var y := d / l
	var x := Vector3.UP.cross(y)
	if x.length_squared() < 1e-6:x = Vector3.RIGHT
	x = x.normalized()
	mesh.transform = Transform3D(Basis(x, y * l, x.cross(y)), (a + b) * .5)

## The relation as numbers: what each unit is doing against its programme, and what holds them.
func get_state() -> Dictionary:
	var units := []
	for u in sim.units:
		var c: Vector3 = u.cmd
		units.append({"x": float(u.x), "z": float(u.z), "v": c.x, "w": c.y, "h": c.z, "skid_m": float(u.skid)})
	var state := {"setup": setup, "arrangement": arrangement, "time": float(sim.time), "units": units,
		"ink": _pens.map(func(p): return int(p.count)), "program": [float(sim.P.v0), float(sim.P.w0), float(sim.P.h0)]}
	if sim.units.size() == 2:
		var a: Dictionary = sim.units[0]
		var b: Dictionary = sim.units[1]
		state["distance_m"] = Vector2(float(a.x), float(a.z)).distance_to(Vector2(float(b.x), float(b.z)))
		state["rel_heading_deg"] = rad_to_deg(wrapf(float(a.th) - float(b.th), -PI, PI))
		state["hub_phase_deg"] = rad_to_deg(wrapf(float(a.th) + float(a.ph) - float(b.th) - float(b.ph), -PI, PI))
	if sim.rods.size() > 0:
		state["stretch_mm"] = float(sim.stretch(0)) * 1000.0
	state["means_10s"] = _avg.duplicate()
	return state

func _readout_text() -> String:
	var s := get_state()
	var title: String = {"pair": "THE UNIT - two units, one rod", "triangle": "THE UNIT - three units, a triangle of rods", "apart": "THE UNIT - two units, no rod", "one": "THE UNIT - one unit, a pen"}.get(setup, "THE UNIT")
	var lines := [title, "programmed: turn %.2f  hub %.2f rad/s" % [float(sim.P.w0), float(sim.P.h0)]]
	for i in (s.units as Array).size():
		lines.append("unit %d, last 10 s: turn %.2f  hub %.2f" % [i + 1, float(_avg.get("w%d" % i, 0.0)), float(_avg.get("h%d" % i, 0.0))])
	if _avg.has("d"):
		lines.append("%.2f m apart, %.0f deg between headings" % [float(_avg.d) * scale_used(), rad_to_deg(atan2(float(_avg.hs), float(_avg.hc)))])
	if setup != "one":
		lines.append("start: %s  -  press for the next" % arrangement)
	return "\n".join(lines)

func _mat(c: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color = c;m.metallic = metal;m.roughness = rough
	return m

func _box(parent: Node, n: String, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new();mi.name = n;var bm := BoxMesh.new();bm.size = size;mi.mesh = bm;mi.material_override = mat;mi.position = at
	parent.add_child(mi)
	return mi

func _cyl(parent: Node, n: String, r: float, h: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new();mi.name = n;var cm := CylinderMesh.new();cm.top_radius = r;cm.bottom_radius = r;cm.height = h;cm.radial_segments = 16
	mi.mesh = cm;mi.material_override = mat;mi.position = at;parent.add_child(mi)
	return mi

func _sphere(parent: Node, n: String, r: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new();mi.name = n;var sm := SphereMesh.new();sm.radius = r;sm.height = r * 2.0;mi.mesh = sm;mi.material_override = mat;mi.position = at
	parent.add_child(mi)
	return mi
