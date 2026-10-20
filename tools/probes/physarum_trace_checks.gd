extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok}); print("TRACE ","PASS " if ok else "FAIL ",title)
	if not ok: failures.append(title)
func run() -> void:
	var parent := Node3D.new(); root.add_child(parent); parent.position=Vector3(24,3,-10); parent.rotation.y=.73
	var host = load("res://commons/artifacts/physarum_trace_gallery/physarum_trace_gallery.tscn").instantiate(); parent.add_child(host)
	host.set_physics_process(false); host.toggle_play()
	var colony = host.source.colony
	var agents: Array = colony.get_children().filter(func(n):return n is PhysarumAgent)
	check("One original 300-agent colony supplies all three views",agents.size()==300 and host.wall.material_override==host.pad.material_override and host.pad.material_override==host.source.screen.material_override)
	check("Original agent and grid resources are used",agents[0].get_script().resource_path.ends_with("physarum/PhysarumAgent.gd") and colony.grid.get_script().resource_path.ends_with("physarum/PhysarumGrid.gd"))
	check("Simulation stays at world origin in its own physics world",colony.global_transform==Transform3D.IDENTITY and colony.get_world_3d()!=host.get_world_3d())
	check("Wall and hand surface retain square proportions",host.wall.mesh.size==Vector2(6,6) and host.pad.mesh.size==Vector2(1.2,1.2))
	check("Pad center maps to grid center",host.uv_to_cell(Vector2(.5,.5))==Vector2i(128,128))
	check("Table corners outside the simulation margin are rejected",host.point_uv(host.PAD+Vector3(.59,.2,0)).x<0)
	check("High and below-surface points cannot write",host.point_uv(host.PAD+Vector3(0,.71,0)).x<0 and host.point_uv(host.PAD+Vector3(0,.07,0)).x<0)
	var camera: Camera3D=host.source.viewport.get_camera_3d()
	var aligned:=true
	for uv in [Vector2(.2,.2),Vector2(.2,.8),Vector2(.8,.2),Vector2(.8,.8)]:
		var world: Vector2 = (uv-Vector2.ONE*.5)*host.CAMERA_SPAN
		var rendered:Vector2=camera.unproject_position(Vector3(world.x,0,world.y))/Vector2(host.source.viewport.size)
		aligned=aligned and rendered.distance_to(uv)<.001
	check("Input coordinates agree with the original live camera in all quadrants",aligned)
	var pointer:=Node3D.new(); root.add_child(pointer)
	host.point.action();check("An unheld point cannot start a stroke",not host.drawing)
	host.point.on_desktop_grab(pointer)
	host.point.global_position=host.to_global(host.PAD+Vector3(-.3,.2,-.2))
	host._physics_process(.1);check("Carrying alone leaves the field intact",host.input_mark_count==0 and colony.grid.grid.count(0.0)==65536)
	host.point.action();host._physics_process(.05)
	var cell:Vector2i=host.uv_to_cell(host.point_uv(host.point.position))
	check("Held action deposits the declared amount into the original field",is_equal_approx(colony.grid.get_slime(cell.x,cell.y),host.INK) and host.input_mark_count==1)
	check("The brush is a bounded circle of 29 cells",host.written_cells==29)
	check("Writing while paused refreshes the actual source texture",colony.p_image.get_pixel(cell.x,cell.y).g>.9)
	var start:=cell
	host.point.global_position=host.to_global(host.PAD+Vector3(.3,.2,-.2));host._physics_process(.05)
	cell=host.uv_to_cell(host.point_uv(host.point.position))
	var continuous:=true
	for x in range(start.x,cell.x+1):continuous=continuous and colony.grid.get_slime(x,cell.y)>0
	check("Moving the held point makes a continuous stroke",continuous)
	host.point.global_position=host.to_global(host.PAD+Vector3(2,.2,0));host._physics_process(.05)
	check("Leaving the surface ends the current segment",host.previous_cell==Vector2i(-1,-1) and not host.wall_cursor.visible)
	host.point.global_position=host.to_global(host.PAD+Vector3(0,.2,.25));host._physics_process(.05)
	var isolated:Vector2i=host.uv_to_cell(host.point_uv(host.point.position))
	check("Re-entering does not bridge the gap",is_zero_approx(colony.grid.get_slime(128,128)) and colony.grid.get_slime(isolated.x,isolated.y)>0)
	host.point.action_release();var written:int=host.input_mark_count;var before:PackedFloat32Array=colony.grid.grid.duplicate();host._physics_process(.2)
	check("Releasing action stops writes and preserves the mark",host.input_mark_count==written and before==colony.grid.grid)
	check("Wall and pad cursors describe the same position",is_equal_approx(host.wall_cursor.position.x,0) and host.wall_cursor.position.y<3.65)
	var stopped:Vector3=agents[0].position;await create_timer(.15).timeout
	check("Pause stops the original agents",agents[0].position==stopped)
	host.toggle_play();await create_timer(.3).timeout;host.toggle_play()
	check("Resume lets the original colony change the field and move",agents[0].position!=stopped and colony.grid.grid!=before)
	# Isolate the stored mark: the unchanged grid rule evolves it without a hand.
	var grid=colony.grid;grid.grid.fill(0);host.write_brush(Vector2i(128,128));var value:float=grid.get_slime(128,128)
	grid.process_step()
	check("The original decay/diffusion changes a mark after writing stops",grid.get_slime(128,128)<value and grid.get_slime(128,128)>0)
	for i in range(30):host.write_brush(Vector2i(128,128))
	var capped := true
	for value_now in grid.grid: capped = capped and value_now <= 10
	check("Repeated deposits respect the original concentration cap",capped)
	host.point.on_desktop_drop(pointer);host._physics_process(3.1)
	check("Dropped point stops writing and returns to its dock",not host.drawing and host.point.position.distance_to(host.HOME)<.001)
	var prior_returns:int=host.return_count;host._physics_process(1)
	check("Resting point is not repeatedly repositioned",host.return_count==prior_returns)
	host.buttons[1].pressed.emit();await process_frame
	check("Restart clears marks and original field while respecting pause",host.input_mark_count==0 and colony.grid.grid.count(0.0)==65536 and not host.playing)
	host.buttons[0].pressed.emit();check("Nearby pause/play button resumes colony",host.playing)
	check("Both control caps face up",host.buttons.all(func(b):return b.global_basis.y.normalized().dot(Vector3.UP)>.99))
	FileAccess.open("res://ada_run/physarum_trace_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "))
	parent.queue_free();pointer.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
