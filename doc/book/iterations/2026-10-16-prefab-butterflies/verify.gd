extends SceneTree
const Flock=preload("res://commons/artifacts/prefab_disorder/bounded_butterflies.gd")
var checks:=[]
var failures:=[]
func _initialize() -> void: run.call_deferred()
func check(name: String, okay: bool) -> void:
	checks.append({"name":name,"passed":okay})
	if not okay: failures.append(name)
	print("[butterfly] ","PASS " if okay else "FAIL ",name)

func run() -> void:
	var bench=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate()
	bench.butterfly_count=16
	root.add_child(bench)
	bench.position=Vector3(13.5,0,3.5);bench.rotation.y=PI
	var flock: Node3D=bench.butterflies
	flock.set_physics_process(false)
	check("sixteen butterflies belong to the table",flock.birds.size()==16 and flock.get_parent()==bench)
	check("no source cameras or wander scripts survive",flock.find_children("*","Camera3D",true,false).is_empty() and flock.birds.all(func(b):return b.node.get_script()==null))
	var record: Dictionary=bench.capture()
	var replica=Flock.new();root.add_child(replica);replica.set_physics_process(false)
	check("local flock seed is reproducible",range(16).all(func(i):return flock.birds[i].node.position==replica.birds[i].node.position))
	var baseline: Vector3=flock.birds[0].node.position
	var body_inside:=true
	var wing_inside:=true
	var upright:=true
	for step in 1200:
		flock.advance(0.1)
		for bird in flock.birds:
			var body: Node3D=bird.node
			body_inside=body_inside and flock.center_bounds().grow(0.0001).has_point(body.position)
			upright=upright and body.basis.y.normalized().dot(Vector3.UP)>0.94
			if step%10==0:
				for wing: MeshInstance3D in [bird.left,bird.right]:
					var local: Transform3D=flock.global_transform.affine_inverse()*wing.global_transform
					for vertex in wing.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
						wing_inside=wing_inside and Flock.HABITAT.grow(0.0001).has_point(local*vertex)
	check("all bodies stay inside for two simulated minutes",body_inside)
	check("wing tips also stay inside while turning and flapping",wing_inside)
	check("bodies remain upright through every turn",upright)
	check("flock actually moves",flock.birds[0].node.position.distance_to(baseline)>0.05)
	flock.advance(5)
	check("long frame cannot escape enclosure",flock.birds.all(func(b):return flock.center_bounds().grow(0.0001).has_point(b.node.position)))
	check("flight never consumes hybrid draws or changes its record",bench.capture()==record)
	var local_before: Vector3=flock.birds[0].node.position
	bench.position+=Vector3(8,0,-6);bench.rotation.y=0.65
	check("habitat moves and turns with the installation",bench.to_local(flock.birds[0].node.global_position).is_equal_approx(local_before))
	bench.show_gallery(true)
	check("gallery pauses and hides the flock",not flock.visible and not flock.can_process())
	bench.show_gallery(false)
	check("closing gallery restores same flock",flock.visible and flock.can_process() and flock.birds.size()==16)
	bench.act("SEED +1");bench.set_disorder(1)
	check("hybrid seed still makes new targets",bench.experiment_seed==436 and bench.hybrids!=record.hybrids)
	check("existing saved arrangement still restores",bench.restore(record) and bench.capture()==record)
	bench.apply_grid_config({"butterflies":"16"})
	check("reapplying config does not duplicate flock",bench.butterflies==flock)
	bench.apply_grid_config({"butterflies":"0"})
	check("zero explicitly disables local flock",bench.butterflies==null)
	# The general swarm used local points as world look_at targets. Its small
	# correction must keep head direction and scale independent of placement.
	var old=load("res://algorithms/randomness/proceduralrandomness/movementbased/scenes/randombutterflies/butterfly.tscn").instantiate()
	root.add_child(old);old.position=Vector3(18,2,9);old.rotation.y=PI
	var brain: Node3D=old.get_node("butterfly")
	brain.set_process(false);brain.set_physics_process(false)
	brain.point_in_direction(Vector3(1,0.1,-0.4))
	check("shared butterfly faces its local travel direction",(-brain.basis.z).normalized().dot(Vector3(1,0.1,-0.4).normalized())>0.999)
	check("shared turn preserves artwork scale and upward body",brain.scale.is_equal_approx(Vector3.ONE*0.4) and brain.basis.y.normalized().dot(Vector3.UP)>0.99)
	var file=FileAccess.open("res://doc/book/iterations/2026-10-16-prefab-butterflies/checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));file.close()
	# Finish deferred visibility, physics removal and entropy discovery before exit.
	await process_frame
	await physics_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
