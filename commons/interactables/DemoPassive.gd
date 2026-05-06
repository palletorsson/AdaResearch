extends Node3D

## Row 2 only — passive elements (speakers, meters, monitors). No scene loading.

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")
const SPACING := 0.30
const ROW_Y := 1.1

func _ready():
	var elements := [
		{ "builder": "build_speaker_dots", "label": "SPEAKER\nDOTS" },
		{ "builder": "build_speaker_lines", "label": "SPEAKER\nLINES" },
		{ "builder": "build_speaker_grid", "label": "SPEAKER\nGRID" },
		{ "builder": "build_vu_meter_v", "label": "VU METER V" },
		{ "builder": "build_vu_meter_h", "label": "VU METER H" },
		{ "builder": "build_monitor_sm", "label": "MONITOR SM" },
		{ "builder": "build_monitor_lg", "label": "MONITOR LG" },
	]

	var start_x := -(elements.size() - 1) * SPACING / 2.0
	var total_w := elements.size() * SPACING + 0.2

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

	for i in elements.size():
		var def: Dictionary = elements[i]
		var x := start_x + i * SPACING
		var container := Node3D.new()
		container.transform.origin = Vector3(x, ROW_Y, 0.02)
		add_child(container)

		match def["builder"]:
			"build_speaker_dots": RackPassiveElementsScript.build_speaker_dots(container)
			"build_speaker_lines": RackPassiveElementsScript.build_speaker_lines(container)
			"build_speaker_grid": RackPassiveElementsScript.build_speaker_grid(container)
			"build_vu_meter_v": RackPassiveElementsScript.build_vu_meter_v(container)
			"build_vu_meter_h": RackPassiveElementsScript.build_vu_meter_h(container)
			"build_monitor_sm": RackPassiveElementsScript.build_monitor(container, 0.09, 0.06)
			"build_monitor_lg": RackPassiveElementsScript.build_monitor(container, 0.12, 0.08)

		var lbl := Label3D.new()
		lbl.text = def["label"]
		lbl.font_size = 26
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1, 1, 1)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x, ROW_Y - 0.14, 0.03)
		add_child(lbl)

	print("DemoPassive: %d elements" % elements.size())


func apply_grid_config(_config: Dictionary) -> void:
	pass
