extends SceneTree

## Re-measures sorting_hall's work table under every value of `initial_order`.
##
## The header of sorting_hall.gd carries a table of cells moved per row per input, and it
## was computed against the OLD unit — cells whose value CHANGED. The unit now has a floor
## of one per step, because merging two already-sorted runs rewrites every cell with the
## value it already held and counted as zero work. Rather than editing published numbers
## by hand, this asks the artifact.
##
## IT MUST RUN IN A SUBVIEWPORT WITH ITS OWN WORLD, exactly as capture_config_sweep does,
## and it must yield frames before reading. A bar_array row parented straight to the
## SceneTree root in a --script run cannot compile its bar shader (INSTANCE_ID is not
## available to the material the substrate builds there), the substrate's _ready aborts
## on the way back out, and the hall reports six empty rows — which looks exactly like an
## artifact that measured nothing, and is not.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_sorting_hall_work.gd

const SCENE := preload("res://commons/artifacts/sorting_hall/sorting_hall.tscn")
const ORDERS: PackedStringArray = ["reversed", "shuffled", "nearly_sorted", "sorted"]
const TOKENS: PackedStringArray = ["bar_array_bubble_sort", "bar_array_insertion_sort",
	"bar_array_selection_sort", "bar_array_merge_sort", "bar_array_quicksort",
	"bar_array_heap_sort"]
const SHORT: PackedStringArray = ["bubble", "insertion", "selection", "merge", "quick", "heap"]


func _initialize() -> void:
	_run()


func _run() -> void:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = Vector2i(64, 64)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	await process_frame
	await process_frame

	var head := "%-16s" % "input"
	for s in SHORT:
		head += "%11s" % s
	print("\nPROBE " + head)

	var unit := "?"
	for order in ORDERS:
		var hall: Node3D = SCENE.instantiate()
		hall.set("initial_order", order)
		hall.set("moment", "done")
		vp.add_child(hall)
		await process_frame
		await process_frame

		var rep: Dictionary = hall.call("work_report")
		var line := "%-16s" % order
		for ti in range(TOKENS.size()):
			var v: int = -1
			var key: String = TOKENS[ti]
			if rep.has(key):
				v = int((rep[key] as Dictionary)["total"])
				unit = str((rep[key] as Dictionary)["unit"])
			line += "%11d" % v
		print("PROBE " + line)

		vp.remove_child(hall)
		hall.queue_free()
		await process_frame

	print("PROBE unit: %s" % unit)
	quit(0)
