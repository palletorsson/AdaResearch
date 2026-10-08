extends "res://commons/artifacts/spine_films/film_stage.gd"
const Rules = preload("res://commons/artifacts/spine_films/foundation_b/study_rules.gd")
const WHITE := Color("eee8dd")
const PINK := Color("ef9dab")
const TEAL := Color("76cec2")
var manual := false
var model: Dictionary = Rules.initial_function()
var reference: Node3D
var variants: Dictionary = {}
var bodies: Dictionary = {}
var ring_labels: Array[Label3D] = []
var input_label: Label3D
var output_label: Label3D
var phase_label: Label3D
var reference_points := PackedVector3Array()

func _build() -> void:
	title_text = "One rule makes a family"
	duration = 28.0
	phases = ["TWO RINGS OF POSITIONS", "JOIN THE POSITIONS", "CHANGE THE RADIAL COUNT", "CHANGE ONLY HEIGHT"]
	notes = ["The same angular rule returns two rings. Left: 4 positions per ring. Right: 8.",
		"The supplied display joins neighbouring positions into sides and closes the top.",
		"4, 6, 8, 12, 16 positions around each ring. The height stays 2 metres.",
		"Keep 16 positions per ring and change height from 1 to 3 metres. The left reference stays fixed."]
	source_paths = ["res://commons/artifacts/spine_films/foundation_source.js"]
	evidence = {"source":"Function browser study: column(cx,height,sides), drawFunction, and input attributes",
		"reference":{"height":2.0,"sides":4},"initial_editable":{"height":2.0,"sides":8},
		"height_range":[1.0,3.0],"height_step":0.1,"sides":[4,6,8,12,16],
		"rule":"theta=i/sides*TAU; two rings at y=0 and y=height; radius fixed",
		"display_radius":Rules.RADIUS,"prebuilt_meshes":6,
		"limits":"Reduced straight two-ring study, not the museum's rich column profiles. Browser 49-pixel radius becomes a declared 0.70 m display radius. The bottom remains open. Flat-shaded rendering duplicates vertices; the generator's position list still contains exactly 2*n entries."}
	add_box(Vector3(0,-.10,0),Vector3(6.6,.14,2.7),Color("202b37"))
	for x in [-1.65,1.65]:
		add_box(Vector3(x,-.015,0),Vector3(1.72,.04,1.72),Color("4b555f"))
	reference_points = Rules.positions(2.0,4)
	reference = _make_column(4,WHITE,false)
	reference.position = Vector3(-1.65,0,0)
	reference.scale.y = 2.0
	for child in reference.get_children():
		if str(child.name).begins_with("Input"): child.scale.y = .5
	for sides in Rules.SIDES:
		var column := _make_column(sides,PINK,true)
		column.position = Vector3(1.65,0,0)
		variants[sides] = column
	input_label = add_label("",Vector3(1.65,-.34,1.92),PINK)
	input_label.font_size = 34
	input_label.pixel_size = .007
	var reference_label := add_label("FIXED\nheight 2.0 m  /  sides 4",Vector3(-1.65,-.34,1.92),WHITE)
	reference_label.font_size = 34
	reference_label.pixel_size = .007
	output_label = add_label("",Vector3(0,3.38,-.1),TEAL)
	output_label.font_size = 34
	output_label.pixel_size = .008
	# A metre scale belongs to the display, not the generated position list.
	add_rod(Vector3(2.95,0,-.4),Vector3(2.95,3,-.4),.012,Color("798a9b"))
	for height in [1.0,2.0,3.0]:
		add_rod(Vector3(2.87,height,-.4),Vector3(3.03,height,-.4),.014,WHITE)
		add_label(str(int(height)),Vector3(3.17,height,-.4),WHITE).font_size = 20
	frame_scene(Vector3(0,1.43,0),11.55,.30,.20)

func _make_column(sides: int, colour: Color, editable: bool) -> Node3D:
	var column := Node3D.new()
	column.name = ("Editable" if editable else "Reference")+str(sides)
	display.add_child(column)
	var body := add_mesh(Rules.mesh(sides),colour,Vector3.ZERO,column)
	body.name = "Surface"
	add_lines(Rules.edge_pairs(sides),Color("242c36"),column).name = "Edges"
	# Ring rods and input dots are prebuilt. Only the selected instance is shown.
	var points := Rules.positions(1.0,sides)
	for i in points.size():
		var marker := add_ball(points[i],.034,TEAL,column)
		marker.name = "Input%02d" % i
	for ring in range(2):
		for i in sides:
			var start := points[ring*sides+i]
			var finish := points[ring*sides+(i+1)%sides]
			add_rod(start,finish,.012,TEAL,column)
	return column

