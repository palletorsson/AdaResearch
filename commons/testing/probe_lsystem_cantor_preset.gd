extends SceneTree
## Readback for the Cantor preset added to lsystem_editor on 2026-09-25: does a
## map token `lsystem_editor#grammar:cantor` build the 5th Cantor row — 32 drawn
## pieces in 243 steps — and does `grammar:koch` still build what it always did?
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_lsystem_cantor_preset.gd

const OUT := "C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/8987ca3e-a19b-46d1-b00a-85888e1b0458/scratchpad/lsystem_cantor_probe.txt"
var _lines: PackedStringArray = []

func _init() -> void:
	await process_frame
	await _stand("cantor", 32, 243, "Cantor")
	await _stand("koch", -1, -1, "Koch Curve")
	await _stand("cantor#depth:3", 8, 27, "Cantor")
	_say("[probe] done")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
	quit()

func _say(msg: String) -> void:
	print(msg)
	_lines.append(msg)

func _stand(spec: String, want_f: int, want_len: int, want_name: String) -> void:
	var packed: PackedScene = load("res://commons/artifacts/lsystem_editor/lsystem_editor.tscn")
	var inst: Node3D = packed.instantiate()
	var parts := spec.split("#")
	var cfg := {"grammar": parts[0]}
	for i in range(1, parts.size()):
		var kv := parts[i].split(":")
		cfg[kv[0]] = kv[1]
	inst.apply_grid_config(cfg)  # the museum configures before _ready
	root.add_child(inst)
	await create_timer(0.5).timeout
	var s: String = inst._current_string
	var nf := s.count("F")
	var name: String = inst.PRESETS[inst.preset][4] if inst.preset < inst.PRESETS.size() else "Custom"
	var verts: int = inst.fitted_lines.size()
	var label: String = inst._info_label.text.split("\n")[0] if inst._info_label else "?"
	var ok := (want_f < 0 or nf == want_f) and (want_len < 0 or s.length() == want_len) and name == want_name
	_say("[probe] %s -> preset %d '%s' | F=%d len=%d gens=%d angle=%.1f | line vertices %d | label '%s' | %s" % [
		spec, inst.preset, name, nf, s.length(), inst.generations, inst.angle_degrees, verts, label, "PASS" if ok else "FAIL"])
	if spec.begins_with("cantor") and s.length() <= 300:
		_say("[probe]   sentence: %s" % s)
	inst.queue_free()
	await process_frame
