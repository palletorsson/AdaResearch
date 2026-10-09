extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Presentation only. Mechanisms and their physics belong to the actual artifacts.
@export var hall_number := 1
@export var map_id := ""
var travel_status: Label3D

func _ready() -> void:
	set_meta("em_keep_scale",true)
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/force_halls/curation.json"))
	var row: Dictionary={}
	for candidate in plan.halls+plan.get("archived_halls",[]):
		if candidate.map==map_id:row=candidate; break
	if row.is_empty():row=plan.halls[clampi(hall_number-1,0,plan.halls.size()-1)]
	hall_number=int(row.get("number",hall_number))
	var w: float=row.size[0];var d: float=row.size[1]
	var pale=material("e7e3da");var ink=material("26272a");var rose=material("bb7c96")
	# A slender entrance lectern offers a single action, outside the passage.
	box(Vector3(2.1,0.53,3),Vector3(1.6,1.06,0.4),pale,true)
	box(Vector3(2.1,1.48,3.06),Vector3(1.72,0.35,0.05),pale)
	var l=label("%02d / TELEPORT\n%s" % [hall_number,row.title.to_upper()],Vector3(2.1,1.48,3.02),0.0008)
	l.font_size=48;l.rotation.y=PI;l.modulate=Color("222329")
	# Explicit teleport controls reuse the museum's supported hall arrivals.
	for direction in [-1,1]:
		var b=PUSH.instantiate()
		b.name="PreviousSpace" if direction<0 else "NextSpace"
		b.position=Vector3(2.1-direction*0.48,1.03,2.76)
		b.scale=Vector3.ONE*1.3
		b.rotation.x=-PI/2.0
		b.released_color=Color("bd879f") if direction>0 else Color("969491")
		add_child(b);buttons["NEXT" if direction>0 else "PREVIOUS"]=b
		b.pressed.connect(travel.bind(direction))
		var words=label("NEXT" if direction>0 else "PREVIOUS",b.position+Vector3(0,0.22,-0.04),0.0008)
		words.rotation.y=PI;words.modulate=Color("222329");words.outline_size=0
	travel_status=label("TELEPORT BETWEEN SPACES",Vector3(2.1,0.82,2.77),0.00065)
	travel_status.rotation.y=PI;travel_status.modulate=Color("222329");travel_status.outline_size=0
	# Rear inscription belongs to the architecture, leaving the floor for actions.
	box(Vector3(w*0.5-0.5,3.5,d-1.59),Vector3(minf(w-5,15),1.35,0.09),pale)
	var title=label(row.title.to_upper(),Vector3(w*0.5-0.5,3.15,d-1.65),0.0023)
	title.font_size=108;title.rotation.y=PI;title.modulate=Color("222329")
	var brand=label("ENDLESS MUSEUM   /   always another room",Vector3(w*0.5-0.5,3.85,d-1.65),0.0011)
	brand.font_size=92;brand.rotation.y=PI;brand.modulate=Color("454249")
	for words in [l,title,brand]:words.outline_size=0
	if row.map!="Vectors_Act5_ForceAsPlace":
		# A quiet continuous route around the right side. Flush marks are not ledges.
		for z in range(4,int(d)-3,2):box(Vector3(w-2.0,0.015,z),Vector3(0.045,0.012,0.5),ink)
		for a in row.placements:
			var x: float=a.cell[0];var z: float=a.cell[1];var width: float=a.zone[0];var depth: float=a.zone[1]
			var mat=rose if a.role=="tutorial" else pale
			if a.get("pedestal",false):box(Vector3(x,0.41,z),Vector3(1.9,0.82,1.4),pale,true)
			# Small corner brackets let each experiment hold its own patch of floor.
			for side in [-1,1]:
				box(Vector3(x+side*width/2,0.012,z-depth/2),Vector3(0.045,0.015,0.65),mat)
				box(Vector3(x+side*(width/2-0.3),0.012,z-depth/2-0.3),Vector3(0.65,0.015,0.045),mat)
		# One bench gives the comparisons a place to linger, with walking space around it.
		box(Vector3(2.0,0.24,d*0.57),Vector3(0.7,0.48,2.4),pale,true)
	if row.map=="VFM_08_Arena":
		# A shared receiving tray joins the turret and its real pooled targets.
		box(Vector3(19,0.05,16),Vector3(5,0.1,5),pale,true)
		for x in [16.5,21.5]:box(Vector3(x,0.35,16),Vector3(0.12,0.6,5.1),pale,true)
		for z in [13.5,18.5]:box(Vector3(19,0.35,z),Vector3(5.1,0.6,0.12),pale,true)
		box(Vector3(19,1.45,18.75),Vector3(5.2,2.9,0.12),pale,true)
		box(Vector3(21.65,1.45,16),Vector3(0.12,2.9,5.6),pale,true)
		var caption=label("A TARGET IS CHOSEN",Vector3(19,3,18.65),0.0014)
		caption.rotation.y=PI;caption.modulate=Color("26272a");caption.outline_size=0

func travel(direction: int) -> bool:
	var navigator=get_tree().get_first_node_in_group("museum_portal_navigation")
	if navigator==null or navigator.busy:
		travel_status.text="A MOMENT BETWEEN HALLS"
		return false
	var accepted: bool=navigator.request_crossing(direction)
	if accepted:
		travel_status.text="OPENING THE NEXT SPACE" if direction>0 else "RETURNING TO THE PREVIOUS SPACE"
	else:
		var current: Dictionary=navigator.get("_current")
		var no_history=direction<0 and not current.is_empty() and navigator.museum.call("_freed_index_for_boundary",float(current.z0),-1)<0
		travel_status.text="NO PREVIOUS SPACE ON THIS VISIT" if no_history else "STAND ON A FLOOR TO TELEPORT"
	return accepted
