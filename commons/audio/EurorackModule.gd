extends Node3D
class_name EurorackModule

## A single Eurorack-style module panel.
## Contains a dark aluminum panel mesh, mounting screws, name label,
## accent color stripe, and interactive sub-controls positioned by HP coordinates.

const HP_METERS: float = 0.018       # ~3.5x real HP for VR hands
const ROW_HEIGHT: float = 0.450      # ~3.5x real 3U
const PANEL_DEPTH: float = 0.008
const SCREW_RADIUS: float = 0.0025
const SCREW_HEIGHT: float = 0.002
const CONTROL_Z_OFFSET: float = 0.01 # Controls sit forward of panel face
const STRIPE_HEIGHT: float = 0.004
const LABEL_MARGIN_TOP: float = 0.015
const CTRL_LABEL_OFFSET_Y: float = -0.025  # Below control center

const SLIDER_SCENE = preload("res://commons/interactables/slider_smooth.tscn")
const ModuleFaceTextureScript = preload("res://commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd")
const JACK_SLIDER_SCALE: float = 0.22  # Scale down slider to fit beside jack
const JACK_SLIDER_OFFSET_X: float = 0.020  # Horizontal offset from jack center

# Dark material for all control backplates (knobs, sliders, displays)
static var _dark_backplate_material: StandardMaterial3D

var module_def: Dictionary = {}
var hp_width: int = 8
var row_span: int = 1
var module_id: String = ""
var controls: Dictionary = {}  # control_id -> Node3D instance
var jacks: Dictionary = {}     # jack_id -> SynthJack instance
var _panel_mesh: MeshInstance3D
var _accent_stripe: MeshInstance3D

# Materials (created once, shared)
static var _panel_material: StandardMaterial3D
static var _screw_material: StandardMaterial3D
static var _stripe_material: StandardMaterial3D


func _init_materials() -> void:
	if not _panel_material:
		_panel_material = StandardMaterial3D.new()
		_panel_material.albedo_color = Color(0.06, 0.06, 0.08)
		_panel_material.metallic = 0.92
		_panel_material.roughness = 0.22

	if not _screw_material:
		_screw_material = StandardMaterial3D.new()
		_screw_material.albedo_color = Color(0.75, 0.75, 0.78)
		_screw_material.metallic = 0.95
		_screw_material.roughness = 0.12
		_screw_material.emission_enabled = true
		_screw_material.emission = Color(0.3, 0.3, 0.32)
		_screw_material.emission_energy_multiplier = 0.05

	if not _dark_backplate_material:
		_dark_backplate_material = StandardMaterial3D.new()
		_dark_backplate_material.albedo_color = Color(0.10, 0.10, 0.13)
		_dark_backplate_material.metallic = 0.7
		_dark_backplate_material.roughness = 0.28


## Get the default unscaled size of a control type from UVAC constants.
func _get_control_default_size(ctrl_type: String, uvac: Node3D) -> Vector2:
	if "CONTROL_SIZES" in uvac:
		var sizes: Dictionary = uvac.CONTROL_SIZES
		if sizes.has(ctrl_type):
			return sizes[ctrl_type]
	# Fallback sizes for common display types
	match ctrl_type:
		"simple_waveform", "srcwave", "rack_wave":
			return Vector2(0.32, 0.24)
		"monitor", "mon", "scope":
			return Vector2(0.30, 0.30)
		"spectrum", "spec", "fft":
			return Vector2(0.30, 0.15)
	return Vector2.ZERO


## Darken the backplate of any control (knob, slider, display) to match the module panel.
func _darken_control_backplate(control: Node) -> void:
	# Try common backplate paths used by dial_smooth, slider_smooth, etc.
	for path in ["Frame/PanelMesh", "PanelMesh", "BackPlate", "Frame/BackPlate"]:
		var panel_mesh: MeshInstance3D = control.get_node_or_null(path)
		if panel_mesh:
			panel_mesh.material_override = _dark_backplate_material
			return


