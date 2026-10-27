extends "res://commons/artifacts/line_black_box/line_black_box.gd"
## Two real XR endpoints carry a live ruler, free in all three directions.
const Ruler := preload("survey_ruler.gd")
const Blueprint := preload("survey_blueprint.gd")
@export var plan := true
var scale_factor := 10.0
var measured_length := 0.0
var mounted_readout := false
var glow: OmniLight3D
var ruler: Node3D
var local_positions: Array[Vector3] = [Vector3(-1,1.06,0),Vector3(1,1.06,0)]

func _ready() -> void:
	scale_factor = 10.0 if plan else 1.0
	super()
	for label in get_children():
		if label is Label3D and label != readout: label.queue_free()
	readout.rotation = Vector3.ZERO
	readout.font_size = 30
	readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var title := _label("02 / THIS FLOOR AT 1:10" if plan else "SPACE RULER / 1:1", Vector3(0,1.9,1.25 if plan else 0),28,Color("f6e9dc"))
	title.name = "SurveyTitle"
	title.rotation = Vector3.ZERO
	var caption := _label("Take either end. Measure across, up or through." if plan else "Move either end in any direction. Metres at full size.",Vector3(0,.65,1.3 if plan else .15),24,Color("f6e9dc"))
	caption.name = "SurveyInstructions"
	caption.rotation = Vector3.ZERO
	ruler = Ruler.new()
	ruler.name = "LiveRuler"
	line.add_child(ruler)
	glow = OmniLight3D.new()
	glow.name = "MeasureLight"
	glow.light_color = Color("b5f2ed")
	glow.omni_range = 3.4
	glow.light_energy = 1.6
	add_child(glow)
	reset_line()

func _build_reset() -> void: pass

func _build_room() -> void:
	# The full-size instrument is the changing line itself, with no fixed board.
	if not plan: return
	_box("Table",Vector3(4.8,.12,2.8),Vector3(0,.92,0),_material(Color("102c40"),.78),true)
	for x in [-1.9,1.9]: _box("Leg",Vector3(.08,.86,2.1),Vector3(x,.43,0),_material(Color("353a40"),.48),true)
	var drawing := Blueprint.new()
	drawing.name = "Blueprint"
	drawing.position.y = .986
	add_child(drawing)

func _process(_delta: float) -> void:
	if glow == null: return
	var endpoints: Array[XRToolsPickable] = [point_a,point_b]
	for i in range(2):
		var point := endpoints[i]
		# Released positions stay local when the editable assembly moves.
		# Held positions come from the actual XR hand in all three dimensions.
		var p: Vector3 = point.position if point.is_picked_up() else local_positions[i]
		local_positions[i] = p
		point.position = p
		PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
	var span := point_a.global_position.distance_to(point_b.global_position)
	measured_length = span*scale_factor
	readout.text = ("1:10   %.2f m = %.2f m" % [span,measured_length]) if plan else "1:1   %.2f m" % measured_length
	if not mounted_readout:
		readout.position = (local_positions[0]+local_positions[1])*.5+Vector3(0,.30,0)
	line.call("update_line_transform",local_positions[0],local_positions[1])
	line.get("current_line").visible = span > .001
	ruler.update_measure(local_positions[0],local_positions[1],measured_length)
	glow.global_position = line.to_global((local_positions[0]+local_positions[1])*.5+Vector3(0,.16,0))
	glow.visible = point_a.is_picked_up() or point_b.is_picked_up()

func reset_line() -> void:
	if point_a.is_picked_up() or point_b.is_picked_up(): return
	var edge := .85 if plan else 0.0
	local_positions = [Vector3(-1,1.08,edge),Vector3(1,1.08,edge)]
	point_a.position = local_positions[0]
	point_b.position = local_positions[1]
	_process(0.0)
