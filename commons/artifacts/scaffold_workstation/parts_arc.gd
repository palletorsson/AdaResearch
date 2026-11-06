extends RefCounted
## Stable tool addresses. Later lessons open a socket, never shuffle the rack.
const Furniture=preload("shop_furniture.gd")
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
## The 4 m rod lays a joint at every metre (model.gd MACRO_UNITS); the 8 m rod exists in the grammar but the bench's
## domain is 6 m, so it has no socket here until the domain grows.
const ORDER=["point","rod_short","rod","rod_4","panel","quad","quad_4","wedge","pyramid"]
const TITLES=["POINT","1 M ROD","2 M ROD","4 M ROD","TRIANGLE","QUAD","4 M QUAD","WEDGE","PYRAMID"]

static func address(index:int)->Vector3:
	var angle:float=PI-float(index)*PI/float(ORDER.size()-1)
	return Vector3(.1+cos(angle)*.69,.04+sin(angle)*.58,.24)

static func build(parent:Node3D,tier:int,prefabs:bool)->void:
	var rack:=Node3D.new();rack.name="PartsArc";parent.add_child(rack)
	# The support stays behind the stock and above the model, with an open centre.
	for i in 30:
		var a:float=PI-i*PI/30.0;var b:float=PI-(i+1)*PI/30.0
		Furniture.tube(rack,"Arc",Vector3(.1+cos(a)*.69,.04+sin(a)*.58,.13),Vector3(.1+cos(b)*.69,.04+sin(b)*.58,.13),.012,Color("b9c8c4"))
	for x in [-.59,.79]:
		Furniture.tube(rack,"Foot",Vector3(x,-.25,.13),Vector3(x,.04,.13),.014,Color("c7cfcb"))
	for i in ORDER.size():
		var at:=address(i)
		var available:bool=i<=[0,3,4,6][tier] or (i>=7 and prefabs)
		Furniture.tube(rack,"SocketStem",at-Vector3(0,0,.11),at-Vector3(0,0,.055),.009,Color("8d9e9a"))
		Kit.box(rack,"Socket",at-Vector3(0,0,.055),Vector3(.09,.035,.025),Color("9dafab") if available else Color("4e5c5a"),false)
		Furniture.tube(rack,"CaptionStem",at-Vector3(0,0,.11),at+Vector3(0,.17,-.02),.004,Color("8d9e9a"))
		var plate:=Kit.box(rack,"CaptionPlate",at+Vector3(0,.17,-.008),Vector3(.185,.048,.008),Color("263638"),false)
		var caption:=Kit.label(plate,TITLES[i] if available else "—",Vector3(0,0,.005),10)
		caption.modulate=Color("e0e9e3") if available else Color("7b8985")
