extends Node3D
## A free-standing board-formed concrete slab on steel feet, a backdrop wall; face +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const WIDTH := 3.0
const HEIGHT := 3.2
const THICK := .25
const LIFT := .08

func _ready() -> void:
	var concrete := Stock.finish("a3a39c", .95)
	var seam := Stock.finish("8b8d88", .97)
	var dark := Stock.finish("343b3d", .9)
	var steel := Stock.finish("899599", .5, .7)
	var half := THICK*.5
	# Body stops short of the top; a chamfer and an uneven cap make the cast edge.
	var body_top := HEIGHT-.09
	Stock.box(self,"SlabBody",Vector3(0,LIFT+(body_top-LIFT)*.5,0),Vector3(WIDTH,body_top-LIFT,THICK),concrete)
	var cap_widths := [.55,.7,.45,.8,.5]
	var cap_heights := [.09,.075,.088,.062,.084]
	var cx := -WIDTH*.5
	for i in range(cap_widths.size()):
		var w: float = cap_widths[i]
		var h: float = cap_heights[i]
		Stock.box(self,"CapChunk",Vector3(cx+w*.5,body_top+h*.5,-.02),Vector3(w,h,THICK-.04),concrete)
		cx += w
	var chamfer := Stock.box(self,"Chamfer",Vector3(0,body_top-.005,half-.028),Vector3(WIDTH,.08,.08),concrete,false)
	chamfer.rotation_degrees.x = 45
	# Board-form lines: shallow darker strips standing 2 mm proud on both faces.
	for y in [.42,.74,1.06,1.38,1.70,2.02,2.34,2.66,2.94]:
		for z in [half+.002,-half-.002]:
			Stock.box(self,"BoardLine",Vector3(0,y,z),Vector3(WIDTH-.01,.012,.004),seam,false)
	# A few stopped board ends, so the forms read as timber boards, not ruled lines.
	for p in [Vector2(-.62,.58),Vector2(.84,1.22),Vector2(-.15,1.86),Vector2(1.05,2.50)]:
		Stock.box(self,"BoardJoint",Vector3(p.x,LIFT+p.y,half+.002),Vector3(.01,.31,.004),seam,false)
	# Formwork tie holes, a 4 x 4 grid of dark plugs on the face.
	for ix in range(4):
		for iy in range(4):
			var at := Vector3(-1.08+ix*.72,.58+iy*.72,half+.003)
			Stock.box(self,"TieHole",at,Vector3(.048,.048,.006),dark,false)
	# Two steel feet with a rear raking brace each: placed, not built in.
	for x in [-1.05,1.05]:
		Stock.box(self,"Foot",Vector3(x,LIFT*.5,0),Vector3(.16,LIFT,.90),steel)
		for z in [half+.006,-half-.006]:
			Stock.box(self,"Cleat",Vector3(x,LIFT+.07,z),Vector3(.14,.14,.012),steel,false)
		Stock.tube(self,"RearBrace",Vector3(x,LIFT,-.43),Vector3(x,1.55,-half-.02),.024,steel)
		Stock.box(self,"BraceShoe",Vector3(x,1.55,-half-.012),Vector3(.10,.14,.012),steel,false)
		for z in [.25,-.40]: Stock.bolt(self,Vector3(x,LIFT,z),dark)
	Stock.batch_static(self)
