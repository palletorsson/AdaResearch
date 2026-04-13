extends Node3D

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")

## Interactable Demo — one row of every control type with labels.
## For inspecting, testing, and improving each VR control element.
## Run this scene directly or place as artifact in a map.

## Control definitions — scenes loaded at runtime (not preload) to avoid
## RigidBody3D script compilation errors with interactable_handle.gd
var CONTROLS := [
	{ "scene": "res://commons/interactables/push_button.tscn", "label": "BUTTON", "y": 0.0 },
	{ "scene": "res://commons/interactables/push_button_front.tscn", "label": "BUTTON\nFRONT", "y": 0.0 },
	{ "scene": "res://commons/interactables/dial_smooth.tscn", "label": "KNOB", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_smooth.tscn", "label": "SLIDER V", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_horizontal.tscn", "label": "SLIDER H", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_snap.tscn", "label": "SNAP", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_zero.tscn", "label": "ZERO", "y": 0.0 },
	{ "scene": "res://commons/interactables/lever_smooth.tscn", "label": "LEVER", "y": 0.0 },
	{ "scene": "res://commons/interactables/wheel_smooth.tscn", "label": "WHEEL", "y": 0.0 },
	{ "scene": "res://commons/interactables/joystick_smooth.tscn", "label": "JOYSTICK", "y": -0.05 },
	{ "scene": "res://commons/interactables/slider_plane.tscn", "label": "XY PAD", "y": -0.05 },
]

## Row 4: New prototype modules — procedural versions of the interface_prototypes preset
const ROW4_Y := -0.25
const NEW_MODULES := [
	{ "type": "touch_grid", "label": "TOUCH\nGRID" },
	{ "type": "rotary_selector", "label": "ROTARY\nSELECTOR" },
	{ "type": "needle_meter", "label": "NEEDLE\nMETER" },
	{ "type": "patch_matrix", "label": "PATCH\nMATRIX" },
]

const SPACING := 0.30  # meters between each control
const CONTROL_Z := 0.02  # forward from back panel
const LABEL_Y_OFFSET := -0.18  # below control center
const ROW_Y := 1.1  # height of row center
const COMPOUND_FRAME_HEIGHT := 0.28
const COMPOUND_INNER_MARGIN := 0.015
const FRAME_BAR_THICKNESS := 0.008
const FRAME_BAR_DEPTH := 0.004
const FRAME_Z_OFFSET := -0.004
const VERTICAL_SLIDER_SIZE := Vector2(0.08, 0.22)
const HORIZONTAL_SLIDER_SIZE := Vector2(0.22, 0.08)
const VERTICAL_SLIDER_GAP := 0.04
const HORIZONTAL_SLIDER_GAP := 0.008
const SLIDER_VERTICAL_SCENE := "res://commons/interactables/slider_smooth.tscn"
const SLIDER_HORIZONTAL_SCENE := "res://commons/interactables/slider_horizontal.tscn"


## Row 2: Passive elements — speakers, meters, working monitors (use real scenes)
const PASSIVE_ELEMENTS = [
	{ "builder": "build_speaker_dots", "label": "SPEAKER DOTS", "width": 1 },
	{ "builder": "build_speaker_lines", "label": "SPEAKER LINES", "width": 1 },
	{ "builder": "build_speaker_grid", "label": "SPEAKER GRID", "width": 1 },
	{ "builder": "build_vu_meter_v", "label": "VU METER V", "width": 1 },
	{ "builder": "build_vu_meter_h", "label": "VU METER H", "width": 1 },
	{ "monitor": "scope", "slots": 2, "label": "SCOPE", "width": 2 },
	{ "monitor": "scope", "slots": 3, "label": "SCOPE WIDE", "width": 3 },
	{ "monitor": "spectrum", "slots": 2, "label": "SPECTRUM", "width": 2 },
	{ "monitor": "lissajous", "slots": 2, "label": "LISSAJOUS", "width": 2 },
]

const ROW2_Y := 0.65  # Second row below first
const ROW3_Y := 0.20  # Third row (compounds)

## Row 3: Compound layouts — double/triple footprint allowed
const COMPOUNDS = [
	{ "type": "sliders_v", "count": 2, "label": "2x SLIDER V", "width": 2 },
	{ "type": "sliders_v", "count": 3, "label": "3x SLIDER V", "width": 2 },
	{ "type": "sliders_v", "count": 4, "label": "4x SLIDER V", "width": 2 },
	{ "type": "sliders_h", "count": 2, "label": "2x SLIDER H", "width": 2 },
	{ "type": "sliders_h", "count": 3, "label": "3x SLIDER H", "width": 2 },
	{ "type": "sliders_h", "count": 4, "label": "4x SLIDER H", "width": 2 },
	{ "type": "monitor_sliders", "count": 3, "label": "MONITOR+SLIDERS", "width": 2 },
	{ "type": "speaker_meters", "count": 2, "label": "SPEAKER+METERS", "width": 2 },
	{ "type": "meters_v", "count": 3, "label": "3x METERS", "width": 1 },
]