## Build the module from a definition dictionary.
## uvac: reference to the UniversalVRAudioController for control creation.
func build_from_definition(def: Dictionary, uvac: Node3D) -> void:
	_init_materials()
	module_def = def
	hp_width = int(def.get("hp_width", 8))
	row_span = int(def.get("row_span", 1))
	module_id = str(def.get("name", "MOD"))
	name = "Module_%s" % module_id

	var panel_w: float = hp_width * HP_METERS
	var panel_h: float = row_span * ROW_HEIGHT

	# --- Panel mesh ---
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(panel_w, panel_h, PANEL_DEPTH)
	_panel_mesh.mesh = box
	_panel_mesh.material_override = _panel_material
	add_child(_panel_mesh)

	# --- Module face texture (2D rendered panel with all controls) ---
	var face := ModuleFaceTextureScript.new()
	face.name = "ModuleFace"
	face.transform.origin = Vector3(0, 0, PANEL_DEPTH * 0.5 + 0.001)
	add_child(face)
	face.build(def)
	var _module_face = face

	# --- Mounting screws (4 corners) ---
	_add_screws(panel_w, panel_h)

	# --- 3D Controls (invisible, collision only — visuals come from face texture) ---
	var control_defs: Array = def.get("controls", [])
	for ctrl_def in control_defs:
		_spawn_control(ctrl_def, panel_w, panel_h, uvac)

	# --- Jacks ---
	var jack_defs: Array = def.get("jacks", [])
	for jack_def in jack_defs:
		_spawn_jack(jack_def, panel_w, panel_h)


func _add_screws(panel_w: float, panel_h: float) -> void:
	var screw_mesh := CylinderMesh.new()
	screw_mesh.top_radius = SCREW_RADIUS
	screw_mesh.bottom_radius = SCREW_RADIUS
	screw_mesh.height = SCREW_HEIGHT
	screw_mesh.radial_segments = 24

	var margin_x := 0.008
	var margin_y := 0.008
	var positions := [
		Vector3(-panel_w * 0.5 + margin_x, panel_h * 0.5 - margin_y, PANEL_DEPTH * 0.5 + SCREW_HEIGHT * 0.5),
		Vector3(panel_w * 0.5 - margin_x, panel_h * 0.5 - margin_y, PANEL_DEPTH * 0.5 + SCREW_HEIGHT * 0.5),
		Vector3(-panel_w * 0.5 + margin_x, -panel_h * 0.5 + margin_y, PANEL_DEPTH * 0.5 + SCREW_HEIGHT * 0.5),
		Vector3(panel_w * 0.5 - margin_x, -panel_h * 0.5 + margin_y, PANEL_DEPTH * 0.5 + SCREW_HEIGHT * 0.5),
	]

	for i in positions.size():
		var mi := MeshInstance3D.new()
		mi.name = "Screw_%d" % i
		mi.mesh = screw_mesh
		mi.material_override = _screw_material
		mi.transform.origin = positions[i]
		# Screws face forward (cylinder default is Y-up, rotate to Z-forward)
		mi.rotation_degrees.x = 90
		add_child(mi)


func _spawn_control(ctrl_def: Dictionary, panel_w: float, panel_h: float, uvac: Node3D) -> void:
	var ctrl_id: String = str(ctrl_def.get("id", "ctrl"))
	var ctrl_type: String = str(ctrl_def.get("type", "knob"))
	var x_hp: float = float(ctrl_def.get("x_hp", 0))
	var y_frac: float = float(ctrl_def.get("y_frac", 0.5))

	# Unique ID combining module name and control id
	var unique_id: String = "%s_%s" % [module_id, ctrl_id]

	# Instantiate control via UVAC public API
	var control: Node = null
	if uvac.has_method("instantiate_control"):
		control = uvac.instantiate_control(ctrl_type, unique_id)
	else:
		push_warning("EurorackModule: UVAC missing instantiate_control method")
		return

	if not control:
		push_warning("EurorackModule: Failed to instantiate control '%s' type '%s'" % [unique_id, ctrl_type])
		return

	# Add control to this module (not to UVAC parameter_container)
	add_child(control)

	# Position: x_hp from left edge, y_frac from top
	var x_pos: float = (x_hp * HP_METERS) - (panel_w * 0.5)
	var y_pos: float = (panel_h * 0.5) - (y_frac * panel_h)
	control.transform.origin = Vector3(x_pos, y_pos, PANEL_DEPTH * 0.5 + CONTROL_Z_OFFSET)

	# Configure control (labels, ranges, defaults)
	if uvac.has_method("configure_control"):
		uvac.configure_control(control, ctrl_def, ctrl_type)

	# Connect signals
	if uvac.has_method("connect_control_signals"):
		uvac.connect_control_signals(control, unique_id, ctrl_type, ctrl_def)

	# Strip ALL visual meshes — ModuleFaceTexture provides the visuals
	# Keep only collision shapes for VR/desktop interaction
	_strip_all_visuals(control)

	# Apply size constraints from width_hp if specified (for displays/monitors)
	if ctrl_def.has("width_hp"):
		var target_w: float = float(ctrl_def["width_hp"]) * HP_METERS
		# Get default size from UVAC CONTROL_SIZES or estimate from mesh
		var default_size: Vector2 = _get_control_default_size(ctrl_type, uvac)
		if default_size.x > 0:
			var scale_factor: float = target_w / default_size.x
			control.scale = Vector3.ONE * scale_factor

	# Register in UVAC active_controls
	if "active_controls" in uvac:
		uvac.active_controls[unique_id] = {
			"instance": control,
			"parameter": ctrl_def.get("parameter", ""),
			"parameter_x": ctrl_def.get("parameter_x", ""),
			"parameter_y": ctrl_def.get("parameter_y", ""),
			"config": ctrl_def,
			"type": ctrl_type
		}

	# Labels rendered by ModuleFaceTexture — no 3D labels needed

	controls[ctrl_id] = control


