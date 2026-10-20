extends Node3D
## Eight removable cards on a laced, kinematic belt. The belt is the deck order.
## It advances only during indexing; hooks and shuttle wait for the card to seat.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const COUNT := 8
const PITCH := .48
const RADIUS := .20
const LENGTH := COUNT * PITCH
const STRAIGHT := (LENGTH - TAU * RADIUS) * .5
const TOP := 2.23
const X := -1.55
const Z := .16
const CARD_SCALE := Vector3(1.45, 1.6, 1.0)
var phase := 0.0
var from_phase := 0.0
var to_phase := 0.0
var frames: Array[Node3D] = []
var lights: Array[MeshInstance3D] = []
var laces: Array[MeshInstance3D] = []
var drum: Node3D
var caption: Label3D

func _ready() -> void:
	var wood := G.material("654d3c")
	var brass := G.material("b79361", .6)
	var string_mat := G.material("eee0bf")
	for x in [X-.43, X+.43]:
		G.box(self,Vector3(x,1.28,Z-.08),Vector3(.055,2.56,.07),wood,true)
	G.box(self,Vector3(X,.055,Z),Vector3(.98,.11,.9),wood,true)
	G.box(self,Vector3(X,2.51,Z),Vector3(.95,.09,.60),wood,true)
	# Open frame: both hanging runs and their laces can be seen from the side.
	drum=Node3D.new(); drum.position=Vector3(X,TOP,Z); add_child(drum)
	var cylinder:=MeshInstance3D.new(); var shape:=CylinderMesh.new()
	shape.top_radius=RADIUS-.022; shape.bottom_radius=shape.top_radius
	shape.height=.82; shape.radial_segments=24
	cylinder.mesh=shape; cylinder.rotation.z=PI*.5
	cylinder.material_override=wood; drum.add_child(cylinder)
	for i in range(8):
		var a:=TAU*i/8.0
		G.box(drum,Vector3(0,sin(a)*.18,cos(a)*.18),Vector3(.86,.012,.012),brass)
	# A fixed reading window, immediately in front of the seated card.
	for y in [-.19,.19]:
		G.box(self,Vector3(X,TOP+y,Z+RADIUS+.036),Vector3(.83,.023,.027),brass)
	for x in [-.405,.405]:
		G.box(self,Vector3(X+x,TOP,Z+RADIUS+.036),Vector3(.023,.40,.027),brass)
	G.box(self,Vector3(-.71,2.51,Z),Vector3(.86,.035,.035),brass)
	caption=G.label(self,"CARD 01 → READER",Vector3(X,2.70,Z+.22),14)
	G.label(self,"LACED CARD CHAIN",Vector3(X,.49,Z+.40),14)
	G.label(self,"GRAB A CARD · REPLACE IN AN EMPTY FRAME",Vector3(X,.39,Z+.40),9)
	for i in range(COUNT):
		var frame:=Node3D.new(); add_child(frame); frames.append(frame)
		for y in [-.17,.17]: G.box(frame,Vector3(0,y,-.022),Vector3(.76,.012,.012),brass)
		lights.append(G.box(frame,Vector3(-.386,0,0),Vector3(.018,.23,.018),brass))
		G.label(frame,str(i+1),Vector3(.394,0,.018),10)
		for side in [-1,1]:
			var lace:=MeshInstance3D.new(); lace.material_override=string_mat
			add_child(lace); laces.append(lace)
	update_geometry()

func path_frame(distance: float) -> Transform3D:
	var d:=fposmod(distance,LENGTH)
	var p:=Vector3(X,TOP,Z+RADIUS)
	var angle:=0.0
	if d<STRAIGHT:
		p.y-=d
	elif d<STRAIGHT+PI*RADIUS:
		var a:=(d-STRAIGHT)/RADIUS
		p.y=TOP-STRAIGHT-sin(a)*RADIUS; p.z=Z+cos(a)*RADIUS
		angle=a
	elif d<2.0*STRAIGHT+PI*RADIUS:
		p.y=TOP-STRAIGHT+(d-STRAIGHT-PI*RADIUS); p.z=Z-RADIUS
		angle=PI
	else:
		var a:=(d-2.0*STRAIGHT-PI*RADIUS)/RADIUS
		p.y=TOP+sin(a)*RADIUS; p.z=Z-cos(a)*RADIUS
		angle=PI+a
	return Transform3D(Basis(Vector3.RIGHT,angle),p)

func slot_frame(slot: int) -> Transform3D:
	return path_frame((slot-phase)*PITCH)

func begin_move(slot: int, first_pick: bool) -> void:
	from_phase=phase
	var steps:=fposmod(float(slot)-phase,COUNT)
	# A chain with only one remaining card still makes a whole revolution.
	if steps<.0001 and not first_pick: steps=COUNT
	to_phase=phase+steps

func move_to(amount: float) -> void:
	phase=lerpf(from_phase,to_phase,smoothstep(0.0,1.0,clampf(amount,0.0,1.0)))
	update_geometry()

func focus(slot: int) -> void:
	phase=float(slot); from_phase=phase; to_phase=phase; update_geometry()

func update_geometry() -> void:
	if frames.is_empty(): return
	drum.rotation.x=-phase*PITCH/RADIUS
	for i in range(COUNT):
		frames[i].transform=slot_frame(i)
		for side in range(2):
			var points:=PackedVector3Array()
			# Lace connects the short edges of neighbours, continuing through a vacancy.
			for j in range(6):
				var d:=(i-phase)*PITCH+lerpf(.154,PITCH-.154,float(j)/5.0)
				var f:=path_frame(d)
				points.append(f*Vector3(-.30 if side==0 else .30,0,.012))
			laces[i*2+side].mesh=G.tube(points,.005)
