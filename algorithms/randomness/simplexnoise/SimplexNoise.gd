extends Node3D

# @identity
# essence: simplex(p) = Σ contribution(simplex_vertex) over the n+1 vertices of the simplex enclosing p, where contributions use (r² - dist²)⁴ falloff — no grid artifacts because simplexes have no axis-aligned edges
# desire: to compare two landscapes side-by-side and feel the difference between Perlin's rectangular grid bias and Simplex's isotropic smoothness — to see algorithm aesthetics with your body
# critical_parameter: persistence — controls how much each successive octave contributes relative to the previous; high persistence makes noise spiky and self-similar, low persistence makes it smooth with barely-visible detail
# triggers: compare_button is designed to show Perlin vs Simplex simultaneously — currently logs to console but demonstrates the design intent of architectural comparison
# emerges: the learner notices that Simplex noise has no preferred directions — mountain ridges don't tend to align with axes the way Perlin's do, which becomes perceptible when generating large terrains
# needs: frequency slider [has] (2D UI); amplitude slider [has]; persistence slider [has]; compare button [has] (non-functional); regenerate button [has]; VR panel [has, under panel=front]
# relationships: contrasts with PerlinNoise.gd (same scene architecture, different algorithm); shares the Noise_Perlin_Simplex map for direct comparison; Simplex is Perlin's successor — fewer visual artifacts, better performance in higher dimensions
# truth: Simplex noise solved Perlin's axis-alignment problem by changing the grid — the simplex lattice has no preferred directions, so randomness becomes genuinely isotropic

## STAGE-2 DNA PROMOTION (2026-07-29). Before this the root exposed no exports at
## all: the whole parameter space lived in a 2D Control panel that the grid strips
## out of every map placement (the demo-as-artifact UI suppression). So all 8
## placements were the same 20x20 field of half-metre cubes, displaced in y, tinted
## pink-to-teal — and nothing in map_data could say otherwise.
##
## Two axes, both lifted from constants already in this scene:
##
##   readout  WHAT the field is claimed to BE    relief · plate · column
##            (the cube.position.y = value line in SimplexVisualizer)
##   octaves  HOW MANY scales are summed         1 · 2 · 4 · 6
##            (noise_generator.fractal_octaves = 4, hard-coded in _ready)
##
## readout is the argument. relief reads the noise as TERRAIN — a landscape you
## could walk, which is how noise is usually sold. plate flattens every cube to the
## ground and leaves only the colour, so the field is an IMAGE of a scalar function
## and the mountains are revealed as our reading of it, not a property of it.
## column grows each cube from the floor to its value, so each sample is a MEASURED
## QUANTITY standing in a bar chart — noise as data, before it is scenery.
##
## octaves is the honest twin of the @identity's critical_parameter. persistence
## says how much each successive octave contributes; with the octave count nailed
## at 4 you can never see the term it is weighting. At 1 the field is pure simplex
## and its isotropy is legible; at 6 it is fractal brownian terrain and the lattice
## disappears under detail.
##
## readout=relief, octaves=4 is exactly the pre-promotion behaviour and is the
## default, so all 8 existing placements are untouched.
##
## THE COMPARISON CONTRACT (2026-09-10, doc/research/waves-chance-noise, the
## Noise_Perlin_Simplex pilot). The two displays in that hall were "compared"
## with independent random seeds, two colour ramps, two UI vocabularies and no
## reachable control. Four declarations fix that, every default the shipped one:
##
##   seed    a named seed (-1 = the old randi()). `#seed:20260910` on both
##           displays makes each REPEATABLE; it does not make their features
##           correspond — the same integer in two bases is two fields.
##   ramp    legacy | shared. `shared` is one ramp both displays use, so colour
##           stops being a difference the eye can mistake for a basis.
##   size    cells on a side, resolution unchanged: `#size:8` is a 4 m field of
##           the same half-metre cubes, so two fit in a hall with an aisle.
##   panel   none | front. A world-space RackTemplates panel in front of the
##           field — FREQ and OCTAVES sliders, REGEN and REPLAY — plus a readout
##           that prints the basis, the seed, the parameters, and the field's
##           value at two fixed coordinates. The 2D UI never reached a visitor.
##
## Usage in map_data.json:
##   "simplex_noise"
##   "simplex_noise#readout:plate"
##   "simplex_noise#readout:column#octaves:1"
##   "simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front"

