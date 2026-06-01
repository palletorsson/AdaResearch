extends SceneTree

## List every Label3D / signage node in the built Point One lab with its
## text + world position, so we can see WHERE the title actually is and
## whether "TEST CHAMBER λ-S" is the lab signage or some other label.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_lab_labels.gd

const LAB_ROOM := "res://commons/artifacts/lab_room/lab_room.tscn"
const LAB_JSON := "res://commons/labs/point_one.lab.json"


func _initialize() -> void:
	_run.call_deferred()


func _walk(n: Node, depth: int) -> void:
	if n is Label3D:
		var l := n as Label3D
		print("[lbl] '%s'  text='%s'  world=%s" %
			[n.name, l.text, l.global_position])
	# Signage root container
	if n.name == "Signage":
		print("[lbl] <Signage root> world=%s" % (n as Node3D).global_position)
	for c in n.get_children():
		_walk(c, depth + 1)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var lab: Node3D = load(LAB_ROOM).instantiate()
	lab.set_meta("config_mounted_lab_json", LAB_JSON)
	world.add_child(lab)
	for i in range(60):
		await process_frame
	print("[lbl] signage_wall on lab = '%s'" % lab.get("signage_wall"))
	_walk(lab, 0)
	print("[lbl] DONE")
	quit(0)