func _ready():
	_build_back_panel()
	_spawn_controls()
	_spawn_passive_elements()
	_spawn_compounds()
	_spawn_new_modules()
	_add_title()
	print("InteractableDemo: %d controls + %d passive + %d compounds + %d new modules" % [CONTROLS.size(), PASSIVE_ELEMENTS.size(), COMPOUNDS.size(), NEW_MODULES.size()])


func _build_back_panel():
	var total_w: float = CONTROLS.size() * SPACING + 0.2
	var panel := MeshInstance3D.new()
	panel.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(total_w, 0.45, 0.008)
	panel.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.50, 0.48, 0.44)  # Warm gray (Rams)
	mat.metallic = 0.3
	mat.roughness = 0.6
	panel.material_override = mat
	panel.transform.origin = Vector3(0, ROW_Y, -0.005)
	add_child(panel)

	# Subtle border frame
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(total_w + 0.02, 0.47, 0.004)
	frame.mesh = frame_box
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.35, 0.33, 0.30)
	frame_mat.metallic = 0.2
	frame_mat.roughness = 0.7
	frame.material_override = frame_mat
	frame.transform.origin = Vector3(0, ROW_Y, -0.008)
	add_child(frame)


func _make_frame_material() -> StandardMaterial3D:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
	frame_mat.metallic = 0.3
	frame_mat.roughness = 0.7
	return frame_mat


func _add_outline_frame(frame_name: String, center: Vector3, width: float, height: float) -> void:
	var frame_root := Node3D.new()
	frame_root.name = frame_name
	frame_root.transform.origin = center + Vector3(0, 0, FRAME_Z_OFFSET)
	add_child(frame_root)

	var frame_mat := _make_frame_material()
	var horizontal_width: float = maxf(width, FRAME_BAR_THICKNESS)
	var vertical_height: float = maxf(height - FRAME_BAR_THICKNESS * 2.0, FRAME_BAR_THICKNESS)

	var segments := [
		{ "name": "Top", "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, height * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "name": "Bottom", "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, -height * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "name": "Left", "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(-width * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0, 0) },
		{ "name": "Right", "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(width * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0, 0) },
	]

	for segment in segments:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "%s_%s" % [frame_name, segment["name"]]
		var box := BoxMesh.new()
		box.size = segment["size"]
		mesh_instance.mesh = box
		mesh_instance.material_override = frame_mat
		mesh_instance.transform.origin = segment["pos"]
		frame_root.add_child(mesh_instance)


func _get_control_frame_size(scene_path: String) -> Vector2:
	if "slider_horizontal" in scene_path:
		return Vector2(0.25, 0.10)
	if "slider_plane" in scene_path:
		return Vector2(0.18, 0.18)
	if "push_button" in scene_path:
		return Vector2(0.10, 0.10)
	if "dial_smooth" in scene_path or "wheel_smooth" in scene_path:
		return Vector2(0.12, 0.12)
	if "lever_smooth" in scene_path:
		return Vector2(0.10, 0.18)
	if "joystick" in scene_path:
		return Vector2(0.12, 0.14)
	if "slider_" in scene_path:
		return Vector2(0.10, 0.24)
	return Vector2(0.12, 0.12)


func _get_passive_frame_size(def: Dictionary, elem_width: int) -> Vector2:
	if def.has("monitor"):
		return Vector2(elem_width * SPACING - 0.05, 0.21)

	match String(def.get("builder", "")):
		"build_speaker_dots", "build_speaker_lines", "build_speaker_grid":
			return Vector2(0.19, 0.19)
		"build_vu_meter_v":
			return Vector2(0.055, 0.22)
		"build_vu_meter_h":
			return Vector2(0.15, 0.06)
		_:
			return Vector2(0.14, 0.14)


func _get_compound_frame_size(comp_type: String, count: int, frame_width: float) -> Vector2:
	match comp_type:
		"sliders_v":
			var width: float = count * VERTICAL_SLIDER_SIZE.x + float(maxi(0, count - 1)) * VERTICAL_SLIDER_GAP + COMPOUND_INNER_MARGIN * 2.0
			return Vector2(minf(width, frame_width - 0.02), 0.25)
		"sliders_h":
			if count >= 4:
				return Vector2(minf(frame_width - 0.03, 0.52), 0.22)
			var scale: float = 1.0 if count == 2 else 0.975
			var total_height: float = HORIZONTAL_SLIDER_SIZE.y * scale * count + HORIZONTAL_SLIDER_GAP * float(maxi(0, count - 1))
			return Vector2(0.25, total_height + 0.03)
		"monitor_sliders":
			return Vector2(frame_width - 0.05, 0.23)
		"speaker_meters":
			return Vector2(0.17, 0.20)
		"meters_v":
			return Vector2(0.13, 0.22)
		_:
			return Vector2(frame_width - 0.05, 0.20)


func _spawn_controls():
	var start_x: float = -(CONTROLS.size() - 1) * SPACING / 2.0

	for i in CONTROLS.size():
		var def: Dictionary = CONTROLS[i]
		var scene_path: String = def["scene"]
		var label_text: String = def["label"]
		var y_offset: float = def.get("y", 0.0)

		var x_pos: float = start_x + i * SPACING

		# Load and instantiate control
		var scene := load(scene_path) as PackedScene
		if not scene:
			push_warning("InteractableDemo: Failed to load %s" % scene_path)
			continue

		var frame_size := _get_control_frame_size(scene_path)
		_add_outline_frame("Frame_%d" % i, Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z), frame_size.x, frame_size.y)

		var control := scene.instantiate()
		control.name = "Control_%d" % i
		control.transform.origin = Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z)
		add_child(control)

		# Name label below — white text with dark outline for contrast on gray
		var lbl := Label3D.new()
		lbl.name = "Label_%d" % i
		lbl.text = label_text
		lbl.font_size = 32
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 6
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, ROW_Y + LABEL_Y_OFFSET, CONTROL_Z + 0.01)
		add_child(lbl)

		# Index number above — bright copper with dark outline
		var idx_lbl := Label3D.new()
		idx_lbl.name = "Index_%d" % i
		idx_lbl.text = "%d" % (i + 1)
		idx_lbl.font_size = 24
		idx_lbl.pixel_size = 0.0005
		idx_lbl.modulate = Color(1.0, 0.6, 0.2)
		idx_lbl.outline_size = 4
		idx_lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		idx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		idx_lbl.transform.origin = Vector3(x_pos, ROW_Y + 0.20, CONTROL_Z + 0.01)
		add_child(idx_lbl)


