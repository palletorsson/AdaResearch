extends SceneTree
const Phrase := preload("res://commons/artifacts/vogue_timeline/dance_phrase.gd")
var checks: Array = []
var failures: Array = []
var folder := "res://doc/book/iterations/2026-10-11-vogue-a-phrase-of-your-own/"
func _initialize() -> void: run.call_deferred()
func check(label: String, value: bool) -> void:
	checks.append({"name":label,"passed":value})
	if not value: failures.append(label)
	print("VOGUE ", "PASS " if value else "FAIL ", label)

func run() -> void:
	var p := Phrase.new()
	var yaw := Basis(Vector3.UP,1.7)
	var head := Vector3(17,1.5,-12)
	var local := Vector3(-0.3,0.1,-0.2)
	check("translated/rotated player retains head-relative features", Phrase.feature(head,head+yaw*local,yaw,0.65).is_equal_approx(local/0.65))
	check("chosen reach normalizes differently sized movements",Phrase.feature(Vector3.ZERO,local*2.0,Basis.IDENTITY,1.3).is_equal_approx(local/0.65))
	check("guide starts at declared frame",p.target(0.0)[0].is_equal_approx(Phrase.LEFT[0]))
	check("guide reaches lift at beat two",p.target(2.0)[1].is_equal_approx(Phrase.RIGHT[1]))
	check("midpoint contains real travel",not p.target(1.0)[0].is_equal_approx(p.target(0.0)[0]))
	check("long phrase has sixteen poses across 32 beats", Phrase.LENGTH == 32.0 and Phrase.NAMES.size() == 16)
	check("loop seam is continuous",p.target(Phrase.LENGTH-0.001)[0].distance_to(p.target(0)[0])<0.001)
	var smooth := true
	var poses_exact := true
	var moving := true
	var held := true
	for cue in 16:
		var at := float(cue) * 2.0
		var pose := p.target(at)
		poses_exact = poses_exact and pose[0].is_equal_approx(Phrase.LEFT[cue]) and pose[1].is_equal_approx(Phrase.RIGHT[cue])
		for hand in 2:
			var incoming: Vector3 = (pose[hand] - p.target(at-0.001)[hand]) / 0.001
			var outgoing: Vector3 = (p.target(at+0.001)[hand] - pose[hand]) / 0.001
			smooth = smooth and incoming.distance_to(outgoing) < 0.015
			if cue % 4 == 0:
				held = held and p.target(at-0.2)[hand].is_equal_approx(pose[hand]) and p.target(at+0.2)[hand].is_equal_approx(pose[hand])
			else:
				moving = moving and outgoing.length() > 0.02
	check("both hands reach all sixteen poses on their beats",poses_exact)
	check("velocity remains continuous through poses and the loop seam",smooth)
	check("intermediate poses keep flowing instead of stopping",moving)
	check("four section anchors hold briefly on both sides of their beat",held)
	var bounded := true
	var separated := true
	var curvature := 0.0
	for i in 3200:
		var pair := p.target(float(i) / 100.0)
		for position: Vector3 in pair:
			bounded = bounded and position.is_finite() and position.length() < 1.25 and position.z < -0.2
		separated = separated and pair[0].distance_to(pair[1]) > 0.2
	for cue in 16:
		for hand in 2:
			curvature += p.target(float(cue)*2.0+1.0)[hand].distance_to(p.target(float(cue)*2.0)[hand].lerp(p.target(float(cue)*2.0+2.0)[hand],0.5))
	check("curves stay bounded and in front of the player",bounded)
	check("two hand targets remain separated throughout the phrase",separated)
	check("transitions bend through space rather than just joining straight lines",curvature>0.5)
	for i in ceili((4.0 + 2.0 * Phrase.LENGTH + 1.0) * 60.0 / p.bpm / 0.01):
		var target := p.target(maxf(0.0,p.beat+0.01*p.bpm/60.0))
		p.advance(0.01,target[0],target[1],true)
	check("following two full phrases meets at least 32 cues",p.hits>=32)
	check("exact continuous path has full flow similarity",p.flow_time>1.0 and p.flow_sum/p.flow_time>0.999)
	var before := p.hits
	var time_before := p.beat
	for i in 100: p.advance(0.01,Vector3.ZERO,Vector3.ZERO,false)
	check("lost tracking never advances or awards",p.hits==before and p.beat==time_before)
	check("invalid tracking clears dwell",p.dwell==0.0 and p.error==INF)
	p.reset()
	for i in 2200: p.advance(0.01,Vector3(8,8,8),Vector3(9,9,9),true)
	check("wrong movement is rejected",p.hits==0 and p.flow_sum==0.0)
	p.reset();p.beat=1.9
	var t:=p.target(2.0)
	p.advance(0.01,t[0],t[1],true)
	check("one lucky frame cannot meet a pose",p.hits==0)
	p.reset();p.beat=1.66
	for i in 40: p.advance(0.01,t[0],t[1],true)
	check("one held pose awards its cue only once",p.hits==1)
	p.reset();p.beat=1.66
	for i in 40:
		var target := p.target(p.beat+0.01*p.bpm/60.0)
		p.advance(0.01,target[0],target[1]+Vector3(p.tolerance*1.2,0,0),true)
	check("one exact hand cannot compensate for the other outside tolerance",p.hits==0 and p.error<p.tolerance)
	check("independent distances identify which hand needs to move",p.hand_errors[0]<0.001 and p.hand_errors[1]>p.tolerance)
	p.advance(0.01,Vector3.ZERO,Vector3.ZERO,false)
	check("tracking loss clears both independent hand distances",p.hand_errors[0]==INF and p.hand_errors[1]==INF)
	p.reset()
	for i in 2200:
		var target := p.target(maxf(0.0,p.beat+0.01*p.bpm/60.0))
		p.advance(0.01,target[1],target[0],true)
	check("swapped hands do not pass asymmetric cues",p.hits==0)
	p.start_recording()
	for i in 2200:
		if not p.recording: break
		p.advance(0.01,Vector3(-0.4,sin(p.beat)*0.3,-0.2+sin(p.beat/2.0)*0.1),Vector3(0.4,cos(p.beat)*0.3,-0.2+cos(p.beat/2.0)*0.1),true)
	check("32 beats retain sampled original movement",p.recorded.size()>300 and not p.recording and p.use_recorded and p.recorded[-1].beat>31.8)
	check("record completion gives replay count-in",p.beat==-4.0)
	var sample:Dictionary=p.recorded[25]
	check("recorded target uses measured sample",p.target(sample.beat)[0].distance_to(sample.left)<0.001)
	check("recorded targets remain finite around loop seam",p.target(0.0)[0].is_finite() and p.target(Phrase.LENGTH-0.01)[1].is_finite())
	var samples_exact := true
	for entry: Dictionary in p.recorded:
		var replay := p.target(entry.beat)
		samples_exact = samples_exact and replay[0].distance_to(entry.left)<0.001 and replay[1].distance_to(entry.right)<0.001
	check("every measured sample survives longer replay without smoothing it away",samples_exact)
	var count := p.recorded.size()
	p.start_recording();p.cancel_recording()
	check("cancel preserves previous completed phrase",p.recorded.size()==count and p.pending.is_empty())
	var packed := load("res://commons/artifacts/vogue_timeline/vogue_timeline.tscn") as PackedScene
	check("production scene loads",packed!=null)
	if packed != null:
		var stage=packed.instantiate()
		root.add_child(stage)
		await process_frame
		check("nine real controls built",stage.controls.find_children("Btn_*","Node",true,false).size()==9)
		check("preview does not manufacture tracking",not stage.tracked() and not stage.playing)
		stage.command("RECORD")
		check("record refuses absent controllers",not stage.phrase.recording)
		var old_reach:float=stage.reach
		var button=stage.controls.find_child("Btn_4",true,false).get_node("InteractableAreaButton")
		button.button_pressed.emit(button)
		check("actual reach button changes reach",stage.reach!=old_reach)
		stage.phrase.recorded=p.recorded.duplicate(true)
		stage.command("CLEAR")
		check("clear removes player samples",stage.phrase.recorded.is_empty())
		check("original PCM loop loaded",stage.audio.stream.get_length()>4.0 and stage.audio.stream.get_length()<4.4)
		stage.render_pose(2.0)
		for hand in 2:
			var low := Vector3(INF, INF, INF)
			var high := Vector3(-INF, -INF, -INF)
			var exact := true
			for i in stage.PATH_SAMPLES:
				var line: MeshInstance3D = stage.path_rods[hand * stage.PATH_SAMPLES + i]
				var a: Vector3 = stage.phrase.target(stage.path_start + float(i) * stage.LOOKAHEAD_BEATS / stage.PATH_SAMPLES)[hand]
				var b: Vector3 = stage.phrase.target(stage.path_start + float(i + 1) * stage.LOOKAHEAD_BEATS / stage.PATH_SAMPLES)[hand]
				exact = exact and (line.transform * Vector3(0, -0.5, 0)).distance_to(a) < 0.001
				exact = exact and (line.transform * Vector3(0, 0.5, 0)).distance_to(b) < 0.001
				low = low.min(line.global_position)
				high = high.max(line.global_position)
			check("hand %d reference tubes preserve all three target coordinates" % hand, exact)
			check("hand %d path floats with height and depth, no floor projection" % hand, low.y > 0.9 and high.y - low.y > 0.45 and high.z - low.z > 0.1)
			check("hand %d moving bead sits on the current 3D target" % hand, stage.beads[hand * 8].position.is_equal_approx(stage.phrase.target(2.0)[hand]))
		stage.render_pose(18.25)
		check("long phrase reveals the next eight beats in its moving path window",stage.path_start==18.25 and stage.LOOKAHEAD_BEATS==8.0)
		var markers_exact := true
		for hand in 2:
			for i in range(1,8):
				markers_exact = markers_exact and stage.beads[hand*8+i].position.is_equal_approx(stage.phrase.target(18.0+float(i))[hand])
		check("both hand markers anticipate actual integer beats",markers_exact)
		var arrows_correct := true
		for hand in 2:
			for i in 3:
				var at_arrow := 18.0 + 1.5 + float(i)*2.0
				var arrow: MeshInstance3D = stage.direction_arrows[hand*3+i]
				var tangent: Vector3 = stage.phrase.target(at_arrow+0.01)[hand]-stage.phrase.target(at_arrow-0.01)[hand]
				arrows_correct = arrows_correct and arrow.visible and arrow.position.distance_to(stage.phrase.target(at_arrow)[hand])<0.001 and arrow.basis.y.dot(tangent.normalized())>0.999
		check("six arrows sit on both curves and point forward through time",arrows_correct)
		check("wall previews continue into later poses instead of repeating the first four",stage.cards[0].get_node("Caption").text=="21 / WEAVE")
		stage.render_pose(18.0)
		var onbeat_scale: float = stage.beads[0].scale.x
		stage.render_pose(18.5)
		check("both leading beads pulse on the beat",onbeat_scale>stage.beads[0].scale.x and stage.beads[0].scale.is_equal_approx(stage.beads[8].scale))
		for tempo in [96.0,112.0,128.0]:
			var tempo_phrase := Phrase.new()
			tempo_phrase.bpm=tempo
			for i in ceili((4.0+Phrase.LENGTH+1.0)*60.0/tempo/0.01):
				var target := tempo_phrase.target(maxf(0.0,tempo_phrase.beat+0.01*tempo/60.0))
				tempo_phrase.advance(0.01,target[0],target[1],true)
			check("all 16 pose cues remain reachable at %d BPM" % int(tempo),tempo_phrase.hits>=16)
			var audio_aligned := true
			for bar in 9:
				var at := float(bar)*4.0
				audio_aligned = audio_aligned and is_equal_approx(stage.audio_phase(at,tempo),fposmod(at+4.0,8.0)*60.0/tempo)
			check("audio wraps within the eight-beat backing across 32 beats at %d BPM" % int(tempo),audio_aligned)
		# A recorded gesture changes depth as well as height; replay must retain it.
		stage.phrase.recorded = [{"beat":0.0,"left":Vector3(-0.4,0.2,-0.8),"right":Vector3(0.6,-0.3,-0.1)}, {"beat":4.0,"left":Vector3(-0.7,-0.4,-0.1),"right":Vector3(0.3,0.5,-0.9)}]
		stage.phrase.use_recorded = true
		stage._refresh_paths()
		stage.render_pose(4.0)
		check("recorded left/right depth survives airborne replay", stage.beads[0].position.is_equal_approx(Vector3(-0.7,-0.4,-0.1)) and stage.beads[8].position.is_equal_approx(Vector3(0.3,0.5,-0.9)))
		stage.phrase.recorded = [{"beat":0.0,"left":Vector3(-0.4,0,-0.5),"right":Vector3(0.4,0,-0.5)}, {"beat":16.0,"left":Vector3(-0.4,0,-0.5),"right":Vector3(0.4,0,-0.5)}]
		stage.render_pose(10.0)
		var stationary_ok := true
		for arrow: MeshInstance3D in stage.direction_arrows:
			stationary_ok = stationary_ok and not arrow.visible and arrow.transform.is_finite()
		check("stationary recorded hands show no invented direction",stationary_ok)
		stage.trails = [[Vector3(-0.2,0.1,-0.1),Vector3(-0.6,0.4,-0.7)], [Vector3(0.3,-0.2,-0.2),Vector3(0.5,0.6,-0.8)]]
		stage._update_trails()
		for hand in 2:
			var line: MeshInstance3D = stage.trail_rods[hand * (stage.TRAIL_POINTS - 1)]
			check("hand %d measured trail preserves both 3D endpoints" % hand, (line.transform * Vector3(0,-0.5,0)).is_equal_approx(stage.trails[hand][0]) and (line.transform * Vector3(0,0.5,0)).is_equal_approx(stage.trails[hand][1]))
		var still: MeshInstance3D = stage.trail_rods[0]
		stage._place_rod(still, Vector3.ONE, Vector3.ONE, 0.01)
		check("holding still creates no invalid tube geometry", still.transform.is_finite() and still.scale.is_zero_approx())
		stage.command("CLEAR")
		check("clear hides both measured hand trails", not stage.trail_rods[0].visible and not stage.trail_rods[stage.TRAIL_POINTS - 1].visible)
		stage.set_process(false)
		var origin := XROrigin3D.new()
		root.add_child(origin)
		var ht := XRPositionalTracker.new()
		ht.name=&"head";ht.type=XRServer.TRACKER_HEAD
		ht.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(0,1.6,0.5)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(ht)
		var cam := XRCamera3D.new();origin.add_child(cam)
		var trackers:Array=[]
		for side in [&"left_hand",&"right_hand"]:
			var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
			tr.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-0.3 if side==&"left_hand" else 0.3,1.5,0.2)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			XRServer.add_tracker(tr);trackers.append(tr)
			var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
		await process_frame;await process_frame
		stage._resolve_rig()
		check("real XR nodes accept supplied tracked poses",stage.tracked())
		stage.command("RECORD")
		check("tracked record button starts a count-in",stage.playing and stage.phrase.recording and stage.phrase.beat==-4.0)
		stage.preview_only = false
		stage.render_pose(0.0)
		check("record mode leaves room for your own trail without reference paths",not stage.path_root.visible and stage.trail_root.visible)
		stage.command("PLAY")
		check("pause cancels unfinished recording",not stage.playing and not stage.phrase.recording)
		stage.command("PLAY")
		cam.make_current()
		stage._process(0.01)
		check("tracked playback shows hand-space targets",stage.hand_targets[0].visible and stage.hand_targets[1].visible)
		var expected:Vector3=stage.head.global_position+stage.facing*(stage.phrase.target(0.0)[0]*stage.reach)
		check("target ring agrees with measured reference frame",stage.hand_targets[0].global_position.distance_to(expected)<0.001)
		check("count-in does not show a successful match",stage.hand_labels[0].text=="LEFT / READY" and stage.hand_labels[1].text=="RIGHT / READY")
		for correct_hand in 2:
			var target: Array = stage.phrase.target(2.0)
			for hand in 2:
				var offset := Vector3.ZERO if hand==correct_hand else Vector3(0.5,0,0)
				var hand_world: Vector3 = cam.global_position+stage.facing*((target[hand]+offset)*stage.reach)
				trackers[hand].set_pose(&"default",Transform3D(Basis.IDENTITY,origin.to_local(hand_world)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await process_frame;await process_frame
			stage.phrase.beat=2.0
			stage._process(0.0)
			check("tracked hand %d gets its own in-place feedback" % correct_hand,stage.hand_labels[correct_hand].text.ends_with("IN PLACE") and stage.hand_labels[1-correct_hand].text.ends_with("FOLLOW"))
			var bright: Color = stage.hand_targets[correct_hand].material_override.albedo_color
			var plain: Color = stage.hand_targets[1-correct_hand].material_override.albedo_color
			check("only matched hand %d brightens its target ring" % correct_hand,bright.is_equal_approx((stage.PINK if correct_hand==0 else stage.CYAN).lightened(0.72)) and plain.is_equal_approx(stage.CYAN if correct_hand==0 else stage.PINK))
		origin.transform = Transform3D(Basis(Vector3.UP, 0.7), Vector3(0.5,0,-0.3))
		stage.command("PLAY")
		stage.command("PLAY")
		stage._process(0.01)
		for hand in 2:
			check("hand %d 3D path and ring agree after player turn and translation" % hand, stage.beads[hand * 8].global_position.distance_to(stage.hand_targets[hand].global_position) < 0.001)
		stage.command("REACH")
		stage._process(0.01)
		check("reach resizes airborne paths with both target rings", stage.beads[0].global_position.distance_to(stage.hand_targets[0].global_position) < 0.001 and stage.beads[8].global_position.distance_to(stage.hand_targets[1].global_position) < 0.001)
		trackers[0].invalidate_pose(&"default")
		check("one invalid controller stops recognition",not stage.tracked())
		var paused_beat:float=stage.phrase.beat
		stage._process(0.05)
		check("live adapter pauses clock, hides targets and stops audio on tracking loss",stage.phrase.beat==paused_beat and not stage.hand_targets[0].visible and not stage.audio.playing)
		check("lost tracking hides measured trails and returns to labelled preview", not stage.trail_root.visible and stage.preview_only)
		check("tracking loss clears both hand feedback indicators",stage.hand_labels[0].text=="LEFT / PAUSED" and stage.hand_labels[1].text=="RIGHT / PAUSED" and stage.hand_targets[0].material_override.albedo_color.is_equal_approx(stage.PINK))
		for tr in trackers: XRServer.remove_tracker(tr)
		XRServer.remove_tracker(ht)
		origin.queue_free()
		stage.queue_free()
		await process_frame
	FileAccess.open(folder+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Godot production core and scene with synthetic inputs; no headset/user dance validation."},"  "))
	quit(0 if failures.is_empty() else 1)
