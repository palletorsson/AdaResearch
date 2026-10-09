extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Room-local paired stations: the receiver uses the source's actual gap, in metres.
signal contributions_changed
var projection_mode := false
var a := Vector2(1.0,0.5)
var b := Vector2(-0.5,0.0)
var gap := Vector2.ZERO
var kept := Vector2.ZERO
var remainder := Vector2.ZERO
var axis := Vector2.RIGHT
var selected_a := true
var revealed := false
var shift_sign := 1.0
var slide_sign := 1.0
var source: Node3D
var drawing: Node3D
var numbers: Label3D
var heading: Label3D
var notice := ""
var cyan: Material
var amber: Material
var pink: Material
var rail: Material

func hall_owner() -> Node:
	var node: Node=self
	while node.get_parent():
		if node.has_meta("em_map"):return node
		node=node.get_parent()
	return node

func _ready() -> void:
	cyan=material("70f2dc",true);amber=material("ffc26a",true);pink=material("ef85bd",true);rail=material("899ba6")
	box(Vector3(0,0.06,0),Vector3(4,0.12,4),material("18333b"),true)
	for i in range(-3,4):
		box(Vector3(i*0.5,0.128,0),Vector3(0.014,0.008,4),rail)
		box(Vector3(0,0.128,i*0.5),Vector3(4,0.008,0.014),rail)
	box(Vector3(0,1.85,-2.25),Vector3(6.6,3.7,0.12),material("14272e"),true)
	box(Vector3(0,3.72,-2.25),Vector3(6.7,0.06,0.16),pink if projection_mode else cyan)
	heading=label("WHAT DOES THIS RAIL KEEP?" if projection_mode else "FROM B TO A",Vector3(0,3.3,-2.17),0.0032)
	label("X right / F forward\nMODEL: 1 m drawn as 0.5 m",Vector3(-1.5,2.9,-2.16),0.0017)
	numbers=label("",Vector3(1.65,1.95,-2.15),0.0021)
	drawing=Node3D.new();drawing.name="SharedVectors";add_child(drawing)
	var ids=["TURN","SLIDE","FLIP","RESET","RULE"] if projection_mode else ["A/B","X-","X+","F-","F+"]
	console(ids,2.65,"")
	# Small tilted readout on the side, preserving the view across the floor.
	readout.position=Vector3(-2.9,1.18,2.65);readout.rotation_degrees.x=-35;readout.pixel_size=0.0011
	for child in get_children():
		if child is MeshInstance3D and child.position.is_equal_approx(Vector3(0,1.52,2.48)):
			child.position=Vector3(-2.9,1.15,2.61);child.mesh.size=Vector3(2.3,0.58,0.055);child.rotation_degrees.x=-35
	box(Vector3(-2.9,0.53,2.6),Vector3(0.15,1.06,0.22),material("14272e"),true)
	if not projection_mode:
		box(Vector3(0,0.94,3.18),Vector3(3.8,0.16,0.45),material("263a44"),true)
		var extra=["SWAP","SHIFT","SAME","RESET","RULE"]
		for i in extra.size():
			var id: String=extra[i];var button=PUSH.instantiate();button.position=Vector3((i-2)*0.7,1.04,3.18);button.scale=Vector3.ONE*1.15
			add_child(button);buttons[id]=button;button.pressed.connect(act.bind(id))
			var caption=label(id,button.position+Vector3(0,0.06,0.16),0.00095);caption.rotation_degrees.x=-55
		add_to_group("vector_gap_sources");refresh();set_process(false)
	else:
		refresh();connect_source()

func connect_source() -> void:
	if is_instance_valid(source):return
	for candidate in get_tree().get_nodes_in_group("vector_gap_sources"):
		if candidate!=self and candidate.hall_owner()==hall_owner():
			source=candidate;source.contributions_changed.connect(refresh);refresh();set_process(false);return

func _process(_delta: float) -> void:
	connect_source()

func point(v: Vector2, wall: bool) -> Vector3:
	return Vector3(-1.5+v.x*0.5,1.8+v.y*0.5,-2.10) if wall else Vector3(v.x*0.5,0.19,-v.y*0.5)

func line(start: Vector3, end: Vector3, mat: Material, tip: bool=true) -> void:
	var d=end-start
	if d.length()<0.00001:return
	var mesh=MeshInstance3D.new();var cylinder=CylinderMesh.new();cylinder.top_radius=0.022;cylinder.bottom_radius=0.022;cylinder.height=d.length();cylinder.radial_segments=8
	mesh.mesh=cylinder;mesh.material_override=mat;drawing.add_child(mesh);mesh.position=(start+end)*0.5;mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
	if tip:
		var head=MeshInstance3D.new();var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.07;cone.height=0.14;cone.radial_segments=8
		head.mesh=cone;head.material_override=mat;drawing.add_child(head);head.position=end-d.normalized()*0.07;head.quaternion=mesh.quaternion

