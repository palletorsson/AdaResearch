extends Node3D
## Scripted, text-anchored rehearsal through the same pointer API as desktop/VR rays.
## This is not an autonomous learner, physics-hand test or evidence of comprehension.
signal step_observed(index: int, observation: Dictionary)
signal finished(report: Dictionary)
const Hologram=preload("res://commons/ghost_students/hologram.gd")
const ObservationRig=preload("res://commons/ghost_students/observation_rig.gd")
const ThoughtStream=preload("res://commons/ghost_students/thought_stream.gd")
const HallWalk=preload("res://commons/ghost_students/hall_walk.gd")
const Store=preload("gallery_store.gd")
const TEXT_REFS=[
	{"path":"res://commons/maps/Random_Entropy/tutorial.md","role":"procedure","excerpt":"At **1**, the left objects are home again; the right parts form four hybrids."},
	{"path":"res://commons/maps/Random_Entropy/tutorial.md","role":"record/replay contract","excerpt":"The record retains the slider, raw draws, source signature, each part's hybrid membership and target transform."},
	{"path":"res://commons/maps/Random_Entropy/final.md","role":"question, not an apparatus claim","excerpt":"Each account made a difference available and left others aside."}]
const STEPS=[
	{"key":"ORIGINAL","say":"Start with the assembled objects.","source":0},
	{"slide":0.5,"say":"What survives when a whole object moves?\nWhat changes when its parts separate?","source":0},
	{"slide":1.0,"say":"The inventory stays. The relations change.","source":0},
	{"key":"SEED +1","say":"Same stage, another seed. Follow one part.","source":0},
	{"slide":0.82,"say":"Keep a form on its way to becoming something else.","source":1},
	{"key":"KEEP","say":"Keep the stage, draws and joining targets.","source":1},
	{"key":"ORIGINAL","say":"Return to the original objects.","source":1},
	{"key":"SEED +1","say":"Change the seed before trying the record.","source":1},
	{"key":"REPLAY","say":"Did the same arrangement return?\nWhat would we change next?","source":1}]
const QUESTIONS=["What makes these parts one object?","What stays together on the left and comes apart on the right?","Is the screen still a screen when its neighbours change?","Does another seed change the screen's role?","What is worth keeping before a form is complete?","What did we preserve, and what did we leave out?","Can we recover the relation after undoing it?","Will the kept form survive a change of seed?","Did the same form return? What should change next?"]
var bench: Node3D
var actor: Node3D
var caption: Label3D
var active:=false
var dispatching:=false
var auto_enabled:=true
var human_has_used:=false
var auto_attempted:=false
var speed:=1.0
var idle_time:=0.0
var phase: String="idle"
var elapsed:=0.0
var index: int=-1
var baseline: Dictionary={}
var baseline_note: String
var before: Dictionary={}
var before_hash: String
var kept: Dictionary={}
var report: Dictionary={}
var report_path: String=""
var ghost_pointer: String
var ghost_saved: String=""
var ghost_store=Store.new()
var target: Node3D
var contact:=Vector3.ZERO
var slide_from:=Vector3.ZERO
var slide_to:=Vector3.ZERO
var actor_from:=Vector3.ZERO
var hand_from:=Vector3.ZERO
var using_hand: int=0
var pressed:=false
var pointer_count:=0
var max_contact_error:=0.0
var text_refs: Array=TEXT_REFS.duplicate(true)
var observer: Node
var capture_marks: Dictionary={}
var thoughts: Node3D
var walk: Node
var baseline_witness:=false
var attention: String="controls"
var next_artifact: Node3D
var arrival_elapsed:=0.0
var gaze_target:=Vector3.ZERO
var gaze_basis:=Basis.IDENTITY
var tour_enabled:=true

