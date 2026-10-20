# Touch and be moved

<!-- @random_touch -->

Five one-metre rods sit before a pale recording wall. A dark bead waits at each centre. Touch starts movement: one virtual hand follows the bead, and circles accumulate behind it. Rows 1–4 share an X path at ½×, 1×, 2× and 4× speed. Row 5 adds Y at 1×. Can the same path make a different encounter while leaving the same ink?

In VR, contact or grabbing starts movement. Withdraw the physical controller more than 20 centimetres from the contact position to release. Only the contacting virtual hand follows; the tracked controller, head, body and other hand remain unchanged. On desktop, right-click grabs or releases; the camera stays still. After release, the bead returns alone. REPLAY clears paths and paper, then waits for contact.

## What stays the same

Bring positions, vectors and elapsed time from the earlier movement studies. X is sideways in the installation; Y is vertical. A **pseudorandom generator** is a calculation with changing internal state. Each request advances it. A **seed** sets its beginning; repeating the seed and request procedure repeats the sequence.

The abacus stores 48 coordinate pairs: the resting centre and 47 generated targets. X stays within ±0.44 metres, Y within ±0.12. Separate generators supply X and Y, so adding Y never consumes another X draw. The targets are uniform: equal-width intervals have equal probability. Saving the actual targets also preserves the path if a later generator implementation changes.

Random Definition starts its instruments from the saved hall seed **435**. Each owns a private stream, so playing the slots does not advance the Geiger. The abacus uses 435 for X and 436 for Y. A seed is not the whole experiment: request order, bounds, mapping and timing also matter.

The window permits explicit seed choices and SEED +1. RESET 435 recalls the saved starting receipt. Loading a retained record can also change the shared seed. Keep 435 throughout this comparison. The frame study cannot reseed the hall; MOVE / KEEP is currently removed from the saved room and is not a required step.

## Time becomes a path and then a mark

Rows 1–4 traverse 0.4, 0.8, 1.6 and 3.2 target segments per second; row 5 uses 0.8. Each clock starts with contact. Idle waiting advances none. Between targets, the fraction `u` becomes `u * u * (3 - 2 * u)`: **interpolation** that slows near each endpoint. After the last target, the path returns to the first.

For targets −0.2 and +0.2, the midpoint is zero. Row 2 reaches it 0.625 seconds into that segment; row 3 takes 0.3125. More generally, row 2 at `t` matches rows 1, 3 and 4 at `2t`, `t/2` and `t/4`. Row 5 shares row 2's X at equal times.

The wall stamps twelve circles at equal time fractions of each segment. Equal numbers of steps produce identical X marks at all four speeds; equal durations need not. Waiting and the empty return add none. Each row keeps its latest 576 marks. Dark patches record overlapping interpolated positions, not a histogram of generated targets or evidence of true randomness.

## Build a copy we can investigate

Work inside this AdaResearch project. Save the five complete files below together in a new study folder. Create an upright, unit-scale Node3D named `Abacus`, attach `random_touch.gd`, and add a child Node named `Notebook` with `experiment_notebook.gd`. Save the scene and instance it in a practice scene with the inherited museum player, camera, lights and XR Tools. Place its origin on the floor with the front accessible; allow about 1.3 metres width and 0.55 metres depth.

The four apparatus files reproduce the current artifact. Their `res://` dependencies are inherited project components: the [path-preserving point](../../artifacts/random_return/ride_point.gd), [stage helpers](../../artifacts/randomness_space/museum_exhibit_stage.gd), [hall seed controller](../../artifacts/randomness_space/hall_seed.gd) and rectangular button. The hand follower temporarily replaces XR Tools' hand target; it cannot move the physical hand. Read `make_record()` and `offset()` first, then `advance()` and `_sync_hand()`.

The fifth file supplies desktop/operator recording shortcuts for this reconstruction. The installed room still has only REPLAY. Before running, enter the notebook's `condition`, `question` and `prediction` in the Inspector. While running, select Notebook in Godot's **Remote** scene tree to edit those fields. Keep the game window focused for shortcuts; a VR trial can use an operator at the keyboard.

## One complete experiment

