extends Node
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
## One kept seed, separate generators for colours and travel. Opt-in per hall.
const RACK = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const STAGE = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const FRAME_COUNT := 120
const NAMES := {"fixed":"CHOSEN NUMBER","movement":"HAND RECORDING","clock":"CLOCK SNAPSHOT",
	"frame":"FRAME INTERVALS","system":"SYSTEM RANDOM","atmosphere":"SAVED ATMOSPHERE"}
var bench: Node3D
var ride: Node3D
var bank: Dictionary = {}
var selected := "atmosphere"
var console: Node3D
var panel: Node3D
var source_label: Label3D
var details: Label3D
var source_buttons: Dictionary = {}
var jitter_scope: Node3D
var _frames: Array = []
var _frame_previous := -1
var _frame_recording := false
var _scanning := false

func _ready() -> void:
	bench = get_parent()
	bank["fixed"] = {"seed":435 if HallSeed.enabled(self) else 42,"provider":"fixed","label":"Chosen number"}
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://algorithms/randomness/seed_replay/opening_seed.json"))
	if saved is Dictionary: bank["atmosphere"] = saved.duplicate(true)
	bench.seed_selected.connect(_seed_selected)
	bench.sequence_replayed.connect(_replay)
	bench._movement_sampler.started.connect(_movement_started)
	get_tree().node_added.connect(_node_added)
	set_process(false)
	_schedule_link()

func _node_added(_node: Node) -> void:
	if not is_instance_valid(ride): _schedule_link()

func _schedule_link() -> void:
	if _scanning: return
	_scanning = true
	_link.call_deferred()

func _link() -> void:
	_scanning = false
	for candidate in get_tree().get_nodes_in_group("ada_seed_journeys"):
		if HallSeed.enabled(self) and HallSeed.scope(bench) != HallSeed.scope(candidate): continue
		if candidate.route_link == bench.route_link:
			ride = candidate
			ride.coordinator = self
			_build_console()
			_seed_selected(bench.current_seed(),bench._source_receipt)
			_place_sampler.call_deferred()
			return

func _place_sampler() -> void:
	if not is_instance_valid(ride): return
	# Keep ownership/visit persistence at the bench, but put the hand instrument
	# beside the journey controls so the visitor can compare without crossing the room.
	var sampler: Node3D = bench._movement_sampler
	apply_part_layout()
	sampler.point.transform = Transform3D(Basis.IDENTITY,sampler.HOME)
	for node in sampler.get_children():
		if node is Label3D and node.text == "MOVE / KEEP":
			node.text="YOU MOVE THIS SPHERE"
			node.font_size=38

func apply_part_layout() -> void:
	if not is_instance_valid(ride): return
	bench.EDITOR_PARTS.place(bench, bench._movement_sampler, "movement_sampler",
		ride.global_transform * Transform3D(Basis.IDENTITY, Vector3(-1.85, 0, 2.6)))
	if is_instance_valid(console):
		bench.EDITOR_PARTS.place(bench, console, "source_console",
			ride.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.25, 0, 2.9)))
	if is_instance_valid(jitter_scope):
		bench.EDITOR_PARTS.place(bench, jitter_scope, "frame_timing",
			ride.global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-12)), Vector3(2.9, 0, 2.45)))