func setup(host: Node3D) -> void:
	bench=host
	actor=Hologram.new();actor.name="HolographicStudent";add_child(actor);actor.position=Vector3(-0.85,0,2.02)
	observer=ObservationRig.new();observer.name="ObservationRig";add_child(observer)
	observer.setup(bench,actor,observation_context);observer.captured.connect(observation_saved)
	thoughts=ThoughtStream.new();add_child(thoughts);thoughts.setup(actor)
	walk=HallWalk.new();add_child(walk);walk.ended.connect(walk_ended)
	caption=Label3D.new();caption.font_size=30;caption.pixel_size=0.002;caption.outline_size=5
	caption.position=Vector3(0,2.65,1.7);caption.modulate=Color("a9f4f1");caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(caption)
	caption.text="GHOST STUDENT / Watch a rehearsal\nTouch any control to take over"
	# Native grabs win even before the first movement event arrives.
	bench.slider._slider.grabbed.connect(func(_joint):take_over())
	bench.slider._interaction.input_requested.connect(func(_pointer):take_over())

func watch() -> void:
	if walk.walking or walk.requested: walk.cancel("stopped by visitor")
	elif active: stop("stopped",true)
	else: start()

func start() -> bool:
	if active or bench.gallery_open: return false
	if not bench.slider._slider.grabbed_handles.is_empty(): return false
	for key in bench.buttons:
		if key!="WATCH" and bench.buttons[key].get_node("InteractableAreaButton").pressed: return false
	auto_attempted=true
	walk.cancel("new rehearsal");next_artifact=null;arrival_elapsed=0
	actor.position=Vector3(-0.85,0,2.02)
	actor.basis=Basis.IDENTITY
	observer.set_outside(Vector3(1.9,2.8,2.2),Vector3(0,1.85,1),100)
	gaze_basis=actor.head.global_basis
	baseline_witness=bench.witness.enabled
	baseline=bench.capture();baseline_note=bench.note;kept={};ghost_saved=""
	var session:="%d-%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var folder:="user://ghost-students/prefab/"+session
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	ghost_pointer=folder+"/latest.json";report_path=folder+"/rehearsal.json";ghost_store=Store.new()
	capture_marks.clear()
	report={"schema":"ghost-rehearsal/1","artifact":"prefab_disorder","evidence":"scripted native pointer rehearsal; no learner or headset evidence","started":Time.get_datetime_string_from_system(true),"baseline":baseline.duplicate(true),"text_refs":[],"steps":[],"observations":[],"status":"running"}
	for ref in text_refs:
		var text:=FileAccess.get_file_as_string(ref.path)
		var entry: Dictionary=ref.duplicate();entry.sha256=FileAccess.get_sha256(ref.path);entry.found=text.contains(ref.excerpt);report.text_refs.append(entry)
		if not entry.found:
			report.status="text needs review";caption.text="Rehearsal paused: its text has changed."
			write_report();finished.emit(report);return false
	bench.witness.enabled=true;bench.witness.refresh()
	active=true;index=-1;pointer_count=0;max_contact_error=0;next_step();return true

func take_over() -> void:
	if dispatching: return
	human_has_used=true
	walk.cancel("handed to visitor");next_artifact=null
	if active: stop("handed to visitor",false)
	caption.text="YOUR TURN\nWATCH starts another rehearsal"

