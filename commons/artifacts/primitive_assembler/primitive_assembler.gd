extends Node3D
class_name PrimitiveAssembler

# @identity
# essence: an assembly line for the DNA primitives. A conveyor carries raw
#          primitives — sphere, cube, cone — in from the left; one at a time
#          each lifts off the belt and snaps onto a growing vertical stack on
#          the assembly pedestal. The "+" of assemblage made watchable: you
#          see the sum being computed, not just the finished totem.
# desire: to turn a static composition back into the algorithm that made it.
#         primitive_stack.build() runs a y_cursor loop in a single frame; this
#         externalises that loop into space and time so the player FEELS the
#         addition: ● then ● + ■ then ● + ■ + ▲.
# critical_parameter: mode — constant | gradient | relational. The same belt,
#         three readings of colour: a property, a function of index, a relation
#         to the neighbour. The colour theme's whole bloom, on one machine.
# triggers: _process drives a one-piece-at-a-time state machine
#           (travel → place → land → hold → clear → loop)
# emerges: the bridge artifact. input = primitives (theme 1); belt motion =
#          transform/array (themes 2-3); assembled colour stack = colour
#          assemblage (theme 4); "a rule that runs the belt itself" = the
#          sculpture gallery. One station narrates the spine.
# needs: a clean industrial belt with directional arrows [present]; an
#        illuminated assembly pedestal [present]; the DNA alphabet, reused
#        verbatim from primitive_stack [present]; a live formula placard that
#        assembles in step with the stack [present]
# relationships: child of primitive_stack (borrows _make_primitive); remake of
#        the canon_conveyor interaction (ghost stack → snap → roll out), but
#        generalised from canon art to the raw alphabet; cousin to conveyor_belt
#        (shares the "direction is grammar" vocabulary)
# truth: assemblage is a verb. A stack is not an object you find — it is an
#        addition you run. The belt is the plus sign.

const PrimStack = preload("res://commons/primitive_grammar/primitive_stack.gd")
const ConveyorBeltScene = preload("res://commons/artifacts/conveyor_belt/conveyor_belt.tscn")

# ── DNA ────────────────────────────────────────────────────────────────
## The primitives that ride in, in order, bottom of the stack first.
@export var sequence: Array[String] = ["cuboid", "cube", "cylinder", "sphere", "cone"]
## Palette name (bauhaus | wood | mono | pastel | metafora).
@export var palette: String = "bauhaus"
## Colour reading: constant (property) | gradient (f index) | relational (neighbour).
@export var mode: String = "gradient"
## Base size of a primitive unit.
@export var base_scale: float = 0.34

@export_group("Belt")
@export var belt_length: float = 2.8
@export var belt_width: float = 0.7
@export var belt_height: float = 0.52
@export var arrow_count: int = 7
@export var accent_color: Color = Color(0.98, 0.62, 0.12)   # warm assembly accent

@export_group("Timing")
@export var travel_time: float = 1.6
@export var place_time: float = 0.9
@export var land_time: float = 0.28
@export var hold_time: float = 2.6
@export var clear_time: float = 1.1
@export var loop: bool = true

@export_group("Labels")
@export var show_formula: bool = true
@export var title_text: String = "ASSEMBLY"

@export_group("Machine Body")
## Master toggle for the whole sci-fi industrial shell. Off = bare belt + pedestal.
@export var show_machine_body: bool = true
## Tall light-grey cabinet the belt feeds into (with hazard band, beacon, glass panel).
@export var show_housing: bool = true
## Angled control desk: monitor + keyboard + button panel.
@export var show_control_station: bool = true
## Right-hand darker cabinet with circular gauge + arching pipes.
@export var show_gauge_cabinet: bool = true
## Small operator stool beside the control station.
@export var show_stool: bool = true
## Two blue gas cylinders with red hazard-diamond label, far right.
@export var show_cylinders: bool = true
## Thin cylindrical legs + feet raising the in-feed belt off the floor.
@export var show_belt_legs: bool = true
## Overall machine palette — clean light-grey panels.
@export var panel_color: Color = Color(0.78, 0.79, 0.81)
## Dark metal trim / seams / bolts.
@export var trim_color: Color = Color(0.16, 0.17, 0.20)
## Blue accent stripe colour used across the shell.
@export var machine_accent: Color = Color(0.15, 0.42, 0.85)

# ── Geometry anchors (computed in _build) ──────────────────────────────
var _belt_x0: float        # spawn end of belt (-X)
var _belt_x1: float        # pickup end of belt (=0)
var _deck_y: float
var _pedestal_x: float = 0.9
var _pedestal_top_y: float

# ── Runtime state ──────────────────────────────────────────────────────
var _stack_root: Node3D
var _active: MeshInstance3D = null
var _active_mat: StandardMaterial3D = null
var _index: int = 0
var _phase: String = "idle"
var _t: float = 0.0
var _cursor_y: float = 0.0          # top of the growing stack, above pedestal
var _start_pos: Vector3
var _target_pos: Vector3
var _active_height: float = 0.0
var _formula_parts: Array[String] = []
var _formula_label: Label3D
var _arrow_mat: StandardMaterial3D
var _accent_light: OmniLight3D
var _elapsed: float = 0.0

# ── Machine-body refs (procedural shell) ───────────────────────────────
var _machine_root: Node3D
var _beacon_mat: StandardMaterial3D       # pulsing beacon material
var _beacon_light: OmniLight3D            # soft pulse light at the beacon
var _glass_bars_mat: StandardMaterial3D   # emissive bars behind the glass panel
var _screen_texture: ImageTexture         # drawn once, reused on the monitor
# Shared procedural materials (built once per _build, reused across parts).
var _mat_panel: StandardMaterial3D
var _mat_trim: StandardMaterial3D
var _mat_accent: StandardMaterial3D
var _mat_dark_metal: StandardMaterial3D

