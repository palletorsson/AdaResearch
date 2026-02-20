# ===========================================================================
# GravityWell.gd - Rubber-Sheet Gravity Well Visualization
# A deformable grid mesh that warps around a movable mass
# Balls roll toward the depression — the classic GR teaching metaphor
#
# QFEP: Geometry IS gravity — mass tells space how to curve.
# ===========================================================================
extends Node3D

class_name GravityWell

## Grid parameters
@export var grid_size: float = 1.0
@export var grid_resolution: int = 24
@export var well_depth: float = 0.3
@export var well_radius: float = 0.25

## Mass parameters
@export var mass_strength: float = 1.0:
	set(value):
		mass_strength = clampf(value, 0.1, 3.0)
		_update_sheet()

## Particle count
@export var particle_count: int = 6

## Colors
@export var sheet_color: Color = Color(0.3, 0.5, 1.0, 0.6)
@export var mass_color: Color = Color(1.0, 0.8, 0.2)
@export var particle_color: Color = Color(1.0, 0.3, 0.4)

# Internal state
var _sheet_mesh: MeshInstance3D
var _mass_marker: MeshInstance3D
var _mass_pos: Vector3 = Vector3.ZERO  # XZ position of mass on sheet

# Test particles rolling on the sheet
var _particles: Array = []  # [{pos: Vector3, vel: Vector3, mesh: MeshInstance3D}]

var _info_label: Label3D
var _control_panel: Node3D
var _grid_verts: PackedVector3Array  # flat grid
var _grid_normals: PackedVector3Array

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_sheet()
	_create_mass_marker()
	_create_particles()
	_create_labels()
	_create_vr_controls()
	_update_sheet()

func _create_sheet():
	_sheet_mesh = MeshInstance3D.new()
	_sheet_mesh.name = "GravitySheet"
	add_child(_sheet_mesh)

func _create_mass_marker():
	_mass_marker = MeshInstance3D.new()
	_mass_marker.name = "MassMarker"
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	_mass_marker.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = mass_color
	mat.emission_enabled = true
	mat.emission = mass_color
	mat.emission_energy_multiplier = 1.0
	_mass_marker.material_override = mat
	add_child(_mass_marker)

func _create_particles():
	for i in range(particle_count):
		var mesh := MeshInstance3D.new()
		mesh.name = "Particle_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.015
		sphere.height = 0.03
		mesh.mesh = sphere

		var mat := StandardMaterial3D.new()
		var hue := float(i) / float(particle_count)
		var color := Color.from_hsv(hue, 0.8, 1.0)
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.5
		mat.emission_energy_multiplier = 1.5
		mesh.material_override = mat
		add_child(mesh)

		# Random starting position on the sheet edge
		var angle := randf() * TAU
		var r := grid_size * 0.4
		var pos := Vector3(cos(angle) * r, 0, sin(angle) * r)
		# Give tangential velocity for orbiting
		var tangent := Vector3(-sin(angle), 0, cos(angle))
		var speed := randf_range(0.1, 0.3)

		_particles.append({
			"pos": pos,
			"vel": tangent * speed,
			"mesh": mesh,
		})

func _update_sheet():
	# Build a grid mesh that deforms around the mass position
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := grid_size / 2.0
	var step := grid_size / float(grid_resolution)

	# Generate vertex grid with well deformation
	var verts: Array = []  # 2D array [row][col]
	for j in range(grid_resolution + 1):
		var row: Array[Vector3] = []
		for i in range(grid_resolution + 1):
			var x := -half + i * step
			var z := -half + j * step
			var y := _compute_well_depth(x, z)
			row.append(Vector3(x, y, z))
		verts.append(row)

	# Build triangles with normals and vertex colors
	for j in range(grid_resolution):
		for i in range(grid_resolution):
			var tl: Vector3 = verts[j][i]
			var tr: Vector3 = verts[j][i + 1]
			var bl: Vector3 = verts[j + 1][i]
			var br: Vector3 = verts[j + 1][i + 1]

			# Depth-based color: deeper = more blue
			var avg_y := (tl.y + tr.y + bl.y + br.y) / 4.0
			var depth_ratio := clampf(-avg_y / (well_depth * mass_strength), 0, 1)
			var color := sheet_color.lerp(Color(0.1, 0.2, 0.8, 0.7), depth_ratio)

			# Triangle 1: tl, bl, tr
			var n1 := (bl - tl).cross(tr - tl).normalized()
			surface_tool.set_normal(n1)
			surface_tool.set_color(color)
			surface_tool.add_vertex(tl)
			surface_tool.set_normal(n1)
			surface_tool.set_color(color)
			surface_tool.add_vertex(bl)
			surface_tool.set_normal(n1)
			surface_tool.set_color(color)
			surface_tool.add_vertex(tr)

			# Triangle 2: tr, bl, br
			var n2 := (bl - tr).cross(br - tr).normalized()
			surface_tool.set_normal(n2)
			surface_tool.set_color(color)
			surface_tool.add_vertex(tr)
			surface_tool.set_normal(n2)
			surface_tool.set_color(color)
			surface_tool.add_vertex(bl)
			surface_tool.set_normal(n2)
			surface_tool.set_color(color)
			surface_tool.add_vertex(br)

	_sheet_mesh.mesh = surface_tool.commit()

	# Material for the sheet
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = sheet_color * 0.2
	mat.emission_energy_multiplier = 0.3
	_sheet_mesh.material_override = mat

	# Update mass marker position
	var mass_y := _compute_well_depth(_mass_pos.x, _mass_pos.z)
	_mass_marker.position = Vector3(_mass_pos.x, mass_y - 0.03, _mass_pos.z)