func _process(delta: float) -> void:
	if bench==null: return
	if not active:
		if walk.walking or walk.requested:
			actor.visible=true;caption.hide();actor.idle(delta)
			if is_instance_valid(next_artifact): gaze(next_artifact.to_global(Vector3(0,1.4,0)),delta)
			return
		if is_instance_valid(next_artifact) and walk.receipt.get("status")=="arrived":
			actor.idle(delta);gaze(next_artifact.to_global(Vector3(0,1.4,0)),delta)
			arrival_elapsed+=delta
			if arrival_elapsed>1 and not capture_marks.has("12-next-shannon"): capture_pair("12-next-shannon")
			return
		actor.idle(delta)
		actor.visible=not bench.gallery_open and not human_has_used
		caption.visible=not bench.gallery_open
		if auto_enabled and not auto_attempted and not human_has_used and not bench.gallery_open:
			var camera:=get_viewport().get_camera_3d()
			if camera!=null:
				var here:=bench.to_local(camera.global_position)
				var toward:=bench.to_global(Vector3(0,1.2,0))-camera.global_position
				var looking: bool=(-camera.global_basis.z).dot(toward.normalized())>0.65
				if here.z>1.9 and here.z<4.2 and absf(here.x)<2.5 and looking: idle_time+=delta
				else: idle_time=0
				if idle_time>6.0: start()
		return
	actor.visible=true;caption.visible=true
	for key in bench.buttons:
		if key=="WATCH": continue
		for trigger in bench.buttons[key].get_node("InteractableAreaButton")._trigger_items:
			if not trigger in actor.hands: take_over();return
	if not is_instance_valid(target): stop("missing control",true);return
	elapsed+=delta*speed
	var step: Dictionary=STEPS[index]
	if phase=="reach":
		var t:=smoothstep(0.0,1.25,elapsed)
		var local_contact:=to_local(contact)
		var body_to:=Vector3(local_contact.x-(-0.16 if using_hand==0 else 0.16),minf(0,local_contact.y-0.82),local_contact.z+0.61)
		actor.position=actor_from.lerp(body_to,t)
		var aim:=hand_from.lerp(local_contact,t)+Vector3.UP*sin(t*PI)*0.12
		pose_hand(aim)
		if index==0 and elapsed>=0.8 and not capture_marks.has("01-before-touch"):
			capture_pair("01-before-touch");return
		if elapsed>=1.25:
			pose_hand(local_contact)
			max_contact_error=maxf(max_contact_error,actor.hands[using_hand].global_position.distance_to(contact))
			send_pointer(XRToolsPointerEvent.Type.PRESSED,contact);pressed=true;phase="operate";elapsed=0
	elif phase=="operate":
		if step.has("slide"):
			var duration:=6.0 if index==2 else 2.0
			var t:=smoothstep(0.0,duration,elapsed)
			contact=slide_from.lerp(slide_to,t);pose_hand(to_local(contact))
			send_pointer(XRToolsPointerEvent.Type.MOVED,contact)
			if index==2:
				attention="CRT screen / right";gaze(bench.witness.centre(),delta)
				for mark in [{"stage":0.625,"label":"05-follow-early"},{"stage":0.75,"label":"06-follow-middle"},{"stage":0.875,"label":"07-follow-late"}]:
					if bench.disorder>=mark.stage and not capture_marks.has(mark.label): capture_pair(mark.label)
		if elapsed>=((6.0 if index==2 else 2.0) if step.has("slide") else 0.22):
			release();observe_step();phase="observe";elapsed=0
			if not report.steps.back().passed: stop("action failed",true)
	elif phase=="observe":
		actor.position=actor.position.move_toward(Vector3(0,0,2.15),delta*speed*0.7)
		actor.idle(delta)
		var left: bool=index in [0,1] and elapsed<3.0
		attention="whole table" if left else "CRT screen / right"
		gaze(bench.witness.centre(0 if left else 1),delta)
		var label: String=""
		if index==0 and elapsed>=1.5 and elapsed<3: label="02-original-left"
		elif index==1 and elapsed>=1.5 and elapsed<3: label="03-separated-left"
		elif index==1 and elapsed>=4.5: label="04-separated-right"
		elif index==2 and elapsed>=2: label="08-first-hybrid"
		elif index==3 and elapsed>=2: label="09-another-seed"
		elif index==5 and elapsed>=2: label="10-kept"
		elif index==8 and elapsed>=2: label="11-replayed"
		if not label.is_empty() and not capture_marks.has(label): capture_pair(label)
		if elapsed>=(6.0 if index in [0,1] else 3.4) and observer.pending.is_empty() and observer.drawing.is_empty(): next_step()

func gaze(world_point: Vector3, delta: float) -> void:
	gaze_target=world_point
	var desired: Basis=actor.head.global_transform.looking_at(world_point,Vector3.UP).basis
	gaze_basis=gaze_basis.slerp(desired,minf(1.0,delta*speed*5.0))
	actor.head.global_basis=gaze_basis

func capture_pair(label: String) -> void:
	if not observer.pending.is_empty() or not observer.drawing.is_empty(): return
	capture_marks[label]=true
	observer.request_pair(report_path.get_base_dir()+"/observations",label)

func observation_context() -> Dictionary:
	return {"artifact":"prefab_disorder","artifact_state":bench.capture(),"state_hash":state_hash(),"step":index+1,"phase":phase,"action":STEPS[index].get("key","SLIDER") if index>=0 and index<STEPS.size() else "IDLE","rehearsal":report_path,"attention":attention,"gaze_target_world":ObservationRig.xyz(gaze_target),"part_witness":bench.witness.observation(observer.cameras[0]),"thought_stream":thoughts.entries,"tour":walk.receipt.duplicate(true),"evidence":"Scripted questions and source excerpts; actual head poses and native renders. No learner or headset evidence."}