func _spawn_passive_elements():
	# Calculate total width accounting for element widths
	var total_slots: float = 0
	for def in PASSIVE_ELEMENTS:
		total_slots += def.get("width", 1)
	var total_w2: float = total_slots * SPACING + 0.2

	var panel2 := MeshInstance3D.new()
	panel2.name = "BackPanel2"
	var box2 := BoxMesh.new()
	box2.size = Vector3(total_w2, 0.45, 0.008)
	panel2.mesh = box2
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color(0.50, 0.48, 0.44)
	mat2.metallic = 0.3
	mat2.roughness = 0.6
	panel2.material_override = mat2
	panel2.transform.origin = Vector3(0, ROW2_Y, -0.005)
	add_child(panel2)

	var title2 := Label3D.new()
	title2.text = "PASSIVE ELEMENTS & MONITORS"
	title2.font_size = 28
	title2.pixel_size = 0.0007
	title2.modulate = Color(1.0, 1.0, 1.0)
	title2.outline_size = 5
	title2.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.transform.origin = Vector3(0, ROW2_Y + 0.22, CONTROL_Z + 0.01)
	add_child(title2)

	var x_cursor: float = -total_w2 / 2.0 + 0.1
	for i in PASSIVE_ELEMENTS.size():
		var def: Dictionary = PASSIVE_ELEMENTS[i]
		var label_text: String = def["label"]
		var elem_width: int = def.get("width", 1)
		var x_pos: float = x_cursor + (elem_width * SPACING) / 2.0

		var frame_size := _get_passive_frame_size(def, elem_width)
		_add_outline_frame("PassiveFrame_%d" % i, Vector3(x_pos, ROW2_Y, CONTROL_Z), frame_size.x, frame_size.y)

		if def.has("monitor"):
			# Rams-styled grid monitor with SubViewport waveform
			var element := Node3D.new()
			element.name = "Monitor_%d" % i
			element.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z)
			add_child(element)
			RackPassiveElementsScript.build_monitor_grid(element, def.get("slots", 2), def["monitor"])
		elif def.has("builder"):
			var element := Node3D.new()
			element.name = "Passive_%d" % i
			element.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z)
			add_child(element)
			match def["builder"]:
				"build_speaker_dots": RackPassiveElementsScript.build_speaker_dots(element)
				"build_speaker_lines": RackPassiveElementsScript.build_speaker_lines(element)
				"build_speaker_grid": RackPassiveElementsScript.build_speaker_grid(element)
				"build_vu_meter_v": RackPassiveElementsScript.build_vu_meter_v(element)
				"build_vu_meter_h": RackPassiveElementsScript.build_vu_meter_h(element)

		var lbl := Label3D.new()
		lbl.name = "PassiveLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 24
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x_pos, ROW2_Y - 0.14, CONTROL_Z + 0.01)
		add_child(lbl)

		x_cursor += elem_width * SPACING


