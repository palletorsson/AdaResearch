extends Node3D
## A repeatable virtual wall inspired by Cloudflare's physical LavaRand installation.
const MODEL = preload("res://commons/artifacts/lava_entropy_wall/lava_model.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const STAGE = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const RACK = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const COLORS := [Color("ff566e"),Color("93ef63"),Color("ffba45"),Color("43dfda"),Color("d687ff"),Color("ff794b")]
const SAVE_DIR := "user://lava_entropy_wall"
@export var model_seed := 435
var record_directory := SAVE_DIR
var frame := 300
var heat := 100
var covered := false
var running := true
var source := {"provider":"chosen_model_seed","label":"CHOSEN SEED"}
var baseline: Dictionary = {}
var current: Dictionary = {}
var kept: Dictionary = {}
var kept_baseline: Dictionary = {}
var save_path := ""
var _elapsed := 0.0
var _blobs: Array[MeshInstance3D] = []
var _photos: Array[MeshInstance3D] = []
var _bars: Array = []
var _hash_labels: Array[Label3D] = []
var _status: Label3D
var _board: Node3D
var _shutter: MeshInstance3D
var _message := "CAPTURE a baseline; then HEAT + or COVER."

func apply_grid_config(config: Dictionary) -> void:
	if config.has("hall_seed"): set_meta("config_hall_seed",config.hall_seed)
	if is_node_ready() and HallSeed.enabled(self): return # Layout edits do not reseed the room.
	if config.has("seed"): model_seed = clampi(int(config.seed),1,MODEL.MODULUS-1)
	if is_node_ready() and config.has("seed"): reset_model()

func _ready() -> void:
	set_meta("em_keep_scale",true)
	set_meta("em_visibility_bounds",AABB(Vector3(-1.92,0,-0.4),Vector3(3.84,3.4,0.9)))
	_build_wall()
	_build_board()
	current = MODEL.capture(model_seed,frame,heat,covered,source)
	baseline = current.duplicate(true)
	_paint_record(0,baseline)
	_paint_record(1,current)
	_refresh_lamps()
	_refresh_status()
	HallSeed.bind(self)

func _apply_hall_seed(value: int, receipt: Dictionary) -> void:
	model_seed = value
	source = {"provider":"chosen_model_seed","label":"HALL SEED","hall_receipt":receipt}
	current = MODEL.capture(model_seed,frame,heat,covered,source)
	baseline = current.duplicate(true)
	_paint_record(0,baseline)
	_paint_record(1,current)
	_refresh_lamps()
	_refresh_status()

func _physics_process(delta: float) -> void:
	if not running: return
	_elapsed += delta
	if _elapsed < 1.0 / 30.0: return
	var steps := int(_elapsed * 30.0)
	_elapsed -= steps / 30.0
	frame += steps
	_refresh_lamps()

func capture_baseline() -> void:
	running = false
	current = MODEL.capture(model_seed,frame,heat,covered,source)
	baseline = current.duplicate(true)
	_paint_record(0,baseline)
	_paint_record(1,current)
	_message = "Baseline held. HEAT + or COVER changes one condition."
	_refresh_status()

func compare_heat() -> void:
	_restore_configuration(baseline)
	heat = mini(200,int(baseline.heat)+10)
	if heat == int(baseline.heat):
		_compare("Heat is at its limit. RESET 435 starts another comparison."); return
	_compare("Changed heat only; seed, tick and shutter held.")

func compare_cover() -> void:
	_restore_configuration(baseline)
	covered = not bool(baseline.covered)
	_compare("Changed the sensor cover only; lamps unchanged.")

func _compare(message: String) -> void:
	current = MODEL.capture(model_seed,frame,heat,covered,source)
	_paint_record(1,current)
	_refresh_lamps()
	_message = message
	_refresh_status()

func toggle_run() -> void:
	running = not running
	_message = "Lamps moving. CAPTURE holds a new baseline." if running else "Lamps held. CAPTURE records this tick."
	_refresh_status()

func keep_current() -> bool:
	# Save the displayed capture, never substitute an uncaptured live frame.
	if not MODEL.valid(current): return false
	if DirAccess.make_dir_recursive_absolute(record_directory) != OK:
		_message = "Could not create the record folder."; _refresh_status(); return false
	var stem := "%s/%s-%012d-%s" % [record_directory,Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_msec(),current.sha256.left(12)]
	var path := stem + ".json"
	var suffix := 1
	while FileAccess.file_exists(path):
		path = stem + "-%d.json" % suffix
		suffix += 1
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		_message = "Could not write the record."; _refresh_status(); return false
	file.store_string(JSON.stringify({"schema":"ada-lava-comparison-1","baseline":baseline,"capture":current},"\t",true,true))
	file.close()
	kept = current.duplicate(true)
	kept_baseline = baseline.duplicate(true)
	save_path = path
	_message = "Kept capture on disk. REPLAY restores it; LOAD finds the latest."
	_refresh_status()
	return true

func replay_kept() -> bool:
	if kept.is_empty():
		_message = "KEEP a capture first, or LOAD a previous record."; _refresh_status(); return false
	if HallSeed.enabled(self) and int(kept_baseline.get("seed",kept.seed)) != int(kept.seed):
		_message = "This older comparison has two seeds. Replay one capture as a new baseline."; _refresh_status(); return false
	if not replay_record(kept): return false
	if MODEL.valid(kept_baseline):
		baseline = kept_baseline.duplicate(true); _paint_record(0,baseline)
	return true

func replay_record(record: Dictionary) -> bool:
	if not MODEL.valid(record):
		_message = "Record rejected: version, state or sample does not match."; _refresh_status(); return false
	if HallSeed.enabled(self) and not HallSeed.choose(self,int(record.seed),record.source.get("hall_receipt",{"provider":"saved_record","label":"Kept lamp capture","seed":int(record.seed)}),true): return false
	current = record.duplicate(true)
	if HallSeed.enabled(self) and int(baseline.get("seed",-1)) != int(record.seed):
		baseline = current.duplicate(true)
		_paint_record(0,baseline)
	_restore_configuration(current)
	_paint_record(1,current)
	_refresh_lamps()
	_message = "Stored observation replayed. No new source was sampled."
	_refresh_status()
	return true

func load_latest() -> bool:
	if not DirAccess.dir_exists_absolute(record_directory):
		_message = "No saved record folder yet. KEEP a capture first."; _refresh_status(); return false
	var names := DirAccess.get_files_at(record_directory)
	names.sort()
	for i in range(names.size()-1,-1,-1):
		if not names[i].ends_with(".json"): continue
		var path := record_directory + "/" + names[i]
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("schema") == "ada-lava-comparison-1" \
			and parsed.get("capture") is Dictionary and parsed.get("baseline") is Dictionary \
			and MODEL.valid(parsed.capture) and MODEL.valid(parsed.baseline):
			kept = parsed.capture.duplicate(true); kept_baseline = parsed.baseline.duplicate(true); save_path = path
			return replay_kept()
	_message = "No valid saved record found."; _refresh_status(); return false

func fresh_system() -> bool:
	if HallSeed.enabled(self): return HallSeed.next(self)
	var bytes := Crypto.new().generate_random_bytes(16)
	if bytes.size() != 16:
		_message = "System random request failed; previous capture retained."; _refresh_status(); return false
	_restore_configuration(baseline)
	model_seed = maxi(1,MODEL.digest(bytes).left(7).hex_to_int())
	source = {"provider":"godot_crypto_random_bytes","label":"SYSTEM RNG INPUT","bytes_hex":bytes.hex_encode(),
		"claim":"External to the lamp model; no measured physical entropy claim. Displayed and saved, not secret."}
	_compare("New system seed; baseline tick and heat held. This is not lamp TRNG.")
	return true

func reset_model() -> void:
	if HallSeed.enabled(self):
		HallSeed.reset(self); return
	model_seed = 435; frame = 300; heat = 100; covered = false; _elapsed = 0.0
	source = {"provider":"chosen_model_seed","label":"CHOSEN SEED"}
	capture_baseline()
	_refresh_lamps()

func _restore_configuration(record: Dictionary) -> void:
	running = false; _elapsed = 0.0
	model_seed = int(record.seed); frame = int(record.tick); heat = int(record.heat)
	covered = bool(record.covered); source = record.source.duplicate(true)

func _refresh_status() -> void:
	var changed := 0
	var a: PackedByteArray = str(baseline.pixels_hex).hex_decode()
	var b: PackedByteArray = str(current.pixels_hex).hex_decode()
	for i in range(a.size()):
		if a[i] != b[i]: changed += 1
	_status.text = "%s  |  seed %d  |  tick %d  |  heat %.2f\n%d / 4608 sensor pixels changed  |  %s\n%s" % [
		str(current.source.label),int(current.seed),int(current.tick),int(current.heat)/100.0,changed,
		"LAMPS LIVE / CAPTURES HELD" if running else "HELD",_message]

func _label(words: String, at: Vector3, size: int = 30, pixel: float = 0.0017) -> Label3D:
	var label := STAGE.label(self,words,at)
	label.font_size = size; label.pixel_size = pixel; label.outline_size = 3
	return label

func _cylinder(at: Vector3, bottom: float, top: float, height: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom; mesh.top_radius = top; mesh.height = height; mesh.radial_segments = 20
	node.mesh = mesh; node.position = at; node.material_override = STAGE.material(color)
	add_child(node)
	return node

func _build_wall() -> void:
	var dark := Color("15232f")
	STAGE.box(self,Vector3(0,1.65,-0.31),Vector3(3.65,3.30,0.10),dark,true)
	for x in [-1.87,1.87]: STAGE.box(self,Vector3(x,1.65,-0.18),Vector3(0.10,3.4,0.40),Color("c48659"),true)
	_label("LAVA / WHAT CAN YOU PREDICT?",Vector3(0,3.19,-0.16),39)
	_label("Virtual lamps: a repeatable model. Physical observations: a different source.",Vector3(0,3.04,-0.16),23)
	for row in range(2):
		var base_y := 1.62 + row * 0.69
		STAGE.box(self,Vector3(0,base_y-0.03,-0.06),Vector3(3.65,0.055,0.52),Color("9d795b"),true)
		for col in range(6):
			var x := (col-2.5)*0.55
			var tint: Color = COLORS[(col+row*2)%6]
			_cylinder(Vector3(x,base_y+0.07,-0.06),0.13,0.075,0.14,Color("a9bac5"))
			_cylinder(Vector3(x,base_y+0.19,-0.06),0.075,0.145,0.10,Color("c0c9d0"))
			_cylinder(Vector3(x,base_y+0.41,-0.06),0.145,0.075,0.36,Color(tint.r,tint.g,tint.b,0.10))
			_cylinder(Vector3(x,base_y+0.62,-0.06),0.075,0.060,0.06,Color("bac4c9"))
			for blob in range(4):
				var node := MeshInstance3D.new()
				var mesh := SphereMesh.new(); mesh.radius = 1.0; mesh.height = 2.0; mesh.radial_segments = 16; mesh.rings = 8
				node.mesh = mesh
				var material := STAGE.material(tint); material.emission_enabled = true; material.emission = tint; material.emission_energy_multiplier = 0.45
				node.material_override = material; add_child(node); _blobs.append(node)
	_shutter = STAGE.box(self,Vector3(-0.85,2.23,0.18),Vector3(1.65,1.38,0.012),Color(0.04,0.06,0.09,0.80))
	_shutter.visible = false
	for slot in range(2):
		var x := -1.17 if slot == 0 else 1.17
		_label("BASELINE" if slot == 0 else "CURRENT CAPTURE",Vector3(x,1.49,0.02),28)
		STAGE.box(self,Vector3(x,1.12,-0.01),Vector3(1.28,0.60,0.06),Color("080f18"))
		var photo := MeshInstance3D.new(); var quad := QuadMesh.new(); quad.size = Vector2(0.63,0.315)
		photo.mesh = quad; photo.position = Vector3(x-0.27,1.14,0.03)
		var material := StandardMaterial3D.new(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		photo.material_override = material; add_child(photo); _photos.append(photo)
		var bars: Array = []
		for i in range(48):
			var bar := STAGE.box(self,Vector3(x+0.11+(i%12)*0.043,0.94+(i/12)*0.105,0.035),Vector3(0.031,0.07,0.02),COLORS[slot*2])
			bars.append(bar)
		_bars.append(bars)
		_label("sensor > SHA-256 > 48 values",Vector3(x,0.85,0.03),22)
		_hash_labels.append(_label("",Vector3(x,0.75,0.03),21))
	_label("Cloudflare LavaRand / simulated lamps and sensor",Vector3(0,0.07,0.03),21)

func _refresh_lamps() -> void:
	var state := MODEL.bodies(model_seed,frame,heat)
	for i in range(state.size()):
		var b: Dictionary = state[i]
		@warning_ignore("integer_division")
		var row := int(b.lamp) / 6
		var col := int(b.lamp) % 6
		_blobs[i].position = Vector3((col-2.5)*0.55+int(b.x)*0.00065,1.85+row*0.69+int(b.y)*0.00036,-0.04)
		_blobs[i].scale = Vector3(int(b.rx)*0.00068,int(b.ry)*0.00038,int(b.rx)*0.0006)
	_shutter.visible = covered

func _paint_record(slot: int, record: Dictionary) -> void:
	var image := Image.create_from_data(MODEL.WIDTH,MODEL.HEIGHT,false,Image.FORMAT_L8,str(record.pixels_hex).hex_decode())
	_photos[slot].material_override.albedo_texture = ImageTexture.create_from_image(image)
	for i in range(48):
		var bar: MeshInstance3D = _bars[slot][i]
		var h := 0.014 + float(record.values[i])*0.074
		bar.mesh.size.y = h
		@warning_ignore("integer_division")
		bar.position.y = 0.93 + (i/12)*0.105 + h/2
	_hash_labels[slot].text = "hash %s...\nseed %d" % [str(record.sha256).left(16),int(record.output_seed)]

func _build_board() -> void:
	_board = RACK.create_panel("",[
		[{"type":"button","label":"CAPTURE","shape":"rect"},{"type":"button","label":"RUN / HOLD","shape":"rect"},{"type":"button","label":"HEAT +","shape":"rect"}],
		[{"type":"button","label":"KEEP","shape":"rect"},{"type":"button","label":"REPLAY","shape":"rect"},{"type":"button","label":"LOAD","shape":"rect"}],
		[{"type":"button","label":"SEED +1" if HallSeed.enabled(self) else "SYSTEM","shape":"rect"},{"type":"button","label":"RESET 435","shape":"rect"},{"type":"button","label":"COVER","shape":"rect"}]],true)
	_board.name = "LavaControls"
	# The controls fill the wall's centre bay between the two captures.
	_board.position = Vector3(0,1.09,0.07); _board.scale = Vector3.ONE*3.1
	add_child(_board)
	for label in _board.find_children("*","Label3D",true,false): label.outline_size = 0
	var actions := [capture_baseline,toggle_run,compare_heat,keep_current,replay_kept,load_latest,fresh_system,reset_model,compare_cover]
	for i in range(actions.size()): _board.find_child("Btn_%d" % i,true,false).pressed.connect(actions[i])
	STAGE.box(self,Vector3(0,1.09,0.01),Vector3(0.88,0.94,0.07),Color("b7c6c3"))
	STAGE.box(self,Vector3(0,0.33,0.01),Vector3(3.42,0.40,0.04),Color("12212b"))
	_status = _label("",Vector3(0,0.33,0.04),23,0.0014)
	_status.width = 2300; _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
