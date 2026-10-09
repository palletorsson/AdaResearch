extends Node3D
var checks := 0
var failures: Array[String] = []
class TestHand extends Node3D:
	var picked_up_ranged := false
func _ready() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[line-animation] ","PASS " if ok else "FAIL ",message)
func run() -> void:
	var scene = load("res://commons/artifacts/line_space_workshop/line_space_workshop.tscn")
	var work = scene.instantiate()
	add_child(work)
	work.set_process(false)
	await get_tree().create_timer(0.1).timeout
	check(work.buttons.is_empty() and work.find_children("*","StaticBody3D",true,false).is_empty(),"No buttons or control plinth colliders")
	check(work.captions.size()==4,"Only four count labels")
	var first: Transform3D = work.rods[0][0].transform
	var id: int = work.rods[0][0].get_instance_id()
	work.advance(5.9)
	check(work.rods[0][0].transform.is_equal_approx(first),"Six-second readable pause before moving")
	work.advance(0.11)
	check(work.rods[0][0].transform.is_equal_approx(first),"Transition begins without jumping")
	work.advance(2.5)
	check(not work.rods[0][0].transform.is_equal_approx(first),"Mid-transition changes the arrangement")
	var fold_closed := true
	for i in 4:
		fold_closed = fold_closed and work.rods[2][i].endpoints()[1].distance_to(work.rods[2][(i+1)%4].endpoints()[0]) < 0.00001
	check(fold_closed,"Four-edge fold keeps every corner joined mid-animation")
	check(absf(work.rods[2][2].endpoints()[1].z-work.rods[2][0].endpoints()[0].z)>0.01,"Closed fold has acquired depth")
	work.advance(2.5)
	check(work.modes[0]==1,"Automatic cycle arrives at the next arrangement")
	check(work.rods[0][0].get_instance_id()==id,"Existing grabbable rods persist through transitions")
	var rod = work.rods[0][0]
	var hand := TestHand.new()
	add_child(hand)
	hand.global_position = rod.global_position
	rod.pick_up(hand)
	work.advance(0.1)
	var other: Transform3D = work.rods[0][1].transform
	work.advance(20.0)
	check(rod.is_picked_up() and work.rods[0][1].transform.is_equal_approx(other),"Grabbing pauses the entire station")
	hand.position += Vector3(0.17,0.13,0.25)
	hand.rotation_degrees.z = 30
	for i in 10: await get_tree().physics_frame
	rod.let_go(hand,Vector3.ONE,Vector3.ONE)
	var released: Transform3D = rod.transform
	work.advance(0.1)
	work.advance(11.0)
	check(rod.transform.is_equal_approx(released),"Released arrangement is retained during twelve-second grace period")
	work.advance(1.0)
	check(rod.transform.is_equal_approx(released),"Recovery starts from the hand's position without snapping")
	work.advance(2.5)
	check(not rod.transform.is_equal_approx(released),"Recovery glides back toward the paused arrangement")
	work.advance(2.5)
	check(rod.freeze and rod.collision_layer==4,"Released rod remains frozen and grabbable")
	work.begin_motion(3,2,true)
	work.apply_motion(3,1.0)
	work.modes[3]=2
	work.begin_motion(3,3,false)
	work.apply_motion(3,0.5)
	check(is_equal_approx(work.rods[3][8].presence,0.5),"Extra cube edges appear gradually")
	check(not work.rods[3][8].enabled and work.rods[3][8].collision_layer==0,"Partly visible new edges cannot steal a grab")
	work.apply_motion(3,1.0)
	check(work.rods[3][8].enabled and work.rods[3][8].collision_layer==4,"Fully visible new edges become grabbable")
	work.free()
	work=scene.instantiate()
	add_child(work)
	work.set_process(false)
	var lengths_ok := true
	var seen: Array = [{},{},{},{}]
	for step in 500:
		work.advance(0.2)
		for bay in 4:
			seen[bay][work.modes[bay]]=true
			for r in work.rods[bay]:
				lengths_ok = lengths_ok and absf(r.endpoints()[0].distance_to(r.endpoints()[1])-r.span)<0.00001
	check(lengths_ok,"All rod lengths survive 500 samples of automatic movement")
	for bay in 4:
		check(seen[bay].size()==work.PRESETS[bay].size(),"Station %d reaches every authored arrangement" % bay)
	var out:=FileAccess.open("res://ada_run/line-workshop-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_verified":false},"  "))
	out.close()
	get_tree().quit(0 if failures.is_empty() else 1)