## What the field is claimed to be: terrain, image, or measured quantities.
@export_enum("relief", "plate", "column") var readout: String = "relief"
## How many scales of noise are summed. 1 = pure simplex, 6 = fractal terrain.
@export_range(1, 8, 1) var octaves: int = 4
## A named seed; -1 keeps the shipped randi() at build.
@export var seed_value: int = -1
## legacy (this display's pink-to-teal) or shared (the ramp both displays use).
@export_enum("legacy", "shared") var ramp: String = "legacy"
## Cells on a side; the resolution stays 0.5 m.
@export var size: int = 20
## none, or front: a reachable panel in front of the field.
@export_enum("none", "front") var panel: String = "none"
## THE WITNESS (2026-09-13, N6). A controlled comparison is a claim about what was
## held equal, and a claim nobody can check is a label. `#witness:show` on one of the
## pair builds a plate between them printing BOTH generators' own properties, read
## off the FastNoiseLite objects that drew the fields rather than off this script's
## bookkeeping. Default "none": every other placement is untouched.
@export_enum("none", "show") var witness: String = "none"

## The value coordinates the readout reports. The same two on both displays.
const PROBE_A := Vector2(-1.0, 0.5)
const PROBE_B := Vector2(1.0, -1.0)
const FREQ_MIN := 1.0
const FREQ_MAX := 20.0

@onready var noise_field = $NoiseField
@onready var frequency_slider = get_node_or_null("UI/VBoxContainer/FrequencySlider")
@onready var amplitude_slider = get_node_or_null("UI/VBoxContainer/AmplitudeSlider")
@onready var persistence_slider = get_node_or_null("UI/VBoxContainer/PersistenceSlider")
@onready var frequency_label = get_node_or_null("UI/VBoxContainer/FrequencyLabel")
@onready var amplitude_label = get_node_or_null("UI/VBoxContainer/AmplitudeLabel")
@onready var persistence_label = get_node_or_null("UI/VBoxContainer/PersistenceLabel")
@onready var regenerate_button = get_node_or_null("UI/VBoxContainer/RegenerateButton")
@onready var compare_button = get_node_or_null("UI/VBoxContainer/CompareButton")

## The parameters as this root knows them. The 2D sliders seed these once; after
## the grid strips the UI, these are the only copy, and the VR panel writes them.
var _frequency: float = 1.0
var _amplitude: float = 1.0
var _persistence: float = 0.5
var _panel_node: Node3D
var _readout: Label3D
var _built: bool = false
const PAIR_GROUP := "noise_pair_displays"
var _witness_root: Node3D
var _witness_label: Label3D
var _placement_params: Dictionary = {}

func _ready() -> void:
	# The 2D UI, when it exists: seed the values from it and listen.
	if is_instance_valid(frequency_slider):
		_frequency = float(_placement_params.get("frequency", frequency_slider.value))
		_amplitude = float(_placement_params.get("amplitude", amplitude_slider.value))
		_persistence = float(_placement_params.get("persistence", persistence_slider.value))
		frequency_slider.value_changed.connect(_on_frequency_changed)
		amplitude_slider.value_changed.connect(_on_amplitude_changed)
		persistence_slider.value_changed.connect(_on_persistence_changed)
		regenerate_button.pressed.connect(_on_regenerate_pressed)
		compare_button.pressed.connect(_on_compare_pressed)
	# The 2D overlay is the standalone scene's own control surface. Embedded in a map
	# or the museum it would paint every visitor's screen (observed 2026-09-10 in the
	# museum probe capture: two overlapping slider stacks); the front panel is the
	# control there. Hidden, not freed: the sliders still seed the values above.
	var ui: Node = get_node_or_null("UI")
	if ui is CanvasItem and get_tree() != null and get_tree().current_scene != self:
		(ui as CanvasItem).visible = false
	_apply_contract()
	# Initialize the noise field
	_update_noise_parameters()
	_build_panel()
	_built = true
	add_to_group(PAIR_GROUP)
	# The twin may not be in the tree yet, and the museum configures before _ready,
	# so the plate is built once both displays exist.
	if witness == "show":
		_build_witness_plate.call_deferred()

