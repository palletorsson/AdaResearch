extends "res://tools/probes/void_transfer_probe.gd"
## Exercise the actual player pointer/trigger. Algorithm receipts are separate.
var group := "all"
var mode := "both"
var active_tag := ""
var snapshots := false
var selected: Array[int] = []

func click(work: Node3D,key: String) -> void:
	check(active_tag+key+" exists",work.buttons.has(key))
	if not work.buttons.has(key):return
	var cube: Node3D = work.buttons[key];var observed: Array = [];var note := func():observed.append(true)
	cube.pressed.connect(note);await press(cube.get_node("PushButton"))
	check(active_tag+key+" receives real "+("XR trigger" if xr else "mouse click"),observed.size()==1)
	if is_instance_valid(cube):cube.pressed.disconnect(note)

func visit_floor(index: int) -> Node3D:
	level = index;game.place_player(game.spawn_for(level));await frames(25)
	var entry: Dictionary = game.building.content.data.floors[level].artifacts[0]
	var work: Node3D = station(entry.id);var console: Node3D = work.get_node("Controls")
	var foot: Vector3 = console.to_global(Vector3(0,0,1.65));foot.y = game.building.spec.levels[level]+.06
	game.place_player(foot);await frames(20)
	active_tag = ("XR" if xr else "Desktop")+" / floor "+str(level)+" / "
	return work

func held_motion_stops(work: Node3D) -> bool:
	for node in work.generated:
		if is_instance_valid(node) and node is RigidBody3D and not node.freeze:return false
	return true

