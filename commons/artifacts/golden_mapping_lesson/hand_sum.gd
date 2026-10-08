extends "res://commons/artifacts/golden_mapping_lesson/sum_points.gd"
## The printed small construction reads the installed desk's existing record.
## This adapter changes its input ownership, not the numerical generator.
var desk: Node3D
var nearby: Dictionary = {}

func _ready() -> void:
	desk = get_parent()
	position = Vector3(-2.15, 0, 2.0)
	values.assign(desk.source.fibonacci_numbers.slice(0, desk.term_count))
	super._ready()
	desk.box(Vector3(0,0.49,0),Vector3(2.4,0.98,0.72),desk.material("e7e3dc"),true,self)
	desk.box(Vector3(0,1.82,-0.105),Vector3(1.7,0.23,0.025),desk.material("28242d"),false,self)
	var prompt = label("BRING TWO VALUES TOGETHER\nRelease to rearm · trigger also adds once",Vector3(0,0.72,0.37),self)
	prompt.modulate=Color("28242d");prompt.outline_size=0;prompt.pixel_size=0.0012
	for i in 3:
		var id: String = ["NEXT","BACK","RESET"][i]
		var button=desk.PUSH.instantiate();button.position=Vector3((i-1)*0.3,1.0,0.28)
		add_child(button);nearby[id]=button;button.pressed.connect(desk.act.bind(id))
		var tag=label(id,button.position+Vector3(0,0.01,0.085),self);tag.pixel_size=0.0005;tag.rotation_degrees.x=-70

func _process(_dt: float) -> void:
	pass # The installed exhibit does not consume global Enter input.

func advance() -> void:
	if desk.term_count >= LIMIT:
		readout.text="Ten terms · use nearby BACK or RESET."
		return
	var a := values[-2]
	var b := values[-1]
	desk.act("NEXT")
	names[0].text=str(a);names[1].text=str(b)
	readout.text="%d + %d = %d\nRelease both points for the next pair." % [a,b,a+b]

func sync() -> void:
	values.assign(desk.source.fibonacci_numbers.slice(0,desk.term_count))
	redraw()
	# A desk edit during a hold must not turn the same contact into another sum.
	if any_held():latched=true

func show_pair() -> void:
	super.show_pair()
	if values.size()==LIMIT:readout.text="Ten terms · same record in both views\nNearby BACK or RESET returns to earlier terms."
