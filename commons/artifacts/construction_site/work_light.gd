extends Node3D
## Portable twin-head lamp. Front is -Z; rotate the complete prop to aim it.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
@export var powered := true
@export_range(0.0, 20.0, 0.1) var beam_energy := 3.5:
	set(value):
		beam_energy = maxf(value, 0.0)
		var beam := get_node_or_null("WorkBeam") as SpotLight3D
		if beam != null: beam.light_energy = beam_energy
@export_range(1.0, 15.0, 0.1) var beam_range := 9.0
@export_range(10.0, 70.0, 1.0) var beam_angle := 57.0

func _ready() -> void:
	var yellow := Stock.finish("d6aa3b", .48, .45)
	var black := Stock.finish("25292d", .46, .65)
	var steel := Stock.finish("a7b1b3", .32, .8)
	var lens := Stock.finish("fff1ca", .24)
	lens.emission_enabled = true
	lens.emission = Color("ffe2ab")
	lens.emission_energy_multiplier = 2.0 if powered else 0.0
	for i in range(3):
		var angle := TAU * i / 3.0
		var foot := Vector3(cos(angle)*.55,.035,sin(angle)*.55)
		Stock.tube(self,"TripodLeg",Vector3(0,.43,0),foot,.026,yellow)
		Stock.tube(self,"LegBrace",Vector3(0,.18,0),foot.lerp(Vector3(0,.43,0),.3),.012,black,false)
		Stock.box(self,"RubberFoot",foot,Vector3(.12,.055,.1),black)
	Stock.tube(self,"LowerMast",Vector3(0,.12,0),Vector3(0,1.13,0),.032,yellow)
	Stock.tube(self,"TelescopicMast",Vector3(0,1.08,0),Vector3(0,1.65,0),.022,steel)
	Stock.box(self,"HeightLock",Vector3(.04,1.07,0),Vector3(.10,.055,.07),black,false)
	Stock.box(self,"Crossbar",Vector3(0,1.56,0),Vector3(.92,.04,.055),yellow)
	for x in [-.29,.29]:
		var head := Node3D.new()
		head.name = "LampHead"
		head.position = Vector3(x,1.77,0)
		head.rotation_degrees = Vector3(-10,19,0)
		add_child(head)
		Stock.box(head,"Housing",Vector3.ZERO,Vector3(.46,.30,.11),black)
		Stock.box(head,"Lens",Vector3(0,0,-.062),Vector3(.405,.245,.016),lens,false)
		for side in [-1,1]:
			Stock.box(head,"Yoke",Vector3(side*.25,-.09,0),Vector3(.022,.25,.035),yellow,false)
		Stock.box(head,"YokeBase",Vector3(0,-.205,0),Vector3(.52,.026,.035),yellow,false)
		for y in [-.09,-.045,0,.045,.09]:
			Stock.box(head,"CoolingFin",Vector3(0,y,.063),Vector3(.37,.012,.035),black,false)
		for side in [-1,1]:
			for y in [-.115,.115]: Stock.bolt(head,Vector3(side*.19,y,-.08),steel)
	# One cone serves both heads: bounded range, one shadow map even when copied.
	var light := SpotLight3D.new()
	light.name = "WorkBeam"
	light.position = Vector3(0,1.77,-.15)
	light.rotation_degrees = Vector3(-10,19,0)
	light.light_color = Color("ffe1b0")
	light.light_energy = beam_energy
	light.spot_range = beam_range
	light.spot_angle = beam_angle
	light.spot_attenuation = .8
	light.shadow_enabled = true
	light.visible = powered
	add_child(light)
	# Keep the cable on the stand; there is no new cable crossing the floor route.
	for i in range(20):
		var a := i * .22
		var b := (i+1) * .22
		Stock.tube(self,"CoiledLead",Vector3(.075*cos(a),.24+i*.012,.075*sin(a)),Vector3(.075*cos(b),.24+(i+1)*.012,.075*sin(b)),.009,black,false)
	Stock.batch_static(self)