## Push the declared seed, ramp and size down to the field. The field built
## itself in ITS _ready, before this root's, with randi(); a declared seed
## replaces that now, and a declared size rebuilds the cubes once.
func _apply_contract() -> void:
	if noise_field == null:
		return
	noise_field.ramp = ramp
	if size != noise_field.noise_field_size:
		noise_field.rebuild_size(size)
	if seed_value >= 0 and noise_field.current_seed != seed_value:
		noise_field.reseed(seed_value)

func _on_frequency_changed(value) -> void:
	_frequency = float(value)
	if is_instance_valid(frequency_label):
		frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value) -> void:
	_amplitude = float(value)
	if is_instance_valid(amplitude_label):
		amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_persistence_changed(value) -> void:
	_persistence = float(value)
	if is_instance_valid(persistence_label):
		persistence_label.text = "Persistence: " + str(value)
	_update_noise_parameters()

func _on_regenerate_pressed() -> void:
	regenerate()

func _on_compare_pressed() -> void:
	# This could open a comparison scene or overlay
	pass

func _update_noise_parameters() -> void:
	if noise_field:
		noise_field.frequency = _frequency
		noise_field.amplitude = _amplitude
		noise_field.persistence = _persistence
		# DNA axes travel with the sliders. octaves=4 and readout="relief" are what
		# the visualizer already did, so the default path changes nothing.
		noise_field.octaves = octaves
		noise_field.readout = readout
		noise_field.update_noise_field()
	_refresh_readout()

# ── the reachable panel ───────────────────────────────────────────────────────
## A RackTemplates panel like seed_replay_demo's, placed in front of the field
## (-z), at hand height. Two sliders and two buttons: the only controls a visitor
## in the museum can reach. FREQ maps its normalised value onto the 2D slider's
## own range so the two paths agree; OCTAVES onto 1..8.
func _build_panel() -> void:
	if panel != "front":
		return
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	var f0: float = clampf((_frequency - FREQ_MIN) / (FREQ_MAX - FREQ_MIN), 0.0, 1.0)
	var o0: float = clampf(float(octaves - 1) / 7.0, 0.0, 1.0)
	_panel_node = RackTpl.create_panel(basis_name().to_upper(), [
		[{"type": "slider_h", "label": "FREQ", "default": f0}],
		[{"type": "slider_h", "label": "OCTAVES", "default": o0}],
		[
			{"type": "button", "label": "REGEN"},
			{"type": "button", "label": "REPLAY"},
		],
	])
	var half: float = float(noise_field.noise_field_size) * 0.5 * float(noise_field.noise_resolution) if noise_field else 5.0
	_panel_node.position = Vector3(0.0, 0.2, -(half + 0.7))
	_panel_node.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	add_child(_panel_node)
	var fs: Node = _panel_node.find_child("Param_0", true, false)
	if fs and fs.has_signal("slider_moved"):
		fs.slider_moved.connect(func(_v): _on_panel_freq(fs))
	var os_: Node = _panel_node.find_child("Param_1", true, false)
	if os_ and os_.has_signal("slider_moved"):
		os_.slider_moved.connect(func(_v): _on_panel_octaves(os_))
	var b0: Node = _panel_node.find_child("Btn_0", true, false)
	if b0:
		var a0 = b0.get_node_or_null("InteractableAreaButton")
		if a0:
			a0.button_pressed.connect(func(_b): regenerate())
	var b1: Node = _panel_node.find_child("Btn_1", true, false)
	if b1:
		var a1 = b1.get_node_or_null("InteractableAreaButton")
		if a1:
			a1.button_pressed.connect(func(_b): replay())
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.0018
	_readout.font_size = 16
	_readout.outline_size = 4
	_readout.modulate = Color(0.92, 0.9, 0.8)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 0.55, -(half + 0.7))
	add_child(_readout)
	_refresh_readout()

func _on_panel_freq(slider: Node) -> void:
	if slider.has_method("get_normalized_value"):
		_frequency = lerpf(FREQ_MIN, FREQ_MAX, float(slider.get_normalized_value()))
		_update_noise_parameters()

func _on_panel_octaves(slider: Node) -> void:
	if slider.has_method("get_normalized_value"):
		octaves = clampi(1 + int(round(float(slider.get_normalized_value()) * 7.0)), 1, 8)
		_update_noise_parameters()