func refresh() -> void:
	if projection_mode:
		if not is_instance_valid(source):
			numbers.text="Waiting for this hall's\nsubtraction station.";return
		a=source.a;b=source.b
	gap=a-b
	kept=axis*gap.dot(axis)
	remainder=gap-kept
	for child in drawing.get_children():drawing.remove_child(child);child.queue_free()
	for wall in [false,true]:
		if projection_mode:
			line(point(-axis*2,wall),point(axis*2,wall),rail,false)
			line(point(Vector2.ZERO,wall),point(gap,wall),cyan)
			line(point(Vector2.ZERO,wall)+Vector3(0,0.03,0.02),point(kept,wall)+Vector3(0,0.03,0.02),amber)
			line(point(kept,wall),point(gap,wall),pink)
		else:
			line(point(Vector2.ZERO,wall),point(a,wall),amber)
			line(point(Vector2.ZERO,wall),point(b,wall),pink)
			line(point(b,wall)+Vector3(0,0.025,0.02),point(a,wall)+Vector3(0,0.025,0.02),cyan)
	if not projection_mode:
		box(point(a,false)+Vector3(0,0.11,0),Vector3.ONE*0.2,amber,false,drawing)
		box(point(b,false)+Vector3(0,0.11,0),Vector3.ONE*0.2,pink,false,drawing)
		readout.text="Editing %s / 0.5 m steps\nSHIFT moves both addresses.\n%s" % ["A" if selected_a else "B",notice if notice else "Input components limited to +/-1.5 m."]
		numbers.text=("A = %s m\nB = %s m\n\nA-B = %s m\n|A-B| = %.2f m\n\ngap = a - b" % [fmt(a),fmt(b),fmt(gap),gap.length()]) if revealed else "Amber A. Pink B.\nCyan goes from B to A.\n\nSWAP their roles.\nThen move both with SHIFT.\nWhat survives?\n\nSAME brings them together.\nRULE opens the numbers."
		contributions_changed.emit()
	else:
		readout.text="LIVE GAP from subtraction\nTURN: rail +30 degrees\n%s" % [notice if notice else "SLIDE moves A across the rail."]
		numbers.text=("gap = %s m\nkept = %s m\nrest = %s m\n\nsigned length = %.2f m\nrest.dot(axis) = %.3f m\n\nkept + rest = gap" % [fmt(gap),fmt(kept),fmt(remainder),gap.dot(axis),remainder.dot(axis)]) if revealed else "Cyan: the incoming gap.\nGold: along the rail.\nPink: what remains.\n\nSLIDE across the rail.\nDoes gold move?\n\nTURN the rail.\nRULE opens the numbers."

func fmt(v: Vector2) -> String:
	return "(%.2f, %.2f)" % [v.x,v.y]

func fits(v: Vector2) -> bool:
	return absf(v.x)<=1.50001 and absf(v.y)<=1.50001

func reset_inputs() -> void:
	a=Vector2(1,0.5);b=Vector2(-0.5,0);shift_sign=1;notice="";refresh()

func act(id: String) -> void:
	notice=""
	if id=="RULE":revealed=not revealed;refresh();return
	if projection_mode:
		if not is_instance_valid(source):connect_source();return
		match id:
			"TURN":axis=axis.rotated(PI/6).normalized();slide_sign=1
			"FLIP":axis=-axis;slide_sign=1
			"RESET":axis=Vector2.RIGHT;slide_sign=1;source.reset_inputs()
			"SLIDE":
				var step=Vector2(-axis.y,axis.x)*0.5*slide_sign
				if source.fits(source.a+step):source.a+=step;slide_sign=-slide_sign;source.refresh()
				else:notice="A reached the source's input limit."
		refresh();return
	match id:
		"A/B":selected_a=not selected_a
		"SWAP":var old=a;a=b;b=old
		"SAME":b=a
		"RESET":reset_inputs();return
		"SHIFT":
			var step=Vector2(0.5*shift_sign,0)
			if fits(a+step) and fits(b+step):a+=step;b+=step;shift_sign=-shift_sign
			else:notice="SHIFT refused: an address reached its limit."
		_:
			var v=a if selected_a else b
			match id:
				"X-":v.x-=0.5
				"X+":v.x+=0.5
				"F-":v.y-=0.5
				"F+":v.y+=0.5
			if fits(v):
				if selected_a:a=v
				else:b=v
			else:notice="Input limit reached."
	refresh()
