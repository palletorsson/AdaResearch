extends Node3D
## Four open sightlines. Rods remain where the visitor releases them.
## The wall drawings stay fixed, so a moved body can disagree with its first view.
const LINE := preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const DETAIL := preload("res://commons/scenes/em/em_detail.gd")
const KIT := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
var lines: Array[Node3D] = []
var first_poses: Array[Transform3D] = []

func get_artifact_reaction_targets() -> Array:
	# Each held rod is an example. A strike must not erase all four lanes.
	var targets: Array = lines.duplicate()
	for child in get_children():
		if child is MeshInstance3D: targets.append(child)
	return targets

const LANES := [-8.0,-3.0,2.0,7.0]
const TITLES := ["TWO LINES / + AND X", "PARALLEL / BETWEEN", "VERTICAL / HORIZON", "MORE LINES / GRID"]

func _ready() -> void:
	for i in range(4):
		var x: float = LANES[i]
		floor_words(TITLES[i],Vector3(x,0.016,-3.3),Vector2(3.4,0.2))
		# A small empty viewing mark gives the eye a place to start, not a cage.
		paint(Vector3(x-0.38,0.012,-3.9),Vector3(x+0.38,0.012,-3.9),0.04,Color("282b30"))
	# Two pairs: same spans, different relations. The skins have thickness,
	# so the two bars occupy slightly separated depth planes.
	rod("plus_horizontal",Vector3(-8,1.35,0),Vector3.RIGHT,2.0,"stick")
	rod("plus_vertical",Vector3(-8,1.35,0.07),Vector3.UP,2.0,"stick")
	rod("cross_a",Vector3(-8,1.35,4),Vector3(1,1,0).normalized(),2.0,"stick")
	rod("cross_b",Vector3(-8,1.35,4.07),Vector3(1,-1,0).normalized(),2.0,"stick")
	rod("rail_a",Vector3(-3.65,1.0,1.0),Vector3.BACK,3.0,"plank")
	rod("rail_b",Vector3(-2.35,1.0,1.0),Vector3.BACK,3.0,"plank")
	rod("measure_a",Vector3(-3,1.05,5.0),Vector3.RIGHT,2.0,"measure")
	rod("measure_b",Vector3(-3,1.45,5.0),Vector3.RIGHT,2.0,"measure")
	rod("upright_a",Vector3(1.15,1.25,1),Vector3.UP,2.4,"beam")
	rod("upright_b",Vector3(2.85,1.25,1),Vector3.UP,2.4,"beam")
	rod("horizon",Vector3(2,1.55,4.0),Vector3.RIGHT,3.2,"light")
	for k in range(3):
		var v: float = (k-1)*0.8
		rod("grid_horizontal_%d"%k,Vector3(7,1.35+v,1.0),Vector3.RIGHT,2.4,"stick")
		rod("grid_vertical_%d"%k,Vector3(7+v,1.35,1.08),Vector3.UP,2.4,"stick")
	# A sparse spatial grid beyond the planar one: walking sideways separates
	# its depth planes. It deliberately offers no fitted surfaces.
	rod("depth_a",Vector3(6.2,1.25,5.0),Vector3.BACK,2.4,"beam")
	rod("depth_b",Vector3(7.8,1.25,5.0),Vector3.BACK,2.4,"beam")
	rod("depth_cross",Vector3(7,1.25,5.0),Vector3.RIGHT,2.4,"stick")
	floor_words("GRAB A LINE. LEAVE ANOTHER ARRANGEMENT.",Vector3(-0.5,0.016,8.0),Vector2(7,0.22))
	wall_studies()
	wall_planks()
	room_perspective()
	# One continuous mark runs right into the east wall, then up its face.
	paint(Vector3(-6,0.016,13.7),Vector3(12.49,0.016,13.7),0.065,Color("202329"))
	paint(Vector3(12.49,0.016,13.7),Vector3(12.49,3.0,13.7),0.065,Color("202329"))
	floor_words("FOLLOW THIS LINE",Vector3(7.5,0.018,14.1),Vector2(3.5,0.23))

func rod(id: String, at: Vector3, direction: Vector3, length_m: float, finish: String) -> void:
	var body := LINE.new()
	body.name=id;body.span=length_m;body.skin=finish
	body.collision_layer=6;body.collision_mask=1
	body.transform=Transform3D(Basis(Quaternion(Vector3.RIGHT,direction)),at)
	add_child(body);lines.append(body);first_poses.append(body.transform)

func paint(a: Vector3, b: Vector3, width: float, colour: Color) -> void:
	var mesh := MeshInstance3D.new();var box := BoxMesh.new()
	box.size=Vector3(a.distance_to(b),width,width);mesh.mesh=box
	mesh.transform=Transform3D(Basis(Quaternion(Vector3.RIGHT,(b-a).normalized())),(a+b)*0.5)
	var mat := StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.8
	mesh.material_override=mat
	if absf(a.y-b.y)<0.0001 and a.y<0.04:
		# Floor marks are thin ink; elevated lines keep their actual thickness.
		box.size.y=0.003
		mesh.position.y=0.012
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func floor_words(words: String, at: Vector3, size_m: Vector2) -> void:
	var label: MeshInstance3D=KIT.stencil(words,size_m,Color("25282d"))
	if label==null:return
	label.rotation_degrees.x=-90;label.rotation_degrees.y=180;label.position=at;add_child(label)

