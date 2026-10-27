extends "res://tools/probes/sine_yoke.gd"
var pointer:Node3D
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	root.size=Vector2i(1440,900)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("39434b")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.55
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var lamp:=DirectionalLight3D.new();lamp.rotation_degrees=Vector3(-35,-35,0);lamp.light_energy=1;lamp.shadow_enabled=true;scene.add_child(lamp)
	camera=Camera3D.new();camera.name="Camera3D";camera.fov=43;scene.add_child(camera)
	pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new();scene.add_child(pointer)
	var rooms:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var item:Dictionary={}
	for a in rooms.floors[7].artifacts:
		if a.id=="hall":item=a
	var hall:Node3D=load("res://commons/void/primitive_hall.gd").new();hall.position=Vector3(0,-42,0);scene.add_child(hall)
	var config:Dictionary=item.config.duplicate(true);config.only_parts=["PairedCubeDiagonals"];hall.apply_grid_config(config)
	await tick(15)
	var work:Node3D=hall.get_node("PairedCubeDiagonals");var cube:Node3D=work.cubes[0]
	check("one cube replaces the paired bodies and wide measuring display",work.cubes.size()==1 and not work.has_node("CubeB") and not work.has_node("EdgeStudy") and not work.has_node("ReadingPlate"))
	check("saved PairedCubeDiagonals placement survives",work.position.is_equal_approx(Vector3(-10,0,5.75)) and work.scale.is_equal_approx(Vector3.ONE))
	check("original grid builder owns eight corners twelve edges and twelve triangle fragments",cube.get_script().resource_path.ends_with("animatedcubebuilder.gd") and cube.handle_nodes.size()==8 and cube.edge_lines.size()==12 and cube.triangle_meshes.size()==12)
	var palette:Dictionary={};var transparent:=true;var single_skin:=true
	for face in cube.triangle_meshes:
		var mat:StandardMaterial3D=face.material_override;palette[mat.albedo_color.to_html()]=true
		transparent=transparent and mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and is_equal_approx(mat.albedo_color.a,.6) and mat.cull_mode==BaseMaterial3D.CULL_DISABLED
		single_skin=single_skin and face.mesh.get_faces().size()==3
	check("original pink red and black translucent skins are retained",transparent and palette.has("cc336699") and palette.has("cc1a1a99") and palette.has("1a1a1a99"))
	check("transparent fragments have no coincident reverse triangles",single_skin)
	var enabled:=true
	for handle in cube.handle_nodes:enabled=enabled and handle.visible and handle.freeze and handle.collision_layer==4
	check("all eight vertex handles are immediately enabled",enabled and work.free_edit)
	await photo("01-single-transparent-cube",work.to_global(Vector3(2,2.05,3.5)),work.to_global(Vector3(0,.95,.1)))
	var rest:Array=cube.vertices.duplicate();await tick(45)
	check("untouched cube keeps a fixed size and stationary vertices",cube.vertices==rest and cube.scale.is_equal_approx(Vector3.ONE) and is_equal_approx(cube.cube_size,1))
	# Use actual production desktop carry/drop, once for every corner.
	for i in 8:
		work.restore();await tick(2)
		var handle:Node3D=cube.handle_nodes[i];pointer._grab_held(handle)
		var target:Vector3=cube.to_global(rest[i]+Vector3(.13,.14,.15))
		camera.global_basis=Basis.IDENTITY;camera.global_position=target+Vector3(0,0,1.5);pointer._hold_distance=1.5
		await tick(30)
		check("desktop corner %d moves only its shared vertex and connected geometry"%i,only_corner(cube,rest,i) and cube.vertices[i].distance_to(rest[i]+Vector3(.13,.14,.15))<.001 and faces_follow(cube))
		if i==0:
			var kept:Array=cube.vertices.duplicate();work.get_node("Restore").pressed.emit();await tick(3)
			var stable:=true
			for j in 8:stable=stable and cube.vertices[j].distance_to(kept[j])<.001
			check("restore cannot reset a corner currently held on desktop",stable and work.held())
		pointer._drop_held();await tick(3)
		check("desktop corner %d retains its shape after release"%i,not work.held() and handle.freeze and only_corner(cube,rest,i))
	# Actual XRTools pickup with a supplied controller pose, including each of
	# the formerly locked seven corners. No physical-headset claim.
	var origin:=XROrigin3D.new();scene.add_child(origin)
	var hand:=XRController3D.new();origin.add_child(hand)
	var pickup:Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	for i in 8:
		work.restore();await tick(3)
		var handle:Node3D=cube.handle_nodes[i];hand.global_transform=handle.global_transform
		handle.pick_up(pickup);await tick(3)
		hand.global_position+=Vector3(.12,.12,.1);await tick(12)
		check("XRTools corner %d grips and deforms only that corner"%i,handle.is_picked_up() and work.held() and only_corner(cube,rest,i) and faces_follow(cube))
		handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(5)
		check("XRTools corner %d remains editable and frozen after release"%i,not work.held() and handle.freeze and handle.collision_layer==4)
	origin.queue_free();await tick(3)
	var edited:Array=cube.vertices.duplicate();var recipes:Array=cube.triangles.duplicate(true)
	work.get_node("Diagonal").pressed.emit();await tick(3)
	check("one cube compares the other diagonal without moving its corners",work.alternate_diagonal and cube.vertices==edited and cube.triangles[4]==[4,5,6] and cube.triangles[5]==[4,6,7] and faces_follow(cube))
	work.get_node("Diagonal").pressed.emit();await tick(2)
	check("diagonal comparison returns to the original face recipe",cube.triangles==recipes and cube.vertices==edited)
	await photo("02-cube-deformed",work.to_global(Vector3(2,2.05,3.5)),work.to_global(Vector3(0,.95,.1)))
	work.get_node("Replay").pressed.emit();await tick(3)
	check("replay temporarily suspends grabs while revealing the same form",work.replaying and cube.handle_nodes.all(func(h):return h.collision_layer==0))
	var deadline:=Time.get_ticks_msec()+8000
	while work.replaying and Time.get_ticks_msec()<deadline:await tick(1)
	check("replay preserves edited vertices and returns all eight handles",not work.replaying and cube.vertices==edited and cube.handle_nodes.all(func(h):return h.visible and h.collision_layer==4))
	# The parent part stays movable through the existing live editor contract.
	var saved:Transform3D=work.transform
	hall.apply_grid_config({"parts":{"PairedCubeDiagonals":{"position":[-9,.2,5.5],"rotation":[0,73,0]}}});await tick(3)
	var handle:Node3D=cube.handle_nodes[3];pointer._grab_held(handle)
	var goal:Vector3=cube.to_global(edited[3]+Vector3(.1,.1,.1))
	camera.global_basis=Basis.IDENTITY;camera.global_position=goal+Vector3(0,0,1.5);pointer._hold_distance=1.5;await tick(30)
	pointer._drop_held();await tick(3)
	check("moved rotated negative-floor placement still edits vertices in local coordinates",cube.vertices[3].distance_to(edited[3]+Vector3(.1,.1,.1))<.001 and faces_follow(cube))
	work.transform=saved;work.restore();await tick(5)
	check("restore returns all eight original corners and twelve live surfaces",cube.vertices==rest and faces_follow(cube))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native original grid-builder geometry and materials, real desktop carry/drop and supplied XRTools controller poses for all eight vertices, replay/restore and moved editor part. Synthetic XR, not a physical-headset playthrough."},"\t"))
	print("SINGLE_CUBE_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)

func only_corner(cube:Node3D,original:Array,index:int) -> bool:
	if cube.vertices[index].distance_to(original[index])<.03:return false
	for i in 8:
		if i!=index and cube.vertices[i].distance_to(original[i])>.001:return false
	return true

func faces_follow(cube:Node3D) -> bool:
	for i in cube.triangles.size():
		var points:PackedVector3Array=cube.triangle_meshes[i].mesh.get_faces()
		if points.size()!=3:return false
		for point in points:
			var matches:=false
			for index in cube.triangles[i]:matches=matches or point.distance_to(cube.vertices[index])<.001
			if not matches:return false
	return true