func _automatic(time: float) -> Dictionary:
	var state := Rules.initial_function()
	var phase := phase_index(time)
	var progress := phase_progress(time)
	if phase == 2: state.sides = Rules.SIDES[mini(4,int(progress*5.0))]
	if phase == 3:
		state.sides = 16
		state.height = 1.0+mini(20,int(progress*21.0))*.1
	return state

func _draw(time: float) -> void:
	if not manual: model = _automatic(time)
	var surface_visible := manual or phase_index(time)>0
	reference.get_node("Surface").visible = surface_visible
	reference.get_node("Edges").visible = surface_visible
	for sides in variants:
		var column: Node3D = variants[sides]
		column.visible = int(sides)==int(model.sides)
		column.scale.y = float(model.height)
		column.get_node("Surface").visible = surface_visible
		column.get_node("Edges").visible = surface_visible
		for child in column.get_children():
			if str(child.name).begins_with("Input"): child.scale.y = 1.0/float(model.height)
	input_label.text = "EDITABLE\nheight %.1f m  /  sides %d" % [model.height,model.sides]
	output_label.text = "%d positions per ring  ×  2 rings  =  %d positions" % [model.sides,model.sides*2]
	frame_scene(Vector3(0,1.43,0),11.55,.30,.20)

func refresh() -> void:
	super.refresh()
	if manual and _note != null:
		_note.text = "SIDES cycles 4 / 6 / 8 / 12 / 16. LOWER and RAISE change height by 0.1 m. The reference is fixed."
		_footer.text = "YOUR COMPARISON   /   Straight two-ring model; museum profiles are richer"

func experiment_controls() -> Array:
	return [{"key":"sides","label":"SIDES"},{"key":"lower","label":"LOWER"},{"key":"raise","label":"RAISE"},{"key":"reset","label":"RESET"}]

func experiment_action(key: String) -> void:
	if key not in ["sides","lower","raise","reset"]: return
	manual = true
	running = false
	Rules.function_action(model,key)
	refresh()

func experiment_snapshot() -> Dictionary:
	var state := model.duplicate(true)
	state.manual = manual
	state.reference_height = 2.0
	state.reference_sides = 4
	var positions: Array = []
	for point in reference_points: positions.append([point.x,point.y,point.z])
	state.reference_positions = positions
	var output: Array = []
	for point in Rules.positions(float(model.height),int(model.sides)): output.append([point.x,point.y,point.z])
	state.output_positions = output
	state.reference_transform = str(reference.transform)
	state.editable_transform = str(variants[int(model.sides)].transform)
	return state

func replay() -> void:
	manual = false
	super.replay()

func validation() -> Dictionary:
	var tests: Array[Dictionary] = []
	for sides in [4,6,8,12,16]:
		for height in [1.0,2.0,3.0]:
			var points := Rules.positions(height,sides)
			var valid: bool = points.size()==2*sides
			for i in points.size():
				var point := points[i]
				valid = valid and point.is_finite() and is_equal_approx(Vector2(point.x,point.z).length(),.7)
				valid = valid and is_equal_approx(point.y,0.0 if i<sides else height)
			tests.append({"test":"Two rings: n=%d h=%.1f" % [sides,height],"passed":valid})
		var faces := Rules.indices(sides)
		var index_valid: bool = faces.size()==(3*sides-2)*3
		for index in faces: index_valid = index_valid and index>=0 and index<2*sides
		tests.append({"test":"Supplied side and top connectivity: n=%d" % sides,"passed":index_valid})
	var state := Rules.initial_function()
	for i in 50: Rules.function_action(state,"lower")
	tests.append({"test":"Height lower bound remains 1 m","passed":is_equal_approx(state.height,1.0)})
	for i in 50: Rules.function_action(state,"raise")
	tests.append({"test":"Height upper bound remains 3 m","passed":is_equal_approx(state.height,3.0)})
	Rules.function_action(state,"reset")
	tests.append({"test":"Reset restores right h=2 n=8","passed":state==Rules.initial_function()})
	tests.append({"test":"Independent reference remains 2 m / 4 sides","passed":reference_points==Rules.positions(2.0,4) and is_equal_approx(reference.scale.y,2.0)})
	var passed := true
	for test in tests: passed = passed and test.passed
	return {"passed":passed,"checks":tests,"evidence":evidence}
