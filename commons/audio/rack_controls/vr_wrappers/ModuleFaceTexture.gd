# ModuleFaceTexture.gd
# Renders an entire eurorack module face as a single 2D Control layout
# inside a SubViewport, then maps the texture onto a 3D quad mesh.
# This replaces per-control VRFacePlates with one unified module texture.

extends Node3D
class_name ModuleFaceTexture

const HP_PX: float = 18.0    # pixels per HP unit (0.018m * 1000 px/m)
const ROW_PX: float = 450.0  # pixels per row (0.450m * 1000 px/m)
const PX_PER_M: float = 1000.0
const VIEWPORT_SCALE: int = 2  # 2x resolution for clarity

# Scene paths for 2D control types
const CONTROL_SCENES: Dictionary = {
	"knob": "res://commons/audio/rack_controls/RackKnob.tscn",
	"dial": "res://commons/audio/rack_controls/RackKnob.tscn",
	"nb": "res://commons/audio/rack_controls/RackKnob.tscn",
	"rotary": "res://commons/audio/rack_controls/RackKnob.tscn",
	"slv": "res://commons/audio/rack_controls/RackSliderV.tscn",
	"slider": "res://commons/audio/rack_controls/RackSliderV.tscn",
	"slider_vertical": "res://commons/audio/rack_controls/RackSliderV.tscn",
	"slh": "res://commons/audio/rack_controls/RackSliderH.tscn",
	"slider_horizontal": "res://commons/audio/rack_controls/RackSliderH.tscn",
	"sls": "res://commons/audio/rack_controls/RackSliderStepped.tscn",
	"slider_snap": "res://commons/audio/rack_controls/RackSliderStepped.tscn",
	"slz": "res://commons/audio/rack_controls/RackSliderBipolar.tscn",
	"slider_zero": "res://commons/audio/rack_controls/RackSliderBipolar.tscn",
	"btn": "res://commons/audio/rack_controls/RackButton.tscn",
	"button": "res://commons/audio/rack_controls/RackButton.tscn",
	"trigger": "res://commons/audio/rack_controls/RackButton.tscn",
	"wheel": "res://commons/audio/rack_controls/RackWheel.tscn",
	"whl": "res://commons/audio/rack_controls/RackWheel.tscn",
	"xy": "res://commons/audio/rack_controls/RackXYPad.tscn",
	"xypad": "res://commons/audio/rack_controls/RackXYPad.tscn",
	"joystick": "res://commons/audio/rack_controls/RackJoystick.tscn",
	"js": "res://commons/audio/rack_controls/RackJoystick.tscn",
	"lever": "res://commons/audio/rack_controls/RackLever.tscn",
	"lv": "res://commons/audio/rack_controls/RackLever.tscn",
	"meter": "res://commons/audio/rack_controls/RackMeter.tscn",
	"mtr": "res://commons/audio/rack_controls/RackMeter.tscn",
	"lbl": "res://commons/audio/rack_controls/RackLabel.tscn",
	"label": "res://commons/audio/rack_controls/RackLabel.tscn",
	"div": "res://commons/audio/rack_controls/RackDivider.tscn",
	"divider": "res://commons/audio/rack_controls/RackDivider.tscn",
}

var _viewport: SubViewport
var _face_mesh: MeshInstance3D
var _panel_control: Control
var _control_instances: Dictionary = {}  # ctrl_id -> RackControlBase
var _physical_w: float = 0.0
var _physical_h: float = 0.0
var _uvac: Node = null
var _module_prefix: String = ""