1. **Baseline.** Set `condition` to `baseline-row-2`. Confirm seed 435, uniform targets and empty paper. Touch row 2. Aim for eight steps: 96 marks, about ten seconds. Predict what doubling the speed will preserve.
2. **Keep the moment.** While it is moving, press **Ctrl+Shift+K**. This saves without stopping it. Release afterward. Copy the full file path printed in Godot's Output. Open that JSON and fill `observation` and `next_change`; leave `record` and `record_bytes` untouched. Include what drew attention, felt unclear, or made no difference. The stored seconds expose any overshoot beyond the intended eight steps.
3. **Change one condition.** Release and press REPLAY. Change the notebook condition to `comparison-row-3`, then touch row 3 for eight steps, about five seconds. Save again. Seed, targets, X range, smoothing and mark spacing stay fixed; only rate changes. Compare equal prefixes of the recorded ink if stopping times differ. Does faster arrival change the encounter despite matching marks?
4. **Reopen.** Stop and restart the practice scene. Set Notebook's `load_path` to either saved file, then press **Ctrl+Shift+L**. Release held instruments first. Targets, rates, times, offsets and ink return **paused**; no hand attaches. Check the stored seconds and mark count against the restored scene before continuing.
5. **Resume or replay.** **Ctrl+Shift+P** resumes a loaded state; touch the bead to continue its stored phase. A snapshot taken during an empty return completes that return first. To repeat from the beginning instead, release and press **REPLAY**: targets stay, but times and paper clear. Compare at the same elapsed phase. Ctrl+Shift+P also pauses a running trial, releasing its hand.
6. **Reconstruct independently.** Give another person this chapter, the five files, both recordings and the project revision. Ask them to build a fresh scene and load each file. Compare targets, phase, offsets and ink before asking whether the encounter feels similar. Replaying stored data establishes reproducibility, not newly unpredictable randomness or identical sensation.
7. **Let the observation change the next trial.** If speed changes the encounter but the paper hides that difference, ask what another recording procedure would retain. Or compare rows 2 and 5 at equal elapsed time, changing only the available axes. Record the proposed change, prediction and subsequent observation—even if nothing interesting happens.

Each save creates a new file. Its notebook envelope retains the question and observation separately from the `random-touch/4` record. `record` is the readable view; `record_bytes` packs the same state without losing numeric bits and supplies restoration. Godot's JSON reader can slightly round the readable decimals. Preserve the five source files, engine version and project revision alongside it. An incompatible record is refused. The recording retains prescribed bead state and ink, not physical gestures, actual hand trajectories or feelings. In the shared hall, restoring a seed also resets other participating instruments, so use the practice copy for this comparison.

## Complete files

### motion_record.gd

<!-- student-code:motion_record.gd -->

