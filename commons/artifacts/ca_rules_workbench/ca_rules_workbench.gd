extends Node3D
class_name CARulesWorkbench

# @identity
# essence: an interactive 1D-Wolfram cellular automaton workbench — the player turns ONE slider to scrub rule number ∈ [0, 255], and a 256×256 evolution texture redraws live above the table from a single seed cell. The class indicator lamp shifts among four QFEP phase colors (blue=Class 1 frozen, green=Class 2 periodic, orange=Class 3 chaotic, red=Class 4 edge-of-chaos). At rule 30 the lamp glows orange and a label surfaces "high H ≈ 1 — see shannon_workbench". At rule 110 the lamp glows red and "Turing-complete — see halting_workbench" appears. At rule 90 Sierpinski triangles bloom on the panel and "fractal — see fractals (when built)" lights up. At rule 0, 255, 254 the panel goes nearly blank and "vacuum — everything decays" pops in.
# desire: learner viscerally locates Wolfram's four classes as positions along a single integer dial — the boundary between Class 3 (rule 30) and Class 4 (rule 110) is two integer steps apart in some neighborhoods (rule 90 → 91 flips a single bit and the world re-categorizes), and the dial makes those phase transitions felt
# critical_parameter: rule (0..255 integer) — the only knob. Drives the 8 transition bits, the 256×256 image rebuild, the class classification, the QFEP-color lamp, and which cross-reference label surfaces
# triggers: _ready() builds slider + plate + 256×256 image-on-quad + class lamp + readout panel + cross-reference label hooks; _on_slider_changed snaps slider value to the nearest integer 0..255, rebuilds the image via _simulate(), recomputes the class, repaints the lamp, picks the readout text, and surfaces the matching cross-reference
# emerges: Wolfram's classification not as a static table but as a landscape the slider walks through — rule space is 256 cells wide and four colored regions deep, with one-bit flips at the boundaries between regions
# needs: slider_horizontal [present]; ImageTexture for the evolution panel [Image.create + ImageTexture.create_from_image]; Label3D for readouts [present]; QuadMesh + StandardMaterial3D unshaded for the panel and the class lamp [present]
# relationships: paired with /ca-rules-gallery (web frieze frozen at 8 highlighted rules); rule 30 references shannon_workbench (the Class 3 rule that famously passes randomness tests — H ≈ 1); rule 110 references halting_workbench (the Class 4 rule Cook proved Turing-complete in 2004, so it is one of the limits-of-X siblings); rule 90 references the (future) fractals gallery as it draws Sierpinski; rule 184 references traffic_flow models (forthcoming). Sister to shannon_workbench, halting_workbench, cantor_diagonal_workbench, russell_paradox_workbench, complexity_dial_workbench — together they cover the lambda_edge / limits-of-X workbench substrate.
# truth: a 3-cell neighborhood and 8 transition bits suffice to encode every behavior on the qualitative gradient from frozen to chaotic to edge-of-chaos. The encoding is small (8 bits = 256 rules), the dynamics are large (universal computation lives at rule 110). Walking the slider is walking from order through periodicity through chaos to the edge — and a single bit-flip can move you across a class boundary.

## A horizontal workbench for Wolfram's 1D elementary cellular automata.
##
## One slider drives rule R ∈ {0, 1, ..., 255} (integer). As you move it:
##   • a 256×256 evolution panel above the table redraws — single seed cell
##     at column 128, 256 generations rolling down
##   • the class indicator lamp shifts QFEP phase color (Class 1=blue,
##     2=green, 3=orange, 4=red)
##   • the readout panel updates: "Rule R", "Class N — phase_name", "claim-to-fame"
##   • a small cross-reference label surfaces when the rule lands on
##     30 / 90 / 110 / 184 / 0 (or stays dark otherwise)
##
## Rule logic:
##   For a cell, given (left, center, right) ∈ {0,1}³ → index = L*4 + C*2 + R,
##   next = (R_byte >> index) & 1. PackedByteArray tape of length 256,
##   single 1 at index 128, run 256 steps, accumulate into a 256×256 image.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Evolution Panel")
## Side count of the CA evolution (tape width and number of generations).
@export var grid_side: int = 256
## Width/height of the displayed panel in meters (before plate scale).
@export var panel_size: float = 1.0
## Forward distance of the panel in front of the plate.
@export var panel_depth: float = -0.25
## Vertical placement above plate origin.
@export var panel_height: float = 1.45
@export var color_zero: Color = Color(0.04, 0.05, 0.08)
@export var color_one: Color = Color(0.95, 0.96, 1.0)