const GLYPHS := {
	"sphere": "●", "cube": "■", "cuboid": "▬", "cylinder": "▮",
	"cone": "▲", "hemisphere": "◗", "disc": "⬭", "wedge": "◣",
	"bipyramid": "◆", "prism": "⬟",
}


func _ready() -> void:
	_read_overrides()
	_build_belt()
	_build_pedestal()
	_build_machine_body()
	_build_lighting()
	_build_labels()
	_stack_root = Node3D.new()
	_stack_root.name = "StackRoot"
	add_child(_stack_root)
	_reset_cycle()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("sequence"):
		var raw = config["sequence"]
		if raw is String:
			var arr: Array[String] = []
			for s in str(raw).split(",", false):
				arr.append(s.strip_edges())
			sequence = arr
		elif raw is Array:
			var arr2: Array[String] = []
			for s in raw:
				arr2.append(str(s))
			sequence = arr2
	if config.has("palette"): palette = str(config["palette"])
	if config.has("mode"): mode = str(config["mode"])
	if config.has("base_scale"): base_scale = float(config["base_scale"])
	if config.has("title_text"): title_text = str(config["title_text"])
	# Uniform scale: applied to the whole rig (belt + stack + machine shell).
	if config.has("scale"):
		var sc = config["scale"]
		if sc is float or sc is int:
			var s: float = float(sc)
			if s > 0.0:
				scale = Vector3(s, s, s)
		elif sc is Vector3:
			scale = sc
	# Per-part visibility overrides, if the map asks for a bare belt etc.
	if config.has("show_machine_body"): show_machine_body = bool(config["show_machine_body"])
	if config.has("show_control_station"): show_control_station = bool(config["show_control_station"])
	if config.has("show_cylinders"): show_cylinders = bool(config["show_cylinders"])
	# Rebuild from scratch.
	for c in get_children():
		c.queue_free()
	_active = null
	call_deferred("_ready")


func _read_overrides() -> void:
	if has_meta("config_mode"): mode = str(get_meta("config_mode"))
	if has_meta("config_palette"): palette = str(get_meta("config_palette"))


# ── Static build: belt, pedestal, light, labels ────────────────────────

func _build_belt() -> void:
	_belt_x0 = -belt_length
	_belt_x1 = 0.0
	_deck_y = belt_height

	# Reuse the polished conveyor_belt artifact (the lab's "circulatory
	# system") rather than hand-rolling a belt. Its convention matches ours:
	# origin at deck centre, +X direction, deck top at y = belt_height — so
	# instancing it at the belt centre aligns the travel path automatically.
	var belt: Node3D = ConveyorBeltScene.instantiate()
	belt.name = "Belt"
	belt.belt_length = belt_length
	belt.belt_width = belt_width
	belt.belt_height = belt_height
	belt.direction_arrow_count = arrow_count
	belt.accent_color = accent_color
	belt.arrow_color = accent_color
	belt.position = Vector3(-belt_length * 0.5, 0.0, 0.0)
	add_child(belt)


func _build_pedestal() -> void:
	_pedestal_top_y = belt_height
	var ped := Node3D.new()
	ped.name = "Pedestal"
	ped.position = Vector3(_pedestal_x, 0, 0)
	add_child(ped)

	# Plinth column.
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34
	cm.bottom_radius = 0.4
	cm.height = belt_height
	cm.radial_segments = 32
	col.mesh = cm
	col.position = Vector3(0, belt_height * 0.5, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.13, 0.13, 0.16)
	cmat.roughness = 0.5
	cmat.metallic = 0.3
	col.material_override = cmat
	ped.add_child(col)

	# Glowing assembly disc on top — the stage where addition happens.
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.36
	dm.bottom_radius = 0.36
	dm.height = 0.02
	dm.radial_segments = 40
	disc.mesh = dm
	disc.position = Vector3(0, belt_height + 0.01, 0)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = accent_color
	dmat.emission_enabled = true
	dmat.emission = accent_color
	dmat.emission_energy_multiplier = 0.9
	disc.material_override = dmat
	ped.add_child(disc)

	# Halo ring.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.37
	tm.outer_radius = 0.42
	ring.mesh = tm
	ring.position = Vector3(0, belt_height + 0.015, 0)
	var ringmat := StandardMaterial3D.new()
	ringmat.albedo_color = accent_color
	ringmat.emission_enabled = true
	ringmat.emission = accent_color
	ringmat.emission_energy_multiplier = 1.4
	ring.material_override = ringmat
	ped.add_child(ring)


func _build_lighting() -> void:
	_accent_light = OmniLight3D.new()
	_accent_light.position = Vector3(_pedestal_x, belt_height + 1.5, 0.4)
	_accent_light.light_color = Color(1.0, 0.92, 0.78)
	_accent_light.light_energy = 2.2
	_accent_light.omni_range = 4.0
	_accent_light.omni_attenuation = 1.4
	add_child(_accent_light)


func _build_labels() -> void:
	var title := Label3D.new()
	title.text = title_text
	title.font_size = 80
	title.pixel_size = 0.0016
	title.position = Vector3(_pedestal_x, belt_height + 1.45, 0)
	title.modulate = Color(0.95, 0.95, 0.98)
	title.outline_modulate = Color(0, 0, 0, 0.7)
	title.outline_size = 10
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

	var sub := Label3D.new()
	sub.text = "%s · %s" % [palette, mode]
	sub.font_size = 40
	sub.pixel_size = 0.0014
	sub.position = Vector3(_pedestal_x, belt_height + 1.28, 0)
	sub.modulate = accent_color
	sub.outline_modulate = Color(0, 0, 0, 0.6)
	sub.outline_size = 6
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sub)

	if show_formula:
		_formula_label = Label3D.new()
		_formula_label.text = ""
		_formula_label.font_size = 64
		_formula_label.pixel_size = 0.0017
		_formula_label.position = Vector3(_pedestal_x, belt_height + 1.1, 0)
		_formula_label.modulate = Color(0.95, 0.95, 0.98)
		_formula_label.outline_modulate = Color(0, 0, 0, 0.7)
		_formula_label.outline_size = 8
		_formula_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_formula_label)