```gdscript
extends RefCounted
## Five abacus paths starting at rest. X is shared; only the last row adds Y.
const COUNT := 48
const RANGE := 0.44
const Y_RANGE := 0.12
const RATES := [0.4, 0.8, 1.6, 3.2, 0.8]
const LANES := 5
const MARKS_PER_SEGMENT := 12
const INK_LIMIT := COUNT * MARKS_PER_SEGMENT

static func make_record(seed_value: int = 435, distribution: String = "uniform") -> Dictionary:
	var x_rng := RandomNumberGenerator.new()
	var y_rng := RandomNumberGenerator.new()
	x_rng.seed = seed_value
	y_rng.seed = seed_value + 1
	var points: Array = [[0.0, 0.0]]
	for i in range(1, COUNT):
		points.append([draw(x_rng,RANGE,distribution), draw(y_rng,Y_RANGE,distribution)])
	return {"schema":"random-touch/4", "seed":seed_value, "distribution":distribution, "points":points, "rates":RATES.duplicate(), "range":RANGE, "y_range":Y_RANGE, "seconds":[0.0,0.0,0.0,0.0,0.0], "offsets":[[0.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0]], "returning":[false,false,false,false,false], "ink":[[],[],[],[],[]]}

static func draw(rng: RandomNumberGenerator, extent: float, distribution: String) -> float:
	if distribution == "uniform": return rng.randf_range(-extent,extent)
	# Truncated normal, sigma = extent/3. Reject tails, never pile them at an edge.
	var value := rng.randfn(0.0,extent/3.0)
	while absf(value) > extent: value = rng.randfn(0.0,extent/3.0)
	return value

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid(record: Dictionary) -> bool:
	if record.get("schema") != "random-touch/4": return false
	if record.get("distribution") not in ["uniform","gaussian_bounded"]: return false
	if not number(record.get("seed")): return false
	if not record.get("points") is Array or record.points.size() != COUNT: return false
	if not record.get("rates") is Array or record.rates != RATES: return false
	if not number(record.get("range")): return false
	if not is_equal_approx(float(record.range), RANGE): return false
	if not number(record.get("y_range")) or not is_equal_approx(float(record.y_range), Y_RANGE): return false
	for field in ["seconds", "offsets", "returning"]:
		if not record.get(field) is Array or record[field].size() != LANES: return false
	for p in record.points:
		if not p is Array or p.size() != 2: return false
		for v in p:
			if not number(v) or absf(float(v)) > RANGE: return false
		if absf(float(p[1])) > Y_RANGE: return false
	if float(record.points[0][0]) != 0 or float(record.points[0][1]) != 0: return false
	for lane in LANES:
		if not number(record.seconds[lane]) or float(record.seconds[lane]) < 0: return false
		if not record.returning[lane] is bool: return false
		var p = record.offsets[lane]
		if not p is Array or p.size() != 2: return false
		if not number(p[0]) or not number(p[1]): return false
		if absf(float(p[0])) > RANGE or absf(float(p[1])) > Y_RANGE: return false
		if lane < LANES-1 and float(p[1]) != 0: return false
		if not record.returning[lane] and not Vector3(p[0],p[1],0).is_equal_approx(offset(record,lane,float(record.seconds[lane]))): return false
	if not record.get("ink") is Array or record.ink.size() != LANES: return false
	for lane in LANES:
		if not record.ink[lane] is Array or record.ink[lane].size() > INK_LIMIT: return false
		for p in record.ink[lane]:
			if not p is Array or p.size()!=2 or not number(p[0]) or not number(p[1]): return false
			if absf(p[0])>RANGE or absf(p[1])>Y_RANGE or (lane<4 and p[1]!=0): return false
	return true

static func offset(record: Dictionary, lane: int, seconds: float) -> Vector3:
	var phase := maxf(seconds, 0.0) * float(record.rates[lane])
	var index := int(floor(phase)) % COUNT
	var u := fposmod(phase, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var a: Array = record.points[index]
	var b: Array = record.points[(index + 1) % COUNT]
	return Vector3(lerpf(a[0], b[0], u), lerpf(a[1], b[1], u) if lane == LANES-1 else 0.0, 0)
```

### random_touch.gd

<!-- student-code:random_touch.gd -->