func _spawn_jack(jack_def: Dictionary, panel_w: float, panel_h: float) -> void:
	var jack_id: String = str(jack_def.get("id", "jack"))
	var jack_type_str: String = str(jack_def.get("type", "output"))
	var param_name: String = str(jack_def.get("parameter", ""))
	var x_hp: float = float(jack_def.get("x_hp", 0))
	var y_frac: float = float(jack_def.get("y_frac", 0.9))

	var jack := SynthJack.new()
	jack.name = "Jack_%s_%s" % [module_id, jack_id]
	jack.jack_type = SynthJack.JackType.OUTPUT if jack_type_str == "output" else SynthJack.JackType.INPUT
	jack.parameter_name = "%s_%s" % [module_id.to_lower(), param_name]

	add_child(jack)

	# Position using same HP/frac system as controls
	var x_pos: float = (x_hp * HP_METERS) - (panel_w * 0.5)
	var y_pos: float = (panel_h * 0.5) - (y_frac * panel_h)
	jack.transform.origin = Vector3(x_pos, y_pos, PANEL_DEPTH * 0.5 + 0.005)

	# Add jack label (short, above jack socket)
	var label_text: String = str(jack_def.get("label", ""))
	if not label_text.is_empty():
		var jack_label := Label3D.new()
		jack_label.name = "%s_Label" % jack_id
		jack_label.text = label_text
		jack_label.font_size = 14
		jack_label.pixel_size = 0.0004
		jack_label.modulate = Color(0.50, 0.50, 0.55)
		jack_label.outline_size = 2
		jack_label.outline_modulate = Color(0, 0, 0, 0.5)
		jack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jack_label.transform.origin = Vector3(x_pos, y_pos + 0.016, PANEL_DEPTH * 0.5 + 0.002)
		add_child(jack_label)

	# Spawn level slider next to the jack
	_spawn_jack_level_slider(jack, x_pos, y_pos)

	jacks[jack_id] = jack


func _spawn_jack_level_slider(jack: SynthJack, jack_x: float, jack_y: float) -> void:
	var slider := SLIDER_SCENE.instantiate()
	slider.name = "LevelSlider_%s" % jack.name
	add_child(slider)

	# Position: beside the jack, offset to the right, scaled small
	slider.scale = Vector3.ONE * JACK_SLIDER_SCALE
	slider.transform.origin = Vector3(
		jack_x + JACK_SLIDER_OFFSET_X,
		jack_y,
		PANEL_DEPTH * 0.5 + CONTROL_Z_OFFSET
	)

	# Configure range 0–1 (attenuation level)
	slider.set_range(0.0, 1.0)
	# Default to full level (1.0)
	slider.set_normalized_value(1.0)
	# Label it "LVL"
	slider.set_param_name("LVL")

	# Darken the panel backplate so it blends with module panel
	_darken_control_backplate(slider)

	# Connect slider signal to update jack level
	slider.slider_moved.connect(_on_jack_level_changed.bind(jack, slider))

	# Store reference on the jack
	jack.level_slider = slider
	jack.level = 1.0


func _on_jack_level_changed(position, jack: SynthJack, slider: Node3D) -> void:
	var norm: float = slider.get_normalized_value()
	jack.level = norm


## Strip all visual meshes from a 3D interactable, keeping only collision shapes.
## This makes the control invisible — ModuleFaceTexture provides the visuals.
func _strip_all_visuals(control: Node) -> void:
	for child in control.get_children():
		if child is MeshInstance3D:
			child.visible = false
		elif child is Label3D:
			child.visible = false
		# Recurse into children
		if child.get_child_count() > 0:
			_strip_all_visuals(child)