func _build_console() -> void:
	if is_instance_valid(panel): return
	console = Node3D.new()
	console.name = "SourceConsole"
	console.position = Vector3(0.25, 0, 2.9)
	ride.add_child(console)
	var rows := [
		[{"type":"button","label":"NUMBER","shape":"rect"},{"type":"button","label":"HAND","shape":"rect"},{"type":"button","label":"CLOCK","shape":"rect"}],
		[{"type":"button","label":"FRAMES","shape":"rect"},{"type":"button","label":"SYSTEM","shape":"rect"},{"type":"button","label":"AIR","shape":"rect"}],
		[{"type":"button","label":"NEW SAMPLE","shape":"rect"},{"type":"button","label":"REPLAY","shape":"rect"}]]
	if HallSeed.enabled(self):
		rows = [[{"type":"button","label":"NUMBER","shape":"rect"},{"type":"button","label":"HAND","shape":"rect"}],
			[{"type":"button","label":"RESET 435","shape":"rect"},{"type":"button","label":"REPLAY","shape":"rect"}]]
	panel = RACK.create_panel("CHOOSE A SOURCE",rows)
	panel.name = "JourneySources"
	panel.set_meta("em_local_instrument",true)
	panel.position = Vector3(0,1.05,0)
	panel.rotation_degrees.x = -25
	panel.scale = Vector3.ONE*3.2
	console.add_child(panel)
	var kinds := ["fixed","movement","clock","frame","system","atmosphere"]
	if HallSeed.enabled(self): kinds = ["fixed","movement","atmosphere"]
	for i in range(kinds.size()):
		var kind: String = kinds[i]
		var button: Node = panel.find_child("Btn_"+str(i),true,false)
		source_buttons[kind] = button
		button.pressed.connect(select_source.bind(kind))
	if HallSeed.enabled(self):
		panel.find_child("Btn_3",true,false).pressed.connect(bench.replay)
	else:
		panel.find_child("Btn_6",true,false).pressed.connect(resample)
		panel.find_child("Btn_7",true,false).pressed.connect(bench.replay)
	bench._contrast_panel(panel)
	bench._contrast_panel.call_deferred(panel)
	STAGE.box(console,Vector3(0,0.46,0),Vector3(0.3,0.92,0.3),Color("263039"),true)
	STAGE.box(console,Vector3(0,2.05,-0.08),Vector3(2.55,0.92,0.06),Color("131e25"))
	source_label = STAGE.label(console,"",Vector3(0,2.28,-0.04))
	source_label.pixel_size=0.0014;source_label.font_size=36;source_label.outline_size=0
	details = STAGE.label(console,"",Vector3(0,1.97,-0.04))
	details.pixel_size=0.0015;details.font_size=28;details.outline_size=0
	jitter_scope = load("res://algorithms/randomness/seed_replay/frame_jitter_scope.gd").new()
	jitter_scope.position = Vector3(2.9,0,2.45)
	jitter_scope.rotation_degrees.y = -12
	ride.add_child(jitter_scope)
	# Include the side instrument in the linked exhibit's culling bounds.
	var bounds: AABB = ride.get_meta("em_visibility_bounds")
	ride.set_meta("em_visibility_bounds",bounds.merge(AABB(Vector3(1.5,0,2.0),Vector3(2.9,2.9,1.2))))
	bench._contrast_panel(jitter_scope.controls)
	bench._contrast_panel.call_deferred(jitter_scope.controls)
	_update_label("")

func source_kind(receipt: Dictionary) -> String:
	match str(receipt.get("provider","")):
		"movement": return "movement"
		"clock": return "clock"
		"frame": return "frame"
		"system": return "system"
		"RANDOM.ORG": return "atmosphere"
	return "fixed"

func _seed_selected(value: int, receipt: Dictionary) -> void:
	_stop_frames()
	selected = source_kind(receipt)
	var kept := receipt.duplicate(true)
	kept["seed"] = value
	if kept.get("provider","") == "":
		kept["provider"]="fixed";kept["label"]="Chosen number"
	bank[selected] = kept
	if selected=="movement": bench._movement_sampler.show_kept_recording(kept)
	if selected=="frame" and is_instance_valid(jitter_scope): jitter_scope.show_kept(kept)
	if is_instance_valid(ride) and not HallSeed.enabled(self): ride.keep_seed(value,NAMES[selected])
	_update_label("")

func _replay() -> void:
	_stop_frames()
	bench._seed_revision += 1
	if bench._movement_sampler.collecting:
		bench._movement_sampler.cancel_capture("REPLAY kept the previous seed.")
	selected=source_kind(bench._source_receipt)
	if selected=="frame" and is_instance_valid(jitter_scope): jitter_scope.show_kept(bench._source_receipt)
	if is_instance_valid(ride) and not HallSeed.enabled(self): ride.keep_seed(bench.current_seed(),NAMES[source_kind(bench._source_receipt)])
	_update_label("")

func select_source(kind: String) -> void:
	if HallSeed.enabled(self) and kind not in ["fixed","movement","atmosphere"]: return
	if not NAMES.has(kind): return
	_stop_frames()
	if bench._movement_sampler.collecting:
		bench._movement_sampler.cancel_capture("Source changed; previous recording kept.")
	# Switching away invalidates any pending atmospheric request as well.
	bench._seed_revision += 1
	selected = kind
	if bank.has(kind):
		bench.use_kept_seed(int(bank[kind].seed),bank[kind])
	elif kind == "movement":
		_update_label("Hold, move, release the sphere on the stand.\nThe current journey keeps its seed until release.")
	else:
		resample()

