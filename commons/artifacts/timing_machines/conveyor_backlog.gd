extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Actual rigid boxes carried on a moving-surface collider into a timed receiver.
## The finite pool is shown explicitly: a capacity hold is not a disappearing box.
const LIMIT := 48
const FEED_INTERVAL := 1.2
const BELT_SPEED := 0.9
var boxes: Array[RigidBody3D] = []
var elapsed := 0.0
var feed_clock := 0.0
var receive_clock := 0.0
var receiver_interval := 1.2
var admitted := 0
var collected := 0
var mode := "MATCHED"
var conveyor: StaticBody3D
var bars: Array[MeshInstance3D] = []
var rule: Label3D
var port: MeshInstance3D
var flash := 0.0
func _ready() -> void:
	var belt=preload("res://commons/artifacts/conveyor_belt/conveyor_belt.tscn").instantiate()
	belt.set_meta("config_belt_length",6.0);belt.set_meta("config_belt_width",1.0);belt.set_meta("config_belt_height",1.2);add_child(belt)
	conveyor=StaticBody3D.new();conveyor.name="MovingSurface";conveyor.position=Vector3(0,1.12,0);add_child(conveyor)
	var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(6,0.16,1);c.shape=shape;conveyor.add_child(c)
	var friction=PhysicsMaterial.new();friction.friction=1.0;conveyor.physics_material_override=friction
	var steel=material("29404b")
	for z in [-0.61,0.61]:box(Vector3(0,1.33,z),Vector3(6.1,0.35,0.16),steel,true)
	box(Vector3(3.55,0.30,0),Vector3(1.35,0.3,1.25),steel,true)
	box(Vector3(4.2,0.95,0),Vector3(0.16,1.6,1.25),steel,true)
	var glass=material("8cc9d9");glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color.a=0.22
	for z in [-0.6,0.6]:
		box(Vector3(3.55,0.95,z),Vector3(1.35,1.6,0.12),glass,true)
		box(Vector3(3.55,1.77,z),Vector3(1.35,0.06,0.13),steel)
	port=box(Vector3(4.1,1.05,0),Vector3(0.045,0.85,0.9),material("66eac3",true))
	for i in 12:bars.append(box(Vector3(-3+i*0.5,1.208,0),Vector3(0.07,0.01,0.97),material("87939c")))
	console(["BACK UP","RECOVER","RESET","RULE"],2.6,"THE RECEIVER")
	rule=label("",Vector3(0,2.5,-0.75),0.0015);rule.hide()
	var light=OmniLight3D.new();light.position=Vector3(1,3,1);light.omni_range=9;light.light_energy=1.5;add_child(light)
	refresh()
func _physics_process(delta: float) -> void:
	elapsed+=delta;feed_clock+=delta;receive_clock+=delta;flash=maxf(0.0,flash-delta)
	conveyor.constant_linear_velocity=global_basis.x.normalized()*BELT_SPEED
	# A full tray or occupied inlet holds admission; no existing body is discarded.
	if feed_clock>=FEED_INTERVAL:
		feed_clock=fmod(feed_clock,FEED_INTERVAL)
		if boxes.size()<LIMIT and inlet_clear():spawn_box()
	if receive_clock>=receiver_interval:
		receive_clock=fmod(receive_clock,receiver_interval);collect_one()
	for i in bars.size():bars[i].position.x=-3+fposmod(i*0.5+elapsed*BELT_SPEED,6.0)
	port.scale.y=1.0+flash*0.3
	refresh()
func inlet_clear() -> bool:
	for b in boxes:
		var p=to_local(b.global_position)
		if p.distance_to(Vector3(-2.65,1.65,0))<0.65:return false
	return true
func spawn_box() -> RigidBody3D:
	var b=RigidBody3D.new();b.name="Parcel_%d" % admitted;b.mass=0.5;b.continuous_cd=true;b.can_sleep=false;b.collision_layer=1;b.collision_mask=1
	var pm=PhysicsMaterial.new();pm.friction=0.75;pm.bounce=0.05;b.physics_material_override=pm
	var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=Vector3.ONE*0.44;c.shape=s;b.add_child(c)
	box(Vector3.ZERO,Vector3.ONE*0.44,material(["ecad67","ed80a6","87d0cd"][admitted%3]),false,b)
	box(Vector3(0,0.223,0),Vector3(0.09,0.008,0.445),material("f7dfb1"),false,b)
	add_child(b);b.global_position=to_global(Vector3(-2.65,1.77,0));boxes.append(b);admitted+=1;return b
func collect_one() -> bool:
	# Only the oldest parcel that has physically reached the collection tray.
	for b in boxes:
		var at=to_local(b.global_position)
		if at.x>=2.9 and at.y<1.12:
			boxes.erase(b);b.queue_free();collected+=1;flash=0.3;return true
	return false
func refresh() -> void:
	readout.text="%s / admitted %d / collected %d / here %d\nfeed %.2f s / collect %.2f s%s" % [mode,admitted,collected,boxes.size(),FEED_INTERVAL,receiver_interval," / FEED HELD: 48" if boxes.size()>=LIMIT else (" / INLET HELD" if not inlet_clear() else "")]
	rule.text="here = admitted - collected\nEach receiver pulse collects at most one arrived box."
func act(id: String) -> void:
	match id:
		"BACK UP":mode="BACKLOG";receiver_interval=3.0;receive_clock=0
		"RECOVER":mode="RECOVERING";receiver_interval=0.6;receive_clock=0
		"RESET":
			for b in boxes:b.queue_free()
			boxes.clear();admitted=0;collected=0;feed_clock=0;receive_clock=0;mode="MATCHED";receiver_interval=1.2
		"RULE":rule.visible=not rule.visible
	refresh()