func _spawn_compounds():
	var total_slots: float = 0
	for def in COMPOUNDS:
		total_slots += def.get("width", 1)
	var total_w3: float = total_slots * SPACING + 0.2

	var panel3 := MeshInstance3D.new()
	panel3.name = "BackPanel3"
	var box3 := BoxMesh.new()
	box3.size = Vector3(total_w3, 0.45, 0.008)
	panel3.mesh = box3
	var mat3 := StandardMaterial3D.new()
	mat3.albedo_color = Color(0.50, 0.48, 0.44)
	mat3.metallic = 0.3
	mat3.roughness = 0.6
	panel3.material_override = mat3
	panel3.transform.origin = Vector3(0, ROW3_Y, -0.005)
	add_child(panel3)

	var title3 := Label3D.new()
	title3.text = "COMPOUND LAYOUTS"
	title3.font_size = 28
	title3.pixel_size = 0.0007
	title3.modulate = Color(1.0, 1.0, 1.0)
	title3.outline_size = 5
	title3.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title3.transform.origin = Vector3(0, ROW3_Y + 0.22, CONTROL_Z + 0.01)
	add_child(title3)

	var x_cursor: float = -total_w3 / 2.0 + 0.1
	for i in COMPOUNDS.size():
		var def: Dictionary = COMPOUNDS[i]
		var comp_type: String = def["type"]
		var count: int = def.get("count", 2)
		var label_text: String = def["label"]
		var elem_width: int = def.get("width", 1)
		var x_pos: float = x_cursor + (elem_width * SPACING) / 2.0

		var frame_width := elem_width * SPACING - 0.02
		var frame_size := _get_compound_frame_size(comp_type, count, frame_width)
		_add_outline_frame("CompFrame_%d" % i, Vector3(x_pos, ROW3_Y, CONTROL_Z), frame_size.x, frame_size.y)

		var container := Node3D.new()
		container.name = "Compound_%d" % i
		container.transform.origin = Vector3(x_pos, ROW3_Y, CONTROL_Z)
		add_child(container)

		_build_compound(container, comp_type, count, frame_width)

		var lbl := Label3D.new()
		lbl.name = "CompLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 22
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x_pos, ROW3_Y - 0.14, CONTROL_Z + 0.01)
		add_child(lbl)

		x_cursor += elem_width * SPACING


func _instantiate_compound_control(scene_path: String) -> Node3D:
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_warning("InteractableDemo: Failed to load %s" % scene_path)
		return null
	return scene.instantiate() as Node3D


func _add_vertical_slider_pack(container: Node3D, count: int, frame_width: float) -> void:
	var ideal_spread: float = (VERTICAL_SLIDER_SIZE.x + VERTICAL_SLIDER_GAP) * float(count - 1)
	var spread: float = minf(frame_width - COMPOUND_INNER_MARGIN * 2.0 - VERTICAL_SLIDER_SIZE.x, ideal_spread)
	spread = maxf(spread, 0.0)
	var step: float = spread / float(maxi(1, count - 1))
	var start_x: float = -spread * 0.5

	for j in count:
		var ctrl := _instantiate_compound_control(SLIDER_VERTICAL_SCENE)
		if not ctrl:
			continue
		ctrl.transform.origin = Vector3(start_x + step * j, 0, 0)
		container.add_child(ctrl)


