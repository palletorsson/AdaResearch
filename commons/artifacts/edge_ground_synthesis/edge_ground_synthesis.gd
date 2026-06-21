extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EdgeGroundSynthesis

## @identity
## name: Edge-Ground Synthesis — Every Limit, Made Into Ground
## concept: The edge is the ground
## tier: applied
## lineage: post-crisis synthesis — the trilogy's closing device. The whole arc named four
##   limits that read, in crisis, as failures: INCOMPLETENESS (no system proves itself — Gödel),
##   BIAS (every standpoint is partial — no view from nowhere), CONTRADICTION (the merge conflict,
##   the held-together opposites), and RHIZOME (no centre to ground authority). The synthesis is
##   to stop treating each as a wound and start treating it as stock: incompleteness becomes
##   open-endedness to build into, bias becomes situated knowledge, contradiction becomes the
##   joint that holds tension, rhizome becomes resilient connection. Each limit, fed into the
##   constructive core, becomes the ground the next thing is built on.
## essence: a ~1 m device. Four intake ports ring a central core. At each port a limit-token
##   starts RED (a problem) and, drawn into the core, transmutes to warm amber/teal (a material).
##   A stream of converted material flows from each port into the single bright core, which grows
##   and pulses as it is fed. A readout cycles "INCOMPLETENESS -> MATERIAL", "BIAS -> MATERIAL",
##   "CONTRADICTION -> MATERIAL", "RHIZOME -> MATERIAL", and rests on "EVERY LIMIT -> GROUND".
## truth: every limit, made into ground. The edge that read as failure is fed into the core and
##   comes out as the material you build the next thing from.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var problem_red: Color = Color(0.95, 0.30, 0.30)    # the limit read as a problem
@export var material_amber: Color = Color(0.98, 0.72, 0.32) # the limit converted to stock
@export var material_teal: Color = Color(0.35, 0.88, 0.80)  # constructive accent
@export var cycle_period: float = 2.2                       # seconds per limit in the readout
@export var packet_period: float = 0.18                     # seconds between flow packets

var _t: float = 0.0
var _origin := Vector3(0.0, 0.95, 0.0)
var _ports: Array = []           # {label:String, ang:float, token:MeshInstance3D, tmat:StandardMaterial3D, convert:float}
var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _packets: Array = []         # {mesh:MeshInstance3D, from:Vector3, to:Vector3, life:float}
var _readout: Label3D
var _active: int = 0
var _cycle_accum: float = 0.0
var _packet_accum: float = 0.0
var _core_charge: float = 0.0

const LIMITS: Array = ["INCOMPLETENESS", "BIAS", "CONTRADICTION", "RHIZOME"]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cycle_period"):
		cycle_period = float(config["cycle_period"])
	if config.has("packet_period"):
		packet_period = float(config["packet_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_ports = []
	_packets = []
	_active = 0
	_cycle_accum = 0.0
	_packet_accum = 0.0
	_core_charge = 0.0
	_t = 0.0

	# --- compact device body (~1 m) ---
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 1.0), _matte_mat(slate, 0.85, 0.15)))
	add_child(_cylinder(Vector3(0.0, 0.66, 0.0), 0.05, 0.5, _steel_mat(Color(0.34, 0.36, 0.42))))
	# rim ring linking the four ports to the core
	add_child(_torus(_origin, 0.42, 0.006, _glow_mat(wire_purple, 1.0)))
	# core pedestal
	add_child(_cylinder(_origin + Vector3(0.0, -0.06, 0.0), 0.1, 0.04, _glow_mat(material_teal, 1.2)))

	# --- the constructive CORE (single bright node fed by all four limits) ---
	_core_mat = _glow_mat(material_teal, 2.4)
	_core = _sphere(_origin, 0.1, _core_mat)
	add_child(_core)

	# --- four intake ports, one per limit, around the rim ---
	var i: int = 0
	while i < LIMITS.size():
		var ang: float = float(i) / float(LIMITS.size()) * TAU
		var ppos: Vector3 = _origin + Vector3(cos(ang) * 0.42, 0.0, sin(ang) * 0.42)
		# the limit-token: starts RED (a problem), will transmute to material
		var tmat: StandardMaterial3D = _glow_mat(problem_red, 1.8)
		var token: MeshInstance3D = _box(ppos, Vector3(0.07, 0.07, 0.07), tmat)
		add_child(token)
		# a small port plinth
		add_child(_cylinder(ppos + Vector3(0.0, -0.05, 0.0), 0.05, 0.03, _glow_mat(wire_purple, 0.8)))
		# label under each port
		add_child(_billboard_label(String(LIMITS[i]), ppos + Vector3(0.0, 0.14, 0.0), 12, cool_white))
		_ports.append({"label": String(LIMITS[i]), "ang": ang, "token": token, "tmat": tmat, "convert": 0.0, "pos": ppos})
		i += 1

	# --- readout ---
	_readout = _billboard_label("THE EDGE IS THE GROUND\nINCOMPLETENESS -> MATERIAL", _origin + Vector3(0.0, 0.95, 0.0), 22, material_teal)
	add_child(_readout)
	add_child(_billboard_label("every limit, made into ground", _origin + Vector3(0.0, 0.68, 0.0), 14, wire_purple))