## Build the module face from a module definition dictionary.
func build(module_def: Dictionary, uvac: Node = null, module_prefix: String = "") -> void:
	_uvac = uvac
	_module_prefix = module_prefix

	var hp_width: int = int(module_def.get("hp_width", 8))
	var row_span: int = int(module_def.get("row_span", 1))
	var module_name: String = str(module_def.get("name", "MOD"))
	var accent_hex: String = str(module_def.get("color_accent", "#F27426"))
	var accent_color := Color(accent_hex)
	var controls_defs: Array = module_def.get("controls", [])

	# Pixel dimensions
	var px_w: float = hp_width * HP_PX
	var px_h: float = row_span * ROW_PX

	# Physical size in meters
	_physical_w = px_w / PX_PER_M
	_physical_h = px_h / PX_PER_M

	# Viewport at scaled resolution
	var vp_w: int = int(px_w) * VIEWPORT_SCALE
	var vp_h: int = int(px_h) * VIEWPORT_SCALE

	_viewport = SubViewport.new()
	_viewport.name = "FaceViewport"
	_viewport.disable_3d = true
	_viewport.size = Vector2i(vp_w, vp_h)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	add_child(_viewport)

	# Root panel control (fills viewport)
	_panel_control = Control.new()
	_panel_control.name = "ModulePanel2D"
	_panel_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(_panel_control)

	# Scale factor: viewport pixels are VIEWPORT_SCALE × layout pixels
	var sf: float = float(VIEWPORT_SCALE)

	# Dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.52, 0.50, 0.46)  # Warm gray panel (Rams)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_control.add_child(bg)

	# Accent stripe at top
	var stripe := ColorRect.new()
	stripe.name = "AccentStripe"
	stripe.color = accent_color
	stripe.position = Vector2(px_w * 0.06 * sf, 18 * sf)
	stripe.size = Vector2(px_w * 0.88 * sf, 4 * sf)
	_panel_control.add_child(stripe)

	# Module name label
	var name_lbl := Label.new()
	name_lbl.name = "ModuleName"
	name_lbl.text = module_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", int(14 * sf))
	name_lbl.add_theme_color_override("font_color", Color(0.10, 0.10, 0.10))  # Black text on gray
	name_lbl.position = Vector2(0, 2 * sf)
	name_lbl.size = Vector2(vp_w, 18 * sf)
	_panel_control.add_child(name_lbl)

	# Spawn 2D controls
	for ctrl_def in controls_defs:
		var ctrl_id: String = str(ctrl_def.get("id", ""))
		var ctrl_type: String = str(ctrl_def.get("type", "knob"))
		var x_hp: float = float(ctrl_def.get("x_hp", 0))
		var y_frac: float = float(ctrl_def.get("y_frac", 0.5))
		var label: String = str(ctrl_def.get("label", ""))
		var default_val: float = float(ctrl_def.get("default", 0.5))
		var min_val: float = float(ctrl_def.get("min", 0.0))
		var max_val: float = float(ctrl_def.get("max", 1.0))

		# Display types: render as green scope rectangles in the 2D panel
		var is_display: bool = ctrl_type in ["monitor", "mon", "scope", "spectrum", "spec", "fft",
				"waveform", "wave", "osc", "simple_waveform", "srcwave", "rack_wave",
				"lissajous", "liss", "xy_wave", "paramwave"]
		if is_display:
			var disp_w_hp: float = float(ctrl_def.get("width_hp", 6))
			var disp_w: float = disp_w_hp * HP_PX * sf
			var disp_h: float = min(y_frac * px_h * sf * 0.5, 120.0 * sf)
			var disp_x: float = x_hp * HP_PX * sf
			var disp_y: float = y_frac * px_h * sf - disp_h / 2.0
			_add_scope_display(disp_x, disp_y, disp_w, disp_h, label, sf)
			continue

		if not CONTROL_SCENES.has(ctrl_type):
			continue

		var scene_path: String = CONTROL_SCENES[ctrl_type]
		var scene := load(scene_path) as PackedScene
		if not scene:
			continue

		var ctrl_node: Control = scene.instantiate() as Control
		if ctrl_node == null:
			continue

		var ctrl_size: Vector2 = ctrl_node.custom_minimum_size if ctrl_node.custom_minimum_size != Vector2.ZERO else Vector2(80, 100)
		if ctrl_def.has("width_hp"):
			ctrl_size.x = float(ctrl_def.get("width_hp", 0.0)) * HP_PX
		if ctrl_def.has("height_frac"):
			ctrl_size.y = float(ctrl_def.get("height_frac", 0.0)) * px_h
		elif ctrl_def.has("height_px"):
			ctrl_size.y = float(ctrl_def.get("height_px", 0.0))
		ctrl_node.custom_minimum_size = ctrl_size
		ctrl_node.size = ctrl_size

		# Set label and default value
		if "control_label" in ctrl_node:
			ctrl_node.control_label = label
		var style_variant: String = str(ctrl_def.get("style", ctrl_def.get("style_variant", "")))
		if not style_variant.is_empty() and "style_variant" in ctrl_node:
			ctrl_node.style_variant = style_variant
		var step_count: int = int(ctrl_def.get("step_count", 0))
		if step_count > 0:
			if "step_count" in ctrl_node:
				ctrl_node.step_count = step_count
			elif "steps" in ctrl_node:
				ctrl_node.steps = step_count
		if "normalized_value" in ctrl_node:
			var norm: float = 0.5
			if max_val != min_val:
				norm = clampf((default_val - min_val) / (max_val - min_val), 0.0, 1.0)
			ctrl_node.normalized_value = norm
		if "normalized_value_y" in ctrl_node:
			var default_val_y: float = float(ctrl_def.get("default_y", ctrl_def.get("default", 0.5)))
			var min_val_y: float = float(ctrl_def.get("min_y", ctrl_def.get("min", 0.0)))
			var max_val_y: float = float(ctrl_def.get("max_y", ctrl_def.get("max", 1.0)))
			var norm_y: float = 0.5
			if max_val_y != min_val_y:
				norm_y = clampf((default_val_y - min_val_y) / (max_val_y - min_val_y), 0.0, 1.0)
			ctrl_node.normalized_value_y = norm_y

		# Position in viewport pixel space (scaled)
		var cx: float = x_hp * HP_PX * sf - ctrl_size.x * sf / 2.0
		var cy: float = y_frac * px_h * sf - ctrl_size.y * sf / 2.0

		# Scale the control to match viewport resolution
		ctrl_node.scale = Vector2.ONE * sf
		ctrl_node.position = Vector2(cx, cy)

		_panel_control.add_child(ctrl_node)
		_control_instances[ctrl_id] = ctrl_node
		_register_control_with_uvac(ctrl_id, ctrl_type, ctrl_node, ctrl_def)

		# Set button colors — must be deferred so _ready() finishes first
		var btn_color_str: String = str(ctrl_def.get("color", ""))
		if not btn_color_str.is_empty():
			var c_node = ctrl_node
			var c_color = Color(btn_color_str)
			call_deferred("_apply_button_color", c_node, c_color)

	# Create quad mesh textured with viewport
	_face_mesh = MeshInstance3D.new()
	_face_mesh.name = "FaceQuad"
	var quad := QuadMesh.new()
	quad.size = Vector2(_physical_w, _physical_h)
	_face_mesh.mesh = quad
	add_child(_face_mesh)

	# Add collision body for VR pointer interaction
	_setup_pointer_collision()

	# Defer texture assignment to after node is in tree
	call_deferred("_assign_texture")


