extends SceneTree
## Real creature, native Jolt collision, Void octapod, health and both
## actual projectile classes. The stationary visitor is a test fixture, not XR.
const Spider := preload("res://commons/void/spider.tscn")
const Behavior := preload("res://commons/void/spider.gd")
const Health := preload("res://commons/void/health.gd")
const DesktopShot := preload("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd")
const VRShot := preload("res://commons/artifacts/ignorance_gallery/form_projectile.gd")
class Visit extends Node3D:
	var body: CharacterBody3D
	var ready_for_play := true
	var returning := false
var visit: Visit
var health: Node
var spider: CharacterBody3D
var checks: Array[Dictionary] = []
var out := "user://"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, okay: bool) -> void:
	checks.append({"name":label,"passed":okay})
	print("[spider] ","PASS " if okay else "FAIL ",label)

func frames(count: int) -> void:
	for i in count: await physics_frame
	await process_frame

func fresh(at := Vector3(0,-42,0.035)) -> void:
	if is_instance_valid(spider):
		spider.queue_free()
		await frames(3)
	health.suspended=false
	health.reset()
	visit.body.position=Vector3(7,-42,0)
	spider=Spider.instantiate()
	spider.position=at
	visit.add_child(spider)
	await frames(15)

func wall(at: Vector3, size: Vector3) -> StaticBody3D:
	var node:=StaticBody3D.new()
	node.position=at
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=size
	shape.shape=box
	node.add_child(shape)
	visit.add_child(node)
	return node

func fire(script: Script) -> void:
	var shot: RigidBody3D=script.new()
	if script==VRShot:
		# FirstCatalystAbility copies its held sphere into this projectile.
		shot.form=SphereMesh.new()
		shot.form.radius=.1;shot.form.height=.2
	shot.position=spider.global_position+Vector3(3,1,0)
	shot.direction=Vector3.LEFT
	visit.add_child(shot)
	await frames(30)

func run() -> void:
	visit=Visit.new()
	root.add_child(visit)
	health=Health.new()
	visit.add_child(health)
	visit.body=CharacterBody3D.new()
	var shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=.3;capsule.height=1.7
	shape.shape=capsule;shape.position.y=.85
	visit.body.add_child(shape)
	visit.add_child(visit.body)
	wall(Vector3(0,-42.2,0),Vector3(10,.4,10))
	await fresh()
	check("eight mechanical legs",spider.gait.find_children("LegMesh_*","MeshInstance3D",true,false).size()==8)
	check("human-scale shoulder at 1.35 m",is_equal_approx(spider.gait.position.y,1.35))
	check("feet plant on this floor, not world zero",absf(spider.gait._ground()+42)<.05 and absf(spider.gait._feet[0].global_position.y+42)<.05)
	await frames(120)
	check("distant player leaves spider still and harmless",spider.state==Behavior.State.REST and health.health==100 and spider.global_position.distance_to(spider.home)<.1)
	visit.body.position=Vector3(2.8,-42,0)
	await frames(20)
	check("proximity gives a warning before rushing",spider.state==Behavior.State.WARNING and health.health==100)
	var fastest:=0.0
	for i in 90:
		await frames(1)
		fastest=maxf(fastest,spider.velocity.slide(Vector3.UP).length())
		if spider.attacks>0: break
	check("rush reaches 4.5 m/s",is_equal_approx(fastest,4.5))
	check("first attack costs exactly 20 health",spider.attacks==1 and health.health==80 and spider.state==Behavior.State.COOLDOWN)
	await frames(120)
	check("two seconds of contact cannot repeat a bite",spider.attacks==1 and health.health==80)
	await frames(105)
	check("another bite requires cooldown and a fresh warning",spider.attacks==2 and health.health==60)
	visit.body.position=Vector3(8,-42,0)
	await frames(360)
	check("leaving ends pursuit and returns creature home",spider.state==Behavior.State.REST and spider.global_position.distance_to(spider.home)<.18 and spider.attacks==2)
	visit.body.position=Vector3(.8,-36,0)
	await frames(120)
	check("player on another storey cannot trigger attack",spider.attacks==2 and health.health==60)
	await fresh()
	var barrier:=wall(Vector3(1.4,-40.8,0),Vector3(.2,2.4,3))
	visit.body.position=Vector3(2.5,-42,0)
	await frames(180)
	check("a wall blocks proximity attacks",spider.attacks==0 and health.health==100)
	barrier.queue_free();await frames(3)
	for script in [DesktopShot,VRShot]:
		await fresh()
		await fire(script)
		check("real projectile collision calms: "+script.resource_path.get_file(),spider.state==Behavior.State.CALM)
	health.set_health(65)
	visit.body.position=spider.global_position+Vector3(1.3,0,0)
	await frames(115)
	check("health source waits for its pulse",health.health==65)
	await frames(10)
	check("calm source supplies ten health",health.health==75 and spider.healing_pulses==1 and spider.attacks==0)
	await frames(360)
	check("healing caps at 100 and never attacks",health.health==100 and spider.attacks==0)
	health.set_health(80)
	visit.body.position=Vector3(7,-42,0)
	await frames(150)
	check("source does not heal remotely",health.health==80)
	visit.body.position=Vector3(1.3,-36,0)
	await frames(150)
	check("source cannot heal through another floor",health.health==80)
	barrier=wall(Vector3(.65,-40.8,0),Vector3(.2,2.4,3))
	visit.body.position=Vector3(1.4,-42,0)
	await frames(150)
	check("source cannot heal through a wall",health.health==80)
	barrier.queue_free();await frames(3)
	health.set_health(0);health.suspended=true
	await frames(150)
	check("source cannot revive a dead/recovering player",health.health==0)
	health.reset();health.suspended=false
	await frames(3)
	check("calm state survives player recovery",spider.state==Behavior.State.CALM)
	spider.process_mode=Node.PROCESS_MODE_DISABLED
	await frames(5)
	spider.process_mode=Node.PROCESS_MODE_INHERIT
	check("stream sleep keeps calm state",spider.state==Behavior.State.CALM)
	await fresh()
	visit.body.position=Vector3(1,-42,0)
	await frames(60)
	check("aggressive encounter reaches its bite cooldown",spider.attacks==1 and spider.state==Behavior.State.COOLDOWN)
	await fire(DesktopShot)
	await frames(240)
	check("catalyst interrupts aggression permanently, including queued attacks",spider.state==Behavior.State.CALM and spider.attacks==1 and health.health==100)
	await fresh(Vector3(3.8,-42,0))
	visit.body.position=Vector3(6,-42,0)
	await frames(180)
	check("rush stops before an unsupported shaft edge",spider.global_position.x<4.4 and absf(spider.global_position.y+42)<.1 and spider.attacks==0)
	await fresh()
	health.set_health(10)
	visit.body.position=Vector3(1,-42,0)
	await frames(90)
	check("lethal bite depletes health without going negative",health.health==0 and spider.attacks==1)
	await frames(180)
	check("depleted health prevents further attacks",spider.attacks==1)
	var passed:=checks.all(func(c):return c.passed)
	FileAccess.open(out.path_join("spider-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Native Jolt, real octapod rig, actual catalyst projectile collisions, real Void health; stationary player fixture."},"\t"))
	visit.queue_free();await frames(10)
	quit(0 if passed else 1)
