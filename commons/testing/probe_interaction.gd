## probe_interaction.gd — does the artifact actually RESPOND, or is the affordance decoration?
##
## THE GAP. A static grep can prove an artifact DECLARES a grab sphere, a push button or a
## slider. It cannot prove the button fires, that anything is connected to it, or that the
## artifact changes when it does. Nine of fifteen vector artifacts declare an affordance and
## not one of them has ever been driven — the corpus has no runtime interaction test at all,
## so "interactive" has meant "contains the word" since the day it was first claimed.
##
## THE NEGATIVE CONTROL IS THE WHOLE DESIGN, and without it this probe would be worthless.
## Plenty of these artifacts animate: a vortex spins, a ball falls, a field advects. Snapshot,
## fire, snapshot again and you will see a change every time, and it will be the clock rather
## than the button. So the run is:
##
##     settle -> snapshot A -> wait dt -> snapshot B      (B-A is what moves BY ITSELF)
##     fire the control     -> wait dt -> snapshot C      (C-B is what moved WITH the firing)
##
## and the verdict is C-B measured AGAINST B-A. An artifact that drifts by 40 units a tick and
## drifts by 41 after a button press did not respond to the button.
##
## WHAT COUNTS AS FIRING. The corpus's controls are separate nodes that EMIT to the artifact —
## push_button emits `button_pressed`, slider_horizontal emits `slider_moved`. So the probe
## walks the subtree, finds every node carrying one of those signals, and emits it with
## arguments built from the signal's own declared types via get_signal_list(). It does not
## guess arities: a wrong-arity emit_signal is a runtime error, not a failed test.
##
## GRABBABLES ARE MOVED, NOT EMITTED. A pickable has no "I was grabbed" signal to fire in
## isolation; what a hand does to it is change its transform. So the probe translates it 12 cm
## and lets the artifact notice.
##
## Usage:
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_interaction.gd -- --scene=res://path/to.tscn \
##     [--label=token] [--fixture={"k":v}] [--out=res://ada_run/interaction]
extends SceneTree

const SETTLE := 1.1
const DT := 0.45          ## long enough for a deferred rebuild, short enough to stay cheap

## Signals the corpus's own controls emit. Anything carrying one is a control worth firing.
const CONTROL_SIGNALS: PackedStringArray = [
	"button_pressed", "pressed", "slider_moved", "value_changed", "toggled",
	"grabbed", "released", "activated", "triggered", "interacted",
]
## Names that mean "a hand can hold this". Moved rather than emitted.
const GRAB_HINTS: PackedStringArray = ["grab", "pickable", "pickup", "handle", "knob"]


func _initialize() -> void:
	var scene := ""
	var label := ""
	var out_dir := "res://ada_run/interaction"
	var fixture_json := ""
	var list_path := ""
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--scene="):
			scene = a.substr(8)
		elif a.begins_with("--label="):
			label = a.substr(8)
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--fixture="):
			fixture_json = a.substr(10)
		elif a.begins_with("--list="):
			list_path = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out_dir)

	# BATCH MODE. One boot costs about six seconds and the test itself costs two, so a
	# per-artifact boot spends three quarters of the corpus run on process startup — four
	# hours for 2670 artifacts against roughly one. The list is processed in order and EACH
	# RESULT IS WRITTEN AS IT LANDS, so a scene that takes the boot down costs the remainder
	# of its chunk and nothing already measured.
	if list_path != "":
		await _run_list(list_path, out_dir)
		return

	if scene == "" or not ResourceLoader.exists(scene):
		push_error("probe_interaction: no scene at " + scene)
		quit(2)
		return
	if label == "":
		label = scene.get_file().get_basename()
	_run(scene, label, out_dir, fixture_json)