@export_group("Class Lamp")
## QFEP phase colors keyed to Wolfram class (1..4).
@export var color_class_1: Color = Color(0.32, 0.55, 1.0)   # frozen — blue
@export var color_class_2: Color = Color(0.40, 0.92, 0.50)  # periodic — green
@export var color_class_3: Color = Color(1.0, 0.62, 0.20)   # chaotic — orange
@export var color_class_4: Color = Color(1.0, 0.30, 0.30)   # edge — red

@export_group("Initial State")
@export var initial_rule: int = 110

# ── Internal state ────────────────────────────────────────────────────

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const DisplayMount = preload("res://commons/ui/display_mount.gd")

var _rule: int = 110

var _plate_root: Node3D
var _display_root: Node3D                 # anchor that carries the viz cluster
var _slider: Node                       # canonical slider_smooth (on the console)
var _plate_readout                       # console summary readout (Label)
var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

var _panel_root: Node3D
var _panel_mesh: MeshInstance3D
var _panel_material: StandardMaterial3D
var _panel_image: Image
var _panel_texture: ImageTexture

var _lamp_root: Node3D
var _lamp_mesh: MeshInstance3D
var _lamp_material: StandardMaterial3D

var _readout_root: Node3D
var _readout_rule: Label3D
var _readout_class: Label3D
var _readout_claim: Label3D

var _crossref_root: Node3D
var _crossref_label: Label3D
var _crossref_bg_mat: StandardMaterial3D

# ── Wolfram class table ───────────────────────────────────────────────
#
# Standard Wolfram classification of all 256 elementary CA rules.
# Sources: Wolfram (2002) "A New Kind of Science"; Wuensche & Lesser (1992);
# subsequent literature. Where a rule has been described by different authors
# differently (rule 110 in particular: Cook proved it Turing-complete in 2004,
# moving it from Class 3 → Class 4 by most accounts), the modern consensus
# is used. Rules left out default to Class 2 (periodic) — the most common.

const CLASS_TABLE: Dictionary = {
	# Class 1 — uniform / decays to constant. The vacuum.
	0: 1, 8: 1, 32: 1, 40: 1, 128: 1, 136: 1, 160: 1, 168: 1,
	# Class 3 — chaotic / pseudo-random. High Kolmogorov complexity.
	18: 3, 22: 3, 30: 3, 45: 3, 60: 3, 75: 3, 86: 3, 89: 3,
	101: 3, 105: 3, 122: 3, 126: 3, 129: 3, 135: 3, 146: 3,
	149: 3, 150: 3, 161: 3, 165: 3, 182: 3, 183: 3, 195: 3,
	# Class 4 — complex / edge-of-chaos. Universal computation lives here.
	54: 4, 110: 4, 124: 4, 137: 4, 147: 4, 193: 4,
	# Selected Class 2 — periodic / nested. Sierpinski included for clarity.
	90: 2, 94: 2, 102: 2, 118: 2, 153: 2, 184: 2, 220: 2, 222: 2,
}

# Cross-reference table — only the rules that connect to sibling artifacts
# show a label. Everything else stays dark, keeping the panel readable.
const CROSSREF: Dictionary = {
	0:   "vacuum — everything decays to 0",
	30:  "high H ≈ 1, low K — see shannon_workbench",
	54:  "Class 4 complex — sibling of rule 110",
	90:  "Sierpinski triangle — see fractals (when built)",
	110: "Turing-complete (Cook 2004) — see halting_workbench",
	126: "chaotic — like rule 30, but symmetric",
	150: "additive (XOR) — fractal under iteration",
	184: "1D traffic flow model",
	254: "growing solid — Class 1 closing in",
	255: "vacuum — every cell becomes 1, then constant",
}