# ── Cycle / state machine ──────────────────────────────────────────────

func _reset_cycle() -> void:
	for c in _stack_root.get_children():
		c.queue_free()
	_active = null
	_index = 0
	_cursor_y = 0.0
	_formula_parts.clear()
	if _formula_label: _formula_label.text = ""
	_phase = "spawn"
	_t = 0.0


func _spawn_active() -> void:
	if _index >= sequence.size():
		_phase = "hold"
		_t = 0.0
		return
	var shape := str(sequence[_index])
	var color := _color_for(_index, sequence.size())
	var built: Dictionary = PrimStack._make_primitive(shape, base_scale, color)
	_active = built["mesh"]
	_active_height = float(built["height"])
	_active_mat = _active.material_override
	# Start on the belt's spawn end, resting on the deck.
	_start_pos = Vector3(_belt_x0, _deck_y + _active_height * 0.5, 0)
	_active.position = _start_pos
	add_child(_active)
	# Target slot on the stack.
	_target_pos = Vector3(_pedestal_x, _pedestal_top_y + _cursor_y + _active_height * 0.5, 0)
	_phase = "travel"
	_t = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	_animate_ambient()

	match _phase:
		"spawn":
			_spawn_active()
		"travel":
			_t += delta / max(0.01, travel_time)
			if _t >= 1.0:
				_t = 1.0
				_phase = "place"
				var k := _t
				_active.position.x = lerpf(_belt_x0, _belt_x1, k)
				_t = 0.0
			else:
				_active.position.x = lerpf(_belt_x0, _belt_x1, _t)
		"place":
			_t += delta / max(0.01, place_time)
			var k2: float = clampf(_t, 0.0, 1.0)
			var e := _smooth(k2)
			var from := Vector3(_belt_x1, _deck_y + _active_height * 0.5, 0)
			var pos := from.lerp(_target_pos, e)
			pos.y += 0.55 * 4.0 * e * (1.0 - e)        # pick-and-place arc
			_active.position = pos
			_active.rotation.y = e * TAU * 0.5          # half turn as it places
			if _t >= 1.0:
				_active.position = _target_pos
				_active.rotation.y = 0.0
				_phase = "land"
				_t = 0.0
		"land":
			_t += delta / max(0.01, land_time)
			var k3: float = clampf(_t, 0.0, 1.0)
			# Scale pop + emissive flash, settling to rest.
			var pop := 1.0 + 0.18 * sin(k3 * PI)
			_active.scale = Vector3.ONE * pop
			if _active_mat:
				_active_mat.emission_enabled = true
				_active_mat.emission = _active_mat.albedo_color
				_active_mat.emission_energy_multiplier = 1.6 * (1.0 - k3)
			if _t >= 1.0:
				_land_active()
		"hold":
			_t += delta
			_stack_root.rotation.y += delta * 0.6        # presentation turntable
			if _t >= hold_time:
				_phase = "clear"
				_t = 0.0
		"clear":
			_t += delta / max(0.01, clear_time)
			var k4: float = clampf(_t, 0.0, 1.0)
			# Drop + fade the finished totem out.
			_stack_root.position.y = -1.6 * _smooth(k4)
			_fade_stack(1.0 - k4)
			if _t >= 1.0:
				_stack_root.position.y = 0.0
				_stack_root.rotation.y = 0.0
				_fade_stack(1.0)
				if loop:
					_reset_cycle()
				else:
					_phase = "done"


func _land_active() -> void:
	# Reparent the landed piece onto the stack root (so it turns/clears as a unit).
	var world_pos := _active.global_position
	remove_child(_active)
	_stack_root.add_child(_active)
	_active.global_position = world_pos
	_active.scale = Vector3.ONE
	if _active_mat:
		_active_mat.emission_energy_multiplier = 0.0
	_cursor_y += _active_height
	# Build up the formula.
	_formula_parts.append(GLYPHS.get(str(sequence[_index]), str(sequence[_index])))
	if _formula_label:
		_formula_label.text = "  +  ".join(_formula_parts)
	_index += 1
	_active = null
	_active_mat = null
	_phase = "spawn" if _index < sequence.size() else "hold"
	_t = 0.0


func _animate_ambient() -> void:
	# Pulse the belt arrows and assembly light gently — the machine breathes.
	var pulse := 0.8 + 0.5 * (0.5 + 0.5 * sin(_elapsed * 3.0))
	if _arrow_mat:
		_arrow_mat.emission_energy_multiplier = pulse
	if _accent_light:
		_accent_light.light_energy = 2.0 + 0.4 * sin(_elapsed * 1.5)
	# Beacon: a soft amber pulse on top of the housing (status light).
	var beat: float = 0.5 + 0.5 * sin(_elapsed * 2.2)
	if _beacon_mat:
		_beacon_mat.emission_energy_multiplier = 1.4 + 3.2 * beat
	if _beacon_light:
		_beacon_light.light_energy = 0.4 + 2.0 * beat
	# Glass-panel internals: a slow shimmer so the machine reads as "running".
	if _glass_bars_mat:
		_glass_bars_mat.emission_energy_multiplier = 1.1 + 0.5 * sin(_elapsed * 1.1)


func _fade_stack(alpha: float) -> void:
	for child in _stack_root.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = child.material_override
			if alpha < 1.0:
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var c := m.albedo_color
			c.a = clampf(alpha, 0.0, 1.0)
			m.albedo_color = c


# ── Machine body: the sci-fi industrial shell ──────────────────────────
#
# Wraps the working belt+pedestal in a lab machine. Reads left → right:
#   left:        in-feed belt on thin legs+feet
#   centre-right HOUSING the belt feeds into (hazard band, beacon, glass panel)
#   front:       angled CONTROL STATION (monitor + keyboard + button panel)
#   right:       darker GAUGE cabinet (circular gauge + arching pipes) + stool
#   far right:   two blue GAS CYLINDERS (red hazard-diamond label) on a base
# All static MeshInstance3D with a few shared StandardMaterial3D. The pedestal
# (the machine's OUTPUT stage) sits in front of the housing so the assembled
# stack reads as the product coming off the line.

