extends SceneTree
## Real-scene drum motion, immutable local frames, and physical visitor approach.
## A spinning display test; not perceptual proof of a physical zoetrope illusion.
const SCENE := "res://commons/artifacts/transformation_sampling/transformation_sampling.tscn"
const SCRIPT := "res://commons/artifacts/transformation_sampling/transformation_sampling.gd"
const OUT := "res://doc/space/zoetrope-encounter-2026-09-17/test-results.json"
var checks: Array = []
var failures: Array[String] = []
var observations: Dictionary = {}
var world: Node3D
var pointer: Camera3D
var source_hash: String

func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name":title,"passed":passed,"detail":detail})
	if not passed: failures.append(title)
	print("[zoetrope-test] ","PASS " if passed else "FAIL ",title," ",str(detail) if detail != null else "")
func tick() -> void:
	await physics_frame
	await process_frame
func xyz(p: Vector3) -> Array: return [p.x,p.y,p.z]
func poses(bench: Node3D, global: bool) -> Array:
	var result: Array = []
	for station in bench.stations:
		for frame in station.frames:
			result.append(frame.global_transform if global else frame.transform)
			if not global: result.append(frame.get_parent().transform)
	return result
func same(a: Array,b: Array) -> bool:
	if a.size()!=b.size(): return false
	for i in a.size():
		if not (a[i] as Transform3D).is_equal_approx(b[i]): return false
	return true
func all_changed(a: Array,b: Array) -> bool:
	if a.size()!=b.size(): return false
	for i in a.size():
		if (a[i] as Transform3D).is_equal_approx(b[i]): return false
	return true
func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	await tick()
func new_bench(at: Vector3,yaw: float) -> Node3D:
	var bench: Node3D = load(SCENE).instantiate()
	bench.position=at
	bench.rotation.y=yaw
	bench.playing=false
	world.add_child(bench)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(24,0.2,24)
	collision.shape=shape
	collision.position=Vector3(0,-0.1,3)
	floor_body.add_child(collision)
	bench.add_child(floor_body)
	return bench
func visitor(at: Vector3) -> CharacterBody3D:
	var body:=CharacterBody3D.new()
	body.name="VisitorApproach"
	body.collision_layer=524288
	body.collision_mask=1
	body.floor_snap_length=0.12
	var collision:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new()
	shape.radius=0.22
	shape.height=1.75
	collision.shape=shape
	collision.position.y=0.875
	body.add_child(collision)
	world.add_child(body)
	body.global_position=at
	return body

func approach(bench: Node3D,station: Dictionary) -> Dictionary:
	var disc: MeshInstance3D=station.disc
	var extent:=disc.mesh.get_aabb()
	var radius:float=maxf(extent.size.x,extent.size.z)*0.5
	var center:Vector3=bench.to_local(disc.global_position)
	# Visitor feet remain at room floor; front edge is approached from negative Z.
	var end_local:=Vector3(center.x,0.01,center.z-radius-0.24)
	var start_local:=end_local-Vector3(0,0,1.3)
	var start:Vector3=bench.to_global(start_local)
	var direction:Vector3=bench.global_basis.z.normalized()
	var body:=visitor(start)
	var travel:=0.0
	var stalled:=0
	var minimum_y:=start.y
	var drift:=0.0
	var support_count:=0
	for i in 105:
		await physics_frame
		body.velocity=direction*2.0+Vector3.UP*(body.velocity.y-9.8/Engine.physics_ticks_per_second)
		body.move_and_slide()
		var next:float=(body.global_position-start).dot(direction)
		stalled=stalled+1 if next-travel<0.0005 else 0
		travel=next
		minimum_y=minf(minimum_y,body.global_position.y)
		drift=maxf(drift,absf(bench.to_local(body.global_position).x-center.x))
		if body.is_on_floor(): support_count+=1
		if travel>=1.3 or stalled>=30: break
	var result:Dictionary={"arrived":travel>=1.28,"travel_m":travel,"end_local":xyz(bench.to_local(body.global_position)),"target_local":xyz(end_local),"floor_height_error_m":absf(minimum_y-bench.global_position.y),"lateral_drift_m":drift,"supported_ticks":support_count,"disc_radius_m":radius}
	body.queue_free()
	await tick()
	return result

