extends SceneTree
## Headless unit tests for sequence accrual + brush resampling.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_sequence_accrual.gd

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const SequenceAccrual = preload("res://commons/biome_layers/sequence_accrual.gd")

var _fails := 0

func _ok(cond: bool, label: String) -> void:
	print(("  PASS  " if cond else "  FAIL  ") + label)
	if not cond:
		_fails += 1

func _initialize() -> void:
	print("=== 1. brush resample: 20x20 centred disc → 7x27 grid keeps the shape ===")
	# Build a 20x20 brush mask: 1.0 inside a centred disc (r=6), else 0.
	var bw := 20; var bd := 20
	var rows: Array = []
	for z in bd:
		var row: Array = []
		for x in bw:
			var d := sqrt(float((x - bw / 2) * (x - bw / 2) + (z - bd / 2) * (z - bd / 2)))
			row.append(1.0 if d <= 6.0 else 0.0)
		rows.append(row)
	var spec := {"element": "ground", "mode": "brush", "density": 1.0, "brush": rows}
	# Re-evaluate on a 7x27 grid (different aspect — like the next map in a sequence).
	var gw := 7; var gd := 27
	var field := DistributionField.build_field(spec, gw, gd, 0)
	var centre: float = field[(gd / 2) * gw + (gw / 2)]
	var corner: float = field[0]
	var edge_mid: float = field[(gd / 2) * gw + 0]   # left-middle, outside the disc horizontally
	print("    centre=%.2f corner=%.2f left-mid=%.2f" % [centre, corner, edge_mid])
	_ok(centre > 0.6, "disc centre stays high after resample")
	_ok(corner < 0.2, "corner stays low (disc didn't smear to corners)")
	_ok(field.size() == gw * gd, "field sized to target grid (%d)" % (gw * gd))

	print("=== 2. brush same-size = crisp direct copy ===")
	var f2 := DistributionField.build_field(spec, bw, bd, 0)
	_ok(f2[(bd / 2) * bw + (bw / 2)] > 0.9, "same-size centre ~1.0")
	_ok(f2[0] < 0.01, "same-size corner ~0")

	print("=== 3. compose(): preceding maps first, own last ===")
	var a := [{"element": "ground", "_accrued_from": "MapA"}]
	var b := [{"element": "flower", "_accrued_from": "MapB"}, {"element": "tree", "_accrued_from": "MapB"}]
	var own := [{"element": "shader"}]
	var merged := SequenceAccrual.compose([a, b], own)
	_ok(merged.size() == 4, "4 layers total")
	_ok(str(merged[0].get("element")) == "ground", "MapA's ground is first")
	_ok(str(merged[3].get("element")) == "shader", "own (shader) is last")
	_ok(merged[3].has("_accrued_from") == false, "own layer not tagged accrued")

	print("=== 4. compose with no preceding = own unchanged ===")
	var only_own := SequenceAccrual.compose([], own)
	_ok(only_own.size() == 1 and str(only_own[0].get("element")) == "shader", "lone map → just own")

	print("=== 5. accrued_layers: null eco → own unchanged (graceful) ===")
	var safe := SequenceAccrual.accrued_layers(null, "Whatever", own)
	_ok(safe.size() == 1, "null eco is a safe no-op")

	print(("\nRESULT: ALL PASS" if _fails == 0 else "\nRESULT: %d FAILURE(S)" % _fails))
	quit(_fails)