func _add_horizontal_slider_pack(container: Node3D, count: int, frame_width: float) -> void:
	if count >= 4:
		var columns := 2
		var rows := int(ceil(float(count) / float(columns)))
		var usable_width: float = frame_width - COMPOUND_INNER_MARGIN * 2.0
		var usable_height: float = COMPOUND_FRAME_HEIGHT - COMPOUND_INNER_MARGIN * 2.0
		var gap_x: float = 0.04
		var gap_y: float = 0.025
		var scale_x: float = (usable_width - gap_x * float(columns - 1)) / (HORIZONTAL_SLIDER_SIZE.x * float(columns))
		var scale_y: float = (usable_height - gap_y * float(rows - 1)) / (HORIZONTAL_SLIDER_SIZE.y * float(rows))
		var scale: float = clampf(minf(scale_x, scale_y), 0.85, 1.0)
		var x_step: float = HORIZONTAL_SLIDER_SIZE.x * scale + gap_x
		var y_step: float = HORIZONTAL_SLIDER_SIZE.y * scale + gap_y
		var start_x: float = -x_step * 0.5
		var start_y: float = y_step * 0.5

		for j in count:
			var ctrl := _instantiate_compound_control(SLIDER_HORIZONTAL_SCENE)
			if not ctrl:
				continue
			var col := j % columns
			var row := int(j / columns)
			ctrl.scale = Vector3.ONE * scale
			ctrl.transform.origin = Vector3(start_x + col * x_step, start_y - row * y_step, 0)
			container.add_child(ctrl)
		return

	var usable_height: float = COMPOUND_FRAME_HEIGHT - COMPOUND_INNER_MARGIN * 2.0
	var scale: float = (usable_height - HORIZONTAL_SLIDER_GAP * float(count - 1)) / (HORIZONTAL_SLIDER_SIZE.y * float(count))
	scale = clampf(scale, 0.7, 1.0)

	var slider_height: float = HORIZONTAL_SLIDER_SIZE.y * scale
	var total_height: float = slider_height * count + HORIZONTAL_SLIDER_GAP * float(count - 1)
	var top_y: float = total_height * 0.5 - slider_height * 0.5

	for j in count:
		var ctrl := _instantiate_compound_control(SLIDER_HORIZONTAL_SCENE)
		if not ctrl:
			continue
		ctrl.scale = Vector3.ONE * scale
		ctrl.transform.origin = Vector3(0, top_y - j * (slider_height + HORIZONTAL_SLIDER_GAP), 0)
		container.add_child(ctrl)


func _build_compound(container: Node3D, comp_type: String, count: int, frame_width: float) -> void:
	match comp_type:
		"sliders_v":
			_add_vertical_slider_pack(container, count, frame_width)

		"sliders_h":
			_add_horizontal_slider_pack(container, count, frame_width)

		"monitor_sliders":
			# Monitor on top, sliders below
			RackPassiveElementsScript.build_monitor(container, 0.09, 0.04)
			# Shift monitor up
			for child in container.get_children():
				if child is Node3D:
					child.transform.origin.y += 0.03
			# Add sliders below
			var gap := 0.03
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				var ctrl := _instantiate_compound_control(SLIDER_VERTICAL_SCENE)
				if not ctrl:
					continue
				ctrl.transform.origin = Vector3(offset + j * gap, -0.03, 0)
				ctrl.scale = Vector3.ONE * 0.55
				container.add_child(ctrl)

		"speaker_meters":
			# Speaker on top, meters below
			var sp := Node3D.new()
			sp.transform.origin = Vector3(0, 0.025, 0)
			sp.scale = Vector3.ONE * 0.6
			container.add_child(sp)
			RackPassiveElementsScript.build_speaker_dots(sp)
			# Meters below
			var gap := 0.035
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3((j - 0.5) * gap, -0.04, 0)
				m.scale = Vector3.ONE * 0.5
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)

		"meters_v":
			# Multiple VU meters side by side
			var gap := 0.03
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3(offset + j * gap, 0, 0)
				m.scale = Vector3.ONE * 0.7
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)


func _spawn_new_modules():
	var start_x: float = -(NEW_MODULES.size() - 1) * SPACING / 2.0
	var total_w4: float = NEW_MODULES.size() * SPACING + 0.2

	# Back panel
	var panel4 := MeshInstance3D.new()
	panel4.name = "BackPanel4"
	var box4 := BoxMesh.new()
	box4.size = Vector3(total_w4, 0.45, 0.008)
	panel4.mesh = box4
	var mat4 := StandardMaterial3D.new()
	mat4.albedo_color = Color(0.50, 0.48, 0.44)
	mat4.metallic = 0.3
	mat4.roughness = 0.6
	panel4.material_override = mat4
	panel4.transform.origin = Vector3(0, ROW4_Y, -0.005)
	add_child(panel4)

	var title4 := Label3D.new()
	title4.text = "NEW MODULES"
	title4.font_size = 28
	title4.pixel_size = 0.0007
	title4.modulate = Color(1.0, 1.0, 1.0)
	title4.outline_size = 5
	title4.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title4.transform.origin = Vector3(0, ROW4_Y + 0.28, CONTROL_Z + 0.01)
	add_child(title4)

	var copper := Color(0.75, 0.38, 0.13)
	var dark := Color(0.10, 0.10, 0.10)
	var cream := Color(0.78, 0.75, 0.67)

	for i in NEW_MODULES.size():
		var def: Dictionary = NEW_MODULES[i]
		var mod_type: String = def["type"]
		var label_text: String = def["label"]
		var x_pos: float = start_x + i * SPACING

		# Black accent frame
		var frame := MeshInstance3D.new()
		frame.name = "NewFrame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, COMPOUND_FRAME_HEIGHT, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW4_Y, CONTROL_Z - 0.004)
		add_child(frame)

		var container := Node3D.new()
		container.name = "NewModule_%d" % i
		container.transform.origin = Vector3(x_pos, ROW4_Y, CONTROL_Z)
		add_child(container)

		_build_new_module(container, mod_type, copper, dark, cream)

		var lbl := Label3D.new()
		lbl.name = "NewLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 24
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, ROW4_Y - 0.18, CONTROL_Z + 0.01)
		add_child(lbl)


