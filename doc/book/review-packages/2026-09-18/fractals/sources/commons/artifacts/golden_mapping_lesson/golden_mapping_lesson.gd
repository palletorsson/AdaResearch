extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Two different mappings, each attached to its existing registered specimen.
var source: Node3D
var kind := "numbers"
var term_count := 2
var linear := false
var show_sum := false
var show_rule := false
var cut := 0
var show_arc := false
var show_measure := false
var sum_view: Node3D
var height_values: Array[float] = []

func _ready() -> void:
	source=get_parent()
	position=Vector3(0,0,-4 if kind=="numbers" else -2)
	rotation.y=PI
	_build_compact_console(["NEXT","BACK","HEIGHT","SUM","RESET","RULE"] if kind=="numbers" else ["NEXT","BACK","ARC","MEASURE","RESET","RULE"],"WHAT DID THE MAPPING ADD?")
	if kind=="numbers":
		_retain_examples()
		sum_view=Node3D.new();sum_view.name="UnitSum";source.add_child(sum_view)
		_numbers()
	else:
		source.extrusion_height=0.01
		_rectangle()
	refresh()

func _clear(host: Node) -> void:
	for child in host.get_children():host.remove_child(child);child.queue_free()

func _tag(host: Node3D,text: String,at: Vector3,pixels: float=0.002) -> Label3D:
	var tag=Label3D.new();tag.text=text;tag.position=at;tag.pixel_size=pixels
	tag.font_size=32;tag.rotation.y=PI;tag.outline_size=8;host.add_child(tag);return tag

func _retain_examples() -> void:
	# Freeze the existing examples once. Their original construction functions and
	# dimensions remain; place the downward diagram above a supporting plinth.
	for name_ in ["GoldenSpiral","NaturalPatterns","RecursionVisualization"]:_clear(source.get_node(name_))
	source.create_golden_spiral();source.show_natural_patterns();source.demonstrate_recursion()
	source.get_node("GoldenSpiral").position=Vector3(8,0.95,3.5)
	source.get_node("NaturalPatterns").position=Vector3(0,0.95,5.5)
	source.get_node("RecursionVisualization").position=Vector3(-6,6.9,11)
	var fixtures=Node3D.new();fixtures.name="ExampleSupports";source.add_child(fixtures)
	var stone=material("31454c")
	box(Vector3(0,0.45,5.5),Vector3(11,0.9,4.3),stone,true,fixtures)
	box(Vector3(8,0.45,3.5),Vector3(2,0.9,2),stone,true,fixtures)
	box(Vector3(-6,0.45,11),Vector3(9.8,0.9,9),stone,true,fixtures)
	_tag(fixtures,"ADDED RULES / HELD EXAMPLES",Vector3(0,0.62,3.32),0.0022)
	_tag(fixtures,"144 points: radius = 0.1 sqrt(i)\nturn = 360 / phi²",Vector3(-3,1.1,4.1),0.0015)
	_tag(fixtures,"8 around each of 13 layers\nlayer turn = 0.3 radians",Vector3(0,1.1,3.5),0.0015)
	_tag(fixtures,"8 shell-like chambers\nchosen growth and quarter turns",Vector3(3,1.1,4.5),0.0015)
	_tag(fixtures,"LOGARITHMIC HELIX\nradius × phi per FULL turn",Vector3(8,1.1,2.35),0.0015)
	_tag(fixtures,"A DIFFERENT BRANCH RULE\nF(depth + 1) % 4 + 1 children",Vector3(-6,7.5,11),0.002)
	# Scene-local camera, light and screen UI are for standalone exhibition.
	for child in source.get_children():
		if child is Camera3D:child.current=false
		if child is Light3D:child.visible=false
		if child is CanvasLayer:child.hide()

