extends SceneTree

## Verify the podium palm scanner's TEXT feedback actually updates through
## the scan states (the _prompt_label was previously never cached, so the
## label stayed on "PLACE HAND" forever — no "ACCESS GRANTED" feedback).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_palm_label.gd

const SCANNER := "res://commons/artifacts/palm_scanner/palm_scanner.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _phys(n: int) -> void:
	for i in range(n):
		await physics_frame


func _label_text(scanner: Node) -> String:
	var lbl = scanner.get("_prompt_label")
	return str(lbl.text) if lbl != null else "<no label cached>"


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var scanner: Node3D = load(SCANNER).instantiate()
	scanner.set("scan_active", true)
	scanner.set("mounting", "podium")
	scanner.set("auto_connect_door", false)
	world.add_child(scanner)
	await _phys(20)

	# The real bug was that _prompt_label was never cached (stayed null), so
	# NO text ever updated. Guard that directly, then check each state writes
	# its text. Read on the SAME frame as the call — _physics_process resets
	# to idle when no hand is present, which would mask the SCANNING text.
	var cached: bool = scanner.get("_prompt_label") != null
	print("[label] _prompt_label cached = %s  (expect true)" % cached)

	var idle := _label_text(scanner)
	print("[label] idle     = '%s'  (expect PLACE HAND)" % idle)

	scanner.call("_begin_scan")
	var scanning := _label_text(scanner)
	print("[label] scanning = '%s'  (expect SCANNING…)" % scanning)

	scanner.call("_grant_access")
	var granted := _label_text(scanner)
	print("[label] granted  = '%s'  (expect ACCESS GRANTED)" % granted)

	var ok: bool = cached and idle == "PLACE HAND" and scanning.begins_with("SCANNING") and granted == "ACCESS GRANTED"
	print("[label] RESULT: %s" % ("PASS — text feedback updates" if ok else "FAIL"))
	quit(0 if ok else 1)
