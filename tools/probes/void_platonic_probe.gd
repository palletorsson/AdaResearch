extends "res://tools/probes/void_ignorance_route_probe.gd"
const Names := ["Tetrahedron","Cube","Octahedron","Dodecahedron","Icosahedron"]
const Counts := [Vector3i(4,6,4),Vector3i(8,12,6),Vector3i(6,12,8),Vector3i(20,30,12),Vector3i(12,30,20)]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_ignorance(true)
		game._set_enabled(false)
		await photograph("family.png",Vector3(0,-45.5,-.3),Vector3(0,-46.85,-4.7),96)
		await photograph("five-solids.png",Vector3(6.9,-46,-2.7),Vector3(-.6,-46.85,-4.7),73)
		await photograph("faces-and-edges.png",Vector3(3.0,-46.25,-2.9),Vector3(2.2,-46.8,-4.7),65)
		var hall: Node3D=game.building.content.exhibits["8/hall"].get_node("Artifact")
		var body: Node3D=hall.get_node("Dodecahedron/Solid")
		# Capture actual XRTools pickup, with the same controls as play.
		game._set_enabled(true)
		game.place_player(Vector3(2.2,-47.94,-3.5))
		await frames(10)
		hand_at(right,body.global_position);await frames(10)
		right.set_input("grip",1.0);await frames(15)
		check("Screenshot uses a real held dodecahedron",body.is_picked_up())
		hand_at(right,Vector3(2.2,-46.6,-3.7));await frames(15)
		await photograph("held.png",Vector3(3.5,-46.1,-2.1),Vector3(2.2,-46.6,-3.7),65)
		right.set_input("grip",0.0);await frames(90)
		await cleanup(true)
	else:
		await exercise_solids(false)
		await exercise_solids(true)
		# The six paired spheres, original controls, shafts and full walk remain valid.
		await exercise_ignorance(false)
		await exercise_ignorance(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	quit(0 if failed.is_empty() else 1)

func exercise_solids(use_xr: bool) -> void:
	await arrive_ignorance(use_xr)
	var Study: Script=load("res://commons/void/platonic_study.gd")
	var hall: Node3D=game.building.content.exhibits["8/hall"].get_node("Artifact")
	var tag := "XR " if use_xr else "Desktop "
	for i in Names.size():
		var station: Node3D=hall.get_node(Names[i])
		var body: Node3D=station.get_node("Solid")
		var study: Node3D=station.get_node("Study")
		var data: Dictionary=Study.topology(body.get_node("Faces").mesh)
		var counts := Vector3i(data.vertices.size(),data.edges.size(),data.planes.size())
		check(tag+Names[i]+" correct V/E/F and Euler relation",counts==Counts[i] and counts.x-counts.y+counts.z==2)
		var closed := true
		for edge in data.adjacency: closed=closed and data.adjacency[edge].size()==2
		check(tag+Names[i]+" closed two-manifold surface",closed)
		var first: Vector2i=data.edges[0]
		var edge_length: float=data.vertices[first.x].distance_to(data.vertices[first.y])
		var regular := true
		for edge in data.edges:
			regular=regular and absf(data.vertices[edge.x].distance_to(data.vertices[edge.y])-edge_length)<.00002
		var sides := 4 if i==1 else 5 if i==3 else 3
		var meetings := 4 if i==2 else 5 if i==4 else 3
		for face in data.face_vertices: regular=regular and face.size()==sides
		for vertex in data.vertices.size():
			var degree := 0
			for edge in data.edges:
				if edge.x==vertex or edge.y==vertex: degree+=1
			regular=regular and degree==meetings
		check(tag+Names[i]+" equal edges, regular face sizes and same vertex degree",regular)
		var convex := true
		for plane in data.planes:
			for vertex in data.vertices: convex=convex and plane.distance_to(vertex)<.00002
		check(tag+Names[i]+" all faces bound the convex solid",convex)
		# Check the source too, so a display cannot conceal a broken original.
		var source: Node3D=load(body.get_meta("void_source")).instantiate()
		root.add_child(source)
		var original: Mesh=source.get_node("MeshInstance3D").mesh
		var original_data: Dictionary=Study.topology(original)
		check(tag+Names[i]+" carries the source vertices and face count",original_data.vertices.size()==data.vertices.size() and original_data.vertices.all(func(v): return data.vertices.has(v)) and original_data.planes.size()==counts.z)
		source.free()
		var start_pose := body.global_transform
		game.place_player(Vector3(station.global_position.x,-47.94,-3.5));await frames(12)
		if use_xr:
			hand_at(right,body.global_position);await frames(12)
			right.set_input("grip",1.0);await frames(12)
		else:
			game.body.desktop_pointer._grab_held(body);await frames(12)
		check(tag+Names[i]+" real grip enables its own light",body.is_picked_up() and study.lamp.visible and study.edge_material.emission_energy_multiplier>1)
		var held_at := body.global_position
		if use_xr: hand_at(right,held_at+Vector3(.2,.15,.12))
		else: game.camera.position.x+=.2
		await frames(15)
		check(tag+Names[i]+" same body and light travel with hand",body.global_position.distance_to(held_at)>.1 and study.lamp.global_position.is_equal_approx(body.global_position))
		if use_xr: right.set_input("grip",0.0)
		else: game.body.desktop_pointer._drop_held();game.camera.position.x-=.2
		await frames(10)
		check(tag+Names[i]+" release restores quiet edges and unfreezes physics",not body.is_picked_up() and not study.lamp.visible and not body.freeze and study.edge_material.emission_energy_multiplier<.2)
		body.freeze=true;body.global_transform=start_pose
		body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,start_pose)
	# XRTools removes hand collision exceptions on a delayed timer after release.
	# Let that real lifecycle finish before destroying the test world's bodies.
	await frames(90)
	await cleanup(use_xr)
