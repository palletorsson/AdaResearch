extends SceneTree
## Bake the runtime-built ControlConsole (CSG cabinet + plate) into meshes and
## write a .glb so it can be edited in Blender etc. The CSG combiner is baked to
## a static ArrayMesh in place; live SubViewport screens export as blank quads
## (geometry only — that's what's editable here).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/export_console_gltf.gd -- --out=C:/Users/palle/Desktop/control_console.glb

var _out := "C:/Users/palle/Desktop/control_console.glb"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--out="):
			_out = str(a).split("=", true, 1)[1]
	_run()


func _run() -> void:
	var packed: PackedScene = ResourceLoader.load("res://commons/ui/control_console.tscn")
	if packed == null:
		push_error("[export] could not load control_console.tscn")
		quit(1); return
	var console: Node3D = packed.instantiate()
	get_root().add_child(console)

	# Let _ready → _build_body (deferred, awaits frames) finish + plate settle.
	await process_frame
	await create_timer(1.0).timeout
	await process_frame

	_bake_csg(console)
	await process_frame

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(console, state)
	if err != OK:
		push_error("[export] append_from_scene failed: %d" % err)
		quit(1); return
	err = doc.write_to_filesystem(state, _out)
	if err != OK:
		push_error("[export] write_to_filesystem failed: %d" % err)
		quit(1); return
	print("[export] wrote %s" % _out)
	quit()


## Replace each root CSGCombiner3D with a baked MeshInstance3D so the glTF
## exporter (which ignores CSG nodes) captures the welded cabinet geometry.
func _bake_csg(root: Node) -> void:
	var combiners: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CSGCombiner3D:
			combiners.append(n)
			continue   # its children are part of the combine — don't descend
		for c in n.get_children():
			stack.append(c)

	for csg in combiners:
		var mesh: ArrayMesh = null
		if csg.has_method("bake_static_mesh"):
			mesh = csg.bake_static_mesh()
		if mesh == null:
			var arr: Array = csg.get_meshes()
			if arr.size() >= 2 and arr[1] is ArrayMesh:
				mesh = arr[1]
		if mesh == null:
			push_warning("[export] could not bake %s" % csg.name)
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		# "Body" → "ConsoleBody" so the editor can tell structure from board parts.
		mi.name = "Console" + str(csg.name)
		var parent: Node = csg.get_parent()
		var xf: Transform3D = csg.transform
		parent.add_child(mi)
		mi.transform = xf
		parent.remove_child(csg)
		csg.queue_free()