## Sync a single control's value (called when 3D interactable moves).
func sync_control(ctrl_id: String, normalized: float) -> void:
	if _control_instances.has(ctrl_id):
		var ctrl = _control_instances[ctrl_id]
		if "normalized_value" in ctrl:
			ctrl.normalized_value = normalized


## Sync Y axis for XY pads / joysticks.
func sync_control_y(ctrl_id: String, normalized: float) -> void:
	if _control_instances.has(ctrl_id):
		var ctrl = _control_instances[ctrl_id]
		if "normalized_value_y" in ctrl:
			ctrl.normalized_value_y = normalized


## Get the 2D control instance for a given id.
func get_2d_control(ctrl_id: String) -> Control:
	return _control_instances.get(ctrl_id)


func _register_control_with_uvac(ctrl_id: String, ctrl_type: String, ctrl_node: Control, ctrl_def: Dictionary) -> void:
	if _uvac == null or _module_prefix.is_empty():
		return

	if not ("active_controls" in _uvac):
		return

	var unique_id := "%s_%s" % [_module_prefix, ctrl_id]
	_uvac.active_controls[unique_id] = {
		"instance": ctrl_node,
		"parameter": ctrl_def.get("parameter", ""),
		"parameter_x": ctrl_def.get("parameter_x", ""),
		"parameter_y": ctrl_def.get("parameter_y", ""),
		"config": ctrl_def,
		"type": ctrl_type
	}

	if ctrl_node.has_signal("value_changed"):
		if ctrl_type in ["xy", "xypad", "2df", "pad", "js", "joystick"]:
			ctrl_node.value_changed.connect(_on_dual_axis_x_changed.bind(unique_id))
		elif ctrl_type in ["btn", "button", "trigger"]:
			ctrl_node.value_changed.connect(_on_button_value_changed.bind(unique_id))
		else:
			ctrl_node.value_changed.connect(_on_control_value_changed.bind(unique_id))

	if ctrl_node.has_signal("value_y_changed"):
		ctrl_node.value_y_changed.connect(_on_dual_axis_y_changed.bind(unique_id))


