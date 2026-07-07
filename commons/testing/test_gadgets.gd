extends SceneTree

## Headless smoke test: instantiate every new hand gadget + the wall,
## settle a few frames, report parse/instantiate failures. Run:
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_gadgets.gd

const TARGETS := [
	"res://commons/interactables/hand_scanner.tscn",
	"res://commons/interactables/grab_cube.tscn",
	"res://commons/interactables/snap_socket.tscn",
	"res://commons/interactables/poke_keypad.tscn",
	"res://commons/interactables/climb_grip.tscn",
	"res://commons/interactables/gadget_wall.tscn",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var ok := 0
	var fail := 0
	for path in TARGETS:
		var fname: String = path.get_file()
		if not ResourceLoader.exists(path):
			print("[gadget-test] MISSING  %s" % fname)
			fail += 1
			continue
		var packed: PackedScene = load(path)
		if packed == null:
			print("[gadget-test] LOADFAIL %s" % fname)
			fail += 1
			continue
		var inst: Node = packed.instantiate()
		if inst == null:
			print("[gadget-test] INSTFAIL %s" % fname)
			fail += 1
			continue
		var root := Node3D.new()
		get_root().add_child(root)
		root.add_child(inst)
		# Settle so _ready / _build / deferred calls fire.
		for i in range(8):
			await get_root().get_tree().process_frame
		var child_count := inst.get_child_count()
		print("[gadget-test] OK       %s (children=%d)" % [fname, child_count])
		ok += 1
		root.queue_free()
		await get_root().get_tree().process_frame

	print("\n[gadget-test] DONE: %d ok, %d failed" % [ok, fail])
	quit(0 if fail == 0 else 1)
