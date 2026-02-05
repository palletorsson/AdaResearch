# sine_wall_explanation.gd
# Shows ONE wall with animated sine values displayed
# Demonstrates: x_offset = A·sin(f·z + t)

extends Node3D

class_name SineWallExplanation

@export var display_size: float = 1.0
@export var wall_height: float = 0.5
@export var wall_length: float = 0.9
@export var amplitude: float = 0.12
@export var frequency: float = 2.0
@export var wave_speed: float = 0.4
@export var animate: bool = false
@export var wall_color: Color = Color(0.8, 0.2, 0.3)
@export var value_color: Color = Color(1.0, 1.0, 0.4)

var _wall_mesh: MeshInstance3D
var _base_plate: MeshInstance3D
var _formula_label: Label3D
var _title_label: Label3D
var _value_labels: Array[Label3D] = []
var _value_markers: Array[MeshInstance3D] = []
var _sine_curve: MeshInstance3D
var _time: float = 0.0

const SEGMENTS = 48
const VALUE_POINTS = 5  # Number of points showing values


func _ready():
	_create_base_plate()
	_create_wall()
	_create_sine_curve()
	_create_value_markers()
	_create_labels()
	_create_reference_plane()
	set_process(animate)


func _create_base_plate():
	_base_plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(display_size * 0.6, 0.02, display_size)
	_base_plate.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.08)
	mat.metallic = 0.2
	mat.roughness = 0.9
	_base_plate.material_override = mat
	_base_plate.position.y = -0.01
	add_child(_base_plate)


func _create_wall():
	_wall_mesh = MeshInstance3D.new()
	_wall_mesh.name = "SineWall"
	add_child(_wall_mesh)
	_update_wall_mesh(0.0)


func _update_wall_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_length = wall_length / 2.0
	
	for i in range(SEGMENTS):
		var z0 = lerp(-half_length, half_length, float(i) / SEGMENTS)
		var z1 = lerp(-half_length, half_length, float(i + 1) / SEGMENTS)
		
		var t0 = float(i) / SEGMENTS
		var t1 = float(i + 1) / SEGMENTS
		
		# Sine displacement
		var disp0 = amplitude * sin(frequency * TAU * t0 + phase)
		var disp1 = amplitude * sin(frequency * TAU * t1 + phase)
		
		var x0 = disp0
		var x1 = disp1
		
		# Quad vertices - wall facing +X
		var v0 = Vector3(x0, 0.0, z0)
		var v1 = Vector3(x1, 0.0, z1)
		var v2 = Vector3(x1, wall_height, z1)
		var v3 = Vector3(x0, wall_height, z0)
		
		# Color: bright where displaced most
		var intensity0 = abs(disp0) / amplitude
		var intensity1 = abs(disp1) / amplitude
		var c0 = wall_color.lerp(Color.WHITE, intensity0 * 0.4)
		var c1 = wall_color.lerp(Color.WHITE, intensity1 * 0.4)
		
		# Face toward viewer (+X direction)
		st.set_color(c0); st.add_vertex(v0)
		st.set_color(c1); st.add_vertex(v1)
		st.set_color(c1); st.add_vertex(v2)
		
		st.set_color(c0); st.add_vertex(v0)
		st.set_color(c1); st.add_vertex(v2)
		st.set_color(c0); st.add_vertex(v3)
	
	st.generate_normals()
	_wall_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.15
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = wall_color * 0.3
	mat.emission_energy_multiplier = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wall_mesh.material_override = mat


func _create_sine_curve():
	# Visual curve showing the sine wave path
	_sine_curve = MeshInstance3D.new()
	_sine_curve.name = "SineCurve"
	_sine_curve.position.y = wall_height + 0.02
	add_child(_sine_curve)