func _build_machine_body() -> void:
	if not show_machine_body:
		return
	_make_machine_materials()
	_machine_root = Node3D.new()
	_machine_root.name = "MachineBody"
	add_child(_machine_root)

	# Floor footprint baseplate, ties belt + housing + cabinets together.
	_build_machine_base()
	if show_belt_legs:
		_build_belt_legs()
	if show_housing:
		_build_housing()
	if show_control_station:
		_build_control_station()
	if show_gauge_cabinet:
		_build_gauge_cabinet()
	if show_stool:
		_build_stool()
	if show_cylinders:
		_build_gas_cylinders()


func _make_machine_materials() -> void:
	# Clean light-grey panel.
	_mat_panel = StandardMaterial3D.new()
	_mat_panel.albedo_color = panel_color
	_mat_panel.roughness = 0.55
	_mat_panel.metallic = 0.15

	# Dark metal trim / seams / bolts.
	_mat_trim = StandardMaterial3D.new()
	_mat_trim.albedo_color = trim_color
	_mat_trim.roughness = 0.4
	_mat_trim.metallic = 0.65

	# Blue accent stripe (lightly emissive so it pops in the lab gloom).
	_mat_accent = StandardMaterial3D.new()
	_mat_accent.albedo_color = machine_accent
	_mat_accent.roughness = 0.5
	_mat_accent.metallic = 0.1
	_mat_accent.emission_enabled = true
	_mat_accent.emission = machine_accent
	_mat_accent.emission_energy_multiplier = 0.5

	# Darker brushed metal for the right cabinet / pipes.
	_mat_dark_metal = StandardMaterial3D.new()
	_mat_dark_metal.albedo_color = Color(0.30, 0.31, 0.34)
	_mat_dark_metal.roughness = 0.35
	_mat_dark_metal.metallic = 0.8


# ── Shared small builders ──────────────────────────────────────────────

func _box(parent: Node3D, box_name: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, cyl_name: String, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = cyl_name
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 20
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _bolt(parent: Node3D, pos: Vector3) -> void:
	# A small dark cylinder lying flat against a +Z face, reads as a bolt head.
	var b := MeshInstance3D.new()
	b.name = "Bolt"
	var m := CylinderMesh.new()
	m.top_radius = 0.012
	m.bottom_radius = 0.012
	m.height = 0.01
	m.radial_segments = 8
	b.mesh = m
	b.material_override = _mat_trim
	b.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # axis → +Z, face out the front
	b.position = pos
	parent.add_child(b)


func _panel_seam(parent: Node3D, length: float, pos: Vector3) -> void:
	# A thin recessed horizontal seam line along X on a +Z face.
	_box(parent, "Seam", Vector3(length, 0.012, 0.004), pos, _mat_trim)


# ── Floor baseplate ────────────────────────────────────────────────────

func _build_machine_base() -> void:
	# A low plinth running under the housing + cabinets (not under the belt,
	# which has its own legs). Spans from just in front of the pedestal to the
	# far-right cylinders.
	var x0: float = _pedestal_x - 0.5
	var x1: float = _pedestal_x + 2.05
	var cx: float = (x0 + x1) * 0.5
	var w: float = x1 - x0
	_box(_machine_root, "Baseplate", Vector3(w, 0.06, 1.5), Vector3(cx, 0.03, -0.15), _mat_trim)


# ── In-feed belt legs ──────────────────────────────────────────────────

func _build_belt_legs() -> void:
	# Thin cylindrical legs + little feet raising the belt deck off the floor.
	# The belt deck top sits at y = belt_height; legs run from a foot up to
	# just under the deck. Belt spans local x in [-belt_length, 0].
	var legs := Node3D.new()
	legs.name = "BeltLegs"
	_machine_root.add_child(legs)

	var leg_top: float = belt_height - 0.03
	var leg_h: float = leg_top - 0.04     # leave room for the foot
	if leg_h < 0.05:
		return
	var pairs: int = 3
	var z_off: float = belt_width * 0.42
	var x_start: float = _belt_x0 + 0.22
	var x_end: float = _belt_x1 - 0.22
	for i in range(pairs):
		var t: float = 0.5
		if pairs > 1:
			t = float(i) / float(pairs - 1)
		var x: float = lerpf(x_start, x_end, t)
		for sign_z in [1.0, -1.0]:
			var z: float = z_off * sign_z
			# Leg.
			_cyl(legs, "BeltLeg_%d" % i, 0.022, leg_h, Vector3(x, 0.04 + leg_h * 0.5, z), _mat_dark_metal)
			# Foot pad.
			_cyl(legs, "BeltFoot_%d" % i, 0.05, 0.025, Vector3(x, 0.0125, z), _mat_trim)


# ── Housing (centre-right cabinet) ─────────────────────────────────────

func _build_housing() -> void:
	# A tall light-grey cabinet that the belt feeds into. Stands behind/around
	# the pedestal so the assembled stack appears to roll OUT of it. The belt
	# pickup end is x≈0; the pedestal output is x≈_pedestal_x (0.9).
	var house := Node3D.new()
	house.name = "Housing"
	_machine_root.add_child(house)

	var hw: float = 1.3          # width along X
	var hh: float = 1.7          # height
	var hd: float = 0.9          # depth along Z
	var hx: float = _pedestal_x + 0.05   # centred a touch behind the pedestal
	var hz: float = -0.35        # pushed back so the pedestal sits in front
	var hcy: float = hh * 0.5

	# Main body.
	_box(house, "HousingBody", Vector3(hw, hh, hd), Vector3(hx, hcy, hz), _mat_panel)

	# A recessed work-mouth on the belt-facing (-X) side at deck height — the
	# slot the belt feeds into. Dark inset box.
	_box(house, "FeedMouth", Vector3(0.12, belt_width + 0.08, belt_width + 0.18),
		Vector3(hx - hw * 0.5 - 0.01, belt_height + 0.05, 0.0), _mat_trim)

	# Front face panel-line seams + a couple of bolts (front = +Z face).
	var front_z: float = hz + hd * 0.5 + 0.006
	_panel_seam(house, hw * 0.86, Vector3(hx, hh * 0.66, front_z))
	_panel_seam(house, hw * 0.86, Vector3(hx, hh * 0.33, front_z))
	_bolt(house, Vector3(hx - hw * 0.5 + 0.07, hh - 0.09, front_z))
	_bolt(house, Vector3(hx + hw * 0.5 - 0.07, hh - 0.09, front_z))
	_bolt(house, Vector3(hx - hw * 0.5 + 0.07, 0.12, front_z))
	_bolt(house, Vector3(hx + hw * 0.5 - 0.07, 0.12, front_z))

	# Blue accent stripe wrapping the lower front.
	_box(house, "AccentStripe", Vector3(hw * 0.92, 0.05, 0.01),
		Vector3(hx, 0.22, front_z), _mat_accent)

	# Hazard band + beacon on top.
	_build_hazard_band(house, Vector3(hx, hh, hz), hw, hd)
	_build_beacon(house, Vector3(hx + hw * 0.5 - 0.18, hh + 0.02, hz + hd * 0.5 - 0.18))

	# Front glass panel (upper-left) with emissive vertical bars behind it.
	_build_glass_panel(house, Vector3(hx - hw * 0.27, hh * 0.66, front_z), 0.55, 0.6)


func _build_hazard_band(parent: Node3D, top_centre: Vector3, hw: float, hd: float) -> void:
	# A blue+black diagonal hazard stripe band laid flat on top of the housing.
	var band := Node3D.new()
	band.name = "HazardBand"
	band.position = top_centre + Vector3(0.0, 0.015, 0.0)
	parent.add_child(band)

	# Black backing slab.
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.05, 0.05, 0.06)
	black.roughness = 0.6
	_box(band, "BandBase", Vector3(hw * 0.96, 0.02, hd * 0.34), Vector3(0.0, 0.0, 0.0), black)

	# Diagonal blue chevrons sitting on the black backing.
	var blue := StandardMaterial3D.new()
	blue.albedo_color = machine_accent
	blue.roughness = 0.45
	blue.emission_enabled = true
	blue.emission = machine_accent
	blue.emission_energy_multiplier = 0.4
	var span: float = hw * 0.9
	var stripes: int = 8
	var step: float = span / float(stripes)
	for i in range(stripes):
		var x: float = -span * 0.5 + step * (float(i) + 0.5)
		var s := MeshInstance3D.new()
		s.name = "HazardStripe_%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(step * 0.5, 0.012, hd * 0.46)
		s.mesh = m
		s.material_override = blue
		s.rotation = Vector3(0.0, deg_to_rad(35.0), 0.0)  # diagonal
		s.position = Vector3(x, 0.018, 0.0)
		band.add_child(s)


