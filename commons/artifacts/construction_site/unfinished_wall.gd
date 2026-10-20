extends Node3D
## A relocatable 3.6 m stud bay with partially attached plasterboard.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

func _ready() -> void:
	var steel := Stock.finish("899599", .48, .72)
	var edge := Stock.finish("d0c5b1", .94)
	var plaster := Stock.finish("dedbd0", .93)
	var dark := Stock.finish("52595a", .7, .45)
	for y in [.045,2.855]:
		Stock.box(self,"ChannelWeb",Vector3(0,y,0),Vector3(3.6,.025,.09),steel)
		for z in [-.05,.05]: Stock.box(self,"ChannelLip",Vector3(0,y,z),Vector3(3.6,.065,.012),steel)
	for i in range(7):
		var x := -1.76+i*(3.52/6)
		Stock.box(self,"StudWeb",Vector3(x,1.45,0),Vector3(.012,2.8,.09),steel)
		for z in [-.05,.05]: Stock.box(self,"StudFlange",Vector3(x,1.45,z),Vector3(.048,2.8,.012),steel)
	# Two full sheets stop before the last two stud bays; the upper edge stays unfinished.
	for i in range(2):
		var x := -1.175+i*1.18
		Stock.box(self,"SheetCore",Vector3(x,1.22,.072),Vector3(1.17,2.36,.024),edge)
		Stock.box(self,"PlasterFace",Vector3(x,1.22,.086),Vector3(1.164,2.354,.004),plaster,false)
		for dx in [-.54,.54]:
			for y in [.12,.56,1.0,1.44,1.88,2.32]: Stock.bolt(self,Vector3(x+dx,y,.09),dark)
	for x in [-1.5,1.5]:
		Stock.box(self,"BraceFoot",Vector3(x,.025,0),Vector3(.25,.05,.86),dark)
		Stock.tube(self,"SupportBrace",Vector3(x,.05,-.4),Vector3(x,.9,0),.019,steel)
	# A narrow leaning offcut makes the unfinished bay read as a paused piece of work.
	var offcut := Stock.box(self,"BoardOffcut",Vector3(1.12,.63,.20),Vector3(.40,1.26,.024),edge)
	offcut.rotation_degrees.x = -9
	Stock.batch_static(self)
