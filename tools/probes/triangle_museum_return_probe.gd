extends "res://tools/probes/trace_museum_return_probe.gd"
## Compare the actual tower encounters with Point_Triangle_Context/final.md.
## Reuse the tested desktop/XR grip driver, never substitute geometry algorithms.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	for mode in ([true] if "--capture" in OS.get_cmdline_user_args() else [false,true]):
		await triangle_visit(mode)
	OS.delay_msec(150);await frames(10)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop and synthetic XR grip/release, actual meshes, physics and button callbacks. Mobile captures. No physical headset or human usability claim."},"\t"))
	quit(0 if failed.is_empty() else 1)

func triangle_visit(use_xr: bool) -> void:
	await arrive(use_xr) # Arrive at Trace first; Triangle is only preloaded.
	tag="XR: " if xr else "Desktop: "
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	var content:Node3D=game.building.content
	var area:Node3D=content.exhibits["5/drawing"].get_node("Artifact")
	var source:Node3D=area.get_node("Drawing")
	var twin:Node3D=area.get_node("LiveTwin")
	check(tag+"Triangle preload leaves the archive handoff pending",not area.drawing_entered)
	var archive:Node=root.get_node("TraceData")
	var shadow:Node3D=content.exhibits["4/record"].get_node("Artifact/ShadowPoint")
	game.place_player(Vector3(17,-23.94,3));await frames(15)
	await grab(shadow.point)
	var beginning:Vector3=shadow.point.global_position
	for i in range(24):
		var t:=float(i)/23*TAU
		await carry(shadow.point,beginning+Vector3(sin(t)*.65,.3+cos(t)*.2,cos(t)*.4))
	await release()
	check(tag+"Trace release creates a real retained gesture",archive.saved_traces.size()==1 and archive.saved_traces[0].size()>8)
	if archive.saved_traces.is_empty():return
	var original:Array=archive.saved_traces[0].duplicate()
	var grid:Node3D=content.exhibits["4/record"].get_node("Artifact/GridReplay/SavedTraceGrid")
	game.checkpoint=5;game.place_player(Vector3(13.5,-29.94,4));await frames(50)
	check(tag+"Triangle reads late Trace as an open outline of up to six corners",area.drawing_entered and source.placed_points.size()>=3 and source.placed_points.size()<=6 and source.completed_triangles.is_empty())
	check(tag+"Triangle and Grid preserve the original world record",archive.saved_traces[0]==original and grid._trace_data_list[0].raw_points==original)
	check(tag+"large twin and monitor follow this station",twin.source==source and area.get_node("FaceMonitor").source==source)
	var clear:=true
	for x in [-11.5,-10.0,-8.5]:
		for z in [-1.5,0.0,1.5]: clear=clear and ray(Vector3(x,-24.2,z),Vector3(x,-30.3,z)).is_empty()
	check(tag+"nine physics rays through shaft A miss the former blocking plinth",clear)
	var support:=ray(twin.global_position+Vector3(0,.02,0),twin.global_position+Vector3(0,-.3,0))
	check(tag+"relocated twin rests on solid west slab",twin.global_position.is_equal_approx(Vector3(-16,-30,0)) and not support.is_empty() and support.collider.get_meta("void_floor_index",-1)==5)
	source.get_node("MuseumWorkbench").buttons.close.pressed.emit();await frames(12)
	check(tag+"close connects the carried outline and builds the same fan at both scales",twin.triangle_count==source.placed_points.size()-2 and local_fill(source) and twin.faces.mesh!=null)
	source.get_node("MuseumWorkbench").buttons.fill.pressed.emit();await frames(10)
	check(tag+"hide fill hides both surfaces and retains the edges",not local_fill(source) and not twin.faces.visible and twin.edge_pairs.size()>0)
	source.get_node("MuseumWorkbench").buttons.fill.pressed.emit();await frames(10)
	check(tag+"show fill restores both surfaces",local_fill(source) and twin.faces.visible)
	check(tag+"restore starts from the editable three-corner triangle",twin.restore_reference());await frames(12)
	game.place_player(source.global_position+Vector3(0,-1.24,1.3));await frames(15)
	var handle:Node3D=source.point_indicators[2]
	await grab(handle)
	var midpoint:Vector3=(source.placed_points[0]+source.placed_points[1])*.5
	await carry(handle,midpoint);await carry(handle,midpoint);await release();await frames(10)
	check(tag+"collinear corners remove surface area while keeping three points",twin.faces.mesh==null and twin.corners.multimesh.instance_count==3)
	await grab(handle);await carry(handle,midpoint+Vector3(0,.7,0));await release();await frames(10)
	check(tag+"lifting the same corner restores the surface and both scales agree",twin.faces.mesh!=null and twin.large_points[2].is_equal_approx(twin.CENTRE+source.to_local(source.placed_points[2])*twin.ENLARGEMENT))
	await picture("drawing-desk.png",Vector3(-9.3,-27.8,-4.9),Vector3(-10,-28.85,-7.25))
	await picture("triangle-enlarged.png",Vector3(-12.8,-27.7,3.2),Vector3(-16,-28.3,0))
	await picture("shaft-clear.png",Vector3(-6.9,-25.6,-3.8),Vector3(-10,-29,0))
	await fan_trial(source,twin)
	await closure_trial(content.exhibits["5/arrival"].get_node("Artifact/ThreeEdges"))
	var surfaces:Node3D=content.exhibits["5/surfaces"].get_node("Artifact")
	await shared_faces(surfaces)
	var facing:Node3D=surfaces.get_node("FacingTriangle")
	var colours:PackedColorArray=facing._tri_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	check(tag+"original two-sided parasol exposes two colours on opposite windings",colours.size()==6 and colours[0]!=colours[3] and facing.sidedness=="two_tone" and is_equal_approx(facing.triangle_size,.85))
	check(tag+"parasol culls the hidden side to prevent coplanar colour overwrite",facing._tri_mesh.material_override.cull_mode==BaseMaterial3D.CULL_BACK)
	await picture("pink-face.png",facing.global_position+Vector3(.6,1.9,2.4),facing.global_position+Vector3(0,1.5,0))
	await picture("blue-face.png",facing.global_position+Vector3(-.6,1.9,-2.4),facing.global_position+Vector3(0,1.5,0))
	check(tag+"all four directional signs and the curator copy remain",surfaces.has_node("PinkTriangleRight") and surfaces.has_node("PinkTriangleLeft") and surfaces.has_node("PinkTriangleDown") and content.exhibits.has("5/surfaces-copy-1"))
	var proof:Node3D=area.get_node("PythagorasFloor")
	var splits:Array=[]
	for item in proof.proofs:splits.append(item.split)
	proof.buttons.swap.pressed.emit();await frames(140)
	var reversed:=true
	for i in range(proof.proofs.size()):reversed=reversed and proof.proofs[i].split!=splits[i] and not proof.proofs[i].moving
	check(tag+"three proof walls exchange all six four-triangle arrangements",proof.proofs.size()==6 and reversed)
	proof.buttons.reset.pressed.emit();await frames(10)
	var table:Node3D=content.exhibits["5/assembly"].get_node("Artifact/TriangleTable")
	check(tag+"assembly retains twelve triangular building pieces",table.pieces.size()==12)
	var piece:Node3D=table.pieces[0]
	game.place_player(table.global_position+Vector3(0,.06,1.2));await frames(15)
	await grab(piece);await carry(piece,piece.global_position+Vector3(0,.5,.2));await release()
	check(tag+"released face keeps the visitor's composition",piece.freeze and not piece.is_picked_up())
	await picture("proofs-and-building.png",Vector3(2.9,-27.2,-.1),Vector3(0,-28.5,-4.5))
	var zone:Node3D=surfaces.get_node("MeshRevealZone")
	game.place_player(zone.global_position+Vector3(0,.06,0));await frames(12)
	check(tag+"standing in mesh zone reveals the actual triangles",zone._holding and game.get_viewport().debug_draw==Viewport.DEBUG_DRAW_WIREFRAME)
	await picture("mesh-zone.png",Vector3(3,-27.8,5),Vector3(0,-28.1,-2))
	game.place_player(Vector3(3,-29.94,4.2));await frames(12)
	check(tag+"leaving the zone restores ordinary rendering",not zone._holding and game.get_viewport().debug_draw==Viewport.DEBUG_DRAW_DISABLED)
	check(tag+"all Triangle experiments leave the Trace archive intact",archive.saved_traces[0]==original)
	var kept:Array=source.placed_points.duplicate()
	game.place_player(game.spawn_for(0));await frames(25)
	game.place_player(Vector3(13.5,-29.94,4));await frames(35)
	check(tag+"return preserves the edited face instead of reseeding it",source.placed_points==kept and area.drawing_entered)
	await finish_room(use_xr)

