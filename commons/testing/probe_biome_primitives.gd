extends SceneTree
const Model := preload("res://commons/artifacts/biome_primitives/encounter_model.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)

func run() -> void:
	var m = Model.new()
	m.move_point(Vector3(2,.3,1))
	m.advance(10)
	check(m.samples.is_empty(), "Point has no implicit movement history")
	m.set_stage(1)
	check(m.anchor == Vector3(2,.3,1), "First relation takes the present point as anchor")
	m.move_point(Vector3(3,.3,2))
	check(m.anchor != m.point, "Moving the point leaves the anchor fixed")
	m.set_stage(2)
	m.advance(.06)
	check(m.samples.is_empty(), "No sample before the interval")
	m.advance(.06)
	check(m.samples.size() == 1, "Interval captures the observed position")
	m.advance(2)
	check(m.samples.size() == 1, "Stationary frames do not fill memory")
	m.move_point(Vector3(4,.3,2))
	m.advance(2)
	check(m.samples.size() == 2, "A stalled frame does not fabricate intermediate points")
	var archive: Array = m.samples.duplicate(true)
	m.toggle_capability()
	m.move_point(Vector3(-3,.3,2))
	m.advance(2)
	check(m.samples == archive and m.snapshot().visible_samples == 0, "Withdraw retains hidden archive and stops recording")
	m.toggle_capability()
	m.advance(.12)
	check(m.samples.back().start, "Return does not bridge unrecorded movement")
	m.set_stage(3)
	var p: Vector3 = m.point
	m.toggle_capability()
	check(m.level() == 2 and m.point == p, "Grid withdrawal leaves other capabilities and position")
	m.set_stage(3)
	m.move_point(Vector3(-5.8,.3,-5.8))
	check(m.address() == Vector2i(0,0), "Negative-side cell address")
	m.move_point(Vector3(5.95,.3,5.95))
	check(m.address() == Vector2i(11,11), "Outer boundary stays in final cell")
	m.move_point(Vector3(.2,.3,.2))
	var cell: Vector2i = m.address()
	m.move_point(Vector3(.8,.3,.8))
	check(m.address() == cell and is_equal_approx(m.point.x, .8), "Address does not snap or collapse the point")
	m.clear_memory()
	m.capacity = 4
	for i in range(9):
		m.move_point(Vector3(float(i)*.1,.3,0))
		m.advance(.12)
	check(m.samples.size() == 4 and m.dropped == 5, "Memory drops exactly the oldest samples")
	check(m.samples[0].start and is_equal_approx(float(m.samples[0].p[0]), .5), "Truncated history starts at first retained point")
	m.set_stage(0)
	m.toggle_capability()
	p = m.point
	m.move_point(Vector3.ZERO)
	check(m.point == p and m.level() == -1, "Withdrawn point cannot be moved")
	m.clear_memory()
	check(m.samples.is_empty() and m.dropped == 0, "Clear memory is explicit")
	# Shared input fixture becomes an oracle for the browser companion.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/biome_primitives/pilot.json"))
	var snapshots := {}
	# Load the scene after the project's autoloads.
	var scene: PackedScene = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn")
	for stage in range(Model.STAGES.size()):
		var a = Model.new()
		var b = Model.new()
		a.set_stage(stage)
		b.set_stage(stage)
		for action in (data.hinge_demo if stage >= 6 else (data.form_demo if stage >= 4 else data.demo)):
			a.move_point(Model._vec(action.p))
			a.advance(float(action.dt))
			b.move_point(Model._vec(action.p))
			b.advance(float(action.dt))
		check(a.snapshot() == b.snapshot(), "Repeatable fixture for stage %d" % stage)
		snapshots[Model.STAGES[stage]] = a.snapshot()
		var artifact = scene.instantiate()
		artifact.stage = Model.STAGES[stage]
		artifact.demo = true
		root.add_child(artifact)
		await process_frame
		check(artifact.get_state() == a.snapshot(), "Scene exposes the model's exact record")
		artifact.set_hall("Point_Trace")
		check(artifact.model.level() == 2, "Hall sets capability without a control panel")
		artifact.position = Vector3(20,4,-8)
		artifact.observe_player(Vector3(22,4,-10),.12)
		check(artifact.model.point.is_equal_approx(Vector3(2,.05,-2)), "Walk uses local frame under a moved parent")
		var saved: Array = artifact.model.samples.duplicate(true)
		artifact.observe_player(Vector3(30,4,-10),.12)
		check(artifact.model.samples == saved, "Outside the ground does not record a false boundary path")
		artifact.observe_player(Vector3(18,4,-10),.12)
		check(artifact.model.samples.back().start, "Reentry begins a new stroke")
		check(artifact.find_children("*", "Label3D", true, false).is_empty(), "No in-world interface or labels")
		var floor_shape: BoxShape3D = artifact.get_node("Ground/WalkableFloor").get_child(0).shape
		check(floor_shape.size == Vector3(12,.16,12) and artifact.scale == Vector3.ONE, "Full-size twelve-metre collidable ground")
		artifact.free()
	# Exercise active-camera discovery, not only direct coordinate injection.
	var ground = scene.instantiate()
	ground.stage = "Point_Trace"
	ground.demo = true
	root.add_child(ground)
	ground.model.clear_memory()
	var walker := Node3D.new()
	walker.add_to_group("em_walker")
	walker.position = Vector3(2,0,-3)
	var camera := Camera3D.new()
	camera.position.y = 1.65
	walker.add_child(camera)
	root.add_child(walker)
	camera.make_current()
	ground._process(.12)
	check(ground.model.point.is_equal_approx(Vector3(2,.05,-3)), "Active museum desktop camera selects its walker")
	walker.free()
	var origin := XROrigin3D.new()
	origin.position = Vector3(-2,0,0)
	var xr_camera := Camera3D.new()
	xr_camera.position = Vector3(1,1.65,2)
	origin.add_child(xr_camera)
	root.add_child(origin)
	xr_camera.make_current()
	ground._process(.12)
	check(ground.model.point.is_equal_approx(Vector3(-1,.05,2)), "Room-scale camera movement is included in ground projection")
	origin.free()
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(0,2,0),Vector3(0,-1,0))
	var hit: Dictionary = ground.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.get("collider") == ground.get_node("Ground/WalkableFloor"), "Physics ray hits the walkable floor")
	ground.free()
	var walk_scene: PackedScene = load("res://commons/testing/biome_primitives_walk.tscn")
	var walk = walk_scene.instantiate()
	root.add_child(walk)
	for frame in range(40): await physics_frame
	check(walk.walker.is_on_floor(), "Standalone full-size walk scene supports its body")
	walk.free()
	# Test the spatial claim against Godot collision, not a width calculation.
	var study = scene.instantiate()
	study.stage = "Primitives_Polythedra"
	study.demo = true
	root.add_child(study)
	await physics_frame
	await physics_frame
	var forms: Array = study.model.forms()
	check(forms.size() == 5 and study.get_node("Ground/Forms").get_child_count() == 5, "Five solid forms and five colliders")
	check(study.get_node("Ground/Forms/form_0/TwoTriangles").mesh.get_surface_count() == 2, "Front face is explicitly two triangles")
	var space: PhysicsDirectSpaceState3D = study.get_world_3d().direct_space_state
	var narrow_x: float = float(forms[0].center[0]) + .55 + .35*.5
	var wide_x: float = float(forms[1].center[0]) + .55 + .65*.5
	check(clear_fraction(space, Vector3(narrow_x,.9,4), Vector3(0,0,-8),.25) < .5, "Half-metre body is stopped by the 0.35 metre gap")
	check(clear_fraction(space, Vector3(narrow_x,.9,4), Vector3(0,0,-8),.12) > .999, "Same gap permits a different collision body")
	check(clear_fraction(space, Vector3(wide_x,.9,4), Vector3(0,0,-8),.25) > .999, "Half-metre body passes the 0.65 metre gap")
	check(clear_fraction(space, Vector3(5.3,.9,4), Vector3(0,0,-8),.25) > .999, "An edge route remains available")
	var route_clear := true
	for i in range(1, data.form_demo.size()):
		var start := Model._vec(data.form_demo[i-1].p)
		var end := Model._vec(data.form_demo[i].p)
		start.y = .9
		end.y = .9
		if clear_fraction(space,start,end-start,.25) < .999: route_clear = false
	check(route_clear, "Recorded form-study walk fits between every collision surface")
	var retained: Dictionary = study.model.snapshot()
	study.set_hall("Point_Triangle_Context")
	await physics_frame
	await physics_frame
	var panels: Array = study.model.forms()
	check(is_equal_approx(float(panels[0].size[2]),.04), "Surface stage uses a stated thin collision slab")
	check(is_equal_approx(float(panels[0].center[2])+.02,.4), "Thin panel retains the solid front position")
	check(clear_fraction(space,Vector3(-4.15,.9,-1),Vector3(0,0,-1),.25) > .999, "Withdrawn depth frees the former interior")
	study.set_hall("Point_Line_Grid")
	await physics_frame
	await physics_frame
	check(study.get_node("Ground/Forms").get_child_count() == 0, "Withdrawing surfaces removes their collision bodies")
	check(clear_fraction(space,Vector3(-4.15,.9,4),Vector3(0,0,-8),.25) > .999, "Former solid location is traversable on grid ground")
	study.set_hall("Primitives_Polythedra")
	check(study.model.forms() == forms, "Returning solid capability restores the same specimen")
	check(study.model.snapshot().samples == retained.samples and study.model.clock == retained.clock, "Stage changes preserve the recorded walk and its clock")
	study.free()
	# A fixed pivot preserves distances while the collision routes change.
	var hinges = scene.instantiate()
	hinges.stage = "Trans_Rotation"
	hinges.demo = true
	root.add_child(hinges)
	await physics_frame
	await physics_frame
	space = hinges.get_world_3d().direct_space_state
	var rest: Array = hinges.model.forms()
	check(hinges.get_node("Ground/Forms/form_0") is AnimatableBody3D, "Hinged geometry has a moving collision body")
	check(clear_fraction(space,Vector3(-4.15,.9,4),Vector3(0,0,-8),.25)<.5, "Closed face blocks the forward route")
	check(clear_fraction(space,Vector3(-4.15,.9,-.5),Vector3(2,0,0),.25)>.999, "Closed faces leave a transverse route behind them")
	hinges.model.hinge_angle = PI*.5
	hinges._update_form_poses()
	await physics_frame
	await physics_frame
	check(clear_fraction(space,Vector3(-4.15,.9,4),Vector3(0,0,-8),.25)>.999, "Quarter-turn opens the former face as a forward route")
	check(clear_fraction(space,Vector3(-4.15,.9,-.5),Vector3(2,0,0),.25)<.6, "The same turn interrupts the transverse route")
	for i in range(rest.size()):
		var form: Dictionary = hinges.model.forms()[i]
		var pivot := Model._vec(form.pivot)
		var body: Node3D = hinges.get_node("Ground/Forms/form_%d" % i)
		var corner := body.transform * Vector3(-.55,0,.02)
		check(corner.is_equal_approx(pivot+Vector3.UP*.9), "Left-edge pivot remains fixed for panel %d" % i)
		check(form.size == rest[i].size and form.id == rest[i].id, "Rotation preserves dimensions and identity %d" % i)
	hinges.model.hinge_time = 6
	hinges.model.hinge_angle = Model.angle_at(6)
	hinges.observe_player(Vector3(-4.1,0,-.3),.12)
	var held_time: float = hinges.model.hinge_time
	var held_angle: float = hinges.model.hinge_angle
	hinges._physics_process(.1)
	check(hinges.model.hinge_held and hinges.model.hinge_time == held_time and hinges.model.hinge_angle == held_angle, "Actual artifact physics holds when tracked visitor is in a sweep")
	var world_time: float = hinges.model.clock
	hinges.observe_player(Vector3(-4.1,0,-.3),.12)
	check(hinges.model.clock > world_time, "Holding the motor does not stop the general clock")
	hinges.observe_player(Vector3(0,0,4.5),.12)
	hinges._physics_process(.1)
	check(not hinges.model.hinge_held and hinges.model.hinge_time > held_time, "Leaving the sweep resumes from the retained phase")
	var frozen: Array = hinges.model.forms()
	hinges.model.toggle_capability()
	hinges._refresh()
	hinges._physics_process(.1)
	check(hinges.model.forms() == frozen, "Withdrawing motor holds the pose instead of replacing panels with solids")
	hinges.model.toggle_capability()
	hinges._physics_process(.1)
	check(hinges.model.forms() != frozen, "Returning motor resumes its motion")
	check(is_zero_approx(Model.angle_at(1)) and is_equal_approx(Model.angle_at(11),PI*.5), "Motor rests at both endpoints")
	check(is_equal_approx(Model.angle_at(6),PI*.25) and is_equal_approx(Model.angle_at(16),PI*.25), "Eased turns have matching midpoint poses")
	check(is_zero_approx(Model.angle_at(20)), "Motor loop meets its starting pose")
	snapshots["hinge_schedule"] = []
	for time in [0.0,1.0,2.0,4.0,6.0,10.0,11.0,12.0,16.0,19.9,20.0]:
		hinges.model.hinge_angle = Model.angle_at(time)
		snapshots.hinge_schedule.append({"time":time,"angle":hinges.model.hinge_angle,"forms":hinges.model.forms()})
	hinges.free()
	# A width comparison keeps the pivots and body fixed. Check actual collision.
	var scaling = scene.instantiate()
	scaling.stage = "Trans_Scale"
	scaling.demo = true
	root.add_child(scaling)
	await physics_frame
	await physics_frame
	space = scaling.get_world_3d().direct_space_state
	var small: Array = scaling.model.forms()
	check(clear_fraction(space,Vector3(-3.645,.9,4),Vector3(0,0,-8),.25)>.999, "Narrow panels admit the half-metre body through the first gap")
	scaling.model.width_factor = 1.25
	scaling._update_form_poses()
	await physics_frame
	await physics_frame
	check(clear_fraction(space,Vector3(-3.645,.9,4),Vector3(0,0,-8),.25)<.5, "Wider panels block the same body on the same route")
	check(clear_fraction(space,Vector3(5.5,.9,4),Vector3(0,0,-8),.25)>.999, "Scale leaves an outer route available")
	scaling.model.hinge_angle = PI*.25
	scaling._update_form_poses()
	for i in range(small.size()):
		var form: Dictionary = scaling.model.forms()[i]
		var body: Node3D = scaling.get_node("Ground/Forms/form_%d" % i)
		var corner := body.transform * Vector3(-float(form.size[0])*.5,0,.02)
		check(corner.is_equal_approx(Model._vec(small[i].pivot)+Vector3.UP*.9), "Scale and rotation keep hinge %d fixed" % i)
		check(body.scale == Vector3.ONE, "Moving collision body %d is never non-uniformly scaled" % i)
		var shape: BoxShape3D = body.get_child(0).shape
		check(shape.size.is_equal_approx(Vector3(1.375,1.8,.04)), "Collision dimensions follow the visible width %d" % i)
		var visual: MeshInstance3D = body.get_child(1)
		check(is_equal_approx(visual.mesh.size.x * visual.scale.x, 1.375), "Visible width matches collision width %d" % i)
	var pose: Dictionary = Model.scale_pose_at(22)
	scaling.model.scale_time = 22
	scaling.model.width_factor = pose.factor
	scaling.model.hinge_angle = pose.angle
	scaling.observe_player(Vector3(5.2,0,.4),.12)
	scaling._physics_process(.1)
	check(scaling.model.hinge_held and scaling.model.scale_time == 22 and scaling.model.width_factor == pose.factor, "Visitor within future maximum sweep holds growth before it reaches them")
	world_time = scaling.model.clock
	scaling.observe_player(Vector3(5.2,0,.4),.12)
	check(scaling.model.clock > world_time, "Width hold does not stop the general clock")
	scaling.observe_player(Vector3(0,0,4.5),.12)
	scaling._physics_process(.1)
	check(not scaling.model.hinge_held and scaling.model.scale_time > 22, "Leaving the sweep resumes scale at the retained phase")
	frozen = scaling.model.forms()
	scaling.model.toggle_capability()
	scaling._refresh()
	scaling._physics_process(.1)
	check(scaling.model.forms() == frozen, "Withdrawal holds width and angle without losing the specimen")
	scaling.model.toggle_capability()
	scaling._physics_process(.1)
	check(scaling.model.forms() != frozen, "Returning scale resumes growth")
	check(is_equal_approx(float(Model.scale_pose_at(6).angle), float(Model.scale_pose_at(30).angle)), "Narrow and wide comparison repeat the same turn")
	check(Model.scale_pose_at(48) == Model.scale_pose_at(0), "Scale schedule closes its loop")
	var separate := true
	for tick in range(480):
		var before: Dictionary = Model.scale_pose_at(tick*.1)
		var after: Dictionary = Model.scale_pose_at((tick+1)*.1)
		if not is_equal_approx(float(before.factor),float(after.factor)) and (not is_zero_approx(float(before.angle)) or not is_zero_approx(float(after.angle))): separate = false
	check(separate, "Width changes only while the panels are closed")
	snapshots["scale_schedule"] = []
	for time in [0.0,6.0,11.0,19.0,20.0,22.0,24.0,30.0,35.0,44.0,46.0,48.0]:
		pose = Model.scale_pose_at(time)
		scaling.model.width_factor = float(pose.factor)
		scaling.model.hinge_angle = float(pose.angle)
		snapshots.scale_schedule.append({"time":time,"pose":pose,"forms":scaling.model.forms()})
	scaling.free()
	DirAccess.make_dir_recursive_absolute("res://ada_run/biome_primitives")
	var file := FileAccess.open("res://ada_run/biome_primitives/oracle.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshots, "  "))
	file.close()
	print("[probe_biome_primitives] %d checks, %d failed" % [checks, failed])
	quit(1 if failed else 0)

func clear_fraction(space: PhysicsDirectSpaceState3D, start: Vector3, motion: Vector3, radius: float) -> float:
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY,start)
	query.motion = motion
	query.collision_mask = 1
	query.margin = .001
	var fractions := space.cast_motion(query)
	return fractions[0]