func _on_control_value_changed(_value: float, control_id: String) -> void:
	if _uvac and _uvac.has_method("_on_parameter_changed_json"):
		_uvac._on_parameter_changed_json(_value, control_id)


func _on_dual_axis_x_changed(value: float, control_id: String) -> void:
	_store_dual_axis_values(control_id, value, null)
	_trigger_uvac_update(control_id)


func _on_dual_axis_y_changed(value: float, control_id: String) -> void:
	_store_dual_axis_values(control_id, null, value)
	_trigger_uvac_update(control_id)


func _on_button_value_changed(value: float, control_id: String) -> void:
	if _uvac and "active_controls" in _uvac and _uvac.active_controls.has(control_id):
		_uvac.active_controls[control_id]["toggle_state"] = value >= 0.5
	_trigger_uvac_update(control_id)


func _store_dual_axis_values(control_id: String, x_value: Variant, y_value: Variant) -> void:
	if _uvac == null or not ("active_controls" in _uvac) or not _uvac.active_controls.has(control_id):
		return

	var control_data: Dictionary = _uvac.active_controls[control_id]
	if x_value != null:
		control_data["last_x"] = x_value
	if y_value != null:
		control_data["last_y"] = y_value

	var control: Control = control_data.get("instance", null) as Control
	if control:
		if control.has_method("get_normalized_value"):
			control_data["last_x"] = control.get_normalized_value()
		if control.has_method("get_normalized_value_y"):
			control_data["last_y"] = control.get_normalized_value_y()

	_uvac.active_controls[control_id] = control_data


func _trigger_uvac_update(control_id: String) -> void:
	if _uvac == null:
		return

	if _uvac.has_method("_update_waveform_displays"):
		_uvac._update_waveform_displays()
	if _uvac.has_method("_on_parameter_changed_json"):
		_uvac._on_parameter_changed_json(0.0, control_id)


var _collision_body: StaticBody3D
var _is_pointer_pressed: bool = false


## Create a StaticBody3D with collision shape matching the panel quad.
## The body has pointer_event() method so XRToolsPointerEvent.report() finds it.
func _setup_pointer_collision() -> void:
	_collision_body = StaticBody3D.new()
	_collision_body.name = "PanelCollision"
	# Pointable layer (21) + UI layer (23) — matches XR pointer DEFAULT_MASK
	_collision_body.collision_layer = (1 << 20) | (1 << 22)
	_collision_body.collision_mask = 0

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(_physical_w, _physical_h, 0.005)
	shape.shape = box
	_collision_body.add_child(shape)

	# Attach a tiny script that forwards pointer_event to us
	var script := GDScript.new()
	script.source_code = """extends StaticBody3D

var _face_texture: Node3D

func pointer_event(event) -> void:
	if _face_texture and _face_texture.has_method("_on_pointer_event"):
		_face_texture._on_pointer_event(event)
"""
	script.reload()
	_collision_body.set_script(script)
	_collision_body.set("_face_texture", self)

	add_child(_collision_body)


