extends "res://commons/artifacts/spine_films/film_stage.gd"
const E = preload("res://commons/artifacts/spine_films/early/geometry.gd")
var source: Node3D
var batch: MultiMeshInstance3D
var marks: MultiMeshInstance3D

func _build() -> void:
	title_text = "An address keeps a place"
	phases.assign(["One row becomes a plane", "Four layers of addresses", "Turn at every address", "Move and scale, keep the address"])
	notes.assign(["A nested frame is placed at each fixed site.","4 x 4 x 4 sites; four frames at each site.","Stable per-site choices come from the existing Molnar study.","Transformation changes the occupant, not the index."])
	source_paths.assign(["res://commons/artifacts/molnar_cube_study/molnar_cube_study.gd"])
	source = load(source_paths[0]).new()
	source.call("_build_data")
	batch = MultiMeshInstance3D.new()
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.mesh = source.call("_frame_mesh")
	batch.multimesh.instance_count = 256
	batch.material_override = E.material(E.PINK)
	display.add_child(batch)
	marks = MultiMeshInstance3D.new()
	marks.multimesh = MultiMesh.new()
	marks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new(); dot.radius=0.025; dot.height=0.05; dot.radial_segments=8; dot.rings=4
	marks.multimesh.mesh = dot
	marks.multimesh.instance_count = 64
	marks.material_override = E.material(E.WHITE)
	display.add_child(marks)
	for i in range(64):
		var cell: Dictionary = source.get("cells")[i]
		marks.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,(cell.home-Vector3(0,1.85,0))*1.55+Vector3(0,1.8,0)))
	evidence = {"sites":source.get("cells").size(),"frames":256,"source_pose_method":"frame_pose","addresses":source.get("cells").map(func(cell): return cell.address)}
	frame_scene(Vector3(0,1.8,0),8.2,0.5,0.3)

func _draw(time: float) -> void:
	var p := phase_index(time); var u := phase_progress(time)
	var count := clampi(int(ceil(16.0*u)),1,16) if p==0 else (16+int(floor(48.0*u)) if p==1 else 64)
	var amount := Vector3.ZERO
	if p==2: amount.y=smoothstep(0,1,u)
	if p==3: amount=Vector3(smoothstep(0,1,u),1,smoothstep(0,1,u))
	source.set("amount",amount)
	batch.multimesh.visible_instance_count=count*4
	marks.multimesh.visible_instance_count=count
	for i in range(64):
		for shell in range(4):
			var pose: Transform3D = source.call("frame_pose",i,shell)
			pose.origin=(pose.origin-Vector3(0,1.85,0))*1.55+Vector3(0,1.8,0)
			pose.basis=pose.basis.scaled(Vector3.ONE*1.55)
			batch.multimesh.set_instance_transform(i*4+shell,pose)
	evidence["visible_sites"]=count

func _exit_tree() -> void:
	if is_instance_valid(source): source.free()