func _build_beacon(parent: Node3D, base_pos: Vector3) -> void:
	# A short capsule beacon that softly pulses (amber/white), on a dark stem.
	var beacon := Node3D.new()
	beacon.name = "Beacon"
	beacon.position = base_pos
	parent.add_child(beacon)

	# Stem.
	_cyl(beacon, "BeaconStem", 0.025, 0.06, Vector3(0.0, 0.03, 0.0), _mat_trim)

	# Glowing capsule.
	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.albedo_color = Color(1.0, 0.82, 0.45)
	_beacon_mat.roughness = 0.3
	_beacon_mat.emission_enabled = true
	_beacon_mat.emission = Color(1.0, 0.78, 0.4)
	_beacon_mat.emission_energy_multiplier = 2.0
	var cap := MeshInstance3D.new()
	cap.name = "BeaconCap"
	var cm := CapsuleMesh.new()
	cm.radius = 0.045
	cm.height = 0.16
	cm.radial_segments = 16
	cap.mesh = cm
	cap.material_override = _beacon_mat
	cap.position = Vector3(0.0, 0.135, 0.0)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(cap)

	# Soft pulse light.
	_beacon_light = OmniLight3D.new()
	_beacon_light.position = Vector3(0.0, 0.14, 0.0)
	_beacon_light.light_color = Color(1.0, 0.8, 0.5)
	_beacon_light.light_energy = 1.2
	_beacon_light.omni_range = 1.6
	beacon.add_child(_beacon_light)


func _build_glass_panel(parent: Node3D, centre: Vector3, w: float, h: float) -> void:
	# Translucent panel with emissive vertical bars behind it — visible internals.
	var panel := Node3D.new()
	panel.name = "GlassPanel"
	panel.position = centre
	parent.add_child(panel)

	# Recessed dark frame backing.
	_box(panel, "PanelBack", Vector3(w + 0.06, h + 0.06, 0.02), Vector3(0.0, 0.0, -0.02), _mat_trim)

	# Emissive vertical bars (internal structure), animated in _animate_ambient.
	_glass_bars_mat = StandardMaterial3D.new()
	_glass_bars_mat.albedo_color = machine_accent
	_glass_bars_mat.emission_enabled = true
	_glass_bars_mat.emission = Color(0.4, 0.7, 1.0)
	_glass_bars_mat.emission_energy_multiplier = 1.2
	_glass_bars_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var bars: int = 5
	for i in range(bars):
		var fx: float = -w * 0.5 + w * (float(i) + 0.5) / float(bars)
		var bh: float = h * (0.4 + 0.5 * fposmod(float(i) * 0.37, 1.0))
		_box(panel, "Bar_%d" % i, Vector3(w / float(bars) * 0.5, bh, 0.012),
			Vector3(fx, -h * 0.5 + bh * 0.5, -0.005), _glass_bars_mat)

	# Translucent glass in front of the bars.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.75, 0.85, 0.28)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.08
	glass.metallic = 0.0
	var g := MeshInstance3D.new()
	g.name = "Glass"
	var gm := BoxMesh.new()
	gm.size = Vector3(w, h, 0.012)
	g.mesh = gm
	g.material_override = glass
	g.position = Vector3(0.0, 0.0, 0.02)
	panel.add_child(g)


