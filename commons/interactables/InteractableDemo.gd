extends Node3D

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")

## Interactable Demo — one row of every control type with labels.
## For inspecting, testing, and improving each VR control element.
## Run this scene directly or place as artifact in a map.

## Control definitions — ALL procedural (no scene loading, no RigidBody errors)
var CONTROLS := [
	{ "type": "button", "label": "BUTTON", "y": 0.0 },
	{ "type": "button", "label": "BUTTON\nFRONT", "y": 0.0 },
	{ "type": "knob", "label": "KNOB", "y": 0.0 },
	{ "type": "slider_v", "label": "SLIDER V", "y": 0.0 },
	{ "type": "slider_h", "label": "SLIDER H", "y": 0.0 },
	{ "type": "slider_v", "label": "SNAP", "y": 0.0 },
	{ "type": "slider_v", "label": "ZERO", "y": 0.0 },
	{ "type": "lever", "label": "LEVER", "y": 0.0 },
	{ "type": "wheel", "label": "WHEEL", "y": 0.0 },
	{ "type": "joystick", "label": "JOYSTICK", "y": -0.05 },
	{ "type": "xy_pad", "label": "XY PAD", "y": -0.05 },
]

const SPACING := 0.30  # meters between each control
const CONTROL_Z := 0.02  # forward from back panel
const LABEL_Y_OFFSET := -0.18  # below control center
const ROW_Y := 1.1  # height of row center


const PASSIVE_ELEMENTS = [
	{ "builder": "build_speaker_dots", "label": "SPEAKER\nDOTS" },
	{ "builder": "build_speaker_lines", "label": "SPEAKER\nLINES" },
	{ "builder": "build_speaker_grid", "label": "SPEAKER\nGRID" },
	{ "builder": "build_vu_meter_v", "label": "VU METER\nV" },
	{ "builder": "build_vu_meter_h", "label": "VU METER\nH" },
	{ "builder": "build_monitor_sm", "label": "MONITOR\nSM" },
	{ "builder": "build_monitor_lg", "label": "MONITOR\nLG" },
]

const ROW2_Y := 0.65  # Second row below first
const ROW3_Y := 0.20  # Third row (compounds)

## Compound layout definitions — each spawns multiple controls programmatically
const COMPOUNDS = [
	{ "type": "sliders_v", "count": 2, "label": "2x SLIDER V" },
	{ "type": "sliders_v", "count": 3, "label": "3x SLIDER V" },
	{ "type": "sliders_v", "count": 4, "label": "4x SLIDER V" },
	{ "type": "sliders_h", "count": 2, "label": "2x SLIDER H" },
	{ "type": "sliders_h", "count": 3, "label": "3x SLIDER H" },
	{ "type": "monitor_sliders", "count": 3, "label": "MONITOR\n+SLIDERS" },
	{ "type": "speaker_meters", "count": 2, "label": "SPEAKER\n+METERS" },
	{ "type": "meters_v", "count": 3, "label": "3x METERS" },
]


func _ready():
	_build_back_panel()
	_spawn_controls()
	_spawn_passive_elements()
	_spawn_compounds()
	_add_title()
	print("InteractableDemo: %d controls + %d passive + %d compounds" % [CONTROLS.size(), PASSIVE_ELEMENTS.size(), COMPOUNDS.size()])


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


