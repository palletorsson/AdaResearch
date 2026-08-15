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
	# HOW MANY OF THESE CONTROLS ARE WIRED TO ANYTHING AT ALL. Without this the harness can
	# say "fired and nothing moved" but not say WHY, and the two whys want opposite repairs:
	# a signal with zero connections is a dangling control and a real defect, while a signal
	# with a listener means the handler DID run and changed something in a channel this probe
	# cannot see — colour, material, label text, audio. Convicting the second kind is the same
	# fault as convicting a step sequencer with a geometry probe.
	var wired: int = 0
	var dangling: Array = []
	for c in controls:
		var node: Node = c["node"]
		var sig: String = c["signal"]
		if not is_instance_valid(node):
			continue
		var conns: int = node.get_signal_connection_list(sig).size()
		if conns > 0:
			wired += 1
		else:
			dangling.append("%s.%s" % [node.name, sig])
		# MOVE THE CONTROL, THEN ANNOUNCE IT. Emitting value_changed(0.75) at a spin box does
		# not change the spin box: the handler reads `slider.value`, finds it exactly where it
		# was, and rebuilds something identical. A deterministic generator asked to regenerate
		# with unchanged parameters produces a byte-identical result, which this probe cannot
		# tell from a generator that ignored the button — and that is most of what was left in
		# the inert column: recursive_tree, space_colonization_algorithm, wfc_dungeon_generator,
		# every one of them a builder wired to a slider nobody had actually moved.
		var moved_value := false
		if "value" in node and "min_value" in node and "max_value" in node:
			var lo := float(node.get("min_value"))
			var hi := float(node.get("max_value"))
			var cur := float(node.get("value"))
			if hi > lo:
				# Somewhere far from where it is now, and inside its own declared range.
				var want: float = lo + (hi - lo) * (0.28 if cur > lo + (hi - lo) * 0.5 else 0.76)
				if not is_equal_approx(want, cur):
					node.set("value", want)
					moved_value = true
		var args: Array = _default_args(node, sig)
		if moved_value and args.size() == 1 and (args[0] is float or args[0] is int):
			args[0] = float(node.get("value"))
		# emit_signal with the wrong arity is an error, not a failed test — the args come
		# from the signal's own declared types.
		node.callv("emit_signal", [sig] + args)
		fired.append("%s.%s" % [node.name, sig])

	# THE CONTROLS ARE MEASURED BEFORE ANYTHING IS SHOVED, because measuring the two together
	# is circular. The grab test moves a pickable 12 cm and then measures the subtree the
	# pickable is IN, so the response can never come back below 12 cm whether or not a single
	# thing was listening — "it moved because I moved it" scored as a pass. Splitting the
	# firing gives one number that owes nothing to the shove.
	await create_timer(DT).timeout
	var c1: Dictionary = _snapshot(inst)
	var response: float = _delta(b, c1)      # controls ONLY — nothing has been pushed yet
	var look_drift: float = _look_delta(a, b)
	var look_response: float = _look_delta(b, c1)

	for g in grabs:
		if g is Node3D and is_instance_valid(g):
			(g as Node3D).global_position += Vector3(0.12, 0.0, 0.0)
			fired.append("%s.moved" % g.name)
	await create_timer(DT).timeout
	var c2: Dictionary = _snapshot(inst)
	var grab_response: float = _delta(c1, c2)
	# What the shove itself accounts for, before anything listens: each pickable carries its
	# own position into the sum, so 0.12 m per grabbed body is the floor a genuine knock-on
	# effect has to clear. It is a floor and not a subtraction — a pickable dragging a linkage
	# with it also moves itself.
	var grab_floor: float = 0.12 * float(grabs.size())

	# The verdict. A response has to clear the artifact's own drift by a real margin, and
	# clear an absolute floor so that float noise on a still artifact is not a "yes".
	var margin: float = response - drift
	var verdict := "no affordance"
	if controls.is_empty() and not grabs.is_empty():
		# ITS AFFORDANCE IS CARRIAGE, AND THIS TEST CANNOT GRADE THAT. A pickable with no other
		# control responds by being picked up and carried, which the pickup system does by
		# moving it — there is nothing for the artifact itself to handle. Calling it RESPONDS
		# would be scoring my own shove; calling it INERT is what the old build did to nineteen
		# artifacts including every parametric knot in the corpus.
		verdict = "grabbable - affordance is carriage, which this test cannot grade"
	elif not fired.is_empty():
		if response > maxf(drift * 2.0, 0.0005):
			verdict = "RESPONDS"
		elif look_response > maxf(look_drift * 2.0, 0.0005):
			# It did not move. It changed colour, emission, transparency, a shader uniform or a
			# line of text — which for a large part of this corpus IS the response.
			verdict = "RESPONDS in appearance - recoloured or relabelled, did not move"
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
		"wired": wired, "dangling": dangling.slice(0, 24),
		"dangling_count": dangling.size(),
		"grab_response": grab_response, "grab_floor": grab_floor,
		"look_drift": look_drift, "look_response": look_response,
		"verdict": verdict,
	})
	print("INTERACTION %s  fired=%d drift=%.5f response=%.5f  %s"
		% [label, fired.size(), drift, response, verdict])
	vp.queue_free()
	await process_frame