# ── Control station (front-centre desk) ────────────────────────────────

func _build_control_station() -> void:
	# An angled desk jutting forward (+Z) carrying a monitor, keyboard slab, and
	# a small button panel. Positioned in front of the housing, off to one side
	# so it doesn't block the pedestal output.
	var station := Node3D.new()
	station.name = "ControlStation"
	# Forward of the housing, slightly left of the pedestal.
	station.position = Vector3(_pedestal_x - 0.45, 0.0, 0.62)
	station.rotation = Vector3(0.0, deg_to_rad(18.0), 0.0)  # angled to face the player
	_machine_root.add_child(station)

	# Desk pedestal + angled top.
	_box(station, "DeskColumn", Vector3(0.7, 0.78, 0.4), Vector3(0.0, 0.39, 0.0), _mat_panel)
	var deck := _box(station, "DeskTop", Vector3(0.8, 0.05, 0.5), Vector3(0.0, 0.8, 0.05), _mat_trim)
	deck.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)   # tilt toward the operator
	# Blue accent stripe along the desk front.
	_box(station, "DeskStripe", Vector3(0.7, 0.04, 0.012), Vector3(0.0, 0.62, 0.205), _mat_accent)

	# Monitor riser + screen.
	_build_monitor(station, Vector3(0.0, 0.86, -0.12))
	# Keyboard slab on the desk, in front of the monitor.
	_build_keyboard(station, Vector3(0.0, 0.84, 0.12))
	# Small control panel with round buttons + indicator lights, to the side.
	_build_button_panel(station, Vector3(0.34, 0.83, 0.1))


func _build_monitor(parent: Node3D, base_pos: Vector3) -> void:
	var mon := Node3D.new()
	mon.name = "Monitor"
	mon.position = base_pos
	mon.rotation = Vector3(deg_to_rad(-12.0), 0.0, 0.0)   # tilt the screen up
	parent.add_child(mon)

	# Stand.
	_box(mon, "Stand", Vector3(0.05, 0.18, 0.05), Vector3(0.0, 0.09, 0.0), _mat_trim)
	# Bezel.
	_box(mon, "Bezel", Vector3(0.62, 0.42, 0.03), Vector3(0.0, 0.4, 0.0), _mat_trim)

	# Emissive screen quad with the procedurally-drawn UI texture.
	if _screen_texture == null:
		_screen_texture = _make_screen_texture()
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_texture = _screen_texture
	screen_mat.emission_enabled = true
	screen_mat.emission_texture = _screen_texture
	screen_mat.emission_energy_multiplier = 1.5
	screen_mat.roughness = 0.25
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.56, 0.36)
	screen.mesh = qm
	screen.material_override = screen_mat
	screen.position = Vector3(0.0, 0.4, 0.018)   # just in front of the bezel
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mon.add_child(screen)


func _build_keyboard(parent: Node3D, pos: Vector3) -> void:
	var kb := Node3D.new()
	kb.name = "Keyboard"
	kb.position = pos
	kb.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
	parent.add_child(kb)
	# Slab.
	_box(kb, "Slab", Vector3(0.4, 0.02, 0.16), Vector3(0.0, 0.0, 0.0), _mat_trim)
	# Key field hint: a slightly raised lighter inset.
	var keys := StandardMaterial3D.new()
	keys.albedo_color = Color(0.5, 0.51, 0.54)
	keys.roughness = 0.7
	_box(kb, "Keys", Vector3(0.36, 0.012, 0.13), Vector3(0.0, 0.014, 0.0), keys)


func _build_button_panel(parent: Node3D, pos: Vector3) -> void:
	var panel := Node3D.new()
	panel.name = "ButtonPanel"
	panel.position = pos
	panel.rotation = Vector3(deg_to_rad(-30.0), 0.0, 0.0)   # angled face-up slab
	parent.add_child(panel)

	# Base slab.
	_box(panel, "PanelSlab", Vector3(0.28, 0.02, 0.2), Vector3(0.0, 0.0, 0.0), _mat_panel)
	# Blue accent stripe across it.
	_box(panel, "PanelStripe", Vector3(0.26, 0.014, 0.02), Vector3(0.0, 0.012, -0.07), _mat_accent)

	# Three round buttons (dark caps).
	var btn_mat := StandardMaterial3D.new()
	btn_mat.albedo_color = Color(0.12, 0.12, 0.14)
	btn_mat.roughness = 0.4
	for i in range(3):
		var bx: float = -0.08 + 0.08 * float(i)
		_cyl(panel, "Button_%d" % i, 0.022, 0.02, Vector3(bx, 0.018, 0.02), btn_mat)

	# Two indicator lights (green + amber), emissive.
	_build_indicator(panel, Vector3(-0.04, 0.016, 0.07), Color(0.2, 0.95, 0.35))
	_build_indicator(panel, Vector3(0.04, 0.016, 0.07), Color(0.98, 0.7, 0.18))


