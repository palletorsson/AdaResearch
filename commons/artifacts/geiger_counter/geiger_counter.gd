extends Node3D
## HotBits-inspired timing study. Every event here is simulated and recorded.
const MODEL = preload("res://commons/artifacts/geiger_counter/geiger_model.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const STAGE = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const RACK = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const DIAL_SWEEP := 65.0 * PI / 180.0
const DIAL_RADIUS := 0.25
const DIAL_MAX_RATE := 12.0
var dial_marks: Array[MeshInstance3D] = []
var current: Dictionary = {}
var baseline: Dictionary = {}
var kept: Dictionary = {}
var kept_baseline: Dictionary = {}
var record_directory := "user://geiger_counter"
var saved_path := ""
var sound_on := true
var _audio: AudioStreamPlayer3D
var _board: Node3D
var _screen: Label3D
var _comparison: Label3D
var _pair_label: Label3D
var _led: MeshInstance3D
var _needle: Node3D
var _cursor: MeshInstance3D
var _timeline: Node3D
var _bits: Array[MeshInstance3D] = []
var _progress := 0.0
var _count := 0
var _playback_started := false
var _last_text_tick := -1
var _message := "Continuous replay of 96 simulated detections."

func _ready() -> void:
	set_meta("em_keep_scale",true)
	set_meta("em_visibility_bounds",AABB(Vector3(-1.4,0,-0.3),Vector3(2.8,3.1,0.75)))
	_build()
	_audio = AudioStreamPlayer3D.new(); _audio.name = "RecordedClicks"
	_audio.position=Vector3(0,2.20,0.1); _audio.volume_db=-12; _audio.unit_size=2.0; _audio.max_distance=6.0
	add_child(_audio)
	_audio.finished.connect(_finished)
	reset_model()
	HallSeed.bind(self)

func _apply_hall_seed(value: int, receipt: Dictionary) -> void:
	var rate := int(current.get("rate_per_second",4))
	var resolution := int(current.get("clock_us",1000))
	_set_record(MODEL.make_record(value,rate,resolution,{"provider":"chosen_seed","label":"HALL SEED / SIMULATION","hall_receipt":receipt}))
	baseline = current.duplicate(true)
	_message = "Same hall seed; independent sequence of 96 detections."
	_refresh_text()

func reset_model() -> void:
	if HallSeed.enabled(self) and not current.is_empty():
		HallSeed.reset(self); return
	_set_record(MODEL.make_record(435,4,1000,{"provider":"chosen_seed","label":"SEEDED SIMULATION"}))
	baseline=current.duplicate(true)
	_message="Continuous replay of 96 simulated detections."
	_refresh_text()

func _set_record(record: Dictionary) -> void:
	_audio.stop(); _audio.stream_paused=false; _playback_started=false; _progress=0.0; _count=0; _last_text_tick=-1
	current=record.duplicate(true)
	_audio.stream=MODEL.waveform(current.events_us)
	for child in _timeline.get_children():
		_timeline.remove_child(child); child.queue_free()
	var duration := float(current.events_us[-1])/1000000.0
	for stamp in current.events_us:
		var x := -1.02+float(stamp)/1000000.0/duration*2.04
		STAGE.box(_timeline,Vector3(x,0,0),Vector3(0.006,0.07,0.008),Color("71f2be"))
	for i in range(_bits.size()):
		var bit := int(current.pairs[i].bit)
		_bits[i].material_override.albedo_color = Color("f6ba5d") if bit==1 else (Color("63d7d0") if bit==0 else Color("8e8294"))
	_refresh_visuals(0.0)
	_playback_started=true
	_audio.play(0.0)

func play_hold() -> void:
	# Compatibility for existing callers: the machine now always runs.
	restart()

func restart() -> void:
	_audio.stop(); _audio.stream_paused=false; _playback_started=true; _audio.play(0.0)
	_message="Same event times and sound, from the beginning."; _refresh_text()

func toggle_sound() -> void:
	sound_on=not sound_on
	_audio.volume_db=-12 if sound_on else -80
	_message="Sound on." if sound_on else "Muted. Event timing and extracted bits are unchanged."
	_refresh_text()

func new_sample() -> void:
	if HallSeed.enabled(self):
		HallSeed.next(self); return
	var bytes := Crypto.new().generate_random_bytes(4)
	if bytes.size()!=4:
		_message="System seed unavailable; previous trace retained."; _refresh_text(); return
	var seed_value := int(bytes.decode_u32(0) % (MODEL.MODULUS-1))+1
	_set_record(MODEL.make_record(seed_value,int(baseline.rate_per_second),int(baseline.clock_us),
		{"provider":"system_seed","label":"SYSTEM-SEEDED SIMULATION","bytes_hex":bytes.hex_encode()}))
	_message="New seed; baseline rate and clock held. No radioactive source is connected."; _refresh_text()

func compare_rate() -> void:
	var rate := 8 if int(baseline.rate_per_second)==4 else 4
	_set_record(MODEL.make_record(int(baseline.seed),rate,int(baseline.clock_us),baseline.source))
	_message="Rate changed; same PRNG draws and clock. Listen to the changed rhythm."; _refresh_text()

func compare_clock() -> void:
	var resolution := 100000 if int(baseline.clock_us)==1000 else 1000
	_set_record(MODEL.make_record(int(baseline.seed),int(baseline.rate_per_second),resolution,baseline.source))
	_message="Clock changed; identical clicks. Equal measured intervals are skipped."; _refresh_text()

func keep_baseline() -> void:
	baseline=current.duplicate(true)
	_message="Current trace is the comparison baseline."; _refresh_text()

func keep() -> bool:
	if not MODEL.valid(current) or not MODEL.valid(baseline): return false
	if DirAccess.make_dir_recursive_absolute(record_directory)!=OK: return _save_error()
	var path := "%s/%s-%012d.json" % [record_directory,Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return _save_error()
	file.store_string(JSON.stringify({"schema":"ada-geiger-comparison-1","baseline":baseline,"capture":current},"\t",true,true)); file.close()
	kept=current.duplicate(true); kept_baseline=baseline.duplicate(true); saved_path=path
	_message="Comparison saved. REPLAY restores it; LOAD finds the latest saved pair."; _refresh_text()
	return true

func _save_error() -> bool:
	_message="Could not save the record; previous kept result retained."; _refresh_text(); return false

func replay() -> bool:
	if not MODEL.valid(kept) or not MODEL.valid(kept_baseline):
		_message="KEEP a comparison first, or LOAD one from disk."; _refresh_text(); return false
	if HallSeed.enabled(self) and int(kept.seed) != int(kept_baseline.seed):
		_message="This older comparison uses two seeds. Keep a comparison within one hall seed."; _refresh_text(); return false
	if HallSeed.enabled(self) and not HallSeed.choose(self,int(kept.seed),kept.source.get("hall_receipt",{"provider":"saved_record","label":"Kept Geiger trace","seed":int(kept.seed)}),true): return false
	baseline=kept_baseline.duplicate(true)
	_set_record(kept); restart()
	_message="Replaying kept event times; no source resampled."; _refresh_text()
	return true

func load_latest() -> bool:
	if DirAccess.dir_exists_absolute(record_directory):
		var names := DirAccess.get_files_at(record_directory); names.sort()
		for i in range(names.size()-1,-1,-1):
			if not names[i].ends_with(".json"): continue
			var path := record_directory+"/"+names[i]
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary and data.get("schema")=="ada-geiger-comparison-1" \
				and data.get("baseline") is Dictionary and data.get("capture") is Dictionary \
				and MODEL.valid(data.baseline) and MODEL.valid(data.capture):
				kept=data.capture; kept_baseline=data.baseline; saved_path=path
				return replay()
	_message="No valid saved comparison found."; _refresh_text(); return false

func _process(_delta: float) -> void:
	if not _audio.playing or _audio.stream_paused: return
	var seconds := maxf(0.0,_audio.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
	_refresh_visuals(seconds)

func _finished() -> void:
	# Repeating a stored record is not a fresh random-source event.
	_audio.stream_paused=false; _playback_started=true; _audio.play(0.0)
	_refresh_visuals(0.0)
	_message="Looping the same 96 detections. SEED +1 chooses another beginning." if HallSeed.enabled(self) else "Looping the same 96 detections. NEW selects another simulated trace."
	_refresh_text()

func _refresh_visuals(seconds: float) -> void:
	_progress=seconds; _count=0
	var recent := 0
	var last := -1.0
	for stamp in current.events_us:
		var when := float(stamp)/1000000.0
		if when>seconds: break
		_count+=1; last=when
		if when>seconds-2.0: recent+=1
	_led.material_override.emission_energy_multiplier=2.0 if last>=0 and seconds-last<0.07 else 0.03
	_needle.rotation.z = dial_angle(recent / 2.0)
	_cursor.position.x = -1.02+clampf(seconds/(float(current.events_us[-1])/1000000.0),0,1)*2.04
	@warning_ignore("integer_division")
	var pair_index := clampi((_count-1)/4,0,23)
	var pair: Dictionary = current.pairs[pair_index]
	_pair_label.text="Recorded pair %02d: T1 %d ms / T2 %d ms > %s%s" % [pair_index+1,int(pair.t1)*int(current.clock_us)/1000,
		int(pair.t2)*int(current.clock_us)/1000,"SKIP" if int(pair.bit)<0 else str(int(pair.bit))," (reversed rule)" if pair.reverse else ""]
	if int(seconds*10)!=_last_text_tick:
		_last_text_tick=int(seconds*10); _refresh_text()

func _refresh_text() -> void:
	if current.is_empty() or baseline.is_empty(): return
	_screen.text="%s\nseed %d / mean %d events per second / clock %d ms\n%02d / 96 detections played | %.1f s | %s\n%s" % [
		current.source.label,int(current.seed),int(current.rate_per_second),int(current.clock_us)/1000,_count,_progress,
		"SOUND ON" if sound_on else "MUTED",_message]
	_comparison.text="BASELINE  %s\nCURRENT   %s\n0 = cyan   1 = amber   - = tied intervals, skipped" % [MODEL.bit_string(baseline),MODEL.bit_string(current)]

func _label(words: String, position_value: Vector3, font: int=26, pixel: float=0.0015) -> Label3D:
	var label := STAGE.label(self,words,position_value); label.font_size=font; label.pixel_size=pixel; label.outline_size=2
	return label

## Both marks and needle use this radian sweep: zero at left, 12 events/s at right.
static func dial_angle(rate: float) -> float:
	return lerpf(DIAL_SWEEP, -DIAL_SWEEP, clampf(rate / DIAL_MAX_RATE, 0.0, 1.0))

func capture_book_state() -> Dictionary:
	return {"record":current.duplicate(true),"seconds":_progress,"detections_played":_count,
		"needle_radians":_needle.rotation.z,"sound_on":sound_on}

func _build() -> void:
	var cabinet := STAGE.box(self,Vector3(0,1.5,-0.16),Vector3(2.6,3.0,0.20),Color("233c3d"),true)
	cabinet.name="MachineCabinet"
	cabinet.set_meta("book_capture_omit", true)
	for x in [-1.34,1.34]:
		var rail := STAGE.box(self,Vector3(x,1.5,-0.13),Vector3(0.08,3.04,0.30),Color("d4a75b"),true)
		rail.name="CabinetRail"
		rail.set_meta("book_capture_omit", true)
	_label("HOTBITS / COUNTING THE GAPS",Vector3(0,2.37,0),35)
	_label("Geiger-style simulation / continuous recorded clicks",Vector3(0,2.24,0),25)
	# Tube and an electronic pulse lamp: audio is a representation of detection.
	STAGE.box(self,Vector3(-0.58,1.99,0.06),Vector3(0.95,0.24,0.14),Color("131d22"))
	for i in range(13): STAGE.box(self,Vector3(-1.00+i*0.07,1.99,0.15),Vector3(0.018,0.19,0.01),Color("9aabac"))
	STAGE.box(self,Vector3(-0.58,1.99,0.17),Vector3(0.90,0.012,0.012),Color("f0b95b"))
	_led=STAGE.box(self,Vector3(-0.03,2.00,0.12),Vector3(0.06,0.06,0.035),Color("ff6655"))
	_led.material_override.emission_enabled=true; _led.material_override.emission=Color("ff513c")
	STAGE.box(self,Vector3(0.62,2.02,0.02),Vector3(0.88,0.38,0.10),Color("ddd6bd"))
	_needle=Node3D.new(); _needle.position=Vector3(0.62,1.91,0.09); add_child(_needle)
	STAGE.box(_needle,Vector3(0,0.105,0),Vector3(0.012,0.21,0.01),Color("bb4a38"))
	for i in range(9):
		var angle := dial_angle(i * DIAL_MAX_RATE / 8.0)
		var radial := Vector3(-sin(angle), cos(angle), 0)
		var mark := STAGE.box(self,_needle.position + radial * DIAL_RADIUS,Vector3(0.008,0.028,0.008),Color("394043"))
		mark.name = "DialMark%d" % i
		mark.rotation.z = angle
		dial_marks.append(mark)
	_label("events / s - last 2 seconds",Vector3(0.62,1.83,0.10),17)
	STAGE.box(self,Vector3(0,1.56,0.01),Vector3(2.2,0.40,0.04),Color("0a181d"))
	_screen=_label("",Vector3(0,1.56,0.04),23,0.00145); _screen.width=1400; _screen.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_timeline=Node3D.new(); _timeline.position=Vector3(0,1.26,0.07); add_child(_timeline)
	_cursor=STAGE.box(self,Vector3(-1.02,1.26,0.09),Vector3(0.012,0.10,0.014),Color("ffffff"))
	_pair_label=_label("",Vector3(0,1.13,0.06),23)
	for i in range(24): _bits.append(STAGE.box(self,Vector3(-1.02+i*2.04/23,0.98,0.06),Vector3(0.07,0.09,0.018),Color("63d7d0")))
	_comparison=_label("",Vector3(0,0.76,0.04),23)
	# Lift the instruments to leave a built-in control bay below the comparison.
	for child in get_children():
		if child is Node3D and child != cabinet and not str(child.name).begins_with("CabinetRail"):
			child.position.y += 0.45
	_label("SIMULATED EVENTS / four pulses > two gaps > one bit",Vector3(0,0.13,0.03),21)
	_board=RACK.create_panel("",[
		[{"type":"button","label":"RESTART","shape":"rect"},{"type":"button","label":"SEED +1" if HallSeed.enabled(self) else "NEW","shape":"rect"},{"type":"button","label":"SOUND","shape":"rect"},{"type":"button","label":"RATE","shape":"rect"},{"type":"button","label":"CLOCK","shape":"rect"}],
		[{"type":"button","label":"BASELINE","shape":"rect"},{"type":"button","label":"RESET 435","shape":"rect"},{"type":"button","label":"KEEP","shape":"rect"},{"type":"button","label":"REPLAY","shape":"rect"},{"type":"button","label":"LOAD","shape":"rect"}]],true)
	_board.name="GeigerControls"
	_board.set_meta("book_capture_omit", true)
	_board.position=Vector3(0,0.65,0.09); _board.scale=Vector3.ONE*3.6
	add_child(_board)
	for label in _board.find_children("*","Label3D",true,false): label.outline_size=0
	STAGE.box(self,Vector3(0,0.65,0.01),Vector3(1.55,0.79,0.07),Color("c4cabc"))
	var actions := [restart,new_sample,toggle_sound,compare_rate,compare_clock,keep_baseline,reset_model,keep,replay,load_latest]
	for i in range(actions.size()): _board.find_child("Btn_%d" % i,true,false).pressed.connect(actions[i])
