extends Node3D
## An editable explanatory model; not a replacement for the installed museum hall.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Folder := "res://doc/book/iterations/2026-10-13-randomness-concept-map/"
const Ink := Color("21353a")
const Teal := Color("207e79")
const Rose := Color("ae4165")
const Amber := Color("b87827")
var kept_seed := 880
var number: Label3D
var source_mark: Label3D
var grids: Array[Node3D] = []
var camera: Camera3D
var receipt: Dictionary

func _ready() -> void:
	receipt = JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-13-movement-becomes-a-seed/runtime-report.json")).observations.scripted_movement_receipt
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("e8e4d9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d2e3e7")
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62,-30,0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	Stage.box(self,Vector3(0,-0.22,0),Vector3(21,0.4,13),Color("9eaaab"))
	Stage.box(self,Vector3(0,1.4,-6.5),Vector3(21,2.8,0.2),Color("728284"))
	for x in [-10.4,10.4]:Stage.box(self,Vector3(x,0.55,0),Vector3(0.2,1.1,13),Color("728284"))
	_label("WHAT CAN RETURN?",Vector3(0,4.9,-5.8),70,Ink)
	_label("A movement ends. A saved seed can begin the picture again.",Vector3(0,4.0,-5.8),27,Ink)
	# Left entrance: a physical contribution, before any numerical record.
	_podium(Vector3(-7,0,1.2),0.5,1.0)
	var point: Node3D = load("res://commons/artifacts/ignorance_gallery/point_body.gd").new()
	point.position = Vector3(-7,1.22,1.2)
	point.scale = Vector3.ONE*2.0
	add_child(point)
	point.get_child(0).material_override = Stage.material(Color("162630"))
	_label("1  MOVE",Vector3(-7,2.7,1.2),39,Ink)
	_label("A hand, a sphere, a duration",Vector3(-7,2.1,1.2),23,Ink)
	# A simple visitor silhouette establishes scale and contact, not sensor internals.
	_sphere(Vector3(-8.4,1.72,1.4),0.17,Color("c4b6a0"))
	Stage.box(self,Vector3(-8.4,1.05,1.4),Vector3(0.45,0.95,0.28),Color("ae4165"))
	for x in [-8.54,-8.26]:_rod(Vector3(x,0.1,1.4),Vector3(x,0.65,1.4),0.08,Ink)
	_rod(Vector3(-8.2,1.4,1.4),Vector3(-7.65,1.0,1.7),0.065,Rose)
	_rod(Vector3(-7.65,1.0,1.7),Vector3(-7.12,1.22,1.22),0.065,Rose)
	# An alternative seed source enters the same generator, not the pose hash.
	_podium(Vector3(-7,0,-3.2),1.5,1.1)
	_label("435",Vector3(-7,2.15,-3.2),90,Amber)
	_label("SAVED ATMOSPHERE",Vector3(-7,3.25,-3.2),30,Amber)
	_label("A previous arrival / another source",Vector3(-7,1.5,-3.0),21,Ink)
	# The trace sculpture is an enlarged drawing of recorded changes.
	_podium(Vector3(-3.6,0,1.2),1.9,0.6)
	for channel in range(3):
		var previous := Vector3.ZERO
		for i in range(0,120,2):
			var row: Array = receipt.samples[i]
			var y := float(row[channel+1])/100000.0
			if channel == 1:y-=1.2
			if channel == 2:y-=0.4
			var p := Vector3(-4.45+i/120.0*1.7,0.95+channel*0.28+y*0.8,1.2)
			if i>0:_rod(previous,p,0.015,[Rose,Teal,Amber][channel])
			previous=p
	_label("2  RECORD",Vector3(-3.6,2.7,1.2),39,Ink)
	_label("Pose + timing\nA chosen measurement",Vector3(-3.6,2.08,1.2),23,Ink)
	# Seed construction remains explicitly labelled as a deterministic operation.
	_podium(Vector3(0,0,0),1.6,1.7)
	number=_label("880",Vector3(0,2.55,0),100,Teal)
	_label("3  KEEP A SEED",Vector3(0,3.55,0),36,Ink)
	source_mark=_label("Movement fixture",Vector3(0,2.0,0.1),22,Ink)
	_label("bytes > SHA-256 > 32 bits > mod 1000",Vector3(-1.5,0.35,2.6),20,Ink)
	# All grids are generated through the same Godot RNG and RGB request order.
	for pos in [Vector3(4.8,0,-2.6),Vector3(7.8,0,-2.6),Vector3(6.3,0,4.1)]:
		var group := Node3D.new();group.position=pos;add_child(group);grids.append(group)
	_label("4  REPEAT THE PROCEDURE",Vector3(6.3,3.5,-2.6),36,Ink)
	_label("Same seed / same generator / same requests",Vector3(6.3,2.95,-2.6),22,Ink)
	_label("48 draws",Vector3(4.8,0.45,-1.8),23,Teal)
	_label("48 draws",Vector3(7.8,0.45,-1.8),23,Teal)
	_label("CHANGE THE REQUESTS",Vector3(6.3,3.5,4.1),31,Rose)
	_label("Same seed / skip one draw first",Vector3(6.3,2.95,4.1),22,Rose)
	_label("The cells stay. Their colours change.",Vector3(6.3,0.28,5.6),22,Ink)
	_arrow([Vector3(-6.5,0.09,1.2),Vector3(-4.8,0.09,1.2)],Teal)
	_arrow([Vector3(-2.5,0.09,1.2),Vector3(-1.1,0.09,0.2)],Teal)
	_arrow([Vector3(-6,0.09,-3.2),Vector3(-2,0.09,-3.2),Vector3(-0.5,0.09,-1)],Amber)
	_arrow([Vector3(1.1,0.09,0),Vector3(2.9,0.09,0),Vector3(3.6,0.09,-2.4)],Teal)
	_arrow([Vector3(2.9,0.09,0),Vector3(3.9,0.09,4.1)],Rose)
	_arrow([Vector3(8.7,0.09,-3.5),Vector3(8.7,0.09,-5.3),Vector3(0,0.09,-5.3),Vector3(0,0.09,-1.2)],Teal)
	_label("REPLAY",Vector3(2.9,0.45,-5.4),26,Teal)
	_label("Unpredictability is a question about the source.\nA changing trace does not prove it.",Vector3(-5.5,0.5,4.5),24,Ink)
	_label("Who decided what could change?",Vector3(0,0.5,5.7),30,Rose)
	camera = Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=18
	add_child(camera);camera.position=Vector3(0,15,22);camera.look_at(Vector3(0,1,0));camera.current=true
	_rebuild_grids()
	if "--capture" in OS.get_cmdline_user_args():_capture.call_deferred()
	else:_controls()