```gdscript
extends Node3D
## A compact five-row abacus. Contact moves one virtual hand, never the body.
const Motion = preload("motion_record.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Point = preload("res://commons/artifacts/random_return/ride_point.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const HandFollower = preload("hand_follower.gd")
const InkWall = preload("ink_wall.gd")
const HOMES := [Vector3(0,1.73,0), Vector3(0,1.59,0), Vector3(0,1.45,0), Vector3(0,1.31,0), Vector3(0,1.03,0)]
const NAMES := ["1 / X / ½×", "2 / X / 1×", "3 / X / 2×", "4 / X / 4×", "5 / X + Y / 1×"]
const BEAD_RADIUS := 0.05
const TOUCH_RADIUS := 0.065
const REPLAY_HEIGHT := 0.72
const RETURN_SPEED := 0.4
var record := Motion.make_record()
var kept: Dictionary = {}
var times: Array = [0.0,0.0,0.0,0.0,0.0]
var offsets: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var returning: Array = [false,false,false,false,false]
var blocked: Array[bool] = [false,false,false,false,false]
var paused := false
var points: Array = []
var areas: Array[Area3D] = []
var lines: Array[MeshInstance3D] = []
var readout: Label3D
var source_label: Label3D
var ink_labels: Array[Label3D] = []
var ink: Node3D
var active_lane := -1
var follower: Node3D
var active_controller: XRController3D
var held_motion := false
var save_path := "user://random-touch-ink-001.json"
var message := ""

func _ready() -> void:
	if HallSeed.enabled(self): record = Motion.make_record(HallSeed.current(self),record.distribution)
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-0.65,0,-0.25),Vector3(1.3,2.15,0.55)))
	process_physics_priority = -100 # Set the target before XR collision/visual hands.
	follower = HandFollower.new()
	follower.name = "HandMotionTarget"
	add_child(follower)
	ink = InkWall.new()
	ink.name = "RecordingWall"
	add_child(ink)
	ink.build(HOMES)
	# Pale recording paper, thin charcoal case, warm metal rods.
	var paper := Stage.box(self,Vector3(0,1.405,-0.145),Vector3(1.12,1.11,0.05),Color("eeeade"))
	paper.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Stage.box(self,Vector3(0,2.035,-0.08),Vector3(1.20,0.14,0.12),Color("213138"))
	var title := _label("RANDOM / TOUCH",Vector3(0,2.04,0.005),28)
	title.modulate = Color("eeeade")
	for x in [-0.56,0.56]:
		Stage.box(self,Vector3(x,0.99,-0.10),Vector3(0.035,1.98,0.10),Color("213138"))
		Stage.box(self,Vector3(x,0.025,0),Vector3(0.14,0.05,0.48),Color("213138"))
	for y in [0.85,1.94]: Stage.box(self,Vector3(0,y,-0.10),Vector3(1.15,0.025,0.10),Color("213138"))
	for lane in Motion.LANES:
		var line := Stage.box(self,HOMES[lane],Vector3(1.0,0.006,0.006),Color("b59c63"))
		line.name = "Line%d" % lane
		lines.append(line)
		_label(NAMES[lane],HOMES[lane]+Vector3(-0.30,0.20 if lane == 4 else 0.07,0.018),15)
		ink_labels.append(_label("0 marks",HOMES[lane]+Vector3(0.37,0.20 if lane==4 else 0.07,-0.07),12))
		for x in [-0.5,0.5]: Stage.box(self,HOMES[lane]+Vector3(x,0,-0.01),Vector3(0.018,0.026,0.035),Color("b59c63"))
		if lane == 4: Stage.box(self,HOMES[lane]+Vector3(0,0,-0.095),Vector3(0.002,Motion.Y_RANGE*2,0.002),Color("b6c0bb"))
		var point = Point.new()
		point.name = "TouchSphere%d" % lane
		point.position = HOMES[lane]
		add_child(point)
		point.sphere.radius = BEAD_RADIUS
		point.sphere.height = BEAD_RADIUS*2.0
		point.get_child(1).shape.radius = BEAD_RADIUS
		points.append(point)
		var touch := Area3D.new()
		touch.collision_layer = 0
		touch.collision_mask = 393216
		var boundary := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = TOUCH_RADIUS
		boundary.shape = shape
		touch.add_child(boundary)
		point.add_child(touch)
		areas.append(touch)
	var control_face := Stage.box(self,Vector3(0,0.67,-0.08),Vector3(1.12,0.34,0.10),Color("d7d7c9"))
	control_face.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var replay = load("res://commons/interactables/push_button.tscn").instantiate()
	replay.name = "ReplayButton"
	Rack.make_button_rectangular(replay)
	replay.rotation.x = PI/2
	replay.position = Vector3(0,REPLAY_HEIGHT,-0.025)
	replay.released_color = Color("263b41")
	replay.pressed_color = Color("c4a970")
	replay.get_node("ButtonBase/BaseMesh").visible = false
	replay.get_node("Button/ButtonMesh").mesh.size = Vector3(0.76,0.024,0.20)
	replay.get_node("AccentRing").mesh.size = Vector3(0.80,0.014,0.24)
	replay.get_node("Button/CollisionShape3D").shape.size = Vector3(0.76,0.028,0.20)
	replay.get_node("InteractableAreaButton/CollisionShape3D").shape.size = Vector3(0.80,0.06,0.24)
	add_child(replay)
	var caption := _label("REPLAY",Vector3.ZERO,52)
	caption.reparent(replay.get_node("Button"),false)
	caption.position = Vector3(0,0.015,0)
	caption.rotation.x = -PI/2
	caption.modulate = Color("eeeade")
	replay.pressed.connect(act.bind(0))
	readout = _label("",Vector3(0,0.53,-0.015),14)
	source_label = _label("",Vector3(0,1.89,-0.07),15)
	_update_pose()
	HallSeed.bind(self)

func can_apply_hall_seed() -> bool:
	return not _busy()

func _apply_hall_seed(value: int, _receipt: Dictionary) -> void:
	record = Motion.make_record(value,record.distribution)
	_reset_paths()
	paused = false
	_update_pose()

func _reset_paths() -> void:
	times.fill(0.0)
	offsets.fill(Vector3.ZERO)
	returning.fill(false)
	ink.clear()

func _label(words: String, at: Vector3, size: int) -> Label3D:
	var l := Stage.label(self,words,at)
	l.font_size = size
	l.pixel_size = 0.0018
	l.outline_size = 0
	l.modulate = Color("24363b")
	return l

func _physics_process(delta: float) -> void:
	_sync_hand()
	advance(delta)

func _contacts(lane: int) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for body in areas[lane].get_overlapping_bodies():
		if _controller(body) != null: found.append(body)
	return found

func _controller(body: Node) -> XRController3D:
	var node := body
	while node != null:
		if node is XRController3D: return node
		node = node.get_parent()
	return null

func _sync_hand() -> void:
	if active_lane >= 0:
		var point = points[active_lane]
		if paused or (held_motion and not point.held()):
			stop_motion()
		elif is_instance_valid(active_controller):
			if follower.withdrawn(): stop_motion()
		elif follower.installed or not point.held():
			stop_motion()
	var candidates: Array = []
	for lane in Motion.LANES:
		var hands := _contacts(lane)
		if not points[lane].held() and hands.is_empty(): blocked[lane] = false
		if active_lane >= 0 or paused or blocked[lane] or returning[lane]: continue
		if points[lane].held():
			begin_motion(lane, points[lane].get_picked_up_by_controller())
		else:
			for hand in hands:
				candidates.append({"lane":lane,"hand":hand,"distance":hand.global_position.distance_squared_to(points[lane].global_position)})
	# A palm can overlap adjacent compact rows; choose the nearest bead.
	candidates.sort_custom(func(a,b): return a.distance < b.distance)
	for candidate in candidates:
		if active_lane >= 0: break
		if begin_motion(candidate.lane,_controller(candidate.hand)): break

func begin_motion(lane: int, controller: XRController3D = null) -> bool:
	if lane < 0 or lane >= Motion.LANES or active_lane >= 0 or paused: return false
	if returning[lane] or blocked[lane]: return false
	if controller != null:
		if not follower.begin(controller, points[lane]): return false
	elif not points[lane].held():
		return false
	active_lane = lane
	active_controller = controller
	held_motion = points[lane].held()
	if controller != null and controller.get_is_active():
		controller.trigger_haptic_pulse("haptic",0.0,0.16,0.035,0.0)
	return true

func stop_motion() -> void:
	if active_lane < 0: return
	var lane := active_lane
	active_lane = -1
	follower.stop()
	active_controller = null
	held_motion = false
	returning[lane] = true
	blocked[lane] = true
	points[lane].release_rider()

func advance(delta: float) -> void:
	if not paused:
		for lane in Motion.LANES:
			if lane == active_lane:
				var before: float = times[lane]
				times[lane] += maxf(delta,0.0)
				offsets[lane] = Motion.offset(record,lane,times[lane])
				ink.record_span(record,lane,before,times[lane])
			elif returning[lane]:
				offsets[lane] = offsets[lane].move_toward(Vector3.ZERO,RETURN_SPEED*maxf(delta,0.0))
				if offsets[lane].is_zero_approx():
					offsets[lane] = Vector3.ZERO
					times[lane] = 0.0
					returning[lane] = false
	_update_pose()
	follower.update_target()

func _update_pose() -> void:
	for lane in points.size():
		points[lane].position = HOMES[lane] + offsets[lane]
		points[lane].freeze = true
		PhysicsServer3D.body_set_state(points[lane].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,points[lane].global_transform)
		points[lane].force_update_transform()
		ink_labels[lane].text = "%d / %d marks" % [ink.marks[lane].size(),Motion.INK_LIMIT]
	source_label.text = "%s  ·  12 marks / step" % ("UNIFORM TARGETS" if record.distribution=="uniform" else "GAUSSIAN TARGETS / BOUNDED")
	readout.text = "SEED %d / %s%s\n%s" % [int(record.seed),"PAUSED" if paused else ("HAND %d" % (active_lane+1) if active_lane >= 0 else "WAITING FOR TOUCH")," / KEPT" if not kept.is_empty() else "",message]

func capture() -> Dictionary:
	var value := record.duplicate(true)
	if HallSeed.enabled(self): value["hall_receipt"] = HallSeed.state(self).receipt.duplicate(true)
	value.seconds = times.duplicate()
	value.returning = returning.duplicate()
	value.offsets = []
	value.ink = ink.marks.duplicate(true)
	for offset in offsets: value.offsets.append([offset.x,offset.y])
	return value

func _busy() -> bool:
	if active_lane >= 0: return true
	for point in points:
		if point.held(): return true
	return false

func restore(value: Dictionary) -> bool:
	if _busy() or not Motion.valid(value): return false
	if HallSeed.enabled(self) and not HallSeed.choose(self, int(value.seed), value.get("hall_receipt",{"provider":"saved_record","label":"Kept hand path","seed":int(value.seed)}), true): return false
	record = value.duplicate(true)
	times = record.seconds.duplicate()
	returning = record.returning.duplicate()
	for lane in Motion.LANES: offsets[lane] = Vector3(record.offsets[lane][0],record.offsets[lane][1],0)
	ink.restore(record.ink)
	paused = true
	_update_pose()
	return true

func act(index: int) -> void:
	message = ""
	if index in [0,3,4] and _busy():
		message = "Let go before changing the path."
		_update_pose()
		return
	match index:
		0:
			_reset_paths()
			paused = false
		1:
			paused = not paused
			if paused: stop_motion()
		2:
			var value := capture()
			var file := FileAccess.open(save_path,FileAccess.WRITE)
			if file == null:
				message = "Could not save. Current path remains available."
			else:
				file.store_string(JSON.stringify(value,"",true,true))
				kept = value
		3:
			if not FileAccess.file_exists(save_path):
				message = "KEEP a comparison first."
			else:
				var value = JSON.parse_string(FileAccess.get_file_as_string(save_path))
				if not value is Dictionary or not restore(value):
					message = "Invalid recording; current path retained."
				else: kept = value.duplicate(true)
		4:
			var distribution := "gaussian_bounded" if record.distribution=="uniform" else "uniform"
			record = Motion.make_record(int(record.seed),distribution)
			_reset_paths()
			paused = false
			message = "Same seed; new target distribution. Touch to compare."
		5:
			ink.clear()
			message = "Paper cleared; path and pace unchanged."
	_update_pose()

func _exit_tree() -> void:
	stop_motion()
```

