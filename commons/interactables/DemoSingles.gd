extends Node3D

## Row 1 only — single procedural controls. No scene loading.

const SPACING := 0.30
const CONTROL_Z := 0.02
const ROW_Y := 1.1

func _ready():
	var types := ["button", "knob", "slider_v", "slider_h", "lever", "wheel", "joystick", "xy_pad"]
	var labels := ["BUTTON", "KNOB", "SLIDER V", "SLIDER H", "LEVER", "WHEEL", "JOYSTICK", "XY PAD"]
	var start_x := -(types.size() - 1) * SPACING / 2.0

	# Back panel
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(types.size() * SPACING + 0.2, 0.35, 0.008)
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

	for i in types.size():
		var x := start_x + i * SPACING
		var container := Node3D.new()
		container.transform.origin = Vector3(x, ROW_Y, CONTROL_Z)
		add_child(container)
		_build(container, types[i], copper, dark)

		var lbl := Label3D.new()
		lbl.text = labels[i]
		lbl.font_size = 28
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1, 1, 1)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x, ROW_Y - 0.15, CONTROL_Z + 0.01)
		add_child(lbl)

	print("DemoSingles: %d controls" % types.size())


func _build(c: Node3D, t: String, copper: Color, dark: Color) -> void:
	match t:
		"button":
			var m := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.02
			cm.height = 0.01
			cm.radial_segments = 24
			m.mesh = cm
			m.material_override = _mat(copper, 0.3)
			m.rotation_degrees.x = 90
			m.transform.origin.z = 0.005
			c.add_child(m)
		"knob":
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.025
			bm.bottom_radius = 0.028
			bm.height = 0.012
			bm.radial_segments = 32
			body.mesh = bm
			body.material_override = _mat(Color(0.12, 0.12, 0.12), 0.0)
			body.rotation_degrees.x = 90
			body.transform.origin.z = 0.006
			c.add_child(body)
			var ind := MeshInstance3D.new()
			ind.mesh = BoxMesh.new()
			ind.mesh.size = Vector3(0.002, 0.018, 0.002)
			ind.material_override = _mat(copper, 0.5)
			ind.transform.origin = Vector3(0, 0.015, 0.013)
			c.add_child(ind)
		"slider_v":
			var track := MeshInstance3D.new()
			track.mesh = BoxMesh.new()
			track.mesh.size = Vector3(0.004, 0.12, 0.003)
			track.material_override = _mat(dark, 0.0)
			c.add_child(track)
			var handle := MeshInstance3D.new()
			handle.mesh = BoxMesh.new()
			handle.mesh.size = Vector3(0.03, 0.008, 0.01)
			handle.material_override = _mat(copper, 0.3)
			handle.transform.origin = Vector3(0, 0.02, 0.005)
			c.add_child(handle)
		"slider_h":
			var track := MeshInstance3D.new()
			track.mesh = BoxMesh.new()
			track.mesh.size = Vector3(0.12, 0.004, 0.003)
			track.material_override = _mat(dark, 0.0)
			c.add_child(track)
			var handle := MeshInstance3D.new()
			handle.mesh = BoxMesh.new()
			handle.mesh.size = Vector3(0.008, 0.025, 0.01)
			handle.material_override = _mat(copper, 0.3)
			handle.transform.origin = Vector3(0.02, 0, 0.005)
			c.add_child(handle)
		"lever":
			var slot := MeshInstance3D.new()
			slot.mesh = BoxMesh.new()
			slot.mesh.size = Vector3(0.008, 0.08, 0.004)
			slot.material_override = _mat(Color(0.50, 0.47, 0.42), 0.0)
			c.add_child(slot)
			var ball := MeshInstance3D.new()
			ball.mesh = SphereMesh.new()
			ball.mesh.radius = 0.008
			ball.mesh.height = 0.016
			ball.material_override = _mat(copper, 0.3)
			ball.transform.origin = Vector3(0, 0.03, 0.006)
			c.add_child(ball)
		"wheel":
			var ring := MeshInstance3D.new()
			ring.mesh = TorusMesh.new()
			ring.mesh.inner_radius = 0.035
			ring.mesh.outer_radius = 0.038
			ring.material_override = _mat(dark, 0.0)
			c.add_child(ring)
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.030
			bm.bottom_radius = 0.030
			bm.height = 0.015
			bm.radial_segments = 24
			body.mesh = bm
			body.material_override = _mat(Color(0.15, 0.14, 0.13), 0.0)
			body.rotation_degrees.x = 90
			c.add_child(body)
		"joystick":
			var base := MeshInstance3D.new()
			var basem := CylinderMesh.new()
			basem.top_radius = 0.035
			basem.bottom_radius = 0.035
			basem.height = 0.006
			basem.radial_segments = 24
			base.mesh = basem
			base.material_override = _mat(dark, 0.0)
			base.rotation_degrees.x = 90
			c.add_child(base)
			var ball := MeshInstance3D.new()
			ball.mesh = SphereMesh.new()
			ball.mesh.radius = 0.012
			ball.mesh.height = 0.024
			ball.material_override = _mat(copper, 0.3)
			ball.transform.origin.z = 0.05
			c.add_child(ball)
		"xy_pad":
			var pad := MeshInstance3D.new()
			pad.mesh = BoxMesh.new()
			pad.mesh.size = Vector3(0.08, 0.08, 0.004)
			pad.material_override = _mat(Color(0.12, 0.12, 0.12), 0.0)
			c.add_child(pad)
			var cursor := MeshInstance3D.new()
			cursor.mesh = SphereMesh.new()
			cursor.mesh.radius = 0.005
			cursor.mesh.height = 0.01
			cursor.material_override = _mat(copper, 0.6)
			cursor.transform.origin = Vector3(0.01, -0.01, 0.005)
			c.add_child(cursor)


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
