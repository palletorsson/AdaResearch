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
		if floor_contact(ball,target):reached=true;break
		if ball.global_position.y < -2:break
	metrics[target+"_ball_end"]=xyz(full.to_local(ball.global_position))
	check("Jolt ball descends to "+target,reached)
	ball.free();await ticks(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();host.name="SDescentStudy";root.add_child(host);current_scene=host
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("b6b3ba")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e5dce4");env.ambient_light_energy=.7
	environment.environment=env;host.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/s-study"].get_node("Artifact")
	check("registered saved model loads with 25 independent members",artifact.part_defaults.size()==25)
	var entry: Node3D=artifact.get_node("EntryDeck");var exit: Node3D=artifact.get_node("ExitDeck")
	check("1:10 model represents a twelve-metre / two-storey descent",absf(entry.position.y-exit.position.y-1.2)<.0001)
	metrics.model_drop=entry.position.y-exit.position.y;metrics.canonical_drop=12;metrics.parts=artifact.part_defaults
	# Build an isolated full-size route outside the building. It is a geometry
	# fixture, not an installed full-size floor or a physical-headset playtest.
	var full: Node3D=load("res://commons/modular/recipe_area.tscn").instantiate()
	full.apply_grid_config({"recipe":"s_descent_model","bindings":{"model_scale":1,"yaw":0,"cutaway_alpha":.12}})
	full.position=Vector3(60,0,0);host.add_child(full)
	for member in ["StudyStand","LevelGuide0","LevelGuide6","LevelGuide12"]:full.get_node(member).free()
	await ticks(8)
	var exclude: Array[RID]=[]
	for member in ["EntryDeck","UpperSlide","TurnLanding","LowerSlide","ExitDeck"]:
		for body in full.get_node(member).find_children("*","StaticBody3D",true,false):exclude.append(body.get_rid())
	var clear:=true;var rays:=true;var count:=0
	var capsule:=CapsuleShape3D.new();capsule.radius=.3;capsule.height=1.8
	for member in ["UpperSlide","TurnLanding","LowerSlide"]:
		var source: Node3D=full.get_node(member).get_node("Source")
		var path: Array=source.get_meta("sweep_path")
		var origin: Vector3=Vector3(path[0][0],path[0][1],path[0][2])
		for point in path:
			var local: Vector3=Vector3(point[0],point[1],point[2])-origin
			var foot: Vector3=source.to_global(local)
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform.origin=foot+Vector3.UP*1.35;query.exclude=exclude;query.collision_mask=1
			if not host.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():clear=false
			var ray:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.05,foot-Vector3.UP*.25,1)
			if host.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():rays=false
			count+=1
	check("continuous collision beneath all %d centreline samples"%count,rays)
	check("upright 1.8m capsule clears walls and roof along the route",clear)
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
	copy.apply_grid_config({"recipe":"s_descent_model","only_parts":["TurnLanding"],"parts":{"TurnLanding":{"position":[1,.8,2],"rotation":[0,90,0]}}});host.add_child(copy)
	check("landing can be copied, moved and rotated independently",copy.part_defaults.size()==1 and copy.get_node("TurnLanding").position.is_equal_approx(Vector3(1,.8,2)) and absf(copy.get_node("TurnLanding").rotation_degrees.y-90)<.001)
	copy.free()
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=45;camera.near=.02;host.add_child(camera)
	await shot("01-cutaway-model",Vector3(2.4,2.7,3.3),Vector3(0,1.3,0))
	await shot("02-two-slides",Vector3(-.2,1.65,3.5),Vector3(0,1.3,0))
	await shot("03-turning-landing",Vector3(1.4,2,1.5),Vector3(.2,1.25,0))
	await shot("04-plan",Vector3(0,3.6,.35),Vector3(0,1,0))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"metrics":metrics,"scope":"Saved 1:10 model and independent member overrides. Isolated unscaled Jolt ball drops on both slides, production walker on level landing, capsule clearance. Full tower descent and physical headset are not tested."},"  "))
	print("S_DESCENT_DONE ",JSON.stringify({"failed":failed}));building.free();host.free();quit(0 if failed.is_empty() else 1)