### hand_follower.gd

<!-- student-code:hand_follower.gd -->

```gdscript
extends Node3D
## Offsets only the contacting virtual hand. Tracking, camera and body stay intact.
const WITHDRAW_DISTANCE := 0.20
const PRIORITY := 120
var controller: XRController3D
var point: Node3D
var tracked_start := Vector3.ZERO
var point_start := Vector3.ZERO
var collision_hand: Node3D
var visual_hand: Node3D
var installed := false
var had_tracking := false

func begin(tracked: XRController3D, sphere: Node3D) -> bool:
	if not is_instance_valid(tracked) or not is_instance_valid(sphere): return false
	if tracked.has_meta("random_touch_owner") and is_instance_valid(tracked.get_meta("random_touch_owner")): return false
	# Runtime-created hand roots may not have a PackedScene owner.
	collision_hand = XRTools.find_xr_child(tracked,"*","XRToolsCollisionHand",true,false)
	visual_hand = XRTools.find_xr_child(tracked,"*","XRToolsHand",true,false)
	if collision_hand == null and visual_hand == null: return false
	controller = tracked
	point = sphere
	tracked_start = tracked.global_position
	point_start = sphere.global_position
	had_tracking = tracked.get_is_active()
	global_transform = tracked.global_transform
	if collision_hand != null: collision_hand.add_target_override(self, PRIORITY)
	if visual_hand != null: visual_hand.add_target_override(self, PRIORITY)
	tracked.set_meta("random_touch_owner", self)
	installed = true
	return true

func withdrawn() -> bool:
	if not installed or not is_instance_valid(controller) or not is_instance_valid(point): return true
	if had_tracking and not controller.get_is_active(): return true
	# Compare actual tracking with the original contact, never the displaced mesh.
	return controller.global_position.distance_to(tracked_start) > WITHDRAW_DISTANCE

func update_target() -> void:
	if not installed or not is_instance_valid(controller) or not is_instance_valid(point): return
	global_transform = controller.global_transform
	global_position += point.global_position - point_start
	force_update_transform()

func stop() -> void:
	if is_instance_valid(collision_hand): collision_hand.remove_target_override(self)
	if is_instance_valid(visual_hand): visual_hand.remove_target_override(self)
	if is_instance_valid(controller) and controller.has_meta("random_touch_owner") and controller.get_meta("random_touch_owner") == self:
		controller.remove_meta("random_touch_owner")
	installed = false

func _exit_tree() -> void:
	stop()
```

