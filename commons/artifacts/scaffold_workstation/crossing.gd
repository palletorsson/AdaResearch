extends "workstation.gd"
## The carried integer graph becomes a deck in the Transformation crossing.
## Only its origin changes. Every connection, length and saved record survives.
var fitted_cell:=Vector3.ZERO

func _ready() -> void:
	super._ready()
	# A receiving outline has no floor collision: the learner supplies the surface.
	clear_children(output.get_node("Bay"))
	for x in [0.0,WORLD_UNIT]:Kit.box(output.get_node("Bay"),"SocketGuide",Vector3(x,-.04,WORLD_UNIT*.5),Vector3(.018,.018,WORLD_UNIT),Color("b8b8b8"),false)
	for z in [0.0,WORLD_UNIT]:Kit.box(output.get_node("Bay"),"SocketGuide",Vector3(WORLD_UNIT*.5,-.04,z),Vector3(WORLD_UNIT,.018,.018),Color("b8b8b8"),false)
	var title:Label3D=controls.get_node("InfoCard").get_children().filter(func(n):return n is Label3D)[0]
	title.text="SCAFFOLD / CROSSING"
	# This receiver is to the left of the hand model; keep its sightline clear.
	controls.get_node("InfoCard").position.x=.75
	redraw()

func completed_square() -> Dictionary:
	# Prefer the square nearest the original point. Scanning is deterministic and
	# accepts any horizontal layer, including the lower layer used in Primitives.
	var squares:Array[Dictionary]=[]
	for r in model.records:
		if r.kind not in ["panel","quad"] or r.plane!=[0,2] or float(r.get("span",1))!=1:continue
		if r.kind=="quad":squares.append(r);continue
		if r.half!=0:continue
		var partner:Dictionary=r.duplicate(true);partner.half=1
		if model.has_record(partner):squares.append(r)
	squares.sort_custom(func(a,b):return Model.vec(a.at).length_squared()<Model.vec(b.at).length_squared())
	return {} if squares.is_empty() else squares[0]

func redraw() -> void:
	super.redraw()
	if not _ready_done:return
	feedback.text="Fill a horizontal square: 4 RODS + 2 HALVES or 1 QUAD. BUILD repairs the crossing." if completed_square().is_empty() else "Your square is ready. BUILD fits the same construction into the crossing."

func copy_pose(record:Dictionary) -> Transform3D:
	var pose:Transform3D=Model.pose(record);pose.origin=(pose.origin-fitted_cell)*WORLD_UNIT;return pose

func build_copy() -> bool:
	if not _interactive or is_instance_valid(held):return false
	var square:=completed_square()
	if square.is_empty():
		feedback.text="The gap needs a floor: close one horizontal square with 4 RODS and both HALVES or one QUAD.";return false
	var previous:=fitted_cell
	fitted_cell=Vector3(Model.vec(square.at))
	if not super.build_copy():fitted_cell=previous;return false
	feedback.text="CROSSING BUILT / your square is now a two-metre deck. Walk across it."
	return true
