extends Node3D
## One field, one controlled height scale, and two proposed ways across it.
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const HEIGHTS := [0.0, 0.25, 0.65, 0.9]
var ground: Node3D
var height_index: int = 1
var route_index: int = 0
var sample_index: int = 0
var revision: int = 0
var blocked: bool = false
var profile: Array = []
var distances: Array = []
var surface_length: float = 0
var maximum_grade: float = 0
var _readout: Label3D
var _route: MeshInstance3D
var _chart: MeshInstance3D
var _marker: MeshInstance3D
var _chart_marker: MeshInstance3D

func build(owner_ground: Node3D) -> void:
	name = "WalkStudy"
	ground = owner_ground
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.18,0.23,0.26)
	stone.roughness = 0.9
	for side in [-1,1]:
		box(Vector3(side*4.4,0.5,0),Vector3(0.8,1,9.6),stone)
		box(Vector3(0,0.5,side*4.4),Vector3(8,1,0.8),stone)
	_route = line_mesh("ProposedRoute");add_child(_route)
	_marker = dot(Color(1,0.85,0.22),0.055);add_child(_marker)
	for z in [-4.0,4.0]:
		var gate := Node3D.new();gate.position = Vector3(0,1,z);add_child(gate)
		for x in [-0.65,0.65]:
			var post := Kit.box(Vector3(x,0.42,0),Vector3(0.07,0.84,0.07),Kit.emissive(Color(0.25,0.9,0.8),0.6));gate.add_child(post)
	var board := Node3D.new();board.name = "Instrument";board.position = Vector3(3.85,1.8,0);board.rotation_degrees = Vector3(-55,90,0);add_child(board)
	board.add_child(Kit.box(Vector3(0,0.05,-0.04),Vector3(3.4,1.4,0.08),stone))
	_chart = line_mesh("RouteProfile");_chart.position = Vector3(0,0.25,0.02);board.add_child(_chart)
	_chart_marker = dot(Color(1,0.85,0.22),0.025);board.add_child(_chart_marker)
	_readout = Label3D.new();_readout.name = "Readout";_readout.font_size = 22;_readout.pixel_size = 0.0022
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT;_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_readout.position = Vector3(-1.55,-0.23,0.025);board.add_child(_readout)
	for z in [-1.3,1.3]:box(Vector3(4.0,1.35,z),Vector3(0.12,0.7,0.12),stone)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D = rack.create_panel("",[[{"type":"button","label":"HEIGHT"},{"type":"button","label":"ROUTE"}],[{"type":"button","label":"SAMPLE"},{"type":"button","label":"RESET"}]],true)
	controls.name = "Controls";controls.position = Vector3(4.0,1.9,2.35);controls.rotation_degrees = Vector3(-35,90,0);controls.scale = Vector3.ONE*1.9;add_child(controls)
	var actions: Array[Callable] = [next_height,next_route,next_sample,reset]
	for i in range(4):
		var action: Callable = actions[i]
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_button):action.call())
	refresh_profile()

func can_rebuild() -> bool:
	var bodies: Array = get_tree().get_nodes_in_group("player_body")
	bodies.append_array(get_tree().get_nodes_in_group("em_walker"))
	for body in bodies:
		if body is Node3D:
			var p: Vector3 = ground.to_local(body.global_position)
			if absf(p.x)<4.05 and absf(p.z)<4.05 and p.y>-0.2 and p.y<5: return false
	return true

func set_height(index: int) -> bool:
	blocked = not can_rebuild()
	if blocked:
		update_witness();return false
	height_index = clampi(index,0,HEIGHTS.size()-1)
	ground.height_scale = HEIGHTS[height_index]
	ground.generate_space()
	refresh_profile()
	return true

func next_height() -> void: set_height((height_index+1)%HEIGHTS.size())
func next_route() -> void:
	route_index = (route_index+1)%2;refresh_profile()
func next_sample() -> void:
	sample_index = (sample_index+1)%5;update_witness()
func reset() -> void:
	if set_height(1):
		route_index = 0;sample_index = 0;refresh_profile()

