extends Node3D
## Godot reconstruction inspired by props_c17/fence01a.
## Galvanized frame with a real diamond wire mesh; floor origin, width along X.
const Stock := preload("stock.gd")
const WIDTH := 3.40
const HEIGHT := 2.76

func _ready() -> void:
	var steel := Stock.finish("929b9b", .54, .65)
	var wire := Stock.finish("7a8587", .62, .52)
	var rust := Stock.finish("715746", .93, .12)
	var half := WIDTH*.5-.032
	for x in [-half,half]:
		Stock.tube(self,"Post",Vector3(x,.032,0),Vector3(x,HEIGHT-.032,0),.032,steel)
		Stock.box(self,"BasePlate",Vector3(x,.009,0),Vector3(.13,.018,.16),steel)
	for y in [.052,HEIGHT-.052]:
		Stock.tube(self,"EdgeRail",Vector3(-half,y,0),Vector3(half,y,0),.026,steel)
	Stock.tube(self,"MiddleRail",Vector3(-half,HEIGHT*.5,-.012),Vector3(half,HEIGHT*.5,-.012),.017,steel)
	Stock.tube(self,"DiagonalBrace",Vector3(-half+.025,.08,-.035),Vector3(half-.025,HEIGHT-.08,-.035),.013,steel)
	# Clip both diagonal families to the inside of the frame. All wire is solid
	# geometry, batched into one surface; no transparent texture sorting in VR.
	var xmin := -half+.015
	var xmax := half-.015
	var ymin := .075
	var ymax := HEIGHT-.075
	for slope in [-1.0,1.0]:
		for i in range(-34,35):
			var intercept := float(i)*.14
			var lo := maxf(xmin,(ymin-intercept)/slope) if slope>0 else maxf(xmin,(ymax-intercept)/slope)
			var hi := minf(xmax,(ymax-intercept)/slope) if slope>0 else minf(xmax,(ymin-intercept)/slope)
			if hi-lo<.02: continue
			Stock.tube(self,"DiamondWire",Vector3(lo,slope*lo+intercept,.012*slope),Vector3(hi,slope*hi+intercept,.012*slope),.0035,wire,false)
	for x in [-half,half]:
		for y in [.28,.85,1.42,1.99,2.55]:
			Stock.tube(self,"WireTie",Vector3(x-.035,y,.021),Vector3(x+.035,y,.021),.005,rust,false)
	# The mesh openings are visual. A body cannot pass through a chain-link bay;
	# use one thin panel collision instead of one physics shape per strand.
	var web := Node3D.new()
	web.name = "WireCollision"
	web.position.y = HEIGHT*.5
	add_child(web)
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH-.064,HEIGHT-.10,.035)
	Stock.collision(web,shape)
	Stock.batch_static(self)
