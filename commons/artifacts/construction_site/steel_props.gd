extends Node3D
## Three adjustable steel props on a timber sole plank, carrying a header beam to the slab above (5.60 m).
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

func _ready() -> void:
	var timber := Stock.finish("9b8f78", .95)
	var oxide := Stock.finish("8a4a3c", .75, .2)
	var galv := Stock.finish("899599", .45, .75)
	var dark := Stock.finish("343b3d", .7, .5)
	Stock.box(self,"SolePlank",Vector3(0,.025,0),Vector3(2.6,.05,.25),timber)
	Stock.box(self,"HeaderBeam",Vector3(0,5.525,0),Vector3(2.6,.15,.2),timber)
	for x in [-1.1,0.0,1.1]:
		Stock.box(self,"BasePlate",Vector3(x,.056,0),Vector3(.15,.012,.15),oxide)
		Stock.box(self,"HeadPlate",Vector3(x,5.444,0),Vector3(.15,.012,.15),oxide)
		Stock.tube(self,"OuterTube",Vector3(x,.062,0),Vector3(x,3.0,0),.03,oxide)
		Stock.tube(self,"InnerTube",Vector3(x,2.9,0),Vector3(x,5.438,0),.022,galv)
		Stock.tube(self,"Collar",Vector3(x,2.95,0),Vector3(x,3.06,0),.042,oxide,false)
		Stock.tube(self,"Pin",Vector3(x-.075,3.1,0),Vector3(x+.075,3.1,0),.008,dark,false)
		Stock.tube(self,"PinTail",Vector3(x+.075,3.1,0),Vector3(x+.075,3.02,.01),.006,dark,false)
		for i in range(6):
			Stock.box(self,"AdjustHole",Vector3(x,3.3+i*.32,.021),Vector3(.012,.012,.004),dark,false)
	Stock.batch_static(self)
