extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(name:String,ok:bool)->void:
	checks.append({"name":name,"passed":ok});print("PAINT ","PASS " if ok else "FAIL ",name)
	if not ok:failures.append(name)
func run()->void:
	var parent:=Node3D.new();root.add_child(parent);parent.position=Vector3(19,4,-8);parent.rotation.y=.8
	var h=load("res://commons/artifacts/flow_direction_table/flow_direction_table.tscn").instantiate();parent.add_child(h)
	h.set_physics_process(false);h.toggle_play()
	check("Original 200 agents and private physics world are retained",h.flow.agents.size()==200 and h.flow.get_world_3d()!=h.get_world_3d() and h.flow.global_transform==Transform3D.IDENTITY)
	check("Original agent and field sources are used",h.flow.agents[0].get_script().resource_path.ends_with("/FlowAgent.gd") and h.flow.grid is FlowGrid)
	check("Hand pad and original table share their live view",h.pad.material_override==h.screen.material_override)
	check("Draw starts with one constant direction",h.flow.scenario=="wind" and h.flow.grid.vector_field.count(Vector2.RIGHT)==1600)
	check("Pad centre addresses grid centre",h.uv_to_cell(Vector2(.5,.5))==Vector2i(20,20))
	check("Height and camera margins reject stray input",h.point_uv(h.PAD+Vector3(0,.07,0)).x<0 and h.point_uv(h.PAD+Vector3(0,.66,0)).x<0 and h.point_uv(h.PAD+Vector3(.44,.2,0)).x<0)
	var camera:Camera3D=h.viewport.get_camera_3d();var projection:=true
	for uv in [Vector2(.2,.2),Vector2(.2,.8),Vector2(.8,.2),Vector2(.8,.8)]:
		var p:Vector2=(uv-Vector2.ONE*.5)*h.CAMERA_SPAN
		projection=projection and (camera.unproject_position(Vector3(p.x,0,p.y))/Vector2(h.viewport.size)).distance_to(uv)<.001
	check("Input matches the original camera in four quadrants",projection)
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.action();check("Unheld action cannot paint",not h.drawing)
	h.point.on_desktop_grab(pointer);h.point.global_position=h.to_global(h.PAD+Vector3(0,.2,-.2));h._physics_process(.05)
	check("Carrying alone leaves directions unchanged",h.field_edits==0)
	h.point.action();h._physics_process(.05);h._physics_process(.1)
	check("A stationary held point does not invent a direction",h.field_edits==0)
	h.point.global_position=h.to_global(h.PAD+Vector3(0,.2,.2));h._physics_process(.05)
	check("A positive Z stroke writes positive grid Y",h.flow.grid.vector_field[20*40+20]==Vector2.DOWN and h.field_edits==1)
	check("The stroke edits a local strip and keeps other directions",h.flow.grid.vector_field[0]==Vector2.RIGHT and h.changed.count(1)>50 and h.changed.count(1)<160)
	var arrows:=true
	for i in range(1600):
		var v:Vector2=h.flow.grid.vector_field[i];var d:=Vector3(v.x,0,v.y)
		arrows=arrows and h.shafts.get_instance_transform(i).basis.y.distance_to(d)<.001
	check("Cylinder arrows point along the vectors agents sample",arrows)
	# MultiMesh instance colour is quantized by the rendering backend.
	var gold:Color=h.shafts.get_instance_color(20*40+20);var cyan:Color=h.shafts.get_instance_color(0)
	check("Edited cells are gold and untouched cells cyan",Vector3(gold.r,gold.g,gold.b).distance_to(Vector3(h.INK.r,h.INK.g,h.INK.b))<.008 and Vector3(cyan.r,cyan.g,cyan.b).distance_to(Vector3(h.CYAN.r,h.CYAN.g,h.CYAN.b))<.008)
	var kept:PackedVector2Array=h.flow.grid.vector_field.duplicate();h.point.action_release()
	h.point.global_position=h.to_global(h.PAD+Vector3(.2,.2,0));h._physics_process(.1)
	check("Action release keeps the field and stops editing",kept==h.flow.grid.vector_field and not h.drawing)
	h.point.action();h._physics_process(.05);h.point.global_position=h.to_global(h.PAD+Vector3(0,1,0));h._physics_process(.05)
	check("Leaving the surface ends the current segment",h.previous.x<0)
	h.point.global_position=h.to_global(h.PAD+Vector3(-.2,.2,0));h._physics_process(.05)
	check("Reentry begins a new stroke without bridging the gap",kept==h.flow.grid.vector_field)
	h.point.on_desktop_drop(pointer);h._physics_process(3.1)
	check("Drop returns the point and preserves written directions",h.point.position==h.HOME and kept==h.flow.grid.vector_field and h.returns==1)
	h._physics_process(4);check("Resting point is not repeatedly returned",h.returns==1)
	var ids:Array=[];var positions:Array=[]
	for a in h.flow.agents:ids.append(a.get_instance_id());positions.append(a.position)
	h.reset_field()
	check("Reset clears edits to constant wind without respawning",h.changed.count(0)==1600 and h.flow.grid.vector_field.count(Vector2.RIGHT)==1600 and h.flow.agents[0].get_instance_id()==ids[0] and h.flow.agents[0].position==positions[0])
	h.toggle_mode();check("Tour uses original scenarios and visualizer",not h.edit_mode and h.flow.scenario=="tour" and h.flow.visualizer.visible and not h.direction_layer.visible)
	h.point.on_desktop_grab(pointer);h.point.action();check("Tour cannot accidentally be painted",not h.drawing)
	h.point.on_desktop_drop(pointer);h.toggle_mode()
	check("Returning from tour starts a fresh editable field",h.edit_mode and h.flow.scenario=="wind" and h.direction_layer.visible and not h.flow.visualizer.visible)
	# Remove neighbour collisions from this controlled response fixture only.
	for a in h.flow.agents:a.process_mode=Node.PROCESS_MODE_DISABLED
	var a=h.flow.agents[0];a.position=Vector3.ZERO;a.velocity=Vector3.ZERO
	for i in range(1,200):h.flow.agents[i].position=Vector3(15,0,15)
	h.flow.grid.generate_linear_field(Vector2.DOWN);h.refresh_arrows();h.toggle_play()
	a.process_mode=Node.PROCESS_MODE_INHERIT
	await create_timer(.15).timeout
	check("Original agent responds to the edited vector",a.velocity.z>0 and absf(a.velocity.x)<.001 and a.position.z>0)
	var kept_field:PackedVector2Array=h.flow.grid.vector_field.duplicate()
	await create_timer(.1).timeout
	check("Moving agents read without writing the field",kept_field==h.flow.grid.vector_field)
	h.toggle_play();var p:Vector3=a.position;await create_timer(.1).timeout
	check("Pause actually stops the original agent",a.position==p)
	check("Control caps face upward",h.caps.all(func(b):return b.rotation.is_zero_approx()))
	FileAccess.open("res://ada_run/flow_painter_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "))
	parent.queue_free();pointer.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
