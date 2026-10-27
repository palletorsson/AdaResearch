extends Node3D
## Edges supply insertion frames. Frozen hand-placed panels, not simulated glue.
## Lift one face to release its joins while the other faces stay in place.
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Piece = preload("res://commons/artifacts/primitive_encounters/piece.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const ANGLES: Array[float] = [0,15,30,45,60,70.528779366,90,109.471220634,120,150]
const EDGE := .32
const HALF_THICKNESS := .009
const SNAP_DISTANCE := .14
const STOCK_BATCH := 6
const MAX_PANELS := 96
@export_enum("Triangle:3", "Square:4") var sides := 3
@export var already_started := false
@export var fold_degrees := 60.0
var pieces: Array[Node3D] = []
var polygon := PackedVector3Array()
var links: Array[Dictionary] = []
var homes: Dictionary = {}
var part_defaults: Dictionary = {}
var buttons: Dictionary = {}
var controls: Node3D
var support: Node3D
var readout: Label3D
var feedback: Label3D
var guide: MeshInstance3D
var held_piece: Node3D
var _reverse := false
var _angle_index := 4
var _stock_enabled := true
var _next_panel := 12
var _panel_mesh: ArrayMesh
var _panel_shape: ConvexPolygonShape3D
var _rim_mesh: CylinderMesh
var _face_materials: Array[StandardMaterial3D] = []
var _rim_material: StandardMaterial3D

func _ready() -> void:
	already_started = bool(get_meta("config_already_started",already_started))
	fold_degrees = float(get_meta("config_fold_degrees",fold_degrees))
	if sides==4:
		polygon = PackedVector3Array([Vector3(-EDGE/2,0,-EDGE/2),Vector3(EDGE/2,0,-EDGE/2),Vector3(EDGE/2,0,EDGE/2),Vector3(-EDGE/2,0,EDGE/2)])
	else:
		var altitude := EDGE*sqrt(3.0)/2
		polygon = PackedVector3Array([Vector3(-EDGE/2,0,-altitude/3),Vector3(EDGE/2,0,-altitude/3),Vector3(0,0,altitude*2/3)])
	make_support()
	make_pieces()
	if already_started:seed_assembly()
	make_controls()
	guide = MeshInstance3D.new();guide.name = "NearestFreeEdge"
	var bar := CylinderMesh.new();bar.top_radius = .005;bar.bottom_radius = .005;bar.height = EDGE;bar.radial_segments = 8
	guide.mesh = bar;guide.material_override = Kit.material(Color("f6c965"));guide.visible = false
	controls.add_child(guide)
	remember_parts()
	set_fold(fold_degrees)
	set_process(false)

func make_support() -> void:
	support = Node3D.new();support.name = "Support";add_child(support)
	var top := Kit.box(support,"TimberTop",Vector3(0,.78,0),Vector3(3.2,.09,1.6),Color.WHITE)
	top.mesh = Timber.mesh(Vector3(3.2,.09,1.6));top.material_override = Timber.material()
	for x in [-1.35,1.35]:
		for z in [-.58,.58]:Kit.box(support,"Leg",Vector3(x,.38,z),Vector3(.08,.76,.08),Color("514653"))

func make_pieces() -> void:
	var vertices := PackedVector3Array()
	for y in [-HALF_THICKNESS,HALF_THICKNESS]:
		for v in polygon:vertices.append(v+Vector3.UP*y)
	var faces: Array = [];var bottom: Array = [];var top: Array = []
	for i in sides:bottom.append(sides-1-i);top.append(sides+i)
	faces.append(bottom);faces.append(top)
	for i in sides:faces.append([i,(i+1)%sides,(i+1)%sides+sides,i+sides])
	_panel_mesh = Kit.mesh(vertices,faces)
	_panel_shape = ConvexPolygonShape3D.new();_panel_shape.points = vertices
	_face_materials = [Kit.material(Color("d78ba7")),Kit.material(Color("d3c5db"))]
	_rim_material = Kit.material(Color("574755"))
	_rim_mesh = CylinderMesh.new();_rim_mesh.top_radius = .002;_rim_mesh.bottom_radius = .002;_rim_mesh.height = EDGE;_rim_mesh.radial_segments = 6
	for i in 12:
		make_panel(i,Vector3(-1.15+(i%6)*.46,.845+floorf(i/6.0)*.026,.43))

func make_panel(index: int, at: Vector3, stock := false) -> Node3D:
	var panel := Piece.new();panel.name = ("Triangle" if sides==3 else "Square")+"%02d"%index
	panel.set_meta("desktop_preserve_orientation",true)
	panel.set_meta("assembly_stock",stock);panel.position = at
	var face := MeshInstance3D.new();face.name = "Face";face.mesh = _panel_mesh;face.material_override = _face_materials[index%2];panel.add_child(face)
	var collider := CollisionShape3D.new();collider.shape = _panel_shape;panel.add_child(collider)
	for edge in sides:
		var a: Vector3 = polygon[edge]+Vector3.UP*.010
		var b: Vector3 = polygon[(edge+1)%sides]+Vector3.UP*.010
		var line := MeshInstance3D.new();line.name = "Edge%d"%edge
		line.mesh = _rim_mesh;line.material_override = _rim_material
		panel.add_child(line);line.position = (a+b)*.5;line.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	panel.picked_up.connect(lift);panel.dropped.connect(release)
	add_child(panel);pieces.append(panel)
	return panel

func make_controls() -> void:
	controls = Node3D.new();controls.name = "Controls";add_child(controls)
	Kit.box(controls,"InstructionPlate",Vector3(0,1.17,-.78),Vector3(2.7,.6,.025),Color("eee6db"),false)
	Kit.label(controls,"%s / JOIN AT AN EDGE"%("TRIANGLE FACES" if sides==3 else "SQUARE FACES"),Vector3(0,1.40,-.759),22)
	readout = Kit.label(controls,"",Vector3(0,1.29,-.759),19)
	var actions: Array[Callable] = [step_angle.bind(-1),step_angle.bind(1),reverse_fold,request_stock,reset]
	for i in 5:
		var key: String = ["less","more","reverse","stock","reset"][i]
		var button: Node3D = ButtonScene.instantiate();button.name = key.capitalize()
		# Upward-facing controls on the near rail, below the working faces.
		button.position = Vector3(-1+i*.5,.88,.72);button.rotation = Vector3.ZERO
		button.released_color = Color("dc9bb5");button.pressed.connect(actions[i]);controls.add_child(button);buttons[key] = button
		var caption := Kit.label(controls,["ANGLE -","ANGLE +","OTHER SIDE","MORE FACES","START OVER"][i],Vector3(-1+i*.5,.90,.79),13)
		caption.rotation.x = -PI/2
	Kit.box(controls,"NearControlRail",Vector3(0,.84,.73),Vector3(2.8,.05,.22),Color("eee6db"))
	var presets := [70.528779366,109.471220634] if sides==3 else [90.0,0.0]
	for i in 2:
		var button: Node3D = ButtonScene.instantiate();button.name = "Preset%d"%i
		button.position = Vector3(-1.40+i*2.8,.90,.42);button.rotation = Vector3.ZERO
		button.released_color = Color("f6c965");button.pressed.connect(set_fold.bind(presets[i]));controls.add_child(button)
		buttons["solid" if i==0 else "alternate"] = button
		var words: String = (["DIAMOND","TETRAHEDRON"] if sides==3 else ["CUBE","FLAT"])[i]
		var caption := Kit.label(controls,words,Vector3(-1.40+i*2.8,.91,.56),12);caption.rotation.x = -PI/2
	feedback = Kit.label(controls,"Lift a face to detach. Bring two free edges together, then release.",Vector3(0,.94,-.755),14)
	Kit.label(controls,"Desktop: Q/E roll, R/F tilt while holding.  |  Grip and turn by hand in VR.",Vector3(0,.865,-.755),13)

func edge_frame(edge: int) -> Transform3D:
	var a: Vector3 = polygon[edge];var b: Vector3 = polygon[(edge+1)%sides]
	var x := (b-a).normalized();var z := (-(a+b)*.5).normalized()
	return Transform3D(Basis(x,z.cross(x).normalized(),z),(a+b)*.5)

func joined_pose(moving_edge: int, target: Node3D, target_edge: int, angle: float) -> Transform3D:
	# Opposed edge directions place interiors on opposite sides at 0 degrees.
	# Folding around the target edge retains BOTH shared endpoints exactly.
	var fold := Transform3D(Basis(Vector3.RIGHT,deg_to_rad(angle))*Basis(Vector3.UP,PI),Vector3.ZERO)
	return target.global_transform*edge_frame(target_edge)*fold*edge_frame(moving_edge).affine_inverse()

func edge_free(panel: Node3D, edge: int) -> bool:
	for link in links:
		if (link.a==panel and link.ea==edge) or (link.b==panel and link.eb==edge):return false
	return true

func lift(panel: Node3D) -> void:
	links = links.filter(func(link):return link.a!=panel and link.b!=panel)
	held_piece = panel;set_process(true)
	if is_instance_valid(feedback):feedback.text = "Face released. Gold marks the nearest free edge."

func nearest_edge(panel: Node3D) -> Dictionary:
	var best: Dictionary = {};var distance := SNAP_DISTANCE
	for other in pieces:
		if other==panel or other.held():continue
		for target_edge in sides:
			if not edge_free(other,target_edge):continue
			var target_frame: Transform3D = other.global_transform*edge_frame(target_edge)
			for moving_edge in sides:
				var moving_frame: Transform3D = panel.global_transform*edge_frame(moving_edge)
				if absf(moving_frame.basis.x.normalized().dot(target_frame.basis.x.normalized()))<.75:continue
				var d := moving_frame.origin.distance_to(target_frame.origin)
				if d<distance:
					var pose := joined_pose(moving_edge,other,target_edge,fold_degrees)
					if overlaps_face(panel,pose):continue
					distance = d;best = {"moving_edge":moving_edge,"target":other,"target_edge":target_edge,"pose":pose}
	return best

func overlaps_face(panel: Node3D, pose: Transform3D) -> bool:
	# The edge centre-lines coincide, so finite-thickness faces necessarily
	# overlap in a narrow seam when folded. Check the broad interior separately
	# (3cm triangle / 5cm square seam allowance), including against the support.
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := ConvexPolygonShape3D.new();var points := PackedVector3Array()
	for y in [-.004,.004]:
		for v in polygon:points.append(v*.78+Vector3.UP*y)
	shape.points = points;query.shape = shape;query.transform = pose
	query.collision_mask = 7;query.exclude = [panel.get_rid()];query.margin = .001
	return not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func release(panel: Node3D) -> void:
	var candidate := nearest_edge(panel)
	if not candidate.is_empty():
		panel.global_transform = candidate.pose;sync(panel)
		links.append({"a":panel,"ea":candidate.moving_edge,"b":candidate.target,"eb":candidate.target_edge})
		close_coincident_edges(panel)
		if is_instance_valid(feedback):feedback.text = "EDGE JOINED / %.1f degrees fold. Lift a face to change the form."%fold_degrees
	elif is_instance_valid(feedback):feedback.text = "Free placement. Bring parallel edges closer to join."
	if held_piece==panel:
		held_piece = null;set_process(false)
		if is_instance_valid(guide):guide.hide()
	refill_if_empty.call_deferred()

func loose_count() -> int:
	var joined: Dictionary = {}
	for link in links:joined[link.a] = true;joined[link.b] = true
	var count := 0
	for panel in pieces:
		if not joined.has(panel) and not panel.held():count += 1
	return count

func refill_if_empty() -> void:
	if _stock_enabled and not pieces.is_empty() and loose_count()==0:add_stock()

func request_stock() -> void:
	add_stock.call_deferred()

func add_stock() -> int:
	if not _stock_enabled or not is_instance_valid(support):return 0
	if pieces.size()>=MAX_PANELS:
		if is_instance_valid(feedback):feedback.text = "Stock limit reached. Reuse a face or START OVER."
		return 0
	var added := 0
	# Start on the existing right-hand stock area. A real shape query finds
	# clear spaces/stacks without moving or replacing any visitor-built faces.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _panel_shape;query.collision_mask = 7;query.margin = .001
	# Keep replenished stock below 1.25m rather than piling it above reach.
	for level in 8:
		for slot in 6:
			if added>=STOCK_BATCH or pieces.size()>=MAX_PANELS:break
			var at := Vector3(.05+(slot%3)*.46,.845+(level*2+floorf(slot/3.0))*.026,.43)
			query.transform = support.global_transform*Transform3D(Basis.IDENTITY,at)
			if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():continue
			var local_pose: Transform3D = global_transform.affine_inverse()*query.transform
			var panel := make_panel(_next_panel,local_pose.origin,true);panel.transform = local_pose;_next_panel += 1
			sync(panel);added += 1
		if added>=STOCK_BATCH or pieces.size()>=MAX_PANELS:break
	if is_instance_valid(feedback):
		feedback.text = "%d more faces on the stock area. Keep building."%added if added>0 else "Clear a space on the stock area, then press MORE FACES."
	return added

func close_coincident_edges(panel: Node3D) -> void:
	# The last face of a box/tetrahedron closes several edges at once.
	for other in pieces:
		if other==panel:continue
		for a in sides:
			if not edge_free(panel,a):continue
			var p: Transform3D = panel.global_transform*edge_frame(a)
			for b in sides:
				if not edge_free(other,b):continue
				var q: Transform3D = other.global_transform*edge_frame(b)
				if p.origin.distance_to(q.origin)<.002 and absf(p.basis.x.normalized().dot(q.basis.x.normalized()))>.999:
					links.append({"a":panel,"ea":a,"b":other,"eb":b});break

func _process(_delta: float) -> void:
	if not is_instance_valid(held_piece):
		if is_instance_valid(guide):guide.hide()
		set_process(false);return
	var candidate := nearest_edge(held_piece)
	if not is_instance_valid(guide):return
	guide.visible = not candidate.is_empty()
	if guide.visible:
		var frame: Transform3D = candidate.target.global_transform*edge_frame(candidate.target_edge)
		guide.global_position = frame.origin
		guide.global_basis = Basis(Quaternion(Vector3.UP,frame.basis.x.normalized()))

func set_fold(value: float) -> void:
	fold_degrees = clampf(value,-150,150);_reverse = value<0
	var distance := INF
	for i in ANGLES.size():
		if absf(ANGLES[i]-absf(value))<distance:distance = absf(ANGLES[i]-absf(value));_angle_index = i
	if is_instance_valid(readout):readout.text = "FOLD FROM FLAT / %+.1f degrees / applies to the next join"%fold_degrees

func step_angle(direction: int) -> void:
	_angle_index = posmod(_angle_index+direction,ANGLES.size())
	set_fold(ANGLES[_angle_index]*(-1 if _reverse else 1))

func reverse_fold() -> void:
	_reverse = not _reverse
	set_fold(ANGLES[_angle_index]*(-1 if _reverse else 1))

func seed_assembly() -> void:
	# A folded beginning, not a solved object. The other faces remain stock.
	pieces[0].position = Vector3(-.72,.845,.38)
	var used := 5 if sides==4 else 3
	for i in range(1,used):
		pieces[i].global_transform = joined_pose(0,pieces[0],i-1,90 if sides==4 else fold_degrees)
		links.append({"a":pieces[i],"ea":0,"b":pieces[0],"eb":i-1})
	for i in range(used,12):
		var index := i-used
		pieces[i].position = Vector3(.05+(index%3)*.46,.845+floorf(index/3.0)*.026,.43)
	for p in pieces:close_coincident_edges(p)

func reset() -> void:
	for panel in pieces:
		if panel.held():return
	links.clear()
	for i in range(pieces.size()-1,-1,-1):
		if pieces[i].get_meta("assembly_stock",false):
			var spare: Node3D = pieces[i];pieces.remove_at(i);spare.free()
	_next_panel = 12
	for panel in pieces:
		panel.transform = homes[str(panel.name)];sync(panel)
	for panel in pieces:close_coincident_edges(panel)
	if is_instance_valid(feedback):feedback.text = "Starting faces restored. Try a different fold."

func sync(node: Node) -> void:
	if node is RigidBody3D:PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	for child in node.get_children():sync(child)

func remember_parts() -> void:
	for child in get_children():
		if not child is Node3D:continue
		var bounds := mesh_bounds(child,child)
		part_defaults[str(child.name)] = {"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
		if child in pieces:homes[str(child.name)] = child.transform

func apply_grid_config(config: Dictionary) -> void:
	if config.has("fold_degrees"):set_fold(float(config.fold_degrees))
	if config.has("only_parts"):
		_stock_enabled = false
		var kept: Array = config.only_parts
		for child in get_children():
			if child is Node3D and str(child.name) not in kept:
				pieces.erase(child);part_defaults.erase(str(child.name));child.free()
		if not is_instance_valid(controls):held_piece = null;set_process(false)
	for key in config.get("parts",{}):
		var node := get_node_or_null(NodePath(key)) as Node3D
		if node==null or not part_defaults.has(key):continue
		var pose: Dictionary = config.parts[key]
		var p: Array = pose.get("position",part_defaults[key].position)
		var r: Array = pose.get("rotation",part_defaults[key].rotation)
		node.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
		node.rotation_degrees = Vector3(float(r[0]),float(r[1]),float(r[2]));sync(node)
	links.clear()
	for panel in pieces:
		homes[str(panel.name)] = panel.transform;close_coincident_edges(panel)

func mesh_bounds(node: Node3D, relative: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D and node.mesh!=null:result = (relative.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var bounds := mesh_bounds(child,relative)
			if bounds.has_surface():result = bounds if not result.has_surface() else result.merge(bounds)
	return result