func _spawn_controls():
	var start_x: float = -(CONTROLS.size() - 1) * SPACING / 2.0

	for i in CONTROLS.size():
		var def: Dictionary = CONTROLS[i]
		var ctrl_type: String = def["type"]
		var label_text: String = def["label"]
		var y_offset: float = def.get("y", 0.0)

		var x_pos: float = start_x + i * SPACING

		# Black accent frame
		var frame := MeshInstance3D.new()
		frame.name = "Frame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, 0.28, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z - 0.004)
		add_child(frame)

		# Build control procedurally (no scene loading)
		var container := Node3D.new()
		container.name = "Control_%d" % i
		container.transform.origin = Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z)
		add_child(container)
		_build_procedural_control(container, ctrl_type)

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
	var start_x: float = -(PASSIVE_ELEMENTS.size() - 1) * SPACING / 2.0

	# Back panel for row 2
	var total_w2: float = PASSIVE_ELEMENTS.size() * SPACING + 0.2
	var panel2 := MeshInstance3D.new()
	panel2.name = "BackPanel2"
	var box2 := BoxMesh.new()
	box2.size = Vector3(total_w2, 0.35, 0.008)
	panel2.mesh = box2
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color(0.50, 0.48, 0.44)
	mat2.metallic = 0.3
	mat2.roughness = 0.6
	panel2.material_override = mat2
	panel2.transform.origin = Vector3(0, ROW2_Y, -0.005)
	add_child(panel2)

	# Title for row 2
	var title2 := Label3D.new()
	title2.text = "PASSIVE ELEMENTS"
	title2.font_size = 30
	title2.pixel_size = 0.0007
	title2.modulate = Color(1.0, 1.0, 1.0)
	title2.outline_size = 5
	title2.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.transform.origin = Vector3(0, ROW2_Y + 0.22, CONTROL_Z + 0.01)
	add_child(title2)

	for i in PASSIVE_ELEMENTS.size():
		var def: Dictionary = PASSIVE_ELEMENTS[i]
		var builder: String = def["builder"]
		var label_text: String = def["label"]
		var x_pos: float = start_x + i * SPACING

		# Black accent frame
		var frame := MeshInstance3D.new()
		frame.name = "PassiveFrame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, 0.14, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z - 0.004)
		add_child(frame)

		# Build the element
		var element := Node3D.new()
		element.name = "Passive_%d" % i
		element.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z)
		add_child(element)

		match builder:
			"build_speaker_dots":
				RackPassiveElementsScript.build_speaker_dots(element)
			"build_speaker_lines":
				RackPassiveElementsScript.build_speaker_lines(element)
			"build_speaker_grid":
				RackPassiveElementsScript.build_speaker_grid(element)
			"build_vu_meter_v":
				RackPassiveElementsScript.build_vu_meter_v(element)
			"build_vu_meter_h":
				RackPassiveElementsScript.build_vu_meter_h(element)
			"build_monitor_sm":
				RackPassiveElementsScript.build_monitor(element, 0.09, 0.06)
			"build_monitor_lg":
				RackPassiveElementsScript.build_monitor(element, 0.12, 0.08)

		# Label
		var lbl := Label3D.new()
		lbl.name = "PassiveLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 28
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, ROW2_Y - 0.12, CONTROL_Z + 0.01)
		add_child(lbl)


func _spawn_compounds():
	var start_x: float = -(COMPOUNDS.size() - 1) * SPACING / 2.0

	# Back panel for row 3
	var total_w3: float = COMPOUNDS.size() * SPACING + 0.2
	var panel3 := MeshInstance3D.new()
	panel3.name = "BackPanel3"
	var box3 := BoxMesh.new()
	box3.size = Vector3(total_w3, 0.35, 0.008)
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
	title3.font_size = 30
	title3.pixel_size = 0.0007
	title3.modulate = Color(1.0, 1.0, 1.0)
	title3.outline_size = 5
	title3.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title3.transform.origin = Vector3(0, ROW3_Y + 0.22, CONTROL_Z + 0.01)
	add_child(title3)

	for i in COMPOUNDS.size():
		var def: Dictionary = COMPOUNDS[i]
		var comp_type: String = def["type"]
		var count: int = def.get("count", 2)
		var label_text: String = def["label"]
		var x_pos: float = start_x + i * SPACING

		# Black accent frame
		var frame := MeshInstance3D.new()
		frame.name = "CompFrame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, 0.14, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW3_Y, CONTROL_Z - 0.004)
		add_child(frame)

		var container := Node3D.new()
		container.name = "Compound_%d" % i
		container.transform.origin = Vector3(x_pos, ROW3_Y, CONTROL_Z)
		add_child(container)

		_build_compound(container, comp_type, count)

		var lbl := Label3D.new()
		lbl.name = "CompLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 26
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, ROW3_Y - 0.12, CONTROL_Z + 0.01)
		add_child(lbl)


