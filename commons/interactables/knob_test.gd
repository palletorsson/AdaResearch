extends Node3D

var _knob_pivot: Node3D
var _value: float = 0.0
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _drag_start_value: float = 0.0

func _ready():
	# Bright environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.90, 0.88, 0.83)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 4.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Light
	var light := DirectionalLight3D.new()
	light.light_energy = 3.0
	light.transform = Transform3D.IDENTITY.looking_at(Vector3(-0.3, -0.5, -1), Vector3.UP)
	light.transform.origin = Vector3(0, 2, 1)
	add_child(light)

	# Camera
	var cam := Camera3D.new()
	cam.fov = 40
	cam.transform.origin = Vector3(0, 0, 0.25)
	cam.current = true
	add_child(cam)

	# Cream panel background
	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.12, 0.12, 0.008)
	panel.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.90, 0.87, 0.80)
	panel_mat.roughness = 0.8
	panel.material_override = panel_mat
	add_child(panel)

	# Rotating pivot for knob + pointer + indicator
	_knob_pivot = Node3D.new()
	_knob_pivot.name = "KnobPivot"
	_knob_pivot.transform.origin = Vector3(0, 0, 0.012)
	add_child(_knob_pivot)

	# Dark knob body (cylinder facing Z)
	var knob := MeshInstance3D.new()
	var knob_mesh := CylinderMesh.new()
	knob_mesh.top_radius = 0.024
	knob_mesh.bottom_radius = 0.028
	knob_mesh.height = 0.015
	knob_mesh.radial_segments = 32
	knob.mesh = knob_mesh
	var knob_mat := StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.12, 0.12, 0.12)
	knob_mat.metallic = 0.8
	knob_mat.roughness = 0.25
	knob.material_override = knob_mat
	knob.rotation_degrees.x = 90  # Cylinder Y-up → faces Z
	_knob_pivot.add_child(knob)

	# Base ring
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.032
	ring_mesh.bottom_radius = 0.032
	ring_mesh.height = 0.006
	ring_mesh.radial_segments = 32
	ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.15, 0.15, 0.15)
	ring_mat.metallic = 0.7
	ring_mat.roughness = 0.3
	ring.material_override = ring_mat
	ring.rotation_degrees.x = 90
	ring.transform.origin = Vector3(0, 0, 0.005)
	add_child(ring)

	# Copper indicator dot
	var ind := MeshInstance3D.new()
	var ind_mesh := SphereMesh.new()
	ind_mesh.radius = 0.004
	ind_mesh.height = 0.008
	ind.mesh = ind_mesh
	var ind_mat := StandardMaterial3D.new()
	ind_mat.albedo_color = Color(0.75, 0.38, 0.13)
	ind_mat.emission_enabled = true
	ind_mat.emission = Color(0.75, 0.38, 0.13)
	ind_mat.emission_energy_multiplier = 0.4
	ind.material_override = ind_mat
	ind.transform.origin = Vector3(0, 0.022, 0.008)
	_knob_pivot.add_child(ind)

	# White pointer line
	var ptr := MeshInstance3D.new()
	var ptr_mesh := BoxMesh.new()
	ptr_mesh.size = Vector3(0.002, 0.015, 0.002)
	ptr.mesh = ptr_mesh
	var ptr_mat := StandardMaterial3D.new()
	ptr_mat.albedo_color = Color(0.9, 0.9, 0.85)
	ptr.material_override = ptr_mat
	ptr.transform.origin = Vector3(0, 0.012, 0.008)
	_knob_pivot.add_child(ptr)

	# Tick marks around 270-degree arc with numbers
	var tick_mat := StandardMaterial3D.new()
	tick_mat.albedo_color = Color(0.15, 0.15, 0.15)
	var arc_r := 0.038
	var start_deg := 135.0
	var sweep_deg := 270.0
	for i in 11:
		var pct := float(i) / 10.0
		var angle := deg_to_rad(start_deg + sweep_deg * pct)
		var is_major := (i % 5 == 0)

		# Tick line
		var tick := MeshInstance3D.new()
		var tmesh := BoxMesh.new()
		tmesh.size = Vector3(0.001, 0.006 if is_major else 0.004, 0.001)
		tick.mesh = tmesh
		tick.material_override = tick_mat
		var tr := arc_r + (0.003 if is_major else 0.002)
		tick.transform.origin = Vector3(cos(angle) * tr, sin(angle) * tr, 0.005)
		tick.rotation.z = angle - deg_to_rad(90)
		add_child(tick)

		# Number label at major ticks
		if is_major or i % 2 == 0:
			var num := Label3D.new()
			num.text = str(i)
			num.font_size = 12
			num.pixel_size = 0.0003
			num.modulate = Color(0.2, 0.2, 0.2)
			var nr := arc_r + 0.012
			num.transform.origin = Vector3(cos(angle) * nr, sin(angle) * nr, 0.005)
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(num)

	# Label
	var lbl := Label3D.new()
	lbl.text = "KNOB TEST"
	lbl.font_size = 24
	lbl.pixel_size = 0.0006
	lbl.modulate = Color(0.1, 0.1, 0.1)
	lbl.transform.origin = Vector3(0, -0.08, 0.01)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)

	# Also load the real dial_smooth for rotation comparison
	var dial_scene := load("res://commons/interactables/dial_smooth.tscn") as PackedScene
	if dial_scene:
		var dial := dial_scene.instantiate()
		dial.name = "RealDial"
		dial.transform.origin = Vector3(0.2, 0, 0)
		add_child(dial)

		var dial_lbl := Label3D.new()
		dial_lbl.text = "REAL DIAL\n(grab to rotate)"
		dial_lbl.font_size = 18
		dial_lbl.pixel_size = 0.0005
		dial_lbl.modulate = Color(0.1, 0.1, 0.1)
		dial_lbl.transform.origin = Vector3(0.2, -0.08, 0.01)
		dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(dial_lbl)

	# Set initial rotation
	_update_knob_rotation()
	print("KnobTest: built from scratch — drag up/down to rotate")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_drag_start_value = _value
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var delta: float = -(event.position.y - _drag_start_y) / 200.0
		_value = clampf(_drag_start_value + delta, 0.0, 1.0)
		_update_knob_rotation()


func _update_knob_rotation() -> void:
	if not _knob_pivot:
		return
	# Map 0-1 to -135° to +135° (270° sweep)
	var angle_deg: float = -135.0 + _value * 270.0
	_knob_pivot.rotation_degrees.z = angle_deg
