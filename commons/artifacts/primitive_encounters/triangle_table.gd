extends Node3D
const Kit=preload("geometry.gd")
const Piece=preload("piece.gd")
@export var already_started := false
var pieces: Array[Node3D]=[]
func _ready() -> void:
	already_started=bool(get_meta("config_already_started",already_started))
	Kit.box(self,"Table",Vector3(0,0.78,0),Vector3(3.2,0.09,1.6),Color("bba49b"))
	for x in [-1.35,1.35]:
		for z in [-0.58,0.58]:Kit.box(self,"Leg",Vector3(x,0.38,z),Vector3(0.08,0.76,0.08),Color("514653"))
	# Thin triangular prisms, 46 cm edges. Broad faces start horizontal.
	var verts:=PackedVector3Array()
	for y in [-0.012,0.012]:
		for v in [Vector3(-0.23,y,-0.133),Vector3(0.23,y,-0.133),Vector3(0,y,0.265)]:verts.append(v)
	var faces:=[[0,2,1],[3,4,5],[0,1,4,3],[1,2,5,4],[2,0,3,5]]
	for i in 12:
		var p:=Piece.new();p.name="Triangle%02d"%i
		if already_started:
			p.transform=unfinished_pose(i)
		else:
			p.position=Vector3(-1.15+(i%6)*0.46,0.84,-0.40+(i/6)*0.70)
		Kit.solid(p,"Face",verts,faces,Color("df8cae") if i%2==0 else Color("b8a3d3"),false)
		var shape:=ConvexPolygonShape3D.new();shape.points=verts
		var col:=CollisionShape3D.new();col.shape=shape;p.add_child(col)
		add_child(p);pieces.append(p)
	Kit.box(self,"InstructionPlate",Vector3(0,1.12,-0.78),Vector3(2.05,0.43,0.025),Color("eee6db"),false)
	var invitation := "ALREADY BEGUN\nAdd a face, take one away, or start over." if already_started else "TWELVE TRIANGLES\nLift, turn, join. A pyramid, or another form."
	Kit.label(self,invitation+"\nPieces stay where released.\nDesktop: Q/E roll, R/F tilt while holding.",Vector3(0,1.12,-0.759),23)

func unfinished_pose(i: int) -> Transform3D:
	# A stable starting composition, not a random scatter or a solved model.
	# The same twelve pickable bodies keep their normal release behaviour.
	var tabletop := 0.839
	if i<5:
		var loose := [Vector3(.68,tabletop,.20),Vector3(1.20,tabletop,-.37),Vector3(1.22,tabletop,.28),Vector3(.75,tabletop,-.43),Vector3(1.16,tabletop+.026,.28)]
		return Transform3D(Basis(Vector3.UP,deg_to_rad([-18,28,-42,78,-34][i])),loose[i])
	if i<9:
		# Four joined faces leave an open fan, with room to continue it.
		var turn := Basis(Vector3.UP,PI/12+(i-5)*PI/3)
		return Transform3D(turn,Vector3(-.83,tabletop,-.08)-turn*Vector3(0,0,.265))
	if i<11:
		# Two faces share an inclined edge: the start of a body, still open.
		var a := Vector3(-.23,0,-.133)
		var b := Vector3(.23,0,-.133)
		var c := Vector3(0,0,.265)
		var tip := Vector3(0,.3755,0)
		var left := a if i==9 else b
		var right := b if i==9 else c
		var x := (right-left).normalized()
		var towards_tip := tip-(left+right)*.5
		var z := (towards_tip-x*x.dot(towards_tip)).normalized()
		var turn := Basis(x,z.cross(x).normalized(),z)
		return Transform3D(turn,Vector3(.08,tabletop,-.15)+(left+right)*.5+z*.133)
	return Transform3D(Basis(Vector3.UP,deg_to_rad(152)),Vector3(.20,tabletop,.43))