func run() -> void:
	trial = "matter_logic_reference";root.size = Vector2i(1440,900)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--group="):group = arg.trim_prefix("--group=")
		if arg.begins_with("--mode="):mode = arg.trim_prefix("--mode=")
		if arg=="--capture":snapshots = true
		if arg.begins_with("--levels="):
			for value in arg.trim_prefix("--levels=").split(","):selected.append(int(value))
	for use_xr in [false,true]:
		if mode=="desktop" and use_xr or mode=="xr" and not use_xr:continue
		level = 1;await start(use_xr)
		for index in range(1,37):
			if not selected.is_empty() and index not in selected:continue
			if group=="gate-inputs" and index>6:continue
			if group=="gates" and index>13:continue
			if group=="programs" and (index<14 or index>26):continue
			if group=="knitting" and index<27:continue
			var work: Node3D = await visit_floor(index)
			if index<=6:
				var bit: bool = work.inputs.X;await click(work,"X");check(active_tag+"X changes input",work.inputs.X!=bit)
				if work.graph.inputs.has("Y"):
					var y: bool = work.inputs.Y;await click(work,"Y");check(active_tag+"Y changes input",work.inputs.Y!=y)
				else:
					var hidden: bool = not work.buttons.Y.visible
					for collider in work.buttons.Y.find_children("*","CollisionObject3D",true,false):hidden = hidden and collider.collision_layer==0 and collider.collision_mask==0
					check(active_tag+"unary gate has no invisible second input",hidden)
				await click(work,"RELEASE");check(active_tag+"release starts physics",work.running)
				await click(work,"RESET");check(active_tag+"reset returns standby",not work.running and work.result<0)
			elif index<=12:
				for inlet in work.graph.inlets:
					var before: int = work.marbles.size();await click(work,inlet)
					# The source spaces queued drops by .8–1.3 seconds. A second
					# legitimate click must wait its turn rather than spawn instantly.
					for frame in 125:
						if work.marbles.size()>=before+1:break
						await frames(1)
					check(active_tag+"hopper releases one marble",work.marbles.size()==before+1)
				await click(work,"CLEAR");check(active_tag+"clear removes delivered marbles",work.marbles.is_empty())
			elif index==13:
				await click(work,"RELEASE");check(active_tag+"tyre starts",work.running)
				await click(work,"RESET");check(active_tag+"chain resets",not work.running)
			elif index==14:
				var before: int = work.chosen;await click(work,"TYPE");check(active_tag+"type changes",work.chosen!=before)
				await click(work,"PUSH");check(active_tag+"stack accepts crate",work.ordered("stack").size()==1)
				await click(work,"POP");check(active_tag+"stack pops crate",work.ordered("stack").is_empty() and work.removed.size()==1)
				await click(work,"ENQUEUE");check(active_tag+"queue accepts crate",work.ordered("queue").size()==1)
				await click(work,"DEQUEUE");check(active_tag+"queue releases crate",work.ordered("queue").is_empty() and work.removed.size()==2)
				await click(work,"CLEAR");check(active_tag+"clear resets containers",work.crates.is_empty() and work.removed.is_empty())
			elif index<=18:
				var before: int = work.preset_index;await click(work,"PRESET");check(active_tag+"preset changes",work.preset_index!=before)
				var key := "n0" if index==15 else "step" if index==17 else "limit";var old: int = int(work.settings[key]);await click(work,"MORE");check(active_tag+"more changes parameter",int(work.settings[key])==mini(old+1,6 if index==15 else 16));await click(work,"LESS")
				await click(work,"RUN");await frames(90);check(active_tag+"run creates active work",work.running and not work.generated.is_empty())
				await click(work,"RUN");var t: float = float(work.job.get("t",0));await frames(20);check(active_tag+"pause stops both bodies and program time",work.paused and not work.running and held_motion_stops(work) and is_equal_approx(t,float(work.job.get("t",0))))
				await click(work,"RUN");check(active_tag+"resume continues the same work",work.running and not work.paused)
				await click(work,"CLEAR");check(active_tag+"clear removes suspended work",work.generated.is_empty() and not work.running and work.suspended.is_empty())
			elif index<=22:
				var old: String = JSON.stringify(work.graph.params) if index in [21,22] else str(work.inputs.X)
				await click(work,"X");check(active_tag+"input or index changes",old!=(JSON.stringify(work.graph.params) if index in [21,22] else str(work.inputs.X)))
				await click(work,"RELEASE");check(active_tag+"program starts",work.running)
				await click(work,"RESET");check(active_tag+"program resets",not work.running and work.result<0)
			elif index<=26:
				await click(work,"RELEASE");await frames(90);check(active_tag+"pins wait for player input",work.running and not work.pulled)
				await click(work,"X");await frames(90);check(active_tag+"pull releases physical pins",work.pulled and work.pull_at>=0)
				await click(work,"RESET");check(active_tag+"reset replaces pins",not work.pulled and not work.pull_requested and not work.running)
			elif index<=32:
				var old: int = work.variant;await click(work,"X");check(active_tag+"threshold setting changes",work.variant==(old+1)%3)
				await click(work,"RELEASE");check(active_tag+"threshold take starts",work.running)
				await click(work,"RESET");check(active_tag+"threshold resets",not work.running and work.reading.is_empty())
			elif index<=34:
				var old: int = work.rule
				for p in range(8):await click(work,"BIT_"+str(p))
				check(active_tag+"all eight switches address rule bits",work.rule==(old^255))
				await click(work,"RULE");check(active_tag+"preset restores rule 90",work.rule==90)
				for n in range(3):await click(work,"SEED")
				check(active_tag+"seed selector cycles back to single",work.seed_mode=="single" and work.seed_values.count(1)==1)
				var edge: bool = work.wrap;await click(work,"EDGE");check(active_tag+"boundary changes",work.wrap!=edge)
				await click(work,"RUN");await frames(35);await click(work,"RUN");check(active_tag+"knitter pause stops the live marble",not work.running and held_motion_stops(work))
				await click(work,"RUN");check(active_tag+"knitter resumes",work.running)
				await click(work,"CLEAR");await click(work,"STEP")
				for tick in 1100:
					if work.stitched>0 or work.jams>0:break
					await frames(1)
				check(active_tag+"step completes one actual stitch",work.stitched==1 and work.computed==0 and work.errors==0 and not work.running)
				print("KNITTER_INPUT_STATE ",{"floor":level,"xr":xr,"stitched":work.stitched,"computed":work.computed,"errors":work.errors,"jams":work.jams,"phase":work.phase,"seconds":work.phase_time,"ball":work.to_local(work.ball.global_position) if is_instance_valid(work.ball) else null,"global_origin":work.global_position})
				await click(work,"COMPUTE");check(active_tag+"compute is explicit and separately counted",work.finished and work.computed>0)
				await click(work,"RUN");check(active_tag+"completed fabric can restart",work.running and not work.finished and work.computed==0)
				await click(work,"CLEAR")
			elif index==35:
				var old: String = work.n0;await click(work,"START");check(active_tag+"start changes",work.n0!=old)
				await click(work,"RUN");await frames(30);await click(work,"RUN");var t: float = work.phase_t;await frames(15);check(active_tag+"kinematic pause holds the path clock",not work.running and is_equal_approx(t,work.phase_t))
				await click(work,"STEP");check(active_tag+"step arms one reading",work.step_once and work.running)
				await click(work,"FINISH");check(active_tag+"finish reaches one",work.stopped and work.n=="1")
				await click(work,"RUN");check(active_tag+"run restarts after finish",work.running and not work.stopped and not work.step_once)
				await click(work,"CLEAR");check(active_tag+"clear resets pending step",not work.running and not work.step_once and work.step_index==0)
			else:
				var old: String = work.method;await click(work,"METHOD");check(active_tag+"knitting method changes",work.method!=old)
				await click(work,"PAGE");check(active_tag+"page changes and panel identities remain editable",work.page==1 and work.has_node("WrittenPattern") and work.has_node("PunchCard") and work.has_node("BaseSix"))
				var start: String = work.n0;await click(work,"START");check(active_tag+"knitting start changes",work.n0!=start)
				await click(work,"CLEAR");check(active_tag+"clear restores first page",work.page==0)
		game.queue_free();await frames(12)
		if xr:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	var receipt := {"passed":failed.is_empty(),"group":group,"mode":mode,"checks":checks,"failures":failed,"scope":"Actual rendered desktop mouse and/or synthetic XR trigger controls on registered trial floors. Covers input state, physical pause/resume, manual pin release, rule bits/seed/edges and restart/reset. Source algorithm/physics results have separate receipts; no physical-headset acceptance or full HTML editor parity."}
	FileAccess.open(out.path_join("primary-controls-"+group+"-"+mode+("" if selected.is_empty() else "-focus")+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(receipt));quit(0 if failed.is_empty() else 1)
