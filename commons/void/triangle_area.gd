extends "res://commons/void/lines_area.gd"
## Tower placements for the existing Triangle hall. The artifacts own geometry
## and interaction; this adapter supplies the route and first-visit handoff.
const Boundary = preload("res://commons/primitives/line/puzzles/triangle_line_puzzle.tscn")
const Plate = preload("res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn")
const Drawing = preload("res://commons/primitives/point/draw_triangle_faces.tscn")
const Twin = preload("res://commons/artifacts/triangle_live_twin/triangle_live_twin.tscn")
const Reveal = preload("res://commons/artifacts/concept_monitor/triangle_reveal_monitor.tscn")
const Quad = preload("res://commons/primitives/quad/quad.tscn")
const QuadBoundary = preload("res://commons/primitives/line/puzzles/quad_line_puzzle.tscn")
const Fold = preload("res://commons/primitives/folded_strip/folded_strip.tscn")
const Pink = preload("res://commons/artifacts/triangle_direction_sign/triangle_direction_sign.tscn")
const Parasol = preload("res://commons/primitives/triangle/parasol_triangle.tscn")
const Assembly = preload("res://commons/artifacts/primitive_encounters/triangle_assembly_table.tscn")
const Bracing = preload("res://commons/artifacts/construction_triangle_brace/construction_triangle_brace.tscn")
const WallProof = preload("res://commons/artifacts/pythagoras_cubicle/pythagoras_cubicle.tscn")
const MeshZone = preload("res://commons/artifacts/wireframe_threshold/wireframe_threshold.tscn")
const EdgeLight = preload("res://commons/void/triangle_edge_light.gd")
@export_enum("arrival", "drawing", "surfaces", "assembly") var encounter := "arrival"
var drawing_entered := false
var homes: Dictionary = {}