# Per-class "claim-to-fame" line for the readout panel. Falls back to a
# class-typical phrase if the rule isn't individually annotated.
const CLAIM_TABLE: Dictionary = {
	0:   "vacuum — everything decays to 0",
	18:  "chaotic — nested triangles, fractal in time",
	30:  "chaotic — used in RNG, passes randomness tests",
	45:  "chaotic — equivalent to rule 30 under reflection",
	54:  "edge-of-chaos — local structures persist",
	60:  "Class 3 — Pascal's triangle mod 2 in disguise",
	90:  "Class 2 — Sierpinski triangle, XOR rule",
	110: "Turing-complete (Cook 2004) — universal computation",
	126: "Class 3 — chaotic, symmetric",
	150: "Class 3 — additive (XOR of three cells)",
	184: "Class 2 — particle / traffic flow",
	254: "Class 1 — almost-everywhere fills in",
	255: "vacuum — every cell becomes 1",
}

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_rule = clamp(initial_rule, 0, 255)
	_build_plate_and_slider()
	_build_evolution_panel()
	_build_class_lamp()
	_build_readout_panel()
	_build_crossref_label()
	_refresh_all()
	_mount_display.call_deferred()


## Gather the viz roots onto a composer-placed anchor + floor stand (DisplayMount).
func _mount_display() -> void:
	var center := Vector3(0.0, panel_height, panel_depth)
	_display_root = DisplayMount.make_anchor(self, "ca_rules_workbench", center, 1.0, 0.0)
	DisplayMount.mount_cluster(_display_root, [_panel_root, _lamp_root, _readout_root, _crossref_root], center)
	DisplayMount.build_stand(self, _display_root)


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole (workbench principal) hosts the Rule slider
	# + a summary readout; the evolution panel + detail card stay as world-space viz.
	# Replaces the hand-built plate + old jumpy slider_horizontal with slider_smooth.
	_plate_root = InterfacePresets.build("workbench", "CA Rules", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")
	_slider = _plate_root.add_slider("Rule", "Rule")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", float(_rule) / 255.0)
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var n: Variant = _slider.call("get_normalized_value")
	# Snap to the 256 integer rule positions. With 256 detents in [0,1]
	# the slider has a natural step of ~0.0039, well below human grip jitter,
	# so this gives smooth scrubbing through the rule space.
	var snapped: int = int(round(clampf(float(n), 0.0, 1.0) * 255.0))
	if snapped == _rule:
		return
	_rule = snapped
	_viz_dirty = true   # throttled rebuild (see _process) — keep the grab loop free


func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Evolution panel (256×256) ─────────────────────────────────────────

func _build_evolution_panel() -> void:
	_panel_root = Node3D.new()
	_panel_root.name = "EvolutionPanel"
	_panel_root.position = Vector3(0.0, panel_height, panel_depth)
	add_child(_panel_root)

	# Frame behind the panel for contrast.
	var frame := MeshInstance3D.new()
	frame.name = "PanelFrame"
	var frame_mesh := QuadMesh.new()
	frame_mesh.size = Vector2(panel_size + 0.04, panel_size + 0.04)
	frame.mesh = frame_mesh
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.015, 0.018, 0.03)
	frame_mat.roughness = 0.95
	frame.material_override = frame_mat
	frame.position = Vector3(0.0, 0.0, -0.006)
	_panel_root.add_child(frame)

	# Image + texture for the CA evolution. RGB8 is plenty — we only write
	# B/W. Image.create initializes black; _simulate fills it.
	_panel_image = Image.create(grid_side, grid_side, false, Image.FORMAT_RGB8)
	_panel_texture = ImageTexture.create_from_image(_panel_image)

	# Quad showing the texture.
	_panel_material = StandardMaterial3D.new()
	_panel_material.albedo_texture = _panel_texture
	_panel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_panel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_panel_material.emission_enabled = true
	_panel_material.emission_texture = _panel_texture
	_panel_material.emission_energy_multiplier = 0.6

	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "PanelQuad"
	var pmesh := QuadMesh.new()
	pmesh.size = Vector2(panel_size, panel_size)
	_panel_mesh.mesh = pmesh
	_panel_mesh.material_override = _panel_material
	_panel_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_panel_root.add_child(_panel_mesh)


