extends Node3D
const Design = preload("design.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const START := {"depth": 4.0, "forks": 2.0, "angle": 45.0}
const GENES := ["depth", "forks", "angle"]
const RANGES := [Vector2(2, 10), Vector2(1, 8), Vector2(15, 90)]
const PLACES := [Vector3(-2,.78,-2.5), Vector3(2,.78,-2.5), Vector3(0,.035,-8)]
var model = Design.new()
var editing: Dictionary = START.duplicate(true)
var held: Dictionary = {}
var planted: Dictionary = {}
var preview: Dictionary
var selected := 0
var drawing: Node3D
var readout: Label3D
var point: XRToolsPickable
var last_detent := -1

func _ready() -> void:
	readout = label("", Vector3(0,1.9,1.7))
	label("G: GENE   arrows: LESS / MORE\nH / HELD TRIGGER: HOLD   P: PLANT   R: RESET",Vector3(0,.92,2.75))
	point = PointBody.new(); add_child(point)
	point.action_pressed.connect(func(_body): keep("held"))
	refresh(); park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var detent := clampi(roundi((to_local(point.global_position).x / .8 + .5) * 40), 0, 40)
		if last_detent == -1:
			last_detent = detent
			return
		if detent != last_detent:
			last_detent = detent
			set_normalized(detent / 40.0)
	else:
		last_detent = -1
		park()

func normalized() -> float:
	var span: Vector2 = RANGES[selected]
	return inverse_lerp(span.x, span.y, editing[GENES[selected]])

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((normalized()-.5)*.8,1.18,2.55))

func set_normalized(value: float) -> void:
	var span: Vector2 = RANGES[selected]
	editing[GENES[selected]] = lerpf(span.x, span.y, clampf(value,0,1))
	refresh()

func keep(slot: String) -> void:
	# Retain the recipe, not a reference to the editable dictionary.
	var snapshot := editing.duplicate(true)
	if slot == "held": held = snapshot
	elif slot == "planted": planted = snapshot
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_G: selected = (selected+1) % GENES.size(); refresh()
		KEY_LEFT: set_normalized(snappedf(normalized()-.025,.025))
		KEY_RIGHT: set_normalized(snappedf(normalized()+.025,.025))
		KEY_H: keep("held")
		KEY_P: keep("planted")
		KEY_R: editing = START.duplicate(true); selected = 0; refresh()

func refresh() -> void:
	preview = model.build(editing)
	if is_instance_valid(drawing): remove_child(drawing); drawing.queue_free()
	drawing = Node3D.new(); add_child(drawing)
	var records := [editing, held, planted]
	for i in 3:
		if records[i].is_empty(): continue
		var result: Dictionary = model.build(records[i])
		if not result.accepted: continue
		for j in range(0,result.ends.size(),2):
			var line = LineSkin.new(); drawing.add_child(line)
			var a: Vector3 = PLACES[i]+result.ends[j]
			var b: Vector3 = PLACES[i]+result.ends[j+1]
			line.show_segment(a,b-a,a.distance_to(b))
		var caption := label("%s / depth %.3f\n%d generations / %d commands" % [["EDITING","HELD","PLANTED"][i],records[i].depth,result.parameters.generations,result.requested],PLACES[i]+Vector3(0,-.15,.6))
		caption.reparent(drawing)
	if not preview.accepted: readout.text = preview.error; return
	readout.text = "%s %.3f / %d generations / %d forks\n%d requested / %d read / %d visible cylinders" % [GENES[selected],editing[GENES[selected]],preview.parameters.generations,preview.parameters.forks,preview.requested,preview.drawn_commands,preview.ends.size()/2]

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new(); tag.text=text; tag.position=at
	tag.font_size=36; tag.pixel_size=.002; tag.outline_size=8; add_child(tag)
	return tag
