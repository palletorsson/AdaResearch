extends Node3D

@export var system_path: NodePath
var system: MusicGraphSystem

var _nodes_visuals: Dictionary = {} # ID -> MeshInstance3D
var _cursor_visuals: Array[MeshInstance3D] = []
var _initialized: bool = false

# Visual Settings
const COLOR_DEFAULT = Color(0.2, 0.2, 0.8)
const COLOR_ACTIVE = Color(1.0, 0.7, 0.2) # Golden Orange
const COLOR_EDGE_DEFAULT = Color(0.5, 0.5, 0.5, 0.3)

func _process(delta):
	if not system: 
		if system_path: system = get_node(system_path)
		return
	
	if not _initialized and not system.nodes.is_empty():
		_build_static_graph()
		_initialized = true
		
	if _initialized:
		_update_visuals(delta)

func _build_static_graph():
	# Clear existing
	for c in get_children():
		c.queue_free()
	_nodes_visuals.clear()
	_cursor_visuals.clear()
	
	# 1. Build Nodes
	for id in system.nodes:
		var n = system.nodes[id]
		_create_node_visual(n)
		
	# 2. Build Edges (after all nodes exist so we have positions)
	for id in system.nodes:
		var n = system.nodes[id]
		for edge in n.edges:
			if system.nodes.has(edge.target_id):
				var target = system.nodes[edge.target_id]
				_create_edge_visual(n.position, target.position, edge.type)

func _create_node_visual(node_data):
	var mesh_inst = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.25
	sph.height = 0.5
	sph.radial_segments = 32
	sph.rings = 16
	mesh_inst.mesh = sph
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = node_data.color # Use node's custom color
	mat.emission_enabled = true
	mat.emission = Color.BLACK
	mat.roughness = 0.2
	mesh_inst.material_override = mat
	
	mesh_inst.position = node_data.position
	add_child(mesh_inst)
	
	# Label
	var label = Label3D.new()
	# Show Note Name clearly
	label.text = node_data.note
	label.font_size = 48
	label.outline_size = 12
	label.position = Vector3(0, 0.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.8, 0.8, 1.0, 0.5) # Dim default
	mesh_inst.add_child(label)
	
	_nodes_visuals[node_data.id] = mesh_inst

func _create_edge_visual(from: Vector3, to: Vector3, type: String):
	var dist = from.distance_to(to)
	if dist < 0.01: return
	
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	# Thin line
	box.size = Vector3(0.02, 0.02, dist)
	mesh_inst.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	if type == "fork":
		mat.albedo_color = Color(0.8, 0.5, 0.2, 0.5)
	elif type == "loop":
		mat.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	else:
		mat.albedo_color = COLOR_EDGE_DEFAULT
		
	mesh_inst.material_override = mat
	
	# Position at midpoint
	mesh_inst.position = (from + to) / 2.0
	mesh_inst.look_at_from_position(mesh_inst.position, to, Vector3.UP)
	
	add_child(mesh_inst)

func _update_visuals(delta):
	# Decay all nodes back to default
	for id in _nodes_visuals:
		var mesh = _nodes_visuals[id]
		var mat = mesh.material_override
		var label = mesh.get_child(0) as Label3D
		
		# Smooth decay
		mat.albedo_color = mat.albedo_color.lerp(COLOR_DEFAULT, delta * 3.0)
		mat.emission = mat.emission.lerp(Color.BLACK, delta * 3.0)
		mesh.scale = mesh.scale.lerp(Vector3.ONE, delta * 5.0)
		
		if label:
			label.modulate = label.modulate.lerp(Color(0.8, 0.8, 1.0, 0.5), delta * 3.0)
			label.font_size = lerp(float(label.font_size), 48.0, delta * 5.0)

	# Manage Cursors & Highlight Active Nodes
	while _cursor_visuals.size() < system.active_cursors.size():
		_cursor_visuals.append(_create_cursor_visual())
		
	for i in range(_cursor_visuals.size()):
		var vis = _cursor_visuals[i]
		
		if i < system.active_cursors.size():
			vis.visible = true
			var cursor_data = system.active_cursors[i]
			var node_id = cursor_data.current_node
			
			if _nodes_visuals.has(node_id):
				var node_vis = _nodes_visuals[node_id]
				
				# Snap cursor to node
				vis.position = node_vis.position
				
				# Pulse Cursor
				var t = cursor_data.timer
				var pulse = 1.0 + sin(t * 10.0) * 0.1
				vis.scale = Vector3.ONE * 0.5 * pulse
				
				# Activate Node Visuals
				var mat = node_vis.material_override
				mat.albedo_color = COLOR_ACTIVE
				mat.emission = COLOR_ACTIVE
				node_vis.scale = Vector3.ONE * 1.5
				
				# Highlight Label
				var label = node_vis.get_child(0) as Label3D
				if label:
					label.modulate = Color.WHITE
					label.outline_modulate = COLOR_ACTIVE
					label.font_size = 64
		else:
			vis.visible = false

func _create_cursor_visual() -> MeshInstance3D:
	# Ring cursor
	var m = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.4
	m.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0) 
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	
	# Orient flat
	m.rotation_degrees.x = 90
	
	add_child(m)
	return m
