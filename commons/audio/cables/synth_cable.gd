extends Node3D
class_name SynthCable

## A patch cable with two grabbable plugs for VR modular synth
## Plugs can be grabbed and inserted into SynthJack sockets

signal connection_changed(output_jack: SynthJack, input_jack: SynthJack)

@export var cable_color: Color = Color(0.8, 0.2, 0.2)
@export var cable_thickness: float = 0.008
@export var plug_length: float = 0.025
@export var plug_radius: float = 0.01
@export var gravity_sag: float = 0.15
@export var tube_sides: int = 8
@export var curve_segments: int = 16

var plug_a: SynthCablePlug
var plug_b: SynthCablePlug
var cable_mesh: MeshInstance3D
var curve: Curve3D

# Connection state
var connected_jack_a: SynthJack = null
var connected_jack_b: SynthJack = null


func _ready():
	curve = Curve3D.new()
	_create_plugs()
	_create_cable_mesh()
	_update_cable()


func _process(_delta):
	_update_cable()


func _create_plugs():
	# Create plug A (one end)
	plug_a = SynthCablePlug.new()
	plug_a.name = "PlugA"
	plug_a.plug_color = cable_color
	plug_a.plug_radius = plug_radius
	plug_a.plug_length = plug_length
	plug_a.position = Vector3(-0.15, 0, 0)
	add_child(plug_a)
	plug_a.snapped_to_jack.connect(_on_plug_a_snapped)
	plug_a.unsnapped_from_jack.connect(_on_plug_a_unsnapped)
	
	# Create plug B (other end)
	plug_b = SynthCablePlug.new()
	plug_b.name = "PlugB"
	plug_b.plug_color = cable_color
	plug_b.plug_radius = plug_radius
	plug_b.plug_length = plug_length
	plug_b.position = Vector3(0.15, 0, 0)
	add_child(plug_b)
	plug_b.snapped_to_jack.connect(_on_plug_b_snapped)
	plug_b.unsnapped_from_jack.connect(_on_plug_b_unsnapped)


func _create_cable_mesh():
	cable_mesh = MeshInstance3D.new()
	cable_mesh.name = "CableMesh"
	add_child(cable_mesh)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = cable_color
	mat.metallic = 0.1
	mat.roughness = 0.8
	cable_mesh.material_override = mat


func _update_cable():
	if not plug_a or not plug_b:
		return
	
	var start_pos = plug_a.get_cable_attachment_point()
	var end_pos = plug_b.get_cable_attachment_point()
	
	# Convert to local space
	start_pos = to_local(start_pos)
	end_pos = to_local(end_pos)
	
	# Generate cable mesh
	_generate_cable_mesh(start_pos, end_pos)


func _generate_cable_mesh(start: Vector3, end: Vector3):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate curve points with catenary sag
	var positions: Array[Vector3] = []
	var distance = start.distance_to(end)
	var sag = gravity_sag * distance
	
	for i in range(curve_segments + 1):
		var t = float(i) / float(curve_segments)
		var pos = start.lerp(end, t)
		
		# Add catenary sag
		var sag_amount = sin(t * PI) * sag
		pos.y -= sag_amount
		
		# Slight sideways variation for organic look
		pos.x += sin(t * PI * 2.0) * 0.002
		pos.z += cos(t * PI * 3.0) * 0.002
		
		positions.append(pos)
	
	# Build tube mesh
	for i in range(positions.size() - 1):
		var p1 = positions[i]
		var p2 = positions[i + 1]
		var segment_dir = (p2 - p1).normalized()
		
		if segment_dir.length_squared() < 0.0001:
			continue
		
		# Find perpendicular vectors
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()
		
		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU
			
			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * cable_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * cable_thickness
			
			# Triangle 1
			st.add_vertex(p1 + offset1)
			st.add_vertex(p2 + offset1)
			st.add_vertex(p2 + offset2)
			
			# Triangle 2
			st.add_vertex(p1 + offset1)
			st.add_vertex(p2 + offset2)
			st.add_vertex(p1 + offset2)
	
	st.generate_normals()
	cable_mesh.mesh = st.commit()


func _on_plug_a_snapped(jack: SynthJack):
	connected_jack_a = jack
	_check_connection()


func _on_plug_a_unsnapped(_jack: SynthJack):
	connected_jack_a = null
	_check_connection()


func _on_plug_b_snapped(jack: SynthJack):
	connected_jack_b = jack
	_check_connection()


func _on_plug_b_unsnapped(_jack: SynthJack):
	connected_jack_b = null
	_check_connection()


func _check_connection():
	# Determine output and input jacks
	var output_jack: SynthJack = null
	var input_jack: SynthJack = null
	
	if connected_jack_a and connected_jack_a.is_output():
		output_jack = connected_jack_a
	elif connected_jack_b and connected_jack_b.is_output():
		output_jack = connected_jack_b
	
	if connected_jack_a and connected_jack_a.is_input():
		input_jack = connected_jack_a
	elif connected_jack_b and connected_jack_b.is_input():
		input_jack = connected_jack_b
	
	connection_changed.emit(output_jack, input_jack)
	
	if output_jack and input_jack:
		print("SynthCable: Connected %s → %s" % [output_jack.parameter_name, input_jack.parameter_name])


## API
func is_synth_cable() -> bool:
	return true


func get_output_jack() -> SynthJack:
	if connected_jack_a and connected_jack_a.is_output():
		return connected_jack_a
	if connected_jack_b and connected_jack_b.is_output():
		return connected_jack_b
	return null


func get_input_jack() -> SynthJack:
	if connected_jack_a and connected_jack_a.is_input():
		return connected_jack_a
	if connected_jack_b and connected_jack_b.is_input():
		return connected_jack_b
	return null


func is_fully_connected() -> bool:
	return get_output_jack() != null and get_input_jack() != null


func set_cable_color(color: Color):
	cable_color = color
	if cable_mesh and cable_mesh.material_override:
		cable_mesh.material_override.albedo_color = color
	if plug_a:
		plug_a.set_plug_color(color)
	if plug_b:
		plug_b.set_plug_color(color)