func local_fill(source:Node3D) -> bool:
	return not source.completed_triangles.is_empty() and source.completed_triangles[0].mesh.visible

func closure_trial(puzzle:Node3D) -> void:
	game.place_player(puzzle.global_position+Vector3(0,-1.34,1.15));await frames(15)
	check(tag+"boundary uses the three original loose lines",puzzle.snap_lines.size()==3 and puzzle.stock=="ringed")
	for i in range(3):
		var line:Node3D=puzzle.snap_lines[i]
		for j in range(2):
			var endpoint:Node3D=line.endpoint_a if j==0 else line.endpoint_b
			await grab(endpoint)
			var target:Vector3=puzzle.to_global(puzzle.target_positions[(i+j)%3])
			await carry(endpoint,target);await carry(endpoint,target);await release()
	await frames(10)
	check(tag+"six releases close the boundary without adding a face",puzzle.is_completed and puzzle.discovery_face==null)
	await picture("closed-boundary.png",puzzle.global_position+Vector3(.8,.4,2.7),puzzle.global_position+Vector3(0,-.1,0))
	puzzle.get_node("ExperimentPanel").buttons.fill.pressed.emit();await frames(8)
	check(tag+"separate fill action adds the face",puzzle.discovery_face!=null and puzzle.discovery_face.visible)
	await picture("filled-boundary.png",puzzle.global_position+Vector3(.8,.4,2.7),puzzle.global_position+Vector3(0,-.1,0))

