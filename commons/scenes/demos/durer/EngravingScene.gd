extends "res://commons/scenes/demos/durer/DurerScene.gd"
## A walk-around sculptural interpretation of Melencolia I, after the engraving.
## Front is +Z. Projected relationships follow the print; depths are authored.
## Nothing here claims to recover an exact room or a single symbolic meaning.

const SOLID = preload("res://commons/scenes/demos/durer/DurerPolyhedron.gd")
const NUMBERS = [[16,3,2,13],[5,10,11,8],[9,6,7,12],[4,15,14,1]]
var groups: Dictionary = {}
var ivory: StandardMaterial3D
var stone: StandardMaterial3D
var dark: StandardMaterial3D
var wood: StandardMaterial3D
var iron: StandardMaterial3D
var paper: StandardMaterial3D
var solid: MeshInstance3D
var _built := false

func _ready() -> void:
	_build_engraving()
	_captured = false
	super._ready()

func apply_grid_config(config_data: Dictionary) -> void:
	if not _built:
		for key in config_data: set_meta("config_%s" % str(key), config_data[key])
		return
	super.apply_grid_config(config_data)

func _group(title: String, at := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = title; n.position = at; add_child(n); groups[title] = n
	return n

func _mat(hex: String, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex); m.roughness = rough; m.metallic = metal
	return m

func _mesh(parent: Node3D, title: String, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title; n.mesh = shape; n.material_override = mat
	parent.add_child(n); n.position = at
	return n

func _box(parent: Node3D, title: String, at: Vector3, dims: Vector3, mat: Material, collide := false) -> MeshInstance3D:
	var shape := BoxMesh.new(); shape.size = dims
	var n := _mesh(parent,title,shape,at,mat)
	if collide:
		var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
		var c := CollisionShape3D.new(); var s := BoxShape3D.new(); s.size = dims
		c.shape = s; body.add_child(c); n.add_child(body)
	return n

func _ellipsoid(parent: Node3D, title: String, at: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new(); shape.radius = 1; shape.height = 2
	shape.radial_segments = 24; shape.rings = 12
	var n := _mesh(parent,title,shape,at,mat); n.scale = radii
	return n

func _rod(parent: Node3D, title: String, a: Vector3, b: Vector3, radius: float, mat: Material, radius_top := -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new(); shape.top_radius = radius if radius_top < 0 else radius_top
	shape.bottom_radius = radius; shape.height = a.distance_to(b); shape.radial_segments = 12
	var n := _mesh(parent,title,shape,(a+b)*0.5,mat)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return n

func _ring(parent: Node3D, title: String, at: Vector3, inner: float, outer: float, mat: Material) -> MeshInstance3D:
	var shape := TorusMesh.new(); shape.inner_radius = inner; shape.outer_radius = outer
	shape.rings = 40; shape.ring_segments = 10
	var n := _mesh(parent,title,shape,at,mat); n.rotation.x = PI/2
	return n

func _label(parent: Node3D, title: String, words: String, at: Vector3, font_pixels: int, pixel_size: float) -> Label3D:
	var n := Label3D.new(); n.name = title; n.text = words; n.font_size = font_pixels
	n.pixel_size = pixel_size; n.outline_size = 0; n.modulate = Color("39372f")
	n.no_depth_test = false; parent.add_child(n); n.position = at
	return n

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var norm := (b-a).cross(c-a).normalized()
	# Godot uses clockwise front winding.
	for p in [a,c,b]: st.set_normal(norm); st.add_vertex(p)

func _cloth(parent: Node3D, title: String, rings: Array, folds: int, mat: Material) -> MeshInstance3D:
	# Rings: centre, horizontal radius, depth radius, pleat amplitude. Irregular
	# folds belong to the silhouette as well as to its lighting; no texture trick.
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 96
	var rows: Array = []
	for j in range(rings.size()):
		var row: Array[Vector3] = []; var r: Array = rings[j]
		for i in range(count):
			var a := TAU*i/count
			var fold := float(r[3])*(sin(a*folds+float(j)*0.26)+0.3*sin(a*(folds+3)))
			row.append(r[0]+Vector3(cos(a)*(float(r[1])+fold),0,sin(a)*(float(r[2])+fold)))
		rows.append(row)
	for j in range(rows.size()-1):
		for i in range(count):
			var k := (i+1)%count
			_tri(st,rows[j][i],rows[j+1][i],rows[j][k])
			_tri(st,rows[j][k],rows[j+1][i],rows[j+1][k])
	return _mesh(parent,title,st.commit(),Vector3.ZERO,mat)

func _feather(parent: Node3D, a: Vector3, b: Vector3, width: float, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v := (b-a).normalized(); var side := v.cross(Vector3.FORWARD).normalized()*width
	var mid := a.lerp(b,0.45)+Vector3(0,0,0.08)
	for pair in [[a,mid+side,b],[a,b,mid-side]]:
		_tri(st,pair[0],pair[1],pair[2]); _tri(st,pair[2],pair[1],pair[0])
	_mesh(parent,"Feather",st.commit(),Vector3.ZERO,mat)
	_rod(parent,"Quill",a,b,0.009,stone)

func _build_engraving() -> void:
	if _built:return
	_built = true
	ivory = _mat("d8d3c5"); stone = _mat("aaa79b"); dark = _mat("4b4941")
	wood = _mat("777164"); iron = _mat("555752",0.43,0.55); paper = _mat("e5e0d2")
	_architecture(); _polyhedron()
	if str(get_meta("config_figure", "")) == "skull": _skull_study()
	else: _main_figure()
	_putto(); _dog(); _instruments(); _tools(); _sky()
	var sphere := _group("Sphere",Vector3(-2.25,0.43,2.05))
	var ball := _ellipsoid(sphere,"StoneSphere",Vector3.ZERO,Vector3.ONE*0.43,ivory)
	ball.create_convex_collision()
	var key := OmniLight3D.new(); key.name = "WarmSculptureLight"; add_child(key)
	key.position = Vector3(3.0,4.4,3.5); key.light_color = Color("fff5df")
	key.light_energy = 1.7; key.omni_range = 10; key.shadow_enabled = true
	var fill := OmniLight3D.new(); fill.name = "HorizonFill"; add_child(fill)
	fill.position = Vector3(-3.0,3.5,1.0); fill.light_color = Color("e0e5ee")
	fill.light_energy = 0.55; fill.omni_range = 7

func _architecture() -> void:
	var g := _group("Architecture")
	_box(g,"RearWall",Vector3(1.2,2.65,-1.8),Vector3(3.65,5.3,0.28),ivory,true)
	_box(g,"ReturnWall",Vector3(3.1,2.65,-0.8),Vector3(0.22,5.3,2.3),stone,true)
	_box(g,"Cornice",Vector3(1.3,5.25,-1.58),Vector3(4.0,0.14,0.32),paper)
	_box(g,"SeatStep",Vector3(1.45,0.24,0.0),Vector3(2.65,0.48,1.6),stone,true)
	_box(g,"PolyhedronStep",Vector3(-1.85,0.12,-0.5),Vector3(2.5,0.24,2.35),stone,true)
	_label(g,"Date","1514 · AD",Vector3(2.1,0.26,0.817),32,0.003)
	# Subtle mortar joints in the architectural surface; one wall, not many cubes.
	for y in [0.8,1.6,2.4,3.2,4.0,4.8]:
		_rod(g,"Mortar",Vector3(-0.6,y,-1.653),Vector3(2.99,y,-1.653),0.006,stone)

func _polyhedron() -> void:
	var g := _group("Polyhedron",Vector3(-1.85,1.365,-0.15))
	solid = SOLID.new(); solid.name = "TruncatedRhombohedron"; solid.size = 0.75
	solid.rotation_degrees.y = -12; solid.material = stone; g.add_child(solid)
	solid.create_convex_collision()

func _main_figure() -> void:
	var g := _group("Melencolia",Vector3(1.35,0.0,0.25))
	# Seated body: the skirt spreads across knees and drops over the stone step.
	_cloth(g,"PleatedSkirt",[
		[Vector3(0.12,0.14,0.45),1.0,0.72,0.09],
		[Vector3(0.1,0.5,0.4),0.88,0.71,0.075],
		[Vector3(-0.08,0.95,0.38),0.74,0.69,0.07],
		[Vector3(-0.18,1.3,0.38),0.69,0.62,0.06],
		[Vector3(0.02,1.62,0.0),0.44,0.3,0.025]],18,ivory)
	_cloth(g,"Bodice",[
		[Vector3(0.02,1.6,0),0.44,0.3,0.025],
		[Vector3(0.06,1.87,-0.06),0.43,0.27,0.014],
		[Vector3(0.04,2.12,-0.03),0.54,0.31,0.018],
		[Vector3(-0.04,2.28,-0.01),0.4,0.23,0.018]],16,ivory)
	_ellipsoid(g,"Neck",Vector3(-0.12,2.4,0),Vector3(.16,.24,.16),ivory)
	var head := Node3D.new(); head.name="HeadInclinedIntoHand";g.add_child(head)
	head.position=Vector3(-0.19,2.68,0.08);head.rotation_degrees=Vector3(-4,-32,-12)
	_ellipsoid(head,"HairMass",Vector3(0,0,-0.09),Vector3(.29,.35,.26),wood)
	_ellipsoid(head,"Face",Vector3(0,-0.015,0.045),Vector3(.225,.285,.19),ivory)
	_rod(head,"Nose",Vector3(0,.06,.22),Vector3(0,-.08,.26),.033,stone,.026)
	for x in [-0.085,0.085]:
		_rod(head,"Brow",Vector3(x-.046,.085,.213),Vector3(x+.044,.062,.215),.013,stone)
		_rod(head,"Eye",Vector3(x-.025,.04,.216),Vector3(x+.028,.035,.216),.004,dark)
	_rod(head,"ClosedMouth",Vector3(-.065,-.15,.201),Vector3(.055,-.154,.199),.005,stone)
	for i in range(15):
		var a:=TAU*i/15
		_ellipsoid(head,"WreathLeaf",Vector3(.265*cos(a),.24,.23*sin(a)),Vector3(.06,.032,.11),stone)
	for side in [-1,1]:
		for i in range(4):
			_rod(g,"HairLock",Vector3(-.19+side*(.2+.024*i),2.74,-.04-.025*i),Vector3(-.15+side*(.28+.04*i),2.14+.07*i,.02),.028,wood)
	# Bent left arm carries the head; the right rests across the book.
	_rod(g,"LeftSleeveUpper",Vector3(-.4,2.14,.01),Vector3(-.64,1.73,.53),.17,ivory,.135)
	_rod(g,"LeftSleeveForearm",Vector3(-.64,1.73,.53),Vector3(-.43,2.4,.26),.13,ivory,.085)
	_ellipsoid(g,"FistUnderCheek",Vector3(-.43,2.44,.26),Vector3(.105,.14,.10),ivory)
	_rod(g,"RightSleeveUpper",Vector3(.47,2.12,0),Vector3(.58,1.62,.31),.18,ivory,.14)
	_rod(g,"RightSleeveForearm",Vector3(.58,1.62,.31),Vector3(-.21,1.5,.74),.12,ivory,.08)
	_ellipsoid(g,"CompassHand",Vector3(-.22,1.52,.73),Vector3(.13,.08,.09),ivory)
	var book := _box(g,"BookOnLap",Vector3(-.05,1.4,.62),Vector3(.85,.08,.55),wood)
	book.rotation_degrees=Vector3(12,0,-8)
	var pages:=_box(g,"BookPages",Vector3(-.05,1.425,.63),Vector3(.78,.05,.50),paper);pages.rotation=book.rotation
	for x in [-.28,.24]:
		_rod(g,"CompassLeg",Vector3(-.22,1.68,.82),Vector3(x-.22,.73,1.04),.018,iron,.009)
	_ring(g,"CompassHinge",Vector3(-.22,1.68,.842),.017,.037,iron)
	for i in range(3):
		var x:=.4+i*.065
		_ring(g,"KeyBow",Vector3(x,1.32,.53),.035,.05,iron)
		_rod(g,"KeyStem",Vector3(x,1.3,.53),Vector3(x,1.03-.025*i,.63),.012,iron)
		_box(g,"KeyTooth",Vector3(x+.028,1.03-.025*i,.63),Vector3(.067,.024,.024),iron)
	_ellipsoid(g,"Slipper",Vector3(.53,.15,1.04),Vector3(.21,.13,.37),wood)
	# Two feathered wings arc above the shoulders, as reliefs with real depth.
	for i in range(19):
		var t:=float(i)/18
		_feather(g,Vector3(.25+.24*t,1.75,-.39),Vector3(.64+1.0*t,3.37-.75*t,-.47-.22*sin(t*PI)),.1,ivory)
	for i in range(12):
		var t:=float(i)/11
		_feather(g,Vector3(-.2,1.86,-.47),Vector3(-.7-.52*t,3.08-.77*t,-.60),.075,stone)
	# Collision follows the seated volume, not the entire tableau footprint.
	var body:=StaticBody3D.new();body.name="SeatedBody";body.collision_layer=1;body.collision_mask=0;g.add_child(body)
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(1.55,2.7,1.55);c.shape=shape;c.position=Vector3(0,1.35,.3);body.add_child(c)

func _putto() -> void:
	var g:=_group("PuttoAndMillstone",Vector3(-.35,0,-.55))
	var mill:=_ring(g,"Millstone",Vector3(0,.68,0),.12,.72,stone)
	mill.scale.y=.33;mill.rotation_degrees.x=90
	for i in range(18):
		var a:=TAU*i/18
		_rod(g,"MillstoneGroove",Vector3(.22*cos(a),.68+.22*sin(a),.24),Vector3(.65*cos(a+.10),.68+.65*sin(a+.1),.24),.006,wood)
	_ellipsoid(g,"ChildTorso",Vector3(.0,1.69,.02),Vector3(.23,.3,.17),ivory)
	_ellipsoid(g,"ChildHead",Vector3(-.02,2.1,.11),Vector3(.21,.24,.2),ivory)
	for i in range(10):
		var a:=TAU*i/10
		_ellipsoid(g,"Curl",Vector3(-.02+.18*cos(a),2.21,.1+.16*sin(a)),Vector3.ONE*.065,wood)
	for x in [-.13,.13]:
		_rod(g,"ChildThigh",Vector3(x,1.52,0),Vector3(x,1.34,.34),.105,ivory)
		_rod(g,"ChildLeg",Vector3(x,1.34,.34),Vector3(x,.99,.37),.075,ivory)
		_ellipsoid(g,"ChildFoot",Vector3(x,1.0,.44),Vector3(.08,.065,.15),ivory)
	var tablet:=_box(g,"DrawingTablet",Vector3(0,1.5,.39),Vector3(.42,.03,.32),wood);tablet.rotation_degrees.x=28
	for side in [-1,1]:
		_rod(g,"ChildArm",Vector3(side*.21,1.86,.03),Vector3(side*.19,1.57,.43),.07,ivory)
		for i in range(5):_feather(g,Vector3(side*.12,1.6,-.11),Vector3(side*(.32+.055*i),1.9+.03*i,-.15),.05,ivory)
	_rod(g,"Stylus",Vector3(.13,1.64,.42),Vector3(.06,1.48,.51),.009,iron)

func _dog() -> void:
	var g:=_group("RestingDog",Vector3(-1.65,.0,1.25))
	_ellipsoid(g,"CurledBody",Vector3(0,.34,0),Vector3(.62,.29,.35),stone)
	_ellipsoid(g,"Hip",Vector3(-.45,.29,.05),Vector3(.27,.25,.3),stone)
	_ellipsoid(g,"Shoulder",Vector3(.43,.27,.11),Vector3(.22,.24,.24),stone)
	for x in [.12,.3]:_ellipsoid(g,"FoldedPaw",Vector3(x,.08,.48),Vector3(.27,.07,.09),ivory)
	_ellipsoid(g,"HeadOnPaws",Vector3(.39,.19,.44),Vector3(.22,.14,.2),stone)
	_ellipsoid(g,"Muzzle",Vector3(.49,.15,.56),Vector3(.15,.07,.1),ivory)
	_ellipsoid(g,"Nose",Vector3(.59,.16,.59),Vector3(.055,.038,.047),dark)
	_ellipsoid(g,"FoldedEar",Vector3(.27,.22,.41),Vector3(.07,.13,.14),wood)
	for i in range(5):
		var x:=-.22+i*.085
		_rod(g,"Rib",Vector3(x,.43,.27),Vector3(x-.02,.24,.32),.009,wood)
	for i in range(12):
		var a:=.2+2.2*i/12;var b:=.2+2.2*(i+1)/12
		_rod(g,"CurledTail",Vector3(-.23+.56*cos(a),.08,.07+.4*sin(a)),Vector3(-.23+.56*cos(b),.08,.07+.4*sin(b)),.027,wood)

func _instruments() -> void:
	var g:=_group("Ladder")
	for x in [-.33,.33]:
		_rod(g,"Rail",Vector3(-1.0+x,0,-.9),Vector3(-.45+x,5.65,-1.99),.047,wood)
	for i in range(11):
		var t:=(float(i)+.7)/11
		var p:=Vector3(-1,0,-.9).lerp(Vector3(-.45,5.65,-1.99),t)
		_rod(g,"Rung",p+Vector3(-.33,0,0),p+Vector3(.33,0,0),.036,wood)
	g=_group("Scales",Vector3(-.05,4.15,-1.33))
	_rod(g,"Hook",Vector3(0,.45,-.28),Vector3(0,.4,0),.017,iron)
	_rod(g,"Suspension",Vector3(0,.4,0),Vector3(0,0,0),.012,iron)
	_rod(g,"BalanceArm",Vector3(-.46,0,0),Vector3(.46,0,0),.02,iron)
	for x in [-.43,.43]:
		for k in [-1,1]:_rod(g,"PanChain",Vector3(x,0,0),Vector3(x+k*.15,-.6,0),.008,iron)
		var pan:=_ellipsoid(g,"BalancePan",Vector3(x,-.61,0),Vector3(.23,.045,.17),iron)
		pan.set_meta("not_interactive",true)
	g=_group("Hourglass",Vector3(.93,4.39,-1.39))
	for y in [-.43,.43]:_box(g,"HourglassCap",Vector3(0,y,0),Vector3(.45,.07,.3),wood)
	for x in [-.18,.18]:_rod(g,"HourglassColumn",Vector3(x,-.4,.1),Vector3(x,.4,.1),.025,wood)
	var glass:=_mat("c9d1ce",.16,.12)
	_rod(g,"UpperBulb",Vector3(0,0,0),Vector3(0,.36,0),.025,glass,.155)
	_rod(g,"LowerBulb",Vector3(0,-.36,0),Vector3(0,0,0),.155,glass,.025)
	_rod(g,"FallingSand",Vector3(0,-.2,.13),Vector3(0,.15,.13),.007,wood)
	g=_group("MagicSquare",Vector3(2.1,4.01,-1.59))
	_box(g,"IncisedPanel",Vector3.ZERO,Vector3(1.12,1.12,.07),stone)
	for i in range(5):
		var p:=-.5+.25*i
		_rod(g,"Grid",Vector3(p,-.5,.05),Vector3(p,.5,.05),.006,wood)
		_rod(g,"Grid",Vector3(-.5,p,.05),Vector3(.5,p,.05),.006,wood)
	for row in range(4):
		for col in range(4):
			var number:=_label(g,"Number_%d_%d"%[row,col],str(NUMBERS[row][col]),Vector3(-.375+.25*col,.375-.25*row,.052),64,.0025)
			# The printed 5 is inverted; the 9 is reversed. Numerical values stay unchanged.
			if row==1 and col==0:number.rotation.z=PI
			if row==2 and col==0:number.scale.x=-1
	g=_group("Bell",Vector3(2.13,5.00,-1.29))
	_ring(g,"BellHook",Vector3(0,.29,0),.053,.076,iron)
	_rod(g,"BellCrown",Vector3(0,-.03,0),Vector3(0,.21,0),.11,iron,.067)
	_rod(g,"BellFlare",Vector3(0,-.23,0),Vector3(0,-.03,0),.24,iron,.11)
	_ellipsoid(g,"Clapper",Vector3(0,-.28,0),Vector3(.04,.08,.04),dark)
	_rod(g,"BellCord",Vector3(.24,.3,-.12),Vector3(.48,-1.9,.23),.008,wood)

func _tools() -> void:
	var g:=_group("GroundTools")
	var plane:=_box(g,"CarpentersPlane",Vector3(-1.26,.1,2.46),Vector3(.76,.17,.25),wood)
	plane.rotation.y=-.3
	_rod(g,"PlaneHandle",Vector3(-1.51,.17,2.46),Vector3(-1.55,.39,2.46),.045,wood)
	var blade:=_box(g,"PlaneBlade",Vector3(-1.22,.25,2.46),Vector3(.08,.3,.17),iron);blade.rotation.z=-.3
	_rod(g,"HammerHandle",Vector3(-2.5,.07,1.8),Vector3(-1.98,.08,1.46),.025,wood)
	_box(g,"HammerHead",Vector3(-2.05,.09,1.5),Vector3(.14,.11,.28),iron)
	var saw:=_box(g,"SawBlade",Vector3(-.15,.06,2.51),Vector3(.95,.015,.2),iron);saw.rotation.y=-.12
	for i in range(19):_box(g,"SawTooth",Vector3(-.6+i*.045,.06,2.63+i*.006),Vector3(.022,.018,.035),iron)
	_ring(g,"SawHandle",Vector3(.48,.075,2.55),.09,.14,wood).rotation.x=0
	_rod(g,"Ruler",Vector3(-.88,.05,2.12),Vector3(.75,.05,1.94),.018,ivory)
	for i in range(7):_rod(g,"Nail",Vector3(2.0+i*.09,.04,1.9),Vector3(1.9+i*.11,.04,2.08),.009,iron)
	_ellipsoid(g,"Purse",Vector3(2.4,.19,1.5),Vector3(.25,.17,.22),wood)
	_ring(g,"PurseTie",Vector3(2.4,.37,1.5),.035,.046,iron).rotation.x=0
	var pot:=_group("Crucible",Vector3(-2.92,.34,-.56))
	_ring(pot,"CrucibleRim",Vector3(0,.18,0),.12,.18,iron).rotation.x=0
	_rod(pot,"CrucibleBody",Vector3(0,0,0),Vector3(0,.18,0),.13,iron,.18)

func _sky() -> void:
	var g:=_group("DistantHorizon",Vector3(-1.98,3.07,-2.09))
	_box(g,"SkyRelief",Vector3.ZERO,Vector3(2.67,4.39,.09),_mat("b8bbaf"))
	for i in range(13):
		var y:=-1.6+i*.055
		_rod(g,"Sea",Vector3(-1.29,y,.052),Vector3(1.29,y,.052),.004,stone)
	for i in range(50):
		var a:=.14+2.7*i/50;var b:=.14+2.7*(i+1)/50
		_rod(g,"RainbowArc",Vector3(-.18+1.36*cos(a),.13+1.69*sin(a),.057),Vector3(-.18+1.36*cos(b),.13+1.69*sin(b),.057),.017,ivory)
	var star:=Vector3(.45,.74,.07)
	for i in range(24):
		var a:=TAU*i/24;var length:=.24 if i%2==0 else .4
		_rod(g,"CometRay",star,star+Vector3(cos(a),sin(a),0)*length,.006,paper)
	_ellipsoid(g,"Comet",star,Vector3(.045,.045,.025),paper)
	# The inscription belongs to a wing-shaped relief rather than a floating UI.
	_feather(g,Vector3(-.65,.55,.13),Vector3(-1.19,.92,.13),.15,wood)
	_feather(g,Vector3(-.65,.55,.13),Vector3(-.1,.88,.13),.15,wood)
	_box(g,"Banner",Vector3(-.66,.59,.15),Vector3(1.04,.22,.025),paper)
	_label(g,"MelencoliaTitle","MELENCOLIA I",Vector3(-.66,.59,.17),48,.0022)

func _skull_study() -> void:
	var g := _group("SkullStudy", Vector3(1.35,0,0.25))
	_box(g,"StoneSupport",Vector3(0,.74,.1),Vector3(.58,.52,.52),stone,true)
	var skull:Node3D = load("res://commons/artifacts/primitive_encounters/skull.gd").new()
	skull.name="Skull";skull.position=Vector3(0,1.55,.1);skull.scale=Vector3.ONE*.48
	skull.rotation_degrees.y=-22;g.add_child(skull)
	# This is Ada's variation, not a reconstruction of Dürer's seated figure.
	# Retain feather geometry from the figure so the replacement has real depth.
	for side in [-1,1]:
		var wing := Node3D.new()
		wing.name="LeftWing" if side<0 else "RightWing"
		g.add_child(wing)
		for i in range(16):
			var t := float(i)/15
			var root := Vector3(side*(.16+.18*t),1.45,-.22)
			var tip := Vector3(side*(.50+1.03*t),3.15-.94*t,-.35-.22*sin(t*PI))
			_feather(wing,root,tip,.105,ivory if side>0 else stone)
	_label(g,"Variation","ADA VARIATION · winged skull",Vector3(0,.86,.37),26,.0015)
