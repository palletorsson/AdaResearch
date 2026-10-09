# turing_pattern_generator.gd
# Gray-Scott reaction-diffusion simulation
# VR-enabled with preset and parameter controls

extends Node3D

# @identity
# essence: CPU Gray-Scott simulation — du/dt = Du*laplacian(u) - u*v^2 + f*(1-u), dv/dt = Dv*laplacian(v) + u*v^2 - (k+f)*v — iterated steps_per_frame times per frame on a 2D grid
# desire: to hold a Turing pattern in your hands and twist the feed/kill knobs until you find the boundary where spots become stripes become mazes
# critical_parameter: feed/kill ratio — the two parameters together define a 2D phase space; each preset (Spots, Stripes, Maze, Mitosis, Coral, Waves) is a point in that space
# triggers: VR sliders for feed, kill, and preset selection; reset button re-seeds the simulation; keyboard 1-6 for direct preset selection
# emerges: the laplacian coupling between neighboring cells means local perturbations propagate as waves — pattern is not local but a property of the entire coupled field
# needs: slider_horizontal [has] (preset, feed, kill); push_button [has] (reset); Label3D [has]
# relationships: CPU complement to reaction_diffusion's GPU shader approach; both demonstrate Turing's morphogenesis paper in different implementations
# truth: pattern emerges from the ratio of two diffusion rates — not from a template, not from a gene, but from the mathematics of how fast activation outruns inhibition

class_name TuringPatternGenerator

## Display size
@export var display_size: float = 1.0

## Simulation resolution
@export var resolution: int = 64

# ═══════════════════════════════════════════
#  DNA (stage 2 — variation)
# ═══════════════════════════════════════════
# regime: WHICH NAMED POINT of the feed/kill phase space the chemistry sits at.
#   The whole argument of this artifact is that spots, stripes and mazes are not
#   six pictures but one law at six settings, and the six settings were already
#   sitting in PRESETS below — reachable from a VR slider, and from a map token
#   not at all. `pattern_type` is a typed INT and map_data.json config values
#   arrive as STRINGS, so `turing_pattern_generator#pattern_type:2` set an int
#   property from "2", was rejected, and silently rendered Spots (the same trap
#   lsystem_editor was promoted out of on 2026-08-03). `regime` is that same
#   choice as a word, DERIVED from PRESETS rather than transcribed: _regime_index
#   reads the third column of the table, so the list cannot drift from the code.
#   "spots" is PRESETS[0], which is the shipped pattern_type, so it is a no-op.
@export_enum("spots", "stripes", "maze", "mitosis", "coral", "waves") var regime: String = "spots"

# seeding: WHAT THE FIELD IS INOCULATED WITH before the chemistry runs. `regime`
#   moves feed and kill; this file's own truth line is about neither — "pattern
#   emerges from the ratio of two diffusion rates, not from a template, not from a
#   gene" — and until now nothing let anyone test it, because every placement in
#   the corpus starts from the same five random discs.
#   MEASURED, not assumed: the update rule below was re-implemented exactly (same
#   0.2/0.05 laplacian weights, same clamp, same U=0.5 / V=0.25 stamp) and all four
#   inoculations run at every regime, resolution 40, 1600 steps. Under `maze` the
#   four settle at coverage 0.434 / 0.410 / 0.443 / 0.440 while 39-73% of the CELLS
#   differ: the law fixes HOW MUCH, the seed fixes WHERE, which is the truth line
#   vindicated. Under `waves` the lattice never ignites and under `mitosis` the ring
#   dies out entirely, so the seed also decides IF. Both halves of that answer are
#   in the picture, and neither is reachable through regime.
#   "discs" is the shipped five-random-disc inoculation, moved but not changed.
@export_enum("discs", "centre", "lattice", "ring") var seeding: String = "discs"

