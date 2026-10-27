extends "res://tools/probes/movable_pivot_probe.gd"
## Saved tabletop model, plus isolated full-size collision tests. No tower integration claim.
var metrics: Dictionary={}

func xyz(v: Vector3) -> Array:return [v.x,v.y,v.z]

func floor_contact(ball: RigidBody3D, member: String) -> bool:
	for body in ball.get_colliding_bodies():
		if member in str(body.get_path()):return true
	return false

func ball_slide(full: Node3D,start: Vector3,velocity: Vector3,target: String) -> void:
	var ball:=RigidBody3D.new();ball.name="SlideBall";ball.mass=.3;ball.continuous_cd=true
	ball.contact_monitor=true;ball.max_contacts_reported=12
	var collision:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=.14;collision.shape=sphere;ball.add_child(collision)
	var material:=PhysicsMaterial.new();material.friction=.25;material.bounce=0;ball.physics_material_override=material
	host.add_child(ball);ball.global_position=full.to_global(start);ball.linear_velocity=velocity
	var reached:=false
	for frame in 480:
		await ticks(1)
		var local: Vector3=full.to_local(ball.global_position)
		if (target=="TurnLanding" and local.y<7 and local.y>6.5 and local.x>1.95) or (target=="ExitDeck" and local.y<1 and local.x< -1.95):
			if not ball.get_colliding_bodies().is_empty():reached=true;break
		if ball.global_position.y < -2:break
	metrics[target+"_ball_end"]=xyz(full.to_local(ball.global_position))
	check("Jolt ball descends to "+target,reached)
	ball.free();await ticks(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();host.name="BooleanSDescentStudy";root.add_child(host);current_scene=host
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("b6b3ba")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e5dce4");env.ambient_light_energy=.7
	environment.environment=env;host.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/s-boolean"].get_node("Artifact")
	check("registered saved model loads with 8 independent members",artifact.part_defaults.size()==8)
	await artifact.prepare_editor_preview()
	var entry: Node3D=artifact.get_node("EntryMouth");var exit: Node3D=artifact.get_node("ExitMouth")
	check("1:10 model represents a twelve-metre / two-storey descent",absf(entry.position.y-exit.position.y-1.2)<.0001)
	metrics.model_drop=entry.position.y-exit.position.y;metrics.canonical_drop=12;metrics.parts=artifact.part_defaults
	# Build an isolated full-size route outside the building. It is a geometry
	# fixture, not an installed full-size floor or a physical-headset playtest.
	var full: Node3D=load("res://commons/modular/recipe_area.tscn").instantiate()
	full.apply_grid_config({"recipe":"boolean_s_descent_model","bindings":{"model_scale":1,"yaw":0,"xray":true}})
	full.position=Vector3(60,0,0);host.add_child(full)
	for member in ["StudyStand","LevelGuide0","LevelGuide6","LevelGuide12"]:full.get_node(member).free()
	await ticks(8)
	await full.prepare_editor_preview();await ticks(4)
	var passage: Node3D=full.get_node("ContinuousPassage/Source")
	check("original Boolean Tunnel supplies the subtraction lineage",passage.get_meta("source_artifact")=="boolean_tunnel" and passage.get_meta("boolean_operands")==2)
	check("one baked Boolean mesh and one matching physical body",passage.find_children("*","MeshInstance3D",true,false).size()==1 and passage.find_children("*","StaticBody3D",true,false).size()==1)
	var clear:=true;var rays:=true;var internal_caps:=false;var count:=0
	var capsule:=CapsuleShape3D.new();capsule.radius=.3;capsule.height=1.8
	var path: Array=passage.get_meta("sweep_path");var origin:=Vector3(path[0][0],path[0][1],path[0][2])
	for i in path.size():
		var point: Array=path[i];var local:=Vector3(point[0],point[1],point[2])-origin
		var foot: Vector3=passage.to_global(local)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform.origin=foot+Vector3.UP*1.35;query.collision_mask=1
		if not host.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():clear=false
		var ray:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.05,foot-Vector3.UP*.4,1)
		if host.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():rays=false
		if i>0 and i<path.size()-1:
			var before: Array=path[i-1];var after: Array=path[i+1];var tangent:=Vector3(after[0]-before[0],0,after[2]-before[2]).normalized()
			var centre:=foot+Vector3.UP*1.4
			if not host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(centre-tangent*.025,centre+tangent*.025,1)).is_empty():internal_caps=true
		count+=1
	check("continuous Boolean floor beneath all %d centreline samples"%count,rays)
	check("upright 1.8m capsule clears the actual Boolean shell",clear)
	check("no transverse caps obstruct any interior path join",not internal_caps)
	var mouths_open:=true
	for end in [0,path.size()-1]:
		var point: Array=path[end];var local:=Vector3(point[0],point[1],point[2])-origin
		var direction:=Vector3.RIGHT if end==0 else Vector3.LEFT
		var centre: Vector3=passage.to_global(local+Vector3.UP*1.4)
		if not host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(centre-direction*.3,centre+direction*.3,1)).is_empty():mouths_open=false
	check("entrance and exit mouths are physically open",mouths_open)
	await ball_slide(full,Vector3(-1.85,12.9,-1.2),Vector3(1.2,0,0),"TurnLanding")
	await ball_slide(full,Vector3(1.85,6.9,1.2),Vector3(-1.2,0,0),"ExitDeck")
	var walker: CharacterBody3D=load("res://commons/void/walker.gd").new();walker.scripted_input=true
	host.add_child(walker);walker.global_position=full.to_global(Vector3(2,6.68,-1.2));await ticks(20)
	var completed:=true;var lowest: float=walker.position.y
	for i in range(1,25):
		var angle: float=PI*i/24
		var target: Vector3=full.to_global(Vector3(2+1.2*sin(angle),6.65,-1.2*cos(angle)))
		var reached:=false
		for frame in 75:
			var delta: Vector3=target-walker.global_position;delta.y=0
			if delta.length()<.09:reached=true;break
			walker.drive=Vector2(delta.x,delta.z).normalized()*.45
			await ticks(1);lowest=minf(lowest,walker.global_position.y)
		if not reached:completed=false;break
	metrics.landing_walker_end=xyz(full.to_local(walker.global_position));metrics.landing_lowest=lowest
	check("production desktop walker traverses the level U landing",completed and lowest>6.5)
	walker.free();full.free();await ticks(4)
	# Saved part overrides use the production adapter; verify an isolated copy.
	var copy: Node3D=load("res://commons/modular/recipe_area.tscn").instantiate()
	copy.apply_grid_config({"recipe":"boolean_s_descent_model","only_parts":["ContinuousPassage"],"parts":{"ContinuousPassage":{"position":[1,.8,2],"rotation":[0,90,0]}}});host.add_child(copy)
	check("continuous passage can be copied, moved and rotated independently",copy.part_defaults.size()==1 and copy.get_node("ContinuousPassage").position.is_equal_approx(Vector3(1,.8,2)) and absf(copy.get_node("ContinuousPassage").rotation_degrees.y-90)<.001)
	await copy.prepare_editor_preview()
	copy.position=Vector3(40,-12,16);copy.rotation.y=deg_to_rad(35);await ticks(4)
	var copied_source: Node3D=copy.get_node("ContinuousPassage/Source")
	var centre: Vector3=copied_source.to_global(Vector3(1,0,0))
	var support: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(centre+Vector3.UP*.01,centre-Vector3.UP*.05,1))
	check("moved and rotated negative-floor copy retains its Boolean collision",not support.is_empty() and copy.is_ancestor_of(support.collider))
	copy.free()
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=45;camera.near=.02;host.add_child(camera)
	await shot("01-xray-passage",Vector3(2.4,2.7,3.3),Vector3(0,1.3,0))
	await shot("02-connected-bore",Vector3(-.2,1.65,3.5),Vector3(0,1.3,0))
	await shot("03-boolean-landing",Vector3(1.4,2,1.5),Vector3(.2,1.25,0))
	artifact.get_node("ContinuousPassage/Source").set_xray(false)
	await shot("04-solid-shell",Vector3(2.4,2.7,3.3),Vector3(0,1.3,0))
	var fill:=OmniLight3D.new();fill.light_energy=.35;fill.omni_range=4;host.add_child(fill);fill.global_position=artifact.to_global(Vector3(-1.2,2.3,.4))
	camera.fov=40
	await shot("05-open-entry",Vector3(-1.05,2.2,.23),Vector3(.15,1.75,-.14))
	fill.free();artifact.get_node("ContinuousPassage/Source").set_xray(true)
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"metrics":metrics,"scope":"Saved Boolean Tunnel 1:10 model; actual CSG subtraction result and independent member overrides. Isolated unscaled Jolt ball drops on both slides, production walker on level landing, capsule clearance. Full tower descent and physical headset are not tested."},"  "))
	print("BOOLEAN_S_DONE ",JSON.stringify({"failed":failed}));building.free();host.free();quit(0 if failed.is_empty() else 1)
