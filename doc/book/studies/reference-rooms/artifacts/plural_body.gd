extends "./build.gd"
## Original primitive assemblage. No scanned likenesses, rig or soft-body claim.
func build() -> void:
	var skin := ShaderMaterial.new()
	skin.shader = preload("./skin.gdshader")
	var silver := material(Color(0.77,0.72,0.80),0.14,0.9)
	var pink := material(Color(0.94,0.34,0.63),0.23,0.68)
	var dark := material(Color(0.045,0.017,0.045),0.21,0.58)
	cylinder(Vector3(0,0.16,0),2.35,0.32,dark,96)
	ring(Vector3(0,0.32,0),2.15,0.012,emissive(Color("e76aad"),1.4))
	ball(Vector3(0,1.8,0),Vector3(0.64,0.90,0.44),skin)
	ball(Vector3(0,2.62,0),Vector3(0.49,0.63,0.39),silver)
	ball(Vector3(0,3.46,0),Vector3(0.35,0.43,0.33),skin)
	# Three heads share a trunk. Their spacing changes with the same unfolding.
	for sign_value in [-1,1]:
		var head_at := Vector3(sign_value*lerpf(0.34,0.85,amount),3.25,0.05)
		ball(head_at,Vector3(0.28,0.35,0.28),pink)
		segment(Vector3(sign_value*0.28,2.9,0),head_at,0.13,skin)
		ball(Vector3(sign_value*0.33,0.84,0.0),Vector3(0.25,0.65,0.27),skin)
		ball(Vector3(sign_value*0.37,0.4,0.18),Vector3(0.26,0.14,0.41),pink)
	var tips: Array[Vector3] = []
	for side in [-1,1]:
		for limb in 3:
			var path := PackedVector3Array()
			var start := Vector3(side*0.44,2.6-limb*0.4,0.0)
			var tip := Vector3(side*lerpf(0.55,2.15+limb*0.18,amount),lerpf(2.9-limb*0.25,3.9-limb*1.3,amount),0.25+limb*0.05)
			tips.append(tip)
			var control := Vector3(side*lerpf(1.0,2.3,amount),2.3-limb*0.24,-0.6)
			for j in 41:
				var t := j / 40.0
				path.append((1-t)*(1-t)*start+2*(1-t)*t*control+t*t*tip)
			tube(path,0.20,skin if limb != 1 else silver)
			ball(tip,Vector3(0.18,0.24,0.16),pink)
	# Open loops frame a body without prescribing a human outline.
	for side in [-1,1]:
		var halo := ring(Vector3(side*0.86,2.3,-0.65),1.5,0.065,silver,Vector3(90,side*22,side*24))
		halo.scale = Vector3(0.8,1,1.25)
	for i in 8:
		var angle := TAU*i/8.0
		ball(Vector3(cos(angle)*0.38,3.84+0.07*sin(i*2),sin(angle)*0.3),Vector3(0.085,0.13,0.085),pink)
	evidence = {"limbs": 6, "heads": 3, "tips": tips, "unfold": amount, "physics": "none; geometric pose", "skin": "view-dependent rim, metallic shading"}