## Build a single control type procedurally (no scene loading)
func _build_procedural_control(container: Node3D, ctrl_type: String) -> void:
	var copper := Color(0.75, 0.38, 0.13)
	var dark := Color(0.10, 0.10, 0.10)
	var cream := Color(0.78, 0.75, 0.67)

	match ctrl_type:
		"button":
			# Circle button
			var house_mat := StandardMaterial3D.new()
			house_mat.albedo_color = dark
			var house := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.025
			hm.bottom_radius = 0.025
			hm.height = 0.008
			hm.radial_segments = 24
			house.mesh = hm
			house.material_override = house_mat
			house.rotation_degrees.x = 90
			container.add_child(house)
			var cap_mat := StandardMaterial3D.new()
			cap_mat.albedo_color = copper
			cap_mat.emission_enabled = true
			cap_mat.emission = copper
			cap_mat.emission_energy_multiplier = 0.3
			var cap := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.018
			cm.bottom_radius = 0.018
			cm.height = 0.01
			cm.radial_segments = 24
			cap.mesh = cm
			cap.material_override = cap_mat
			cap.rotation_degrees.x = 90
			cap.transform.origin.z = 0.006
			container.add_child(cap)

		"knob":
			# Knob with indicator
			var body_mat := StandardMaterial3D.new()
			body_mat.albedo_color = Color(0.12, 0.12, 0.12)
			body_mat.metallic = 0.7
			body_mat.roughness = 0.3
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.025
			bm.bottom_radius = 0.028
			bm.height = 0.012
			bm.radial_segments = 32
			body.mesh = bm
			body.material_override = body_mat
			body.rotation_degrees.x = 90
			body.transform.origin.z = 0.006
			container.add_child(body)
			# Ring
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = dark
			var ring := MeshInstance3D.new()
			var rm := TorusMesh.new()
			rm.inner_radius = 0.030
			rm.outer_radius = 0.033
			rm.rings = 8
			rm.ring_segments = 24
			ring.mesh = rm
			ring.material_override = ring_mat
			container.add_child(ring)
			# Indicator
			var ind_mat := StandardMaterial3D.new()
			ind_mat.albedo_color = copper
			ind_mat.emission_enabled = true
			ind_mat.emission = copper
			ind_mat.emission_energy_multiplier = 0.5
			var ind := MeshInstance3D.new()
			var im := BoxMesh.new()
			im.size = Vector3(0.002, 0.018, 0.002)
			ind.mesh = im
			ind.material_override = ind_mat
			ind.transform.origin = Vector3(0, 0.015, 0.013)
			container.add_child(ind)

		"slider_v":
			_make_slider_v(container, Vector3.ZERO, 1.0)

		"slider_h":
			_make_slider_h(container, Vector3.ZERO, 1.0)

		"lever":
			# Slot + bar + ball
			var slot_mat := StandardMaterial3D.new()
			slot_mat.albedo_color = Color(0.50, 0.47, 0.42)
			var slot := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.008, 0.08, 0.004)
			slot.mesh = sm
			slot.material_override = slot_mat
			container.add_child(slot)
			var bar_mat := StandardMaterial3D.new()
			bar_mat.albedo_color = Color(0.55, 0.55, 0.55)
			bar_mat.metallic = 0.8
			bar_mat.roughness = 0.2
			var bar := MeshInstance3D.new()
			var barm := BoxMesh.new()
			barm.size = Vector3(0.004, 0.04, 0.004)
			bar.mesh = barm
			bar.material_override = bar_mat
			bar.transform.origin = Vector3(0, 0.01, 0.006)
			container.add_child(bar)
			var ball_mat := StandardMaterial3D.new()
			ball_mat.albedo_color = copper
			ball_mat.emission_enabled = true
			ball_mat.emission = copper
			ball_mat.emission_energy_multiplier = 0.3
			var ball := MeshInstance3D.new()
			var ballm := SphereMesh.new()
			ballm.radius = 0.008
			ballm.height = 0.016
			ball.mesh = ballm
			ball.material_override = ball_mat
			ball.transform.origin = Vector3(0, 0.035, 0.006)
			container.add_child(ball)

		"wheel":
			# Torus ring + dark body
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = dark
			var ring := MeshInstance3D.new()
			var rm := TorusMesh.new()
			rm.inner_radius = 0.035
			rm.outer_radius = 0.038
			rm.rings = 8
			rm.ring_segments = 32
			ring.mesh = rm
			ring.material_override = ring_mat
			container.add_child(ring)
			var body_mat := StandardMaterial3D.new()
			body_mat.albedo_color = Color(0.15, 0.14, 0.13)
			body_mat.metallic = 0.5
			body_mat.roughness = 0.4
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.030
			bm.bottom_radius = 0.030
			bm.height = 0.015
			bm.radial_segments = 24
			body.mesh = bm
			body.material_override = body_mat
			body.rotation_degrees.x = 90
			container.add_child(body)
			var ind_mat := StandardMaterial3D.new()
			ind_mat.albedo_color = copper
			ind_mat.emission_enabled = true
			ind_mat.emission = copper
			ind_mat.emission_energy_multiplier = 0.5
			var ind := MeshInstance3D.new()
			var im := BoxMesh.new()
			im.size = Vector3(0.002, 0.015, 0.001)
			ind.mesh = im
			ind.material_override = ind_mat
			ind.transform.origin = Vector3(0, 0.020, 0.009)
			container.add_child(ind)

		"joystick":
			# Base + stick + ball
			var base_mat := StandardMaterial3D.new()
			base_mat.albedo_color = dark
			var base := MeshInstance3D.new()
			var basem := CylinderMesh.new()
			basem.top_radius = 0.035
			basem.bottom_radius = 0.035
			basem.height = 0.006
			basem.radial_segments = 24
			base.mesh = basem
			base.material_override = base_mat
			base.rotation_degrees.x = 90
			container.add_child(base)
			var stick_mat := StandardMaterial3D.new()
			stick_mat.albedo_color = Color(0.55, 0.55, 0.55)
			stick_mat.metallic = 0.8
			stick_mat.roughness = 0.2
			var stick := MeshInstance3D.new()
			var stickm := CylinderMesh.new()
			stickm.top_radius = 0.005
			stickm.bottom_radius = 0.005
			stickm.height = 0.05
			stickm.radial_segments = 8
			stick.mesh = stickm
			stick.material_override = stick_mat
			stick.rotation_degrees.x = 90
			stick.transform.origin.z = 0.025
			container.add_child(stick)
			var ball_mat := StandardMaterial3D.new()
			ball_mat.albedo_color = copper
			ball_mat.emission_enabled = true
			ball_mat.emission = copper
			ball_mat.emission_energy_multiplier = 0.3
			var ball := MeshInstance3D.new()
			var ballm := SphereMesh.new()
			ballm.radius = 0.012
			ballm.height = 0.024
			ball.mesh = ballm
			ball.material_override = ball_mat
			ball.transform.origin.z = 0.052
			container.add_child(ball)

		"xy_pad":
			# Dark square pad + grid + cursor
			var pad_mat := StandardMaterial3D.new()
			pad_mat.albedo_color = Color(0.12, 0.12, 0.12)
			var pad := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.08, 0.08, 0.004)
			pad.mesh = pm
			pad.material_override = pad_mat
			container.add_child(pad)
			var cursor_mat := StandardMaterial3D.new()
			cursor_mat.albedo_color = copper
			cursor_mat.emission_enabled = true
			cursor_mat.emission = copper
			cursor_mat.emission_energy_multiplier = 0.6
			var cursor := MeshInstance3D.new()
			var curm := SphereMesh.new()
			curm.radius = 0.005
			curm.height = 0.01
			cursor.mesh = curm
			cursor.material_override = cursor_mat
			cursor.transform.origin = Vector3(0.01, -0.01, 0.005)
			container.add_child(cursor)


