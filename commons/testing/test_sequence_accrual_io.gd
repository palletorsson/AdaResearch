extends SceneTree
## Integration test: accrued_layers reads an earlier map's paint_layers from disk
## and composes them under the current map's own. Self-contained — creates a temp
## map dir under commons/maps/, tests, then deletes it. No real maps touched.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_sequence_accrual_io.gd

const SequenceAccrual = preload("res://commons/biome_layers/sequence_accrual.gd")

const TEMP_A := "res://commons/maps/_AccrualTestA"
const TEMP_B := "res://commons/maps/_AccrualTestB"

class FakeEco:
	var seqmap := {}
	var seqs := {}
	func get_sequence_for_map(m): return seqmap.get(m, "")
	func get_sequence_maps(s): return seqs.get(s, [])

var _fails := 0
func _ok(c: bool, label: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + label)
	if not c: _fails += 1

func _write_map(dir: String, paint_layers) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var data := {"map_info": {"dimensions": {"width": 10, "depth": 10}}}
	if paint_layers != null:
		data["paint_layers"] = paint_layers
	var f := FileAccess.open(dir + "/map_data.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()

func _rm(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d:
		for fn in d.get_files():
			d.remove(fn)
	DirAccess.remove_absolute(dir)

func _initialize() -> void:
	# Map A (first) has a flower-noise + a ground-curve. Map B (second) has none yet.
	_write_map(TEMP_A, [
		{"element": "flower", "mode": "noise", "density": 0.6, "scale": 0.3},
		{"element": "ground", "mode": "curve", "axis": "radial", "height": 1.2},
	])
	_write_map(TEMP_B, null)

	var eco := FakeEco.new()
	eco.seqmap = {"_AccrualTestA": "atest", "_AccrualTestB": "atest"}
	eco.seqs = {"atest": ["_AccrualTestA", "_AccrualTestB"]}

	print("=== B (2nd map) builds on A ===")
	var b := SequenceAccrual.accrued_layers(eco, "_AccrualTestB", [{"element": "shader"}])
	print("    B effective layers = %d" % b.size())
	_ok(b.size() == 3, "B sees A's 2 layers + its own shader (=3)")
	var from_a := 0
	for l in b:
		if l is Dictionary and str(l.get("_accrued_from", "")) == "_AccrualTestA":
			from_a += 1
	_ok(from_a == 2, "2 layers tagged accrued from A")
	_ok(str(b[b.size() - 1].get("element", "")) == "shader", "B's own shader is last/on-top")

	print("=== A (1st map) builds on nothing ===")
	var a := SequenceAccrual.accrued_layers(eco, "_AccrualTestA", [{"element": "tree"}])
	_ok(a.size() == 1 and str(a[0].get("element")) == "tree", "first map → just its own")

	print("=== map with no sequence → own unchanged ===")
	var orphan := SequenceAccrual.accrued_layers(eco, "NotInAnySequence", [{"element": "tree"}])
	_ok(orphan.size() == 1, "orphan map is a safe no-op")

	_rm(TEMP_A)
	_rm(TEMP_B)
	print(("\nRESULT: ALL PASS" if _fails == 0 else "\nRESULT: %d FAILURE(S)" % _fails))
	quit(_fails)
