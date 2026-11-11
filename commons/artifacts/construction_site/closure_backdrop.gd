extends Node3D
## A 4.0 m x 5.6 m floor-to-ceiling board closure on a light steel frame, raked from behind. Face is +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

const Z0 := .40 # shifts the whole frame forward so the envelope is centred in z

func _ready() -> void:
	var board := Stock.finish("e2dfd4", .92)
	var steel := Stock.finish("899599", .48, .72)
	var dark := Stock.finish("52595a", .7, .45)
	var shadow := Stock.finish("343b3d", .9)
	# Base plate on the slab, top plate meeting the slab above.
	Stock.box(self,"BasePlate",Vector3(0,.03,Z0),Vector3(4.0,.06,.14),steel)
	Stock.box(self,"TopPlate",Vector3(0,5.57,Z0),Vector3(4.0,.06,.14),steel)
	for x in [-1.975,0.0,1.975]:
		Stock.box(self,"Stud",Vector3(x,2.8,Z0),Vector3(.05,5.48,.09),steel)
	var row_h: float = (5.48-.04)/3.0
	var col_w: float = (4.0-.02)/2.0
	for r in range(3):
		var y0: float = .06+r*(row_h+.02)
		if r > 0:
			Stock.box(self,"Noggin",Vector3(0,y0-.01,Z0),Vector3(3.9,.05,.09),steel,false)
			Stock.box(self,"ShadowJoint",Vector3(0,y0-.01,Z0+.042),Vector3(4.0,.04,.004),shadow,false)
		for c in range(2):
			var x: float = -2.0+col_w/2.0+c*(col_w+.02)
			Stock.box(self,"Panel",Vector3(x,y0+row_h/2.0,Z0+.054),Vector3(col_w,row_h,.018),board)
	Stock.box(self,"ShadowJoint",Vector3(0,2.8,Z0+.042),Vector3(.04,5.48,.004),shadow,false)
	# Two raking struts brace the frame from behind.
	for x in [-1.3,1.3]:
		var head := Vector3(x,3.4,Z0-.045)
		var foot := Vector3(x,.04,Z0-.80)
		Stock.tube(self,"RakingStrut",head,foot,.024,steel)
		Stock.box(self,"StrutCleat",head+Vector3(0,0,-.015),Vector3(.12,.16,.02),dark,false)
		Stock.box(self,"FootPlate",Vector3(x,.01,Z0-.80),Vector3(.18,.02,.18),dark)
		Stock.tube(self,"Kicker",Vector3(x,.05,Z0-.78),Vector3(x,.05,Z0-.07),.016,steel,false)
		for dx in [-.05,.05]:
			Stock.bolt(self,Vector3(x+dx,.021,Z0-.80+.05),steel)
	Stock.batch_static(self)