func _ready() -> void:
	add_to_group("void_lines_area")
	# Keep the twin and observer attached to this drawing, including editor copies.
	set_meta("em_map", "Point_Triangle_Context")
	match encounter:
		"arrival":
			# Three full-height bays follow the outer east edge in succession.
			# Keep them inside the column line so each whole triangle is visible.
			for i in range(3):
				place(Bracing,"EastBracing"+(str(i+1) if i>0 else ""),Vector3(2.9,0,-6+i*6),90)
			place(Boundary,"ThreeEdges",Vector3(0,1.4,0.6),270,{"discovery":"1","stock":"ringed"})
			place(Plate,"PointsEdgesFace",Vector3(0,0,-2.8))
			words("01 / CLOSE THREE EDGES",Vector3(0,0.025,2.7),true,0.0018)
			words("Closing a boundary does not fill it.",Vector3(0,0.025,3.2),true,0.0014)
			words("THE ENDLESS MUSEUM\nalways another room",Vector3(0,3.25,-3.48),false,0.0018)
		"drawing":
			# The next floor is preloaded while Trace is still being drawn. Import
			# its final record on the first live visit, not during that preload.
			place(Drawing,"Drawing",Vector3(0,1.3,2.6),0,{"discovery":"1","style":"line","carry":"none","show_local_fill":true})
			place(Twin,"LiveTwin",Vector3(-5.5,0,-3.2))
			place(Reveal,"FaceMonitor",Vector3(4.0,0,0.8))
			place(WallProof,"PythagorasFloor",Vector3(-3.5,0,-6.8))
			words("02 / ONE DRAWING, TWO SCALES",Vector3(0,0.025,4.0),true,0.0016)
		"surfaces":
			place(QuadBoundary,"FourEdges",Vector3(-2.5,1.35,2.4),270)
			wall(Vector3(-2.5,0.35,2.4),Vector3(1.0,0.7,0.7),Color("e8e4da"),"BoundaryPlinth")
			place(Quad,"SharedDiagonal",Vector3(0.5,1.45,-0.7))
			wall(Vector3(0.5,0.3,-0.7),Vector3(2.2,0.6,0.65),Color("e8e4da"),"QuadPlinth")
			place(Fold,"FoldedStrip",Vector3(0,0.65,-4.5),0,{"study":1,"geometry_scale":1.75})
			# The chapter's pink-front/blue-back face is distinct from the four
			# directional signs. Keep both, as independently editable exhibits.
			place(Parasol,"FacingTriangle",Vector3(0,0,4.6),0,{"size":0.85,"height":1.4,"tilt":0})
			var zone := place(MeshZone,"MeshRevealZone",Vector3(-2.6,0,-2))
			var label := Label3D.new()
			label.name = "Instruction"
			label.text = "STEP INSIDE\nSEE THE TRIANGLES"
			label.font_size = 48
			label.pixel_size = 0.0014
			label.outline_size = 0
			label.position.y = 0.025
			label.rotation.x = -PI/2
			zone.add_child(label)
			# Four separate, copyable variants; all retain the TURN button.
			for i in range(4):
				var title: String = ["PinkTriangle","PinkTriangleDown","PinkTriangleLeft","PinkTriangleRight"][i]
				place(Pink,title,Vector3(-2.95+i*1.3,0,-7.2),0,{"direction":[0,2,3,1][i]})
			words("03 / TWO FACES SHARE AN EDGE",Vector3(0,0.025,1.4),true,0.0015)
			words("ONE FACE / TWO SIDES",Vector3(0,0.025,5.6),true,0.0014)
		"assembly":
			place(Assembly,"TriangleTable",Vector3.ZERO,0,{"already_started":true})
			words("04 / WHAT CAN THESE FACES BECOME?",Vector3(0,0.025,1.8),true,0.0015)
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)] = {"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
	remember_homes.call_deferred()

func place(scene: PackedScene, title: String, at: Vector3, facing := 0.0, config := {}) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.name = title
	node.position = at
	node.rotation_degrees.y = facing
	for key in config: node.set_meta("config_"+str(key),config[key])
	add_child(node)
	if node.has_method("apply_grid_config") and not config.is_empty(): node.apply_grid_config(config)
	var lighting := {"ThreeEdges":"boundary", "FourEdges":"boundary", "Drawing":"drawing", "SharedDiagonal":"quad", "FoldedStrip":"strip", "TriangleTable":"table"}
	if lighting.has(title):
		var light := EdgeLight.new()
		light.name = "EdgeIllumination"
		light.kind = lighting[title]
		node.add_child(light)
	return node

func _process(_delta: float) -> void:
	if encounter != "drawing" or drawing_entered: return
	var tower := get_tree().get_first_node_in_group("void_game")
	if tower != null:
		var floor_root := get_parent()
		while floor_root != null and not floor_root.has_meta("void_content_floor"): floor_root = floor_root.get_parent()
		if floor_root == null or tower.floor_stream == null or tower.floor_stream.focus != int(floor_root.get_meta("void_content_floor")): return
	drawing_entered = true
	var drawing := get_node_or_null("Drawing")
	var twin := get_node_or_null("LiveTwin")
	if drawing != null:
		var archive := get_node_or_null("/root/TraceData")
		if archive != null and not archive.saved_traces.is_empty():
			drawing.clear_all()
			drawing.carry = "trace"
			drawing._carry_seed()
	if twin != null:
		twin._find_source()
		if drawing != null and drawing.placed_points.is_empty(): twin.restore_reference()
		twin.refresh(true)
	remember_homes()

func remember_homes() -> void:
	for body in find_children("*","RigidBody3D",true,false):
		if body.has_method("is_picked_up") and not homes.has(body): homes[body] = body.transform

func reset_after_fall() -> void:
	# Recover dropped tools, leaving the current composition and archive intact.
	for body in homes:
		if not is_instance_valid(body) or body.is_picked_up(): continue
		if body.global_position.y < global_position.y - 1.0:
			body.transform = homes[body]
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