func encounter(bench: Node3D,label: String) -> void:
	check(label+": four rotating drums exist",bench.stations.size()==4 and bench.stations.all(func(s):return s.has("drum") and s.has("disc")))
	if bench.stations.size()!=4 or not bench.stations[0].has("drum"): return
	var top_errors: Array=[]
	var descendants:=true
	for station in bench.stations:
		var disc: MeshInstance3D=station.disc
		var bounds:=disc.mesh.get_aabb()
		var top_world:Vector3=disc.to_global(Vector3(0,bounds.end.y,0))
		top_errors.append(absf(bench.to_local(top_world).y-1.7))
		for frame in station.frames: descendants=descendants and station.drum.is_ancestor_of(frame)
	check(label+": every platform plane is exactly 1.7m above local floor",top_errors.all(func(e):return e<0.00001),top_errors)
	check(label+": all 48 frames belong to rotating drums",descendants)
	bench.seek(0.0)
	var local_before:=poses(bench,false)
	var world_before:=poses(bench,true)
	bench.seek(0.75)
	check(label+": seeking moves every frame in world space",all_changed(world_before,poses(bench,true)))
	check(label+": seeking preserves every frame and mount local pose",same(local_before,poses(bench,false)))
	bench.seek(1.5)
	var quarter_errors:Array=[]
	for station in bench.stations:
		var relative:Basis=bench.global_basis.inverse()*station.drum.global_basis
		quarter_errors.append((relative*Vector3.RIGHT-Vector3.FORWARD).length())
	check(label+": six-second drum period makes a quarter turn in 1.5 seconds",quarter_errors.all(func(e):return e<0.00001),quarter_errors)
	bench.seek(6.0)
	check(label+": six seconds returns every indexed frame to its world pose",same(world_before,poses(bench,true)))
	bench.seek(0.75)
	var play_buttons: Array=[]
	for child in bench.get_children():
		if child is Node3D and child.has_signal("pressed"):play_buttons.append(child)
	check(label+": original five controls remain wired",play_buttons.size()==5)
	if play_buttons.size()==5:
		var last_clock:float=bench.elapsed
		var last_world:=poses(bench,true)
		await press(play_buttons[3])
		await create_timer(0.32).timeout
		check(label+": real PLAY turns all drums through elapsed time",bench.playing and bench.elapsed-last_clock>0.2 and all_changed(last_world,poses(bench,true)))
		check(label+": real running drum leaves local pose archive unchanged",same(local_before,poses(bench,false)))
		await press(play_buttons[3])
		last_clock=bench.elapsed
		last_world=poses(bench,true)
		await create_timer(0.16).timeout
		check(label+": real PAUSE holds clock and whole drum",not bench.playing and bench.elapsed==last_clock and same(last_world,poses(bench,true)))
		await press(play_buttons[4])
		check(label+": RESET restores original drum orientation without resuming",bench.elapsed==0.0 and not bench.playing and same(world_before,poses(bench,true)))
	var walk_results:Array=[]
	for station in bench.stations:
		var result:Dictionary=await approach(bench,station)
		result["mode"]=station.mode
		walk_results.append(result)
		check(label+": visitor can walk up to "+station.mode+" platform rim",result.arrived and result.lateral_drift_m<0.015 and result.floor_height_error_m<0.015 and result.supported_ticks>10,result)
	observations[label]={"plane_height_errors":top_errors,"approaches":walk_results}

func run() -> void:
	source_hash=FileAccess.get_sha256(SCRIPT)
	world=Node3D.new()
	root.add_child(world)
	current_scene=world
	pointer=Camera3D.new()
	world.add_child(pointer)
	var bench:=new_bench(Vector3.ZERO,0.0)
	for i in 5:await tick()
	await encounter(bench,"origin")
	bench.queue_free()
	for i in 3:await tick()
	bench=new_bench(Vector3(17,2.3,-11),PI)
	for i in 3:await tick()
	await encounter(bench,"translated_yaw180")
	var output:=FileAccess.open(OUT,FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"source_sha256":source_hash,"source_sha256_at_finish":FileAccess.get_sha256(SCRIPT),"limits":["Standalone real artifact on a supplied flat floor; this does not prove a complete museum route.","Real CharacterBody capsule and pointer-button wiring; no headset comfort or tracked-hand reach test.","Local immutable poses moving through world space prove spinning geometry, not perceptual fusion or a strobe illusion."]},"\t"))
	output.close()
	print("[zoetrope-test] RESULT ",checks.size()," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