func wall_studies() -> void:
	var z := 18.48
	var ink := Color("25282d")
	paint(Vector3(-9.2,1.6,z),Vector3(-6.8,1.6,z),0.065,ink)
	paint(Vector3(-8,0.4,z),Vector3(-8,2.8,z),0.065,ink)
	# Equal physical gaps on the wall; perspective belongs to the visitor.
	for x in [-3.6,-2.4]:paint(Vector3(x,0.2,z),Vector3(x,3.4,z),0.06,ink)
	paint(Vector3(0.6,1.6,z),Vector3(3.4,1.6,z),0.04,ink)
	paint(Vector3(2,0.05,z),Vector3(2,3.8,z),0.07,ink)
	for i in range(4):
		var p: float = float(i)*0.65
		paint(Vector3(6+p,0.55,z),Vector3(6+p,2.5,z),0.035,ink)
		paint(Vector3(6,0.55+p,z),Vector3(7.95,0.55+p,z),0.035,ink)

func restore_arrangements() -> void:
	# Native room reset may call this; no automatic snapping interrupts a hand.
	for i in range(lines.size()):
		if not lines[i].is_picked_up():lines[i].transform=first_poses[i]

func wall_planks() -> void:
	# Seven lengths share one angle and section. Account for the section so
	# each lower corner rests on the floor and the upper edge meets the wall.
	var angle := deg_to_rad(70.0)
	var direction := Vector3(cos(angle),sin(angle),0)
	for i in range(7):
		var length_m := 1.0 + float(i)*0.5
		var centre := Vector3(
			12.48 - length_m*0.5*cos(angle) - 0.06*sin(angle),
			length_m*0.5*sin(angle) + 0.06*cos(angle),
			1.0 + float(i)*0.9)
		rod("wall_plank_%d" % (i+1),centre,direction,length_m,"plank")

func room_perspective() -> void:
	# Two strong parallels make one readable depth study. Each of the four
	# neighbouring arrangements keeps its short viewpoint mark, not another rail.
	var ink := Color("202329")
	for x in [-6.4,-1.6]:
		paint(Vector3(x,0.031,-8.15),Vector3(x,0.031,11.5),0.06,ink)
		for k in range(10):
			var z: float = -7.5 + float(k)*2.0
			paint(Vector3(x-0.2,0.031,z),Vector3(x+0.2,0.031,z),0.045,ink)
	# Side canopies put a quiet, actual surface behind the ceiling edge. Most
	# of the roof stays open. The museum still owns its architectural height.
	var ceiling_y: float = DETAIL.CEIL_SOFFIT
	var edge_y := ceiling_y-0.065
	var canopy_width := 2.4
	var edge_x := 12.5-canopy_width
	for side in [-1.0,1.0]:
		var soffit := MeshInstance3D.new()
		soffit.name="CeilingStripLeft" if side<0 else "CeilingStripRight"
		var box := BoxMesh.new();box.size=Vector3(canopy_width,0.12,26.4)
		soffit.mesh=box;soffit.position=Vector3(side*(12.5-canopy_width*0.5),ceiling_y+0.06,4.75)
		var mat := StandardMaterial3D.new();mat.albedo_color=Color("e5e1d8");mat.roughness=0.9
		soffit.material_override=mat;add_child(soffit)
		paint(Vector3(side*edge_x,edge_y,-8.45),Vector3(side*edge_x,edge_y,17.95),0.12,ink)
	# Closer and thicker than the first version: the separation should be
	# visible during an ordinary step, rather than requiring a diagram.
	var eye := Vector3(-4,1.65,-7)
	var edge_a := Vector3(-edge_x,edge_y,-5.5)
	var edge_b := Vector3(-edge_x,edge_y,16.5)
	var fraction := 0.38
	var a := eye.lerp(edge_a,fraction)
	var b := eye.lerp(edge_b,fraction)
	paint(a,b,0.12*fraction,ink)
	get_child(get_child_count()-1).name="DetachedCeilingLine"
	set_meta("alignment_eye",eye)
	set_meta("alignment_edge",[edge_a,edge_b])
	set_meta("alignment_line",[a,b])
	# Alignment occurs along a plane of possible eyes, not one privileged
	# height. A short lateral strip lets lower/taller visitors find their view.
	paint(Vector3(-5.5,0.012,-7),Vector3(-2.5,0.012,-7),0.045,ink)
	floor_words("FIND THE EDGE. STEP ASIDE.",Vector3(-4,0.016,-7.65),Vector2(4.4,0.23))