## Handle XR pointer events — convert 3D hit position to 2D viewport coordinates.
func pointer_event(event) -> void:
	_on_pointer_event(event)


func _on_pointer_event(event) -> void:
	if not _viewport or not is_instance_valid(_viewport):
		return

	var pos_2d := _global_to_viewport(event.position)

	match event.event_type:
		0:  # ENTERED
			pass
		1:  # EXITED
			if _is_pointer_pressed:
				_push_mouse_button(pos_2d, false)
				_is_pointer_pressed = false
		2:  # PRESSED
			_is_pointer_pressed = true
			_push_mouse_button(pos_2d, true)
		3:  # RELEASED
			_push_mouse_button(pos_2d, false)
			_is_pointer_pressed = false
		4:  # MOVED
			_push_mouse_motion(pos_2d)


## Convert a 3D world position to 2D viewport coordinates.
func _global_to_viewport(world_pos: Vector3) -> Vector2:
	var local_pos := global_transform.affine_inverse() * world_pos
	# Map from local 3D (-w/2..w/2, -h/2..h/2) to viewport pixels (0..vp_w, 0..vp_h)
	var vp_size := Vector2(_viewport.size)
	var x := (local_pos.x / _physical_w + 0.5) * vp_size.x
	var y := (0.5 - local_pos.y / _physical_h) * vp_size.y  # Y flipped
	return Vector2(clampf(x, 0, vp_size.x), clampf(y, 0, vp_size.y))


func _push_mouse_button(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	_viewport.push_input(ev)


func _push_mouse_motion(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	if _is_pointer_pressed:
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	_viewport.push_input(ev)


func _apply_button_color(ctrl_node: Control, color: Color) -> void:
	if "_released_color" in ctrl_node:
		ctrl_node._released_color = color
	if "_pressed_color" in ctrl_node:
		ctrl_node._pressed_color = color.lightened(0.3)
	ctrl_node.queue_redraw()


## Draw a scope/waveform display area as a green-tinted rectangle with animated wave.
func _add_scope_display(x: float, y: float, w: float, h: float, label_text: String, sf: float) -> void:
	# Dark bezel
	var bezel := ColorRect.new()
	bezel.color = Color(0.04, 0.06, 0.04)
	bezel.position = Vector2(x - 2 * sf, y - 2 * sf)
	bezel.size = Vector2(w + 4 * sf, h + 4 * sf)
	_panel_control.add_child(bezel)

	# Scope background
	var scope_bg := ColorRect.new()
	scope_bg.color = Color(0.02, 0.08, 0.03)
	scope_bg.position = Vector2(x, y)
	scope_bg.size = Vector2(w, h)
	_panel_control.add_child(scope_bg)

	# Grid lines (horizontal)
	for i in 5:
		var line := ColorRect.new()
		line.color = Color(0.08, 0.15, 0.08, 0.4)
		line.position = Vector2(x, y + (float(i) / 5.0) * h)
		line.size = Vector2(w, 1 * sf)
		_panel_control.add_child(line)

	# Grid lines (vertical)
	for i in 8:
		var line := ColorRect.new()
		line.color = Color(0.08, 0.15, 0.08, 0.4)
		line.position = Vector2(x + (float(i) / 8.0) * w, y)
		line.size = Vector2(1 * sf, h)
		_panel_control.add_child(line)

	# Label
	if not label_text.is_empty():
		var lbl := Label.new()
		lbl.text = label_text
		lbl.add_theme_font_size_override("font_size", int(9 * sf))
		lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4, 0.7))
		lbl.position = Vector2(x + 3 * sf, y + 2 * sf)
		_panel_control.add_child(lbl)


func _assign_texture() -> void:
	if not _viewport or not _face_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission_texture = _viewport.get_texture()
	mat.emission_energy_multiplier = 0.25
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_face_mesh.material_override = mat