func _update_sine_curve(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var half_length = wall_length / 2.0
	
	for i in range(SEGMENTS + 1):
		var t = float(i) / SEGMENTS
		var z = lerp(-half_length, half_length, t)
		var x = amplitude * sin(frequency * TAU * t + phase)
		
		st.set_color(value_color)
		st.add_vertex(Vector3(x, 0, z))
	
	_sine_curve.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_sine_curve.material_override = mat


func _create_value_markers():
	var half_length = wall_length / 2.0
	
	for i in range(VALUE_POINTS):
		# Marker sphere
		var marker = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.02
		sphere.height = 0.04
		marker.mesh = sphere
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = value_color
		mat.emission_enabled = true
		mat.emission = value_color
		mat.emission_energy_multiplier = 0.6
		marker.material_override = mat
		
		add_child(marker)
		_value_markers.append(marker)
		
		# Value label
		var label = Label3D.new()
		label.pixel_size = 0.001
		label.font_size = 36
		label.outline_size = 4
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate = value_color
		add_child(label)
		_value_labels.append(label)


func _update_value_markers(phase: float):
	var half_length = wall_length / 2.0
	
	for i in range(VALUE_POINTS):
		var t = float(i) / (VALUE_POINTS - 1)
		var z = lerp(-half_length, half_length, t)
		var sine_value = sin(frequency * TAU * t + phase)
		var x = amplitude * sine_value
		
		# Update marker position
		_value_markers[i].position = Vector3(x, wall_height * 0.5, z)
		
		# Update label with current sine value
		_value_labels[i].text = "%.2f" % sine_value
		_value_labels[i].position = Vector3(x + 0.08, wall_height * 0.5, z)
		
		# Color based on sign
		var col = value_color if sine_value >= 0 else Color(0.4, 0.8, 1.0)
		_value_labels[i].modulate = col
		(_value_markers[i].material_override as StandardMaterial3D).emission = col
		(_value_markers[i].material_override as StandardMaterial3D).albedo_color = col


func _create_reference_plane():
	# Vertical reference plane at x=0
	var ref_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(0.001, wall_length)
	ref_plane.mesh = plane_mesh
	ref_plane.rotation.x = PI/2
	ref_plane.position = Vector3(0, wall_height / 2, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.4, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ref_plane.material_override = mat
	add_child(ref_plane)
	
	# Zero line label
	var zero_label = Label3D.new()
	zero_label.pixel_size = 0.001
	zero_label.font_size = 28
	zero_label.text = "x=0"
	zero_label.position = Vector3(-0.05, wall_height + 0.02, -wall_length/2)
	zero_label.modulate = Color(0.5, 0.5, 0.6)
	add_child(zero_label)


func _create_labels():
	# Title
	_title_label = Label3D.new()
	_title_label.pixel_size = 0.001
	_title_label.font_size = 52
	_title_label.outline_size = 6
	_title_label.text = "Sine Wall"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector3(0, wall_height + 0.22, 0)
	_title_label.modulate = wall_color
	add_child(_title_label)
	
	# Formula
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 48
	_formula_label.outline_size = 6
	_formula_label.text = "x = A·sin(f·z + t)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, wall_height + 0.12, 0)
	_formula_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_formula_label)
	
	# Z-axis label
	var z_label = Label3D.new()
	z_label.pixel_size = 0.001
	z_label.font_size = 36
	z_label.text = "z (along corridor) →"
	z_label.position = Vector3(0, -0.06, wall_length/2 + 0.08)
	z_label.rotation.x = -PI/4
	z_label.modulate = Color(0.5, 0.7, 0.9)
	add_child(z_label)
	
	# X-offset explanation
	var x_label = Label3D.new()
	x_label.pixel_size = 0.001
	x_label.font_size = 32
	x_label.text = "← x offset →"
	x_label.position = Vector3(amplitude + 0.12, wall_height/2, 0)
	x_label.rotation.y = -PI/2
	x_label.modulate = Color(0.9, 0.6, 0.5)
	add_child(x_label)
	
	# Min/max labels
	var max_label = Label3D.new()
	max_label.pixel_size = 0.001
	max_label.font_size = 28
	max_label.text = "+A"
	max_label.position = Vector3(amplitude + 0.04, wall_height + 0.04, 0)
	max_label.modulate = value_color
	add_child(max_label)
	
	var min_label = Label3D.new()
	min_label.pixel_size = 0.001
	min_label.font_size = 28
	min_label.text = "-A"
	min_label.position = Vector3(-amplitude - 0.06, wall_height + 0.04, 0)
	min_label.modulate = Color(0.4, 0.8, 1.0)
	add_child(min_label)


func _process(delta):
	if not animate:
		return
	_time += delta * wave_speed
	_update_wall_mesh(_time)
	_update_sine_curve(_time)
	_update_value_markers(_time)


# Public API
func set_amplitude(a: float) -> void:
	amplitude = a
	_refresh_static()

func set_frequency(f: float) -> void:
	frequency = f
	_refresh_static()

func set_wave_speed(s: float) -> void:
	wave_speed = s


func _refresh_static() -> void:
	if _wall_mesh == null or _sine_curve == null or _value_markers.is_empty():
		return
	_time = 0.0
	_update_wall_mesh(_time)
	_update_sine_curve(_time)
	_update_value_markers(_time)