func _simulate(rule: int) -> void:
	# 1D Wolfram CA: PackedByteArray tape of length grid_side, seeded with a
	# single 1 at the center. For each of grid_side generations, paint the
	# current tape onto row g of the image, then advance.
	var tape := PackedByteArray()
	tape.resize(grid_side)
	for i in range(grid_side):
		tape[i] = 0
	tape[grid_side / 2] = 1

	# Precompute bit lookup: bits[i] = (rule >> i) & 1 for i in 0..7.
	var bits := PackedByteArray()
	bits.resize(8)
	for i in range(8):
		bits[i] = (rule >> i) & 1

	for g in range(grid_side):
		# Paint current generation onto row g.
		for c in range(grid_side):
			var col: Color = color_one if tape[c] == 1 else color_zero
			_panel_image.set_pixel(c, g, col)
		# Advance one generation (wrap-around boundaries; cleaner edge than
		# fixed-0 boundaries for the visualization).
		var next := PackedByteArray()
		next.resize(grid_side)
		for c in range(grid_side):
			var l: int = tape[(c - 1 + grid_side) % grid_side]
			var m: int = tape[c]
			var r: int = tape[(c + 1) % grid_side]
			var idx: int = l * 4 + m * 2 + r
			next[c] = bits[idx]
		tape = next

	# Push image bytes into the existing texture (cheap on the GPU).
	_panel_texture.update(_panel_image)


# ── Class lamp ────────────────────────────────────────────────────────

func _build_class_lamp() -> void:
	_lamp_root = Node3D.new()
	_lamp_root.name = "ClassLamp"
	# Place to the right of the evolution panel.
	_lamp_root.position = Vector3(panel_size * 0.5 + 0.12, panel_height + 0.32, panel_depth)
	add_child(_lamp_root)

	# Lamp dome — a glowing sphere.
	_lamp_mesh = MeshInstance3D.new()
	_lamp_mesh.name = "LampDome"
	var lamp_sphere := SphereMesh.new()
	lamp_sphere.radius = 0.06
	lamp_sphere.height = 0.12
	lamp_sphere.radial_segments = 24
	lamp_sphere.rings = 12
	_lamp_mesh.mesh = lamp_sphere
	_lamp_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_lamp_material = StandardMaterial3D.new()
	_lamp_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lamp_material.emission_enabled = true
	_lamp_material.emission_energy_multiplier = 2.5
	_lamp_mesh.material_override = _lamp_material
	_lamp_root.add_child(_lamp_mesh)

	# Lamp socket (a dark cylinder behind the dome).
	var socket := MeshInstance3D.new()
	socket.name = "LampSocket"
	var socket_mesh := CylinderMesh.new()
	socket_mesh.top_radius = 0.045
	socket_mesh.bottom_radius = 0.045
	socket_mesh.height = 0.04
	socket_mesh.radial_segments = 16
	socket.mesh = socket_mesh
	var socket_mat := StandardMaterial3D.new()
	socket_mat.albedo_color = Color(0.06, 0.07, 0.1)
	socket_mat.metallic = 0.4
	socket_mat.roughness = 0.5
	socket.material_override = socket_mat
	socket.position = Vector3(0.0, 0.0, -0.05)
	socket.rotation_degrees.x = 90.0
	_lamp_root.add_child(socket)

	# "CLASS" label below the lamp.
	var lamp_caption := Label3D.new()
	lamp_caption.text = "CLASS"
	lamp_caption.font_size = 22
	lamp_caption.outline_size = 3
	lamp_caption.pixel_size = 0.001
	lamp_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lamp_caption.modulate = Color(0.6, 0.65, 0.75)
	lamp_caption.position = Vector3(0.0, -0.12, 0.0)
	_lamp_root.add_child(lamp_caption)


func _refresh_class_lamp() -> void:
	var cls: int = _class_for_rule(_rule)
	var col: Color = _color_for_class(cls)
	_lamp_material.albedo_color = col
	_lamp_material.emission = col


static func _class_for_rule(rule: int) -> int:
	if CLASS_TABLE.has(rule):
		return int(CLASS_TABLE[rule])
	return 2  # default: periodic. Most rules in the unlisted 200+ are Class 2.