func observation_saved(receipt: Dictionary) -> void:
	if report.is_empty() or receipt.get("folder","")!=report_path.get_base_dir()+"/observations": return
	report.observations.append(receipt)
	write_report()

func pose_hand(tip: Vector3) -> void:
	var tips: Array=[Vector3(-0.25,1.02,-0.20),Vector3(0.25,1.02,-0.20)]
	tips[using_hand]=actor.to_local(to_global(tip))
	actor.pose(tips,actor.to_local(contact))

func next_step() -> void:
	index+=1
	if index==STEPS.size(): stop("completed",true);return
	var step: Dictionary=STEPS[index]
	before=bench.capture();before_hash=state_hash();using_hand=0 if step.has("slide") else 1
	if step.has("slide"):
		target=bench.slider
		var driver: Node3D=bench.slider._slider
		slide_from=driver.global_position
		slide_to=driver.get_parent().to_global(Vector3(lerpf(driver.slider_limit_min,driver.slider_limit_max,step.slide),0,0))
		contact=slide_from
	else:
		target=bench.buttons[step.key].get_node("InteractableAreaButton")
		contact=target.get_node("CollisionShape3D").global_position
	actor_from=actor.position;hand_from=to_local(actor.hands[using_hand].global_position)
	caption.text="REHEARSAL %d / %d\n%s" % [index+1,STEPS.size(),step.say]
	# The floating stream replaces the fixed, apparatus-obscuring caption while active.
	caption.text=""
	thoughts.show_entries([
		{"role":"tutorial · excerpt","text":tutorial_cue(),"path":TEXT_REFS[0].path},
		{"role":"final · excerpt","text":TEXT_REFS[2].excerpt,"path":TEXT_REFS[2].path},
		{"role":"rehearsal · question","text":QUESTIONS[index]}])
	phase="reach";elapsed=0

func tutorial_cue() -> String:
	match index:
		0: return "At **0**, both tables hold the original objects."
		1: return "Mesh boundaries are modelling decisions, not atoms or physically simulated joints."
		2: return TEXT_REFS[0].excerpt
		3: return "SEED +1 produces another set of forms on the same four pads."
		4: return "Also keep an intermediate setting and compare it with a completed hybrid."
		_: return TEXT_REFS[1].excerpt

func send_pointer(kind: XRToolsPointerEvent.Type, at: Vector3) -> void:
	# Only the synchronous dispatch owns this namespace. Human callbacks always see
	# their own pointer, gallery store, selection, saved path and gallery page.
	var saved_context: Array=[bench.pointer_path,bench.saved_path,bench.gallery_selected_path,bench.gallery_store,bench.gallery.page]
	bench.pointer_path=ghost_pointer;bench.saved_path=ghost_saved;bench.gallery_selected_path=ghost_saved;bench.gallery_store=ghost_store
	dispatching=true
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(kind,actor.hands[using_hand],target,at,at))
	pointer_count+=1;ghost_saved=bench.saved_path
	dispatching=false
	bench.pointer_path=saved_context[0];bench.saved_path=saved_context[1];bench.gallery_selected_path=saved_context[2];bench.gallery_store=saved_context[3];bench.gallery.page=saved_context[4]

func release() -> void:
	if pressed and is_instance_valid(target): send_pointer(XRToolsPointerEvent.Type.RELEASED,contact)
	pressed=false

func state_hash() -> String:
	# Godot renders Transform3D in float32. JSON's decimal parsing may differ in
	# the last float64 bit; compare the actual engine precision, not its spelling.
	var state: Array=[str(bench.experiment_seed),float(PackedFloat32Array([bench.disorder])[0]),bench.sample.draws,bench.recipe_version]
	for entry in bench.hybrids:
		var pose: Array=[]
		# JSON drops negative zero. The two signs describe identical transforms.
		for n in PackedFloat32Array(entry.pose): pose.append(0.0 if n==0.0 else float(n))
		state.append([int(entry.item),entry.key,int(entry.group),pose])
	for part in bench.pieces:
		for view in part.views:
			var rendered: Array=[]
			for n in bench.Hybrid.pack(view.transform): rendered.append(0.0 if n==0.0 else float(n))
			state.append(rendered)
	return JSON.stringify(state,"",true,true).sha256_text()

