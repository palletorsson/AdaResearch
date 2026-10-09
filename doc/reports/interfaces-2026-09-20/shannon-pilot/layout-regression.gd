extends SceneTree
## Layout and real pointer-handler regression checks. Does not claim tracked-hand
## reach or headset comfort. Run with --headless --xr-mode off --script ...
const PanelScript = preload("res://commons/ui/control_panel.gd")
const OUT := "res://doc/reports/interfaces-2026-09-20/shannon-pilot/"
var failures: Array[String] = []
var checks := 0
var presses: Array[int] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[panel-rows] ", "PASS " if ok else "FAIL ", message)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var pointer := Node3D.new()
	world.add_child(pointer)
	var panels: Array = []
	for columns in [0, 4]:
		var panel := PanelScript.new()
		panel.title = "SAME EIGHT ACTIONS"
		panel.layout_columns = columns
		panel.position.x = columns
		world.add_child(panel)
		for i in 8:
			var button := panel.add_button("ACTION %d" % i)
			button.pressed.connect(func(): presses.append(i))
		var display := panel.add_readout("kept value 0.42")
		panels.append({"panel": panel, "display": display})
	for frame in 6: await process_frame
	var legacy: Node3D = panels[0].panel
	var compact: Node3D = panels[1].panel
	check(is_equal_approx(legacy._items[7].node.position.x - legacy._items[0].node.position.x, 2.1), "legacy row keeps its 2.10 m centre span")
	check(is_equal_approx(compact._items[3].node.position.x - compact._items[0].node.position.x, 0.9), "four-column centre span is 0.90 m")
	check(is_equal_approx(compact._items[0].node.position.y, compact._items[3].node.position.y), "first four controls share a row")
	check(compact._items[4].node.position.y < compact._items[0].node.position.y, "second group sits below first")
	check(is_equal_approx(compact._items[0].node.position.x, compact._items[4].node.position.x), "rows align")
	var back: MeshInstance3D = compact.get_node("Tilt/Chrome/BackPanel")
	check(is_equal_approx(back.mesh.size.x, 1.256), "backplate fits four full-size slots")
	var transforms: Array = []
	for i in 8:
		var button: Node3D = compact._items[i].node
		transforms.append(button.transform)
		check(button.global_basis.get_scale().is_equal_approx(Vector3.ONE), "button %d remains full size" % i)
		var cap: MeshInstance3D = button.get_node("Button/ButtonMesh")
		var old_cap: MeshInstance3D = legacy._items[i].node.get_node("Button/ButtonMesh")
		check(cap.mesh.get_aabb().size.is_equal_approx(old_cap.mesh.get_aabb().size), "button %d cap size unchanged" % i)
		var area: Area3D = button.get_node("InteractableAreaButton")
		XRToolsPointerEvent.pressed(pointer, area, area.global_position)
		check(area.pressed, "button %d enters pressed state through pointer handler" % i)
		XRToolsPointerEvent.released(pointer, area, area.global_position)
		check(not area.pressed, "button %d releases" % i)
		var label: MeshInstance3D = compact.get_node("Tilt/Row/Label_%d" % i)
		check(label.mesh is QuadMesh and is_equal_approx(label.position.z, PanelScript.PLATE_Z + 0.001), "label %d is flat on the plate" % i)
		var bounds: AABB = compact._control_bounds(button)
		var absolute := bounds.position + button.position
		check(absolute.x >= -back.mesh.size.x * 0.5 and absolute.x + bounds.size.x <= back.mesh.size.x * 0.5, "button %d input bounds have backing" % i)
	check(presses == [0,1,2,3,4,5,6,7], "pointer presses reach exactly the corresponding receiver once")
	for attempt in 3: compact._relayout()
	for frame in 3: await process_frame
	for i in 8: check(compact._items[i].node.transform.is_equal_approx(transforms[i]), "reflow does not drift button %d" % i)
	check(compact._readout_label == panels[1].display and panels[1].display.text == "kept value 0.42", "readout identity and state survive reflow")
	check(compact.get_node("Tilt/Row").get_child_count() == 16, "reflow does not duplicate controls or labels")
	var mixed := PanelScript.new()
	mixed.layout_max_width = 0.75
	world.add_child(mixed)
	var custom := Node3D.new()
	custom.rotation_degrees.z = 90
	custom.scale = Vector3.ONE * 1.25
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.10, 0.8, 0.03)
	mesh.mesh = box
	custom.add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var area_shape := BoxShape3D.new()
	area_shape.size = Vector3(0.16, 0.9, 0.08)
	shape.shape = area_shape
	body.add_child(shape)
	custom.add_child(body)
	mixed.add_node(custom, "WIDE INPUT")
	var next := mixed.add_button("NEXT")
	for frame in 4: await process_frame
	check(custom.scale.is_equal_approx(Vector3.ONE * 1.25), "custom control keeps authored scale")
	check(custom.rotation_degrees.is_equal_approx(Vector3(0,0,90)), "custom control keeps authored rotation")
	check(next.position.y < custom.position.y, "oversized input gets its own row")
	check(mixed.get_node("Tilt/Chrome/BackPanel").mesh.size.x >= 1.125 + PanelScript.GAP * 2, "larger collision shape determines row width")
	var single := PanelScript.new()
	single.layout_columns = 4
	single.title = "READING ONLY"
	world.add_child(single)
	var readout := single.add_readout("no controls")
	for frame in 3: await process_frame
	check(single.has_node("Tilt/Chrome/BackPanel") and readout.text == "no controls", "empty wrapped panel still backs its readout")
	var result := {"checks": checks, "failures": failures, "headset_tested": false,
		"legacy_span_m": 2.1, "compact_span_m": 0.9,
		"evidence": "Real Godot controls and pointer handlers; geometry and retained-state assertions"}
	FileAccess.open(OUT + "layout-checks.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("PANEL_ROWS ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
