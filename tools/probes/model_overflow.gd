extends SceneTree
const OUT := "res://ada_run/model_overflow/"
var checks:Array=[]
var camera:Camera3D
var work:Node3D
var captures:Array=[]

func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok});print("[model overflow] ","PASS " if ok else "FAIL ",label)
func tick() -> void:
	await physics_frame;await process_frame
func bounds() -> AABB:
	var result:=AABB();var first:=true
	for item in work.rendered:
		var box:AABB=item.global_transform*item.get_aabb()
		result=box if first else result.merge(box);first=false
	return result
func capture(id:String,eye:Vector3=Vector3.ZERO,target:Vector3=Vector3.ZERO) -> void:
	var box:=bounds();var centre:=box.get_center();var extent:=maxf(12,maxf(box.size.x,maxf(box.size.y,box.size.z)))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=55
	camera.position=centre+Vector3(-extent*.8,extent*.55,extent*1.35) if eye==Vector3.ZERO else eye
	camera.look_at(centre if target==Vector3.ZERO else target);camera.current=true
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+id+".png"))
	captures.append({"id":id,"mode":work.mode,"steps":work.steps,"capacity":work.capacity,"status":work.status,"bounds_position":str(box.position),"bounds_size":str(box.size)})
	if id in ["source","calls","calls-six","calls-twelve","restored","leak","wrap","unwritten"]:
		var export_root:=Node3D.new();export_root.name="OverflowModel";export_root.transform=work.body.transform
		for item in work.rendered:export_root.add_child(item.duplicate())
		var doc:=GLTFDocument.new();var state:=GLTFState.new()
		var a:=doc.append_from_scene(export_root,state);var b:=doc.write_to_filesystem(state,OUT+id+".glb") if a==OK else FAILED
		check("native GLB export "+id,a==OK and b==OK);export_root.free()
