extends SceneTree
const MODEL = preload("res://commons/artifacts/lava_entropy_wall/lava_model.gd")
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("PASS " if passed else "FAIL ",label)
func run() -> void:
	var a := MODEL.capture(435,300,100,false,{"provider":"chosen_model_seed","label":"CHOSEN SEED"})
	check("repeatable full capture",a == MODEL.capture(435,300,100,false,a.source))
	check("valid own receipt",MODEL.valid(a))
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(a,"",true,true))
	check("JSON roundtrip reconstruction",MODEL.valid(roundtrip))
	var hot := MODEL.capture(435,300,110,false,a.source)
	check("heat changes observation",a.sha256 != hot.sha256)
	var mask := MODEL.capture(435,300,100,true,a.source)
	check("cover leaves bodies unchanged",mask.bodies == a.bodies)
	check("cover changes observation",mask.sha256 != a.sha256)
	var bytes: PackedByteArray = mask.pixels_hex.hex_decode()
	var right: PackedByteArray = a.pixels_hex.hex_decode()
	var correct := true
	for y in range(MODEL.HEIGHT):
		for x in range(MODEL.WIDTH):
			correct = correct and bytes[y*MODEL.WIDTH+x] == (0 if x < 48 else right[y*MODEL.WIDTH+x])
	check("cover affects only left sensor half",correct)
	check("full hash SHA256 known vector",MODEL.digest("abc".to_utf8_buffer()) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
	check("48 bounded outputs",a.values.size()==48 and a.values.all(func(v):return v>0 and v<1))
	var tampered: Dictionary = a.duplicate(true); tampered.tick = 301
	check("inconsistent recipe rejected",not MODEL.valid(tampered))
	tampered = a.duplicate(true); tampered.values[0] = 0.0
	check("changed output rejected",not MODEL.valid(tampered))
	tampered = a.duplicate(true); tampered.sha256 = "0".repeat(64)
	check("changed hash rejected",not MODEL.valid(tampered))
	tampered = a.duplicate(true); tampered.seed = []
	check("malformed seed rejected without conversion",not MODEL.valid(tampered))
	var wall: Node3D = load("res://commons/artifacts/lava_entropy_wall/lava_entropy_wall.tscn").instantiate()
	root.add_child(wall); wall.running=false
	check("twelve lamps / forty-eight blobs",wall._blobs.size()==48)
	wall._board.find_child("Btn_0",true,false).pressed.emit()
	check("baseline control holds frame",not wall.running and wall.baseline==wall.current)
	wall._board.find_child("Btn_2",true,false).pressed.emit()
	check("heat button preserves seed and tick",wall.current.seed==wall.baseline.seed and wall.current.tick==wall.baseline.tick and wall.current.heat!=wall.baseline.heat)
	wall.kept = wall.current.duplicate(true)
	wall.reset_model()
	check("saved observation replays exactly",wall.replay_kept() and wall.current==wall.kept and not wall.running)
	wall._board.find_child("Btn_8",true,false).pressed.emit()
	check("cover button preserves body state",wall.current.bodies==wall.baseline.bodies and wall.current.covered!=wall.baseline.covered)
	check("new system source labelled",wall.fresh_system() and wall.current.source.provider=="godot_crypto_random_bytes" and wall.current.source.bytes_hex.length()==32)
	var system: Dictionary = wall.current.duplicate(true)
	check("system-seeded capture replays without resampling",wall.replay_record(system) and wall.current==system)
	tampered = system.duplicate(true); tampered.source.bytes_hex = "0".repeat(32)
	check("inconsistent system source rejected",not MODEL.valid(tampered))
	wall.record_directory = "res://ada_run/lava_entropy_wall_probe"
	check("keep writes a valid receipt",wall.keep_current() and FileAccess.file_exists(wall.save_path))
	var path: String = wall.save_path
	var fresh: Node3D = load(wall.scene_file_path).instantiate()
	root.add_child(fresh); fresh.running=false; fresh.record_directory=wall.record_directory
	check("fresh instance loads a preserved result",fresh.load_latest() and MODEL.valid(fresh.current) and fresh.current.pixels_hex==system.pixels_hex and fresh.current.sha256==system.sha256 and fresh.save_path==path)
	check("fresh load also restores comparison baseline",fresh.baseline.pixels_hex==wall.baseline.pixels_hex)
	fresh.queue_free()
	var output := {"checks":checks,"baseline":a,"changed_heat":hot,"limitations":["No headset test or independent visitor reconstruction.","Synthetic sensor, not a real camera or entropy certification."]}
	var file := FileAccess.open("res://doc/book/iterations/2026-10-14-lava-entropy-wall/model.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t",true,true)); file.close()
	wall.queue_free()
	await process_frame
	quit(0 if checks.all(func(c):return c.passed) else 1)