## What the readout says: the basis by name, the seed the field is drawn from,
## the parameters, and the field's value at two fixed coordinates — the same
## two the sibling display reports, so a visitor can put the numbers side by
## side without trusting either picture.
func _refresh_readout() -> void:
	if _readout == null or noise_field == null:
		return
	var a: float = noise_field.sample_at(PROBE_A.x, PROBE_A.y)
	var b: float = noise_field.sample_at(PROBE_B.x, PROBE_B.y)
	_readout.text = "%s · seed %d · oct %d · f %.2f · gain %.2f\n(%.1f, %.1f) = %+.3f    (%.1f, %.1f) = %+.3f" % [
		basis_name(), noise_field.current_seed, octaves, _frequency, _persistence,
		PROBE_A.x, PROBE_A.y, a, PROBE_B.x, PROBE_B.y, b]

## REGEN: another seed, recorded on the readout.
func regenerate() -> void:
	if noise_field:
		noise_field.regenerate_noise()
	_refresh_readout()

## REPLAY: back to the declared seed, or to the seed the field was born with.
func replay() -> void:
	_frequency = float(_placement_params.get("frequency", _frequency))
	octaves = int(_placement_params.get("octaves", octaves))
	if noise_field:
		noise_field.reseed(seed_value if seed_value >= 0 else noise_field.current_seed)
	_update_noise_parameters()
	_sync_panel()

func _sync_panel() -> void:
	if _panel_node == null: return
	var fs: Node = _panel_node.find_child("Param_0", true, false)
	var os_: Node = _panel_node.find_child("Param_1", true, false)
	if fs != null: fs.set_normalized_value((_frequency - FREQ_MIN) / (FREQ_MAX - FREQ_MIN))
	if os_ != null: os_.set_normalized_value(float(octaves - 1) / 7.0)

# ── read by the probe (commons/testing/probe_wcn_noise_pair.gd) ──────────────
func basis_name() -> String:
	match noise_type():
		FastNoiseLite.TYPE_SIMPLEX: return "simplex"
		FastNoiseLite.TYPE_PERLIN: return "perlin"
		FastNoiseLite.TYPE_VALUE: return "value"
		FastNoiseLite.TYPE_CELLULAR: return "cellular"
	return "unknown"

func noise_type() -> int:
	return noise_field.noise_generator.noise_type if noise_field and noise_field.noise_generator else -1

func current_seed() -> int:
	return noise_field.current_seed if noise_field else -1

func sample_at(x: float, z: float) -> float:
	return noise_field.sample_at(x, z) if noise_field else 0.0

func contract() -> Dictionary:
	return {"basis": basis_name(), "seed": current_seed(), "octaves": octaves, "frequency": _frequency,
		"gain": _persistence, "amplitude": _amplitude, "size": noise_field.noise_field_size if noise_field else 0,
		"resolution": noise_field.noise_resolution if noise_field else 0.0, "ramp": ramp, "readout": readout}

func set_frequency(f: float) -> void:
	_frequency = clampf(f, FREQ_MIN, FREQ_MAX)
	_update_noise_parameters()
	_sync_panel()

## Grid system integration.
## Guarded: the field is only re-read when a value actually changed, and never
## before _ready has built the cubes (noise_field is @onready, so it is null until
## then — the values simply wait and are picked up by _ready's own update).
func apply_grid_config(config: Dictionary) -> void:
	if config.has("witness"):
		var wv: String = str(config["witness"]).to_lower()
		if wv != witness:
			witness = wv
			if witness == "show" and _built:
				_build_witness_plate.call_deferred()
	var changed: bool = false
	for key in ["frequency", "amplitude", "persistence", "octaves"]:
		if config.has(key):
			_placement_params[key] = config[key]
			changed = true
	if config.has("frequency"):
		_frequency = clampf(float(config["frequency"]), FREQ_MIN, FREQ_MAX)
	if config.has("amplitude"):
		_amplitude = maxf(0.01, float(config["amplitude"]))
	if config.has("persistence"):
		_persistence = clampf(float(config["persistence"]), 0.0, 1.0)
	if config.has("readout"):
		var r: String = str(config["readout"])
		if r != readout:
			readout = r
			changed = true
	if config.has("octaves"):
		var o: int = int(config["octaves"])
		if o != octaves:
			octaves = o
			changed = true
	if config.has("seed"):
		var s: int = int(config["seed"])
		if s != seed_value:
			seed_value = s
			changed = true
	if config.has("ramp"):
		var m: String = str(config["ramp"]).to_lower()
		if m != ramp:
			ramp = m
			changed = true
	if config.has("size"):
		var n: int = int(config["size"])
		if n != size:
			size = n
			changed = true
	if config.has("panel"):
		var p: String = str(config["panel"]).to_lower()
		if p != panel:
			panel = p
			if _built and _panel_node == null:
				_build_panel()
	if changed and noise_field != null:
		_apply_contract()
		_update_noise_parameters()