# ── Capture knobs. NOT axes: both default to 0, which is shipped behaviour. ──
# pattern_seed pins the five seeded blobs. Without it six regime frames are six
#   different random inoculations and the sweep measures the RNG, not the law.
# warmup runs N Gray-Scott steps inside _ready, before the first frame. Without
#   it every value photographs the same five undifferentiated blobs: at step 0
#   no feed/kill pair has said anything yet. Measured in a faithful port of this
#   exact update rule — at resolution 40 the six regimes separate from ~1200
#   steps and are fully settled by ~2000 (coverage 0.03 / 0.21 / 0.16 / 0.09 /
#   0.03 / 0.13), while at the shipped 4 steps per frame a 0.35 s capture settle
#   reaches step 84 and all six are indistinguishable.
@export var pattern_seed: int = 0
@export var warmup: int = 0

## Pattern presets
@export_enum("Spots", "Stripes", "Maze", "Mitosis", "Coral", "Waves") var pattern_type: int = 0:
	set(value):
		pattern_type = clampi(value, 0, 5)
		_apply_preset()
		_sync_preset_slider()

## Simulation speed
@export var steps_per_frame: int = 4
@export var auto_run: bool = true

## Color gradient
@export var color_gradient: Gradient

## Diffusion rates
@export var Du: float = 0.16
@export var Dv: float = 0.08

## Feed and kill rates
@export var feed: float = 0.055:
	set(value):
		feed = clampf(value, 0.01, 0.1)
		_update_info()

@export var kill: float = 0.062:
	set(value):
		kill = clampf(value, 0.04, 0.08)
		_update_info()

const PRESETS = {
	0: [0.055, 0.062, "Spots"],
	1: [0.042, 0.059, "Stripes"],
	2: [0.029, 0.057, "Maze"],
	3: [0.028, 0.062, "Mitosis"],
	4: [0.058, 0.065, "Coral"],
	5: [0.014, 0.047, "Waves"],
}

## An uncapped warmup at resolution 64 is 4096 cells x N steps of interpreted
## GDScript inside _ready, which blocks the boot and gets the run killed by the
## 16-second capture watchdog. The budget is a real ceiling, not a formality:
## 4 M cell-updates buys 2500 steps at resolution 40 and 976 at 64.
const WARMUP_CELL_BUDGET: int = 4000000

const SEEDINGS: Array[String] = ["discs", "centre", "lattice", "ring"]

var _seed_rng: RandomNumberGenerator = null
## true once _ready has built and inoculated the field at least once.
var _built: bool = false

var _U: Array[Array] = []
var _V: Array[Array] = []
var _U_next: Array[Array] = []
var _V_next: Array[Array] = []

var _display_mesh: MeshInstance3D
var _image: Image
var _texture: ImageTexture
var _material: StandardMaterial3D
var _info_label: Label3D

# VR Controls
var _preset_slider: Node
var _feed_slider: Node
var _kill_slider: Node
var _control_panel: Node3D


func _ready():
	_init_default_gradient()
	_create_display()
	_create_base()
	_create_labels()
	_create_vr_controls()
	_init_simulation()
	_resolve_regime()
	_apply_preset()
	_run_warmup()
	_built = true

## Fold the DNA word back onto the integer the rest of the file (and the VR
## preset slider) already speaks. At the default "spots" this resolves to 0,
## which pattern_type already holds, so NOTHING is assigned and the setter does
## not fire — the shipped path is byte for byte what it was.
func _resolve_regime() -> void:
	var idx: int = _regime_index(regime)
	if idx != pattern_type:
		pattern_type = idx

## The value list is read out of PRESETS, never typed twice.
func _regime_index(regime_name: String) -> int:
	for key in PRESETS.keys():
		if str(PRESETS[key][2]).to_lower() == regime_name:
			return int(key)
	return 0

func _has_regime(regime_name: String) -> bool:
	for key in PRESETS.keys():
		if str(PRESETS[key][2]).to_lower() == regime_name:
			return true
	return false