func all_finite() -> bool:
	for item in work.rendered:
		for s in item.mesh.get_surface_count():
			for point in item.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				if not (item.transform*point).is_finite():return false
	return true

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var room=load("res://commons/artifacts/model_overflow/preview.tscn").instantiate();root.add_child(room);current_scene=room
	await tick();work=room.work;work.set_process(false)
	camera=Camera3D.new();root.add_child(camera)
	var verts:PackedVector3Array=work.original_vertices.duplicate();var ids:PackedInt32Array=work.original_indices.duplicate()
	var ref_mesh=work.reference.get_child(0).mesh
	check("source is real previous bay geometry",work.bay_mesh.get_surface_count()>=3 and work.bay_mesh.get_surface_count()==ref_mesh.get_surface_count())
	work.select_mode(0)
	check("source places sixteen independent siblings",work.poses.size()==16 and work.call_stack.is_empty())
	var restored:Array=work.poses.duplicate();await capture("source")
	work.select_mode(1);work.set_capacity(20)
	work.set_steps(6);await capture("calls-six",Vector3(-24,15,24),Vector3(-5,5,-2))
	work.set_steps(12);await capture("calls-twelve",Vector3(-24,15,24),Vector3(-5,5,-2))
	work.set_steps(20)
	check("twenty calls fit exactly in twenty explicit frames",work.call_stack.size()==20 and work.refused==0)
	var first:Transform3D=work.poses[0]
	check("child transforms inherit the previous call",work.poses[1].is_equal_approx(work.next_call(first)))
	work.advance()
	check("twenty-first call refused before append",work.call_stack.size()==20 and work.poses.size()==20 and work.refused==1)
	var kept:Array=work.poses.duplicate();work.advance()
	check("refusal preserves the already-built model",work.poses==kept and work.steps==21)
	check("recursive study uses no runtime recursive nodes",work.body.get_child_count()<30)
	await capture("calls")
	await capture("calls-ground",Vector3(-12,1.75,14),Vector3(0,6,-2))
	work.set_capacity(24)
	check("larger capacity admits the previously refused call",work.poses.size()==21 and work.refused==0)
	work.set_steps(32)
	check("call count remains bounded at highest input",work.call_stack.size()==24 and work.refused==1 and all_finite())
	work.reset();check("reset empties frames and refusal",work.steps==0 and work.call_stack.is_empty() and work.refused==0)
	work.toggle_play();work._process(.36);check("play advances a frame",work.steps==1)
	work.toggle_play();work._process(1);check("hold stops frame advancement",work.steps==1)
	work.select_mode(2);work.set_capacity(16);work.set_steps(16)
	check("missing restore retains sixteen saved transforms",work.call_stack.size()==16 and work.poses.size()==16)
	check("first sibling matches control; later sibling diverges",work.poses[0].is_equal_approx(restored[0]) and not work.poses[1].is_equal_approx(restored[1]))
	check("leaked model composes rather than randomises",work.poses[1].is_equal_approx(work.poses[0]*work.sibling(1)))
	check("leak remains finite",all_finite())
	await capture("leak")
	work.select_mode(0);check("restoring source recovers every sibling",work.poses==restored)
	await capture("restored")
	work.select_mode(3)
	check("unwritten buffer matches original tower",work.buffer_vertices==verts)
	await capture("unwritten")
	work.set_steps(12)
	check("wrapped writes land in first 84 slots",work.last_write==83 and work.buffer_vertices[83]!=verts[83] and work.buffer_vertices[84]==verts[84])
	check("triangle addresses stay fixed",work.original_indices==ids)
	var valid:=true
	for i in ids:valid=valid and i>=0 and i<work.buffer_vertices.size()
	check("every mesh address is in bounds",valid)
	check("old faces stretch between old and new positions",work.buffer_vertices[72].distance_to(work.buffer_vertices[84])>4)
	await capture("wrap")
	await capture("wrap-ground",Vector3(-8,1.75,13),Vector3(4,5,-3))
	for n in [1,16,24,32]:work.set_steps(n);check("wrapped model finite at step %d"%n,all_finite())
	work.reset();check("reset restores overwritten data exactly",work.buffer_vertices==verts)
	work.select_mode(1)
	work.panel.step_dial.set_normalized_value(.5);work.read_controls(0)
	check("native step dial selects sixteen steps",work.steps==16)
	work.panel.limit_dial.set_normalized_value(0);work.read_controls(0)
	check("native capacity dial enforces four frames",work.capacity==4 and work.call_stack.size()==4 and work.refused==1)
	check("stored source survives all faults",work.original_vertices==verts and work.original_indices==ids and work.reference.get_child(0).mesh==ref_mesh)
	check("study has no moving colliders or owned camera",work.body.find_children("*","CollisionObject3D",true,false).is_empty() and work.find_children("*","Camera3D",true,false).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();room.add_child(driver);driver.spawn(Vector3(0,.03,12.3),room);await tick()
	await driver.press(work.panel.buttons["WRAP"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer selects wrap",work.mode==3)
	await driver.press(work.panel.buttons["STEP"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer steps the model",work.steps==1 and work.last_write==6)
	await driver.press(work.panel.buttons["RESET"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer resets buffer",work.steps==0 and work.buffer_vertices==verts)
	await driver.teardown();await tick();await tick()
	work.select_mode(1);work.set_capacity(16);work.set_steps(17)
	await capture("console",Vector3(0,1.8,12.7),Vector3(0,.96,11))
	await capture("above",Vector3(0,32,10),Vector3(0,0,-3))
	var viewer=room.spawn_viewer();await tick()
	check("F6 viewer preserves authored light",not viewer.get_node("Head/PlayerHeldLight").darken_environment)
	var failed=checks.filter(func(c):return not c.passed)
	var file:=FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"captures":captures,"scope":"Explicit bounded fault simulation, actual Godot meshes and desktop pointer. No native stack overflow, unsafe memory, physics collapse, headset test, or museum placement."},"\t"));file.close()
	quit(0 if failed.is_empty() else 1)