func _label(words: String, at: Vector3, size: int, hue: Color) -> Label3D:
	var label:=Stage.label(self,words,at)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size=size;label.pixel_size=0.008;label.outline_size=0;label.modulate=hue
	label.no_depth_test=true
	return label

func _podium(at: Vector3, width: float, height: float) -> void:
	Stage.box(self,at+Vector3.UP*height/2,Vector3(width,height,0.75),Color("5b7378"))

func _sphere(at: Vector3, radius: float, hue: Color) -> void:
	var sphere:=MeshInstance3D.new();var shape:=SphereMesh.new()
	shape.radius=radius;shape.height=2*radius;sphere.mesh=shape;sphere.position=at;sphere.material_override=Stage.material(hue);add_child(sphere)

func _rod(a: Vector3,b: Vector3,radius: float,hue: Color) -> void:
	var rod:=MeshInstance3D.new();var mesh:=CylinderMesh.new()
	mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b)
	rod.mesh=mesh;rod.material_override=Stage.material(hue);rod.position=(a+b)/2;add_child(rod)
	var direction:=(b-a).normalized()
	rod.basis=Basis(Quaternion(Vector3.UP,direction))

func _arrow(points: Array, hue: Color) -> void:
	for i in range(1,points.size()):_rod(points[i-1],points[i],0.028,hue)
	var end: Vector3=points[-1]
	var direction: Vector3=(end-points[-2]).normalized()
	var cross:=direction.cross(Vector3.UP)*0.22
	_rod(end,end-direction*0.42+cross,0.03,hue)
	_rod(end,end-direction*0.42-cross,0.03,hue)

func _colours(skip: int) -> PackedColorArray:
	var rng:=RandomNumberGenerator.new();rng.seed=kept_seed
	for i in range(skip):rng.randf()
	var result:=PackedColorArray()
	for i in range(16):result.append(Color(rng.randf(),rng.randf(),rng.randf()))
	return result

func _rebuild_grids() -> void:
	number.text=str(kept_seed)
	source_mark.text="Movement fixture" if kept_seed==880 else "Saved atmospheric draw"
	for i in range(grids.size()):
		var group: Node3D=grids[i]
		for old in group.get_children():group.remove_child(old);old.queue_free()
		Stage.box(group,Vector3(0,1.5,-0.05),Vector3(2.15,2.15,0.1),Ink)
		var colours:=_colours(1 if i==2 else 0)
		for cell in range(16):
			Stage.box(group,Vector3((cell%4-1.5)*0.51,1.5+(1.5-cell/4)*0.51,0.10),Vector3(0.49,0.49,0.22),colours[cell])

func _controls() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var row:=HBoxContainer.new();row.position=Vector2(20,20);layer.add_child(row)
	for entry in [["Movement fixture 880",880],["Saved atmosphere 435",435]]:
		var button:=Button.new();button.text=entry[0];row.add_child(button)
		var value:int=entry[1]
		button.pressed.connect(func():kept_seed=value;_rebuild_grids())
	var replay:=Button.new();replay.text="REPLAY";row.add_child(replay);replay.pressed.connect(_rebuild_grids)

func _capture() -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(Folder+"godot-concept-map.png"))
	var sample_script=load("res://algorithms/randomness/seed_replay/movement_seed.gd")
	var checks:={"fixture_seed_matches_hash":sample_script.seed_for(receipt.source,receipt.samples)==880,"same_requests_agree":_colours(0)==_colours(0),"skipping_changes_picture":_colours(0)!=_colours(1),"grids_have_16_cells":grids[0].get_child_count()==17,"seed_range_explicit":kept_seed>=0 and kept_seed<1000}
	var kept:=_colours(0);_rebuild_grids();checks["replay_keeps_colours"]=_colours(0)==kept
	kept_seed=435;_rebuild_grids();checks["other_source_reaches_same_generator"]=_colours(0)!=kept and number.text=="435"
	var passed:=true
	for value in checks.values():passed=passed and value
	var f:=FileAccess.open(Folder+"concept-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Standalone explanatory Godot model, synthetic movement fixture; not a new installed hall or headset test."},"  "));f.close()
	print("CONCEPT MAP: ",checks)
	get_tree().quit(0 if passed else 1)