## Every node carrying a control signal, and every node that reads as grabbable.
##
## A NODE THAT DECLARES `grabbed` IS GRABBABLE, WHICH IS NOT THE SAME AS BEING DRIVEN BY IT.
## The first version of this classified purely by NAME — a node had to be called something
## containing "grab", "handle" or "knob" — and emitted `grabbed`/`released` on everything else
## as though they were controls. They are not controls; they are ANNOUNCEMENTS the grab system
## makes after the hand has already moved the object. Nothing connects to them, and nothing
## should: a pickable responds by being carried, not by handling its own notification.
##
## So the harness fired the announcement and skipped the act. Nineteen artifacts came back
## with every control dangling and a verdict of INERT — catenoid, torus_knot, force_cube, and
## color_sets_overview with 288 stickers not one of which was "connected to anything". All of
## them were grabbable objects the probe had declined to grab, because `Catenoid` does not
## contain the letters g-r-a-b. Declaring the signal is the evidence; the name never was.
func _collect(node: Node, controls: Array, grabs: Array) -> void:
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var announces_grab := false
		for s in n.get_signal_list():
			var sname := String(s.get("name", ""))
			if sname == "grabbed" or sname == "released":
				announces_grab = true
			elif CONTROL_SIGNALS.has(sname):
				controls.append({"node": n, "signal": sname})
		var low := n.name.to_lower()
		var named_grab := false
		for hint in GRAB_HINTS:
			if low.contains(hint):
				named_grab = true
				break
		if (announces_grab or named_grab) and n is Node3D:
			grabs.append(n)
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
## A SECOND CHANNEL, BECAUSE MOST OF THIS CORPUS ARGUES IN COLOUR. The geometry channel alone
## convicted pattern_tile_plate, NoiseColors3D, WhiteNoiseGallery and visual_color_mixing of
## being inert — artifacts whose entire subject is what colour a surface is. Their handlers
## ran; the probe was measuring the one thing they do not change. Same fault as judging a step
## sequencer by its meshes, one channel over, and it is the reason this is reported apart from
## the geometry number rather than summed into it: "it recoloured but did not move" is a
## different fact about an artifact than "it moved", and flattening them loses both.
func _appearance(n: Node, acc: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var m: Material = mi.get_active_material(0)
		if m == null:
			m = mi.material_override
		if m is BaseMaterial3D:
			var bm := m as BaseMaterial3D
			acc["albedo"] = (acc["albedo"] as Vector3) + Vector3(
				bm.albedo_color.r, bm.albedo_color.g, bm.albedo_color.b)
			acc["emission"] = (acc["emission"] as Vector3) + Vector3(
				bm.emission.r, bm.emission.g, bm.emission.b) * bm.emission_energy_multiplier
			acc["alpha"] = float(acc["alpha"]) + bm.albedo_color.a
		elif m is ShaderMaterial:
			# A shader's uniforms are where a shader-driven artifact keeps its state, and they
			# are readable by name off the material without knowing the shader.
			var sm := m as ShaderMaterial
			if sm.shader != null:
				for u in sm.shader.get_shader_uniform_list():
					var v: Variant = sm.get_shader_parameter(String(u.get("name", "")))
					if v is float or v is int:
						acc["uniforms"] = float(acc["uniforms"]) + float(v)
					elif v is Color:
						var cc := v as Color
						acc["albedo"] = (acc["albedo"] as Vector3) + Vector3(cc.r, cc.g, cc.b)
					elif v is Vector3:
						acc["albedo"] = (acc["albedo"] as Vector3) + (v as Vector3)
	# ANY node that carries text, not just the two 3D label classes. A whole family of these
	# artifacts is a 2D UI panel rendered to a quad — infokiosk, HandheldInfoBoard, settings_ui,
	# panel_bridge_loom with sixty-three buttons — and pressing Next there changes a
	# RichTextLabel inside a SubViewport. Nothing moves, nothing is recoloured, and the earlier
	# channel looked only at Label and Label3D, so the page turned and the probe saw a corpse.
	# Summed length alone would miss a swap between two strings of equal length, so the content
	# is folded in as well.
	if "text" in n:
		var s: String = String(n.get("text"))
		var h: int = 0
		for i in range(s.length()):
			h = (h * 31 + s.unicode_at(i)) % 1000003
		acc["text"] = int(acc["text"]) + s.length() + h


func _snapshot(node: Node) -> Dictionary:
	var meshes: int = 0
	var spatials: int = 0
	var pos := Vector3.ZERO
	var scl := Vector3.ZERO
	var vis: int = 0
	var box := AABB()
	var have := false
	var look: Dictionary = {"albedo": Vector3.ZERO, "emission": Vector3.ZERO,
			"alpha": 0.0, "uniforms": 0.0, "text": 0}
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		_appearance(n, look)
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
			"box_size": box.size, "box_pos": box.position, "look": look}


## How far apart two snapshots look, ignoring where anything is.
func _look_delta(a: Dictionary, b: Dictionary) -> float:
	var x: Dictionary = a["look"]
	var y: Dictionary = b["look"]
	var d: float = 0.0
	d += (x["albedo"] as Vector3).distance_to(y["albedo"] as Vector3)
	d += (x["emission"] as Vector3).distance_to(y["emission"] as Vector3)
	d += absf(float(x["alpha"]) - float(y["alpha"]))
	d += absf(float(x["uniforms"]) - float(y["uniforms"]))
	d += absf(float(int(x["text"]) - int(y["text"])))
	return d


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
