extends Node3D
## Keep the function fixed; inspect which samples contribute to the total.
const RULES = ["MID", "RIGHT", "LEFT"]
const FRACTIONS = [0.5, 1.0, 0.0]
var bench: Node3D
var buttons: Dictionary = {}
var rule := 0
var selected := 0
var show_reference := false
var held: Dictionary = {}
var held_root: Node3D
var held_label: Label3D
var marker: MeshInstance3D

func _ready() -> void:
	bench = get_parent()
	var panel = bench._plate_root
	panel.board_width = 2.0
	panel.face_to_origin = false
	panel.body_height = 0.8
	panel.position.y = 0
	panel.panel().label_mesh = false
	panel.set_title("HEIGHT x WIDTH / THEN ADD")
	for id in ["RULE", "CELL -", "CELL +", "HOLD", "REFERENCE", "RESET"]:
		var button = panel.add_button(id)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
	var light = OmniLight3D.new()
	light.position = Vector3(0.5, 2.0, 1.5)
	light.omni_range = 4.0
	light.light_energy = 2.0
	add_child(light)
	held_root = Node3D.new()
	held_root.position = bench.plot_offset + Vector3(1.3, 0, 0)
	add_child(held_root)
	held_label = Label3D.new()
	held_label.font_size = 28
	held_label.pixel_size = 0.001
	held_label.position = Vector3(0, -0.16, 0)
	held_root.add_child(held_label)
	marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.023; sphere.height = 0.046
	marker.mesh = sphere
	var ink = StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("ff785f")
	marker.material_override = ink
	bench._plot_root.add_child(marker)
	var bar = bench._error_bar_inst.get_parent()
	bar.position = Vector3(-0.9, 1.45, -0.1)
	for label in bar.find_children("*", "Label3D", true, false):
		label.text = "|difference|" if label.text == "|error|" else "scale .05 (capped)"
	reset_values()

func reset_values() -> void:
	rule = 0; selected = 0; show_reference = false
	bench.sample_fraction = 0.5
	bench._n_index = 0; bench._n = 4
	bench._slider.set_normalized_value(0.0)
	held.clear()
	held_root.hide()

func contribution(index: int) -> Dictionary:
	var width: float = (bench.x_max - bench.x_min) / bench._n
	var x: float = bench.x_min + (index + bench.sample_fraction) * width
	var height: float = bench._f(x)
	return {"x":x, "height":height, "width":width, "area":height*width}

func act(id: String) -> void:
	match id:
		"RULE":
			rule = (rule + 1) % RULES.size()
			bench.sample_fraction = FRACTIONS[rule]
		"CELL -": selected = posmod(selected - 1, bench._n)
		"CELL +": selected = posmod(selected + 1, bench._n)
		"REFERENCE": show_reference = not show_reference
		"HOLD":
			bench._refresh_all()
			hold_current()
		"RESET": reset_values()
	bench._refresh_all()

func hold_current() -> void:
	held = {"n":bench._n, "rule":RULES[rule], "sum":bench._compute_riemann_sum(bench._n)}
	for child in held_root.get_children():
		if child != held_label:
			held_root.remove_child(child); child.queue_free()
	# Copy vertex arrays: later rebuilds of the live ImmediateMeshes cannot change this image.
	var originals = [bench._curve_mesh_inst, bench._rects_mesh_inst, bench._rect_edges_mesh_inst]
	var primitives = [Mesh.PRIMITIVE_LINE_STRIP, Mesh.PRIMITIVE_TRIANGLES, Mesh.PRIMITIVE_LINES]
	for i in originals.size():
		var original = originals[i]
		var copy = MeshInstance3D.new()
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(primitives[i], original.mesh.surface_get_arrays(0))
		copy.mesh = mesh
		copy.material_override = original.material_override
		held_root.add_child(copy)
	var backing = bench._plot_root.get_node("PlotBackplate").duplicate()
	held_root.add_child(backing)
	held_label.text = "HELD %s / N %d / sum %.5f" % [held.rule, held.n, held.sum]
	held_root.show()

func refresh() -> void:
	selected = clampi(selected, 0, bench._n - 1)
	var c = contribution(selected)
	marker.position = Vector3(bench._x_to_local(c.x), bench._f_to_local(c.height), 0.009)
	var total: float = bench._compute_riemann_sum(bench._n)
	var detail = "cell %d/%d: %.4f x %.4f = %.5f" % [selected+1, bench._n, c.height, c.width, c.area]
	if show_reference:
		detail = "4096 MID ref %.5f / diff %+.5f" % [bench._true_integral, total-bench._true_integral]
	bench._plate_readout.text = "%s / N %d / sum %.5f\n%s" % [RULES[rule], bench._n, total, detail]
	bench._error_bar_inst.get_parent().visible = show_reference