func _numbers() -> void:
	var host=source.get_node("NumberSequence");_clear(host);_clear(sum_view);height_values.clear()
	for i in range(term_count):
		var n: int=source.fibonacci_numbers[i]
		var h: float=0.05*n if linear else 0.5*log(float(n))+0.5
		height_values.append(h)
		var x: float=(i-4.5)*0.8
		var ink=material("ffa366" if i==term_count-1 else ("76d9d1" if i==term_count-2 else "b3c0e6"))
		box(Vector3(x,h*0.5,0),Vector3(0.6,h,0.6),ink,false,host)
		_tag(host,str(n),Vector3(x,h+0.17,0),0.0024)
		_tag(host,"n=%d"%i,Vector3(x,0.12,-0.38),0.0014)
	if term_count>=3:
		var a: int=source.fibonacci_numbers[term_count-3];var b: int=source.fibonacci_numbers[term_count-2]
		for i in range(a+b):
			box(Vector3(5.4,0.025+i*0.05,0),Vector3(0.42,0.05,0.42),material("b3c0e6" if i<a else "76d9d1"),false,sum_view)
			box(Vector3(6.15,0.025+i*0.05,0),Vector3(0.42,0.05,0.42),material("ffa366"),false,sum_view)
		_tag(sum_view,"%d + %d = %d\nONE UNIT = 5 cm"%[a,b,a+b],Vector3(5.8,(a+b)*0.05+0.3,0),0.002)
	sum_view.visible=show_sum

func _rectangle() -> void:
	source.animate=false;source.is_animating=false;source.max_subdivisions=cut
	source.show_spiral=show_arc;source.show_numbers=show_measure
	source.regenerate();source.spiral_progress=1.0
	if not show_arc and is_instance_valid(source.spiral_mesh):source.spiral_mesh.hide()
	for host in [source.rectangles_parent,source.labels_parent]:
		host.position=Vector3(0,2.4,0);host.rotation.x=-PI/2
	for tag in source.labels_parent.get_children():
		tag.basis=Basis(Vector3.RIGHT,PI/2)*Basis(Vector3.UP,PI)
	if is_instance_valid(source.spiral_mesh):
		source.spiral_mesh.position=Vector3(0,2.4,0);source.spiral_mesh.rotation.x=-PI/2

func act(id: String) -> void:
	if kind=="numbers":
		match id:
			"NEXT":term_count=mini(term_count+1,10);_numbers()
			"BACK":term_count=maxi(term_count-1,2);_numbers()
			"HEIGHT":linear=not linear;_numbers()
			"SUM":show_sum=not show_sum;sum_view.visible=show_sum
			"RESET":term_count=2;linear=false;show_sum=false;show_rule=false;_numbers()
			"RULE":show_rule=not show_rule
	else:
		match id:
			"NEXT":cut=mini(cut+1,8);_rectangle()
			"BACK":cut=maxi(cut-1,0);_rectangle()
			"ARC":show_arc=not show_arc;_rectangle()
			"MEASURE":show_measure=not show_measure;_rectangle()
			"RESET":cut=0;show_arc=false;show_measure=false;show_rule=false;_rectangle()
			"RULE":show_rule=not show_rule
	refresh()

func refresh() -> void:
	if kind=="numbers":
		var n: int=source.fibonacci_numbers[term_count-1]
		readout.text=("F(n) = F(n-1) + F(n-2)\nseeds: 1, 1 / height is a separate rule\n" if show_rule else "")
		readout.text+="%d terms / last value %d\n%s\nNEXT asks for another sum / SUM stacks actual units"%[term_count,n,"LINEAR: h = 0.05 value metres" if linear else "LOG: h = 0.5 ln(value) + 0.5 metres"]
	else:
		var r: Dictionary=source.rectangles.back()
		readout.text=("phi = (1 + sqrt(5)) / 2\nremove a square of side min(w,h)\n" if show_rule else "")
		readout.text+="cut %d / remainder %.3f × %.3f m\nlong / short = %.6f\nARC adds circular segments / MEASURE labels actual sides"%[cut,r.width,r.height,maxf(r.width,r.height)/minf(r.width,r.height)]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
