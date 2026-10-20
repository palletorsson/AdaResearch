extends SceneTree
var checks:Array=[]
var failures:Array=[]
class TestGrabber extends Node3D:
	var picked_up_ranged:=false
	var held:Node3D
	func drop_object()->void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO);held=null
func _initialize()->void:run.call_deferred()
func check(label:String,ok:bool)->void:
	checks.append({"name":label,"passed":ok});print("LENS ","PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func state(f:Node)->Array:
	var result:Array=[]
	for b in f._boids:result.append([b.position,b.velocity])
	return result
func run()->void:
	var parent:=Node3D.new();root.add_child(parent);parent.position=Vector3(12,3,-7);parent.rotation.y=.7
	var h=load("res://commons/artifacts/boids_neighbour_lens/boids_neighbour_lens.tscn").instantiate();parent.add_child(h);h.set_process(false)
	var plain=load("res://commons/artifacts/flocking_controls/flocking_controls.tscn").instantiate();root.add_child(plain);plain.set_process(false)
	await process_frame
	var f=h.flock
	check("The unchanged original scene owns all thirty agents",f._boids.size()==30 and f.get_script()==plain.get_script())
	check("Only the wrapper schedules the original integration",not f.is_processing())
	var initial:=state(f)
	for i in range(30):plain._boids[i].position=f._boids[i].position;plain._boids[i].velocity=f._boids[i].velocity
	for i in range(300):
		var dt:=.013 if i%2==0 else .021
		h._process(dt);plain._process(dt)
	check("Observer leaves all positions and velocities identical over 300 variable steps",state(f)==state(plain))
	var saved:=state(f)
	for i in range(30):f._boids[i].position=Vector3(8,8,8);f._boids[i].velocity=Vector3.ZERO
	f._boids[0].position=Vector3.ZERO;f._boids[0].velocity=Vector3(0,.1,0)
	f._boids[1].position=Vector3(.1,0,0);f._boids[1].velocity=Vector3(.1,0,0)
	f._boids[2].position=Vector3(.3,0,0)
	f._boids[3].position=Vector3.ZERO
	f.perception_radius=.2
	var read:Dictionary=h.sample()
	check("Self, overlap and out-of-range bodies are excluded",read.neighbours==[1])
	check("Separation uses the original weighted inverse-distance vector",read.parts[0].distance_to(Vector3(-15,0,0))<.0001)
	check("Alignment compares mean velocity with current velocity",read.parts[1].distance_to(Vector3(.1,-.1,0))<.0001)
	check("Cohesion points to the local mean position",read.parts[2].distance_to(Vector3(.15,0,0))<.0001)
	check("White sum adds the three weighted requests",read.sum==read.parts[0]+read.parts[1]+read.parts[2])
	var before:=state(f);h.refresh();h.refresh()
	check("Preview never edits positions or velocities",state(f)==before)
	f._update_boids(.01)
	check("Preview matches the actual next body-zero forces",read.parts[0]==f._boids[0].f_sep and read.parts[1]==f._boids[0].f_align and read.parts[2]==f._boids[0].f_coh)
	for i in range(30):f._boids[i].position=saved[i][0];f._boids[i].velocity=saved[i][1]
	h.toggle_play();var stopped:=state(f);h._process(.5)
	check("Pause keeps every position and velocity",not h.playing and state(f)==stopped)
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.action();check("Unheld trigger cannot toggle playback",not h.playing)
	h.point.on_desktop_grab(pointer);h.hand_input(.01)
	h.point.global_position=h.to_global(h.HOME+Vector3(.19,0,0));h.hand_input(.01);h.refresh()
	check("Hand movement adjusts radius in a rotated and translated host",is_equal_approx(f.perception_radius,.39))
	check("Hand preview leaves paused agent state intact",state(f)==stopped)
	check("Links count exactly the reported neighbours",h.links.multimesh.visible_instance_count==h.reading.neighbours.size())
	var links_ok:=true
	for j in h.reading.neighbours.size():
		var t:Transform3D=h.links.multimesh.get_instance_transform(j)
		links_ok=links_ok and (t.origin-t.basis.y*.5).distance_to(f._boids[0].position)<.0001 and (t.origin+t.basis.y*.5).distance_to(f._boids[h.reading.neighbours[j]].position)<.0001
	check("Every visible link joins the witness to a selected neighbour",links_ok)
	h.point.global_position=h.to_global(h.HOME+Vector3(20,0,0));h.hand_input(.01)
	check("Radius is bounded at the original maximum",f.perception_radius==.5)
	h.point.global_position=h.to_global(h.HOME-Vector3(20,0,0));h.hand_input(.01)
	check("Radius is bounded at the original minimum",f.perception_radius==.05)
	h.point.on_desktop_drop(pointer);h.hand_input(1.6)
	check("Drop returns the point while retaining the chosen radius",h.point.position.distance_to(h.HOME)<.001 and f.perception_radius==.05)
	h.point.on_desktop_grab(pointer);h.hand_input(.01)
	check("A second pickup has no radius jump",f.perception_radius==.05)
	h.point.action();check("Held trigger resumes the original simulation",h.playing)
	h.point.on_desktop_drop(pointer);h.hand_input(.01);h._process(.02)
	check("The same agents move after resuming",state(f)!=stopped and f._boids.size()==30)
	h.pause_button.pressed.emit();check("Nearby button pauses",not h.playing)
	f._radius_slider.set_normalized_value(.5);f._radius_slider.slider_moved.emit(Vector3.ZERO);h.refresh()
	check("Original radius slider remains active",is_equal_approx(f.perception_radius,.275))
	f._sep_slider.set_normalized_value(.4);f._sep_slider.slider_moved.emit(Vector3.ZERO)
	check("Original weighting slider remains active",is_equal_approx(f.separation_weight,2))
	for i in range(1,30):f._boids[i].position=Vector3(8,8,8)
	f._boids[0].position=Vector3.ZERO;h.refresh()
	check("Empty neighbourhood gives no preview request or links",h.reading.sum==Vector3.ZERO and h.reading.parts==[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO] and h.links.multimesh.visible_instance_count==0)
	check("Empty requests hide all arrow shafts and tips",h.shafts.all(func(s):return not s.visible) and h.tips.all(func(t):return not t.visible))
	f.perception_radius=.2;h.hand_input(.01)
	var hand:=TestGrabber.new();root.add_child(hand);hand.held=h.point;hand.global_transform=h.point.global_transform;h.point.pick_up(hand)
	for i in range(5):await physics_frame;await process_frame;h.hand_input(.02)
	check("XR Tools near pickup is recognised",h.point.is_picked_up() and h.point.held())
	hand.global_position+=h.global_basis*Vector3(.12,0,0)
	for i in range(8):await physics_frame;await process_frame;h.hand_input(.02)
	check("Synthetic near-grab movement changes radius",absf(f.perception_radius-.32)<.01)
	hand.drop_object();h.hand_input(1.6)
	check("Near release retains radius and returns point",not h.point.held() and absf(f.perception_radius-.32)<.01 and h.point.position.distance_to(h.HOME)<.01)
	hand.queue_free()
	FileAccess.open("res://ada_run/boids_lens_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()},"  "))
	parent.queue_free();plain.queue_free();pointer.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
