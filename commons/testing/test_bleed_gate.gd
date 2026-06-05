extends SceneTree
## Curriculum bleed-gate: a kingdom's soil colour must not appear before its unlock
## stage (matching the spawn gate). tree unlocks at 11, shader is always (0).
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_bleed_gate.gd

const Sub = preload("res://commons/biome_layers/biome_ground_substrate.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _max_alpha(img: Image) -> float:
	var m := 0.0
	for y in img.get_height():
		for x in img.get_width():
			m = maxf(m, img.get_pixel(x, y).a)
	return m

func _compose(sub, layers: Array, stage: int) -> float:
	sub.set_paint_layers(layers, 7, stage)
	return _max_alpha(sub._compose_paint_texture().get_image())

func _initialize() -> void:
	var gw := 12; var gd := 12
	var sub = Sub.new()
	sub.configure(gw, gd, 1.0, Vector3(6, 0, 6))
	var flat := PackedFloat32Array(); flat.resize(gw * gd)
	sub.set_field(flat, gw, gd, 0.0)

	var tree := [{"element": "tree", "mode": "plane", "density": 1.0}]
	var a_low: float = _compose(sub, tree, 5)
	var a_hi: float = _compose(sub, tree, 14)
	print("tree bleed alpha — stage 5: %.2f, stage 14: %.2f" % [a_low, a_hi])
	_ok(a_low < 0.01, "tree bleed GATED at stage 5 (unlock 11)")
	_ok(a_hi > 0.3, "tree bleed SHOWS at stage 14")

	var shader := [{"element": "shader", "mode": "plane", "density": 1.0, "color": [0.2, 0.6, 0.9]}]
	var a_sh: float = _compose(sub, shader, 1)
	print("shader bleed alpha — stage 1: %.2f" % a_sh)
	_ok(a_sh > 0.3, "shader bleeds at stage 1 (always unlocked)")

	var a_default: float = _compose(sub, tree, 999)
	_ok(a_default > 0.3, "ungated default (999) still bleeds — scrubber/tests unaffected")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