### ink_wall.gd

<!-- student-code:ink_wall.gd -->

```gdscript
extends Node3D
## Equal phase samples: speed changes when marks arrive, never their positions.
const Motion = preload("motion_record.gd")
const RADIUS := 0.018
var marks: Array = [[],[],[],[],[]]
var layers: Array[MultiMeshInstance3D] = []

func build(homes: Array) -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
void fragment() {
    float edge = 1.0 - smoothstep(0.91, 1.0, length(UV * 2.0 - 1.0));
    ALBEDO = vec3(0.075, 0.12, 0.14);
    ALPHA = edge * 0.035;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var circle := QuadMesh.new()
	circle.size = Vector2.ONE * RADIUS * 2
	circle.material = material
	for lane in Motion.LANES:
		var layer := MultiMeshInstance3D.new()
		layer.name = "InkRow%d" % lane
		layer.position = homes[lane] + Vector3(0,0,-0.085)
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = circle
		layer.multimesh.instance_count = Motion.INK_LIMIT
		layer.multimesh.visible_instance_count = 0
		layer.multimesh.custom_aabb = AABB(Vector3(-0.48,-0.15,-0.01),Vector3(0.96,0.30,0.02))
		add_child(layer)
		layers.append(layer)

func record_span(record: Dictionary, lane: int, before: float, after: float) -> void:
	var rate: float = record.rates[lane] * Motion.MARKS_PER_SEGMENT
	var first := int(floor(before*rate+0.000001))+1
	var last := int(floor(after*rate+0.000001))
	if last < first: return
	# Even a very large time step only constructs the retained tail.
	first = maxi(first,last-Motion.INK_LIMIT+1)
	for tick in range(first,last+1):
		var p := Motion.offset(record,lane,float(tick)/rate)
		marks[lane].append([p.x,p.y])
	if marks[lane].size()>Motion.INK_LIMIT: marks[lane]=marks[lane].slice(-Motion.INK_LIMIT)
	_refresh(lane)

func clear() -> void:
	marks = [[],[],[],[],[]]
	for lane in layers.size(): _refresh(lane)

func restore(saved: Array) -> void:
	marks = saved.duplicate(true)
	# JSON numbers use doubles; restore the actual 32-bit vector coordinates.
	for row in marks:
		for i in row.size():
			var p := Vector2(row[i][0],row[i][1])
			row[i] = [p.x,p.y]
	for lane in layers.size(): _refresh(lane)

func _refresh(lane: int) -> void:
	if layers.is_empty(): return # Numerical checks can run without a renderer.
	var mesh := layers[lane].multimesh
	for i in marks[lane].size():
		var p: Array = marks[lane][i]
		mesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(p[0],p[1],0)))
	mesh.visible_instance_count = marks[lane].size()
```

