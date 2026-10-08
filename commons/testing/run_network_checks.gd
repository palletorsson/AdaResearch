extends RefCounted
const Surface = preload("res://commons/primitives/pipes/swept_tube.gd")
const Network = preload("res://commons/primitives/pipes/run_network.gd")

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var body = station.specimen
	body.control(8)
	var pipe := Surface.build(PackedVector3Array([Vector3.ZERO,Vector3.UP]),0.2,16,0.05)
	var hollow := true; var winding := true
	for p in pipe.vertices: hollow = hollow and Vector2(p.x,p.z).length() >= 0.1499
	for i in range(0,pipe.indices.size(),3):
		var a: int = pipe.indices[i]; var b: int = pipe.indices[i+1]; var c: int = pipe.indices[i+2]
		winding = winding and (pipe.vertices[b]-pipe.vertices[a]).cross(pipe.vertices[c]-pipe.vertices[a]).dot(pipe.normals[a]) < 0.0
	tree.check("pipe has a real bore with annular rims",hollow and pipe.indices.size()==384)
	tree.check("outer inner and rim faces have clockwise fronts",winding)
	var sag := Network.sag_path(Vector3(-1,2,0),Vector3(1,2,0),0.6)
	tree.check("cable sags while both supports remain exact",sag[0]==Vector3(-1,2,0) and sag[-1]==Vector3(1,2,0) and sag[16].y<1.5)
	var vertical := Network.sag_path(Vector3.ZERO,Vector3(0,2,0),0.6)
	tree.check("vertical cable does not fold under authored sag",vertical[16].is_equal_approx(Vector3(0,1,0)))
	body.control(11); body.rebuild(); body.sync_ends()
	tree.check("network example includes all three forms and three joints",body.strokes.size()==3 and Network.junctions(body.strokes).size()==3 and body.strokes[0].kind=="pipe" and body.strokes[1].kind=="cable" and body.strokes[2].kind=="tube")
	tree.check("connected ends become fixed sockets",not body.ends[2].visible and not body.ends[3].visible and not body.ends[4].visible and body.ends[5].visible)
	var before: Array = body.strokes.duplicate(true)
	# A new pen run starts on the existing pipe and ends in the air.
	for i in 9: body.capture_point(Vector3(1.0,3.7-float(i)*0.1,-1+float(i)*0.09))
	body.finish_stroke(); body.sync_ends(); body.rebuild()
	tree.check("a gesture beginning on a run makes a branch",body.strokes.size()==4 and Network.junctions(body.strokes).size()==4 and body.strokes[-1].ports.size()==1)
	body.control(4)
	tree.check("undo removes branch and its socket together",body.strokes==before)
	# Extend the free pink end towards the cable, then release near its middle.
	body.begin_extension(body.ends[5])
	var start: Vector3 = body.active[-1]
	var target: Vector3 = body.strokes[1].points[16]
	for i in range(1,21): body.capture_point(start.lerp(target,float(i)/20))
	body.finish_stroke(); body.held_end=null; body.blocked_until_release=false; body.sync_ends(); body.rebuild()
	tree.check("extension joins two existing runs on release",Network.junctions(body.strokes).size()==4 and body.strokes[2].points[-1].distance_to(target)<0.001 and not body.ends[5].visible)
	var joined: Array = body.strokes.duplicate(true)
	body.kind_index=1; body.control(9) # Convert last run to a cable, holding its ports.
	tree.check("changing form preserves joined endpoint positions",body.strokes[2].kind=="cable" and body.strokes[2].points[0]==joined[2].points[0] and body.strokes[2].points[-1]==joined[2].points[-1])
	body.control(4)
	# Every changed artifact is in the actual endless-museum room for these images.
	camera.global_position=station.to_global(Vector3(3.6,2.1,5.4)); camera.look_at(station.to_global(Vector3(0,2.4,-0.5)))
	body.rebuild()
	for i in 6: await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.check("native network after joining capture",tree.root.get_texture().get_image().save_png(tree.OUT+"tube-network-joined.png")==OK)
	body.control(11); body.rebuild(); body.sync_ends()
	for i in 6: await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.check("native all forms capture",tree.root.get_texture().get_image().save_png(tree.OUT+"tube-network.png")==OK)
	await layout_checks(tree)
	await cable_checks(tree)
	body.control(8); body.history.clear()