func _build_indicator(parent: Node3D, pos: Vector3, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var led := MeshInstance3D.new()
	led.name = "Indicator"
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	sm.radial_segments = 10
	sm.rings = 6
	led.mesh = sm
	led.material_override = mat
	led.position = pos
	led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(led)


# ── Gauge cabinet (right) ──────────────────────────────────────────────

func _build_gauge_cabinet() -> void:
	var cab := Node3D.new()
	cab.name = "GaugeCabinet"
	cab.position = Vector3(_pedestal_x + 1.05, 0.0, -0.25)
	_machine_root.add_child(cab)

	var cw: float = 0.7
	var ch: float = 1.35
	var cd: float = 0.7
	# Darker body.
	_box(cab, "CabBody", Vector3(cw, ch, cd), Vector3(0.0, ch * 0.5, 0.0), _mat_dark_metal)
	# Accent stripe.
	_box(cab, "CabStripe", Vector3(cw * 0.9, 0.04, 0.01), Vector3(0.0, 0.28, cd * 0.5 + 0.006), _mat_accent)

	# Circular gauge on the front face (disc + ring + needle).
	_build_gauge(cab, Vector3(0.0, ch * 0.62, cd * 0.5 + 0.02))
	# Arching pipes over the top.
	_build_pipes(cab, ch, cw, cd)


func _build_gauge(parent: Node3D, centre: Vector3) -> void:
	var gauge := Node3D.new()
	gauge.name = "Gauge"
	gauge.position = centre
	parent.add_child(gauge)

	# Dial disc (cylinder face pointing +Z).
	var face := StandardMaterial3D.new()
	face.albedo_color = Color(0.9, 0.91, 0.93)
	face.roughness = 0.3
	var disc := MeshInstance3D.new()
	disc.name = "Dial"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.17
	dm.bottom_radius = 0.17
	dm.height = 0.02
	dm.radial_segments = 28
	disc.mesh = dm
	disc.material_override = face
	disc.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # face out +Z
	gauge.add_child(disc)

	# Outer ring.
	var ring := MeshInstance3D.new()
	ring.name = "GaugeRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.165
	tm.outer_radius = 0.19
	ring.mesh = tm
	ring.material_override = _mat_trim
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	gauge.add_child(ring)

	# Needle: a thin box, slightly in front of the dial, rotated.
	var needle_mat := StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.85, 0.2, 0.18)
	needle_mat.roughness = 0.4
	var needle := MeshInstance3D.new()
	needle.name = "Needle"
	var nbm := BoxMesh.new()
	nbm.size = Vector3(0.012, 0.14, 0.006)
	needle.mesh = nbm
	needle.material_override = needle_mat
	needle.position = Vector3(0.04, 0.04, 0.022)
	needle.rotation = Vector3(0.0, 0.0, deg_to_rad(-35.0))
	gauge.add_child(needle)

	# Hub.
	_cyl(gauge, "Hub", 0.022, 0.03, Vector3(0.0, 0.0, 0.02), _mat_trim)


func _build_pipes(parent: Node3D, ch: float, cw: float, cd: float) -> void:
	# A couple of vertical conduits arching over the cabinet top. Each pipe is a
	# vertical riser + a short horizontal crown bend (approximated with boxes/cyls).
	var pipes := Node3D.new()
	pipes.name = "Pipes"
	parent.add_child(pipes)

	var pipe_mat := StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.55, 0.56, 0.6)
	pipe_mat.roughness = 0.3
	pipe_mat.metallic = 0.85

	for i in range(2):
		var px: float = -cw * 0.25 + cw * 0.5 * float(i)
		var pz: float = cd * 0.5 - 0.12
		# Vertical riser up past the cabinet top.
		_cyl(pipes, "PipeRiser_%d" % i, 0.03, ch * 0.5 + 0.25, Vector3(px, ch * 0.75 + 0.12, pz), pipe_mat)
		# Crown elbow (small flattened cylinder bridging toward the housing).
		var elbow := _cyl(pipes, "PipeCrown_%d" % i, 0.03, 0.3, Vector3(px - 0.15, ch + 0.36, pz), pipe_mat)
		elbow.rotation = Vector3(0.0, 0.0, PI * 0.5)   # lay it along X
		# Flange band.
		_cyl(pipes, "PipeFlange_%d" % i, 0.04, 0.025, Vector3(px, ch + 0.2, pz), _mat_trim)


# ── Stool ──────────────────────────────────────────────────────────────

func _build_stool() -> void:
	var stool := Node3D.new()
	stool.name = "Stool"
	stool.position = Vector3(_pedestal_x - 0.45, 0.0, 1.25)
	_machine_root.add_child(stool)

	var seat_h: float = 0.62
	# Seat (cylinder).
	var seat_mat := StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.18, 0.2, 0.24)
	seat_mat.roughness = 0.6
	_cyl(stool, "Seat", 0.17, 0.06, Vector3(0.0, seat_h, 0.0), seat_mat)
	# Central post.
	_cyl(stool, "Post", 0.025, seat_h - 0.1, Vector3(0.0, (seat_h - 0.1) * 0.5 + 0.05, 0.0), _mat_dark_metal)
	# Star base: five thin legs radiating out.
	var legs: int = 5
	for i in range(legs):
		var ang: float = TAU * float(i) / float(legs)
		var leg := MeshInstance3D.new()
		leg.name = "StoolLeg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(0.22, 0.03, 0.04)
		leg.mesh = lm
		leg.material_override = _mat_dark_metal
		leg.position = Vector3(cos(ang) * 0.11, 0.05, sin(ang) * 0.11)
		leg.rotation = Vector3(0.0, -ang, 0.0)
		stool.add_child(leg)
		# Caster foot at the tip.
		_cyl(stool, "Caster_%d" % i, 0.02, 0.03, Vector3(cos(ang) * 0.22, 0.025, sin(ang) * 0.22), _mat_trim)


# ── Gas cylinders (far right) ──────────────────────────────────────────

