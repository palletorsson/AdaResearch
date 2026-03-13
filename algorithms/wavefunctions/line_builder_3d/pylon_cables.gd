# pylon_cables.gd
# Electric pylons with swinging cables between them
# Last cable connects to a transformer box on the floor

extends Node3D

@export_category("Pylons")
@export var num_pylons: int = 4
@export var pylon_spacing: float = 8.0
@export var pylon_height: float = 6.0
@export var pylon_base_width: float = 1.5
@export var pylon_top_width: float = 0.5
@export var pylon_color: Color = Color(0.4, 0.4, 0.45)

@export_category("Cables")
@export var cables_per_span: int = 3  # Number of cable lines between pylons
@export var cable_thickness: float = 0.03
@export var cable_sag: float = 0.8
@export var cable_color: Color = Color(0.1, 0.1, 0.12)
@export var cable_segments: int = 20

@export_category("Transformer Box")
@export var box_size: Vector3 = Vector3(0.8, 0.6, 0.5)
@export var box_color: Color = Color(0.3, 0.5, 0.3)

@export_category("Animation")
@export var wind_enabled: bool = true
@export var wind_strength: float = 0.3
@export var wind_speed: float = 1.5

var _pylons: Array[Node3D] = []
var _cable_meshes: Array[MeshInstance3D] = []
var _cable_data: Array[Dictionary] = []  # Store start/end points for animation
var _transformer_box: Node3D
var _time: float = 0.0


func _ready() -> void:
	_create_pylons()
	_create_cables()
	_create_transformer_box()


func _process(delta: float) -> void:
	if wind_enabled:
		_time += delta
		_update_cable_sway()


func _create_pylons() -> void:
	for i in range(num_pylons):
		var pylon := _create_single_pylon()
		pylon.name = "Pylon_%d" % i
		pylon.position = Vector3(i * pylon_spacing, 0, 0)
		add_child(pylon)
		_pylons.append(pylon)


func _create_single_pylon() -> Node3D:
	var pylon := Node3D.new()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pylon_color
	mat.metallic = 0.6
	mat.roughness = 0.4
	
	# Four legs (tapered)
	var leg_positions: Array[Vector2] = [
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)
	]
	
	for leg_pos: Vector2 in leg_positions:
		var leg := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.04
		cylinder.bottom_radius = 0.08
		cylinder.height = pylon_height
		leg.mesh = cylinder
		leg.material_override = mat
		
		# Position leg with taper
		var base_offset := leg_pos * pylon_base_width * 0.5
		var top_offset := leg_pos * pylon_top_width * 0.5
		var mid_x: float = (base_offset.x + top_offset.x) * 0.5
		var mid_z: float = (base_offset.y + top_offset.y) * 0.5
		leg.position = Vector3(mid_x, pylon_height * 0.5, mid_z)
		
		# Angle the leg
		var angle_x := atan2(base_offset.y - top_offset.y, pylon_height) * 0.5
		var angle_z := atan2(base_offset.x - top_offset.x, pylon_height) * 0.5
		leg.rotation = Vector3(angle_x, 0, -angle_z)
		
		pylon.add_child(leg)
	
	# Cross beams at different heights
	var beam_heights := [pylon_height * 0.3, pylon_height * 0.6, pylon_height * 0.9]
	for h in beam_heights:
		var t: float = h / pylon_height
		var width: float = lerpf(pylon_base_width, pylon_top_width, t)
		_add_cross_beams(pylon, h, width, mat)
	
	# Top cross arm for cables
	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(2.0, 0.1, 0.1)
	arm.mesh = arm_mesh
	arm.material_override = mat
	arm.position = Vector3(0, pylon_height, 0)
	pylon.add_child(arm)
	
	# Insulators on cross arm
	for x in [-0.7, 0.0, 0.7]:
		var insulator := MeshInstance3D.new()
		var ins_mesh := CylinderMesh.new()
		ins_mesh.top_radius = 0.06
		ins_mesh.bottom_radius = 0.04
		ins_mesh.height = 0.15
		insulator.mesh = ins_mesh
		
		var ins_mat := StandardMaterial3D.new()
		ins_mat.albedo_color = Color(0.3, 0.5, 0.3)  # Greenish ceramic
		ins_mat.roughness = 0.3
		insulator.material_override = ins_mat
		insulator.position = Vector3(x, pylon_height - 0.1, 0)
		pylon.add_child(insulator)
	
	return pylon


func _add_cross_beams(pylon: Node3D, height: float, width: float, mat: Material) -> void:
	var beam_size := 0.04
	
	# X beams
	for z in [-1, 1]:
		var beam := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, beam_size, beam_size)
		beam.mesh = box
		beam.material_override = mat
		beam.position = Vector3(0, height, z * width * 0.5)
		pylon.add_child(beam)
	
	# Z beams
	for x in [-1, 1]:
		var beam := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(beam_size, beam_size, width)
		beam.mesh = box
		beam.material_override = mat
		beam.position = Vector3(x * width * 0.5, height, 0)
		pylon.add_child(beam)