func layout_checks(tree: SceneTree) -> void:
	var layout = load("res://commons/primitives/pipes/pipe_layout.gd").new()
	layout.auto_build=false; tree.root.add_child(layout)
	layout.position=Vector3(1000,0,0)
	layout.load_layout_from_dict({"settings":{"pipe_type":"cable"},"anchors":{"A":[0,2,0],"B":[2,2,0]},"paths":[{"id":"run","from":"A","to":"B"}]})
	tree.check("layout resolves mixed-case anchors with cable geometry",layout.pipe_systems.has("run") and layout.get_pipe_system("run").record.points[-1]==Vector3(2,2,0))
	layout.set_anchor("B",Vector3(3,2,1))
	tree.check("moving an anchor rebuilds its connected run",layout.get_pipe_system("run").record.points[-1]==Vector3(3,2,1))
	for type in ["glass","drain"]:
		layout.pipe_type=type
		layout.add_path({"id":"legacy","from":"A","to":"B","code":"f,r,f","pipe_radius":0.04,"segment_length":0.2})
		var system: Node3D=layout.get_pipe_system("legacy")
		tree.check(type+" legacy code builds at its anchor with explicit connector",system!=null and system.position==Vector3(0,2,0) and system.get_child_count()>0)
	var id1: String=layout.add_path({"from":"A","to":"B"})
	layout.remove_path("legacy")
	var id2: String=layout.add_path({"from":"A","to":"B"})
	tree.check("adding after removal keeps distinct path identities",id1!=id2 and layout.pipe_systems.has(id1) and layout.pipe_systems.has(id2))
	layout.remove_anchor("B")
	tree.check("removing an anchor removes dependent paths",layout.paths.is_empty() and layout.pipe_systems.is_empty())
	layout.load_layout("res://commons/primitives/pipes/layouts/three_forms.json")
	tree.check("downloadable three-form layout builds every run",layout.pipe_systems.size()==4 and layout.get_pipe_system("cable").record.kind=="cable")
	layout.set_anchor("Left",Vector3(-3,3,1))
	tree.check("named endpoints override samples when an anchor moves",layout.get_pipe_system("gesture").record.points[0]==Vector3(-3,3,1))
	layout.queue_free()

func cable_checks(tree: SceneTree) -> void:
	var cable = load("res://algorithms/wavefunctions/line_builder_3d/cable_builder.tscn").instantiate()
	cable.control_point_count=2; tree.root.add_child(cable); cable.set_process(false)
	cable.position=Vector3(1200,0,0)
	for point in cable.control_points:
		if point is RigidBody3D: point.freeze=true
	cable.control_points[0].position=Vector3(0,2,0)
	cable.control_points[1].position=Vector3(0,2,3)
	cable._process(0.0)
	tree.check("old cable sag handles follow a Z span rather than X",absf(cable.curve.get_point_out(0).x)<0.001 and cable.curve.get_point_out(0).z>0.8)
	var mesh: Mesh=cable.mesh_instance.mesh
	cable._process(0.0)
	tree.check("idle legacy cable reuses its mesh",cable.mesh_instance.mesh==mesh)
	var arrays: Array=mesh.surface_get_arrays(0)
	tree.check("shared cable mesh retains shader UVs",arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size())
	cable.control_points[1].position=cable.control_points[0].position
	cable._process(0.0)
	tree.check("collapsed cable clears its old mesh",cable.mesh_instance.mesh==null)
	cable.queue_free()