func _compute_well_depth(x: float, z: float) -> float:
	var dx := x - _mass_pos.x
	var dz := z - _mass_pos.z
	var dist := sqrt(dx * dx + dz * dz)
	# Gaussian-ish well: depth falls off with distance
	var depth := -well_depth * mass_strength * exp(-dist * dist / (well_radius * well_radius))
	return depth

func _compute_gradient(x: float, z: float) -> Vector3:
	# Numerical gradient of the well surface (slope direction)
	var eps := 0.01
	var dy_dx := (_compute_well_depth(x + eps, z) - _compute_well_depth(x - eps, z)) / (2.0 * eps)
	var dy_dz := (_compute_well_depth(x, z + eps) - _compute_well_depth(x, z - eps)) / (2.0 * eps)
	# Gradient points downhill on the surface
	return Vector3(dy_dx, 0, dy_dz)

func _physics_process(delta: float):
	var half := grid_size / 2.0
	var damping := 0.995

	for p in _particles:
		# Acceleration from surface gradient (ball rolls downhill)
		var grad := _compute_gradient(p["pos"].x, p["pos"].z)
		var accel := grad * 8.0  # Scale for responsiveness

		p["vel"] += accel * delta
		p["vel"] *= damping
		p["pos"] += p["vel"] * delta

		# Bounce off edges
		if abs(p["pos"].x) > half:
			p["pos"].x = sign(p["pos"].x) * half
			p["vel"].x *= -0.6
		if abs(p["pos"].z) > half:
			p["pos"].z = sign(p["pos"].z) * half
			p["vel"].z *= -0.6

		# Place on surface
		var y := _compute_well_depth(p["pos"].x, p["pos"].z)
		p["mesh"].position = Vector3(p["pos"].x, y + 0.015, p["pos"].z)

func _move_mass(new_pos: Vector3):
	_mass_pos = Vector3(clampf(new_pos.x, -grid_size * 0.3, grid_size * 0.3), 0, clampf(new_pos.z, -grid_size * 0.3, grid_size * 0.3))
	_update_sheet()

func _scatter_particles():
	for p in _particles:
		var angle := randf() * TAU
		var r := grid_size * randf_range(0.2, 0.4)
		p["pos"] = Vector3(cos(angle) * r, 0, sin(angle) * r)
		var tangent := Vector3(-sin(angle), 0, cos(angle))
		p["vel"] = tangent * randf_range(0.1, 0.3)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, 0.3, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.text = "GRAVITY WELL\nMass warps space — balls follow the curve"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.1, grid_size / 2.0 + 0.2)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel
	var panel_back := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Scatter button
	var scatter_btn = PUSH_BUTTON.instantiate()
	scatter_btn.name = "ScatterBtn"
	scatter_btn.position = Vector3(-0.08, 0.025, 0)
	scatter_btn.scale = Vector3(0.65, 0.65, 0.65)
	_control_panel.add_child(scatter_btn)
	_add_button_label(scatter_btn, "SCATTER")
	var scatter_area = scatter_btn.get_node_or_null("InteractableAreaButton")
	if scatter_area:
		scatter_area.button_pressed.connect(func(_b): _scatter_particles())

	# Center mass button
	var center_btn = PUSH_BUTTON.instantiate()
	center_btn.name = "CenterBtn"
	center_btn.position = Vector3(0.08, 0.025, 0)
	center_btn.scale = Vector3(0.65, 0.65, 0.65)
	_control_panel.add_child(center_btn)
	_add_button_label(center_btn, "CENTER")
	var center_area = center_btn.get_node_or_null("InteractableAreaButton")
	if center_area:
		center_area.button_pressed.connect(func(_b): _move_mass(Vector3.ZERO))

	# Mass strength slider
	var strength_slider = SLIDER_HORIZONTAL.instantiate()
	strength_slider.name = "StrengthSlider"
	strength_slider.position = Vector3(0, -0.025, 0)
	strength_slider.rotation_degrees.x = -30
	strength_slider.scale = Vector3(0.8, 0.8, 0.8)
	var strength_label = strength_slider.get_node_or_null("Frame/LabelName")
	if strength_label:
		strength_label.text = "MASS"
	_control_panel.add_child(strength_slider)
	strength_slider.slider_moved.connect(func(_pos):
		if strength_slider.has_method("get_normalized_value"):
			mass_strength = 0.1 + strength_slider.get_normalized_value() * 2.9
	)

func _add_button_label(btn: Node, text: String):
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _scatter_particles()
			KEY_R: _move_mass(Vector3.ZERO); _scatter_particles()
			KEY_UP: mass_strength = minf(mass_strength + 0.2, 3.0)
			KEY_DOWN: mass_strength = maxf(mass_strength - 0.2, 0.1)

func reset():
	_move_mass(Vector3.ZERO)
	_scatter_particles()