func _create_cables() -> void:
	# Cables between each pylon pair
	for i in range(num_pylons - 1):
		var start_pylon := _pylons[i]
		var end_pylon := _pylons[i + 1]
		
		# Create multiple cables at different x offsets on the cross arm
		for c in range(cables_per_span):
			var x_offset: float = (float(c) / float(cables_per_span - 1) - 0.5) * 1.4 if cables_per_span > 1 else 0.0
			
			var start_pos := start_pylon.position + Vector3(x_offset, pylon_height - 0.1, 0)
			var end_pos := end_pylon.position + Vector3(x_offset, pylon_height - 0.1, 0)
			
			var cable_mesh := _create_cable(start_pos, end_pos)
			cable_mesh.name = "Cable_%d_%d" % [i, c]
			add_child(cable_mesh)
			_cable_meshes.append(cable_mesh)
			_cable_data.append({
				"start": start_pos,
				"end": end_pos,
				"x_offset": x_offset,
				"index": c
			})


func _create_cable(start: Vector3, end: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _generate_cable_mesh(start, end, 0.0)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cable_color
	mat.metallic = 0.8
	mat.roughness = 0.3
	mesh_instance.material_override = mat
	
	return mesh_instance


func _generate_cable_mesh(start: Vector3, end: Vector3, wind_offset: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var direction := end - start
	var length := direction.length()
	var dir_norm := direction.normalized()
	
	# Generate catenary points
	var points: Array[Vector3] = []
	for i in range(cable_segments + 1):
		var t := float(i) / float(cable_segments)
		var pos := start.lerp(end, t)
		
		# Catenary sag (parabolic approximation)
		var sag_amount := sin(t * PI) * cable_sag * length * 0.1
		pos.y -= sag_amount
		
		# Wind sway
		var sway := sin(t * PI) * wind_offset
		pos.z += sway
		
		points.append(pos)
	
	# Build tube mesh
	var up := Vector3.UP
	var tube_sides := 6
	
	for i in range(points.size() - 1):
		var p1 := points[i]
		var p2 := points[i + 1]
		var seg_dir := (p2 - p1).normalized()
		
		if abs(seg_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right := seg_dir.cross(up).normalized()
		var forward := right.cross(seg_dir).normalized()
		
		for side in range(tube_sides):
			var angle1 := (float(side) / tube_sides) * TAU
			var angle2 := (float(side + 1) / tube_sides) * TAU
			
			var offset1 := (right * cos(angle1) + forward * sin(angle1)) * cable_thickness
			var offset2 := (right * cos(angle2) + forward * sin(angle2)) * cable_thickness
			
			st.add_vertex(p1 + offset1)
			st.add_vertex(p2 + offset1)
			st.add_vertex(p2 + offset2)
			
			st.add_vertex(p1 + offset1)
			st.add_vertex(p2 + offset2)
			st.add_vertex(p1 + offset2)
	
	st.generate_normals()
	return st.commit()


func _create_transformer_box() -> void:
	_transformer_box = Node3D.new()
	_transformer_box.name = "TransformerBox"
	
	# Position near last pylon
	var last_pylon := _pylons[num_pylons - 1]
	_transformer_box.position = last_pylon.position + Vector3(2.0, 0, 0)
	add_child(_transformer_box)
	
	# Main box
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	box.mesh = box_mesh
	box.position.y = box_size.y * 0.5
	
	var box_mat := StandardMaterial3D.new()
	box_mat.albedo_color = box_color
	box_mat.metallic = 0.4
	box_mat.roughness = 0.6
	box.material_override = box_mat
	_transformer_box.add_child(box)
	
	# Warning stripes
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(box_size.x + 0.01, 0.1, box_size.z + 0.01)
	stripe.mesh = stripe_mesh
	stripe.position.y = box_size.y * 0.7
	
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.9, 0.7, 0.1)
	stripe.material_override = stripe_mat
	_transformer_box.add_child(stripe)
	
	# Cable from last pylon to box
	var last_cable_start := last_pylon.position + Vector3(0, pylon_height - 0.1, 0)
	var last_cable_end := _transformer_box.position + Vector3(0, box_size.y, 0)
	
	var drop_cable := _create_cable(last_cable_start, last_cable_end)
	drop_cable.name = "DropCable"
	add_child(drop_cable)
	_cable_meshes.append(drop_cable)
	_cable_data.append({
		"start": last_cable_start,
		"end": last_cable_end,
		"x_offset": 0.0,
		"index": -1  # Special marker for drop cable
	})


func _update_cable_sway() -> void:
	for i in range(_cable_meshes.size()):
		var data: Dictionary = _cable_data[i]
		var mesh_inst: MeshInstance3D = _cable_meshes[i]
		
		# Calculate wind offset with variation per cable
		var phase := float(data["index"]) * 0.5 + float(i) * 0.3
		var wind_offset := sin(_time * wind_speed + phase) * wind_strength
		
		# Less sway for drop cable
		if data["index"] == -1:
			wind_offset *= 0.3
		
		mesh_inst.mesh = _generate_cable_mesh(data["start"], data["end"], wind_offset)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