func _build_new_module(c: Node3D, t: String, copper: Color, dark: Color, cream: Color) -> void:
	match t:
		"touch_grid":
			# XY touch surface — dark pad with grid lines + copper cursor
			var s := 0.09
			var pad_mat := StandardMaterial3D.new()
			pad_mat.albedo_color = Color(0.05, 0.05, 0.05)
			pad_mat.metallic = 0.2
			pad_mat.roughness = 0.8
			var pad := MeshInstance3D.new()
			pad.mesh = BoxMesh.new()
			pad.mesh.size = Vector3(s, s, 0.005)
			pad.material_override = pad_mat
			c.add_child(pad)
			# Grid lines
			var grid_mat := StandardMaterial3D.new()
			grid_mat.albedo_color = Color(0.2, 0.2, 0.2)
			for gi in 5:
				var line_h := MeshInstance3D.new()
				line_h.mesh = BoxMesh.new()
				line_h.mesh.size = Vector3(s * 0.9, 0.0008, 0.001)
				line_h.material_override = grid_mat
				line_h.transform.origin = Vector3(0, -s * 0.4 + gi * s * 0.2, 0.004)
				c.add_child(line_h)
				var line_v := MeshInstance3D.new()
				line_v.mesh = BoxMesh.new()
				line_v.mesh.size = Vector3(0.0008, s * 0.9, 0.001)
				line_v.material_override = grid_mat
				line_v.transform.origin = Vector3(-s * 0.4 + gi * s * 0.2, 0, 0.004)
				c.add_child(line_v)
			# Cursor
			var cursor_mat := StandardMaterial3D.new()
			cursor_mat.albedo_color = copper
			cursor_mat.emission_enabled = true
			cursor_mat.emission = copper
			cursor_mat.emission_energy_multiplier = 0.6
			var cursor := MeshInstance3D.new()
			cursor.mesh = SphereMesh.new()
			cursor.mesh.radius = 0.006
			cursor.mesh.height = 0.012
			cursor.material_override = cursor_mat
			cursor.transform.origin = Vector3(0.01, -0.01, 0.006)
			c.add_child(cursor)
			# Crosshair lines from cursor
			var ch_mat := StandardMaterial3D.new()
			ch_mat.albedo_color = Color(copper, 0.4)
			var ch_h := MeshInstance3D.new()
			ch_h.mesh = BoxMesh.new()
			ch_h.mesh.size = Vector3(s, 0.0005, 0.001)
			ch_h.material_override = ch_mat
			ch_h.transform.origin = Vector3(0, -0.01, 0.005)
			c.add_child(ch_h)
			var ch_v := MeshInstance3D.new()
			ch_v.mesh = BoxMesh.new()
			ch_v.mesh.size = Vector3(0.0005, s, 0.001)
			ch_v.material_override = ch_mat
			ch_v.transform.origin = Vector3(0.01, 0, 0.005)
			c.add_child(ch_v)

		"rotary_selector":
			# Stepped rotary — circle with position dots around edge
			var r := 0.035
			var steps := 8
			# Body
			var body_mat := StandardMaterial3D.new()
			body_mat.albedo_color = Color(0.12, 0.12, 0.12)
			body_mat.metallic = 0.7
			body_mat.roughness = 0.3
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = r * 0.75
			bm.bottom_radius = r * 0.8
			bm.height = 0.014
			bm.radial_segments = 32
			body.mesh = bm
			body.material_override = body_mat
			body.rotation_degrees.x = 90
			body.transform.origin.z = 0.007
			c.add_child(body)
			# Outer ring
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = dark
			var ring := MeshInstance3D.new()
			var rm := TorusMesh.new()
			rm.inner_radius = r
			rm.outer_radius = r + 0.003
			rm.rings = 8
			rm.ring_segments = 32
			ring.mesh = rm
			ring.material_override = ring_mat
			c.add_child(ring)
			# Position dots
			var start_a := deg_to_rad(135.0)
			var sweep_a := deg_to_rad(270.0)
			for si in steps:
				var pct := float(si) / float(steps - 1)
				var angle := start_a + sweep_a * pct
				var is_selected := si == 2  # default position
				var dot_mat := StandardMaterial3D.new()
				dot_mat.albedo_color = copper if is_selected else Color(0.4, 0.4, 0.4)
				if is_selected:
					dot_mat.emission_enabled = true
					dot_mat.emission = copper
					dot_mat.emission_energy_multiplier = 0.5
				var dot := MeshInstance3D.new()
				dot.mesh = SphereMesh.new()
				dot.mesh.radius = 0.003 if is_selected else 0.002
				dot.mesh.height = 0.006 if is_selected else 0.004
				dot.material_override = dot_mat
				dot.transform.origin = Vector3(cos(angle) * (r + 0.008), sin(angle) * (r + 0.008), 0.003)
				c.add_child(dot)
			# Pointer
			var ptr_mat := StandardMaterial3D.new()
			ptr_mat.albedo_color = Color(0.9, 0.9, 0.85)
			var ptr_angle := start_a + sweep_a * (2.0 / 7.0)
			var ptr := MeshInstance3D.new()
			ptr.mesh = BoxMesh.new()
			ptr.mesh.size = Vector3(0.002, r * 0.5, 0.002)
			ptr.material_override = ptr_mat
			ptr.transform.origin = Vector3(cos(ptr_angle) * r * 0.35, sin(ptr_angle) * r * 0.35, 0.015)
			ptr.rotation.z = -ptr_angle
			c.add_child(ptr)

		"needle_meter":
			# Analog needle meter — cream face, arc scale, needle
			var mw := 0.09
			var mh := 0.07
			# Face
			var face_mat := StandardMaterial3D.new()
			face_mat.albedo_color = cream
			face_mat.metallic = 0.1
			face_mat.roughness = 0.8
			var face := MeshInstance3D.new()
			face.mesh = BoxMesh.new()
			face.mesh.size = Vector3(mw, mh, 0.004)
			face.material_override = face_mat
			c.add_child(face)
			# Arc scale (tick marks)
			var arc_r := mw * 0.38
			var arc_center := Vector3(0, -mh * 0.25, 0.003)
			var arc_mat := StandardMaterial3D.new()
			arc_mat.albedo_color = dark
			for ti in 11:
				var pct := float(ti) / 10.0
				var angle := deg_to_rad(180.0 + pct * 180.0)
				var is_major := ti % 5 == 0
				var t_inner := arc_r * 0.85
				var t_outer := arc_r * (1.05 if is_major else 0.98)
				var tick := MeshInstance3D.new()
				tick.mesh = BoxMesh.new()
				tick.mesh.size = Vector3(0.001, (t_outer - t_inner), 0.001)
				tick.material_override = arc_mat
				var mid_r := (t_inner + t_outer) / 2.0
				tick.transform.origin = arc_center + Vector3(cos(angle) * mid_r, sin(angle) * mid_r, 0)
				tick.rotation.z = angle - deg_to_rad(90)
				c.add_child(tick)
			# Needle
			var needle_mat := StandardMaterial3D.new()
			needle_mat.albedo_color = copper
			needle_mat.emission_enabled = true
			needle_mat.emission = copper
			needle_mat.emission_energy_multiplier = 0.4
			var needle_angle := deg_to_rad(180.0 + 0.65 * 180.0)
			var needle := MeshInstance3D.new()
			needle.mesh = BoxMesh.new()
			needle.mesh.size = Vector3(0.0015, arc_r * 0.9, 0.001)
			needle.material_override = needle_mat
			needle.transform.origin = arc_center + Vector3(cos(needle_angle) * arc_r * 0.45, sin(needle_angle) * arc_r * 0.45, 0.001)
			needle.rotation.z = needle_angle - deg_to_rad(90)
			c.add_child(needle)
			# Pivot dot
			var pivot_mat := StandardMaterial3D.new()
			pivot_mat.albedo_color = dark
			var pivot := MeshInstance3D.new()
			pivot.mesh = SphereMesh.new()
			pivot.mesh.radius = 0.003
			pivot.mesh.height = 0.006
			pivot.material_override = pivot_mat
			pivot.transform.origin = arc_center + Vector3(0, 0, 0.002)
			c.add_child(pivot)

		"patch_matrix":
			# 4x2 jack grid — output row on top, input row on bottom
			var cols := 4
			var gap_x := 0.022
			var gap_y := 0.04
			var start_x := -(cols - 1) * gap_x / 2.0
			# Output jacks (top row, orange rings)
			for ji in cols:
				var jx := start_x + ji * gap_x
				var socket_mat := StandardMaterial3D.new()
				socket_mat.albedo_color = Color(0.02, 0.02, 0.02)
				var socket := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.005
				sm.bottom_radius = 0.004
				sm.height = 0.005
				sm.radial_segments = 16
				socket.mesh = sm
				socket.material_override = socket_mat
				socket.rotation_degrees.x = 90
				socket.transform.origin = Vector3(jx, gap_y / 2.0, 0)
				c.add_child(socket)
				var ring_mat := StandardMaterial3D.new()
				ring_mat.albedo_color = copper
				ring_mat.emission_enabled = true
				ring_mat.emission = copper
				ring_mat.emission_energy_multiplier = 0.4
				var ring := MeshInstance3D.new()
				var rrm := TorusMesh.new()
				rrm.inner_radius = 0.006
				rrm.outer_radius = 0.008
				rrm.rings = 8
				rrm.ring_segments = 16
				ring.mesh = rrm
				ring.material_override = ring_mat
				ring.transform.origin = Vector3(jx, gap_y / 2.0, 0.003)
				c.add_child(ring)
			# Input jacks (bottom row, blue rings)
			for ji in cols:
				var jx := start_x + ji * gap_x
				var socket_mat := StandardMaterial3D.new()
				socket_mat.albedo_color = Color(0.02, 0.02, 0.02)
				var socket := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.005
				sm.bottom_radius = 0.004
				sm.height = 0.005
				sm.radial_segments = 16
				socket.mesh = sm
				socket.material_override = socket_mat
				socket.rotation_degrees.x = 90
				socket.transform.origin = Vector3(jx, -gap_y / 2.0, 0)
				c.add_child(socket)
				var ring_mat := StandardMaterial3D.new()
				ring_mat.albedo_color = Color(0.27, 0.55, 0.95)
				ring_mat.emission_enabled = true
				ring_mat.emission = Color(0.27, 0.55, 0.95)
				ring_mat.emission_energy_multiplier = 0.4
				var ring := MeshInstance3D.new()
				var rrm := TorusMesh.new()
				rrm.inner_radius = 0.006
				rrm.outer_radius = 0.008
				rrm.rings = 8
				rrm.ring_segments = 16
				ring.mesh = rrm
				ring.material_override = ring_mat
				ring.transform.origin = Vector3(jx, -gap_y / 2.0, 0.003)
				c.add_child(ring)
			# Divider line between rows
			var div_mat := StandardMaterial3D.new()
			div_mat.albedo_color = Color(0.3, 0.3, 0.3)
			var div := MeshInstance3D.new()
			div.mesh = BoxMesh.new()
			div.mesh.size = Vector3(cols * gap_x + 0.01, 0.001, 0.001)
			div.material_override = div_mat
			div.transform.origin = Vector3(0, 0, 0.003)
			c.add_child(div)
			# Labels
			var out_lbl := Label3D.new()
			out_lbl.text = "OUT"
			out_lbl.font_size = 14
			out_lbl.pixel_size = 0.0004
			out_lbl.modulate = copper
			out_lbl.transform.origin = Vector3(0, gap_y / 2.0 + 0.015, 0.005)
			c.add_child(out_lbl)
			var in_lbl := Label3D.new()
			in_lbl.text = "IN"
			in_lbl.font_size = 14
			in_lbl.pixel_size = 0.0004
			in_lbl.modulate = Color(0.27, 0.55, 0.95)
			in_lbl.transform.origin = Vector3(0, -gap_y / 2.0 - 0.015, 0.005)
			c.add_child(in_lbl)


func _add_title():
	var title := Label3D.new()
	title.name = "Title"
	title.text = "INTERACTABLE CONTROLS"
	title.font_size = 36
	title.pixel_size = 0.0008
	title.modulate = Color(0.10, 0.10, 0.10)
	title.outline_size = 3
	title.outline_modulate = Color(0.7, 0.68, 0.64, 0.4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.transform.origin = Vector3(0, ROW_Y + 0.28, CONTROL_Z + 0.005)
	add_child(title)


func apply_grid_config(_config: Dictionary) -> void:
	pass  # Map placement compatibility