func waypoints() -> Array[Vector2]:
	if route_index==0: return [Vector2(0,-4),Vector2(0,4)]
	return [Vector2(0,-4),Vector2(-2.4,-2),Vector2(-2.4,2),Vector2(0,4)]

func route_point(t: float) -> Vector2:
	var path: Array[Vector2] = waypoints();var total: float = 0
	for i in range(path.size()-1): total+=path[i].distance_to(path[i+1])
	var along: float = t*total
	for i in range(path.size()-1):
		var length: float = path[i].distance_to(path[i+1])
		if along<=length: return path[i].lerp(path[i+1],along/length)
		along-=length
	return path[-1]

func refresh_profile() -> void:
	profile.clear();distances.clear();surface_length = 0;maximum_grade = 0
	var vertices := PackedVector3Array();var chart := PackedVector3Array()
	for i in range(101):
		var p: Vector2 = route_point(float(i)/100)
		profile.append(Vector3(p.x,ground.walk_height_at(p),p.y))
		if i>0:
			var delta: Vector3 = profile[i]-profile[i-1]
			surface_length+=delta.length()
			maximum_grade=maxf(maximum_grade,rad_to_deg(atan2(absf(delta.y),Vector2(delta.x,delta.z).length())))
			vertices.append(profile[i-1]+Vector3.UP*0.035);vertices.append(profile[i]+Vector3.UP*0.035)
			chart.append(chart_point(i-1));chart.append(chart_point(i))
		distances.append(surface_length)
	# A level reference behind the measured section, at the margin's 1 m height.
	chart.append(Vector3(-1.5,0,0));chart.append(Vector3(1.5,0,0))
	set_lines(_route,vertices);set_lines(_chart,chart)
	update_witness();revision+=1

func chart_point(i: int) -> Vector3:
	return Vector3(-1.5+3.0*float(i)/100,(profile[i].y-1.0)*0.55,0)

func selected() -> Dictionary:
	var i: int = sample_index*25
	var p: Vector3 = profile[i]
	var raw: float = ground.noise.get_noise_2d(p.x*ground.noise_scale,p.z*ground.noise_scale)
	return {"position":[p.x,p.y,p.z],"raw":raw,"edge_weight":ground.edge_weight(Vector2(p.x,p.z)),"analytic_height":ground.ground_at(Vector2(p.x,p.z)),"mesh_height":p.y,"distance":distances[i],"height_scale":ground.height_scale,"route":route_index,"sample":sample_index}

func update_witness() -> void:
	var rec: Dictionary = selected();var i: int = sample_index*25
	_marker.position = profile[i]+Vector3.UP*0.08
	_chart_marker.position = _chart.position+chart_point(i)+Vector3(0,0,0.015)
	_readout.text = "HEIGHT %.2f | route %s | sample %d/5\n" % [ground.height_scale,"A" if route_index==0 else "B",sample_index+1]
	_readout.text += "section %.2f m | steepest segment %.1f deg\n" % [surface_length,maximum_grade]
	_readout.text += "x %+.2f z %+.2f | mesh y %.3f m\n" % [rec.position[0],rec.position[2],rec.mesh_height]
	_readout.text += "field %+.3f | edge weight %.2f | base 1 m\n" % [rec.raw,rec.edge_weight]
	_readout.text += "Return to the margin before changing HEIGHT." if blocked else "Noise fixed. ROUTE is a proposal: try walking it."

func line_mesh(label: String) -> MeshInstance3D:
	var n := MeshInstance3D.new();n.name = label
	n.material_override = Kit.emissive(Color(0.95,0.78,0.28),1.0)
	return n
func set_lines(n: MeshInstance3D, vertices: PackedVector3Array) -> void:
	var a: Array = [];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,a);n.mesh = mesh
func dot(c: Color, radius: float) -> MeshInstance3D:
	var n := MeshInstance3D.new();var mesh := SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=12;mesh.rings=6;n.mesh=mesh;n.material_override=Kit.emissive(c,1);return n
func box(at: Vector3, size: Vector3, material: Material) -> void:
	add_child(Kit.box(at,size,material))
	var body := StaticBody3D.new();var collider := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=size;collider.shape=shape;body.position=at;body.add_child(collider);add_child(body)