func _spawn_packet(from: Vector3) -> void:
	# a converted-material packet flowing from a port into the core
	var col: Color = material_amber.lerp(material_teal, _rng.randf())
	var pkt: MeshInstance3D = _sphere(from, 0.02, _glow_mat(col, 2.4))
	add_child(pkt)
	_packets.append({"mesh": pkt, "from": from, "to": _origin, "life": 0.0})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# --- cycle which limit is being converted; update the readout ---
	_cycle_accum += delta
	if _cycle_accum >= cycle_period:
		_cycle_accum = 0.0
		_active = (_active + 1) % LIMITS.size()
		if _readout != null:
			_readout.text = "THE EDGE IS THE GROUND\n%s -> MATERIAL" % String(LIMITS[_active])

	# --- the active port converts: token lerps red -> material, and emits flow packets ---
	var i: int = 0
	while i < _ports.size():
		var pd: Dictionary = _ports[i]
		var target: float = 1.0 if i == _active else 0.15
		pd["convert"] = lerpf(float(pd["convert"]), target, delta * 2.0)
		var conv: float = float(pd["convert"])
		var tm: StandardMaterial3D = pd["tmat"]
		# red (problem) -> amber/teal (material) as it converts
		var matcol: Color = material_amber.lerp(material_teal, 0.4)
		tm.albedo_color = problem_red.lerp(matcol, conv)
		tm.emission = problem_red.lerp(matcol, conv)
		tm.emission_energy_multiplier = (1.4 + 1.4 * conv) if emissive else 0.3
		# spin the active token as it is drawn in
		var tok: MeshInstance3D = pd["token"]
		if is_instance_valid(tok):
			tok.rotation.y += delta * (0.5 + 3.0 * conv)
			tok.rotation.x += delta * (0.3 + 2.0 * conv)
		i += 1

	# --- emit flow packets from the active port toward the core ---
	_packet_accum += delta
	if _packet_accum >= packet_period:
		_packet_accum = 0.0
		if _active >= 0 and _active < _ports.size():
			var ap: Dictionary = _ports[_active]
			_spawn_packet(Vector3(ap["pos"]))

	# --- advance packets; when they reach the core, charge it ---
	var p: int = _packets.size() - 1
	while p >= 0:
		var pk: Dictionary = _packets[p]
		pk["life"] = float(pk["life"]) + delta * 3.0
		var life: float = float(pk["life"])
		var m: MeshInstance3D = pk["mesh"]
		if life >= 1.0:
			if is_instance_valid(m):
				m.queue_free()
			_packets.remove_at(p)
			_core_charge = minf(1.0, _core_charge + 0.08)
		else:
			if is_instance_valid(m):
				m.position = (Vector3(pk["from"])).lerp(Vector3(pk["to"]), life)
		p -= 1

	# --- the core grows and pulses as it is fed (it is being built up from the limits) ---
	_core_charge = maxf(0.0, _core_charge - delta * 0.15)
	if is_instance_valid(_core):
		var pulse: float = 0.5 + 0.5 * sin(_t * 3.0)
		var s: float = 1.0 + 0.5 * _core_charge + 0.06 * pulse
		_core.scale = Vector3.ONE * s
		_core.rotation.y += delta * 0.6
	if _core_mat != null:
		_core_mat.albedo_color = material_amber.lerp(material_teal, 0.5 + 0.3 * _core_charge)
		_core_mat.emission = material_amber.lerp(material_teal, 0.5 + 0.3 * _core_charge)
		_core_mat.emission_energy_multiplier = (2.0 + 2.5 * _core_charge) if emissive else 0.4
