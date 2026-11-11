extends Node3D
## A waist-high block counter wall with a timber top to lean on; front +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const LENGTH := 2.4
const BODY_H := .96
const DEPTH := .38
const BASE := .05

func _ready() -> void:
	var block := Stock.finish("a3a39c", .95)
	var mortar := Stock.finish("8b8d88", .97)
	var timber := Stock.finish("9b8f78", .85)
	var steel := Stock.finish("52595a", .6, .5)
	var half := DEPTH*.5
	var course := (BODY_H-BASE)/5.0
	Stock.box(self,"Footing",Vector3(0,BASE*.5,0),Vector3(LENGTH+.04,BASE,DEPTH+.04),mortar)
	Stock.box(self,"BlockBody",Vector3(0,BASE+(BODY_H-BASE)*.5,0),Vector3(LENGTH,BODY_H-BASE,DEPTH),block)
	# Five block courses in half bond; joints stand 2 mm proud on front, back and ends.
	for c in range(5):
		var y0 := BASE+c*course
		if c > 0:
			for z in [half+.002,-half-.002]:
				Stock.box(self,"BedJoint",Vector3(0,y0,z),Vector3(LENGTH,.012,.004),mortar,false)
			for x in [LENGTH*.5+.002,-LENGTH*.5-.002]:
				Stock.box(self,"EndJoint",Vector3(x,y0,0),Vector3(.004,.012,DEPTH),mortar,false)
		var offset := .2 if c % 2 == 1 else 0.0
		var x := -LENGTH*.5+.4+offset
		while x < LENGTH*.5-.05:
			for z in [half+.002,-half-.002]:
				Stock.box(self,"PerpJoint",Vector3(x,y0+course*.5,z),Vector3(.012,course-.01,.004),mortar,false)
			x += .4
	# The thick timber top overhangs both faces; dark steel brackets hold it.
	# Three thick boards with open 6 mm gaps between them.
	for z in [-.15,0.0,.15]:
		Stock.box(self,"TimberBoard",Vector3(0,BODY_H+.045,z),Vector3(LENGTH+.06,.09,.144),timber)
	for x in [-.9,0.0,.9]:
		for z in [half+.004,-half-.004]:
			Stock.box(self,"Bracket",Vector3(x,BODY_H-.04,z),Vector3(.06,.08,.008),steel,false)
		Stock.bolt(self,Vector3(x,BODY_H-.05,half+.008),steel)
	Stock.batch_static(self)
