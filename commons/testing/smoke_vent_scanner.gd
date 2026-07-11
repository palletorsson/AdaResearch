extends SceneTree

## Verifies CatalystVentScanner turns editor-painted `e:` utility tokens
## into CatalystVent nodes — the same call GridSystem._scan_catalyst_vents
## makes after the utilities layer builds. Builds a minimal utilities grid,
## runs the scanner with GridSystem's opts (cell_inset 0 + y_lookup), and
## asserts the vents appear with the parsed tunables.
##
## Run: godot --path . --xr-mode off --no-window --script res://commons/testing/smoke_vent_scanner.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== CatalystVentScanner smoke test ===")
	var ScannerScript = load("res://commons/managers/CatalystVentScanner.gd")
	if ScannerScript == null:
		print("FAIL: scanner script didn't load")
		quit(1); return
	print("- scanner script loaded:", ScannerScript.resource_path)

	# Parent node the scanner spawns under — in the tree so global_position works.
	var vents_root: Node3D = Node3D.new()
	vents_root.name = "CatalystVents"
	get_root().add_child(vents_root)

	# Minimal utilities grid: one plain vent token + one with a foe kind.
	# Mirrors GridSystem: layout rows are z, columns are x.
	var utilities: Array = [
		["", "e:0.5:2:0", ""],
		["", "", "e:1:3:2:swarm"],
	]

	# Same opts GridSystem passes: grid cells centre on x * cell_size
	# (inset 0) and y comes from the structure surface — faked flat here.
	var y_lookup: Callable = func(_x: int, _z: int) -> float:
		return 0.5
	var spawned: int = ScannerScript.scan_utilities(utilities, 1.0, Vector3.ZERO, vents_root, {
		"cell_inset": 0.0,
		"y_lookup": y_lookup,
	})
	if spawned != 2:
		print("FAIL: expected 2 vents spawned, got %d" % spawned)
		quit(1); return
	if vents_root.get_child_count() != 2:
		print("FAIL: expected 2 children under vents root, got %d" % vents_root.get_child_count())
		quit(1); return
	print("- scanner spawned 2 vents")

	# First vent: cell (row 0, col 1) → parsed e:0.5:2:0
	var vent_a: Node3D = vents_root.get_child(0) as Node3D
	if vent_a == null or vent_a.get_script() == null:
		print("FAIL: first vent missing or scriptless (compile error in catalyst_vent.gd?)")
		quit(1); return
	if not vent_a.is_in_group("catalyst_vent"):
		print("FAIL: first vent not in group 'catalyst_vent'")
		quit(1); return
	if not is_equal_approx(float(vent_a.get("emit_interval_s")), 0.5):
		print("FAIL: emit_interval_s expected 0.5, got %s" % str(vent_a.get("emit_interval_s")))
		quit(1); return
	if int(vent_a.get("wave_size")) != 2:
		print("FAIL: wave_size expected 2, got %s" % str(vent_a.get("wave_size")))
		quit(1); return
	if not is_equal_approx(float(vent_a.get("start_delay_s")), 0.0):
		print("FAIL: start_delay_s expected 0.0, got %s" % str(vent_a.get("start_delay_s")))
		quit(1); return
	# Position: col 1 → x 1.0 (inset 0), y from y_lookup, row 0 → z 0.0
	var expect_pos: Vector3 = Vector3(1.0, 0.5, 0.0)
	if not vent_a.global_position.is_equal_approx(expect_pos):
		print("FAIL: first vent at %s, expected %s" % [vent_a.global_position, expect_pos])
		quit(1); return
	print("- vent A tunables + position OK (e:0.5:2:0 at %s)" % expect_pos)

	# Second vent: e:1:3:2:swarm → KIND threads to default_foe_mode.
	var vent_b: Node3D = vents_root.get_child(1) as Node3D
	if vent_b == null or vent_b.get_script() == null:
		print("FAIL: second vent missing or scriptless")
		quit(1); return
	if String(vent_b.get("default_foe_mode")) != "swarm":
		print("FAIL: default_foe_mode expected 'swarm', got '%s'" % str(vent_b.get("default_foe_mode")))
		quit(1); return
	if int(vent_b.get("wave_size")) != 3:
		print("FAIL: vent B wave_size expected 3, got %s" % str(vent_b.get("wave_size")))
		quit(1); return
	print("- vent B foe kind OK (e:1:3:2:swarm → default_foe_mode 'swarm')")

	# Guard: a grid with NO e tokens must spawn nothing.
	var clean_root: Node3D = Node3D.new()
	get_root().add_child(clean_root)
	var clean: Array = [["", "t:next", "s"], ["", "", ""]]
	var none: int = ScannerScript.scan_utilities(clean, 1.0, Vector3.ZERO, clean_root, {"cell_inset": 0.0})
	if none != 0 or clean_root.get_child_count() != 0:
		print("FAIL: vent-free grid spawned %d vents / %d children" % [none, clean_root.get_child_count()])
		quit(1); return
	print("- vent-free grid untouched (0 spawns)")

	print("PASS: CatalystVentScanner spawns configured vents from e: tokens")
	quit(0)