func _run_list(list_path: String, out_dir: String) -> void:
	var f := FileAccess.open(list_path, FileAccess.READ)
	if f == null:
		push_error("probe_interaction: cannot read " + list_path)
		quit(2)
		return
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK or not (j.data is Array):
		push_error("probe_interaction: list is not a JSON array")
		quit(2)
		return
	f.close()
	var items: Array = j.data
	var n: int = 0
	for raw_item in items:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var sc := String(item.get("scene", ""))
		var lb := String(item.get("label", ""))
		if sc == "" or lb == "" or not ResourceLoader.exists(sc):
			_write_only(out_dir, lb if lb != "" else "unknown_%d" % n,
				{"label": lb, "verdict": "no scene", "scene": sc})
			n += 1
			continue
		var fx := ""
		if item.has("fixture") and item["fixture"] is Dictionary:
			fx = JSON.stringify(item["fixture"])
		# A TOMBSTONE BEFORE THE LOAD, so a scene that kills the process cannot stall the run.
		# The batch resumes past whatever is already on disk, so a hard crash on scene X used
		# to put X first in the next chunk and crash again — the corpus run stopped dead at the
		# same artifact every pass while looking like it was merely slow. Writing the marker
		# first means a crash LEAVES EVIDENCE and the next pass moves on; _measure overwrites
		# it moments later in the normal case, so this costs one file write per artifact.
		_write_only(out_dir, lb, {"label": lb, "scene": sc,
			"verdict": "CRASHED - this scene killed the runner while loading or settling"})
		await _measure(sc, lb, out_dir, fx)
		n += 1
	var d := FileAccess.open("%s/_done.txt" % out_dir, FileAccess.WRITE)
	if d:
		d.store_string("interaction batch %d\n" % n)
		d.close()
	print("INTERACTION BATCH complete: %d artifacts" % n)
	quit(0)


func _run(scene_path: String, label: String, out_dir: String, fixture_json: String) -> void:
	await _measure(scene_path, label, out_dir, fixture_json)
	quit(0)


