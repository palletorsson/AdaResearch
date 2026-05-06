extends Node3D

## Row 3 only — compound layouts. All procedural, no scene loading.

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")
const SPACING := 0.30
const ROW_Y := 1.1

func _ready():
	var compounds := [
		{ "type": "sliders_v", "count": 2, "label": "2x SLIDER V" },
		{ "type": "sliders_v", "count": 3, "label": "3x SLIDER V" },
		{ "type": "sliders_v", "count": 4, "label": "4x SLIDER V" },
		{ "type": "sliders_h", "count": 2, "label": "2x SLIDER H" },
		{ "type": "sliders_h", "count": 3, "label": "3x SLIDER H" },
		{ "type": "monitor_sliders", "count": 3, "label": "MON+SLIDERS" },
		{ "type": "speaker_meters", "count": 2, "label": "SPK+METERS" },
		{ "type": "meters_v", "count": 3, "label": "3x METERS" },
	]

	var start_x := -(compounds.size() - 1) * SPACING / 2.0
	var total_w := compounds.size() * SPACING + 0.2

	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(total_w, 0.35, 0.008)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.50, 0.48, 0.44)
	mat.metallic = 0.3
	mat.roughness = 0.6
	panel.material_override = mat
	panel.transform.origin = Vector3(0, ROW_Y, -0.005)
	add_child(panel)

	var copper := Color(0.75, 0.38, 0.13)
	var dark := Color(0.10, 0.10, 0.10)

	for i in compounds.size():
		var def: Dictionary = compounds[i]
		var x := start_x + i * SPACING
		var container := Node3D.new()
		container.transform.origin = Vector3(x, ROW_Y, 0.02)
		add_child(container)
		_build(container, def["type"], def.get("count", 2), copper, dark)

		var lbl := Label3D.new()
		lbl.text = def["label"]
		lbl.font_size = 24
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1, 1, 1)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x, ROW_Y - 0.14, 0.03)
		add_child(lbl)

	print("DemoCompounds: %d compounds" % compounds.size())


func _build(c: Node3D, t: String, count: int, copper: Color, dark: Color) -> void:
	match t:
		"sliders_v":
			var gap := 0.035
			var off := -(count - 1) * gap / 2.0
			for j in count:
				_slider_v(c, Vector3(off + j * gap, 0, 0), 0.8, copper, dark)
		"sliders_h":
			var gap := 0.035
			var off := -(count - 1) * gap / 2.0
			for j in count:
				_slider_h(c, Vector3(0, off + j * gap, 0), 0.7, copper, dark)
		"monitor_sliders":
			RackPassiveElementsScript.build_monitor(c, 0.09, 0.04)
			for child in c.get_children():
				if child is Node3D: child.transform.origin.y += 0.03
			var gap := 0.03
			var off := -(count - 1) * gap / 2.0
			for j in count:
				_slider_v(c, Vector3(off + j * gap, -0.03, 0), 0.6, copper, dark)
		"speaker_meters":
			var sp := Node3D.new()
			sp.transform.origin = Vector3(0, 0.025, 0)
			sp.scale = Vector3.ONE * 0.6
			c.add_child(sp)
			RackPassiveElementsScript.build_speaker_dots(sp)
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3((j - 0.5) * 0.035, -0.04, 0)
				m.scale = Vector3.ONE * 0.5
				c.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)
		"meters_v":
			var gap := 0.03
			var off := -(count - 1) * gap / 2.0
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3(off + j * gap, 0, 0)
				m.scale = Vector3.ONE * 0.7
				c.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)


func _slider_v(parent: Node3D, pos: Vector3, sc: float, copper: Color, dark: Color) -> void:
	var track := MeshInstance3D.new()
	track.mesh = BoxMesh.new()
	track.mesh.size = Vector3(0.004, 0.12, 0.003) * sc
	track.material_override = _mat(dark, 0.0)
	track.transform.origin = pos
	parent.add_child(track)
	var handle := MeshInstance3D.new()
	handle.mesh = BoxMesh.new()
	handle.mesh.size = Vector3(0.03, 0.008, 0.01) * sc
	handle.material_override = _mat(copper, 0.3)
	handle.transform.origin = pos + Vector3(0, 0.02 * sc, 0.005 * sc)
	parent.add_child(handle)


func _slider_h(parent: Node3D, pos: Vector3, sc: float, copper: Color, dark: Color) -> void:
	var track := MeshInstance3D.new()
	track.mesh = BoxMesh.new()
	track.mesh.size = Vector3(0.12, 0.004, 0.003) * sc
	track.material_override = _mat(dark, 0.0)
	track.transform.origin = pos
	parent.add_child(track)
	var handle := MeshInstance3D.new()
	handle.mesh = BoxMesh.new()
	handle.mesh.size = Vector3(0.008, 0.025, 0.01) * sc
	handle.material_override = _mat(copper, 0.3)
	handle.transform.origin = pos + Vector3(0.02 * sc, 0, 0.005 * sc)
	parent.add_child(handle)


func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func apply_grid_config(_config: Dictionary) -> void:
	pass
