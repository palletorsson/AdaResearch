extends Node3D
## A propped concrete formwork panel: ply face +Z, steel soldiers, walers and push-pull props.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const WIDTH := 2.4
const HEIGHT := 3.0
const FRONT := .74

func _ready() -> void:
	var ply := Stock.finish("b9a27c", .9)
	var steel := Stock.finish("899599", .5, .7)
	var dark := Stock.finish("343b3d", .8, .3)
	var ply_t := .021
	Stock.box(self,"PlyFace",Vector3(0,HEIGHT*.5,FRONT-ply_t*.5),Vector3(WIDTH,HEIGHT,ply_t),ply)
	Stock.box(self,"SheetJoint",Vector3(0,1.5,FRONT+.002),Vector3(WIDTH-.08,.008,.004),dark,false)
	Stock.box(self,"SheetJoint",Vector3(0,.75,FRONT+.002),Vector3(.008,1.5,.004),dark,false)
	Stock.box(self,"SheetJoint",Vector3(0,2.25,FRONT+.002),Vector3(.008,1.5,.004),dark,false)
	# The steel frame profile wraps the ply edge, so the face reads as a framed panel.
	for x in [-WIDTH*.5+.02,WIDTH*.5-.02]:
		Stock.box(self,"FrameLip",Vector3(x,HEIGHT*.5,FRONT+.005),Vector3(.04,HEIGHT,.01),steel,false)
	for y in [.02,HEIGHT-.02]:
		Stock.box(self,"FrameLip",Vector3(0,y,FRONT+.005),Vector3(WIDTH-.08,.04,.01),steel,false)
	# Edge frame and vertical soldiers directly behind the ply.
	var back := FRONT-ply_t
	var sol_d := .12
	var sol_z := back-sol_d*.5
	for x in [-WIDTH*.5+.04,WIDTH*.5-.04]:
		Stock.box(self,"EdgeSoldier",Vector3(x,HEIGHT*.5,sol_z),Vector3(.08,HEIGHT,sol_d),steel)
	for x in [-.4,.4]:
		Stock.box(self,"Soldier",Vector3(x,HEIGHT*.5,sol_z),Vector3(.08,HEIGHT-.04,sol_d),steel)
	for y in [.04,HEIGHT-.04]:
		Stock.box(self,"EdgeRail",Vector3(0,y,back-.03),Vector3(WIDTH-.16,.08,.06),steel)
	# Horizontal walers ride behind the soldiers; tie-rod ends pass through them.
	var wal_d := .10
	var wal_z := back-sol_d-wal_d*.5
	var wal_back := wal_z-wal_d*.5
	for y in [.45,1.5,2.55]:
		Stock.box(self,"Waler",Vector3(0,y,wal_z),Vector3(WIDTH+.1,.12,wal_d),steel)
		for x in [-.8,.8]:
			Stock.box(self,"TiePlate",Vector3(x,y,wal_back-.01),Vector3(.12,.12,.02),dark,false)
			Stock.box(self,"TieNut",Vector3(x,y,wal_back-.04),Vector3(.05,.05,.04),dark,false)
			Stock.box(self,"TieRod",Vector3(x,y,wal_back-.10),Vector3(.02,.02,.08),dark,false)
			Stock.box(self,"TieCone",Vector3(x,y,FRONT+.003),Vector3(.045,.045,.006),dark,false)
	# Two push-pull props with a kicker each, from the walers down to base plates.
	var foot_z := -.67
	for x in [-.75,.75]:
		var head := Vector3(x,2.55,wal_back-.03)
		var knee := Vector3(x,.45,wal_back-.03)
		var foot := Vector3(x,.06,foot_z)
		Stock.box(self,"HeadBracket",Vector3(x,2.55,wal_back-.015),Vector3(.10,.16,.03),dark,false)
		Stock.box(self,"KneeBracket",Vector3(x,.45,wal_back-.015),Vector3(.10,.14,.03),dark,false)
		var along := (head-foot).normalized()
		var sleeve_end := foot.lerp(head,.55)
		Stock.tube(self,"PropOuter",foot,sleeve_end,.032,steel)
		Stock.tube(self,"PropInner",sleeve_end-along*.1,head,.022,steel)
		Stock.box(self,"PropCollar",sleeve_end,Vector3(.075,.075,.075),dark,false)
		Stock.tube(self,"Kicker",foot+Vector3(0,0,.06),knee,.02,steel)
		Stock.box(self,"FootShoe",foot+Vector3(0,.0,.03),Vector3(.08,.08,.12),dark,false)
		Stock.box(self,"BasePlate",Vector3(x,.008,foot_z+.02),Vector3(.18,.016,.24),dark)
		Stock.bolt(self,Vector3(x,.016,foot_z+.11),steel)
	Stock.batch_static(self)