## Build a simple procedural slider visual (no XRTools, no scene loading)
static func _make_slider_v(parent: Node3D, pos: Vector3, sc: float) -> void:
	var track_mat := StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.10, 0.10, 0.10)
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.75, 0.38, 0.13)
	handle_mat.emission_enabled = true
	handle_mat.emission = Color(0.75, 0.38, 0.13)
	handle_mat.emission_energy_multiplier = 0.3

	var track := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.004, 0.12, 0.003) * sc
	track.mesh = tb
	track.material_override = track_mat
	track.transform.origin = pos
	parent.add_child(track)

	var handle := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.03, 0.008, 0.01) * sc
	handle.mesh = hb
	handle.material_override = handle_mat
	handle.transform.origin = pos + Vector3(0, 0.02 * sc, 0.005 * sc)
	parent.add_child(handle)


static func _make_slider_h(parent: Node3D, pos: Vector3, sc: float) -> void:
	var track_mat := StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.10, 0.10, 0.10)
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.75, 0.38, 0.13)
	handle_mat.emission_enabled = true
	handle_mat.emission = Color(0.75, 0.38, 0.13)
	handle_mat.emission_energy_multiplier = 0.3

	var track := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.12, 0.004, 0.003) * sc
	track.mesh = tb
	track.material_override = track_mat
	track.transform.origin = pos
	parent.add_child(track)

	var handle := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.008, 0.025, 0.01) * sc
	handle.mesh = hb
	handle.material_override = handle_mat
	handle.transform.origin = pos + Vector3(0.02 * sc, 0, 0.005 * sc)
	parent.add_child(handle)


func _build_compound(container: Node3D, comp_type: String, count: int) -> void:
	match comp_type:
		"sliders_v":
			var gap := 0.035
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				_make_slider_v(container, Vector3(offset + j * gap, 0, 0), 0.8)

		"sliders_h":
			var gap := 0.035
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				_make_slider_h(container, Vector3(0, offset + j * gap, 0), 0.7)

		"monitor_sliders":
			RackPassiveElementsScript.build_monitor(container, 0.09, 0.04)
			for child in container.get_children():
				child.transform.origin.y += 0.03
			var gap := 0.03
			var off := -(count - 1) * gap / 2.0
			for j in count:
				_make_slider_v(container, Vector3(off + j * gap, -0.03, 0), 0.6)

		"speaker_meters":
			var sp := Node3D.new()
			sp.transform.origin = Vector3(0, 0.025, 0)
			sp.scale = Vector3.ONE * 0.6
			container.add_child(sp)
			RackPassiveElementsScript.build_speaker_dots(sp)
			var gap := 0.035
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3((j - 0.5) * gap, -0.04, 0)
				m.scale = Vector3.ONE * 0.5
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)

		"meters_v":
			var gap := 0.03
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3(offset + j * gap, 0, 0)
				m.scale = Vector3.ONE * 0.7
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)


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