func observe_step() -> void:
	var step: Dictionary=STEPS[index]
	var ok:=false
	var after:=state_hash()
	if step.has("slide"): ok=is_equal_approx(bench.disorder,step.slide) and bench.experiment_seed==int(before.seed)
	else:
		match step.key:
			"ORIGINAL": ok=is_zero_approx(bench.disorder)
			"SEED +1": ok=bench.experiment_seed!=int(before.seed) and bench.hybrids!=before.hybrids and is_equal_approx(bench.disorder,before.disorder)
			"KEEP":
				var record=Store.read_json(ghost_saved)
				ok=bench.valid_record(record) and after==before_hash
				if ok: kept={"state_hash":after,"path":ghost_saved,"record":record}
			"REPLAY": ok=not kept.is_empty() and after==kept.state_hash
	var observation:={"step":index+1,"action":step.get("key","SLIDER"),"target":step.get("slide",null),"text_ref":step.source,"question":step.say,"before":before,"after":bench.capture(),"changed":after!=before_hash,"passed":ok,"pointer_events":pointer_count,"contact_error_metres":max_contact_error}
	report.steps.append(observation);write_report();step_observed.emit(index,observation)

func stop(reason: String, restore_baseline: bool) -> void:
	if not active: return
	observer.cancel(reason)
	release();active=false;phase="idle"
	report.status=reason;report.last_state=bench.capture();report.kept=kept;report.baseline_restored=false
	if restore_baseline:
		report.baseline_restored=bench.restore(baseline);bench.note=baseline_note;bench.set_disorder(bench.disorder)
	bench.witness.enabled=baseline_witness;bench.witness.refresh()
	for ref in report.text_refs: ref.unchanged=FileAccess.get_sha256(ref.path)==ref.sha256
	report.pointer_events=pointer_count;report.contact_error_metres=max_contact_error
	report.finished=Time.get_datetime_string_from_system(true)
	write_report()
	caption.text="REHEARSAL COMPLETE / Your starting state is back\nTouch the controls. What would we try differently?" if reason=="completed" else "REHEARSAL: "+reason
	finished.emit(report)
	if reason=="completed" and tour_enabled: continue_to_next()

func continue_to_next() -> void:
	# This pilot enters the main route at the ledger; it does not reorder the hall.
	var hall: Node=bench.get_parent()
	while hall!=null and not hall.has_meta("em_map"): hall=hall.get_parent()
	next_artifact=find_next(hall) if hall!=null else null
	attention="next / Shannon ledger"
	thoughts.show_entries([
		{"role":"tutorial · excerpt","text":"A reading that stays still is evidence.","path":TEXT_REFS[0].path},
		{"role":"final · excerpt","text":"The bars keep how often; the row keeps where.","path":TEXT_REFS[2].path},
		{"role":"rehearsal · question","text":"Can a changed arrangement leave a number unchanged?"}])
	phase="walking";walk.begin(actor,next_artifact)

func find_next(node: Node) -> Node3D:
	if node==null: return null
	if node.get_script()!=null and node.get_script().resource_path.ends_with("/shannon_entropy_meter.gd"): return node
	for child in node.get_children():
		var found:=find_next(child)
		if found!=null: return found
	return null

func walk_ended(result: Dictionary) -> void:
	if not report.is_empty(): report.tour=result.duplicate(true);write_report()
	phase="arrived" if result.status=="arrived" else "idle"
	if result.status=="arrived" and is_instance_valid(next_artifact):
		caption.hide();actor.visible=true;attention="Shannon ledger / arrival"
		observer.set_outside(bench.to_local(next_artifact.to_global(Vector3(1.5,3.0,3.3))),bench.to_local(next_artifact.to_global(Vector3(0,1.85,1.4))),90)
	else:
		caption.text="REHEARSAL COMPLETE\n"+str(result.status)

func write_report() -> void:
	var file:=FileAccess.open(report_path,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	else: push_warning("Ghost rehearsal receipt could not be written: "+report_path)

func _exit_tree() -> void:
	if active: stop("scene closed",false)
	if is_instance_valid(walk): walk.cancel("scene closed")