## Fixture only — warmup is 0 in every shipped placement, so a player still
## meets the blank field and watches it organise.
func _run_warmup() -> void:
	if warmup <= 0:
		return
	var cells: int = maxi(resolution * resolution, 1)
	var steps: int = mini(warmup, WARMUP_CELL_BUDGET / cells)
	for _i in range(steps):
		_simulation_step()
	_update_texture()

func _init_default_gradient():
	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.colors = PackedColorArray([
			Color(0.95, 0.9, 0.8),
			Color(0.85, 0.7, 0.4),
			Color(0.4, 0.25, 0.1),
			Color(0.05, 0.02, 0.0)
		])
		color_gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.7, 1.0])

func _create_display():
	_display_mesh = MeshInstance3D.new()
	_display_mesh.name = "PatternDisplay"
	
	var quad = QuadMesh.new()
	quad.size = Vector2(display_size, display_size)
	_display_mesh.mesh = quad
	
	_display_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_display_mesh.position = Vector3(0, 0.02, 0)
	
	_image = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)
	
	_material = StandardMaterial3D.new()
	_material.albedo_texture = _texture
	_material.emission_enabled = true
	_material.emission_texture = _texture
	_material.emission_energy_multiplier = 0.2
	
	_display_mesh.material_override = _material
	add_child(_display_mesh)

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var box = BoxMesh.new()
	box.size = Vector3(display_size + 0.04, 0.03, display_size + 0.04)
	base.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.4
	base.material_override = mat
	
	base.position = Vector3(0, -0.015, 0)
	add_child(base)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 28
	_info_label.position = Vector3(0, 0.05, -display_size/2 - 0.08)
	add_child(_info_label)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("TURING PATTERNS", [
		[{"type": "slider_h", "label": "PRESET", "default": float(pattern_type) / 5.0}],
		[
			{"type": "slider_h", "label": "FEED", "default": (feed - 0.01) / 0.09},
			{"type": "slider_h", "label": "KILL", "default": (kill - 0.04) / 0.04},
		],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0, 0.04, display_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_preset_slider = _control_panel.find_child("Param_0", true, false)
	if _preset_slider and _preset_slider.has_signal("slider_moved"):
		_preset_slider.slider_moved.connect(_on_preset_slider_moved)

	_feed_slider = _control_panel.find_child("Param_1", true, false)
	if _feed_slider and _feed_slider.has_signal("slider_moved"):
		_feed_slider.slider_moved.connect(_on_feed_slider_moved)

	_kill_slider = _control_panel.find_child("Param_2", true, false)
	if _kill_slider and _kill_slider.has_signal("slider_moved"):
		_kill_slider.slider_moved.connect(_on_kill_slider_moved)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_init_simulation)

func _sync_preset_slider():
	if _preset_slider and _preset_slider.has_method("set_normalized_value"):
		_preset_slider.set_normalized_value(float(pattern_type) / 5.0)

func _sync_feed_kill_sliders():
	if _feed_slider and _feed_slider.has_method("set_normalized_value"):
		_feed_slider.set_normalized_value((feed - 0.01) / 0.09)
	if _kill_slider and _kill_slider.has_method("set_normalized_value"):
		_kill_slider.set_normalized_value((kill - 0.04) / 0.04)

func _on_preset_slider_moved(_position):
	if _preset_slider and _preset_slider.has_method("get_normalized_value"):
		var norm = _preset_slider.get_normalized_value()
		var new_preset = int(norm * 5.99)
		if new_preset != pattern_type:
			pattern_type = new_preset

func _on_feed_slider_moved(_position):
	if _feed_slider and _feed_slider.has_method("get_normalized_value"):
		var norm = _feed_slider.get_normalized_value()
		feed = 0.01 + norm * 0.09

func _on_kill_slider_moved(_position):
	if _kill_slider and _kill_slider.has_method("get_normalized_value"):
		var norm = _kill_slider.get_normalized_value()
		kill = 0.04 + norm * 0.04

func _update_info():
	if _info_label:
		var preset = PRESETS.get(pattern_type, PRESETS[0])
		_info_label.text = "TURING: %s\nf=%.3f k=%.3f" % [preset[2], feed, kill]

func _init_simulation():
	_U.clear()
	_V.clear()
	_U_next.clear()
	_V_next.clear()
	
	for y in range(resolution):
		var row_u: Array[float] = []
		var row_v: Array[float] = []
		var row_u2: Array[float] = []
		var row_v2: Array[float] = []
		row_u.resize(resolution)
		row_v.resize(resolution)
		row_u2.resize(resolution)
		row_v2.resize(resolution)
		
		for x in range(resolution):
			row_u[x] = 1.0
			row_v[x] = 0.0
			row_u2[x] = 0.0
			row_v2[x] = 0.0
		
		_U.append(row_u)
		_V.append(row_v)
		_U_next.append(row_u2)
		_V_next.append(row_v2)
	
	_seed_random()

func _seed_random():
	# pattern_seed 0 keeps the shipped global-RNG draws, in the same order and
	# the same number, so an unpinned placement is inoculated exactly as before.
	_seed_rng = null
	if pattern_seed != 0:
		_seed_rng = RandomNumberGenerator.new()
		_seed_rng.seed = pattern_seed
	match seeding:
		"centre":
			_seed_centre()
		"lattice":
			_seed_lattice()
		"ring":
			_seed_ring()
		_:
			_seed_discs()

## THE SHIPPED INOCULATION, moved and not otherwise touched: five discs at random
## centres with random radii, drawn in the same order and the same count from the
## same generator. At the default seeding this is the only branch that runs, so an
## existing placement is inoculated byte for byte as before.
func _seed_discs():
	var seed_size: int = resolution / 8

	for _i in range(5):
		var cx: int = _seed_draw(seed_size, resolution - seed_size)
		var cy: int = _seed_draw(seed_size, resolution - seed_size)
		var size: int = _seed_draw(2, seed_size)
		_stamp_disc(cx, cy, size)

## The stamp the shipped loop applied inline: a filled disc of activator.
func _stamp_disc(cx: int, cy: int, size: int) -> void:
	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var x = cx + dx
			var y = cy + dy
			if x >= 0 and x < resolution and y >= 0 and y < resolution:
				if dx*dx + dy*dy <= size*size:
					_U[y][x] = 0.5
					_V[y][x] = 0.25

## One square in the middle — the inoculation every textbook figure of Gray-Scott
## starts from, and the only one that carries no randomness at all.
func _seed_centre() -> void:
	var h: int = maxi(2, resolution / 10)
	var c: int = resolution / 2
	for y in range(c - h, c + h):
		for x in range(c - h, c + h):
			if x >= 0 and x < resolution and y >= 0 and y < resolution:
				_U[y][x] = 0.5
				_V[y][x] = 0.25

## A regular 3x3 array of identical discs — a TEMPLATE, deliberately. Whether the
## settled pattern still shows the lattice is the question the truth line asks.
func _seed_lattice() -> void:
	var n: int = 3
	var size: int = maxi(2, resolution / 12)
	for iy in range(n):
		for ix in range(n):
			var cx: int = int((float(ix) + 0.5) * float(resolution) / float(n))
			var cy: int = int((float(iy) + 0.5) * float(resolution) / float(n))
			_stamp_disc(cx, cy, size)

## An annulus: a closed front with no ends. Mitosis has nothing to split here and
## the ring dies out; maze fills the field from it exactly as from anything else.
func _seed_ring() -> void:
	var c: float = float(resolution - 1) * 0.5
	var r0: float = float(resolution) * 0.30
	var w: float = maxf(1.5, float(resolution) * 0.05)
	for y in range(resolution):
		for x in range(resolution):
			var dx: float = float(x) - c
			var dy: float = float(y) - c
			if absf(sqrt(dx * dx + dy * dy) - r0) <= w:
				_U[y][x] = 0.5
				_V[y][x] = 0.25

func _seed_draw(lo: int, hi: int) -> int:
	if _seed_rng != null:
		return _seed_rng.randi_range(lo, hi)
	return randi_range(lo, hi)

func _apply_preset():
	var preset = PRESETS.get(pattern_type, PRESETS[0])
	feed = preset[0]
	kill = preset[1]
	_update_info()
	_sync_feed_kill_sliders()

func _process(_delta):
	if auto_run:
		for _i in range(steps_per_frame):
			_simulation_step()
	_update_texture()

func _simulation_step():
	for y in range(resolution):
		for x in range(resolution):
			var u = _U[y][x]
			var v = _V[y][x]
			
			var lap_u = _laplacian(_U, x, y)
			var lap_v = _laplacian(_V, x, y)
			
			var uvv = u * v * v
			var du = Du * lap_u - uvv + feed * (1.0 - u)
			var dv = Dv * lap_v + uvv - (kill + feed) * v
			
			_U_next[y][x] = clampf(u + du, 0.0, 1.0)
			_V_next[y][x] = clampf(v + dv, 0.0, 1.0)
	
	var temp = _U
	_U = _U_next
	_U_next = temp
	
	temp = _V
	_V = _V_next
	_V_next = temp

func _laplacian(grid: Array[Array], x: int, y: int) -> float:
	var sum = 0.0
	var center = grid[y][x]
	
	var xm = (x - 1 + resolution) % resolution
	var xp = (x + 1) % resolution
	var ym = (y - 1 + resolution) % resolution
	var yp = (y + 1) % resolution
	
	sum += grid[y][xm] * 0.2
	sum += grid[y][xp] * 0.2
	sum += grid[ym][x] * 0.2
	sum += grid[yp][x] * 0.2
	
	sum += grid[ym][xm] * 0.05
	sum += grid[ym][xp] * 0.05
	sum += grid[yp][xm] * 0.05
	sum += grid[yp][xp] * 0.05
	
	sum -= center
	
	return sum

func _update_texture():
	for y in range(resolution):
		for x in range(resolution):
			var v = _V[y][x]
			var color = color_gradient.sample(v)
			_image.set_pixel(x, y, color)
	
	_texture.update(_image)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				pattern_type = event.keycode - KEY_1
			KEY_R:
				_init_simulation()
			KEY_SPACE:
				auto_run = not auto_run

func set_gradient(gradient: Gradient):
	color_gradient = gradient

func reset():
	_init_simulation()

## Grid system integration.
##
## The legacy path is untouched: any key naming a property is written straight
## through, exactly as before, and it never rebuilt anything. `regime` is pulled
## out of that loop because writing the word alone would leave feed and kill on
## the old preset.
##
## The DNA path is guarded twice — the word must be one PRESETS actually builds,
## and it must DIFFER from the word already held. It then moves feed and kill and
## nothing else: the field is not re-seeded and no node is torn down, which is
## what the VR preset slider already does. Neither curation bay that mounts this
## artifact sends a regime key, so no shipped room moves.
##
## `seeding` is pulled out of the write-through loop for a reason the blanket
## `set()` would hide: writing the word alone would change what the RESET button
## draws next time and leave the field on screen inoculated the old way, so the
## artifact would be labelled one thing and showing another. It re-seeds instead —
## and only when _ready has already built once, so a config that arrives before the
## grids exist cannot index an empty array.
func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if str(key) == "regime" or str(key) == "seeding":
			continue
		if key in self:
			set(key, config_data[key])
	if config_data.has("regime"):
		var want: String = str(config_data["regime"]).to_lower()
		if _has_regime(want) and want != regime:
			regime = want
			pattern_type = _regime_index(want)
	if config_data.has("seeding"):
		var want_seed: String = str(config_data["seeding"]).to_lower()
		if SEEDINGS.has(want_seed) and want_seed != seeding:
			seeding = want_seed
			if _built:
				_init_simulation()
				_run_warmup()