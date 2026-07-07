extends SceneTree

## Verify wall_placard builds the wall-drag grip and slide_by clamps to range.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_placard_drag.gd

const ART := "res://commons/primitives/wall_placard/wall_placard.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)
	var p: Node3D = load(ART).instantiate()
	p.position = Vector3(0, 1.6, 0)   # placed Y
	world.add_child(p)
	for i in range(20):
		await process_frame

	var grip: Node = p.find_child("SlideGrip", true, false)
	var handle: Node = p.find_child("GripHandle", true, false)
	print("[drag] wall_draggable=%s" % p.get("wall_draggable"))
	print("[drag] SlideGrip present=%s  GripHandle present=%s" %
		[grip != null, handle != null])
	print("[drag] base_y=%s placed_y=%.3f" % [p.get("_base_y"), p.position.y])

	# Drive slide_by past the max — should clamp to drag_max above base.
	var dmax: float = p.get("drag_max")
	var dmin: float = p.get("drag_min")
	for i in range(50):
		p.call("slide_by", 0.1)
	print("[drag] after big +slide: y=%.3f (expect base+%.2f = %.3f)" %
		[p.position.y, dmax, p.get("_base_y") + dmax])
	for i in range(80):
		p.call("slide_by", -0.1)
	print("[drag] after big -slide: y=%.3f (expect base+%.2f = %.3f)" %
		[p.position.y, dmin, p.get("_base_y") + dmin])

	var ok: bool = grip != null and handle != null \
		and is_equal_approx(p.position.y, p.get("_base_y") + dmin)
	print("[drag] RESULT: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
