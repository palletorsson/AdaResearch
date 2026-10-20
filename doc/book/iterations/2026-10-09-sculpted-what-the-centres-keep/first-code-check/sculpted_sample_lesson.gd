extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep/"
const Source = preload("res://algorithms/proceduralgeneration/hybrid_complex/cubemound/cube_mound.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
func settle()->void:
	await process_frame;await physics_frame;await process_frame
func source_cells(positions:Array,spacing:float)->Dictionary:
	var origin:Vector3=positions[0]
	for p in positions:origin=origin.min(p)
	origin-=Vector3.ONE
	var result:Dictionary={};var extent:=ceili(1.0/spacing)
	for p in positions:
		var address:Vector3=((p-origin)/spacing).floor()
		for x in range(-extent,extent+1):
			for y in range(-extent,extent+1):
				for z in range(-extent,extent+1):
					var c:Vector3=address+Vector3(x,y,z);result["%d,%d,%d"%[c.x,c.y,c.z]]=true
	return result
func same_vertices(a:ArrayMesh,b:ArrayMesh)->bool:
	var av:PackedVector3Array=a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bv:PackedVector3Array=b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if av.size()!=bv.size():return false
	for i in av.size():
		if not av[i].is_equal_approx(bv[i]):return false
	return true
func run()->void:
	var G=load(DIR+"printed/sample.gd");var F=load(DIR+"printed/faces.gd");var m=G.new()
	m.sample([],0.5);check("Empty input clears data and makes an empty mesh",m.cells.is_empty() and m.centres.is_empty() and F.build(m.faces(),m.origin,.5).get_surface_count()==0)
	m.sample([Vector3.ZERO],.5)
	check("One cube becomes 125 cells with 150 exposed faces",m.cells.size()==125 and m.faces().size()==150 and m.origin==Vector3(-1,-1,-1))
	var mesh:ArrayMesh=F.build(m.faces(),m.origin,.5)
	check("Single sampled box spans 2.5 units",mesh.get_aabb().size.is_equal_approx(Vector3.ONE*2.5))
	check("Address centres have no extra half-cell shift",mesh.get_aabb().position.is_equal_approx(Vector3.ONE*-1.25))
	m.cells={Vector3i.ZERO:true};check("Single cell has six exposed faces",m.faces().size()==6)
	m.cells[Vector3i.RIGHT]=true;check("Two adjacent cells omit both shared sides",m.faces().size()==10)
	mesh=F.build(m.faces(),Vector3.ZERO,.5)
	var arrays:Array=mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var normal_ok:=true
	for i in range(0,vertices.size(),3):normal_ok=normal_ok and (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).normalized().is_equal_approx(normals[i])
	check("Faces become two clockwise triangles with outward normals",vertices.size()==60 and normal_ok)
	m.sample([Vector3.ZERO,Vector3.ZERO],.5);check("Duplicate centres do not duplicate occupied cells",m.cells.size()==125 and m.centres.size()==2)
	m.sample(m.centres,.5);check("Resampling a retained centre array does not erase input",m.centres.size()==2 and m.cells.size()==125)
	var source=Source.new();var matches:=true;var comparisons:=0
	for spacing in [.5,1.0,.6]:
		for points in [[Vector3.ZERO],[Vector3(-1.5,1,0),Vector3(0,1,0),Vector3(1.5,1,0)],[Vector3(-.4,.7,1.2),Vector3(.8,1.4,-.6)]]:
			m.sample(points,spacing);source.voxel_size=spacing
			var recorded:Dictionary=source_cells(points,spacing);var same:=recorded.size()==m.cells.size()
			for c in m.cells:same=same and recorded.has("%d,%d,%d"%[c.x,c.y,c.z])
			var a:ArrayMesh=source.create_mesh_from_voxels(recorded,m.origin,Vector3.ONE)
			var b:ArrayMesh=F.build(m.faces(),m.origin,spacing)
			matches=matches and same and same_vertices(a,b);comparisons+=1
	check("Nine source assembler comparisons match all submitted vertices",matches and comparisons==9)
	source.free()
	m.sample([Vector3.ZERO,Vector3(.4,0,0)],.5);var floor_count:int=m.cells.size()
	check("Subcell centre movement uses floor rather than nearest address",floor_count==125)
	var host:=Node3D.new();host.position=Vector3(4,0,-3);host.rotation.y=.6;root.add_child(host)
	var study=load(DIR+"printed/sculpture.gd").new();host.add_child(study);await settle()
	check("Complete host builds originals and inherited point",study.bodies.size()==3 and study.point.has_method("pick_up") and not study.skin.visible)
	var local_ok:=true
	for i in 3:local_ok=local_ok and study.model.centres[i].is_equal_approx(study.START[i])
	check("Capture undoes translated rotated scaled frame",local_ok)
	var actual_counts:=[study.model.cells.size(),study.model.faces().size()]
	# Count fixture uses exactly the declared centres, separate from floating-point frame roundtrip.
	m.sample(Array(study.START),.5)
	check("Declared three-centre fixture has 275 cells and 270 faces",m.cells.size()==275 and m.faces().size()==270)
	var old_record:Array=study.model.centres.duplicate();var old_cells:Dictionary=study.model.cells.duplicate();var old_mesh:ArrayMesh=study.skin.mesh
	study.act("MOVE");study.act("VIEW");await settle()
	check("Moving source and switching view preserves last sample",study.model.centres==old_record and study.model.cells==old_cells and study.skin.mesh==old_mesh and study.skin.visible)
	study.act("SAMPLE");var moved_counts:=[study.model.cells.size(),study.model.faces().size()]
	check("New capture records moved third centre",study.model.centres[2].is_equal_approx(study.START[2]+Vector3.RIGHT*.5) and study.model.cells!=old_cells)
	var retained:Dictionary=study.model.cells.duplicate();study.bodies[2].rotation+=Vector3(.4,.2,.3);study.act("SAMPLE")
	check("Rotation alone cannot change centre sample",study.model.cells==retained)
	study.act("RESET");await settle();check("Reset restores source positions and original view",not study.show_sample and not study.moved and study.model.centres[2].is_equal_approx(study.START[2]))
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();hand.global_position+=Vector3(.2,.1,0);await settle()
	check("Held movement does not capture or change view",study.point.is_picked_up() and not study.show_sample)
	study.point.action();await settle();check("Held action captures and shows surface",study.show_sample and study.skin.visible and not study.bodies[0].visible)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Release parks inherited point",study.point.position.is_equal_approx(Vector3(0,1.1,1.5)))
	var event:=InputEventKey.new();event.keycode=KEY_V;event.pressed=true;study._unhandled_key_input(event);check("Keyboard view toggles originals",not study.show_sample and study.bodies[0].visible)
	var edited=load(DIR+"variation/sculpture.gd").new();host.add_child(edited);await settle();edited.act("SAMPLE")
	check("Full edited host retains same captured centres and origin",edited.model.centres==study.model.centres and edited.model.origin==study.model.origin)
	check("Edited occupancy is subset of baseline",edited.model.cells.size()<study.model.cells.size() and edited.model.cells.keys().all(func(c):return study.model.cells.has(c)))
	var small=load(DIR+"variation/sample.gd").new();small.sample(Array(study.START),.5)
	check("Declared edit has 81 cells 126 faces",small.cells.size()==81 and small.faces().size()==126)
	small.sample([Vector3.ZERO],.5);check("Edited single-centre envelope is still 1.5 units wide",F.build(small.faces(),small.origin,.5).get_aabb().size.is_equal_approx(Vector3.ONE*1.5))
	var bad_world=load(DIR+"wrong_world/sample.gd").new();bad_world.capture(study.frame,study.bodies)
	check("Reject unconverted world centres",not bad_world.centres[0].is_equal_approx(study.START[0]))
	var bad_round=load(DIR+"wrong_round/sample.gd").new();bad_round.sample([Vector3.ZERO,Vector3(.4,0,0)],.5)
	check("Reject rounded addresses",bad_round.cells.size()!=floor_count)
	var bad_faces=load(DIR+"wrong_faces/sample.gd").new();bad_faces.cells={Vector3i.ZERO:true,Vector3i.RIGHT:true}
	check("Reject hidden internal faces",bad_faces.faces().size()!=10)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_comparisons":comparisons,"counts":{"transformed_host":actual_counts,"moved_host":moved_counts,"edited_host":[edited.model.cells.size(),edited.model.faces().size()]},"scope":"Exact printed program, geometric fixtures, source mesh comparisons, full edit and rejected faults. Supplied hand poses, not physical headset."}
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	origin.queue_free();host.queue_free();await settle();quit(0 if failures.is_empty() else 1)
