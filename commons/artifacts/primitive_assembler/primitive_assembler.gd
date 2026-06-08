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

const GLYPHS := {
	"sphere": "●", "cube": "■", "cuboid": "▬", "cylinder": "▮",
	"cone": "▲", "hemisphere": "◗", "disc": "⬭", "wedge": "◣",
	"bipyramid": "◆", "prism": "⬟",
}


func _ready() -> void:
	_read_overrides()
	_build_belt()
	_build_pedestal()
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


func _fade_stack(alpha: float) -> void:
	for child in _stack_root.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = child.material_override
			if alpha < 1.0:
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var c := m.albedo_color
			c.a = clampf(alpha, 0.0, 1.0)
			m.albedo_color = c


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