func resample() -> void:
	if HallSeed.enabled(self):
		_update_label("Choose a number at the window, or record a gesture.\nRESET 435 recalls the saved opening.")
		return
	_stop_frames()
	if bench._movement_sampler.collecting:
		_update_label("Release the sampling sphere first.")
		return
	match selected:
		"movement":
			_update_label("Hold, move, release the sphere on the stand.\nAt least 30 changing pose samples.")
		"fixed":
			_update_label("NUMBER recalls your last chosen seed.\nChange it with SEED on the colour bench.")
		"clock":
			keep_clock(Time.get_ticks_msec())
		"system":
			var bytes := Crypto.new().generate_random_bytes(4)
			if bytes.size()!=4:
				_update_label("System source unavailable; previous seed kept.")
				return
			var value := int(bytes.decode_u32(0))
			bench.use_kept_seed(value%1000,{"provider":"system","seed":value%1000,"label":"System random bytes",
				"raw_u32":value,"recipe":"crypto-4-bytes-mod1000","recorded":true})
		"atmosphere":
			# AIR itself recalls the saved draw offline. Only this explicit action asks online.
			if not bench.request_atmospheric_seed():
				_update_label("No new atmospheric draw; kept seed remains.\nAIR recalls the saved draw offline.")
			else: _update_label("Requesting a new atmospheric number…")
		"frame":
			bench._seed_revision += 1
			if is_instance_valid(jitter_scope): jitter_scope.begin_recording()
			# Anchor at the next callback, so a partial button-to-frame interval
			# cannot masquerade as the first whole application frame.
			_frame_previous = -1
			_frame_recording = true
			set_process(true)
			_update_label("Recording 120 application frame intervals…\nTiming variation is not proof of randomness.")

func keep_clock(milliseconds: int) -> void:
	if HallSeed.enabled(self): return
	bench.use_kept_seed(milliseconds%1000,{"provider":"clock","seed":milliseconds%1000,"label":"Clock snapshot",
		"elapsed_msec":milliseconds,"recipe":"elapsed-milliseconds-mod1000","recorded":true})

func _process(_delta: float) -> void:
	record_frame(Time.get_ticks_usec())

func record_frame(now: int) -> void:
	if HallSeed.enabled(self): return
	if not _frame_recording: return
	if _frame_previous < 0:
		_frame_previous=now
		return
	var interval := now-_frame_previous
	if interval <= 0: return
	_frame_previous = now
	_frames.append(interval)
	if is_instance_valid(jitter_scope): jitter_scope.record_interval(interval)
	if _frames.size() < FRAME_COUNT:
		_update_label("Frame intervals: %d / %d\nTiming variation is not proof of randomness." % [_frames.size(),FRAME_COUNT])
		return
	var words := PackedStringArray()
	for value in _frames: words.append(str(int(value)))
	var digest := ("frame-intervals-v1\n"+",".join(words)).sha256_buffer()
	var value: int = int(digest.decode_u32(0)%1000)
	var receipt := {"provider":"frame","seed":value,"label":"Application frame intervals",
		"intervals_usec":_frames.duplicate(),"sample_count":_frames.size(),"recipe":"frame-intervals-v1",
		"sha256":digest.hex_encode(),"recorded":true}
	_stop_frames()
	bench.use_kept_seed(value,receipt)

func _stop_frames() -> void:
	set_process(false)
	if is_instance_valid(jitter_scope): jitter_scope.cancel_recording()
	_frames.clear()
	_frame_previous=-1
	_frame_recording=false

func _movement_started() -> void:
	_stop_frames()
	selected="movement"
	_update_label("Recording your gesture. Release to keep it.")

func _update_label(message: String) -> void:
	if not is_instance_valid(source_label): return
	var active := source_kind(bench._source_receipt)
	source_label.text = "%s  ·  %d" % [NAMES[active],bench.current_seed()]
	if not message.is_empty(): details.text=message;return
	match active:
		"movement": details.text="Pose + timing → SHA-256 → seed 0–999\nREPLAY repeats destinations; it does not repeat your gesture."
		"clock": details.text="%d ms %% 1000 = %d\nA cycling clock, captured at a moment." % [int(bench._source_receipt.get("elapsed_msec",0)),bench.current_seed()]
		"frame": details.text="120 measured frame intervals → hash → seed\nIrregular timing; entropy has not been measured."
		"system": details.text="4 system random bytes → seed 0–999\nKept for replay. No network request."
		"atmosphere": details.text="Saved opening: 435. No fresh draw on arrival.\nREPLAY restarts the hall from its chosen seed." if HallSeed.enabled(self) else "Kept atmospheric draw. AIR recalls it offline.\nNEW SAMPLE asks RANDOM.ORG again."
		_: details.text="A number can be chosen without being random.\nSame seed + same requests → same destinations."

func capture_state() -> Dictionary:
	return {"bank":bank.duplicate(true),"selected":selected}

func restore_state(saved: Dictionary) -> void:
	_stop_frames()
	for kind in saved.get("bank",{}):
		if NAMES.has(kind) and saved.bank[kind] is Dictionary:
			if HallSeed.enabled(self) and not HallSeed.allowed(int(saved.bank[kind].get("seed",-1)),saved.bank[kind]): continue
			bank[kind]=saved.bank[kind].duplicate(true)
	selected=str(saved.get("selected","atmosphere"))