func _build_gas_cylinders() -> void:
	var rack := Node3D.new()
	rack.name = "GasCylinders"
	rack.position = Vector3(_pedestal_x + 1.75, 0.0, -0.25)
	_machine_root.add_child(rack)

	# Little base the cylinders stand on.
	_box(rack, "CylBase", Vector3(0.7, 0.08, 0.5), Vector3(0.0, 0.04, 0.0), _mat_trim)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.16, 0.35, 0.78)   # blue gas bottle
	body_mat.roughness = 0.35
	body_mat.metallic = 0.4

	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.22, 0.23, 0.26)
	cap_mat.roughness = 0.4
	cap_mat.metallic = 0.6

	var body_h: float = 1.05
	var radius: float = 0.16
	for i in range(2):
		var cx: float = -0.18 + 0.36 * float(i)
		var bottle := Node3D.new()
		bottle.name = "Cylinder_%d" % i
		bottle.position = Vector3(cx, 0.08, 0.0)
		rack.add_child(bottle)
		# Rounded capsule body.
		var cap := MeshInstance3D.new()
		cap.name = "Bottle"
		var cm := CapsuleMesh.new()
		cm.radius = radius
		cm.height = body_h
		cm.radial_segments = 18
		cap.mesh = cm
		cap.material_override = body_mat
		cap.position = Vector3(0.0, body_h * 0.5, 0.0)
		bottle.add_child(cap)
		# Neck + valve.
		_cyl(bottle, "Neck", 0.05, 0.12, Vector3(0.0, body_h + 0.04, 0.0), cap_mat)
		_cyl(bottle, "Valve", 0.03, 0.06, Vector3(0.0, body_h + 0.13, 0.0), _mat_trim)
		# Red hazard-diamond label decal (a rotated red square quad on the front).
		_build_hazard_diamond(bottle, Vector3(0.0, body_h * 0.55, radius + 0.005))


func _build_hazard_diamond(parent: Node3D, pos: Vector3) -> void:
	var diamond_mat := StandardMaterial3D.new()
	diamond_mat.albedo_color = Color(0.85, 0.12, 0.1)
	diamond_mat.roughness = 0.45
	diamond_mat.emission_enabled = true
	diamond_mat.emission = Color(0.85, 0.12, 0.1)
	diamond_mat.emission_energy_multiplier = 0.25
	var d := MeshInstance3D.new()
	d.name = "HazardDiamond"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.12, 0.12)
	d.mesh = qm
	d.material_override = diamond_mat
	d.position = pos
	d.rotation = Vector3(0.0, 0.0, deg_to_rad(45.0))   # rotate the square → diamond
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(d)


# ── Procedural screen texture ──────────────────────────────────────────

func _make_screen_texture() -> ImageTexture:
	# Dark UI with colourful "3D-plot" bars + a few readout lines. Drawn once
	# into an Image, returned as an ImageTexture for the monitor's quad.
	var w: int = 256
	var h: int = 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.04, 0.05, 0.08))

	# Header bar.
	_fill_rect(img, 0, 0, w, 18, Color(0.10, 0.13, 0.20))
	_fill_rect(img, 6, 5, 60, 8, machine_accent)            # title block
	_fill_rect(img, w - 22, 5, 8, 8, Color(0.2, 0.9, 0.4))  # status dot (green)

	# A faint grid for the plot region.
	var plot_x0: int = 12
	var plot_y0: int = 28
	var plot_x1: int = 150
	var plot_y1: int = h - 14
	for gx in range(plot_x0, plot_x1, 16):
		_fill_rect(img, gx, plot_y0, 1, plot_y1 - plot_y0, Color(0.12, 0.16, 0.24))
	for gy in range(plot_y0, plot_y1, 16):
		_fill_rect(img, plot_x0, gy, plot_x1 - plot_x0, 1, Color(0.12, 0.16, 0.24))

	# Colourful bars (the "3D plot").
	var bar_cols: Array = [
		Color(0.95, 0.45, 0.25), Color(0.3, 0.75, 0.95), Color(0.95, 0.8, 0.25),
		Color(0.35, 0.9, 0.55), Color(0.7, 0.45, 0.95), Color(0.95, 0.35, 0.55),
	]
	var bars: int = bar_cols.size()
	var bw: int = int(float(plot_x1 - plot_x0) / float(bars)) - 4
	for i in range(bars):
		var bx: int = plot_x0 + 2 + i * (bw + 4)
		var frac: float = 0.3 + 0.65 * fposmod(float(i) * 0.41 + 0.13, 1.0)
		var bh: int = int(float(plot_y1 - plot_y0) * frac)
		var by: int = plot_y1 - bh
		# Bar body.
		_fill_rect(img, bx, by, bw, bh, bar_cols[i])
		# A lighter "3D" top cap to fake depth.
		_fill_rect(img, bx, by, bw, 3, (bar_cols[i] as Color).lerp(Color.WHITE, 0.4))

	# Readout lines on the right column.
	var rx: int = 162
	for r in range(6):
		var ry: int = 30 + r * 16
		var lw: int = 30 + (r * 13) % 60
		_fill_rect(img, rx, ry, lw, 4, Color(0.55, 0.7, 0.85))
		# A small coloured value chip.
		_fill_rect(img, rx + 64, ry - 1, 8, 6, bar_cols[r % bars])

	return ImageTexture.create_from_image(img)


func _fill_rect(img: Image, x: int, y: int, rw: int, rh: int, col: Color) -> void:
	var x1: int = mini(x + rw, img.get_width())
	var y1: int = mini(y + rh, img.get_height())
	var xs: int = maxi(x, 0)
	var ys: int = maxi(y, 0)
	for px in range(xs, x1):
		for py in range(ys, y1):
			img.set_pixel(px, py, col)


# ── Colour: the three readings ─────────────────────────────────────────

func _color_for(index: int, count: int) -> Color:
	var pal: Array = PrimStack.PALETTES.get(palette, PrimStack.PALETTES["bauhaus"])
	match mode:
		"constant":
			# Colour as a property — one hue for the whole stack.
			return pal[0]
		"relational":
			# Colour as a relation — each piece contrasts its neighbour (hue march).
			var base: Color = pal[0]
			var h := fposmod(base.h + 0.41 * index, 1.0)
			return Color.from_hsv(h, 0.62, 0.92)
		_:
			# "gradient" — colour as a function of index across the palette.
			if count <= 1:
				return pal[0]
			var f := float(index) / float(count - 1)
			var fi := f * (pal.size() - 1)
			var lo := int(floor(fi))
			var hi := int(min(lo + 1, pal.size() - 1))
			return (pal[lo] as Color).lerp(pal[hi], fi - lo)


func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
