extends SceneTree
## Brush masks now save as a compact sparse {w,d,cells} form instead of a dense
## grid-of-zeros. Proves: encode is compact, decode round-trips the shape, the
## sparse form still bilinear-resamples across grid sizes, and dense rows (old
## maps) still load.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_brush_sparse.gd

const DF = preload("res://commons/biome_layers/distribution_field.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _disc_field(gw: int, gd: int, r: float) -> PackedFloat32Array:
	var f := PackedFloat32Array(); f.resize(gw * gd)
	for z in gd:
		for x in gw:
			var d := sqrt(float((x - gw / 2) * (x - gw / 2) + (z - gd / 2) * (z - gd / 2)))
			f[z * gw + x] = 1.0 if d <= r else 0.0
	return f

func _initialize() -> void:
	var gw := 20; var gd := 20
	var field := _disc_field(gw, gd, 6.0)

	# Encode → sparse.
	var sparse: Dictionary = DF.field_to_sparse(field, gw, gd)
	print("sparse cells = %d / %d total" % [sparse["cells"].size(), gw * gd])
	_ok(sparse["cells"].size() > 0 and sparse["cells"].size() < gw * gd, "sparse: only painted cells stored")
	_ok(int(sparse["w"]) == gw and int(sparse["d"]) == gd, "sparse carries its native dims")

	# Decode at native size → shape preserved.
	var back := DF.build_field({"element": "tree", "mode": "brush", "density": 1.0, "brush": sparse}, gw, gd, 0)
	_ok(back[(gd / 2) * gw + (gw / 2)] > 0.9, "decoded disc centre ~1.0")
	_ok(back[0] < 0.01, "decoded corner ~0")

	# Decode onto a DIFFERENT grid → bilinear resample (the sequence-accrual path).
	var rw := 7; var rd := 27
	var res := DF.build_field({"element": "tree", "mode": "brush", "density": 1.0, "brush": sparse}, rw, rd, 0)
	_ok(res.size() == rw * rd, "resampled to target grid size")
	_ok(res[(rd / 2) * rw + (rw / 2)] > 0.5, "resampled centre stays high")
	_ok(res[0] < 0.2, "resampled corner stays low")

	# Backward compat: a dense 2D-rows brush (old maps) still loads.
	var rows: Array = []
	for z in gd:
		var row: Array = []
		for x in gw:
			row.append(field[z * gw + x])
		rows.append(row)
	var dense := DF.build_field({"element": "tree", "mode": "brush", "density": 1.0, "brush": rows}, gw, gd, 0)
	_ok(dense[(gd / 2) * gw + (gw / 2)] > 0.9, "legacy dense rows still decode")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