func _color_for_class(cls: int) -> Color:
	match cls:
		1: return color_class_1
		2: return color_class_2
		3: return color_class_3
		4: return color_class_4
		_: return color_class_2


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	# Place below the class lamp, to the right of the evolution panel.
	_readout_root.position = Vector3(panel_size * 0.5 + 0.12, panel_height - 0.15, panel_depth)
	add_child(_readout_root)

	# Backing card.
	var card := MeshInstance3D.new()
	card.name = "ReadoutCard"
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.5, 0.36)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.25, 0.0, -0.005)
	_readout_root.add_child(card)

	# Big "Rule N".
	_readout_rule = Label3D.new()
	_readout_rule.name = "ReadoutRule"
	_readout_rule.font_size = 48
	_readout_rule.outline_size = 5
	_readout_rule.pixel_size = 0.001
	_readout_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_rule.modulate = Color(1.0, 1.0, 0.55)
	_readout_rule.position = Vector3(0.02, 0.12, 0.0)
	_readout_root.add_child(_readout_rule)

	# Class line.
	_readout_class = Label3D.new()
	_readout_class.name = "ReadoutClass"
	_readout_class.font_size = 24
	_readout_class.outline_size = 3
	_readout_class.pixel_size = 0.001
	_readout_class.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_class.modulate = Color(0.7, 0.85, 1.0)
	_readout_class.position = Vector3(0.02, 0.04, 0.0)
	_readout_root.add_child(_readout_class)

	# Claim-to-fame line.
	_readout_claim = Label3D.new()
	_readout_claim.name = "ReadoutClaim"
	_readout_claim.font_size = 20
	_readout_claim.outline_size = 3
	_readout_claim.pixel_size = 0.001
	_readout_claim.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_claim.modulate = Color(0.95, 0.7, 1.0)
	_readout_claim.position = Vector3(0.02, -0.06, 0.0)
	_readout_root.add_child(_readout_claim)


func _refresh_readout() -> void:
	var cls: int = _class_for_rule(_rule)
	_readout_rule.text = "Rule %d" % _rule
	_readout_class.text = "Class %d — %s" % [cls, _phase_name(cls)]
	if CLAIM_TABLE.has(_rule):
		_readout_claim.text = str(CLAIM_TABLE[_rule])
	else:
		_readout_claim.text = _class_typical(cls)
	if _plate_readout:
		_plate_readout.text = "Rule %d\nClass %d" % [_rule, cls]


static func _phase_name(cls: int) -> String:
	match cls:
		1: return "lambda_uniform"
		2: return "lambda_periodic"
		3: return "lambda_chaotic"
		4: return "lambda_edge"
		_: return "lambda_periodic"


static func _class_typical(cls: int) -> String:
	match cls:
		1: return "uniform — decays to a constant pattern"
		2: return "periodic — repeats or nests"
		3: return "chaotic — apparently random structure"
		4: return "edge-of-chaos — complex local persistence"
		_: return "periodic — repeats or nests"


# ── Cross-reference label ─────────────────────────────────────────────

func _build_crossref_label() -> void:
	_crossref_root = Node3D.new()
	_crossref_root.name = "CrossRef"
	# Place below the evolution panel, centered.
	_crossref_root.position = Vector3(0.0, panel_height - panel_size * 0.5 - 0.12, panel_depth)
	add_child(_crossref_root)

	# Backing strip — visible only when the label is shown.
	var bg := MeshInstance3D.new()
	bg.name = "CrossRefBg"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(panel_size * 0.95, 0.08)
	bg.mesh = bg_mesh
	_crossref_bg_mat = StandardMaterial3D.new()
	_crossref_bg_mat.albedo_color = Color(0.03, 0.06, 0.1, 0.85)
	_crossref_bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_crossref_bg_mat.roughness = 0.8
	bg.material_override = _crossref_bg_mat
	bg.position = Vector3(0.0, 0.0, -0.003)
	_crossref_root.add_child(bg)

	_crossref_label = Label3D.new()
	_crossref_label.name = "CrossRefText"
	_crossref_label.font_size = 22
	_crossref_label.outline_size = 4
	_crossref_label.pixel_size = 0.001
	_crossref_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crossref_label.modulate = Color(1.0, 0.95, 0.7)
	_crossref_label.position = Vector3(0.0, 0.0, 0.0)
	_crossref_root.add_child(_crossref_label)


func _refresh_crossref() -> void:
	if CROSSREF.has(_rule):
		_crossref_label.text = str(CROSSREF[_rule])
		_crossref_label.visible = true
		_crossref_bg_mat.albedo_color = Color(0.03, 0.06, 0.1, 0.85)
	else:
		_crossref_label.text = ""
		_crossref_label.visible = false
		# Hide the backing strip by making it fully transparent.
		_crossref_bg_mat.albedo_color = Color(0.03, 0.06, 0.1, 0.0)


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_simulate(_rule)
	_refresh_class_lamp()
	_refresh_readout()
	_refresh_crossref()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_rule"):
		_rule = clamp(int(config_data["initial_rule"]), 0, 255)
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", float(_rule) / 255.0)
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