# ── the measurement contract, read off the generator ─────────────────────────
## `contract()` above reports THIS SCRIPT'S variables. These are the FastNoiseLite's
## own, read from the object that actually drew the field — the difference between
## "we set the frequency to 0.05" and "the generator's frequency is 0.05".
## `sample_scale` and `sample_offset` are the visualizer's own terms, applied to x
## and z BEFORE get_noise_2d, so they belong to the sampling contract too;
## `sample_offset` exists only on the perlin side (NoiseVisualizer adds
## animation_offset to both coordinates and SimplexVisualizer does not), which is
## why it is reported rather than assumed away.
func generator_readback() -> Dictionary:
	var g: FastNoiseLite = noise_field.noise_generator if noise_field != null else null
	if g == null:
		return {}
	var off: Variant = noise_field.get("animation_offset")
	return {
		"basis": basis_name(),
		"noise_type": int(g.noise_type),
		"seed": int(g.seed),
		"gen_frequency": float(g.frequency),
		"fractal_type": int(g.fractal_type),
		"fractal_octaves": int(g.fractal_octaves),
		"fractal_gain": float(g.fractal_gain),
		"fractal_lacunarity": float(g.fractal_lacunarity),
		"sample_scale": float(noise_field.frequency),
		"sample_offset": (float(off) if off != null else 0.0),
	}


## The other display of THIS hall, and no other. The museum streams several halls
## at once, so a group is not a place — the same boundary the voxel bench and the
## wall panel needed.
func _hall_ancestor() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_meta("em_map") or str(n.name).begins_with("Seg"):
			return n
		n = n.get_parent()
	return null


func _twin() -> Node:
	if not is_inside_tree():
		return null
	var hall: Node = _hall_ancestor()
	for other in get_tree().get_nodes_in_group(PAIR_GROUP):
		if other == self or not is_instance_valid(other):
			continue
		if hall != null and not hall.is_ancestor_of(other):
			continue
		return other
	return null


## The terms that MUST match, named here rather than inferred, so a term added
## later is either declared or visibly absent.
const WITNESS_KEYS: Array = ["seed", "gen_frequency", "fractal_type", "fractal_octaves",
	"fractal_gain", "fractal_lacunarity", "sample_scale", "sample_offset"]


func witness_state() -> Dictionary:
	var mine: Dictionary = generator_readback()
	var tw: Node = _twin()
	var theirs: Dictionary = tw.call("generator_readback") if tw != null and tw.has_method("generator_readback") else {}
	var same: Array = []
	var differ: Array = []
	for k in WITNESS_KEYS:
		if theirs.is_empty():
			continue
		if typeof(mine.get(k)) == TYPE_FLOAT:
			if is_equal_approx(float(mine.get(k, 0.0)), float(theirs.get(k, 0.0))):
				same.append(k)
			else:
				differ.append(k)
		elif mine.get(k) == theirs.get(k):
			same.append(k)
		else:
			differ.append(k)
	var hall: Node = _hall_ancestor()
	return {"witness": witness, "mine": mine, "theirs": theirs,
		"twin_found": tw != null, "twin": (str(tw.name) if tw != null else ""),
		"hall": (str(hall.name) if hall != null else ""),
		"held_equal": same, "differing": differ,
		"basis_differs": (not theirs.is_empty()) and int(mine.get("noise_type", -1)) != int(theirs.get("noise_type", -2)),
		"lines": _witness_lines()}