### experiment_notebook.gd

<!-- student-code:experiment_notebook.gd -->

```gdscript
extends Node
## Attach only to the reconstructed abacus. No extra museum controls.
@export var condition := "baseline-row-2"
@export_multiline var question := "What changes when the same path moves twice as fast?"
@export_multiline var prediction := "Same positions and ink after equal numbers of steps; a different pace."
@export_multiline var observation := ""
@export_multiline var next_change := ""
@export var load_path := ""
@onready var abacus = get_parent()

func _ready() -> void:
	print("Notebook: Ctrl+Shift+K save; Ctrl+Shift+L load; Ctrl+Shift+P pause/resume.")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not event.ctrl_pressed or not event.shift_pressed: return
	match event.keycode:
		KEY_K: save_trial()
		KEY_L: load_trial()
		KEY_P: abacus.act(1)
		_: return
	get_viewport().set_input_as_handled()

func save_trial() -> String:
	var snapshot: Dictionary = abacus.capture()
	var entry := {
		"schema":"abacus-notebook/1",
		"created_utc":Time.get_datetime_string_from_system(true),
		"engine":Engine.get_version_info().string,
		"condition":condition, "question":question, "prediction":prediction,
		"observation":observation, "next_change":next_change,
		"record":snapshot,
		# Godot's JSON number parser can round decimals; retain exact Variant bytes too.
		"record_bytes":Marshalls.raw_to_base64(var_to_bytes(snapshot))
	}
	var stamp := "%d-%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var path := "user://abacus-%s.json" % stamp
	var suffix := 0
	while FileAccess.file_exists(path):
		suffix += 1
		path = "user://abacus-%s-%d.json" % [stamp,suffix]
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Recording not saved: %s" % FileAccess.get_open_error())
		return ""
	file.store_string(JSON.stringify(entry,"\t",true,true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_error("Recording write failed: %s" % error)
		return ""
	load_path = path
	print("Saved: ",ProjectSettings.globalize_path(path))
	return path

func load_trial() -> bool:
	if not FileAccess.file_exists(load_path):
		push_warning("Set load_path to an existing notebook JSON file.")
		return false
	var entry = JSON.parse_string(FileAccess.get_file_as_string(load_path))
	if not entry is Dictionary or entry.get("schema") != "abacus-notebook/1":
		push_warning("This is not an abacus notebook recording.")
		return false
	if not entry.get("record_bytes") is String:
		push_warning("Recording has no packed state.")
		return false
	var snapshot = bytes_to_var(Marshalls.base64_to_raw(entry.record_bytes))
	if not snapshot is Dictionary or not abacus.restore(snapshot):
		push_warning("Load refused: release all held instruments and check the record recipe.")
		return false
	for field in ["condition","question","prediction","observation","next_change"]:
		set(field,str(entry.get(field,"")))
	print("Restored paused: ",condition,". Ctrl+Shift+P resumes; REPLAY starts again.")
	return true
```

## What counts as learning here

Check release and scene removal separately: normal tracking returns, and the head, body, controller and other hand stay unchanged. Those are interaction checks; headset comfort and an independent reconstruction still need observations.

The experiment earns another round through an observable difference, a meaningful question, or a reason to rebuild its apparatus. A mismatch between felt pace and matching ink is a candidate, not a required discovery. Either this tutorial or the final text can propose the next experiment; carry the resulting observation back to both.

The **48-value seed bench remains the first research pilot**: its 48 scalar values become colour, bars, size and rotation. This abacus lesson uses 48 coordinate pairs and does not replace that pilot. At RAND, compare holding one group of digits with retaining this movement record. The [colour-grid reconstruction](seed-picture-extension.md) remains optional. Carry explicit samples and their recording conditions into [Random Entropy](../Random_Entropy/tutorial.md).

<!-- @ -->