func fan_trial(source:Node3D,twin:Node3D) -> void:
	# Let XRTools' delayed post-release collision cleanup finish before this
	# test replaces its three-corner fixture with the concave outline.
	await frames(60)
	source.clear_all();await frames(5)
	var boundary:=[Vector2(0,0),Vector2(.8,0),Vector2(.8,.3),Vector2(.3,.3),Vector2(.3,.8),Vector2(0,.8)]
	# Fixture supplies six corners to the real drawing tool; its own close and
	# SHIFT START controls build the fan. No replacement triangulation here.
	for p in boundary:source._create_new_point(source.snap_position_to_grid(source.to_global(Vector3(p.x-.4,p.y-.2,0))))
	source.get_node("MuseumWorkbench").buttons.close.pressed.emit();await frames(12)
	var points:Array=source.placed_points.duplicate()
	var first:Array=source.completed_triangles[0].points.duplicate()
	var before:float=mesh_area(source.completed_triangles[0].mesh.mesh)
	source.get_node("MuseumWorkbench").buttons.shift.pressed.emit();await frames(12)
	check(tag+"SHIFT START changes fan anchor without moving the six corners",source.placed_points==points and source.completed_triangles[0].points!=first and twin.triangle_count==4)
	check(tag+"concave fan can cover the notch despite an unchanged outline",mesh_area(source.completed_triangles[0].mesh.mesh)>before+.01)
	await picture("fan-and-shaft.png",Vector3(-12.8,-27.5,3.2),Vector3(-16,-28.3,0))

func mesh_area(mesh:Mesh) -> float:
	var vertices:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var area:=0.0
	for i in range(0,vertices.size(),6):area+=(vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length()*.5
	return area

func shared_faces(surfaces:Node3D) -> void:
	var quad:Node3D=surfaces.get_node("SharedDiagonal")
	check(tag+"quad keeps the original shared diagonal",quad.triangle_a_indices==[0,1,2] and quad.triangle_b_indices==[0,2,3])
	game.place_player(quad.global_position+Vector3(0,-1.39,1.3));await frames(12)
	var handle:Node3D=quad.drag_points.get_sphere(1)
	var before_a:PackedVector3Array=quad.triangle_mesh_a_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var before_b:PackedVector3Array=quad.triangle_mesh_b_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	await grab(handle);await carry(handle,handle.global_position+Vector3(.15,.2,.15));await release()
	check(tag+"nonshared corner changes only its own face",before_a!=quad.triangle_mesh_a_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] and before_b==quad.triangle_mesh_b_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	handle=quad.drag_points.get_sphere(0)
	before_a=quad.triangle_mesh_a_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	before_b=quad.triangle_mesh_b_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	await grab(handle);await carry(handle,handle.global_position+Vector3(.1,.2,.1));await release()
	check(tag+"shared corner changes both faces",before_a!=quad.triangle_mesh_a_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] and before_b!=quad.triangle_mesh_b_front.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var strip:Node3D=surfaces.get_node("FoldedStrip")
	check(tag+"folded strip retains 24 faces and 26 shared corners",strip.num_triangles==24 and strip.drag_points.get_spheres().size()==26)
	game.place_player(Vector3(-8,-29.94,8));await frames(15)
	handle=strip.drag_points.get_sphere(0)
	await grab(handle);await carry(handle,handle.global_position+Vector3(0,.3,.15));await frames(10)
	check(tag+"folded strip pauses to follow the held corner and lights its edges",not strip.fold_study.playing and strip.get_node("EdgeIllumination").lamps[0].visible)
	await picture("folded-strip.png",Vector3(-7,-27.5,6.2),Vector3(-10,-28.8,9.4))
	await release()