func _witness_lines() -> PackedStringArray:
	var mine: Dictionary = generator_readback()
	var tw: Node = _twin()
	var theirs: Dictionary = tw.call("generator_readback") if tw != null and tw.has_method("generator_readback") else {}
	var out := PackedStringArray()
	if mine.is_empty():
		return out
	if theirs.is_empty():
		out.append("no twin in this hall — nothing to compare against")
		out.append("%s  seed %d  f %.4f  oct %d  gain %.2f" % [str(mine["basis"]),
			int(mine["seed"]), float(mine["gen_frequency"]), int(mine["fractal_octaves"]),
			float(mine["fractal_gain"])])
		return out
	var a: String = str(mine["basis"])
	var b: String = str(theirs["basis"])
	out.append("read off the generators, not off the tokens")
	out.append("                  %-10s %-10s" % [a, b])
	out.append("seed              %-10d %-10d" % [int(mine["seed"]), int(theirs["seed"])])
	out.append("gen frequency     %-10.4f %-10.4f" % [float(mine["gen_frequency"]), float(theirs["gen_frequency"])])
	out.append("fractal octaves   %-10d %-10d" % [int(mine["fractal_octaves"]), int(theirs["fractal_octaves"])])
	out.append("fractal gain      %-10.3f %-10.3f" % [float(mine["fractal_gain"]), float(theirs["fractal_gain"])])
	out.append("fractal lacunarity %-9.3f %-10.3f" % [float(mine["fractal_lacunarity"]), float(theirs["fractal_lacunarity"])])
	out.append("fractal type      %-10d %-10d" % [int(mine["fractal_type"]), int(theirs["fractal_type"])])
	out.append("sample scale      %-10.3f %-10.3f" % [float(mine["sample_scale"]), float(theirs["sample_scale"])])
	out.append("sample offset     %-10.3f %-10.3f" % [float(mine["sample_offset"]), float(theirs["sample_offset"])])
	out.append("")
	out.append("noise_type        %-10d %-10d" % [int(mine["noise_type"]), int(theirs["noise_type"])])
	out.append("the one term that differs. the rest is the control.")
	return out


func _build_witness_plate() -> void:
	if witness != "show" or _witness_root != null:
		return
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	_witness_root = Node3D.new()
	_witness_root.name = "Witness"
	_witness_root.set_meta("em_local_instrument", true)
	add_child(_witness_root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.10, 0.105, 0.12)
	dark.roughness = 0.85
	var case_root := Node3D.new()
	case_root.name = "Case"
	# Between the two panels, at reading height: the token floats this body at
	# 1.1 m, so a local 0.15 puts the plate at about 1.25 m, and -2.7 is the
	# same z the panels stand on, clear of both fields.
	case_root.position = Vector3(2.5, 0.15, -2.7)
	case_root.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	_witness_root.add_child(case_root)
	# 1.45 m across a 1 m aisle: enough for the table, little enough that it does not
	# stand between the entrance and the two fields (the first build was 2.30 m and read
	# as a black slab from the door, with its own text running off both edges).
	case_root.add_child(HangarKit.box(Vector3.ZERO, Vector3(1.45, 0.62, 0.016), dark))
	var head: MeshInstance3D = HangarKit.stencil("HELD EQUAL", Vector2(0.56, 0.036), Color(0.12, 0.13, 0.15))
	if head != null:
		head.position = Vector3(0.0, 0.37, 0.012)
		case_root.add_child(head)
	_witness_label = Label3D.new()
	_witness_label.name = "Text"
	# 0.0018 m per pixel puts twelve lines across about 0.9 m of a 1.45 m panel. The
	# first three builds were a tenth of that and looked right only because the
	# capture camera was standing inside the panel.
	_witness_label.pixel_size = 0.0018
	_witness_label.font_size = 17
	_witness_label.line_spacing = 0.40
	_witness_label.modulate = Color(0.97, 0.98, 1.0)
	_witness_label.outline_size = 3
	_witness_label.outline_modulate = Color(0, 0, 0, 1)
	_witness_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_witness_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_witness_label.position = Vector3(-0.66, 0.26, 0.012)
	case_root.add_child(_witness_label)
	_refresh_witness()


func _refresh_witness() -> void:
	if _witness_label == null:
		return
	_witness_label.text = "\n".join(_witness_lines())