## The measurement itself. Frees everything it makes, so a batch can call it in a loop
## without the previous artifact's bodies still standing in the next one's world.
func _measure(scene_path: String, label: String, out_dir: String, fixture_json: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(64, 64)
	vp.own_world_3d = true
	root.add_child(vp)

	var packed: PackedScene = load(scene_path)
	if packed == null:
		_write_only(out_dir, label, {"label": label, "verdict": "scene would not load"})
		vp.queue_free()
		return
	var inst: Node = packed.instantiate()
	if fixture_json != "":
		var j := JSON.new()
		if j.parse(fixture_json) == OK and j.data is Dictionary:
			for k in (j.data as Dictionary):
				var holder: Node = _holder_of(inst, String(k))
				if holder != null:
					holder.set(String(k), (j.data as Dictionary)[k])
	vp.add_child(inst)
	await create_timer(SETTLE).timeout

	var controls: Array = []
	var grabs: Array = []
	_collect(inst, controls, grabs)

	var a: Dictionary = _snapshot(inst)
	await create_timer(DT).timeout
	var b: Dictionary = _snapshot(inst)
	var drift: float = _delta(a, b)          # what moves BY ITSELF over one dt

	var fired: Array = []
	for c in controls:
		var node: Node = c["node"]
		var sig: String = c["signal"]
		if not is_instance_valid(node):
			continue
		var args: Array = _default_args(node, sig)
		# emit_signal with the wrong arity is an error, not a failed test — the args come
		# from the signal's own declared types.
		node.callv("emit_signal", [sig] + args)
		fired.append("%s.%s" % [node.name, sig])
	for g in grabs:
		if g is Node3D and is_instance_valid(g):
			(g as Node3D).global_position += Vector3(0.12, 0.0, 0.0)
			fired.append("%s.moved" % g.name)

	await create_timer(DT).timeout
	var c2: Dictionary = _snapshot(inst)
	var response: float = _delta(b, c2)      # what moved WITH the firing

	# The verdict. A response has to clear the artifact's own drift by a real margin, and
	# clear an absolute floor so that float noise on a still artifact is not a "yes".
	var margin: float = response - drift
	var verdict := "no affordance"
	if not fired.is_empty():
		if response > maxf(drift * 2.0, 0.0005):
			verdict = "RESPONDS"
		elif int(c2["meshes"]) == 0:
			# NOT A CONVICTION. Both deltas are built from meshes, positions and boxes, so a
			# subtree that never built any geometry scores drift 0.0 and response 0.0 no matter
			# what the controls did — which prints exactly like a dead artifact. That is a fact
			# about the BUILD (a gated _ready, a scene needing a fixture) and the harness has no
			# standing to call it inert. The corpus has been here before with the DNA critic.
			verdict = "unmeasurable - fired, but nothing built any geometry to measure"
		elif drift > 0.0005:
			verdict = "inconclusive - artifact drifts as much as it responded"
		else:
			verdict = "INERT - fired and nothing moved"

	_write_only(out_dir, label, {
		"label": label, "scene": scene_path,
		"controls_found": controls.size(), "grabbables_found": grabs.size(),
		"fired": fired, "drift": drift, "response": response, "margin": margin,
		"meshes": int(c2["meshes"]), "spatials": int(c2["spatials"]),
		"verdict": verdict,
	})
	print("INTERACTION %s  fired=%d drift=%.5f response=%.5f  %s"
		% [label, fired.size(), drift, response, verdict])
	vp.queue_free()
	await process_frame


## Every node carrying a control signal, and every node that reads as grabbable.
func _collect(node: Node, controls: Array, grabs: Array) -> void:
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for s in n.get_signal_list():
			var sname := String(s.get("name", ""))
			if CONTROL_SIGNALS.has(sname):
				controls.append({"node": n, "signal": sname})
		var low := n.name.to_lower()
		for hint in GRAB_HINTS:
			if low.contains(hint) and n is Node3D:
				grabs.append(n)
				break
		for c in n.get_children():
			stack.append(c)


## Arguments for a signal, built from its own declared types rather than guessed.
func _default_args(node: Node, sig: String) -> Array:
	for s in node.get_signal_list():
		if String(s.get("name", "")) != sig:
			continue
		var out: Array = []
		for arg in (s.get("args", []) as Array):
			match int((arg as Dictionary).get("type", TYPE_NIL)):
				TYPE_BOOL: out.append(true)
				TYPE_INT: out.append(1)
				TYPE_FLOAT: out.append(0.75)
				TYPE_STRING: out.append("")
				TYPE_VECTOR3: out.append(Vector3.ZERO)
				TYPE_OBJECT: out.append(node)
				_: out.append(null)
		return out
	return []


## A cheap, sensitive fingerprint of the whole subtree: how many meshes, where they are, how
## big they are, and what they are made of. Any of those moving is the artifact responding.
func _snapshot(node: Node) -> Dictionary:
	var meshes: int = 0
	var spatials: int = 0
	var pos := Vector3.ZERO
	var scl := Vector3.ZERO
	var vis: int = 0
	var box := AABB()
	var have := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D:
			spatials += 1
			var n3 := n as Node3D
			pos += n3.global_position
			scl += n3.scale
			if n3.visible:
				vis += 1
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			meshes += 1
			var mi := n as MeshInstance3D
			var b: AABB = mi.global_transform * mi.get_aabb()
			box = b if not have else box.merge(b)
			have = true
		for c in n.get_children():
			stack.append(c)
	return {"meshes": meshes, "spatials": spatials, "pos": pos, "scale": scl, "visible": vis,
			"box_size": box.size, "box_pos": box.position}


## One number for how far two snapshots are apart. Scaled so a mesh appearing or vanishing
## always outweighs a body drifting a few millimetres.
func _delta(a: Dictionary, b: Dictionary) -> float:
	var d: float = 0.0
	d += absf(float(a["meshes"]) - float(b["meshes"])) * 10.0
	d += absf(float(a["visible"]) - float(b["visible"])) * 10.0
	d += (a["pos"] as Vector3).distance_to(b["pos"] as Vector3)
	d += (a["scale"] as Vector3).distance_to(b["scale"] as Vector3)
	d += (a["box_size"] as Vector3).distance_to(b["box_size"] as Vector3)
	d += (a["box_pos"] as Vector3).distance_to(b["box_pos"] as Vector3)
	return d


func _holder_of(node: Node, key: String) -> Node:
	if key in node:
		return node
	var queue: Array = [node]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if key in c:
				return c
			queue.append(c)
	return null


## Single-shot: writes the result AND the done marker the watchdog waits on.
func _write(out_dir: String, label: String, data: Dictionary) -> void:
	_write_only(out_dir, label, data)
	var d := FileAccess.open("%s/_done.txt" % out_dir, FileAccess.WRITE)
	if d:
		d.store_string("interaction %s\n" % label)
		d.close()


## Batch: the result only. A per-item done marker would let the watchdog declare the whole
## chunk finished after its first artifact.
func _write_only(out_dir: String, label: String, data: Dictionary) -> void:
	var f := FileAccess.open("%s/%s.json" % [out_dir, label], FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
